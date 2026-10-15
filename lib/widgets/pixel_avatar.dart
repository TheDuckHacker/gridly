import 'package:flutter/material.dart';

import '../core/pixel_theme.dart';

/// Configuración de un avatar: índices sobre las paletas de [AvatarParts].
class AvatarConfig {
  const AvatarConfig({
    this.skin = 0,
    this.hair = 0,
    this.hairStyle = 0,
    this.shirt = 0,
    this.pants = 0,
    this.shoes = 0,
    this.accessory = 0,
  });

  final int skin;
  final int hair;
  final int hairStyle;
  final int shirt;
  final int pants;
  final int shoes;
  final int accessory;

  AvatarConfig copyWith({
    int? skin,
    int? hair,
    int? hairStyle,
    int? shirt,
    int? pants,
    int? shoes,
    int? accessory,
  }) => AvatarConfig(
    skin: skin ?? this.skin,
    hair: hair ?? this.hair,
    hairStyle: hairStyle ?? this.hairStyle,
    shirt: shirt ?? this.shirt,
    pants: pants ?? this.pants,
    shoes: shoes ?? this.shoes,
    accessory: accessory ?? this.accessory,
  );

  Map<String, int> toJson() => {
    'skin': skin,
    'hair': hair,
    'hairStyle': hairStyle,
    'shirt': shirt,
    'pants': pants,
    'shoes': shoes,
    'accessory': accessory,
  };

  @override
  bool operator ==(Object other) =>
      other is AvatarConfig &&
      other.skin == skin &&
      other.hair == hair &&
      other.hairStyle == hairStyle &&
      other.shirt == shirt &&
      other.pants == pants &&
      other.shoes == shoes &&
      other.accessory == accessory;

  @override
  int get hashCode =>
      Object.hash(skin, hair, hairStyle, shirt, pants, shoes, accessory);
}

abstract final class AvatarParts {
  static const skins = [
    Color(0xFFF5D6B8),
    Color(0xFFE0A878),
    Color(0xFFB87A4A),
    Color(0xFF7A4A2A),
    Color(0xFF8FE39A), // zombi / alien
    Color(0xFF9AB8F5), // robot
  ];
  static const hairs = [
    Color(0xFF1A1410),
    Color(0xFF6B3A1A),
    Color(0xFF2F5A3A),
    Color(0xFFE8C96A),
    Color(0xFFD9535F),
    Color(0xFF7CF59A),
    Color(0xFF8A5CF5),
    Color(0xFFF0E0C0),
  ];
  static const shirts = [
    Color(0xFF2E7D45),
    Color(0xFF1F3A5A),
    Color(0xFF8A2F2F),
    Color(0xFF3B2A5A),
    Color(0xFFE8C96A),
    Color(0xFF222222),
    Color(0xFFD95F8A),
    Color(0xFF3FA75C),
    Color(0xFFFF3BD4), // RGB magenta
    Color(0xFF1FD6FF), // cian gamer
  ];
  static const pants = [
    Color(0xFF1A1A28),
    Color(0xFF2A3A5A),
    Color(0xFF3B2A1A),
    Color(0xFF222222),
    Color(0xFF4A1F4A),
    Color(0xFF1F4A3A),
    Color(0xFFE8E8F0), // jogger claro
    Color(0xFF7B5CFF),
  ];
  static const shoes = [
    Color(0xFF2A1F14),
    Color(0xFF111111),
    Color(0xFFF2F2FF),
    Color(0xFFFF3B5C),
    Color(0xFF3BFF9E),
    Color(0xFF1FD6FF),
    Color(0xFFE8C96A),
  ];
  static const shirtNames = [
    'Hoodie verde',
    'Camisa navy',
    'Roja',
    'Morada',
    'Dorada',
    'Negra',
    'Rosa',
    'Gamer',
    'Magenta RGB',
    'Cian RGB',
  ];
  static const pantsNames = [
    'Jeans oscuro',
    'Cargo blue',
    'Café',
    'Negro',
    'Violeta',
    'Forest',
    'Jogger',
    'RGB pants',
  ];
  static const shoesNames = [
    'Botas',
    'Negras',
    'Blancas',
    'Rojas',
    'Verdes',
    'Cian',
    'Gold',
  ];
  static const hairStyleNames = ['Corto', 'Punk', 'Largo', 'Capucha', 'Calvo'];
  static const accessoryNames = [
    'Nada',
    'Lentes',
    'Audífonos',
    'Corona',
    'Visor',
  ];
}

