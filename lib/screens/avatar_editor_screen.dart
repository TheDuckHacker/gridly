import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/pixel_theme.dart';
import '../game/avatar_component.dart';
import '../game/avatar_stage_game.dart';
import '../widgets/pixel_avatar.dart';
import '../widgets/pixel_ui.dart';

/// Editor de avatar: la vista previa es una escena Flame que reacciona a
/// cada cambio (salto) y a los toques.
class AvatarEditorScreen extends StatefulWidget {
  const AvatarEditorScreen({super.key});

  @override
  State<AvatarEditorScreen> createState() => _AvatarEditorScreenState();
}

class _AvatarEditorScreenState extends State<AvatarEditorScreen> {
  late AvatarConfig _cfg = AppState.I.avatar;
  late final AvatarStageGame _game = AvatarStageGame(
    config: _cfg,
    showCampfire: false,
  );

  void _update(AvatarConfig c) {
    setState(() => _cfg = c);
    _game.setConfig(c);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PixelAppBar(title: 'EDITAR AVATAR', showBack: true),
      body: Column(
        children: [
          PixelPanel(
            padding: EdgeInsets.zero,
            shadow: false,
            child: SizedBox(height: 200, child: GameWidget(game: _game)),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final (label, mood) in const [
                  ('SALUDAR', AvatarMood.wave),
                  ('BAILAR', AvatarMood.dance),
                  ('SALTAR', AvatarMood.jump),
                  ('QUIETO', AvatarMood.idle),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: PixelChip(
                      label: label,
                      onTap: () => _game.avatar.setMood(mood),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _Section(
                  title: 'PIEL',
                  child: _ColorRow(
                    colors: AvatarParts.skins,
                    selected: _cfg.skin,
                    onPick: (i) => _update(_cfg.copyWith(skin: i)),
                  ),
                ),
                _Section(
                  title: 'PEINADO',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (
                        var i = 0;
                        i < AvatarParts.hairStyleNames.length;
                        i++
                      )
                        PixelChip(
                          label: AvatarParts.hairStyleNames[i].toUpperCase(),
                          selected: _cfg.hairStyle == i,
                          onTap: () => _update(_cfg.copyWith(hairStyle: i)),
                        ),
                    ],
                  ),
                ),
                _Section(
                  title: 'COLOR DE PELO',
                  child: _ColorRow(
                    colors: AvatarParts.hairs,
                    selected: _cfg.hair,
                    onPick: (i) => _update(_cfg.copyWith(hair: i)),
                  ),
                ),
                _Section(
                  title: 'CAMISETA',
                  child: _ColorRow(
                    colors: AvatarParts.shirts,
                    selected: _cfg.shirt,
                    onPick: (i) => _update(_cfg.copyWith(shirt: i)),
                  ),
                ),
                _Section(
                  title: 'PANTALÓN',
                  child: _ColorRow(
                    colors: AvatarParts.pants,
                    selected: _cfg.pants,
                    onPick: (i) => _update(_cfg.copyWith(pants: i)),
                  ),
                ),
                _Section(
                  title: 'ZAPATOS',
                  child: _ColorRow(
                    colors: AvatarParts.shoes,
                    selected: _cfg.shoes,
                    onPick: (i) => _update(_cfg.copyWith(shoes: i)),
                  ),
                ),
                _Section(
                  title: 'ACCESORIO',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (
                        var i = 0;
                        i < AvatarParts.accessoryNames.length;
                        i++
                      )
                        PixelChip(
                          label: AvatarParts.accessoryNames[i].toUpperCase(),
                          selected: _cfg.accessory == i,
                          onTap: () => _update(_cfg.copyWith(accessory: i)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                PixelButton(
                  label: 'GUARDAR',
                  glyph: PixelGlyphKind.save,
                  onPressed: () {
                    AppState.I.setAvatar(_cfg);
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Px.title(8)),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.colors,
    required this.selected,
    required this.onPick,
  });
  final List<Color> colors;
  final int selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (var i = 0; i < colors.length; i++)
        GestureDetector(
          onTap: () => onPick(i),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors[i],
              border: Border.all(
                color: selected == i ? Px.accent : Px.bg,
                width: 3,
              ),
            ),
          ),
        ),
    ],
  );
}
