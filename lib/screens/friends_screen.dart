import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/mock_data.dart';
import '../core/nav.dart';
import '../core/pixel_theme.dart';
import '../core/room.dart';
import '../widgets/pixel_avatar.dart';
import '../widgets/pixel_ui.dart';
import 'call_screen.dart';
import 'messages_screen.dart';
import 'my_room_screen.dart';
import 'visit_room_screen.dart';

/// Amigos: chat, llamada y visitar su habitación.
class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppState.I;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(
            MediaQuery.paddingOf(context).top + 88,
          ),
          child: ListenableBuilder(
            listenable: s,
            builder: (_, __) => Container(
            padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
            decoration: BoxDecoration(
              color: Px.panel,
              border: Border(bottom: BorderSide(color: Px.border, width: 2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      const SizedBox(width: 10),
                      Tooltip(
                        message: 'Tu perfil',
                        child: GestureDetector(
                          onTap: () => AppState.I.requestTab(5),
                          child: AvatarBadge(
                            config: s.avatar,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text('AMIGOS', style: Px.title(10))),
                      PixelIconCard(
                        kind: PixelGlyphKind.room,
                        tooltip: 'Mi habitación',
                        color: Px.magenta,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const MyRoomScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                ),
                TabBar(
                  indicatorColor: Px.accent,
                  labelPadding: EdgeInsets.zero,
                  labelStyle: Px.label(6, Px.accent),
                  unselectedLabelStyle: Px.label(6, Px.textDim),
                  tabs: [
                    Tab(height: 36, text: 'AMIGOS (${s.friends.length})'),
                    Tab(
                      height: 36,
                      text: 'PEDIDOS (${s.friendRequestsIn.length})',
                    ),
                    const Tab(height: 36, text: 'SUGERIDOS'),
                  ],
                ),
              ],
            ),
          ),
          ),
        ),
        body: const TabBarView(
          children: [_FriendsList(), _RequestsList(), _SuggestedList()],
        ),
      ),
    );
  }
}

class _FriendsList extends StatelessWidget {
  const _FriendsList();

