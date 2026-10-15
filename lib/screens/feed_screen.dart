import 'dart:math';

import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/mock_data.dart';
import '../core/nav.dart';
import '../core/pixel_theme.dart';
import '../core/sfx.dart';
import '../widgets/net_image.dart';
import '../widgets/pixel_avatar.dart';
import '../widgets/pixel_ui.dart';
import 'create_story_screen.dart';
import 'filters.dart';
import 'story_viewer_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key, this.playEntrance = false});

  final bool playEntrance;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
      value: widget.playEntrance ? 0 : 1,
    );
    _fade = CurvedAnimation(parent: _enter, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic));
    if (widget.playEntrance) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _enter.forward();
      });
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState.I;
    return Scaffold(
      body: ListenableBuilder(
        listenable: s,
        builder: (_, __) {
          final feed = [...s.myPosts, ...Mock.posts];
          return FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: RefreshIndicator(
            color: Px.accent,
            backgroundColor: Px.panel,
            onRefresh: () async {
              await Sfx.I.tap();
              await Future<void>.delayed(const Duration(milliseconds: 600));
              if (mounted) setState(() {});
            },
            child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              const _StoriesRow(),
              if (feed.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                  child: Column(
                    children: [
                      PixelGlyph(
                        kind: PixelGlyphKind.people,
                        size: 28,
                        color: Px.textDim,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No hay posts todavía',
                        style: Px.bodyDim,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tira hacia abajo para refrescar',
                        style: Px.label(6, Px.textDim),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                for (final p in feed) _PostCard(post: p),
            ],
          ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StoriesRow extends StatelessWidget {
  const _StoriesRow();

  @override
  Widget build(BuildContext context) {
    final s = AppState.I;
    return Container(
      height: 96,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Px.border, width: 2)),
      ),
      child: ListenableBuilder(
        listenable: s,
        builder:
            (_, __) => ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              children: [
                _Story(
                  name: 'tú',
                  config: s.avatar,
                  mine: true,
                  hasStory: s.myStories.isNotEmpty,
                  viewed: false,
                  onTap: () async {
                    if (s.myStories.isNotEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder:
                              (_) => const StoryViewerScreen(startIndex: 0),
                        ),
                      );
                      return;
                    }
                    final ok = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const CreateStoryScreen(),
                      ),
                    );
                    if (ok == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Historia publicada', style: Px.body),
                          backgroundColor: Px.panelLight,
                        ),
                      );
                    }
                  },
                  onAdd: () async {
                    final ok = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const CreateStoryScreen(),
                      ),
                    );
                    if (ok == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Historia publicada', style: Px.body),
                          backgroundColor: Px.panelLight,
                        ),
                      );
                    }
                  },
                ),
                for (var i = 0; i < Mock.stories.length; i++)
                  if (s.following.contains(Mock.stories[i].author) ||
                      s.friends.contains(Mock.stories[i].author))
                    _Story(
                      name: Mock.stories[i].author,
                      config: Mock.users[Mock.stories[i].author]!.avatar,
                      status: Mock.users[Mock.stories[i].author]!.status,
                      viewed: s.viewedStories.contains(Mock.stories[i].author),
                      onTap: () {
                        final author = Mock.stories[i].author;
                        final start = s.allStories.indexWhere(
                          (st) => st.author == author,
                        );
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => StoryViewerScreen(
                              startIndex: start < 0 ? 0 : start,
                            ),
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

class _Story extends StatelessWidget {
  const _Story({
    required this.name,
    required this.config,
    this.mine = false,
    this.hasStory = false,
    this.status = PresenceStatus.online,
    this.viewed = false,
    this.onTap,
    this.onAdd,
  });
  final String name;
  final AvatarConfig config;
  final bool mine;
  final bool hasStory;
  final PresenceStatus status;
  final bool viewed;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final showRing = mine ? hasStory : !viewed;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            SizedBox(
              width: 58,
              height: 58,
              child: Stack(
                children: [
                  ListenableBuilder(
                    listenable: RgbClock.I,
                    builder: (_, __) {
                      final c0 = RgbClock.I.at(0);
                      final c1 = RgbClock.I.at(0.33);
                      final c2 = RgbClock.I.at(0.66);
                      return Container(
                        width: 58,
                        height: 58,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: showRing ? c0 : Px.border,
                            width: 3,
                          ),
                          gradient:
                              showRing
                                  ? LinearGradient(colors: [c0, c1, c2])
                                  : null,
                          color: showRing ? null : Px.border,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Px.bg,
                            border: Border.all(color: Px.bg, width: 2),
                          ),
                          child: ClipOval(
                            child: ColoredBox(
                              color: Px.panelLight,
                              child: Center(
                                child: PixelAvatar(
                                  config: config,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  if (mine)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: onAdd,
                        child: Container(
                          width: 18,
                          height: 18,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Px.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Px.bg, width: 2),
                          ),
                          child: PixelGlyph(
                            kind: PixelGlyphKind.plus,
                            size: 10,
                            color: Px.bg,
                          ),
                        ),
                      ),
                    )
                  else
                    Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: status.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Px.bg, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(name, style: Px.label(6, mine ? Px.accent : Px.textDim)),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatefulWidget {
  const _PostCard({required this.post});
  final Post post;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heartCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _heartScale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.4, end: 1.2), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 25),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
  ]).animate(CurvedAnimation(parent: _heartCtrl, curve: Curves.easeOut));
  final _bits = <_LikeBit>[];

  @override
  void dispose() {
    _heartCtrl.dispose();
    super.dispose();
  }

  void _burstLike() {
    final s = AppState.I;
    if (!s.likedPosts.contains(widget.post.id)) {
      s.toggleLikePost(widget.post.id);
    }
    Sfx.I.tap();
    final rnd = Random();
    setState(() {
      _bits
        ..clear()
        ..addAll(
          List.generate(10, (i) {
            final a = rnd.nextDouble() * pi * 2;
            final d = 28.0 + rnd.nextDouble() * 36;
            return _LikeBit(
              dx: cos(a) * d,
              dy: sin(a) * d,
              color: Px.rgb[i % Px.rgb.length],
            );
          }),
        );
    });
    _heartCtrl.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _bits.clear());
    });
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isMine =
        post.author == AppState.I.username ||
        !Mock.users.containsKey(post.author);
    final user =
        isMine
            ? User(
              AppState.I.username,
              AppState.I.avatar,
              PresenceStatus.online,
            )
            : Mock.users[post.author]!;
    final s = AppState.I;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final liked = s.likedPosts.contains(post.id);
        final saved = s.savedPosts.contains(post.id);
        final reposted = s.repostedPosts.contains(post.id);
        final follows = s.following.contains(post.author);
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
          child: PixelPanel(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (reposted)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                    child: Row(
                      children: [
                        PixelGlyph(
                          kind: PixelGlyphKind.repost,
                          size: 10,
                          color: Px.accentDim,
                        ),
                        const SizedBox(width: 6),
                        Text('Reposteaste', style: Px.label(6, Px.accentDim)),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap:
                            isMine
                                ? null
                                : () => openUserProfile(context, user.name),
                        child: AvatarBadge(
                          config: user.avatar,
                          size: 36,
                          status: user.status,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap:
                              isMine
                                  ? null
                                  : () => openUserProfile(context, user.name),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name, style: Px.label(8, Px.accent)),
                              Text(post.ago, style: Px.bodyDim),
                            ],
                          ),
                        ),
                      ),
                      if (!isMine)
                        PixelChip(
                          label: follows ? 'SIGUIENDO' : 'SEGUIR',
                          selected: follows,
                          onTap: () {
                            s.toggleFollow(post.author);
                            Sfx.I.tap();
                          },
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onDoubleTap: _burstLike,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _PostImage(post: post, author: user.avatar),
                      IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _heartCtrl,
                          builder: (_, __) {
                            final t = _heartCtrl.value;
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                for (final b in _bits)
                                  Transform.translate(
                                    offset: Offset(b.dx * t, b.dy * t),
                                    child: Opacity(
                                      opacity: (1 - t).clamp(0, 1),
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        color: b.color,
                                      ),
                                    ),
                                  ),
                                FadeTransition(
                                  opacity: _heartScale,
                                  child: ScaleTransition(
                                    scale: _heartScale,
                                    child: PixelGlyph(
                                      kind: PixelGlyphKind.heart,
                                      size: 56,
                                      color: Px.danger,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
                  child: Row(
                    children: [
                      PixelIconBtn(
                        kind: PixelGlyphKind.heart,
                        size: 18,
                        color: liked ? Px.danger : Px.text,
                        onPressed: () {
                          s.toggleLikePost(post.id);
                          Sfx.I.tap();
                        },
                      ),
                      Text(
                        compact(post.likes + (liked ? 1 : 0)),
                        style: Px.body,
                      ),
                      PixelIconBtn(
                        kind: PixelGlyphKind.comment,
                        size: 18,
                        onPressed: () => _openComments(context, post),
                      ),
                      Text('${post.comments}', style: Px.body),
                      PixelIconBtn(
                        kind: PixelGlyphKind.share,
                        size: 18,
                        onPressed: () => _openShare(context, post),
                      ),
                      PixelIconBtn(
                        kind: PixelGlyphKind.repost,
                        size: 18,
                        color: reposted ? Px.accent : Px.text,
                        onPressed: () {
                          s.toggleRepost(post.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                reposted ? 'Repost quitado' : '¡Republicado!',
                                style: Px.body,
                              ),
                              backgroundColor: Px.panelLight,
                              duration: const Duration(milliseconds: 900),
                            ),
                          );
                        },
                      ),
                      const Spacer(),
                      PixelIconBtn(
                        kind: PixelGlyphKind.bookmark,
                        size: 18,
                        color: saved ? Px.gold : Px.text,
                        onPressed: () => s.toggleSavePost(post.id),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                  child: Text(
                    '${compact(post.reposts)} reposts',
                    style: Px.label(6),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${user.name}  ',
                          style: Px.label(7, Px.accent),
                        ),
                        TextSpan(text: post.caption, style: Px.body),
                      ],
                    ),
                  ),
                ),
                if (post.comments > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: GestureDetector(
                      onTap: () => _openComments(context, post),
                      child: Text(
                        'Ver los ${post.comments} comentarios',
                        style: Px.label(6, Px.textDim),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openComments(BuildContext context, Post post) {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: PixelPanel(
            shadow: false,
            child: SizedBox(
              height: MediaQuery.sizeOf(ctx).height * 0.55,
              child: ListenableBuilder(
                listenable: AppState.I,
                builder: (_, __) {
                  final comments = Mock.postComments[post.id] ?? [];
                  return Column(
                    children: [
                      Text('COMENTARIOS', style: Px.title(8)),
                      const SizedBox(height: 8),
                      const PixelDivider(),
                      Expanded(
                        child: ListView.builder(
                          itemCount: comments.length,
                          itemBuilder: (_, i) {
                            final c = comments[i];
                            final u = Mock.users[c.author];
                            final cfg = u?.avatar ?? AppState.I.avatar;
                            return ListTile(
                              onTap: () {
                                if (Mock.users.containsKey(c.author)) {
                                  openUserProfile(context, c.author);
                                }
                              },
                              leading: PixelAvatar(config: cfg, size: 28),
                              title: Text(
                                c.author,
                                style: Px.label(7, Px.accent),
                              ),
                              subtitle: Text(c.text, style: Px.body),
                              trailing: Text(c.ago, style: Px.label(5)),
                            );
                          },
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              style: Px.body,
                              cursorColor: Px.accent,
                              decoration: InputDecoration(
                                hintText: 'Escribe un comentario…',
                                hintStyle: Px.bodyDim,
                                filled: true,
                                fillColor: Px.bg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.zero,
                                  borderSide: BorderSide(
                                    color: Px.border,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PixelButton(
                            label: '',
                            glyph: PixelGlyphKind.send,
                            small: true,
                            onPressed: () {
                              final t = controller.text.trim();
                              if (t.isEmpty) return;
                              AppState.I.addComment(post.id, t);
                              controller.clear();
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _openShare(BuildContext context, Post post) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (_) => PixelPanel(
            shadow: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('COMPARTIR', style: Px.title(8)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final name in AppState.I.friends)
                        if (Mock.users[name] != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () {
                                final u = Mock.users[name]!;
                                final ok = AppState.I.trySendDm(
                                  u.name,
                                  'mira este post: ${post.caption}',
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
                                    config: Mock.users[name]!.avatar,
                                    size: 48,
                                    status: Mock.users[name]!.status,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(name, style: Px.label(5)),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
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
                          'Enlace copiado · pixelgram.app/p/${post.id}',
                          style: Px.body,
                        ),
                        backgroundColor: Px.panelLight,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: PixelGlyph(
                    kind: PixelGlyphKind.repost,
                    size: 18,
                    color:
                        AppState.I.repostedPosts.contains(post.id)
                            ? Px.accent
                            : Px.text,
                  ),
                  title: Text('Republicar', style: Px.body),
                  onTap: () {
                    AppState.I.toggleRepost(post.id);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }
}

class _LikeBit {
  const _LikeBit({required this.dx, required this.dy, required this.color});
  final double dx;
  final double dy;
  final Color color;
}

class _PostImage extends StatelessWidget {
  const _PostImage({required this.post, required this.author});
  final Post post;
  final AvatarConfig author;

  @override
  Widget build(BuildContext context) {
    final scene = _PixelScene(post: post, author: author);
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRect(
        child: PixelFilter(
          name: post.filter,
          child:
              post.hasMedia
                  ? NetImage(
                    url: post.imageUrl,
                    localPath: post.localPath,
                    fallback: scene,
                  )
                  : scene,
        ),
      ),
    );
  }
}

/// Escena pixel generada (cuando el post no tiene foto real).
class _PixelScene extends StatelessWidget {
  const _PixelScene({required this.post, required this.author});
  final Post post;
  final AvatarConfig author;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: Px.bg),
        if (post.hue != 0)
          ColoredBox(
            color: HSVColor.fromAHSV(0.25, post.hue, 0.7, 0.9).toColor(),
          ),
        CustomPaint(painter: _NightSky(seed: post.id.hashCode)),
        for (final layer in const [
          'parallax/city_far.png',
          'parallax/city_near.png',
          'parallax/street.png',
          'parallax/road.png',
        ])
          Align(
            alignment: Alignment((post.hue / 180) - 1, 1),
            child: Image.asset(
              'assets/images/$layer',
              fit: BoxFit.fitHeight,
              filterQuality: FilterQuality.none,
            ),
          ),
        Align(
          alignment: const Alignment(-0.2, 0.68),
          child: PixelAvatar(config: author, size: 72, animate: true),
        ),
      ],
    );
  }
}

class _NightSky extends CustomPainter {
  const _NightSky({required this.seed});
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(seed);
    final px = (size.width / 90).clamp(2.0, 8.0);
    final star = Paint()..color = Px.text.withValues(alpha: 0.75);
    final dim = Paint()..color = Px.textDim.withValues(alpha: 0.5);
    for (var i = 0; i < 70; i++) {
      final x = (rnd.nextDouble() * size.width / px).floor() * px;
      final y = (rnd.nextDouble() * size.height * 0.62 / px).floor() * px;
      canvas.drawRect(Rect.fromLTWH(x, y, px, px), i.isEven ? star : dim);
    }
    final mx = size.width * (0.2 + rnd.nextDouble() * 0.6);
    final my = size.height * 0.16;
    final r = px * 6;
    final moon = Paint()..color = Px.text;
    final crater = Paint()..color = Px.textDim;
    for (var dx = -r; dx <= r; dx += px) {
      for (var dy = -r; dy <= r; dy += px) {
        if (dx * dx + dy * dy <= r * r) {
          canvas.drawRect(Rect.fromLTWH(mx + dx, my + dy, px, px), moon);
        }
      }
    }
    canvas.drawRect(
      Rect.fromLTWH(mx - px * 2, my - px, px * 2, px * 2),
      crater,
    );
    canvas.drawRect(Rect.fromLTWH(mx + px * 2, my + px * 2, px, px), crater);
  }

  @override
  bool shouldRepaint(_NightSky old) => old.seed != seed;
}
