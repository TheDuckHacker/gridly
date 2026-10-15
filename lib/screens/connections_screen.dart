import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/mock_data.dart';
import '../core/nav.dart';
import '../core/pixel_theme.dart';
import '../widgets/pixel_avatar.dart';
import '../widgets/pixel_ui.dart';

/// Listas sociales estilo TikTok: Seguidores / Siguiendo / Amigos.
class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key, this.initialTab = 0, this.forUser});

  /// 0 seguidores, 1 siguiendo, 2 amigos
  final int initialTab;

  /// Si es null, es tu cuenta. Si no, perfil ajeno (solo lectura + seguir).
  final String? forUser;

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  late int _tab = widget.initialTab.clamp(0, 2);

  bool get _mine => widget.forUser == null;

  @override
  Widget build(BuildContext context) {
    final s = AppState.I;
    final other = widget.forUser;
    final title = _mine ? 'TU RED' : '@$other';

    return Scaffold(
      appBar: PixelAppBar(title: title, showBack: true),
      body: ListenableBuilder(
        listenable: s,
        builder: (context, _) {
          final List<String> people;
          if (_mine) {
            people = switch (_tab) {
              0 => s.followers.toList()..sort(),
              1 => s.following.toList()..sort(),
              _ => s.friends.toList()..sort(),
            };
          } else {
            // Demo: perfil ajeno muestra un subset de Mock.users.
            final all = Mock.users.keys.where((k) => k != other).toList()
              ..sort();
            people = switch (_tab) {
              0 => all.take(4).toList(),
              1 => all.skip(1).take(4).toList(),
              _ => all.where((k) => s.friends.contains(k) || k == 'nova').take(3).toList(),
            };
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Row(
                  children: [
                    _Tab(
                      label: 'SEGUIDORES',
                      count: _mine ? s.followersCount : people.length,
                      selected: _tab == 0,
                      onTap: () => setState(() => _tab = 0),
                    ),
                    _Tab(
                      label: 'SIGUIENDO',
                      count: _mine ? s.followingCount : null,
                      selected: _tab == 1,
                      onTap: () => setState(() => _tab = 1),
                    ),
                    _Tab(
                      label: 'AMIGOS',
                      count: _mine ? s.friendsCount : null,
                      selected: _tab == 2,
                      onTap: () => setState(() => _tab = 2),
                    ),
                  ],
                ),
              ),
              const PixelDivider(),
              Expanded(
                child: people.isEmpty
                    ? Center(
                        child: Text(
                          _tab == 0
                              ? 'Nadie te sigue aún'
                              : _tab == 1
                                  ? 'Aún no sigues a nadie'
                                  : 'Sin amigos todavía',
                          style: Px.bodyDim,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: people.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final name = people[i];
                          final u = Mock.users[name];
                          if (u == null) return const SizedBox.shrink();
                          final follows = s.following.contains(name);
                          final friend = s.isFriend(name);
                          final pending = s.hasOutgoingRequest(name);
                          final incoming = s.hasIncomingRequest(name);

                          return PixelPanel(
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => openUserProfile(context, name),
                                  child: AvatarBadge(
                                    config: u.avatar,
                                    size: 48,
                                    status: u.status,
                                    rgb: true,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => openUserProfile(context, name),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('@${u.name}', style: Px.label(8, Px.accent)),
                                        Text(
                                          friend
                                              ? 'Amigo'
                                              : follows
                                                  ? 'Lo sigues'
                                                  : u.bio,
                                          style: Px.bodyDim,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_mine || other != name) ...[
                                  _TinyFollow(
                                    follows: follows,
                                    onTap: () => s.toggleFollow(name),
                                  ),
                                  const SizedBox(width: 6),
                                  if (friend)
                                    _TinyIcon(
                                      kind: PixelGlyphKind.contact,
                                      color: Px.gold,
                                      onTap: () => openUserProfile(context, name),
                                    )
                                  else if (incoming)
                                    _TinyIcon(
                                      kind: PixelGlyphKind.check,
                                      color: Px.gold,
                                      onTap: () => s.acceptFriend(name),
                                    )
                                  else if (pending)
                                    _TinyIcon(
                                      kind: PixelGlyphKind.close,
                                      color: Px.textDim,
                                      onTap: () => s.cancelFriendRequest(name),
                                    )
                                  else
                                    _TinyIcon(
                                      kind: PixelGlyphKind.contact,
                                      color: Px.accent,
                                      onTap: () => s.sendFriendRequest(name),
                                    ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Text(
              count == null ? label : '$label · $count',
              style: Px.label(6, selected ? Px.accent : Px.textDim),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Container(
              height: 3,
              color: selected ? Px.accent : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

class _TinyFollow extends StatelessWidget {
  const _TinyFollow({required this.follows, required this.onTap});
  final bool follows;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        color: follows ? Px.panelLight : Px.accent,
        child: Text(
          follows ? 'SIGUE' : 'SEGUIR',
          style: Px.label(6, follows ? Px.text : Px.bg),
        ),
      ),
    );
  }
}

class _TinyIcon extends StatelessWidget {
  const _TinyIcon({
    required this.kind,
    required this.onTap,
    this.color,
  });
  final PixelGlyphKind kind;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        color: Px.panelLight,
        child: PixelGlyph(kind: kind, size: 18, color: color),
      ),
    );
  }
}
