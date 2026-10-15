import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material show Clip;

import '../core/app_state.dart';
import '../core/media.dart';
import '../core/mock_data.dart';
import '../core/nav.dart';
import '../core/pixel_theme.dart';
import '../widgets/net_video.dart';
import '../widgets/pixel_avatar.dart';
import '../widgets/pixel_ui.dart';

/// Feed vertical de clips (estilo TikTok) con video real desde internet.
class ClipsScreen extends StatefulWidget {
  const ClipsScreen({super.key, this.visible = true});

  /// Si la pestaña está visible (IndexedStack). Si no, se pausa el video.
  final bool visible;

  @override
  State<ClipsScreen> createState() => _ClipsScreenState();
}

class _ClipsScreenState extends State<ClipsScreen> with RouteAware {
  final _controller = PageController();
  bool _followingOnly = false;
  int _page = 0;
  bool _covered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);
  }

  @override
  void didPushNext() => setState(() => _covered = true);

  @override
  void didPopNext() => setState(() => _covered = false);

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _controller.dispose();
    super.dispose();
  }

  List<Clip> get _clips {
    if (!_followingOnly) return Mock.clips;
    final f = AppState.I.following;
    return Mock.clips.where((c) => f.contains(c.author)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (context, _) {
        final clips = _clips;
        return Stack(
          children: [
            if (clips.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('SIN CLIPS DE QUIEN SIGUES', style: Px.title(8)),
                      const SizedBox(height: 10),
                      Text(
                        'Sigue a gente desde su perfil\npara verlos aquí',
                        style: Px.bodyDim,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      PixelButton(
                        label: 'VER PARA TI',
                        small: true,
                        onPressed: () => setState(() => _followingOnly = false),
                      ),
                    ],
                  ),
                ),
              )
            else
              PageView.builder(
                controller: _controller,
                scrollDirection: Axis.vertical,
                itemCount: clips.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _ClipPage(
                  key: ValueKey('${clips[i].id}_$_followingOnly'),
                  clip: clips[i],
                  active: i == _page && widget.visible && !_covered,
                ),
              ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 56,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => setState(() {
                      _followingOnly = true;
                      _page = 0;
                      if (_controller.hasClients) {
                        _controller.jumpToPage(0);
                      }
                    }),
                    child: Column(
                      children: [
                        Text(
                          'SIGUIENDO',
                          style: Px.label(
                            8,
                            _followingOnly ? Px.accent : Px.textDim,
                          ),
                        ),
                        if (_followingOnly)
                          Container(width: 40, height: 3, color: Px.accent),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  GestureDetector(
                    onTap: () => setState(() {
                      _followingOnly = false;
                      _page = 0;
                      if (_controller.hasClients) {
                        _controller.jumpToPage(0);
                      }
                    }),
                    child: Column(
                      children: [
                        Text(
                          'PARA TI',
                          style: Px.label(
                            8,
                            !_followingOnly ? Px.accent : Px.textDim,
                          ),
                        ),
                        if (!_followingOnly)
                          Container(width: 40, height: 3, color: Px.accent),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ClipPage extends StatefulWidget {
  const _ClipPage({super.key, required this.clip, this.active = true});
  final Clip clip;
  final bool active;

  @override
  State<_ClipPage> createState() => _ClipPageState();
}

class _ClipPageState extends State<_ClipPage> {
  bool _heart = false;

  void _heartBurst() {
    setState(() => _heart = true);
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _heart = false);
    });
  }

  Widget _media(bool liked, AppState s) {
    final url = widget.clip.videoUrl;
    // Clips con link/asset: SIEMPRE video (nunca escena de avatares).
    // En tests no hay media_kit → placeholder.
    if (url != null && url.isNotEmpty && MediaEnv.online) {
      return NetVideo(
        key: ValueKey(url),
        url: url,
        active: widget.active,
        onDoubleTap: () {
          if (!liked) {
            s.toggleLikeClip(widget.clip.id);
            if (s.likedClips.contains(widget.clip.id)) _heartBurst();
          }
        },
      );
    }
    // Solo en tests / sin red: fondo negro (no avatares).
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Text(
          MediaEnv.online ? 'SIN VIDEO' : 'VIDEO (demo)',
          style: Px.label(8, Px.textDim),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clip = widget.clip;
    final user =
        Mock.users[clip.author] ??
        User(
          clip.author,
          AppState.I.avatar,
          PresenceStatus.online,
          bio: 'tu cuenta',
        );
    final s = AppState.I;
    // Espacio libre encima de Inicio / Clips / Crear / Chat / Amigos.
    final navClear = MediaQuery.paddingOf(context).bottom + 88;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final liked = s.likedClips.contains(clip.id);
        final follows = s.following.contains(clip.author);
        return Stack(
          fit: StackFit.expand,
          children: [
            _media(liked, s),
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: _heart ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: AnimatedScale(
                  scale: _heart ? 1 : 0.4,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  child: Center(
                    child: PixelGlyph(
                      kind: PixelGlyphKind.heart,
                      size: 64,
                      color: Px.danger,
                    ),
                  ),
                ),
              ),
            ),
            // Degradado inferior para legibilidad.
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC07140E)],
                    ),
                  ),
                ),
              ),
            ),
            // Columna de acciones.
            Positioned(
              right: 10,
              bottom: navClear + 12,
              child: Column(
                children: [
                  Stack(
                    clipBehavior: material.Clip.none,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (clip.author == AppState.I.username) return;
                          if (Mock.users.containsKey(clip.author)) {
                            openUserProfile(context, clip.author);
                          }
                        },
                        child: AvatarBadge(
                          config: user.avatar,
                          size: 48,
                          status: user.status,
                        ),
                      ),
                      if (!follows)
                        Positioned(
                          bottom: -10,
                          left: 14,
                          child: GestureDetector(
                            onTap: () => s.toggleFollow(clip.author),
                            child: Container(
                              width: 20,
                              height: 20,
                              color: Px.accent,
                              child: PixelGlyph(
                                kind: PixelGlyphKind.add,
                                size: 12,
                                color: Px.bg,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _Action(
                    kind: PixelGlyphKind.heart,
                    color: liked ? Px.danger : Px.text,
                    label: compact(clip.likes + (liked ? 1 : 0)),
                    onTap: () {
                      final before = liked;
                      s.toggleLikeClip(clip.id);
                      if (!before) {
                        _heartBurst();
                      }
                    },
                  ),
                  _Action(
                    kind: PixelGlyphKind.comment,
                    label: compact(clip.comments),
                    onTap: () => _openComments(context, clip),
                  ),
                  _Action(
                    kind: PixelGlyphKind.share,
                    label: compact(clip.shares),
                    onTap: () => _openShare(context, clip),
                  ),
                  _Action(
                    kind: PixelGlyphKind.bookmark,
                    color: s.savedClips.contains(clip.id) ? Px.gold : Px.text,
                    label: 'Guardar',
                    onTap: () => s.toggleSaveClip(clip.id),
                  ),
                  const SizedBox(height: 8),
                  const _SpinningDisc(),
                ],
              ),
            ),
            // Texto inferior (por encima de la barra).
            Positioned(
              left: 14,
              right: 90,
              bottom: navClear,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (clip.author == AppState.I.username) return;
                          if (Mock.users.containsKey(clip.author)) {
                            openUserProfile(context, clip.author);
                          }
                        },
                        child: Text(
                          '@${user.name}',
                          style: Px.label(9, Px.accent),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => s.toggleSubscribe(clip.author),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          color:
                              s.subscribedTo.contains(clip.author)
                                  ? Px.accentDark
                                  : Px.magenta,
                          child: Text(
                            s.subscribedTo.contains(clip.author)
                                ? 'SUSCRITO'
                                : 'SUSCRIBIRSE',
                            style: Px.label(5, Px.text),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(clip.caption, style: Px.body),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      PixelGlyph(
                        kind: PixelGlyphKind.music,
                        size: 12,
                        color: Px.accent,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          clip.song,
                          style: Px.bodyDim,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _openComments(BuildContext context, Clip clip) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (_) => PixelPanel(
            shadow: false,
            child: SizedBox(
              height: 320,
              child: Column(
                children: [
                  Text(
                    '${compact(clip.comments)} COMENTARIOS',
                    style: Px.title(8),
                  ),
                  const SizedBox(height: 10),
                  const PixelDivider(),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final m in const [
                          Message('nova', 'este clip pega duro 🔥', 'hace 2 h'),
                          Message('kael', 'tutorial del baile pls', 'hace 1 h'),
                          Message('mara', 'guardeado 👑', 'hace 40 min'),
                        ])
                          ListTile(
                            leading: PixelAvatar(
                              config:
                                  Mock.users[m.author]?.avatar ??
                                  AppState.I.avatar,
                              size: 28,
                            ),
                            title: Text(
                              m.author,
                              style: Px.label(7, Px.accent),
                            ),
                            subtitle: Text(m.text, style: Px.body),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _openShare(BuildContext context, Clip clip) {
    final friends =
        AppState.I.friends.map((n) => Mock.users[n]).whereType<User>().toList();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (_) => PixelPanel(
            shadow: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('COMPARTIR CLIP', style: Px.title(8)),
                const SizedBox(height: 6),
                Text('Solo a amigos (chat privado)', style: Px.bodyDim),
                const SizedBox(height: 12),
                if (friends.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Agrega amigos para compartir por chat',
                      style: Px.bodyDim,
                    ),
                  )
                else
                  SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final u in friends)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () {
                                final ok = AppState.I.trySendDm(
                                  u.name,
                                  'mira este clip: ${clip.caption}',
                                );
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok
                                          ? 'Enviado a ${u.name}'
                                          : 'Solo amigos',
                                      style: Px.body,
                                    ),
                                    backgroundColor: Px.panelLight,
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  AvatarBadge(
                                    config: u.avatar,
                                    size: 48,
                                    status: u.status,
                                  ),
                                  Text(u.name, style: Px.label(5)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ListTile(
                  leading: PixelGlyph(
                    kind: PixelGlyphKind.link,
                    size: 18,
                    color: Px.accent,
                  ),
                  title: Text('Copiar enlace', style: Px.body),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Enlace · pixelgram.app/c/${clip.id}',
                          style: Px.body,
                        ),
                        backgroundColor: Px.panelLight,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.kind,
    required this.label,
    required this.onTap,
    this.color,
  });
  final PixelGlyphKind kind;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          PixelRoundIcon(
            kind: kind,
            size: 40,
            glyphSize: 18,
            color: color ?? Px.text,
            fill: const Color(0x99000000),
            borderColor: const Color(0x55FFFFFF),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Px.label(6, Px.text).copyWith(
              shadows: const [
                Shadow(color: Colors.black, offset: Offset(1, 1)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _SpinningDisc extends StatefulWidget {
  const _SpinningDisc();
  @override
  State<_SpinningDisc> createState() => _SpinningDiscState();
}

class _SpinningDiscState extends State<_SpinningDisc>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
    turns: _c,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Px.bg,
        shape: BoxShape.circle,
        border: Border.all(color: Px.border, width: 3),
      ),
      child: PixelGlyph(
        kind: PixelGlyphKind.music,
        size: 16,
        color: Px.accent,
      ),
    ),
  );
}
