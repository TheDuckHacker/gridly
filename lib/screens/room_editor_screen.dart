import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/pixel_theme.dart';
import '../core/room.dart';
import '../game/room_game.dart';
import '../widgets/furniture_thumb.dart';
import '../widgets/pixel_ui.dart';

/// Decorar la habitación: catálogo de muebles (toca uno y luego toca el
/// cuarto para colocarlo; arrastra para mover; selecciona y borra), paredes,
/// pisos, marco RGB y banner.
class RoomEditorScreen extends StatefulWidget {
  const RoomEditorScreen({super.key});

  @override
  State<RoomEditorScreen> createState() => _RoomEditorScreenState();
}

class _RoomEditorScreenState extends State<RoomEditorScreen> {
  late RoomConfig _cfg = AppState.I.room;
  late final RoomGame _game = RoomGame(
    config: _cfg,
    me: AppState.I.avatar,
    myName: AppState.I.username,
    editable: true,
    onChanged: (c) => setState(() => _cfg = c),
    onSelection:
        (i) => setState(() {
          _selected = i;
          _placing = _game.placing;
        }),
  );
  int? _selected;
  String? _placing;
  int _tab = 0; // 0 muebles, 1 pared, 2 piso, 3 extras

  void _pick(String? type) {
    setState(() => _placing = _placing == type ? null : type);
    _game.placing = _placing;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PixelAppBar(
        title: 'DECORAR',
        showBack: true,
        actions: [
          IconButton(
            tooltip: 'Vaciar',
            onPressed:
                () => _game.setConfig(_cfg = _cfg.copyWith(items: const [])),
            icon: PixelGlyph(
              kind: PixelGlyphKind.delete,
              color: Px.textDim,
              size: 18,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                GameWidget(game: _game),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    color: Px.bg.withValues(alpha: 0.7),
                    child: Text(
                      _placing != null
                          ? 'TOCA EL CUARTO PARA COLOCAR: ${Furniture.catalog[_placing]!.name.toUpperCase()}'
                          : _selected != null
                          ? 'ARRASTRA PARA MOVER · BORRA CON 🗑'
                          : 'ELIGE UN MUEBLE ABAJO',
                      style: Px.label(6, Px.text),
                    ),
                  ),
                ),
                if (_selected != null)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: PixelButton(
                      label: 'BORRAR',
                      small: true,
                      color: Px.danger,
                      textColor: Px.text,
                      glyph: PixelGlyphKind.delete,
                      onPressed: _game.removeSelected,
                    ),
                  ),
              ],
            ),
          ),
          // Pestañas.
          Container(
            color: Px.panel,
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [
                for (final (i, label) in const [
                  (0, 'MUEBLES'),
                  (1, 'PARED'),
                  (2, 'PISO'),
                  (3, 'EXTRAS'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: PixelChip(
                      label: label,
                      selected: _tab == i,
                      onTap: () => setState(() => _tab = i),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              color: Px.panel,
              padding: const EdgeInsets.all(8),
              child: switch (_tab) {
                0 => _catalog(),
                1 => _surfaces(RoomPalettes.walls, _cfg.wall, (i) {
                  _game.setWall(i);
                }),
                2 => _surfaces(RoomPalettes.floors, _cfg.floor, (i) {
                  _game.setFloor(i);
                }),
                _ => _extras(),
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Px.bg,
              border: Border(top: BorderSide(color: Px.border, width: 2)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_cfg.items.length} OBJETOS', style: Px.label(6)),
                    Text('Decoración libre', style: Px.label(6, Px.textDim)),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: 160,
                  child: PixelButton(
                    label: 'GUARDAR',
                    glyph: PixelGlyphKind.save,
                    onPressed: () {
                      AppState.I.setRoom(_cfg);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _catalog() => GridView.count(
    crossAxisCount: 5,
    mainAxisSpacing: 6,
    crossAxisSpacing: 6,
    children: [
      for (final e in Furniture.catalog.entries)
        GestureDetector(
          onTap: () => _pick(e.key),
          child: Container(
            decoration: BoxDecoration(
              color: _placing == e.key ? Px.panelLight : Px.bg,
              border: Border.all(
                color: _placing == e.key ? Px.accent : Px.border,
                width: 2,
              ),
            ),
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                Expanded(child: FurnitureThumb(type: e.key, size: 40)),
                Text(
                  e.value.name.toUpperCase(),
                  style: Px.label(4, Px.textDim),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
    ],
  );

  Widget _surfaces(
    List<Surface> list,
    int selected,
    ValueChanged<int> onPick,
  ) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (var i = 0; i < list.length; i++)
        GestureDetector(
          onTap: () => onPick(i),
          child: Container(
            width: 64,
            height: 54,
            decoration: BoxDecoration(
              color: list[i].base,
              border: Border.all(
                color: selected == i ? Px.accent : Px.bg,
                width: 3,
              ),
            ),
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Px.bg.withValues(alpha: 0.7),
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                list[i].name.toUpperCase(),
                style: Px.label(4, Px.text),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
    ],
  );

  Widget _extras() => ListView(
    children: [
      Row(
        children: [
          Text('MARCO DEL CUARTO', style: Px.label(7, Px.text)),
          const Spacer(),
          Switch(
            value: _cfg.rgbFrame,
            activeThumbColor: Px.accent,
            onChanged:
                (v) => setState(() {
                  _cfg = _cfg.copyWith(rgbFrame: v);
                  _game.setConfig(_cfg);
                }),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text('BANNER DEL PERFIL', style: Px.label(7, Px.text)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < RoomPalettes.banners.length; i++)
            GestureDetector(
              onTap: () => setState(() => _cfg = _cfg.copyWith(banner: i)),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _cfg.banner == i ? Px.accent : Px.bg,
                    width: 3,
                  ),
                ),
                child: SizedBox(
                  width: 90,
                  height: 40,
                  child: PixelBanner(index: i, height: 40),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 10),
      Text('NOMBRE DEL CUARTO', style: Px.label(7, Px.text)),
      const SizedBox(height: 6),
      TextFormField(
        initialValue: _cfg.title,
        style: Px.body,
        cursorColor: Px.accent,
        onChanged: (v) => _cfg = _cfg.copyWith(title: v.toUpperCase()),
        decoration: InputDecoration(
          isDense: true,
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
  );
}