  @override
  Widget build(BuildContext context) {
    final s = AppState.I;
    return ListenableBuilder(
      listenable: s,
      builder: (_, __) {
        final list =
            s.friends.toList()..sort((a, b) {
              final sa = Mock.users[a]!.status.index;
              final sb = Mock.users[b]!.status.index;
              return sa.compareTo(sb);
            });
        if (list.isEmpty) {
          return Center(
            child: Text(
              'Aún no tienes amigos.\nVe a SUGERIDOS.',
              style: Px.bodyDim,
              textAlign: TextAlign.center,
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            PixelPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AMIGOS EN GRIDLY', style: Px.title(8)),
                  const SizedBox(height: 6),
                  Text(
                    'Chat, videollamada o visita su habitación pixel.',
                    style: Px.bodyDim,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text('EN LÍNEA', style: Px.label(7, Px.accent)),
            const SizedBox(height: 8),
            for (final name in list)
              _FriendTile(
                name: name,
                onMessage: () {
                  s.openDm(name);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ChatScreen(user: name),
                    ),
                  );
                },
                onCall: () {
                  s.startCall(name, video: true);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CallScreen(peer: name, video: true),
                    ),
                  );
                },
                onVisit: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder:
                          (_) => VisitRoomScreen(
                            hostName: name,
                            room: MockRooms.others[name] ?? MockRooms.mine,
                          ),
                    ),
                  );
                },
                onRemove: () => s.removeFriend(name),
              ),
          ],
        );
      },
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({
    required this.name,
    required this.onMessage,
    required this.onCall,
    required this.onVisit,
    required this.onRemove,
  });
  final String name;
  final VoidCallback onMessage;
  final VoidCallback onCall;
  final VoidCallback onVisit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final u = Mock.users[name]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PixelPanel(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => openUserProfile(context, name),
                  child: AvatarBadge(
                    config: u.avatar,
                    size: 48,
                    status: u.status,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => openUserProfile(context, name),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.name, style: Px.label(8, Px.accent)),
                        Text(
                          u.bio,
                          style: Px.bodyDim,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  color: Px.panel,
                  icon: PixelGlyph(
                    kind: PixelGlyphKind.more,
                    size: 16,
                    color: Px.textDim,
                  ),
                  onSelected: (v) {
                    if (v == 'remove') onRemove();
                  },
                  itemBuilder:
                      (_) => [
                        PopupMenuItem(
                          value: 'remove',
                          child: Text('Eliminar amigo', style: Px.body),
                        ),
                      ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: PixelButton(
                    label: 'CHAT',
                    small: true,
                    glyph: PixelGlyphKind.chat,
                    onPressed: onMessage,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: PixelButton(
                    label: 'VIDEO',
                    small: true,
                    color: Px.accentDim,
                    glyph: PixelGlyphKind.video,
                    onPressed: onCall,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: PixelButton(
                    label: 'VISITAR',
                    small: true,
                    color: Px.magenta,
                    glyph: PixelGlyphKind.room,
                    onPressed: onVisit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestsList extends StatelessWidget {
  const _RequestsList();

  @override
  Widget build(BuildContext context) {
    final s = AppState.I;
    return ListenableBuilder(
      listenable: s,
      builder: (_, __) {
        if (s.friendRequestsIn.isEmpty && s.friendRequestsOut.isEmpty) {
          return Center(
            child: Text('No hay solicitudes nuevas', style: Px.bodyDim),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            for (final name in s.friendRequestsIn)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PixelPanel(
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => openUserProfile(context, name),
                        child: AvatarBadge(
                          config: Mock.users[name]!.avatar,
                          size: 48,
                          status: Mock.users[name]!.status,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => openUserProfile(context, name),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: Px.label(8, Px.accent)),
                              Text(
                                Mock.users[name]?.bio ?? '',
                                style: Px.bodyDim,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      PixelButton(
                        label: 'ACEPTAR',
                        small: true,
                        color: Px.gold,
                        onPressed: () => s.acceptFriend(name),
                      ),
                      const SizedBox(width: 6),
                      PixelButton(
                        label: 'NO',
                        small: true,
                        color: Px.panelLight,
                        onPressed: () => s.rejectFriend(name),
                      ),
                    ],
                  ),
                ),
              ),
            if (s.friendRequestsOut.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('ENVIADAS', style: Px.label(7)),
              const SizedBox(height: 8),
              for (final name in s.friendRequestsOut)
                ListTile(
                  onTap: () => openUserProfile(context, name),
                  leading: PixelAvatar(
                    config: Mock.users[name]!.avatar,
                    size: 36,
                  ),
                  title: Text(name, style: Px.label(8)),
                  subtitle: Text('Esperando respuesta…', style: Px.bodyDim),
                  trailing: TextButton(
                    onPressed: () => s.cancelFriendRequest(name),
                    child: Text('CANCELAR', style: Px.label(6, Px.danger)),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _SuggestedList extends StatelessWidget {
  const _SuggestedList();

  @override
  Widget build(BuildContext context) {
    final s = AppState.I;
    return ListenableBuilder(
      listenable: s,
      builder: (_, __) {
        final suggested =
            Mock.users.keys
                .where(
                  (n) =>
                      !s.friends.contains(n) &&
                      !s.friendRequestsIn.contains(n) &&
                      !s.friendRequestsOut.contains(n),
                )
                .toList();
        if (suggested.isEmpty) {
          return Center(
            child: Text('Ya conoces a todos en la demo ✨', style: Px.bodyDim),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text(
              'Personas que te pueden gustar · agrégalas para chatear y entrar a tu habitación',
              style: Px.bodyDim,
            ),
            const SizedBox(height: 12),
            for (final name in suggested)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PixelPanel(
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => openUserProfile(context, name),
                        child: AvatarBadge(
                          config: Mock.users[name]!.avatar,
                          size: 48,
                          status: Mock.users[name]!.status,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => openUserProfile(context, name),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: Px.label(8, Px.accent)),
                              Text(Mock.users[name]!.bio, style: Px.bodyDim),
                            ],
                          ),
                        ),
                      ),
                      PixelButton(
                        label: s.following.contains(name) ? 'SIGUIENDO' : 'SEGUIR',
                        small: true,
                        color: s.following.contains(name)
                            ? Px.panelLight
                            : Px.accent,
                        onPressed: () => s.toggleFollow(name),
                      ),
                      const SizedBox(width: 6),
                      PixelButton(
                        label: 'AGREGAR',
                        small: true,
                        glyph: PixelGlyphKind.contact,
                        onPressed: () => s.sendFriendRequest(name),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
