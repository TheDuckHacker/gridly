import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import '../core/pixel_theme.dart';
import '../core/room.dart';
import '../widgets/pixel_avatar.dart';
import 'avatar_component.dart';

/// Habitación decorable (vista lateral, estilo Habbo/Pou) hecha con Flame.
///
/// - Pared + piso con paletas elegibles.
/// - Muebles pixel-art colocables, arrastrables y con brillo RGB.
/// - Tu avatar camina al punto del piso que toques; los visitantes deambulan
///   y hablan con burbujas.
class RoomGame extends FlameGame {
  RoomGame({
    required RoomConfig config,
    required this.me,
    required this.myName,
    this.editable = false,
    this.onChanged,
    this.onSelection,
  }) : _config = config;

  RoomConfig _config;
  RoomConfig get config => _config;
  final AvatarConfig me;
  final String myName;
  final bool editable;
  final void Function(RoomConfig)? onChanged;
  final void Function(int? selectedIndex)? onSelection;

  late PixelAvatarComponent player;
  final List<_FurnitureComponent> _furniture = [];
  final List<_Visitor> _visitors = [];
  final Random _rng = Random();

  /// Tipo de mueble que se colocará al tocar (modo edición).
  String? placing;
  int? selected;
  double t = 0;

  double get cell => (size.y / 44).clamp(2.0, 5.5);
  double get wallH => size.y * 0.55;

