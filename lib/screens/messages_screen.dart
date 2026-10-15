import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_state.dart';
import '../core/mock_data.dart';
import '../core/nav.dart';
import '../core/pixel_theme.dart';
import '../core/sfx.dart';
import '../widgets/net_image.dart';
import '../widgets/pixel_avatar.dart';
import '../widgets/pixel_ui.dart';
import 'call_screen.dart';

/// Chats Gridly (pixel): lista + conversación + agregar por celular.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _search = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState.I;
    final topPad = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: Px.bg,
      body: ListenableBuilder(
        listenable: s,
        builder: (_, __) {
          final threads =
              Mock.dms
                  .where((t) => s.friends.contains(t.user))
                  .where((t) {
                    if (_q.isEmpty) return true;
                    final u = Mock.users[t.user]!;
                    return u.name.toLowerCase().contains(_q) ||
                        t.preview.toLowerCase().contains(_q) ||
                        u.phone.contains(_q);
                  })
                  .toList();

          return Column(
            children: [
              Container(
                padding: EdgeInsets.only(top: topPad),
                decoration: BoxDecoration(
                  color: Px.panel,
                  border: Border(
                    bottom: BorderSide(color: Px.border, width: 2),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 52,
                      child: Row(
                        children: [
                          if (!widget.embedded)
                            PixelBackButton(
                              onPressed:
                                  () => Navigator.of(context).maybePop(),
                            )
                          else
                            const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => AppState.I.requestTab(5),
                            child: AvatarBadge(
                              config: s.avatar,
                              size: 34,
                              
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('CHATS', style: Px.title(10)),
                          ),
                          PixelIconBtn(
                            kind: PixelGlyphKind.phone,
                            tooltip: 'Agregar por celular',
                            color: Px.accent,
                            onPressed: () => _addByPhone(context),
                          ),
                          PixelIconBtn(
                            kind: PixelGlyphKind.chat,
                            tooltip: 'Nuevo chat',
                            color: Px.accent,
                            onPressed: () => _pickFriendToChat(context),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Px.bg,
                          border: Border.all(color: Px.border, width: 2),
                        ),
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: PixelGlyph(
                                kind: PixelGlyphKind.search,
                                size: 14,
                                color: Px.textDim,
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _search,
                                style: Px.body,
                                cursorColor: Px.accent,
                                onChanged:
                                    (v) => setState(
                                      () => _q = v.trim().toLowerCase(),
                                    ),
                                decoration: InputDecoration(
                                  hintText: 'Buscar chat o número…',
                                  hintStyle: Px.bodyDim,
                                  isDense: true,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    threads.isEmpty
                        ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PixelGlyph(
                                  kind: PixelGlyphKind.chat,
                                  size: 40,
                                  color: Px.textDim,
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Agrega amigos con su número\nde celular y chatea aquí',
                                  style: Px.bodyDim,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                PixelButton(
                                  label: 'AGREGAR POR CELULAR',
                                  glyph: PixelGlyphKind.phone,
                                  onPressed: () => _addByPhone(context),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Demo: 5551002001 (nova), 5551002002 (byte)…',
                                  style: Px.label(5, Px.textDim),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                        : ListView.builder(
                          itemCount: threads.length,
                          itemBuilder: (_, i) {
                            final t = threads[i];
                            final u = Mock.users[t.user]!;
                            final unread = t.unread > 0;
                            return InkWell(
                              onTap: () {
                                s.openDm(t.user);
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ChatScreen(user: t.user),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Px.border,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    AvatarBadge(
                                      config: u.avatar,
                                      size: 48,
                                      status: u.status,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  u.name,
                                                  style: Px.label(
                                                    8,
                                                    Px.accent,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                t.time,
                                                style: Px.label(
                                                  6,
                                                  unread
                                                      ? Px.accent
                                                      : Px.textDim,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  t.preview.isEmpty
                                                      ? u.phone
                                                      : t.preview,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Px.bodyDim,
                                                ),
                                              ),
                                              if (unread)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                    left: 8,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  color: Px.accent,
                                                  child: Text(
                                                    '${t.unread}',
                                                    style: Px.label(6, Px.bg),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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

  void _addByPhone(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Px.panel,
            title: Text('AGREGAR POR CELULAR', style: Px.title(8)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Escribe el número de tu amigo (demo Gridly)',
                  style: Px.bodyDim,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  keyboardType: TextInputType.phone,
                  style: Px.body,
                  cursorColor: Px.accent,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: '5551002001',
                    hintStyle: Px.bodyDim,
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(12),
                      child: PixelGlyph(
                        kind: PixelGlyphKind.phone,
                        size: 16,
                        color: Px.accent,
                      ),
                    ),
                    filled: true,
                    fillColor: Px.bg,
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
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('CANCELAR', style: Px.label(7)),
              ),
              TextButton(
                onPressed: () {
                  final r = AppState.I.addByPhone(ctrl.text);
                  Navigator.pop(ctx);
                  final msg = switch (r) {
                    'ok' => 'Solicitud / contacto enviado',
                    'already' => 'Ya son amigos',
                    'self' => 'Ese es tu número',
                    'short' => 'Mínimo 8 dígitos',
                    _ => 'Número no encontrado en demo',
                  };
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(msg, style: Px.body),
                      backgroundColor: Px.panelLight,
                    ),
                  );
                  if (r == 'ok' || r == 'already') {
                    final user = AppState.I.findUserByPhone(ctrl.text);
                    if (user != null && AppState.I.isFriend(user)) {
                      AppState.I.openDm(user);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChatScreen(user: user),
                        ),
                      );
                    }
                  }
                },
                child: Text('AGREGAR', style: Px.label(7, Px.accent)),
              ),
            ],
          ),
    );
  }

  void _pickFriendToChat(BuildContext context) {
    final s = AppState.I;
    final friends = s.friends.toList()..sort();
    if (friends.isEmpty) {
      _addByPhone(context);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Px.panel,
      builder:
          (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Text('NUEVO CHAT', style: Px.title(8)),
                      const Spacer(),
                      PixelIconBtn(
                        kind: PixelGlyphKind.phone,
                        color: Px.accent,
                        onPressed: () {
                          Navigator.pop(context);
                          _addByPhone(context);
                        },
                      ),
                    ],
                  ),
                ),
                for (final name in friends)
                  ListTile(
                    leading: AvatarBadge(
                      config: Mock.users[name]!.avatar,
                      size: 40,
                      status: Mock.users[name]!.status,
                    ),
                    title: Text(name, style: Px.label(8, Px.accent)),
                    subtitle: Text(
                      Mock.users[name]!.phone,
                      style: Px.bodyDim,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      s.openDm(name);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChatScreen(user: name),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.user});
  final String user;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _hasText = false;
  bool _peerTyping = false;

  static const _stickerKinds = <(String, PixelGlyphKind, Color)>[
    ('heart', PixelGlyphKind.heart, Color(0xFFFF4466)),
    ('star', PixelGlyphKind.star, Color(0xFFFFD166)),
    ('sparkle', PixelGlyphKind.sparkle, Color(0xFF66FFCC)),
    ('music', PixelGlyphKind.music, Color(0xFF88AAFF)),
    ('play', PixelGlyphKind.play, Color(0xFFAA66FF)),
    ('check', PixelGlyphKind.check, Color(0xFF66FF88)),
    ('fire', PixelGlyphKind.coin, Color(0xFFFF8844)),
    ('chat', PixelGlyphKind.chat, Color(0xFF44DDFF)),
  ];

  DmThread? get _thread {
    for (final t in Mock.dms) {
      if (t.user == widget.user) return t;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    if (AppState.I.isFriend(widget.user)) {
      AppState.I.openDm(widget.user);
    }
    _input.addListener(() {
      final v = _input.text.trim().isNotEmpty;
      if (v != _hasText) setState(() => _hasText = v);
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _markTyping() {
    setState(() => _peerTyping = true);
    Future<void>.delayed(const Duration(milliseconds: 1300), () {
      if (mounted) setState(() => _peerTyping = false);
    });
  }

  void _sendRaw(String text, {String? localPath, String? sticker}) {
    if (!AppState.I.isFriend(widget.user)) return;
    AppState.I.sendDm(
      widget.user,
      text,
      localPath: localPath,
      sticker: sticker,
    );
    Sfx.I.tap();
    _markTyping();
    _jump();
  }

  void _more() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Px.panel,
      builder:
          (ctx) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _PixelAttach(
                  label: 'Foto',
                  kind: PixelGlyphKind.camera,
                  onTap: () {
                    Navigator.pop(ctx);
                    _pick(video: false);
                  },
                ),
                _PixelAttach(
                  label: 'Video',
                  kind: PixelGlyphKind.video,
                  onTap: () {
                    Navigator.pop(ctx);
                    _pick(video: true);
                  },
                ),
                _PixelAttach(
                  label: 'Doc',
                  kind: PixelGlyphKind.attach,
                  onTap: () {
                    Navigator.pop(ctx);
                    _sendRaw('📄 documento.pdf');
                  },
                ),
                _PixelAttach(
                  label: 'Sticker',
                  kind: PixelGlyphKind.emoji,
                  onTap: () {
                    Navigator.pop(ctx);
                    _stickers();
                  },
                ),
                _PixelAttach(
                  label: 'Sala',
                  kind: PixelGlyphKind.people,
                  onTap: () {
                    Navigator.pop(ctx);
                    _openStage(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _pick({required bool video}) async {
    try {
      final picker = ImagePicker();
      final file =
          video
              ? await picker.pickVideo(source: ImageSource.gallery)
              : await picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      if (video) {
        _sendRaw('🎬 ${file.name}');
      } else {
        _sendRaw('📷 ${file.name}', localPath: file.path);
      }
    } catch (_) {
      _sendRaw(video ? '🎬 video' : '📷 foto');
    }
  }

  void _stickers() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => PixelPanel(
            shadow: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('STICKERS PIXEL', style: Px.title(8)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final s in _stickerKinds)
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          _sendRaw('', sticker: s.$1);
                        },
                        child: Container(
                          width: 52,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Px.bg,
                            border: Border.all(color: Px.border, width: 2),
                          ),
                          child: PixelGlyph(
                            kind: s.$2,
                            size: 22,
                            color: s.$3,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );
  }

  void _openStage(BuildContext context) {
    var big = false;
    final u = Mock.users[widget.user]!;
    showDialog<void>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setLocal) => Dialog(
                  backgroundColor: Px.panel,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'SALA · toca para agrandar',
                          style: Px.label(7, Px.accent),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => setLocal(() => big = !big),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: big ? 260 : 120,
                            height: big ? 260 : 120,
                            decoration: BoxDecoration(
                              border: Border.all(color: Px.accent, width: 4),
                              color: Px.bg,
                            ),
                            child: Center(
                              child: PixelAvatar(
                                config: u.avatar,
                                size: big ? 96 : 48,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('@${u.name}', style: Px.body),
                        Text(u.phone, style: Px.bodyDim),
                        const SizedBox(height: 12),
                        PixelButton(
                          label: 'CERRAR',
                          small: true,
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    if (!AppState.I.isFriend(widget.user)) return;
    AppState.I.sendDm(widget.user, text);
    Sfx.I.tap();
    _input.clear();
    _markTyping();
    _jump();
  }

  void _jump() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final u = Mock.users[widget.user]!;
    final s = AppState.I;
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: Px.bg,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: top),
            decoration: BoxDecoration(
              color: Px.panel,
              border: Border(bottom: BorderSide(color: Px.border, width: 2)),
            ),
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  PixelBackButton(onPressed: () => Navigator.pop(context)),
                  GestureDetector(
                    onTap: () => openUserProfile(context, widget.user),
                    child: AvatarBadge(
                      config: u.avatar,
                      size: 36,
                      status: u.status,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => openUserProfile(context, widget.user),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.name, style: Px.label(8, Px.accent)),
                          Text(
                            u.status == PresenceStatus.online
                                ? 'CONECTADO'
                                : 'AUSENTE',
                            style: Px.label(
                              5,
                              u.status == PresenceStatus.online
                                  ? Px.online
                                  : Px.textDim,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (s.isFriend(widget.user)) ...[
                    PixelIconBtn(
                      kind: PixelGlyphKind.video,
                      color: Px.accentDim,
                      onPressed: () {
                        s.startCall(u.name, video: true);
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder:
                                (_) => CallScreen(peer: u.name, video: true),
                          ),
                        );
                      },
                    ),
                    PixelIconBtn(
                      kind: PixelGlyphKind.call,
                      color: Px.accent,
                      onPressed: () {
                        s.startCall(u.name);
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder:
                                (_) =>
                                    CallScreen(peer: u.name, video: false),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: s,
              builder: (_, __) {
                final friend = s.isFriend(widget.user);
                final msgs = _thread?.messages ?? const <Message>[];
                return Column(
                  children: [
                    if (!friend)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        color: Px.panelLight,
                        child: Text(
                          'Solo amigos. Agrégalos por celular en CHATS.',
                          style: Px.label(6, Px.gold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    Expanded(
                      child:
                          msgs.isEmpty
                              ? Center(
                                child: Text(
                                  friend
                                      ? 'Escribe el primer mensaje'
                                      : 'Sin chat hasta ser amigos',
                                  style: Px.bodyDim,
                                ),
                              )
                              : ListView.builder(
                                controller: _scroll,
                                padding: const EdgeInsets.all(12),
                                itemCount: msgs.length + (_peerTyping ? 1 : 0),
                                itemBuilder: (_, i) {
                                  if (_peerTyping && i == msgs.length) {
                                    return const Align(
                                      alignment: Alignment.centerLeft,
                                      child: _TypingDots(),
                                    );
                                  }
                                  final m = msgs[i];
                                  final mine = m.author == s.username;
                                  return _ChatBubble(
                                    key: ValueKey(
                                      '${m.time}-$i-${m.text}-${m.sticker}-${m.localPath}',
                                    ),
                                    mine: mine,
                                    peer: widget.user,
                                    message: m,
                                  );
                                },
                              ),
                    ),
                    if (friend)
                      Container(
                        decoration: BoxDecoration(
                          color: Px.panel,
                          border: Border(
                            top: BorderSide(color: Px.border, width: 2),
                          ),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          6,
                          6,
                          6,
                          6 + MediaQuery.paddingOf(context).bottom,
                        ),
                        child: Row(
                          children: [
                            PixelIconBtn(
                              kind: PixelGlyphKind.plus,
                              color: Px.accent,
                              onPressed: _more,
                            ),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Px.bg,
                                  border: Border.all(
                                    color: Px.border,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    PixelIconBtn(
                                      kind: PixelGlyphKind.emoji,
                                      size: 14,
                                      color: Px.textDim,
                                      onPressed: _stickers,
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _input,
                                        style: Px.body,
                                        cursorColor: Px.accent,
                                        decoration: InputDecoration(
                                          hintText: 'Mensaje…',
                                          hintStyle: Px.bodyDim,
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 10,
                                              ),
                                        ),
                                        onSubmitted: (_) => _send(),
                                      ),
                                    ),
                                    PixelIconBtn(
                                      kind: PixelGlyphKind.camera,
                                      size: 14,
                                      color: Px.textDim,
                                      onPressed: () => _pick(video: false),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap:
                                  _hasText
                                      ? _send
                                      : () => _sendRaw('🎤 nota'),
                              child: Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                color: Px.accent,
                                child: PixelGlyph(
                                  kind:
                                      _hasText
                                          ? PixelGlyphKind.send
                                          : PixelGlyphKind.mic,
                                  size: 16,
                                  color: Px.bg,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child:                         PixelButton(
                          label: 'ENVIAR SOLICITUD',
                          glyph: PixelGlyphKind.contact,
                          onPressed:
                              () => s.sendFriendRequest(widget.user),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PixelAttach extends StatelessWidget {
  const _PixelAttach({
    required this.label,
    required this.kind,
    required this.onTap,
  });

  final String label;
  final PixelGlyphKind kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Px.bg,
                border: Border.all(color: Px.border, width: 2),
              ),
              child: PixelGlyph(kind: kind, size: 18, color: Px.accent),
            ),
            const SizedBox(height: 6),
            Text(label, style: Px.label(6, Px.textDim)),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatefulWidget {
  const _ChatBubble({
    super.key,
    required this.mine,
    required this.peer,
    required this.message,
  });

  final bool mine;
  final String peer;
  final Message message;

  @override
  State<_ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<_ChatBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  PixelGlyphKind? _stickerKind(String? id) {
    for (final s in _ChatScreenState._stickerKinds) {
      if (s.$1 == id) return s.$2;
    }
    return null;
  }

  Color? _stickerColor(String? id) {
    for (final s in _ChatScreenState._stickerKinds) {
      if (s.$1 == id) return s.$3;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final mine = widget.mine;
    final m = widget.message;
    final slide = Tween<Offset>(
      begin: Offset(mine ? 0.12 : -0.12, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

    return FadeTransition(
      opacity: _c,
      child: SlideTransition(
        position: slide,
        child: Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.78,
            ),
            decoration: BoxDecoration(
              color: mine ? Px.accent : Px.panelLight,
              border: Border(
                left: BorderSide(
                  color: mine ? Px.bg : Px.accentDim,
                  width: 4,
                ),
                top: BorderSide(color: Px.border, width: 2),
                right: BorderSide(color: Px.border, width: 2),
                bottom: BorderSide(color: Px.border, width: 2),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  mine ? '> TÚ' : '> ${widget.peer.toUpperCase()}',
                  style: Px.label(5, mine ? Px.bg : Px.accent),
                ),
                const SizedBox(height: 4),
                if (m.hasSticker)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Center(
                      child: PixelGlyph(
                        kind: _stickerKind(m.sticker) ?? PixelGlyphKind.sparkle,
                        size: 36,
                        color: _stickerColor(m.sticker) ?? Px.accent,
                      ),
                    ),
                  )
                else if (m.hasImage)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: SizedBox(
                      height: 140,
                      child: NetImage(
                        localPath: m.localPath,
                        fit: BoxFit.cover,
                        fallback: ColoredBox(
                          color: Px.bg,
                          child: Center(
                            child: PixelGlyph(
                              kind: PixelGlyphKind.image,
                              size: 22,
                              color: mine ? Px.bg : Px.textDim,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Text(
                    m.text,
                    style: Px.body.copyWith(color: mine ? Px.bg : Px.text),
                  ),
                if (m.hasImage && m.text.isNotEmpty)
                  Text(
                    m.text,
                    style: Px.label(6, mine ? Px.bg : Px.textDim),
                  ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    m.time,
                    style: Px.label(
                      5,
                      mine ? Px.bg.withValues(alpha: 0.7) : Px.textDim,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10, top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Px.panelLight,
            border: Border.all(color: Px.border, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Opacity(
                    opacity: ((_c.value + i / 3) % 1.0).clamp(0.25, 1),
                    child: Container(
                      width: 6,
                      height: 6,
                      color: Px.accent,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
