import 'package:flutter/material.dart';

/// Un mueble/adorno colocado en la habitación.
class RoomItem {
  const RoomItem({required this.type, required this.x, required this.y});

  /// Clave del catálogo [Furniture.catalog].
  final String type;

  /// Posición horizontal (0..1 del ancho del cuarto).
  final double x;

  /// Para muebles de piso: profundidad 0 (fondo) .. 1 (frente).
  /// Para adornos de pared: altura 0 (techo) .. 1 (zócalo).
  final double y;

  RoomItem copyWith({double? x, double? y}) =>
      RoomItem(type: type, x: x ?? this.x, y: y ?? this.y);
}

/// Configuración completa de la habitación de un usuario.
class RoomConfig {
  const RoomConfig({
    this.wall = 0,
    this.floor = 0,
    this.items = const [],
    this.rgbFrame = false,
    this.banner = 0,
    this.title = 'MI CUARTO',
  });

  final int wall;
  final int floor;
  final List<RoomItem> items;
  final bool rgbFrame;
  final int banner;
  final String title;

  RoomConfig copyWith({
    int? wall,
    int? floor,
    List<RoomItem>? items,
    bool? rgbFrame,
    int? banner,
    String? title,
  }) => RoomConfig(
    wall: wall ?? this.wall,
    floor: floor ?? this.floor,
    items: items ?? this.items,
    rgbFrame: rgbFrame ?? this.rgbFrame,
    banner: banner ?? this.banner,
    title: title ?? this.title,
  );
}

/// Paletas de pared y piso (color base, color de detalle, nombre).
class Surface {
  const Surface(this.name, this.base, this.detail);
  final String name;
  final Color base;
  final Color detail;
}

abstract final class RoomPalettes {
  static const walls = <Surface>[
    Surface('Noche', Color(0xFF1B1B33), Color(0xFF24244A)),
    Surface('Grafito', Color(0xFF23232B), Color(0xFF2E2E39)),
    Surface('Vino', Color(0xFF3A1B33), Color(0xFF4A2444)),
    Surface('Océano', Color(0xFF13303D), Color(0xFF1A4050)),
    Surface('Bosque', Color(0xFF17301F), Color(0xFF1F402B)),
    Surface('Rosa', Color(0xFF4A2340), Color(0xFF5C2E50)),
    Surface('Crema', Color(0xFFD9CBB0), Color(0xFFC9B99A)),
    Surface('Cielo', Color(0xFF2B4C7E), Color(0xFF35598F)),
  ];
  static const floors = <Surface>[
    Surface('Madera', Color(0xFF5A3A24), Color(0xFF6B4630)),
    Surface('Madera clara', Color(0xFF9A6B3F), Color(0xFFAD7B4B)),
    Surface('Baldosa', Color(0xFF2E2E3E), Color(0xFF3A3A4E)),
    Surface('Alfombra', Color(0xFF3B2A5A), Color(0xFF46336B)),
    Surface('Césped', Color(0xFF2E6B3A), Color(0xFF357A44)),
    Surface('Neón', Color(0xFF101020), Color(0xFF1C1C3A)),
    Surface('Mármol', Color(0xFFBFC3CF), Color(0xFFD2D6E0)),
  ];
  static const banners = <List<Color>>[
    [Color(0xFF7B5CFF), Color(0xFFFF3BD4)],
    [Color(0xFF1FD6FF), Color(0xFF3BFF9E)],
    [Color(0xFFFF8A1F), Color(0xFFFF3B5C)],
    [Color(0xFF101020), Color(0xFF2B2B40)],
    [Color(0xFFFFE31A), Color(0xFFFF8A1F)],
  ];
}

/// Catálogo de muebles dibujados por caracteres (como el avatar).
class Furniture {
  const Furniture({
    required this.name,
    required this.rows,
    required this.colors,
    this.onWall = false,
    this.glow,
    this.price = 0,
    this.sittable = false,
  });

  final String name;
  final List<String> rows;
  final Map<String, Color> colors;

  /// Si se cuelga en la pared en vez de apoyarse en el piso.
  final bool onWall;

  /// Carácter cuyo color se anima con el espectro RGB (pantallas, neón).
  final String? glow;
  final int price;

  /// Se puede sentar el avatar aquí (silla, puff, cama…).
  final bool sittable;

  int get w => rows.first.length;
  int get h => rows.length;

  static const _k = Color(0xFF14121A); // contorno
  static const _wood = Color(0xFF7A4B2A);
  static const _woodD = Color(0xFF5A3620);
  static const _metal = Color(0xFF3A3A4A);
  static const _metalL = Color(0xFF5A5A70);
  static const _white = Color(0xFFEDEDF5);

