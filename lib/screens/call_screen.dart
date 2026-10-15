import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/mock_data.dart';
import '../core/nav.dart';
import '../core/pixel_theme.dart';
import '../core/sfx.dart';
import '../game/avatar_component.dart';
import '../game/room_game.dart';
import '../widgets/pixel_avatar.dart';
import '../widgets/pixel_ui.dart';

/// Llamada / videollamada.
/// - Voz: habitación Flame (puerta abierta).
/// - Video: escenario ligero (sin Flame) para no congelar, esp. en web.
class CallScreen extends StatefulWidget {
  const CallScreen({super.key, required this.peer, this.video = false});
  final String peer;
  final bool video;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  late DateTime _started;
  Timer? _ticker;
  Timer? _emoteTimer;
  AnimationController? _door;
  RoomGame? _game;
  bool _doorDone = false;
  bool _peerInside = false;
  final ValueNotifier<String> _clock = ValueNotifier('00:00');

  bool get _useRoom => !widget.video && !kIsWeb;

  String? get _peerKey => AppState.I.resolveUserKey(widget.peer);

  @override
  void initState() {
    super.initState();
    final s = AppState.I;
    if (s.callWith == null) {
      s.startCall(widget.peer, video: widget.video);
    } else if (widget.video && !s.callIsVideo) {
      s.startCall(widget.peer, video: true);
    }

    if (_useRoom) {
      _game = RoomGame(config: s.room, me: s.avatar, myName: s.username);
      _door = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      )..forward().whenComplete(() {
        if (!mounted) return;
        setState(() => _doorDone = true);
        _letPeerIn();
      });
      _game!.loaded.then((_) {
        if (!mounted) return;
        _game!.emote(AvatarMood.wave);
      });
      CallEmoteBus.listen((mood) {
        if (mounted) _game?.emote(mood);
      });
    } else {
      _doorDone = true;
      // Entrada rápida sin animación pesada.
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (mounted) setState(() => _peerInside = true);
      });
    }

    _started = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final e = DateTime.now().difference(_started);
      final m = e.inMinutes.toString().padLeft(2, '0');
      final sec = (e.inSeconds % 60).toString().padLeft(2, '0');
      _clock.value = '$m:$sec';
    });
  }

  void _letPeerIn() {
    final game = _game;
    if (game == null) return;
    final key = _peerKey;
    final s = AppState.I;
    game.loaded.then((_) {
      if (!mounted) return;
      if (key != null && Mock.users.containsKey(key)) {
        final u = Mock.users[key]!;
        game.addVisitor(
          key,
          u.avatar,
          phrases: [
            'puerta abierta',
            'en llamada',
            'hola ${s.username}',
          ],
        );
        game.sayMe('entra $key');
        setState(() => _peerInside = true);
      } else {
        final guests = s.roomInvites.isEmpty ? s.onlineFriends : s.roomInvites;
        for (final name in guests.take(2)) {
          final u = Mock.users[name];
          if (u == null) continue;
          game.addVisitor(name, u.avatar, phrases: ['en la call', 'hola']);
        }
        setState(() => _peerInside = true);
      }
      _emoteTimer = Timer.periodic(const Duration(seconds: 8), (_) {
        if (!mounted) return;
        _game?.emote(
          [
            AvatarMood.wave,
            AvatarMood.dance,
            AvatarMood.jump,
            AvatarMood.sit,
          ][DateTime.now().second % 4],
        );
      });
    });
  }

  @override
  void dispose() {
    CallEmoteBus.clear();
    _ticker?.cancel();
    _emoteTimer?.cancel();
    _door?.dispose();
    _clock.dispose();
    final g = _game;
    _game = null;
    try {
      g?.pauseEngine();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState.I;
    final key = _peerKey;
    final user = key != null ? Mock.users[key] : null;
    final topPad = MediaQuery.paddingOf(context).top;
    final video = s.callIsVideo || widget.video;

    return Scaffold(
      backgroundColor: Px.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              _CallHeader(
                topPad: topPad,
                peerName: widget.peer,
                peer: user,
                me: s.avatar,
                video: video,
                peerInside: _peerInside,
                clock: _clock,
                onBack: () => Navigator.of(context).pop(),
                onProfile:
                    key == null ? null : () => openUserProfile(context, key),
              ),
              Expanded(
                child:
                    video
                        ? _LightVideoStage(
                          peer: user,
                          me: s.avatar,
                          peerName: widget.peer,
                          peerInside: _peerInside,
                          cameraOn: s.cameraOn,
                        )
                        : (_game != null
                            ? GameWidget(game: _game!)
                            : const ColoredBox(color: Colors.black)),
              ),
              _CallControls(
                video: video,
                onHang: () {
                  Sfx.I.tap();
                  s.endCall();
                  if (mounted) Navigator.of(context).pop();
                },
              ),
            ],
          ),
          if (_useRoom && !_doorDone && _door != null)
            _DoorOverlay(
              animation: _door!,
              peer: user,
              me: s.avatar,
              video: false,
              peerName: widget.peer,
            ),
        ],
      ),
    );
  }
}

