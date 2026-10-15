import 'package:flutter/material.dart';

import '../core/pixel_theme.dart';

/// Panel con doble borde pixel.
class PixelPanel extends StatelessWidget {
  const PixelPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.color,
    this.border,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? border;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final borderC = border ?? Px.border;
    final fillC = color ?? Px.panel;
    return Container(
      decoration: BoxDecoration(
        color: borderC,
        boxShadow:
            shadow
                ? const [
                  BoxShadow(color: Color(0x99000000), offset: Offset(4, 4)),
                ]
                : null,
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        color: Px.bg,
        padding: const EdgeInsets.all(2),
        child: Container(color: fillC, padding: padding, child: child),
      ),
    );
  }
}

/// Botón con sombra dura que se hunde al pulsar.
class PixelButton extends StatefulWidget {
  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.textColor,
    this.icon,
    this.glyph,
    this.small = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final PixelGlyphKind? glyph;
  final bool small;
  final bool enabled;

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const depth = 3.0;
    final pressed = _down || !widget.enabled;
    final h = widget.small ? 32.0 : 44.0;
    final color = widget.color ?? Px.accent;
    final textColor = widget.textColor ?? Px.bg;
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: () => setState(() => _down = false),
      onTapUp:
          widget.enabled
              ? (_) {
                setState(() => _down = false);
                widget.onPressed();
              }
              : null,
      child: SizedBox(
        height: h + depth,
        child: Stack(
          children: [
            Positioned.fill(
              top: depth,
              child: Container(
                color: Color.lerp(color, Colors.black, 0.5),
              ),
            ),
            // Hijo no posicionado: define el tamaño del Stack, así el botón
            // funciona tanto a ancho completo como dentro de un Row.
            AnimatedPadding(
              duration: const Duration(milliseconds: 50),
              padding: EdgeInsets.only(
                top: pressed ? depth : 0,
                bottom: pressed ? 0 : depth,
              ),
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(
                  horizontal: widget.small ? 10 : 16,
                ),
                decoration: BoxDecoration(
                  color:
                      widget.enabled
                          ? color
                          : Color.lerp(color, Colors.black, 0.4),
                  border: Border.all(color: Px.bg, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.glyph != null)
                      PixelGlyph(
                        kind: widget.glyph!,
                        size: widget.small ? 12 : 16,
                        color: textColor,
                      )
                    else if (widget.icon != null)
                      Icon(
                        widget.icon,
                        size: widget.small ? 14 : 18,
                        color: textColor,
                      ),
                    if ((widget.glyph != null || widget.icon != null) &&
                        widget.label.isNotEmpty)
                      const SizedBox(width: 8),
                    if (widget.label.isNotEmpty)
                      Flexible(
                        child: Text(
                          widget.label,
                          textAlign: TextAlign.center,
                          style: Px.title(
                            widget.small ? 7 : 9,
                            textColor,
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
    );
  }
}

class PixelChip extends StatelessWidget {
  const PixelChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Px.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c : Px.panelLight,
          border: Border.all(color: selected ? c : Px.border, width: 2),
        ),
        child: Text(label, style: Px.label(7, selected ? Px.bg : Px.text)),
      ),
    );
  }
}

class PixelDivider extends StatelessWidget {
  const PixelDivider({super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Container(height: 2, color: Px.border)),
      Container(width: 6, height: 6, color: Px.accentDim),
      Expanded(child: Container(height: 2, color: Px.border)),
    ],
  );
}

/// Barra superior estilo HUD.
/// La flecha no sale sola: solo si [showBack] es true (chat y pantallas que tapan la barra).
class PixelAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PixelAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.showBack = false,
  });

  final String title;
  final List<Widget> actions;

  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      decoration: BoxDecoration(
        color: Px.panel,
        border: Border(bottom: BorderSide(color: Px.border, width: 2)),
      ),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            if (showBack)
              PixelBackButton(onPressed: () => Navigator.of(context).pop())
            else
              const SizedBox(width: 14),
            Container(width: 8, height: 8, color: Px.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: Px.title(10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ...actions,
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}

String compact(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1)}K';
  return '$n';
}