  static const catalog = <String, Furniture>{
    'bed': Furniture(
      name: 'Cama',
      rows: [
        '.kkkkkkkk...............',
        '.kppppppk...............',
        '.kppppppkkkkkkkkkkkkkkk.',
        '.kpwwwwpbbbbbbbbbbbbbbk.',
        '.kpwwwwpbbbbbbbbbbbbbbk.',
        '.kppppppBBBBBBBBBBBBBBk.',
        '.kkkkkkkkkkkkkkkkkkkkkk.',
        '.kmmk..............kmmk.',
        '.kkkk..............kkkk.',
      ],
      colors: {
        'k': _k,
        'p': Color(0xFF3B2A5A),
        'w': _white,
        'b': Color(0xFF7B5CFF),
        'B': Color(0xFF5A3FC9),
        'm': _woodD,
      },
      price: 120,
      sittable: true,
    ),
    'desk': Furniture(
      name: 'Escritorio gamer',
      rows: [
        '......kkkkkkkkkk........',
        '......kssssssssk........',
        '......kssssssssk........',
        '......kssssssssk........',
        '......kkkkkkkkkk..kk....',
        '.........kmmk.....kak...',
        'kkkkkkkkkkkkkkkkkkkkkkkk',
        'kwwwwwwwwwwwwwwwwwwwwwwk',
        'kkkkkkkkkkkkkkkkkkkkkkkk',
        '.kmk................kmk.',
        '.kmk................kmk.',
        '.kmk................kmk.',
      ],
      colors: {
        'k': _k,
        's': Color(0xFF3BFF9E),
        'm': _metal,
        'w': _wood,
        'a': Color(0xFF1FD6FF),
      },
      glow: 's',
      price: 250,
    ),
    'chair': Furniture(
      name: 'Silla gamer',
      rows: [
        '..kkkkkk..',
        '.krrrrrrk.',
        '.krRRRRrk.',
        '.krrrrrrk.',
        '.krrrrrrk.',
        '..kkkkkk..',
        '.kkkkkkkk.',
        '.krrrrrrk.',
        '.kkkkkkkk.',
        '....kk....',
        '..kkkkkk..',
      ],
      colors: {'k': _k, 'r': Color(0xFFFF3B5C), 'R': Color(0xFF14121A)},
      price: 90,
      sittable: true,
    ),
    'plant': Furniture(
      name: 'Planta',
      rows: [
        '...gg..gg...',
        '..gGGggGGg..',
        '.gGGGGGGGGg.',
        '..gGGGGGGg..',
        '....gGGg....',
        '....kkkk....',
        '...kppppk...',
        '...kppppk...',
        '....kkkk....',
      ],
      colors: {
        'k': _k,
        'g': Color(0xFF2E8B57),
        'G': Color(0xFF3BFF9E),
        'p': Color(0xFFC96A3B),
      },
      price: 40,
    ),
    'lamp': Furniture(
      name: 'Lámpara',
      rows: [
        '.kkkkkk.',
        'kllllllk',
        'kllllllk',
        '.kkkkkk.',
        '...kk...',
        '...kk...',
        '...kk...',
        '..kkkk..',
      ],
      colors: {'k': _k, 'l': Color(0xFFFFE31A)},
      glow: 'l',
      price: 60,
    ),
    'shelf': Furniture(
      name: 'Repisa',
      rows: [
        'kkkkkkkkkkkkkkkk',
        'kwwwwwwwwwwwwwwk',
        'kkkkkkkkkkkkkkkk',
        '.kbrkgkk.kykbbk.',
        '.kbrkgkk.kykbbk.',
        '.kbrkgkk.kykbbk.',
        'kkkkkkkkkkkkkkkk',
        'kwwwwwwwwwwwwwwk',
        'kkkkkkkkkkkkkkkk',
      ],
      colors: {
        'k': _k,
        'w': _wood,
        'b': Color(0xFF4D6BFF),
        'r': Color(0xFFFF3B5C),
        'g': Color(0xFF3BFF9E),
        'y': Color(0xFFFFE31A),
      },
      onWall: true,
      price: 70,
    ),
    'poster': Furniture(
      name: 'Póster',
      rows: [
        'kkkkkkkkkkkk',
        'kppppppppppk',
        'kpp.pppp.ppk',
        'kppppppppppk',
        'kpppp..ppppk',
        'kppp....pppk',
        'kppppppppppk',
        'kppppppppppk',
        'kkkkkkkkkkkk',
      ],
      colors: {'k': _k, 'p': Color(0xFFFF3BD4), '.': Color(0xFF14121A)},
      onWall: true,
      price: 25,
    ),
    'window': Furniture(
      name: 'Ventana',
      rows: [
        'kkkkkkkkkkkkkkkkkk',
        'knnnnnnnnknnnnnnnk',
        'knnnnnnnnknnnnnnnk',
        'knnnnnnnnknnnnnnnk',
        'knnnnnnnnknnnnnnnk',
        'kkkkkkkkkkkkkkkkkk',
        'knnnnnnnnknnnnnnnk',
        'knnnnnnnnknnnnnnnk',
        'knnnnnnnnknnnnnnnk',
        'knnnnnnnnknnnnnnnk',
        'kkkkkkkkkkkkkkkkkk',
      ],
      colors: {'k': Color(0xFF3A3A4A), 'n': Color(0xFF1B2A4A)},
      onWall: true,
      glow: 'n',
      price: 80,
    ),
    'neon': Furniture(
      name: 'Letrero neón',
      rows: [
        '..nnnnnnnnn...',
        '.nn.......nn..',
        'nn...nnn...nn.',
        'nn..n...n..nn.',
        'nn...nnn...nn.',
        '.nn.......nn..',
        '..nnnnnnnnn...',
      ],
      colors: {'n': Color(0xFF1FD6FF)},
      onWall: true,
      glow: 'n',
      price: 150,
    ),
    'tv': Furniture(
      name: 'TV',
      rows: [
        'kkkkkkkkkkkkkkkkkkkk',
        'kssssssssssssssssssk',
        'kssssssssssssssssssk',
        'kssssssssssssssssssk',
        'kssssssssssssssssssk',
        'kssssssssssssssssssk',
        'kkkkkkkkkkkkkkkkkkkk',
        '.........kk.........',
        '......kkkkkkkk......',
      ],
      colors: {'k': _k, 's': Color(0xFF4D6BFF)},
      glow: 's',
      price: 200,
    ),
    'speaker': Furniture(
      name: 'Parlante',
      rows: [
        'kkkkkk',
        'kmmmmk',
        'kmkkmk',
        'kmmmmk',
        'kmkkmk',
        'kmkkmk',
        'kmmmmk',
        'kkkkkk',
      ],
      colors: {'k': _k, 'm': _metalL},
      price: 55,
    ),
    'rug': Furniture(
      name: 'Alfombra',
      rows: [
        '..rrrrrrrrrrrrrrrrrrrr..',
        '.rRRRRRRRRRRRRRRRRRRRRr.',
        'rRrrrrrrrrrrrrrrrrrrrrRr',
        '.rRRRRRRRRRRRRRRRRRRRRr.',
        '..rrrrrrrrrrrrrrrrrrrr..',
      ],
      colors: {'r': Color(0xFF9D4DFF), 'R': Color(0xFF7B3FD9)},
      price: 35,
    ),
    'trophy': Furniture(
      name: 'Trofeo',
      rows: ['kkkkkkk', 'kyyyyyk', '.kyyyk.', '..kyk..', '..kyk..', '.kkkkk.'],
      colors: {'k': _k, 'y': Color(0xFFFFD23B)},
      price: 300,
    ),
    'cat': Furniture(
      name: 'Gato',
      rows: ['k.k.....', 'kkk..kk.', 'kwkkkkk.', 'kkkkkkkk', 'k.k..k.k'],
      colors: {'k': Color(0xFF2A2A33), 'w': Color(0xFF3BFF9E)},
      price: 999,
    ),
    'beanbag': Furniture(
      name: 'Puff',
      rows: [
        '....kkkkkk....',
        '..kkccccccckk.',
        '.kccccccccccck',
        '.kccccccccccck',
        '..kkkkkkkkkkk.',
      ],
      colors: {'k': _k, 'c': Color(0xFF1FD6FF)},
      price: 45,
      sittable: true,
    ),
    'whiteboard': Furniture(
      name: 'Pizarra',
      rows: [
        'kkkkkkkkkkkkkkkkkkkkkk',
        'kwwwwwwwwwwwwwwwwwwwwk',
        'kwrrrrwwwwbbbbbwwwwwwk',
        'kwwwwwwwwwwwwwwwwwwwwk',
        'kwwggggggwwwwwwrrrwwwk',
        'kwwwwwwwwwwwwwwwwwwwwk',
        'kkkkkkkkkkkkkkkkkkkkkk',
      ],
      colors: {
        'k': _k,
        'w': _white,
        'r': Color(0xFFFF3B5C),
        'b': Color(0xFF4D6BFF),
        'g': Color(0xFF2E8B57),
      },
      onWall: true,
      price: 60,
    ),
  };

