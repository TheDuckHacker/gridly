import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material show Clip;

import '../core/app_state.dart';
import '../core/mock_data.dart';
import '../core/pixel_theme.dart';
import '../core/room.dart';
import '../game/room_game.dart';
import '../widgets/furniture_thumb.dart';
import '../widgets/net_image.dart';
import '../widgets/pixel_avatar.dart';
import '../widgets/pixel_ui.dart';
import 'call_screen.dart';
import 'connections_screen.dart';
import 'messages_screen.dart';
import 'visit_room_screen.dart';

/// Perfil de otro usuario: seguir, solicitudes, chat, clips/posts.
class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key, required this.username});
  final String username;

  String get _key {
    final k = username.toLowerCase();
    if (Mock.users.containsKey(k)) return k;
    for (final e in Mock.users.entries) {
      if (e.value.name.toLowerCase() == k) return e.key;
    }
    return k;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState.I;
    final key = _key;
    final u = Mock.users[key];
    if (u == null) {
      return Scaffold(
        appBar: const PixelAppBar(title: 'PERFIL'),
        body: Center(child: Text('Usuario no encontrado', style: Px.bodyDim)),
      );
    }
    final room = MockRooms.others[key] ?? MockRooms.mine;
    final theirPosts = Mock.posts.where((p) => p.author == key).toList();
    final theirClips = Mock.clips.where((c) => c.author == key).toList();

    return Scaffold(
      body: ListenableBuilder(
        listenable: s,
        builder: (_, __) {
          final friend = s.isFriend(key);
          final pending = s.hasOutgoingRequest(key);
          final incoming = s.hasIncomingRequest(key);
          final follows = s.following.contains(key);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: material.Clip.none,
                  children: [
                    PixelBanner(index: room.banner, height: 120),
                    SafeArea(
                      child: Row(
                        children: [
                          PixelBackButton(
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          if (friend)
                            IconButton(
                              tooltip: 'Llamar',
                              onPressed: () {
                                s.startCall(key);
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => CallScreen(peer: key),
                                  ),
                                );
                              },
                              icon: PixelGlyph(
                                kind: PixelGlyphKind.call,
                                color: Px.accent,
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: -36,
                      child: AvatarBadge(
                        config: u.avatar,
                        size: 84,
                        status: u.status,
                        rgb: true,
                        animate: true,
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RgbText('@${u.name}', style: Px.title(12)),
                      const SizedBox(height: 6),
                      Text(u.bio, style: Px.bodyDim),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _MiniStat('${theirPosts.length + theirClips.length}', 'POSTS'),
                          _MiniStat(
                            '${4 + key.hashCode.abs() % 40}',
                            'SEGUIDORES',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ConnectionsScreen(
                                    initialTab: 0,
                                    forUser: key,
                                  ),
                                ),
                              );
                            },
                          ),
                          _MiniStat(
                            '${3 + key.hashCode.abs() % 20}',
                            'SIGUIENDO',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ConnectionsScreen(
                                    initialTab: 1,
                                    forUser: key,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        friend
                            ? 'AMIGO · chat, llamadas y habitación'
                            : incoming
                                ? 'Te envió solicitud de amistad'
                                : pending
                                    ? 'Solicitud enviada · puedes cancelar'
                                    : follows
                                        ? 'Lo sigues · agrega amigo para chat privado'
                                        : 'Perfil público · síguelo o agrégalo',
                        style: Px.label(6, friend ? Px.accent : Px.gold),
                      ),
                      const SizedBox(height: 14),
                      // Acciones compactas estilo TikTok (no botones largos).
                      Row(
                        children: [
                          Expanded(
                            child: PixelButton(
                              label: follows ? 'SIGUIENDO' : 'SEGUIR',
                              small: true,
                              color: follows ? Px.panelLight : Px.accent,
                              onPressed: () => s.toggleFollow(key),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: friend
                                ? PixelButton(
                                    label: 'MENSAJE',
                                    small: true,
                                    color: Px.magenta,
                                    textColor: Px.text,
                                    glyph: PixelGlyphKind.chat,
                                    onPressed: () {
                                      s.openDm(key);
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => ChatScreen(user: key),
                                        ),
                                      );
                                    },
                                  )
                                : incoming
                                    ? PixelButton(
                                        label: 'ACEPTAR',
                                        small: true,
                                        color: Px.gold,
                                        onPressed: () => s.acceptFriend(key),
                                      )
                                    : pending
                                        ? PixelButton(
                                            label: 'CANCELAR',
                                            small: true,
                                            color: Px.panelLight,
                                            onPressed: () =>
                                                s.cancelFriendRequest(key),
                                          )
                                        : PixelButton(
                                            label: 'AGREGAR',
                                            small: true,
                                            glyph: PixelGlyphKind.contact,
                                            onPressed: () =>
                                                s.sendFriendRequest(key),
                                          ),
                          ),
                        ],
                      ),
                      if (friend || incoming) ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (friend) ...[
                              _IconAction(
                                kind: PixelGlyphKind.call,
                                label: 'Llamar',
                                color: Px.accent,
                                onTap: () {
                                  s.startCall(key);
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => CallScreen(peer: key),
                                    ),
                                  );
                                },
                              ),
                              _IconAction(
                                kind: PixelGlyphKind.video,
                                label: 'Video',
                                color: Px.magenta,
                                onTap: () {
                                  s.startCall(key, video: true);
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          CallScreen(peer: key, video: true),
                                    ),
                                  );
                                },
                              ),
                              _IconAction(
                                kind: PixelGlyphKind.remove,
                                label: 'Eliminar',
                                color: Px.danger,
                                onTap: () => s.removeFriend(key),
                              ),
                            ],
                            if (incoming)
                              _IconAction(
                                kind: PixelGlyphKind.close,
                                label: 'Rechazar',
                                color: Px.textDim,
                                onTap: () => s.rejectFriend(key),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 18),
                      Text('CONTENIDO', style: Px.title(8)),
                      const SizedBox(height: 8),
                      if (theirPosts.isEmpty && theirClips.isEmpty)
                        Text('Aún no publica nada', style: Px.bodyDim)
                      else
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          children: [
                            for (final p in theirPosts)
                              _ContentThumb(
                                imageUrl: p.imageUrl,
                                label: 'POST',
                                avatar: u.avatar,
                              ),
                            for (final _ in theirClips)
                              _ContentThumb(
                                label: 'CLIP',
                                avatar: u.avatar,
                                video: true,
                              ),
                          ],
                        ),
                      const SizedBox(height: 18),
                      Text('SU HABITACIÓN', style: Px.title(8)),
                      const SizedBox(height: 8),
                      Text(room.title, style: Px.bodyDim),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 180,
                        child: GameWidget(
                          game: RoomGame(
                            config: room,
                            me: u.avatar,
                            myName: u.name,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      PixelButton(
                        label: 'VISITAR HABITACIÓN',
                        glyph: PixelGlyphKind.room,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => VisitRoomScreen(
                                hostName: key,
                                room: room,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
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
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Px.panelLight,
                border: Border.all(color: color ?? Px.accent, width: 2),
              ),
              child: PixelGlyph(kind: kind, color: color ?? Px.accent, size: 22),
            ),
            const SizedBox(height: 4),
            Text(label, style: Px.label(5, Px.textDim)),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.value, this.label, {this.onTap});
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Text(value, style: Px.title(9)),
            const SizedBox(height: 2),
            Text(label, style: Px.label(5, onTap != null ? Px.accent : Px.textDim)),
          ],
        ),
      ),
    );
  }
}

class _ContentThumb extends StatelessWidget {
  const _ContentThumb({
    required this.label,
    required this.avatar,
    this.imageUrl,
    this.video = false,
  });
  final String? imageUrl;
  final String label;
  final AvatarConfig avatar;
  final bool video;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Px.panel,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null)
            NetImage(url: imageUrl)
          else
            Center(child: PixelAvatar(config: avatar, size: 36)),
          Positioned(
            left: 4,
            bottom: 4,
            child: Text(label, style: Px.label(5, Px.accent)),
          ),
          if (video)
            Positioned(
              right: 4,
              top: 4,
              child: PixelGlyph(
                kind: PixelGlyphKind.play,
                size: 16,
                color: Px.text,
              ),
            ),
        ],
      ),
    );
  }
}
