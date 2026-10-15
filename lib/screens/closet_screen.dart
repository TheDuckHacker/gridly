import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/mock_data.dart';
import '../core/pixel_theme.dart';
import '../widgets/pixel_avatar.dart';
import '../widgets/pixel_ui.dart';
import 'my_room_screen.dart';
import 'room_editor_screen.dart';

/// Closet estilo Sims: cambiar ropa, guardar looks e invitar amigos al cuarto.
class ClosetScreen extends StatefulWidget {
  const ClosetScreen({super.key});

  @override
  State<ClosetScreen> createState() => _ClosetScreenState();
}

class _ClosetScreenState extends State<ClosetScreen>
    with SingleTickerProviderStateMixin {
  late AvatarConfig _cfg = AppState.I.avatar;
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _wear() {
    AppState.I.wearOutfit(_cfg);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Te pusiste el outfit', style: Px.body),
        backgroundColor: Px.panelLight,
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  void _saveLook() {
    final c = TextEditingController(text: 'Mi look');
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Px.panel,
            title: Text('GUARDAR LOOK', style: Px.title(9)),
            content: TextField(
              controller: c,
              style: Px.body,
              cursorColor: Px.accent,
              decoration: InputDecoration(
                filled: true,
                fillColor: Px.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: Px.border, width: 2),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('CANCELAR', style: Px.label(7)),
              ),
              TextButton(
                onPressed: () {
                  AppState.I.saveClosetLook(c.text, _cfg);
                  AppState.I.wearOutfit(_cfg);
                  Navigator.pop(ctx);
                },
                child: Text('GUARDAR', style: Px.label(7, Px.accent)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(MediaQuery.paddingOf(context).top + 88),
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
          decoration: BoxDecoration(
            color: Px.panel,
            border: Border(bottom: BorderSide(color: Px.border, width: 2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    PixelBackButton(
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(child: Text('CLOSET', style: Px.title(10))),
                    IconButton(
                      tooltip: 'Decorar cuarto',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const RoomEditorScreen(),
                          ),
                        );
                      },
                      icon: PixelGlyph(
                        kind: PixelGlyphKind.chair,
                        color: Px.accentDim,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabs,
                indicatorColor: Px.accent,
                labelStyle: Px.label(6, Px.accent),
                unselectedLabelStyle: Px.label(6, Px.textDim),
                tabs: const [
                  Tab(height: 36, text: 'ROPA'),
                  Tab(height: 36, text: 'LOOKS'),
                  Tab(height: 36, text: 'INVITAR'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Px.panelLight,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                PixelAvatar(config: _cfg, size: 120),
                const SizedBox(height: 8),
                Text('Vista previa', style: Px.label(6)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _ClothesTab(
                  cfg: _cfg,
                  onChanged: (c) => setState(() => _cfg = c),
                ),
                _LooksTab(
                  current: _cfg,
                  onWear: (c) => setState(() => _cfg = c),
                ),
                const _InviteTab(),
              ],
            ),
          ),
          if (_tabs.index != 2)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: PixelButton(
                      label: 'GUARDAR LOOK',
                      small: true,
                      color: Px.accentDim,
                      onPressed: _saveLook,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PixelButton(
                      label: 'PONERME ESTO',
                      small: true,
                      glyph: PixelGlyphKind.closet,
                      onPressed: _wear,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Text(
              'Elige ropa y póntela. Gratis.',
              style: Px.label(5, Px.textDim),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClothesTab extends StatelessWidget {
  const _ClothesTab({required this.cfg, required this.onChanged});
  final AvatarConfig cfg;
  final ValueChanged<AvatarConfig> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('CAMISETA / HOODIE', style: Px.title(8)),
        const SizedBox(height: 8),
        _NamedColors(
          colors: AvatarParts.shirts,
          names: AvatarParts.shirtNames,
          selected: cfg.shirt,
          onPick: (i) => onChanged(cfg.copyWith(shirt: i)),
        ),
        const SizedBox(height: 14),
        Text('PANTALÓN', style: Px.title(8)),
        const SizedBox(height: 8),
        _NamedColors(
          colors: AvatarParts.pants,
          names: AvatarParts.pantsNames,
          selected: cfg.pants,
          onPick: (i) => onChanged(cfg.copyWith(pants: i)),
        ),
        const SizedBox(height: 14),
        Text('ZAPATOS', style: Px.title(8)),
        const SizedBox(height: 8),
        _NamedColors(
          colors: AvatarParts.shoes,
          names: AvatarParts.shoesNames,
          selected: cfg.shoes,
          onPick: (i) => onChanged(cfg.copyWith(shoes: i)),
        ),
        const SizedBox(height: 14),
        Text('ACCESORIO', style: Px.title(8)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < AvatarParts.accessoryNames.length; i++)
              PixelChip(
                label: AvatarParts.accessoryNames[i].toUpperCase(),
                selected: cfg.accessory == i,
                onTap: () => onChanged(cfg.copyWith(accessory: i)),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text('PEINADO', style: Px.title(8)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < AvatarParts.hairStyleNames.length; i++)
              PixelChip(
                label: AvatarParts.hairStyleNames[i].toUpperCase(),
                selected: cfg.hairStyle == i,
                onTap: () => onChanged(cfg.copyWith(hairStyle: i)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _NamedColors(
          colors: AvatarParts.hairs,
          names: List.generate(
            AvatarParts.hairs.length,
            (i) => 'Pelo ${i + 1}',
          ),
          selected: cfg.hair,
          onPick: (i) => onChanged(cfg.copyWith(hair: i)),
        ),
      ],
    );
  }
}

class _NamedColors extends StatelessWidget {
  const _NamedColors({
    required this.colors,
    required this.names,
    required this.selected,
    required this.onPick,
  });
  final List<Color> colors;
  final List<String> names;
  final int selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < colors.length; i++)
          GestureDetector(
            onTap: () => onPick(i),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors[i],
                    border: Border.all(
                      color: selected == i ? Px.accent : Px.border,
                      width: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 64,
                  child: Text(
                    names[i % names.length],
                    style: Px.label(5, selected == i ? Px.accent : Px.textDim),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _LooksTab extends StatelessWidget {
  const _LooksTab({required this.current, required this.onWear});
  final AvatarConfig current;
  final ValueChanged<AvatarConfig> onWear;

  @override
  Widget build(BuildContext context) {
    final s = AppState.I;
    return ListenableBuilder(
      listenable: s,
      builder: (_, __) {
        if (s.closetLooks.isEmpty) {
          return Center(
            child: Text('Guarda un look desde ROPA', style: Px.bodyDim),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: s.closetLooks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final look = s.closetLooks[i];
            final on = look.config == current;
            return PixelPanel(
              child: Row(
                children: [
                  PixelAvatar(config: look.config, size: 56),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          look.name,
                          style: Px.label(8, on ? Px.accent : Px.text),
                        ),
                        Text(
                          on ? 'puesto ahora' : 'tap para probar',
                          style: Px.bodyDim,
                        ),
                      ],
                    ),
                  ),
                  PixelButton(
                    label: on ? 'ON' : 'USAR',
                    small: true,
                    color: on ? Px.panelLight : Px.accent,
                    textColor: on ? Px.text : Px.bg,
                    onPressed: () {
                      onWear(look.config);
                      s.wearOutfit(look.config);
                    },
                  ),
                  IconButton(
                    onPressed: () => s.deleteClosetLook(i),
                    icon: PixelGlyph(
                      kind: PixelGlyphKind.delete,
                      color: Px.danger,
                      size: 18,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _InviteTab extends StatelessWidget {
  const _InviteTab();

  @override
  Widget build(BuildContext context) {
    final s = AppState.I;
    return ListenableBuilder(
      listenable: s,
      builder: (_, __) {
        final friends = s.friends.toList();
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text(
              'Invita amigos a tu habitación para charlar (como Sims / Kumo). Solo amigos.',
              style: Px.bodyDim,
            ),
            const SizedBox(height: 12),
            PixelButton(
              label: 'ABRIR HABITACIÓN CON AMIGOS',
              glyph: PixelGlyphKind.home,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const MyRoomScreen()),
                );
              },
            ),
            const SizedBox(height: 14),
            Text('TUS AMIGOS', style: Px.title(8)),
            const SizedBox(height: 8),
            if (friends.isEmpty)
              Text('Agrega amigos en la pestaña AMIGOS', style: Px.bodyDim)
            else
              for (final name in friends)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PixelPanel(
                    child: Row(
                      children: [
                        AvatarBadge(
                          config: Mock.users[name]!.avatar,
                          size: 44,
                          status: Mock.users[name]!.status,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: Px.label(8, Px.accent)),
                              Text(
                                s.roomInvites.contains(name)
                                    ? 'invitado ✓'
                                    : 'en línea posible',
                                style: Px.bodyDim,
                              ),
                            ],
                          ),
                        ),
                        PixelButton(
                          label:
                              s.roomInvites.contains(name) ? 'OK' : 'INVITAR',
                          small: true,
                          color:
                              s.roomInvites.contains(name)
                                  ? Px.panelLight
                                  : Px.magenta,
                          textColor: Px.text,
                          onPressed: () {
                            final ok = s.inviteToRoom(name);
                            if (!ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Solo amigos', style: Px.body),
                                  backgroundColor: Px.panelLight,
                                ),
                              );
                              return;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const MyRoomScreen(),
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
    );
  }
}