  @override
  Color backgroundColor() => Px.bg;

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    world.add(_Backdrop());
    world.add(_TapLayer());
    player = PixelAvatarComponent(
      config: me,
      cellSize: cell,
      name: myName,
      position: Vector2(size.x * 0.5, wallH + (size.y - wallH) * 0.6),
    );
    world.add(player);
    _rebuildFurniture();
  }

  @override
  void update(double dt) {
    super.update(dt);
    t += dt;
    player.priority = player.position.y.toInt();
    for (final v in _visitors) {
      v.avatar.priority = v.avatar.position.y.toInt();
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      player.cell = cell;
      player.position = Vector2(
        player.position.x.clamp(0, size.x),
        player.position.y.clamp(wallH, size.y),
      );
      for (final f in _furniture) {
        f.layout();
      }
      for (final v in _visitors) {
        v.avatar.cell = cell;
      }
    }
  }

  void _rebuildFurniture() {
    for (final f in _furniture) {
      f.removeFromParent();
    }
    _furniture.clear();
    for (var i = 0; i < _config.items.length; i++) {
      final c = _FurnitureComponent(_config.items[i], i);
      _furniture.add(c);
      world.add(c);
    }
  }

  void setConfig(RoomConfig config) {
    _config = config;
    selected = null;
    if (isLoaded) _rebuildFurniture();
  }

  void _commit(RoomConfig c, {bool rebuild = true}) {
    _config = c;
    if (rebuild) _rebuildFurniture();
    onChanged?.call(c);
  }

  void setWall(int i) => _commit(_config.copyWith(wall: i), rebuild: false);
  void setFloor(int i) => _commit(_config.copyWith(floor: i), rebuild: false);

  void addItem(String type, Vector2 at) {
    final f = Furniture.catalog[type]!;
    final x = (at.x / size.x).clamp(0.05, 0.95);
    final y =
        f.onWall
            ? (at.y / wallH).clamp(0.05, 0.95)
            : ((at.y - wallH) / (size.y - wallH)).clamp(0.0, 1.0);
    _commit(
      _config.copyWith(
        items: [..._config.items, RoomItem(type: type, x: x, y: y)],
      ),
    );
    placing = null; // una colocación por selección
    _select(_config.items.length - 1);
  }

  void moveItem(int index, Vector2 at) {
    final item = _config.items[index];
    final f = Furniture.catalog[item.type]!;
    final x = (at.x / size.x).clamp(0.03, 0.97);
    final y =
        f.onWall
            ? (at.y / wallH).clamp(0.05, 0.95)
            : ((at.y - wallH) / (size.y - wallH)).clamp(0.0, 1.0);
    final items = [..._config.items];
    items[index] = item.copyWith(x: x, y: y);
    _config = _config.copyWith(items: items);
    _furniture[index]
      ..item = items[index]
      ..layout();
    onChanged?.call(_config);
  }

  void removeSelected() {
    final i = selected;
    if (i == null) return;
    final items = [..._config.items]..removeAt(i);
    selected = null;
    onSelection?.call(null);
    _commit(_config.copyWith(items: items));
  }

  void _select(int? i) {
    selected = i;
    onSelection?.call(i);
  }

  void _tapAt(Vector2 p) {
    if (editable && placing != null) {
      addItem(placing!, p);
      return;
    }
    if (editable) _select(null);
    if (p.y >= wallH) {
      player.walkTo(_keepOnFloor(Vector2(p.x, p.y)), speed: cell * 14);
    }
  }

  /// Pies delante del mueble, en el piso, para no caminar encima del sprite.
  Vector2 _inFront(_FurnitureComponent f) {
    if (f.f.onWall) {
      return Vector2(f.position.x, wallH + cell * 4);
    }
    final y = (f.position.y + cell * 2.5).clamp(wallH + cell * 2, size.y - cell);
    return Vector2(f.position.x.clamp(cell * 4, size.x - cell * 4), y);
  }

  /// Punto del asiento: los pies quedan sobre el cojín, no en el borde del piso.
  Vector2 _onSeat(_FurnitureComponent f, {bool lie = false}) {
    final rows = f.f.h;
    final split = f.seatSplit;
    final rowH = f.size.y / rows;
    final fromBottom = lie ? rows * 0.42 : (rows - split).toDouble();
    final y = f.position.y - fromBottom * rowH;
    return Vector2(f.position.x, y.clamp(wallH + cell, size.y - cell * 2));
  }

  /// Si el toque cae dentro de un mueble, lo empuja al piso de delante.
  Vector2 _keepOnFloor(Vector2 p) {
    var x = p.x.clamp(cell * 3, size.x - cell * 3);
    var y = p.y.clamp(wallH + cell * 2, size.y - cell);
    for (final f in _furniture) {
      if (f.f.onWall) continue;
      final left = f.position.x - f.size.x / 2;
      final right = f.position.x + f.size.x / 2;
      final top = f.position.y - f.size.y;
      final bottom = f.position.y;
      if (x > left && x < right && y > top && y < bottom) {
        y = (bottom + cell * 1.5).clamp(wallH + cell * 2, size.y - cell);
      }
    }
    final c = cell;
    return Vector2((x / c).round() * c, (y / c).round() * c);
  }

  void _sitDown(PixelAvatarComponent who, _FurnitureComponent seat, {bool sleep = false}) {
    who.walkTo(_inFront(seat), speed: cell * (sleep ? 8 : 12), onArrive: () {
      who.walkTo(
        _onSeat(seat, lie: sleep),
        speed: cell * 8,
        arriveIdle: false,
        onArrive: () => who.setMood(sleep ? AvatarMood.sleep : AvatarMood.sit),
      );
    });
  }

  /// Camina hasta un mueble; si es silla, puff o cama, se sienta en el asiento.
  void interactFurniture(int index) {
    if (index < 0 || index >= _furniture.length) return;
    final fComp = _furniture[index];
    if (!editable && fComp.f.sittable && !fComp.f.onWall) {
      _sitDown(player, fComp, sleep: fComp.item.type == 'bed');
      return;
    }
    player.walkTo(_inFront(fComp), speed: cell * 14);
  }

  /// Añade un visitante que deambula y habla.
  void addVisitor(
    String name,
    AvatarConfig cfg, {
    List<String> phrases = const [],
  }) {
    // Evita duplicados.
    if (_visitors.any((v) => v.avatar.name == name)) return;
    final a = PixelAvatarComponent(
      config: cfg,
      cellSize: cell,
      name: name,
      position: Vector2(
        size.x * (0.15 + _rng.nextDouble() * 0.7),
        wallH + (size.y - wallH) * 0.7,
      ),
    );
    final v = _Visitor(a, phrases);
    _visitors.add(v);
    world.add(a);
    world.add(
      TimerComponent(
        period: 2.5 + _rng.nextDouble() * 3,
        repeat: true,
        onTick: () => _wander(v),
      ),
    );
  }

  void removeVisitor(String name) {
    _visitors.removeWhere((v) {
      if (v.avatar.name != name) return false;
      v.avatar.removeFromParent();
      return true;
    });
  }

  List<String> get visitorNames =>
      _visitors.map((v) => v.avatar.name).whereType<String>().toList();

  void refreshMyAvatar(AvatarConfig cfg) {
    player.config = cfg;
  }

  void _wander(_Visitor v) {
    if (v.avatar.mood == AvatarMood.walk) return;
    final hour = DateTime.now().hour;
    final night = hour < 7 || hour >= 22;
    if (night) {
      final beds = _furniture.where((f) => f.item.type == 'bed').toList();
      if (beds.isNotEmpty) {
        _sitDown(v.avatar, beds.first, sleep: true);
      } else {
        v.avatar.setMood(AvatarMood.sleep);
      }
      return;
    }
    if (v.avatar.mood == AvatarMood.idle && _rng.nextDouble() < 0.35) {
      v.avatar.setMood(_rng.nextBool() ? AvatarMood.phone : AvatarMood.pc);
      return;
    }
    final r = _rng.nextDouble();
    if (r < 0.4) {
      v.avatar.walkTo(
        Vector2(
          size.x * (0.08 + _rng.nextDouble() * 0.84),
          wallH + (size.y - wallH) * (0.3 + _rng.nextDouble() * 0.7),
        ),
        speed: cell * 10,
      );
    } else if (r < 0.55 && v.phrases.isNotEmpty) {
      v.avatar.say(v.phrases[_rng.nextInt(v.phrases.length)]);
    } else if (r < 0.65) {
      v.avatar.setMood(AvatarMood.wave);
    } else if (r < 0.78) {
      final seats =
          _furniture.where((f) => f.f.sittable && !f.f.onWall).toList();
      if (seats.isNotEmpty) {
        final seat = seats[_rng.nextInt(seats.length)];
        _sitDown(v.avatar, seat, sleep: seat.item.type == 'bed');
      }
    } else if (r < 0.88) {
      v.avatar.setMood(AvatarMood.dance);
    }
  }

  void sayMe(String text) => player.say(text, seconds: 4);

  void emote(AvatarMood m) => player.setMood(m);

  /// Sincroniza posición de un visitante (presencia demo / “red”).
  void syncVisitorPosition(String name, double nx, double ny) {
    for (final v in _visitors) {
      if (v.avatar.name != name) continue;
      final target = Vector2(
        nx.clamp(0.05, 0.95) * size.x,
        wallH + ny.clamp(0.15, 0.95) * (size.y - wallH),
      );
      if (v.avatar.position.distanceTo(target) > cell * 2) {
        v.avatar.walkTo(target, speed: cell * 11);
      }
      return;
    }
  }

  void visitorSay(String name, String text) {
    for (final v in _visitors) {
      if (v.avatar.name == name) {
        v.avatar.say(text, seconds: 3);
        return;
      }
    }
  }
}