/// Cartita pixel redonda: mismo estilo que la barra de abajo.
class PixelIconCard extends StatelessWidget {
  const PixelIconCard({
    super.key,
    required this.kind,
    required this.onTap,
    this.tooltip,
    this.badge,
    this.color,
    this.ghost = false,
  });

  final PixelGlyphKind kind;
  final VoidCallback onTap;
  final String? tooltip;
  final String? badge;
  final Color? color;
  final bool ghost;

  @override
  Widget build(BuildContext context) {
    final box = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ghost ? Colors.transparent : Px.panelLight,
          shape: BoxShape.circle,
          border: Border.all(
            color: ghost ? Color(0x88FFFFFF) : Px.border,
            width: 2,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            PixelGlyph(kind: kind, size: 15, color: color ?? Px.text),
            if (badge != null)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  color: Px.danger,
                  child: Text(badge!, style: Px.label(4, Px.text)),
                ),
              ),
          ],
        ),
      ),
    );
    if (tooltip == null) return box;
    return Tooltip(message: tooltip!, child: box);
  }
}

/// Flecha pixel para salir. Solo en el chat y en pantallas que tapan la barra.
class PixelBackButton extends StatelessWidget {
  const PixelBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Salir',
      onPressed: onPressed,
      icon: PixelGlyph(kind: PixelGlyphKind.back, size: 16),
    );
  }
}

enum PixelGlyphKind {
  home,
  play,
  plus,
  chat,
  people,
  back,
  search,
  call,
  video,
  send,
  mic,
  micOff,
  attach,
  camera,
  more,
  emoji,
  check,
  phone,
  contact,
  heart,
  comment,
  share,
  repost,
  bookmark,
  coin,
  music,
  add,
  world,
  closet,
  room,
  link,
  sparkle,
  hangup,
  settings,
  edit,
  close,
  delete,
  save,
  gallery,
  switchCam,
  record,
  star,
  speaker,
  speakerOff,
  videoOff,
  wait,
  logout,
  refresh,
  chair,
  headset,
  face,
  image,
  remove,
}

/// Icono pixel dibujado en rejilla (estilo Flame / 8-bit), no Material.
class PixelGlyph extends StatelessWidget {
  const PixelGlyph({
    super.key,
    required this.kind,
    this.size = 16,
    this.color,
  });

  final PixelGlyphKind kind;
  final double size;
  final Color? color;

