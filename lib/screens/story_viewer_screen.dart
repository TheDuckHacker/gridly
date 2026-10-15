import 'dart:math';

import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/mock_data.dart';
import '../core/nav.dart';
import '../core/pixel_theme.dart';
import '../widgets/net_image.dart';
import '../widgets/pixel_avatar.dart';
import '../widgets/pixel_ui.dart';
import 'filters.dart';

/// Visor de historias / estados (estilo Instagram).
class StoryViewerScreen extends StatefulWidget {
  const StoryViewerScreen({super.key, required this.startIndex});
  final int startIndex;

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late int _index;
  late final AnimationController _bar;
  List<Story> get _stories => AppState.I.allStories;

  @override
  void initState() {
    super.initState();
    _index = widget.startIndex.clamp(0, _stories.length - 1);
    _bar =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..addStatusListener((st) {
            if (st == AnimationStatus.completed) _next();
          })
          ..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _stories.isEmpty) return;
      AppState.I.markStoryViewed(_stories[_index].author);
    });
  }

  @override
  void dispose() {
    _bar.dispose();
    super.dispose();
  }

  void _next() {
    if (_index >= _stories.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _index++;
      _bar
        ..reset()
        ..forward();
    });
    AppState.I.markStoryViewed(_stories[_index].author);
  }

  void _prev() {
    if (_index <= 0) {
      _bar
        ..reset()
        ..forward();
      return;
    }
    setState(() {
      _index--;
      _bar
        ..reset()
        ..forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_stories.isEmpty) {
      return const Scaffold(body: Center(child: Text('Sin historias')));
    }
    final story = _stories[_index];
    final isMe = story.author == AppState.I.username;
    final user = isMe ? null : Mock.users[story.author];
    final cfg = user?.avatar ?? AppState.I.avatar;
    final name = isMe ? AppState.I.username : story.author;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (d) {
          final w = MediaQuery.sizeOf(context).width;
          if (d.localPosition.dx < w * 0.35) {
            _prev();
          } else {
            _next();
          }
        },
        onLongPressStart: (_) => _bar.stop(),
        onLongPressEnd: (_) => _bar.forward(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PixelFilter(
              name: story.filter,
              child:
                  story.imageUrl != null
                      ? _PhotoStory(story: story, cfg: cfg)
                      : _PixelStory(story: story, cfg: cfg),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (var i = 0; i < _stories.length; i++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: AnimatedBuilder(
                                animation: _bar,
                                builder: (_, __) {
                                  double v;
                                  if (i < _index) {
                                    v = 1;
                                  } else if (i > _index) {
                                    v = 0;
                                  } else {
                                    v = _bar.value;
                                  }
                                  return LinearProgressIndicator(
                                    value: v,
                                    minHeight: 3,
                                    backgroundColor: Colors.white24,
                                    color: Px.accent,
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (name != AppState.I.username &&
                                Mock.users.containsKey(name)) {
                              openUserProfile(context, name);
                            }
                          },
                          child: AvatarBadge(
                            config: cfg,
                            size: 36,
                            status: user?.status ?? PresenceStatus.online,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (name != AppState.I.username &&
                                  Mock.users.containsKey(name)) {
                                openUserProfile(context, name);
                              }
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: Px.label(8, Px.accent)),
                                Text(story.ago, style: Px.label(6)),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: PixelGlyph(
                            kind: PixelGlyphKind.close,
                            color: Px.text,
                            size: 18,
                          ),
                        ),
                      ],
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

/// Historia generada (avatar + texto sobre fondo pixel).
class _PixelStory extends StatelessWidget {
  const _PixelStory({required this.story, required this.cfg});
  final Story story;
  final AvatarConfig cfg;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StoryBg(hue: story.hue, seed: story.author.hashCode),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PixelAvatar(config: cfg, size: 100),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                story.caption,
                style: Px.title(10, Px.text),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Historia con foto real de internet + texto abajo.
class _PhotoStory extends StatelessWidget {
  const _PhotoStory({required this.story, required this.cfg});
  final Story story;
  final AvatarConfig cfg;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        NetImage(
          url: story.imageUrl,
          fallback: _PixelStory(story: story, cfg: cfg),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.center,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xCC000000)],
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 110,
          child: Text(
            story.caption,
            style: Px.title(10, Px.text),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _StoryBg extends CustomPainter {
  const _StoryBg({required this.hue, required this.seed});
  final double hue;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(seed);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = HSVColor.fromAHSV(1, hue, 0.55, 0.35).toColor(),
    );
    for (var i = 0; i < 40; i++) {
      final c = Px.rgb[i % Px.rgb.length].withValues(alpha: 0.25);
      final px = 4.0 + rnd.nextDouble() * 12;
      canvas.drawRect(
        Rect.fromLTWH(
          rnd.nextDouble() * size.width,
          rnd.nextDouble() * size.height,
          px,
          px,
        ),
        Paint()..color = c,
      );
    }
  }

  @override
  bool shouldRepaint(_StoryBg old) => old.hue != hue || old.seed != seed;
}