  static final Paint _paint = Paint();

  /// Dibuja el mueble en el origen; cada celda mide [cell] px.
  static void paint(
    Canvas canvas,
    Furniture f,
    double cell, {
    Color? glowColor,
    int fromRow = 0,
    int? toRow,
  }) {
    final end = toRow ?? f.rows.length;
    for (var y = fromRow; y < end && y < f.rows.length; y++) {
      final row = f.rows[y];
      for (var x = 0; x < row.length; x++) {
        final ch = row[x];
        var color = f.colors[ch];
        if (color == null) continue;
        if (glowColor != null && ch == f.glow) {
          color = Color.lerp(color, glowColor, 0.75)!;
        }
        _paint.color = color;
        canvas.drawRect(
          Rect.fromLTWH(x * cell, y * cell, cell + 0.5, cell + 0.5),
          _paint,
        );
      }
    }
  }
}

/// Habitaciones de ejemplo de otros usuarios.
abstract final class MockRooms {
  static const mine = RoomConfig(
    wall: 0,
    floor: 0,
    items: [
      RoomItem(type: 'window', x: 0.25, y: 0.25),
      RoomItem(type: 'poster', x: 0.72, y: 0.3),
      RoomItem(type: 'neon', x: 0.5, y: 0.1),
      RoomItem(type: 'bed', x: 0.22, y: 0.2),
      RoomItem(type: 'desk', x: 0.72, y: 0.3),
      RoomItem(type: 'chair', x: 0.62, y: 0.55),
      RoomItem(type: 'plant', x: 0.95, y: 0.6),
      RoomItem(type: 'rug', x: 0.45, y: 0.85),
    ],
  );