  /// Máscaras 8×8 dibujadas a mano (legibles a 14–18 px).
  static const _masks = <PixelGlyphKind, List<String>>{
    // Casa
    PixelGlyphKind.home: [
      '...##...',
      '..####..',
      '.##..##.',
      '##....##',
      '########',
      '.##..##.',
      '.##..##.',
      '.##..##.',
    ],
    // Play ▶
    PixelGlyphKind.play: [
      '.##.....',
      '.###....',
      '.####...',
      '.#####..',
      '.#####..',
      '.####...',
      '.###....',
      '.##.....',
    ],
    // +
    PixelGlyphKind.plus: [
      '........',
      '...##...',
      '...##...',
      '.######.',
      '.######.',
      '...##...',
      '...##...',
      '........',
    ],
    // Chat burbuja
    PixelGlyphKind.chat: [
      '.######.',
      '##....##',
      '#......#',
      '#......#',
      '##....##',
      '.######.',
      '...##...',
      '..##....',
    ],
    // Dos personas
    PixelGlyphKind.people: [
      '.##..##.',
      '.##..##.',
      '........',
      '.##..##.',
      '########',
      '##.##.##',
      '##....##',
      '........',
    ],
    // ←
    PixelGlyphKind.back: [
      '........',
      '...##...',
      '..##....',
      '.##.....',
      '.##.....',
      '..##....',
      '...##...',
      '........',
    ],
    // Lupa
    PixelGlyphKind.search: [
      '..####..',
      '.##..##.',
      '.##..##.',
      '.##..##.',
      '..####..',
      '....##..',
      '.....##.',
      '......##',
    ],
    // Teléfono
    PixelGlyphKind.call: [
      '....##..',
      '...####.',
      '...#..#.',
      '..##..##',
      '.##..##.',
      '##..##..',
      '.####...',
      '..##....',
    ],
    // Cámara de video
    PixelGlyphKind.video: [
      '........',
      '.#####..',
      '.#...#.#',
      '.#...###',
      '.#...#.#',
      '.#####..',
      '........',
      '........',
    ],
    // Enviar ▶
    PixelGlyphKind.send: [
      '##......',
      '###.....',
      '.###....',
      '..###...',
      '...###..',
      '..###...',
      '.###....',
      '###.....',
    ],
    // Mic
    PixelGlyphKind.mic: [
      '..####..',
      '.##..##.',
      '.##..##.',
      '.##..##.',
      '..####..',
      '...##...',
      '.######.',
      '..####..',
    ],
    PixelGlyphKind.micOff: [
      '#.####..',
      '.##..##.',
      '.##.#.#.',
      '.##..##.',
      '..##.#..',
      '...##.#.',
      '.######.',
      '..####.#',
    ],
    // Clip
    PixelGlyphKind.attach: [
      '....##..',
      '...#..#.',
      '..#..#.#',
      '.#..#..#',
      '#..#..#.',
      '.#..##..',
      '..##....',
      '........',
    ],
    // Cámara foto
    PixelGlyphKind.camera: [
      '..####..',
      '.##..##.',
      '########',
      '##....##',
      '##.##.##',
      '##....##',
      '########',
      '........',
    ],
    // ⋮
    PixelGlyphKind.more: [
      '........',
      '...##...',
      '........',
      '...##...',
      '........',
      '...##...',
      '........',
      '........',
    ],
    // Cara
    PixelGlyphKind.emoji: [
      '.######.',
      '##....##',
      '#.#..#.#',
      '#......#',
      '#.#..#.#',
      '##.####.',
      '.######.',
      '........',
    ],
    // ✓
    PixelGlyphKind.check: [
      '........',
      '......#.',
      '.....##.',
      '#...##..',
      '.##.##..',
      '..###...',
      '...#....',
      '........',
    ],
    // Celular
    PixelGlyphKind.phone: [
      '..####..',
      '.##..##.',
      '.##..##.',
      '.##..##.',
      '.##..##.',
      '.##..##.',
      '.##..##.',
      '..####..',
    ],
    // Persona +
    PixelGlyphKind.contact: [
      '...##...',
      '..####..',
      '..####..',
      '...##...',
      '......#.',
      '.#####.#',
      '......#.',
      '........',
    ],
    // Corazón
    PixelGlyphKind.heart: [
      '.##..##.',
      '########',
      '########',
      '.######.',
      '..####..',
      '...##...',
      '........',
      '........',
    ],
    // Comentario
    PixelGlyphKind.comment: [
      '.######.',
      '##....##',
      '#......#',
      '#......#',
      '##....##',
      '.####.#.',
      '......#.',
      '........',
    ],
    // Compartir (nodo)
    PixelGlyphKind.share: [
      '......##',
      '.....##.',
      '##..##..',
      '.####...',
      '##..##..',
      '.....##.',
      '......##',
      '........',
    ],
    // Republicar ↺
    PixelGlyphKind.repost: [
      '..####.#',
      '.##....#',
      '##......',
      '##..####',
      '####..##',
      '......##',
      '#....##.',
      '#.####..',
    ],
    // Marcador
    PixelGlyphKind.bookmark: [
      '######..',
      '##..##..',
      '##..##..',
      '##..##..',
      '##..##..',
      '##.#.##.',
      '##...##.',
      '##......',
    ],
    // Moneda
    PixelGlyphKind.coin: [
      '..####..',
      '.##..##.',
      '##.##.##',
      '##.#..##',
      '##.##.##',
      '##.#..##',
      '.##..##.',
      '..####..',
    ],
    // Nota musical
    PixelGlyphKind.music: [
      '....###.',
      '....#.#.',
      '....#.#.',
      '....##..',
      '..###...',
      '.####...',
      '.###....',
      '.##.....',
    ],
    PixelGlyphKind.add: [
      '........',
      '...##...',
      '...##...',
      '.######.',
      '.######.',
      '...##...',
      '...##...',
      '........',
    ],
    // Globo
    PixelGlyphKind.world: [
      '..####..',
      '.##..##.',
      '#.####.#',
      '#.#..#.#',
      '#.####.#',
      '.##..##.',
      '..####..',
      '........',
    ],
    // Closet / armario
    PixelGlyphKind.closet: [
      '########',
      '##....##',
      '##.##.##',
      '##.##.##',
      '##....##',
      '##.##.##',
      '##....##',
      '########',
    ],
    // Puerta
    PixelGlyphKind.room: [
      '.######.',
      '##....##',
      '##....##',
      '##....##',
      '##...###',
      '##....##',
      '##....##',
      '########',
    ],
    // Eslabón
    PixelGlyphKind.link: [
      '..####..',
      '.##..##.',
      '.##.....',
      '..####..',
      '....##..',
      '.##..##.',
      '..####..',
      '........',
    ],
    // Destello ✦
    PixelGlyphKind.sparkle: [
      '...##...',
      '...##...',
      '.##..##.',
      '##....##',
      '.##..##.',
      '...##...',
      '...##...',
      '........',
    ],
    // Colgar (auricular invertido)
    PixelGlyphKind.hangup: [
      '..####..',
      '.##..##.',
      '##....##',
      '........',
      '..####..',
      '.######.',
      '##....##',
      '........',
    ],
    // Engranaje
    PixelGlyphKind.settings: [
      '...##...',
      '.#.##.#.',
      '##....##',
      '#..##..#',
      '#..##..#',
      '##....##',
      '.#.##.#.',
      '...##...',
    ],
    // Lápiz
    PixelGlyphKind.edit: [
      '......##',
      '.....##.',
      '....##.#',
      '...##.#.',
      '..##.#..',
      '.##.#...',
      '##......',
      '#.......',
    ],
    // X gruesa (COLGAR)
    PixelGlyphKind.close: [
      '##....##',
      '###..###',
      '.######.',
      '..####..',
      '..####..',
      '.######.',
      '###..###',
      '##....##',
    ],
    // Papelera
    PixelGlyphKind.delete: [
      '..####..',
      '########',
      '.######.',
      '.##..##.',
      '.##..##.',
      '.##..##.',
      '.######.',
      '........',
    ],
    // Diskette
    PixelGlyphKind.save: [
      '########',
      '##....##',
      '##.##.##',
      '##.##.##',
      '##....##',
      '########',
      '##....##',
      '########',
    ],
    // Galería
    PixelGlyphKind.gallery: [
      '########',
      '##....##',
      '##.#..##',
      '##..#.##',
      '##...###',
      '##....##',
      '########',
      '........',
    ],
    // Cambiar cámara
    PixelGlyphKind.switchCam: [
      '..####.#',
      '.##..###',
      '##......',
      '##..####',
      '####..##',
      '......##',
      '###..##.',
      '#.####..',
    ],
    // Grabar ●
    PixelGlyphKind.record: [
      '........',
      '..####..',
      '.######.',
      '.######.',
      '.######.',
      '..####..',
      '........',
      '........',
    ],
    // Estrella
    PixelGlyphKind.star: [
      '...##...',
      '...##...',
      '.######.',
      '########',
      '..####..',
      '.##..##.',
      '##....##',
      '........',
    ],
    // Altavoz grueso (call)
    PixelGlyphKind.speaker: [
      '#.......',
      '##...#..',
      '###..##.',
      '####..#.',
      '####..#.',
      '###..##.',
      '##...#..',
      '#.......',
    ],
    PixelGlyphKind.speakerOff: [
      '#.....#.',
      '##...#.#',
      '###.#...',
      '####.#..',
      '####..#.',
      '###...#.',
      '##.#...#',
      '#.......',
    ],
    PixelGlyphKind.videoOff: [
      '##...###',
      '.##.###.',
      '..###.#.',
      '...##...',
      '..#.###.',
      '.###.##.',
      '###...##',
      '........',
    ],
    // Reloj / wait
    PixelGlyphKind.wait: [
      '..####..',
      '.##..##.',
      '##.##.##',
      '##..#.##',
      '##....##',
      '.##..##.',
      '..####..',
      '........',
    ],
    // Salir →
    PixelGlyphKind.logout: [
      '######..',
      '##......',
      '##..##..',
      '##.#####',
      '##..##..',
      '##......',
      '######..',
      '........',
    ],
    PixelGlyphKind.refresh: [
      '..####.#',
      '.##..###',
      '##......',
      '##......',
      '......##',
      '......##',
      '###..##.',
      '#.####..',
    ],
    // Silla
    PixelGlyphKind.chair: [
      '.##..##.',
      '.##..##.',
      '########',
      '##....##',
      '########',
      '...##...',
      '...##...',
      '..####..',
    ],
    // Auriculares
    PixelGlyphKind.headset: [
      '..####..',
      '.##..##.',
      '##....##',
      '##.##.##',
      '##.##.##',
      '.#.##.#.',
      '........',
      '........',
    ],
    PixelGlyphKind.face: [
      '.######.',
      '##....##',
      '#.#..#.#',
      '#......#',
      '#.#..#.#',
      '##.####.',
      '.######.',
      '........',
    ],
    // Imagen / paisaje
    PixelGlyphKind.image: [
      '########',
      '##....##',
      '##.#..##',
      '##..#.##',
      '##...###',
      '##....##',
      '########',
      '........',
    ],
    // Quitar persona
    PixelGlyphKind.remove: [
      '...##...',
      '..####..',
      '..####..',
      '...##...',
      '........',
      '.######.',
      '........',
      '........',
    ],
  };

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _PixelGlyphPainter(kind, color ?? Px.text),
    );
  }
}

