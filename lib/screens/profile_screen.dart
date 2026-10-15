import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material show Clip;

import '../core/app_state.dart';
import '../core/mock_data.dart';
import '../core/pixel_theme.dart';
import '../core/room.dart';
import '../widgets/furniture_thumb.dart';
import '../widgets/local_image.dart'
    if (dart.library.io) '../widgets/local_image_io.dart';
import '../widgets/net_image.dart';
import '../widgets/pixel_avatar.dart';
import '../widgets/pixel_ui.dart';
import 'closet_screen.dart';
import 'connections_screen.dart';
import 'login_screen.dart';
import 'my_room_screen.dart';
import 'profile_edit_screen.dart';
import 'room_editor_screen.dart';
import 'visit_room_screen.dart';

/// Perfil propio: quién eres + atajos (closet / decorar / habitación) + posts.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _showSwitchAccount(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (_) => PixelPanel(
            shadow: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('CUENTA DEMO', style: Px.title(8)),
                const SizedBox(height: 6),
                Text(
                  'Cambia de personaje para probar visitas',
                  style: Px.bodyDim,
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: AvatarBadge(config: AppState.I.avatar, size: 40),
                  title: Text('viajero (tú)', style: Px.label(8, Px.accent)),
                  onTap: () {
                    AppState.I.switchDemoAccount(null);
                    Navigator.pop(context);
                  },
                ),
                for (final id in const ['nova', 'byte', 'kael', 'mara'])
                  ListTile(
                    leading: AvatarBadge(
                      config: Mock.users[id]!.avatar,
                      size: 40,
                      status: Mock.users[id]!.status,
                    ),
                    title: Text(id, style: Px.label(8)),
                    subtitle: Text(
                      Mock.users[id]!.bio,
                      style: Px.bodyDim,
                      maxLines: 1,
                    ),
                    onTap: () {
                      AppState.I.switchDemoAccount(id);
                      Navigator.pop(context);
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState.I;
    return Scaffold(
      body: ListenableBuilder(
        listenable: s,
        builder: (context, _) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              Stack(
                clipBehavior: material.Clip.none,
                children: [
                  PixelBanner(
                    index: s.room.banner,
                    height: 120,
                    imageUrl: s.bannerGif,
                    child: SafeArea(
                      bottom: false,
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PixelIconCard(
                              kind: PixelGlyphKind.sparkle,
                              ghost: true,
                              onTap: () {
                                showModalBottomSheet<void>(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => const ThemePickerSheet(),
                                );
                              },
                            ),
                            PixelIconCard(
                              kind: PixelGlyphKind.edit,
                              ghost: true,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const ProfileEditScreen(),
                                ),
                              ),
                            ),
                            PixelIconCard(
                              kind: PixelGlyphKind.settings,
                              ghost: true,
                              onTap: () {
                                showModalBottomSheet<void>(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  builder:
                                      (_) => PixelPanel(
                                        shadow: false,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('AJUSTES', style: Px.title(8)),
                                            ListTile(
                                              leading: PixelGlyph(
                                                kind: PixelGlyphKind.sparkle,
                                                color: Px.magenta,
                                                size: 18,
                                              ),
                                              title: Text(
                                                'Tema / colores',
                                                style: Px.body,
                                              ),
                                              subtitle: Text(
                                                'Oscuro, claro, rosa…',
                                                style: Px.bodyDim,
                                              ),
                                              onTap: () {
                                                Navigator.pop(context);
                                                showModalBottomSheet<void>(
                                                  context: context,
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  builder:
                                                      (_) =>
                                                          const ThemePickerSheet(),
                                                );
                                              },
                                            ),
                                            ListTile(
                                              leading: PixelGlyph(
                                                kind: PixelGlyphKind.edit,
                                                color: Px.accent,
                                                size: 18,
                                              ),
                                              title: Text(
                                                'Editar perfil',
                                                style: Px.body,
                                              ),
                                              onTap: () {
                                                Navigator.pop(context);
                                                Navigator.of(context).push(
                                                  MaterialPageRoute<void>(
                                                    builder:
                                                        (_) =>
                                                            const ProfileEditScreen(),
                                                  ),
                                                );
                                              },
                                            ),
                                            ListTile(
                                              leading: PixelGlyph(
                                                kind: PixelGlyphKind.room,
                                                color: Px.accent,
                                                size: 18,
                                              ),
                                              title: Text(
                                                'Mi habitación',
                                                style: Px.body,
                                              ),
                                              onTap: () {
                                                Navigator.pop(context);
                                                Navigator.of(context).push(
                                                  MaterialPageRoute<void>(
                                                    builder:
                                                        (_) =>
                                                            const MyRoomScreen(),
                                                  ),
                                                );
                                              },
                                            ),
                                            ListTile(
                                              leading: PixelGlyph(
                                                kind: PixelGlyphKind.people,
                                                color: Px.gold,
                                                size: 18,
                                              ),
                                              title: Text(
                                                'Cambiar cuenta demo',
                                                style: Px.body,
                                              ),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _showSwitchAccount(context);
                                              },
                                            ),
                                            ListTile(
                                              leading: PixelGlyph(
                                                kind: PixelGlyphKind.logout,
                                                color: Px.danger,
                                                size: 18,
                                              ),
                                              title: Text(
                                                'Cerrar sesión (demo)',
                                                style: Px.body,
                                              ),
                                              onTap: () {
                                                final name = AppState.I.username;
                                                Navigator.of(context).pop();
                                                Navigator.of(
                                                  context,
                                                ).pushAndRemoveUntil(
                                                  MaterialPageRoute<void>(
                                                    builder:
                                                        (_) => LoginScreen(
                                                          goodbye: name,
                                                        ),
                                                  ),
                                                  (_) => false,
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: -36,
                    child: AvatarBadge(
                      config: s.avatar,
                      size: 84,
                      rgb: true,
                      animate: true,
                      photo:
                          s.photoPath != null
                              ? localFileProvider(s.photoPath!)
                              : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 42),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: RgbText('@${s.username}', style: Px.title(12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(s.bio, style: Px.body),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _Stat(
                          '${s.myPosts.length + Mock.posts.where((p) => p.author == s.username).length}',
                          'POSTS',
                        ),
                        _Stat(
                          '${s.followersCount}',
                          'SEGUIDORES',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder:
                                    (_) =>
                                        const ConnectionsScreen(initialTab: 0),
                              ),
                            );
                          },
                        ),
                        _Stat(
                          '${s.followingCount}',
                          'SIGUIENDO',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder:
                                    (_) =>
                                        const ConnectionsScreen(initialTab: 1),
                              ),
                            );
                          },
                        ),
                        _Stat(
                          '${s.friendsCount}',
                          'AMIGOS',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder:
                                    (_) =>
                                        const ConnectionsScreen(initialTab: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _MiniAction(
                          kind: PixelGlyphKind.closet,
                          label: 'CLOSET',
                          color: Px.magenta,
                          onTap:
                              () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const ClosetScreen(),
                                ),
                              ),
                        ),
                        _MiniAction(
                          kind: PixelGlyphKind.chair,
                          label: 'DECORAR',
                          color: Px.accent,
                          onTap:
                              () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const RoomEditorScreen(),
                                ),
                              ),
                        ),
                        _MiniAction(
                          kind: PixelGlyphKind.room,
                          label: 'HABITACIÓN',
                          color: Px.gold,
                          onTap:
                              () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const MyRoomScreen(),
                                ),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('VISITAR', style: Px.title(8, Px.textDim)),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Entra al cuarto de un amigo',
                  style: Px.bodyDim,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 92,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final e in MockRooms.others.entries)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap:
                              () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder:
                                      (_) => VisitRoomScreen(
                                        hostName: e.key,
                                        room: e.value,
                                      ),
                                ),
                              ),
                          child: Column(
                            children: [
                              AvatarBadge(
                                config: Mock.users[e.key]!.avatar,
                                size: 56,
                                status: Mock.users[e.key]!.status,
                                rgb: true,
                              ),
                              const SizedBox(height: 6),
                              Text(e.key, style: Px.label(6, Px.text)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'PUBLICACIONES',
                  style: Px.title(8, Px.textDim),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Builder(
                  builder: (_) {
                    final posts = [
                      ...s.myPosts,
                      ...Mock.posts.where((p) => p.author == s.username),
                    ];
                    if (posts.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Aún no hay publicaciones',
                          style: Px.bodyDim,
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: posts.length.clamp(0, 12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                          ),
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => _openPost(context, posts[i]),
                        child: _PostThumb(post: posts[i]),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }
}

void _openPost(BuildContext context, Post post) {
  showDialog<void>(
    context: context,
    builder:
        (ctx) => Dialog(
          backgroundColor: Px.panel,
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child:
                      post.imageUrl != null || post.localPath != null
                          ? NetImage(
                            url: post.imageUrl,
                            localPath: post.localPath,
                            fit: BoxFit.cover,
                          )
                          : ColoredBox(
                            color: Px.bg,
                            child: Center(
                              child: PixelAvatar(
                                config: AppState.I.avatar,
                                size: 72,
                                animate: true,
                              ),
                            ),
                          ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RgbText('@${AppState.I.username}', style: Px.title(8)),
                      const SizedBox(height: 6),
                      Text(post.caption, style: Px.body),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: PixelButton(
                          label: 'CERRAR',
                          glyph: PixelGlyphKind.close,
                          onPressed: () => Navigator.pop(ctx),
                        ),
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

class _MiniAction extends StatelessWidget {
  const _MiniAction({
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            PixelRoundIcon(
              kind: kind,
              size: 40,
              color: color ?? Px.accent,
              borderColor: color ?? Px.accent,
            ),
            const SizedBox(height: 4),
            Text(label, style: Px.label(5, Px.textDim)),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label, {this.onTap});
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(value, style: Px.title(10)),
          Text(label, style: Px.label(5, Px.textDim)),
        ],
      ),
    ),
  );
}

class _PostThumb extends StatelessWidget {
  const _PostThumb({required this.post});
  final Post post;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Px.panelLight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (post.imageUrl != null)
            NetImage(url: post.imageUrl, fit: BoxFit.cover)
          else
            ColoredBox(
              color: Px.panel,
              child: Center(
                child: PixelAvatar(config: AppState.I.avatar, size: 36),
              ),
            ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: PixelGlyph(
                kind: PixelGlyphKind.heart,
                color: Px.text,
                size: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
