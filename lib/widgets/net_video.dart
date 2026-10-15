import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../core/media.dart';
import '../core/pixel_theme.dart';
import 'pixel_ui.dart';

/// Video en bucle (asset local o link http), estilo clip.
///
/// Solo crea el reproductor cuando [active] es true.
/// En web, espera al primer frame y atrapa fallos de media_kit.
class NetVideo extends StatefulWidget {
  const NetVideo({
    super.key,
    required this.url,
    this.active = true,
    this.muted = false,
    this.fit = BoxFit.cover,
    this.onTap,
    this.onDoubleTap,
  });

  final String url;
  final bool active;
  final bool muted;
  final BoxFit fit;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  @override
  State<NetVideo> createState() => NetVideoState();
}

class NetVideoState extends State<NetVideo> {
  Player? _player;
  VideoController? _controller;
  bool _error = false;
  bool _paused = false;
  bool _ready = false;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.active) _start();
      });
    }
  }

  Future<void> _start() async {
    if (_player != null || !mounted || _starting) return;
    _starting = true;
    setState(() {
      _error = false;
      _ready = false;
    });

    // En web el engine a veces aún no tiene view/size → esperar un frame más.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      _starting = false;
      return;
    }
    final size = MediaQuery.sizeOf(context);
    if (size.width < 2 || size.height < 2) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (!mounted) {
        _starting = false;
        return;
      }
    }

    Player? player;
    VideoController? controller;
    try {
      player = Player(
        configuration: const PlayerConfiguration(title: 'Gridly'),
      );
      controller = VideoController(player);
      _player = player;
      _controller = controller;
      if (mounted) setState(() {});

      player.stream.width.listen((w) {
        if (!mounted || w == null || w <= 0) return;
        if (!_ready) setState(() => _ready = true);
      });
      player.stream.playing.listen((playing) {
        if (!mounted) return;
        if (playing && !_ready) setState(() => _ready = true);
      });

      await player.setPlaylistMode(PlaylistMode.loop);
      await player.setVolume(widget.muted ? 0 : 100);
      final uri = MediaEnv.playableUri(widget.url);
      await player.open(Media(uri), play: widget.active && !_paused);
      if (mounted) setState(() => _ready = true);
    } catch (e, st) {
      debugPrint('NetVideo error: $e\n$st');
      try {
        await player?.dispose();
      } catch (_) {}
      if (!mounted) {
        _starting = false;
        return;
      }
      setState(() {
        _player = null;
        _controller = null;
        _error = true;
      });
    } finally {
      _starting = false;
    }
  }

  Future<void> _stop() async {
    final p = _player;
    _player = null;
    _controller = null;
    _ready = false;
    if (p != null) {
      try {
        await p.dispose();
      } catch (_) {}
    }
  }

  @override
  void didUpdateWidget(covariant NetVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _paused = false;
      _stop().then((_) {
        if (mounted && widget.active) _start();
      });
      return;
    }
    if (oldWidget.active != widget.active) {
      if (widget.active) {
        _paused = false;
        if (_player == null) {
          _start();
        } else {
          _player!.play();
        }
      } else {
        _player?.pause();
        _stop().then((_) {
          if (mounted) setState(() {});
        });
      }
    }
    if (oldWidget.muted != widget.muted) {
      _player?.setVolume(widget.muted ? 0 : 100);
    }
  }

  void togglePause() {
    final p = _player;
    if (p == null) return;
    setState(() => _paused = !_paused);
    _paused ? p.pause() : p.play();
  }

  @override
  void dispose() {
    final p = _player;
    _player = null;
    _controller = null;
    p?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        togglePause();
        widget.onTap?.call();
      },
      onDoubleTap: widget.onDoubleTap,
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_controller != null && !_error)
              Video(
                controller: _controller!,
                fit: widget.fit,
                controls: NoVideoControls,
                fill: Colors.black,
              ),
            if (_error)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PixelGlyph(
                        kind: PixelGlyphKind.play,
                        size: 28,
                        color: Px.textDim,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        kIsWeb
                            ? 'VIDEO (abre en Windows/Android\npara clips completos)'
                            : 'VIDEO NO DISPONIBLE',
                        style: Px.label(7, Px.textDim),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else if (!_ready)
              Center(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    color: Px.accent,
                    strokeWidth: 3,
                  ),
                ),
              ),
            if (_paused && !_error && _ready)
              Center(
                child: PixelGlyph(
                  kind: PixelGlyphKind.play,
                  size: 48,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
