import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/mock_data.dart';
import '../core/pixel_theme.dart';
import '../widgets/pixel_avatar.dart';
import '../widgets/pixel_ui.dart';
import 'call_screen.dart';
import 'clips_screen.dart';
import 'create_screen.dart';
import 'discover_screen.dart';
import 'feed_screen.dart';
import 'friends_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.fromLogin = false});

  final bool fromLogin;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  double _tabFade = 1;
  Timer? _notifTimer;
  late final AnimationController _enterCtrl;
  late final Animation<double> _enterFade;
  late final Animation<Offset> _enterSlide;

  static const _tabs = [
    (PixelGlyphKind.home, 'INICIO'),
    (PixelGlyphKind.play, 'CLIPS'),
    (PixelGlyphKind.plus, 'CREAR'),
    (PixelGlyphKind.chat, 'CHAT'),
    (PixelGlyphKind.people, 'AMIGOS'),
  ];

  @override
  void initState() {
    super.initState();
    AppState.I.addListener(_onApp);
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
      value: widget.fromLogin ? 0 : 1,
    );
    _enterFade = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _enterSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));
    if (widget.fromLogin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _enterCtrl.forward();
      });
    }
    // Banner demo suave (una sola vez, tarde).
    _notifTimer = Timer(const Duration(seconds: 18), () {
      if (!mounted || _index == 3) return;
      final m = ScaffoldMessenger.of(context);
      m.clearMaterialBanners();
      m.showSnackBar(
        SnackBar(
          backgroundColor: Px.panelLight,
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              PixelAvatar(config: Mock.users['kael']!.avatar, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'kael ', style: Px.label(7, Px.accent)),
                      TextSpan(text: 'te escribió', style: Px.label(6)),
                    ],
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  m.hideCurrentSnackBar();
                  AppState.I.openDm('kael');
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ChatScreen(user: 'kael'),
                    ),
                  );
                },
                child: Text('ABRIR', style: Px.label(7, Px.accent)),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _goTab(int i) {
    if (i == _index) return;
    setState(() {
      _index = i;
      _tabFade = 0.45;
    });
    Future<void>.delayed(const Duration(milliseconds: 90), () {
      if (mounted) setState(() => _tabFade = 1);
    });
  }

  void _onApp() {
    if (!mounted) return;
    final t = AppState.I.takeTabRequest();
    setState(() {
      if (t != null) _index = t;
    });
  }

  @override
  void dispose() {
    AppState.I.removeListener(_onApp);
    _notifTimer?.cancel();
    _enterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // GRIDLY solo en Inicio / Clips / Crear. Chat y Amigos ya traen su cabecera.
    final showTop = _index == 0 || _index == 1 || _index == 2;
    final top = showTop ? MediaQuery.paddingOf(context).top + 52 : 0.0;
    final bottom = 86.0 + MediaQuery.paddingOf(context).bottom;
    return ListenableBuilder(
      listenable: GridTheme.I,
      builder: (_, __) => FadeTransition(
        opacity: _enterFade,
        child: SlideTransition(
          position: _enterSlide,
          child: Scaffold(
            extendBody: true,
            backgroundColor: Px.bg,
            body: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: _tabFade,
                    duration: const Duration(milliseconds: 160),
                    child: IndexedStack(
                      index: _index,
                      children: [
                        _inset(
                          top,
                          bottom,
                          FeedScreen(playEntrance: widget.fromLogin),
                        ),
                        ClipsScreen(visible: _index == 1),
                        _inset(top, bottom, const CreateScreen()),
                        _inset(0, bottom, const MessagesScreen(embedded: true)),
                        _inset(0, bottom, const FriendsScreen()),
                        Padding(
                          padding: EdgeInsets.only(bottom: bottom),
                          child: const ProfileScreen(),
                        ),
                      ],
                    ),
                  ),
                ),
                if (showTop)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _TopBar(profileActive: _index == 5),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _CallBar(),
                      _PixelNavBar(
                        index: _index >= _tabs.length ? -1 : _index,
                        tabs: _tabs,
                        chatBadge: AppState.I.unreadDms,
                        onTap: _goTab,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _inset(double top, double bottom, Widget child) {
  return Padding(
    padding: EdgeInsets.only(top: top, bottom: bottom),
    child: child,
  );
}

/// GRIDLY y lupa sin cajas: solo sombra para leerse sobre el video.
class _TopBar extends StatelessWidget {
  const _TopBar({this.profileActive = false});
  final bool profileActive;

  static const _shadow = [
    Shadow(color: Color(0xCC000000), offset: Offset(1, 1), blurRadius: 2),
  ];

  @override
  Widget build(BuildContext context) {
    final s = AppState.I;
    return ListenableBuilder(
      listenable: s,
      builder: (_, __) => Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => AppState.I.requestTab(5),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: profileActive ? Px.accent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: AvatarBadge(
                      config: s.avatar,
                      size: 34,
                      ghost: !profileActive,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IgnorePointer(
                  child: Text(
                    'GRIDLY',
                    style: Px.title(10).copyWith(shadows: _shadow),
                  ),
                ),
                const Spacer(),
                PixelIconCard(
                  kind: PixelGlyphKind.search,
                  ghost: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DiscoverScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Barra de llamada/videollamada en segundo plano.
class _CallBar extends StatelessWidget {
  const _CallBar();

  @override
  Widget build(BuildContext context) {
    final s = AppState.I;
    return ListenableBuilder(
      listenable: s,
      builder: (_, __) {
        if (s.callWith == null) return const SizedBox.shrink();
        final key = s.resolveUserKey(s.callWith!);
        final peer = key != null ? Mock.users[key] : null;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder:
                      (_) =>
                          CallScreen(peer: s.callWith!, video: s.callIsVideo),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Px.accentDark,
                border: Border(
                  top: BorderSide(color: Px.accent, width: 2),
                ),
              ),
              child: Row(
                children: [
                  const _PulsingDot(),
                  const SizedBox(width: 8),
                  if (peer != null)
                    AvatarBadge(
                      config: peer.avatar,
                      size: 32,
                      status: peer.status,
                      rgb: true,
                    )
                  else
                    PixelGlyph(
                      kind:
                          s.callIsVideo
                              ? PixelGlyphKind.video
                              : PixelGlyphKind.call,
                      size: 16,
                      color: Px.accent,
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            PixelGlyph(
                              kind:
                                  s.callIsVideo
                                      ? PixelGlyphKind.video
                                      : PixelGlyphKind.call,
                              size: 10,
                              color: Px.accent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              s.callIsVideo
                                  ? 'VIDEOLLAMADA'
                                  : 'LLAMADA',
                              style: Px.label(6, Px.accent),
                            ),
                          ],
                        ),
                        Text(
                          '${s.callWith} · toca para volver',
                          style: Px.label(6, Px.text),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: s.toggleMute,
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: s.muted ? Px.danger : Px.panel,
                        border: Border.all(color: Px.border, width: 2),
                      ),
                      child: PixelGlyph(
                        kind:
                            s.muted
                                ? PixelGlyphKind.micOff
                                : PixelGlyphKind.mic,
                        color: s.muted ? Px.bg : Px.text,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: s.endCall,
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Px.danger,
                        border: Border.all(color: Px.danger, width: 2),
                      ),
                      child: PixelGlyph(
                        kind: PixelGlyphKind.hangup,
                        color: Px.bg,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween(begin: 0.3, end: 1.0).animate(_c),
    child: Container(width: 10, height: 10, color: Px.accent),
  );
}

class _PixelNavBar extends StatelessWidget {
  const _PixelNavBar({
    required this.index,
    required this.tabs,
    required this.onTap,
    this.chatBadge = 0,
  });

  final int index;
  final List<(PixelGlyphKind, String)> tabs;
  final ValueChanged<int> onTap;
  final int chatBadge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        6,
        0,
        6,
        6 + MediaQuery.paddingOf(context).bottom,
      ),
      child: SizedBox(
        height: 62,
        child: Row(
          children: [
            for (var i = 0; i < tabs.length; i++)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: i == index ? 40 : 34,
                        height: i == index ? 40 : 34,
                        decoration: BoxDecoration(
                          color: i == index ? Px.accent : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                i == index
                                    ? Px.accent
                                    : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow:
                              i == index
                                  ? null
                                  : const [
                                    BoxShadow(
                                      color: Color(0x99000000),
                                      blurRadius: 4,
                                    ),
                                  ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PixelGlyph(
                              kind: tabs[i].$1,
                              size: i == index ? 16 : 14,
                              color: i == index ? Px.bg : Px.text,
                            ),
                            if (tabs[i].$1 == PixelGlyphKind.chat &&
                                chatBadge > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 14,
                                    minHeight: 14,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Px.danger,
                                    border: Border.all(color: Px.bg, width: 1),
                                  ),
                                  child: Text(
                                    chatBadge > 9 ? '9+' : '$chatBadge',
                                    style: Px.label(5, Px.bg),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tabs[i].$2,
                        style: Px.label(
                          5,
                          i == index ? Px.accent : Px.text,
                        ).copyWith(
                          shadows: const [
                            Shadow(
                              color: Color(0xCC000000),
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