class _Visitor {
  _Visitor(this.avatar, this.phrases);
  final PixelAvatarComponent avatar;
  final List<String> phrases;
}

/// Pared y piso.
class _Backdrop extends PositionComponent with HasGameReference<RoomGame> {
  _Backdrop() : super(priority: -1000);

  @override
  void render(Canvas canvas) {
    final g = game;
    final s = g.size;
    final c = g.cell;
    final wall = RoomPalettes.walls[g.config.wall % RoomPalettes.walls.length];
    final floor =
        RoomPalettes.floors[g.config.floor % RoomPalettes.floors.length];
    final p = Paint();

    // Pared con patrón de puntos.
    p.color = wall.base;
    canvas.drawRect(Rect.fromLTWH(0, 0, s.x, g.wallH), p);
    p.color = wall.detail;
    for (var y = c * 2; y < g.wallH - c; y += c * 4) {
      for (var x = c * 2; x < s.x; x += c * 4) {
        canvas.drawRect(Rect.fromLTWH(x, y, c, c), p);
      }
    }
    // Zócalo.
    p.color = const Color(0xFF14121A);
    canvas.drawRect(Rect.fromLTWH(0, g.wallH - c, s.x, c), p);
    // Piso con baldosas en falsa perspectiva (filas más altas hacia el frente).
    var y = g.wallH;
    var row = 0;
    while (y < s.y) {
      final rowH = c * (1.5 + row * 0.5);
      final tileW = c * (4 + row);
      var x = -(row.isEven ? 0.0 : tileW / 2);
      var k = 0;
      while (x < s.x) {
        p.color = k.isEven ? floor.base : floor.detail;
        canvas.drawRect(Rect.fromLTWH(x, y, tileW, rowH + 0.5), p);
        x += tileW;
        k++;
      }
      // Línea entre filas.
      p.color = const Color(0x33000000);
      canvas.drawRect(Rect.fromLTWH(0, y, s.x, 1), p);
      y += rowH;
      row++;
    }
    // Marco RGB del cuarto.
    if (g.config.rgbFrame) {
      final n = ((s.x + s.y) * 2 / (c * 2)).floor();
      final perim = (s.x + s.y) * 2;
      final seg = perim / n;
      for (var i = 0; i < n; i++) {
        p.color = Px.spectrumStep(i / n - g.t / 4);
        final d = i * seg;
        canvas.drawRect(_edge(d, seg, s, c * 0.6), p);
      }
    }
  }

  Rect _edge(double d, double len, Vector2 s, double th) {
    if (d < s.x) return Rect.fromLTWH(d, 0, len + 0.5, th);
    d -= s.x;
    if (d < s.y) return Rect.fromLTWH(s.x - th, d, th, len + 0.5);
    d -= s.y;
    if (d < s.x) return Rect.fromLTWH(s.x - d - len, s.y - th, len + 0.5, th);
    d -= s.x;
    return Rect.fromLTWH(0, s.y - d - len, th, len + 0.5);
  }
}

