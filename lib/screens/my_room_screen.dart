import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/mock_data.dart';
import '../core/pixel_theme.dart';
import '../core/presence.dart';
import '../game/avatar_component.dart';
import '../game/room_game.dart';
import '../widgets/pixel_avatar.dart';
import '../widgets/pixel_ui.dart';
import 'call_screen.dart';
import 'closet_screen.dart';
import 'room_editor_screen.dart';

/// Habitación social: presencia, puerta, avatares.
class MyRoomScreen extends StatefulWidget {
  const MyRoomScreen({super.key});

  @override
  State<MyRoomScreen> createState() => _MyRoomScreenState();
}

class _MyRoomScreenState extends State<MyRoomScreen> {
  late final RoomGame _game = RoomGame(
    config: AppState.I.room,
    me: AppState.I.avatar,
    myName: AppState.I.username,
  );
  final _chat = TextEditingController();
  final PresenceService _p = PresenceService.I;
  bool _ready = false;
  final Set<String> _spawned = {};

  @override
  void initState() {
    super.initState();
    final s = AppState.I;
    _p.joinRoom(
      roomId: PresenceService.demoRoomId,
      userId: s.username,
      avatar: s.avatar,
    );
    _p.addListener(_onPresence);
    _game.loaded.then((_) {
      // Amigos “online” entran con latencia (demo multiplayer).
      final guests = s.friends.where((f) => Mock.users.containsKey(f)).take(3);
      _p.spawnDemoGuests(guests);
      if (mounted) setState(() => _ready = true);
    });
  }

  void _onPresence() {
    if (!mounted || !_game.isLoaded) {
      if (mounted) setState(() {});
      return;
    }
    final s = AppState.I;
    for (final m in _p.members.values) {
      if (m.id == s.username) continue;
      if (!_spawned.contains(m.id)) {
        _spawned.add(m.id);
        _game.addVisitor(
          m.id,
          m.avatar,
          phrases: ['online ✨', 'hola!', 'aquí estoy'],
        );
      }
      _game.syncVisitorPosition(m.id, m.x, m.y);
      if (m.bubble != null) _game.visitorSay(m.id, m.bubble!);
    }
    setState(() {});
  }

  void _send() {
    final t = _chat.text.trim();
    if (t.isEmpty) return;
    final s = AppState.I;
    _game.sayMe(t);
    _p.say(s.username, t);
    _chat.clear();
  }

  void _inviteFriend() {
    final s = AppState.I;
    final here = _p.members.keys.toSet();
    final candidates = s.friends.where((f) => !here.contains(f)).toList();
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Todos tus amigos ya están online aquí',
            style: Px.body,
          ),
          backgroundColor: Px.panelLight,
        ),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (_) => PixelPanel(
            shadow: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ABRIR PUERTA A…', style: Px.title(8)),
                const SizedBox(height: 6),
                Text('Abren la puerta y entran a tu habitación', style: Px.bodyDim),
                const SizedBox(height: 12),
                for (final name in candidates)
                  ListTile(
                    leading: AvatarBadge(
                      config: Mock.users[name]!.avatar,
                      size: 40,
                      status: Mock.users[name]!.status,
                    ),
                    title: Text(name, style: Px.label(8, Px.accent)),
                    trailing: PixelGlyph(
                      kind: PixelGlyphKind.room,
                      color: Px.gold,
                      size: 18,
                    ),
                    onTap: () {
                      s.inviteToRoom(name);
                      _p.inviteFriendNow(name);
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
  void dispose() {
    _p.removeListener(_onPresence);
    _p.leaveRoom(AppState.I.username);
    _chat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState.I;
    return Scaffold(
      appBar: PixelAppBar(
        title: 'HABITACIÓN',
        showBack: true,
        actions: [
          IconButton(
            tooltip: 'Closet',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ClosetScreen()),
              );
              _game.refreshMyAvatar(AppState.I.avatar);
              setState(() {});
            },
            icon: PixelGlyph(
              kind: PixelGlyphKind.closet,
              color: Px.magenta,
              size: 18,
            ),
          ),
          IconButton(
            tooltip: 'Decorar',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const RoomEditorScreen(),
                ),
              );
              _game.setConfig(AppState.I.room);
              setState(() {});
            },
            icon: PixelGlyph(
              kind: PixelGlyphKind.chair,
              color: Px.accentDim,
              size: 18,
            ),
          ),
          IconButton(
            tooltip: 'Invitar / puerta',
            onPressed: _inviteFriend,
            icon: PixelGlyph(
              kind: PixelGlyphKind.room,
              color: Px.gold,
              size: 18,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                color: Px.panelLight,
                child: Row(
                  children: [
                    Container(width: 8, height: 8, color: Px.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _ready
                            ? 'EN VIVO · ${_p.onlineCount} aquí · toca muebles / invita'
                            : 'Abriendo habitación…',
                        style: Px.label(6, Px.accent),
                      ),
                    ),
                    Text('tú: ${s.username}', style: Px.label(5, Px.textDim)),
                  ],
                ),
              ),
              // Quién está dentro
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  children: [
                    for (final m in _p.members.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Row(
                          children: [
                            AvatarBadge(
                              config: m.avatar,
                              size: 36,
                              status: PresenceStatus.online,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              m.id == s.username ? 'tú' : m.id,
                              style: Px.label(
                                5,
                                m.id == s.username ? Px.magenta : Px.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: GameWidget(game: _game),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  children: [
                    for (final e in [
                      ('HOLA', AvatarMood.wave),
                      ('BAILE', AvatarMood.dance),
                      ('SALTO', AvatarMood.jump),
                      ('SENTAR', AvatarMood.sit),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: PixelChip(
                          label: e.$1,
                          onTap: () => _game.emote(e.$2),
                        ),
                      ),
                    SizedBox(
                      width: 120,
                      child: PixelButton(
                        label: 'VIDEO CALL',
                        small: true,
                        glyph: PixelGlyphKind.video,
                        onPressed: () {
                          final peers = _p.members.keys.where(
                            (k) => k != s.username,
                          );
                          final peer = peers.isNotEmpty ? peers.first : 'nova';
                          s.startCall(peer, video: true);
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder:
                                  (_) => CallScreen(peer: peer, video: true),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 64,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final line    in _p.joinLog.take(5))
                      Text(line, style: Px.bodyDim),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chat,
                        style: Px.body,
                        cursorColor: Px.accent,
                        decoration: InputDecoration(
                          hintText: 'Escribe en la habitación…',
                          hintStyle: Px.bodyDim,
                          filled: true,
                          fillColor: Px.panel,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(color: Px.border, width: 2),
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PixelButton(
                      label: '',
                      glyph: PixelGlyphKind.send,
                      small: true,
                      onPressed: _send,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Flash puerta abierta
          if (_p.doorJustOpened)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: Px.gold.withValues(alpha: 0.12),
                  child: Center(
                    child: Text(
                      'PUERTA ABIERTA 🚪',
                      style: Px.title(12, Px.gold),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
