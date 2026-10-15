import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/mock_data.dart';
import '../core/nav.dart';
import '../core/pixel_theme.dart';
import '../widgets/pixel_avatar.dart';
import '../widgets/pixel_ui.dart';

/// Buscar personas.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _q = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState.I;
    final users =
        Mock.users.values
            .where(
              (u) =>
                  _query.isEmpty ||
                  u.name.contains(_query) ||
                  u.bio.toLowerCase().contains(_query),
            )
            .toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(MediaQuery.paddingOf(context).top + 52),
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
          decoration: BoxDecoration(
            color: Px.panel,
            border: Border(bottom: BorderSide(color: Px.border, width: 2)),
          ),
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                PixelBackButton(onPressed: () => Navigator.pop(context)),
                Expanded(child: Text('DESCUBRIR', style: Px.title(10))),
              ],
            ),
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: s,
        builder:
            (_, __) => ListView(
              padding: const EdgeInsets.all(12),
              children: [
                TextField(
                  controller: _q,
                  style: Px.body,
                  cursorColor: Px.accent,
                  onChanged:
                      (v) => setState(() => _query = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Buscar personas…',
                    hintStyle: Px.bodyDim,
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(12),
                      child: PixelGlyph(
                        kind: PixelGlyphKind.search,
                        size: 16,
                        color: Px.accent,
                      ),
                    ),
                    filled: true,
                    fillColor: Px.panel,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: Px.border, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: Px.accent, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('PERSONAS', style: Px.title(8)),
                const SizedBox(height: 8),
                for (final u in users)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: AvatarBadge(
                      config: u.avatar,
                      size: 40,
                      status: u.status,
                    ),
                    title: Text(u.name, style: Px.label(8, Px.accent)),
                    subtitle: Text(u.bio, style: Px.bodyDim, maxLines: 1),
                    trailing: PixelChip(
                      label:
                          s.friends.contains(u.name)
                              ? 'AMIGO'
                              : (s.following.contains(u.name)
                                  ? 'SIGUIENDO'
                                  : 'SEGUIR'),
                      selected: !s.following.contains(u.name),
                      onTap: () {
                        if (s.friends.contains(u.name)) return;
                        if (s.following.contains(u.name)) {
                          s.toggleFollow(u.name);
                        } else {
                          s.toggleFollow(u.name);
                          s.sendFriendRequest(u.name);
                        }
                      },
                    ),
                    onTap: () => openUserProfile(context, u.name),
                  ),
              ],
            ),
      ),
    );
  }
}