/// Botón solo con glifo pixel (sin iconos de Android).
class PixelIconBtn extends StatelessWidget {
  const PixelIconBtn({
    super.key,
    required this.kind,
    required this.onPressed,
    this.color,
    this.size = 18,
    this.tooltip,
  });

  final PixelGlyphKind kind;
  final VoidCallback onPressed;
  final Color? color;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final btn = InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: PixelGlyph(kind: kind, size: size, color: color ?? Px.text),
      ),
    );
    if (tooltip == null) return btn;
    return Tooltip(message: tooltip!, child: btn);
  }
}

/// Icono pixel dentro de círculo (mismo look que la barra de abajo).
class PixelRoundIcon extends StatelessWidget {
  const PixelRoundIcon({
    super.key,
    required this.kind,
    this.size = 36,
    this.glyphSize,
    this.color,
    this.fill,
    this.borderColor,
    this.onTap,
    this.active = false,
  });

  final PixelGlyphKind kind;
  final double size;
  final double? glyphSize;
  final Color? color;
  final Color? fill;
  final Color? borderColor;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? Px.accent : (fill ?? Px.panelLight),
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? Px.accent : (borderColor ?? Px.border),
          width: 2,
        ),
      ),
      child: PixelGlyph(
        kind: kind,
        size: glyphSize 
        ?? (size * 0.48).clamp(12.0, 22.0),
        color: active ? Px.bg : (color ?? Px.text),
      ),
    );
    if (onTap == null) return child;
    return GestureDetector(onTap: onTap, child: child);
  }
}

class _PixelGlyphPainter extends CustomPainter {
  _PixelGlyphPainter(this.kind, this.color);

  final PixelGlyphKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rows = PixelGlyph._masks[kind]!;
    final n = rows.length;
    // Celdas enteras para que no se vea borroso.
    final cell = (size.width / n).floorToDouble().clamp(1.0, size.width);
    final origin = (size.width - cell * n) / 2;
    final paint =
        Paint()
          ..color = color
          ..isAntiAlias = false
          ..filterQuality = FilterQuality.none;
    for (var y = 0; y < n; y++) {
      final row = rows[y];
      for (var x = 0; x < row.length && x < n; x++) {
        if (row[x] != '#') continue;
        canvas.drawRect(
          Rect.fromLTWH(origin + x * cell, origin + y * cell, cell, cell),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelGlyphPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}