/// Capa invisible que recibe los toques del fondo (piso/pared).
class _TapLayer extends PositionComponent
    with HasGameReference<RoomGame>, TapCallbacks {
  _TapLayer() : super(priority: -999);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void onTapDown(TapDownEvent event) => game._tapAt(event.localPosition);
}

/// Un mueble colocado.
class _FurnitureComponent extends PositionComponent
    with HasGameReference<RoomGame>, TapCallbacks, DragCallbacks {
  _FurnitureComponent(this.item, this.index);

  RoomItem item;
  final int index;
  Furniture get f => Furniture.catalog[item.type]!;

  _SeatFront? _front;

  /// Fila donde empieza el borde delantero (asiento). El respaldo queda detrás.
  int get seatSplit {
    switch (item.type) {
      case 'chair':
        return 6;
      case 'bed':
        return 6;
      case 'beanbag':
        return 2;
      default:
        final mid = (f.h * 0.6).round();
        if (mid < 1) return 1;
        if (mid >= f.h) return f.h - 1;
        return mid;
    }
  }

  @override
  Future<void> onLoad() async {
    anchor = f.onWall ? Anchor.center : Anchor.bottomCenter;
    if (f.sittable && !f.onWall) {
      _front = _SeatFront(this);
      game.world.add(_front!);
    }
    layout();
  }

  @override
  void onRemove() {
    _front?.removeFromParent();
    _front = null;
    super.onRemove();
  }

  void layout() {
    final g = game;
    final c = g.cell;
    final depth = f.onWall ? 0.0 : item.y;
    final sc = f.onWall ? 1.0 : 0.8 + 0.4 * depth;
    size = Vector2(f.w * c * sc, f.h * c * sc);
    if (f.onWall) {
      position = Vector2(item.x * g.size.x, item.y * g.wallH);
      priority = -500;
    } else if (f.sittable) {
      final y = g.wallH + depth * (g.size.y - g.wallH);
      position = Vector2(item.x * g.size.x, y);
      final rowH = size.y / f.h;
      final seatY = y - (f.h - seatSplit) * rowH;
      priority = (seatY - 12).toInt();
      _front?.follow(seatY);
    } else {
      final y = g.wallH + depth * (g.size.y - g.wallH);
      position = Vector2(item.x * g.size.x, y);
      priority = y.toInt();
    }
  }

  @override
  void render(Canvas canvas) {
    final g = game;
    final c = size.x / f.w;
    Color? glow;
    if (f.glow != null) glow = Px.spectrum(g.t / 4 + item.x);
    // Sombra en el piso.
    if (!f.onWall) {
      canvas.drawRect(
        Rect.fromLTWH(c, size.y - c * 0.5, size.x - 2 * c, c),
        Paint()..color = const Color(0x55000000),
      );
    }
    Furniture.paint(
      canvas,
      f,
      c,
      glowColor: glow,
      toRow: f.sittable && !f.onWall ? seatSplit : null,
    );
    // Halo si brilla.
    if (glow != null) {
      canvas.drawRect(
        Rect.fromLTWH(-c, -c, size.x + 2 * c, size.y + 2 * c),
        Paint()..color = glow.withValues(alpha: 0.10),
      );
    }
    if (g.editable && g.selected == index) {
      final p =
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Px.spectrum(g.t);
      canvas.drawRect(Rect.fromLTWH(-2, -2, size.x + 4, size.y + 4), p);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    final g = game;
    if (!g.editable) {
      // Fuera de edición: caminar / sentarse en el mueble.
      g.interactFurniture(index);
      return;
    }
    if (g.placing != null) {
      g.addItem(g.placing!, absolutePosition);
      return;
    }
    g._select(index);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (game.editable) game._select(index);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!game.editable) return;
    game.moveItem(index, position + event.localDelta);
  }
}

/// Borde delantero del mueble (asiento). Se dibuja encima de quien está sentado.
class _SeatFront extends PositionComponent with HasGameReference<RoomGame> {
  _SeatFront(this.host);

  final _FurnitureComponent host;

  void follow(double seatY) {
    anchor = host.anchor;
    size = host.size;
    position = host.position.clone();
    priority = seatY.toInt() + 8;
  }

  @override
  void render(Canvas canvas) {
    final f = host.f;
    final c = size.x / f.w;
    Color? glow;
    if (f.glow != null) glow = Px.spectrum(game.t / 4 + host.item.x);
    Furniture.paint(canvas, f, c, glowColor: glow, fromRow: host.seatSplit);
  }
}