/// Look guardado en el closet (estilo Sims).
class OutfitLook {
  const OutfitLook(this.name, this.config);
  final String name;
  final AvatarConfig config;
}

/// Avatar pixel-art de 16x16 celdas, dibujado por capas con [CustomPainter].
class PixelAvatar extends StatefulWidget {
  const PixelAvatar({
    super.key,
    required this.config,
    this.size = 48,
    this.animate = false,
    this.flip = false,
  });

  final AvatarConfig config;
  final double size;
  final bool animate;
  final bool flip;

  @override
  State<PixelAvatar> createState() => _PixelAvatarState();
}

class _PixelAvatarState extends State<PixelAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(PixelAvatar old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_c.isAnimating) _c.repeat(reverse: true);
    if (!widget.animate && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cell = widget.size / 16;
    return AnimatedBuilder(
      animation: _c,
      builder:
          (_, child) => Transform.translate(
            offset: Offset(0, widget.animate && _c.value > 0.5 ? cell * 0.35 : 0),
            child: child,
          ),
      child: Transform.flip(
        flipX: widget.flip,
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: _AvatarPainter(widget.config),
        ),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  _AvatarPainter(this.cfg);

  final AvatarConfig cfg;

  @override
  void paint(Canvas canvas, Size size) =>
      AvatarRenderer.paint(canvas, size.width / 16, cfg);

  @override
  bool shouldRepaint(_AvatarPainter old) => old.cfg != cfg;
}

/// Renderizador compartido: lo usan el [CustomPainter] (miniaturas) y el
/// componente de Flame `PixelAvatarComponent` (avatar animado en escena).
abstract final class AvatarRenderer {
  /// Sprite original estable (16×16).
  static const _body = [
    '................',
    '................',
    '.....oooooo.....',
    '....osssssso....',
    '...osssssssso...',
    '...ossesssesso..',
    '...osssmmmssso..',
    '....osssssso....',
    '.....otttto.....',
    '...ootttttttoo..',
    '..osotttttttoso.',
    '..osotttttttoso.',
    '..oo.ottttto.oo.',
  ];

  static const _legs = <List<String>>[
    ['.....opp.ppo....', '.....opp.ppo....', '.....obb.bbo....'],
    ['....opp...ppo...', '...opp.....ppo..', '...obb.....bbo..'],
    ['.....opp.ppo....', '....opp..ppo....', '....obb..bbo....'],
  ];

  static const walkFrames = 3;

  static const _hairStyles = <List<String>>[
    // Corto
    [
      '................',
      '.....hhhhhh.....',
      '....hhhhhhhh....',
      '...ohhhhhhhho...',
      '...oh.......ho..',
    ],
    // Punk
    [
      '....h..h..h.....',
      '...hhhhhhhhhh...',
      '...hhhhhhhhhh...',
      '...ohhhhhhhho...',
      '...ohh......o...',
    ],
    // Largo
    [
      '................',
      '.....hhhhhh.....',
      '....hhhhhhhh....',
      '...hhhhhhhhhhh..',
      '..hhh.......hh..',
      '..hh.........hh.',
      '..hh.........hh.',
      '..hh.........hh.',
      '..h...........h.',
    ],
    // Capucha
    [
      '................',
      '.....hhhhhh.....',
      '....hhhhhhhh....',
      '...hhhhhhhhhhh..',
      '...hh.......hh..',
      '...h.........h..',
      '...h.........h..',
      '....h.......h...',
      '....hhh...hhh...',
    ],
    // Calvo
    <String>[],
  ];

  static const _accessories = <List<String>>[
    <String>[],
    // Lentes (fila 5)
    ['', '', '', '', '', '.....ggg.ggg....'],
    // Audífonos
    [
      '',
      '',
      '...aaaaaaaaaa...',
      '..a..........a..',
      '..aa........aa..',
      '..aa........aa..',
    ],
    // Corona
    ['....c.cc.cc.c...', '....cccccccc....'],
    // Visor
    ['', '', '', '', '', '....vvvvvvvvv...'],
  ];

  static final Paint _paint = Paint();

  /// Dibuja el avatar en el origen del canvas; cada celda mide [cell] px.
  /// [legFrame] selecciona la pose de las piernas (ver [_legs]).
  static void paint(
    Canvas canvas,
    double cell,
    AvatarConfig cfg, {
    int legFrame = 0,
    bool wave = false,
    bool walking = false,
    int waveFrame = 0,
    bool happy = false,
  }) {
    final paint = _paint;
    final skin = AvatarParts.skins[cfg.skin % AvatarParts.skins.length];
    final hair = AvatarParts.hairs[cfg.hair % AvatarParts.hairs.length];
    final shirt = AvatarParts.shirts[cfg.shirt % AvatarParts.shirts.length];
    final pants = AvatarParts.pants[cfg.pants % AvatarParts.pants.length];
    final shoes = AvatarParts.shoes[cfg.shoes % AvatarParts.shoes.length];
    final colors = <String, Color>{
      'o': const Color(0xFF14110E),
      's': skin,
      'm': Color.lerp(skin, Colors.black, 0.25)!,
      'e': const Color(0xFF14110E),
      't': shirt,
      'p': pants,
      'b': shoes,
      'h': hair,
      'g': const Color(0xFF1C2E3A),
      'a': const Color(0xFF3FA75C),
      'c': const Color(0xFFE8C96A),
      'v': const Color(0xCC7CF59A),
    };

    void drawRows(List<String> rows, [int y0 = 0]) {
      for (var y = 0; y < rows.length; y++) {
        final row = rows[y];
        for (var x = 0; x < row.length && x < 16; x++) {
          final ch = row[x];
          final color = colors[ch];
          if (color == null) continue;
          paint.color = color;
          canvas.drawRect(
            Rect.fromLTWH(x * cell, (y + y0) * cell, cell, cell),
            paint,
          );
        }
      }
    }

    drawRows(_body);
    if (happy) {
      // Boca sonrisa (cubre la línea plana).
      paint.color = skin;
      canvas.drawRect(Rect.fromLTWH(6 * cell, 6 * cell, 4 * cell, cell), paint);
      paint.color = const Color(0xFF14110E);
      canvas.drawRect(
        Rect.fromLTWH(6 * cell, 6.35 * cell, cell, cell * 0.65),
        paint,
      );
      canvas.drawRect(
        Rect.fromLTWH(7 * cell, 6.7 * cell, 2 * cell, cell * 0.65),
        paint,
      );
      canvas.drawRect(
        Rect.fromLTWH(9 * cell, 6.35 * cell, cell, cell * 0.65),
        paint,
      );
    }
    drawRows(_legs[legFrame % _legs.length], _body.length);
    drawRows(_hairStyles[cfg.hairStyle % _hairStyles.length]);
    drawRows(_accessories[cfg.accessory % _accessories.length]);
  }
}

/// Avatar (o foto) con marco RGB y punto de presencia.
class AvatarBadge extends StatelessWidget {
  const AvatarBadge({
    super.key,
    required this.config,
    this.size = 40,
    this.status = PresenceStatus.online,
    this.animate = false,
    this.rgb = false,
    this.photo,
    this.ghost = false,
  });

  final AvatarConfig config;
  final double size;
  final PresenceStatus status;
  final bool animate;
  final bool rgb;
  final ImageProvider? photo;

  /// Sin caja de fondo (para flotar sobre clips).
  final bool ghost;

  @override
  Widget build(BuildContext context) {
    final dot = size * 0.3;
    final inner =
        photo != null
            ? Image(
              image: photo!,
              fit: BoxFit.cover,
              width: size - 8,
              height: size - 8,
            )
            : PixelAvatar(config: config, size: size - 8, animate: animate);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (rgb)
            RgbFrame(
              thickness: 2,
              segment: 4,
              padding: const EdgeInsets.all(2),
              child: inner,
            )
          else if (ghost)
            inner
          else
            Container(
              decoration: BoxDecoration(
                color: Px.panelLight,
                border: Border.all(color: Px.border, width: 2),
              ),
              padding: const EdgeInsets.all(2),
              child: inner,
            ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: dot,
              height: dot,
              decoration: BoxDecoration(
                color: status.color,
                border: Border.all(color: Px.bg, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum PresenceStatus {
  online,
  idle,
  dnd,
  offline;

  Color get color => switch (this) {
        PresenceStatus.online => Px.online,
        PresenceStatus.idle => Px.idle,
        PresenceStatus.dnd => Px.danger,
        PresenceStatus.offline => Px.offline,
      };
}
