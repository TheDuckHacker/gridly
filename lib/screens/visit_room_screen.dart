import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/mock_data.dart';
import '../core/pixel_theme.dart';
import '../core/room.dart';
import '../game/room_game.dart';
import '../widgets/furniture_thumb.dart';
import '../widgets/pixel_avatar.dart';
import '../widgets/pixel_ui.dart';
import 'call_screen.dart';
import 'messages_screen.dart';
import '../core/nav.dart';

/// Visitar la habitación de otro usuario: su avatar te recibe, puedes
/// caminar, hablar, seguir o suscribirte.
class VisitRoomScreen extends StatefulWidget {
  const VisitRoomScreen({
    super.key,
    required this.hostName,
    required this.room,
  });
  final String hostName;
  final RoomConfig room;

  @override
  State<VisitRoomScreen> createState() => _VisitRoomScreenState();
}

class _VisitRoomScreenState extends State<VisitRoomScreen> {
  late final RoomGame _game = RoomGame(
    config: widget.room,
    me: AppState.I.avatar,
    myName: AppState.I.username,
  );
  final _chat = TextEditingController();

  @override
  void initState() {
    super.initState();
    final host = Mock.users[widget.hostName]!;
    // El anfitrión aparece cuando la escena cargó.
    _game.loaded.then((_) {
      _game.addVisitor(
        widget.hostName,
        host.avatar,
        phrases: [
          '¡Bienvenid@ a mi cuarto!',
          'Mira mi ${Furniture.catalog[widget.room.items.last.type]!.name.toLowerCase()} 😎',
          '¿Jugamos luego?',
          'Dale like a mi último clip',
        ],
      );
    });
  }

  @override
  void dispose() {
    _chat.dispose();
    super.dispose();
  }

  void _send() {
    final t = _chat.text.trim();
    if (t.isEmpty) return;
    _game.sayMe(t);
    _chat.clear();
  }

  @override
  Widget build(BuildContext context) {
    final host = Mock.users[widget.hostName]!;
    final s = AppState.I;
    return Scaffold(
      body: ListenableBuilder(
        listenable: s,
        builder: (context, _) {
          final friend = s.isFriend(widget.hostName);
          final pending = s.hasOutgoingRequest(widget.hostName);
          final incoming = s.hasIncomingRequest(widget.hostName);
          return Column(
            children: [
              Stack(
                children: [
                  PixelBanner(index: widget.room.banner, height: 100),
                  SafeArea(
                    child: Row(
                      children: [
                        PixelBackButton(
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        GestureDetector(
                          onTap:
                              () => openUserProfile(context, widget.hostName),
                          child: AvatarBadge(
                            config: host.avatar,
                            size: 44,
                            status: host.status,
                            rgb: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap:
                                () => openUserProfile(context, widget.hostName),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('@${widget.hostName}', style: Px.title(9)),
                                Text(
                                  widget.room.title,
                                  style: Px.label(6, Px.text),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (friend)
                          IconButton(
                            tooltip: 'Ya son amigos',
                            onPressed:
                                () => openUserProfile(context, widget.hostName),
                            icon: PixelGlyph(
                              kind: PixelGlyphKind.check,
                              color: Px.accent,
                              size: 18,
                            ),
                          )
                        else if (incoming)
                          IconButton(
                            tooltip: 'Aceptar solicitud',
                            onPressed: () => s.acceptFriend(widget.hostName),
                            icon: PixelGlyph(
                              kind: PixelGlyphKind.contact,
                              color: Px.gold,
                              size: 18,
                            ),
                          )
                        else
                          IconButton(
                            tooltip:
                                pending ? 'Solicitud enviada' : 'Agregar amigo',
                            onPressed:
                                pending
                                    ? null
                                    : () =>
                                        s.sendFriendRequest(widget.hostName),
                            icon: PixelGlyph(
                              kind: pending
                                  ? PixelGlyphKind.wait
                                  : PixelGlyphKind.contact,
                              color: pending ? Px.textDim : Px.text,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              Expanded(child: GameWidget(game: _game)),
              Container(
                color: Px.panel,
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    if (!friend)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Agrégalo como amigo para chat, videollamada y habitación privada',
                          style: Px.label(6, Px.gold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    Row(
                      children: [
                        if (friend)
                          Expanded(
                            child: PixelButton(
                              label: 'MENSAJE',
                              small: true,
                              glyph: PixelGlyphKind.chat,
                              onPressed: () {
                                s.openDm(widget.hostName);
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder:
                                        (_) =>
                                            ChatScreen(user: widget.hostName),
                                  ),
                                );
                              },
                            ),
                          )
                        else if (incoming)
                          Expanded(
                            child: PixelButton(
                              label: 'ACEPTAR',
                              small: true,
                              color: Px.gold,
                              glyph: PixelGlyphKind.contact,
                              onPressed: () => s.acceptFriend(widget.hostName),
                            ),
                          )
                        else
                          Expanded(
                            child: PixelButton(
                              label: pending ? 'PEDIDO…' : 'AGREGAR',
                              small: true,
                              color: pending ? Px.panelLight : Px.accent,
                              enabled: !pending,
                              glyph:
                                  pending
                                      ? PixelGlyphKind.wait
                                      : PixelGlyphKind.contact,
                              onPressed: () {
                                if (!pending) {
                                  s.sendFriendRequest(widget.hostName);
                                }
                              },
                            ),
                          ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 48,
                          child: PixelButton(
                            label: '',
                            small: true,
                            color: friend ? Px.accentDim : Px.border,
                            enabled: friend,
                            glyph: PixelGlyphKind.video,
                            onPressed: () {
                              if (!friend) return;
                              s.startCall(widget.hostName, video: true);
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder:
                                      (_) => CallScreen(
                                        peer: widget.hostName,
                                        video: true,
                                      ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chat,
                            style: Px.body,
                            cursorColor: Px.accent,
                            onSubmitted: (_) => _send(),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Di algo en el cuarto…',
                              hintStyle: Px.bodyDim,
                              filled: true,
                              fillColor: Px.bg,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(
                                  color: Px.border,
                                  width: 2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(
                                  color: Px.accent,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 48,
                          child: PixelButton(
                            label: '',
                            small: true,
                            glyph: PixelGlyphKind.send,
                            onPressed: _send,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