/// Escenario de videollamada SIN Flame (no congela).
class _LightVideoStage extends StatelessWidget {
  const _LightVideoStage({
    required this.peer,
    required this.me,
    required this.peerName,
    required this.peerInside,
    required this.cameraOn,
  });

  final User? peer;
  final AvatarConfig me;
  final String peerName;
  final bool peerInside;
  final bool cameraOn;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0A0A16), Color(0xFF16122A), Color(0xFF0C1018)],
            ),
          ),
        ),
        // Peer grande al centro.
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (peer != null)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Px.accent, width: 3),
                  ),
                  child: AvatarBadge(
                    config: peer!.avatar,
                    size: 120,
                    status: peer!.status,
                    animate: peerInside,
                  ),
                )
              else
                PixelGlyph(
                  kind: PixelGlyphKind.video,
                  size: 48,
                  color: Px.accent,
                ),
              const SizedBox(height: 14),
              Text(
                peerName.toUpperCase(),
                style: Px.title(10),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                peerInside ? 'EN VIVO' : 'CONECTANDO…',
                style: Px.label(7, peerInside ? Px.online : Px.gold),
              ),
            ],
          ),
        ),
        // PiP tú.
        Positioned(
          right: 14,
          bottom: 14,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Px.panel.withValues(alpha: 0.95),
              border: Border.all(
                color: cameraOn ? Px.magenta : Px.danger,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (cameraOn)
                  AvatarBadge(config: me, size: 64, animate: false)
                else
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: ColoredBox(
                      color: Px.bg,
                      child: Center(
                        child: PixelGlyph(
                          kind: PixelGlyphKind.videoOff,
                          size: 22,
                          color: Px.danger,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text('TÚ', style: Px.label(5, Px.magenta)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CallHeader extends StatelessWidget {
  const _CallHeader({
    required this.topPad,
    required this.peerName,
    required this.peer,
    required this.me,
    required this.video,
    required this.peerInside,
    required this.clock,
    required this.onBack,
    this.onProfile,
  });

  final double topPad;
  final String peerName;
  final User? peer;
  final AvatarConfig me;
  final bool video;
  final bool peerInside;
  final ValueNotifier<String> clock;
  final VoidCallback onBack;
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, topPad + 6, 8, 10),
      decoration: BoxDecoration(
        color: Px.panel,
        border: Border(bottom: BorderSide(color: Px.border, width: 2)),
      ),
      child: Row(
        children: [
          PixelIconBtn(
            kind: PixelGlyphKind.back,
            color: Px.text,
            tooltip: 'Minimizar',
            onPressed: onBack,
          ),
          const SizedBox(width: 4),
          if (peer != null)
            GestureDetector(
              onTap: onProfile,
              child: AvatarBadge(
                config: peer!.avatar,
                size: 36,
                status: peer!.status,
              ),
            )
          else
            AvatarBadge(config: me, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PixelGlyph(
                      kind:
                          video ? PixelGlyphKind.video : PixelGlyphKind.call,
                      size: 12,
                      color: Px.accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      video ? 'VIDEOLLAMADA' : 'LLAMADA',
                      style: Px.label(6, Px.accent),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  peerName,
                  style: Px.label(8, Px.text),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  peerInside ? 'Conectado' : 'Conectando…',
                  style: Px.label(5, Px.textDim),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Px.bg,
              border: Border.all(color: Px.border, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PixelGlyph(
                  kind: PixelGlyphKind.wait,
                  size: 10,
                  color: Px.gold,
                ),
                const SizedBox(width: 6),
                ValueListenableBuilder<String>(
                  valueListenable: clock,
                  builder:
                      (_, v, __) => Text(v, style: Px.label(7, Px.gold)),
                ),
              ],
            ),
          ),
          if (onProfile != null)
            PixelIconBtn(
              kind: PixelGlyphKind.contact,
              color: Px.magenta,
              tooltip: 'Ver perfil',
              onPressed: () => onProfile!(),
            ),
        ],
      ),
    );
  }
}

class _DoorOverlay extends StatelessWidget {
  const _DoorOverlay({
    required this.animation,
    required this.peer,
    required this.me,
    required this.video,
    required this.peerName,
  });

  final Animation<double> animation;
  final User? peer;
  final AvatarConfig me;
  final bool video;
  final String peerName;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final t = Curves.easeInOutCubic.transform(animation.value);
        final w = MediaQuery.sizeOf(context).width;
        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: Px.bg.withValues(alpha: 1 - t * 0.9)),
            Align(
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: Offset(-w * 0.5 * t, 0),
                child: Container(
                  width: w * 0.5,
                  color: Px.panel,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PixelGlyph(
                        kind: PixelGlyphKind.call,
                        color: Px.accent,
                        size: 32,
                      ),
                      const SizedBox(height: 10),
                      Text('ABRIENDO', style: Px.title(9)),
                      const SizedBox(height: 8),
                      if (peer != null)
                        AvatarBadge(
                          config: peer!.avatar,
                          size: 64,
                          status: peer!.status,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Transform.translate(
                offset: Offset(w * 0.5 * t, 0),
                child: Container(
                  width: w * 0.5,
                  color: Px.panelLight,
                  alignment: Alignment.center,
                  child: AvatarBadge(config: me, size: 64),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CallControls extends StatelessWidget {
  const _CallControls({required this.onHang, required this.video});
  final VoidCallback onHang;
  final bool video;

  @override
  Widget build(BuildContext context) {
    final s = AppState.I;
    return ListenableBuilder(
      listenable: s,
      builder: (_, __) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            12,
            10,
            12,
            MediaQuery.paddingOf(context).bottom + 12,
          ),
          decoration: BoxDecoration(
            color: Px.panel,
            border: Border(top: BorderSide(color: Px.border, width: 2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!video)
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final e in [
                        (PixelGlyphKind.people, 'HOLA', AvatarMood.wave),
                        (PixelGlyphKind.music, 'BAILE', AvatarMood.dance),
                        (PixelGlyphKind.star, 'SALTO', AvatarMood.jump),
                        (PixelGlyphKind.chair, 'SENTAR', AvatarMood.sit),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () {
                              Sfx.I.tap();
                              CallEmoteBus.fire(e.$3);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Px.bg,
                                border: Border.all(
                                  color: Px.border,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  PixelGlyph(
                                    kind: e.$1,
                                    size: 12,
                                    color: Px.accent,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(e.$2, style: Px.label(6)),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              if (!video) const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CallBtn(
                    kind: s.muted ? PixelGlyphKind.micOff : PixelGlyphKind.mic,
                    label: s.muted ? 'MUTE' : 'MIC',
                    active: !s.muted,
                    danger: s.muted,
                    onTap: () {
                      Sfx.I.tap();
                      s.toggleMute();
                    },
                  ),
                  _CallBtn(
                    kind:
                        s.speakerOn
                            ? PixelGlyphKind.speaker
                            : PixelGlyphKind.speakerOff,
                    label: 'ALT',
                    active: s.speakerOn,
                    onTap: () {
                      Sfx.I.tap();
                      s.toggleSpeaker();
                    },
                  ),
                  if (video)
                    _CallBtn(
                      kind:
                          s.cameraOn
                              ? PixelGlyphKind.video
                              : PixelGlyphKind.videoOff,
                      label: 'CAM',
                      active: s.cameraOn,
                      danger: !s.cameraOn,
                      onTap: () {
                        Sfx.I.tap();
                        s.toggleCamera();
                      },
                    ),
                  _CallBtn(
                    kind: PixelGlyphKind.hangup,
                    label: 'COLGAR',
                    active: false,
                    danger: true,
                    wide: true,
                    onTap: onHang,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class CallEmoteBus {
  static void Function(AvatarMood)? _handler;
  static void listen(void Function(AvatarMood) h) => _handler = h;
  static void clear() => _handler = null;
  static void fire(AvatarMood m) => _handler?.call(m);
}

class _CallBtn extends StatelessWidget {
  const _CallBtn({
    required this.kind,
    required this.label,
    required this.onTap,
    this.active = true,
    this.danger = false,
    this.wide = false,
  });

  final PixelGlyphKind kind;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool danger;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final bg = danger ? Px.danger : (active ? Px.accent : Px.panelLight);
    final fg = danger || active ? Px.bg : Px.text;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: wide ? 64 : 54,
            height: 54,
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(
                color: danger ? Px.danger : (active ? Px.accent : Px.border),
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: PixelGlyph(kind: kind, color: fg, size: 28),
          ),
          const SizedBox(height: 4),
          Text(label, style: Px.label(5, danger ? Px.danger : Px.textDim)),
        ],
      ),
    );
  }
}