  static const others = <String, RoomConfig>{
    'nova': RoomConfig(
      wall: 2,
      floor: 3,
      banner: 0,
      title: 'CUARTO DE NOVA',
      items: [
        RoomItem(type: 'poster', x: 0.2, y: 0.3),
        RoomItem(type: 'poster', x: 0.4, y: 0.3),
        RoomItem(type: 'neon', x: 0.75, y: 0.15),
        RoomItem(type: 'tv', x: 0.75, y: 0.25),
        RoomItem(type: 'speaker', x: 0.55, y: 0.3),
        RoomItem(type: 'speaker', x: 0.93, y: 0.3),
        RoomItem(type: 'beanbag', x: 0.3, y: 0.7),
        RoomItem(type: 'cat', x: 0.6, y: 0.85),
      ],
    ),
    'byte': RoomConfig(
      wall: 3,
      floor: 5,
      banner: 1,
      title: 'LAB DE BYTE',
      items: [
        RoomItem(type: 'shelf', x: 0.25, y: 0.3),
        RoomItem(type: 'window', x: 0.7, y: 0.25),
        RoomItem(type: 'desk', x: 0.3, y: 0.25),
        RoomItem(type: 'desk', x: 0.72, y: 0.25),
        RoomItem(type: 'chair', x: 0.3, y: 0.55),
        RoomItem(type: 'lamp', x: 0.92, y: 0.5),
        RoomItem(type: 'trophy', x: 0.08, y: 0.6),
      ],
    ),
    'kael': RoomConfig(
      wall: 4,
      floor: 4,
      banner: 2,
      title: 'JARDÍN DE KAEL',
      items: [
        RoomItem(type: 'window', x: 0.5, y: 0.25),
        RoomItem(type: 'plant', x: 0.15, y: 0.4),
        RoomItem(type: 'plant', x: 0.85, y: 0.4),
        RoomItem(type: 'plant', x: 0.3, y: 0.8),
        RoomItem(type: 'beanbag', x: 0.6, y: 0.7),
        RoomItem(type: 'cat', x: 0.8, y: 0.9),
      ],
    ),
    'mara': RoomConfig(
      wall: 5,
      floor: 1,
      banner: 4,
      title: 'ESTUDIO DE MARA',
      items: [
        RoomItem(type: 'poster', x: 0.3, y: 0.3),
        RoomItem(type: 'shelf', x: 0.7, y: 0.3),
        RoomItem(type: 'bed', x: 0.25, y: 0.3),
        RoomItem(type: 'lamp', x: 0.5, y: 0.4),
        RoomItem(type: 'rug', x: 0.6, y: 0.85),
        RoomItem(type: 'speaker', x: 0.9, y: 0.6),
      ],
    ),
  };
}
