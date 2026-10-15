import 'dart:async';
import 'dart:math';
import 'dart:ui' hide TextStyle;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame/parallax.dart';
import 'package:flame/particles.dart';
import 'package:flame/text.dart';
import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/painting.dart'
    show TextStyle, Shadow, TextPainter, TextSpan, TextDirection;

import '../core/pixel_theme.dart';
import '../widgets/pixel_avatar.dart';
import 'avatar_component.dart';

/// Escena Ãºnica de marca + login: intro GRIDLY â†’ ciudad â†’ avatar â†’ form listo.
/// Una sola pantalla Flame (sin saltar splashâ†’login).
class LoginBackgroundGame extends FlameGame {
  LoginBackgroundGame({
    required this.avatarConfig,
    this.playBrandIntro = false,
    this.onIntroReady,
  });

  final AvatarConfig avatarConfig;

  /// Intro de marca fluida al abrir la app (mismo juego que el login).
  final bool playBrandIntro;
  final void Function()? onIntroReady;

  ParallaxComponent? _parallax;
  late final PixelAvatarComponent avatar;
  _Sky? _sky;
  late final _RgbTitle _title;
  _BrandMark? _brand;
  _IntroVeil? _veil;
  final Random _rng = Random();
  bool _cityReady = false;
  Future<void>? _cityLoad;

  double _speed = 1;
  double _targetSpeed = 1;
  bool _introDone = false;
  bool _avatarLocked = false;

  double get scale => size.y / 180;
  double get cell => scale * 1.0;

  /// Pies en el bordillo del arte (road empieza en y150 del PNG 180).
  Vector2 get _avatarHome => Vector2(size.x * 0.32, size.y - 28 * scale);

  /// Autos un poco más abajo en la calzada.
  double get _roadY => size.y - 12 * scale;

  @override
  Color backgroundColor() =>
      playBrandIntro && !_introDone ? const Color(0xFF000000) : Px.bg;

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    _title = _RgbTitle('')..priority = 70;

    // Avatar siempre (fuera de pantalla en intro).
    final startLeft = playBrandIntro;
    // Personaje bit Flame (más chico que los autos).
    avatar = PixelAvatarComponent(
      config: avatarConfig,
      cellSize: cell * 0.78,
      position:
          startLeft ? Vector2(-56 * scale, _avatarHome.y) : _avatarHome,
    );
    avatar.facing = 1;

    if (playBrandIntro) {
      _introDone = false;
      _avatarLocked = true;
      _speed = 0;
      _targetSpeed = 0;
      avatar.setMood(AvatarMood.idle);

      // 1) NEGRO primero (antes de cualquier edificio).
      _veil = _IntroVeil(opacity: 1)..priority = 90;
      world.add(_veil!);

      // 2) Marca encima del negro (RGB).
      _brand = _BrandMark(
        onCityCue: onBrandSettleStart,
        onSettled: _finishIntro,
        logoYFactor: 0.14,
        logoFont: 34,
      )..priority = 100;
      world.add(_brand!);

      world.add(avatar);
      world.add(_RainRgb(active: false));

      // Ciudad se carga en segundo plano, pero NO se muestra hasta el cue.
      _cityLoad = _loadCityWorld();
    } else {
      await _loadCityWorld();
      world.add(avatar);
      world.add(_RainRgb(active: true));
      _introDone = true;
      avatar.setMood(AvatarMood.walk);
      _targetSpeed = 1;
      WidgetsBindingSafe.call(onIntroReady);
    }
  }

  Future<void> _loadCityWorld() async {
    if (_cityReady) return;
    _sky = _Sky();
    world.add(_sky!);

    _parallax = await loadParallaxComponent(
      [
        ParallaxImageData('parallax/city_far.png'),
        ParallaxImageData('parallax/city_near.png'),
        ParallaxImageData('parallax/street.png'),
        ParallaxImageData('parallax/road.png'),
      ],
      baseVelocity: Vector2(14, 0),
      velocityMultiplierDelta: Vector2(1.9, 1),
      fill: LayerFill.height,
      filterQuality: FilterQuality.none,
      priority: -50,
    );
    world.add(_parallax!);
    if (playBrandIntro && !_introDone) {
      _parallax!.parallax?.baseVelocity.setValues(0, 0);
    }
    if (!world.children.any((c) => c is _TrafficLane)) {
      world.add(_TrafficLane());
    }
    _cityReady = true;
  }

  void _finishIntro() {
    if (_introDone) return;
    _introDone = true;
    _avatarLocked = false;
    onIntroReady?.call();
  }

  /// Salta la intro (tap). Mantiene continuidad: marca ya en logo.
  void skipIntro() {
    if (_introDone || !playBrandIntro) {
      _finishIntro();
      return;
    }
    _brand?.skipToLogo();
    unawaited(_bringCityAndAvatar(fast: true).then((_) {
      if (isMounted) _finishIntro();
    }));
  }

  Future<void> _bringCityAndAvatar({bool fast = false}) async {
    // Espera a que la ciudad esté lista detrás del negro.
    await (_cityLoad ?? _loadCityWorld());
    if (!isMounted) return;
    // Negro → ciudad, solo ahora.
    _veil?.revealCity(fast: fast);
    for (final c in world.children) {
      if (c is _RainRgb) c.active = true;
    }
    _targetSpeed = fast ? 1.05 : 0.85;
    _speed = max(_speed, fast ? 0.5 : 0.2);
    avatar.setMood(AvatarMood.walk);
    final spd = (fast ? 120 : 72) * scale;
    avatar.walkTo(
      _avatarHome,
      speed: spd,
      arriveIdle: false,
      onArrive: () {
        if (!isMounted) return;
        avatar.setMood(AvatarMood.walk);
        _targetSpeed = 1.05;
      },
    );
  }

  /// Llamado por la marca cuando GRIDLY va hacia el logo (ahí nace la ciudad).
  void onBrandSettleStart() {
    if (!playBrandIntro || _introDone) return;
    unawaited(_bringCityAndAvatar());
  }

  void _ensureTitle() {
    if (_title.parent == null) world.add(_title);
    // Quitar GRIDLY del todo (si no, reaparece encima del HOLA / al ir al feed).
    _brand?.removeFromParent();
    _brand = null;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      avatar.cell = cell * 0.78;
      if (_introDone && !_avatarLocked) {
        // Solo anclar si no estÃ¡ en medio de un walkTo.
        if (avatar.mood != AvatarMood.walk ||
            avatar.position.x > _avatarHome.x - 4) {
          avatar.position = _avatarHome;
        }
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _speed += (_targetSpeed - _speed) * min(1, dt * 3);
    _parallax?.parallax?.baseVelocity.setValues(14 * _speed * scale / 2, 0);
    avatar.walkRate = _speed;
    // Mantener pies pegados al suelo del arte.
    if (_introDone && !_avatarLocked && !avatar.isHopping) {
      avatar.position.y = _avatarHome.y;
    }
    if (_introDone) {
      if (_speed < 0.08) {
        if (avatar.mood == AvatarMood.walk) avatar.setMood(AvatarMood.idle);
      } else if (avatar.mood == AvatarMood.idle) {
        avatar.setMood(AvatarMood.walk);
      }
    }
  }

  void shakeError() {
    _targetSpeed = 0;
    avatar.setMood(AvatarMood.sad);
    camera.viewfinder.add(
      MoveByEffect(
        Vector2(6 * scale / 2, 0),
        RepeatedEffectController(ZigzagEffectController(period: 0.08), 4),
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!isMounted) return;
      avatar.setMood(AvatarMood.idle);
      _targetSpeed = 1;
    });
  }

  Future<void> celebrateLogin(String name) async {
    _targetSpeed = 1.6;
    avatar.setMood(AvatarMood.walk);
    avatar.setSmile(true);
    _ensureTitle();
    await _title.loaded;
    _title.show('HOLA, ${name.toUpperCase()}!', burst: true);
    _confetti();
    avatar.hop();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!isMounted) return;
    avatar.setMood(AvatarMood.walk);
    avatar.hop();
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  void walkWithName() {
    _targetSpeed = 2.2;
    avatar.setMood(AvatarMood.walk);
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (!isMounted) return;
      _targetSpeed = 1;
    });
  }

  Future<void> celebrateGoodbye(String name) async {
    _targetSpeed = 1.5;
    avatar.setMood(AvatarMood.walk);
    _ensureTitle();
    await _title.loaded;
    _title.show('CHAU, ${name.toUpperCase()}!', burst: true);
    _confetti();
    avatar.hop();
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!isMounted) return;
    avatar.setMood(AvatarMood.walk);
  }

  void _confetti() {
    world.add(
      ParticleSystemComponent(
        position: Vector2(size.x / 2, -10),
        priority: 60,
        particle: Particle.generate(
          count: 18,
          lifespan: 1.4,
          generator:
              (i) => AcceleratedParticle(
                position: Vector2((_rng.nextDouble() - 0.5) * size.x, 0),
                speed: Vector2(
                  (_rng.nextDouble() - 0.5) * 60 * scale / 2,
                  40 * scale / 2,
                ),
                acceleration: Vector2(0, 60 * scale / 2),
                child: _Confetti(
                  size: cell * 1.5,
                  color: Px.rgb[i % Px.rgb.length],
                ),
              ),
        ),
      ),
    );
  }
}

/// Helper para callbacks diferidos sin acoplar a Flutter widgets.
class WidgetsBindingSafe {
  static void call(void Function()? cb) {
    if (cb == null) return;
    scheduleMicrotask(cb);
  }
}

class _Confetti extends Particle {
  _Confetti({required this.size, required this.color});
  final double size;
  final Color color;
  final Paint _p = Paint();

  @override
  void render(Canvas canvas) {
    _p.color = color.withValues(alpha: (1 - progress).clamp(0, 1));
    final w = size * (0.4 + 0.6 * (sin(progress * 12)).abs());
    canvas.drawRect(Rect.fromLTWH(-w / 2, -size / 2, w, size), _p);
  }
}

/// Cielo: degradado oscuro con estrellas y un resplandor RGB en el horizonte.
class _Sky extends PositionComponent
    with HasGameReference<LoginBackgroundGame> {
  _Sky() : super(priority: -100);
  final List<Vector2> _stars = List.generate(70, (i) {
    final r = Random(i * 7 + 1);
    return Vector2(r.nextDouble(), r.nextDouble() * 0.6);
  });
  double _t = 0;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final s = game.size;
    final sc = game.scale;
    final p =
        Paint()
          ..shader = Gradient.linear(
            Offset.zero,
            Offset(0, s.y),
            const [Color(0xFF07070F), Color(0xFF12122A), Color(0xFF1F1A40)],
            const [0, 0.55, 1],
          );
    canvas.drawRect(Rect.fromLTWH(0, 0, s.x, s.y), p);
    // Resplandor RGB en el horizonte (bandas).
    for (var i = 0; i < 5; i++) {
      final c = Px.spectrum(_t / 6 + i * 0.07);
      canvas.drawRect(
        Rect.fromLTWH(0, s.y - (90 + i * 6) * sc, s.x, 6 * sc),
        Paint()..color = c.withValues(alpha: 0.05 + 0.02 * (4 - i)),
      );
    }
    final star = Paint();
    for (var i = 0; i < _stars.length; i++) {
      final st = _stars[i];
      final tw = 0.5 + 0.5 * sin(_t * (1 + i % 5) + i);
      star.color = Px.text.withValues(alpha: 0.25 + 0.6 * tw);
      final sz = sc * (i % 7 == 0 ? 2 : 1);
      canvas.drawRect(Rect.fromLTWH(st.x * s.x, st.y * s.y, sz, sz), star);
    }
    // Luna pixel.
    final mx = s.x * 0.78, my = s.y * 0.14, r = 10 * sc;
    for (var dx = -r; dx <= r; dx += sc) {
      for (var dy = -r; dy <= r; dy += sc) {
        if (dx * dx + dy * dy <= r * r) {
          canvas.drawRect(
            Rect.fromLTWH(mx + dx, my + dy, sc, sc),
            Paint()..color = const Color(0xFFE8E8FF),
          );
        }
      }
    }
    canvas.drawRect(
      Rect.fromLTWH(mx - 3 * sc, my - sc, 2 * sc, 2 * sc),
      Paint()..color = const Color(0xFFB8B8D8),
    );
    canvas.drawRect(
      Rect.fromLTWH(mx + 3 * sc, my + 3 * sc, sc, sc),
      Paint()..color = const Color(0xFFB8B8D8),
    );
  }
}

/// PartÃ­culas RGB flotando (pocas, baratas).
class _RainRgb extends Component with HasGameReference<LoginBackgroundGame> {
  _RainRgb({this.active = true});

  bool active;
  final Random _rng = Random();
  double _acc = 0;

  @override
  void update(double dt) {
    if (!active) return;
    _acc += dt;
    if (_acc < 0.45) return;
    _acc = 0;
    final g = game;
    final c = Px.rgb[_rng.nextInt(Px.rgb.length)];
    g.world.add(
      ParticleSystemComponent(
        priority: -40,
        position: Vector2(
          _rng.nextDouble() * g.size.x,
          g.size.y * (0.2 + _rng.nextDouble() * 0.55),
        ),
        particle: MovingParticle(
          to: Vector2(-30 * g.scale / 2, -10 * g.scale / 2),
          lifespan: 2.6,
          child: ComputedParticle(
            renderer: (canvas, p) {
              final a = sin(p.progress * pi);
              canvas.drawRect(
                Rect.fromLTWH(0, 0, g.scale, g.scale),
                Paint()..color = c.withValues(alpha: (a * 0.75).clamp(0, 1)),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Titulo HOLA/CHAU: se achica y parte en 2 lineas para caber en pantalla.
class _RgbTitle extends PositionComponent
    with HasGameReference<LoginBackgroundGame> {
  _RgbTitle(this._full) : super(anchor: Anchor.topCenter, priority: 70);

  String _full;
  int _shown = 0;
  double _acc = 0;
  double _t = 0;
  double _yFactor = 0.18;
  final List<_LetterSprite> _letters = [];

  @override
  Future<void> onLoad() async {
    position = Vector2(game.size.x / 2, game.size.y * _yFactor);
    _rebuildLetters();
  }

  void show(String text, {bool burst = false}) {
    _full = text.trim();
    _shown = 0;
    _acc = 0;
    final hi = text.contains('HOLA') || text.contains('CHAU');
    _yFactor = hi ? 0.28 : 0.18;
    position = Vector2(game.size.x / 2, game.size.y * _yFactor);
    _rebuildLetters();
    if (burst) {
      _shown = _letters.length;
      for (final l in _letters) {
        l.revealed = true;
      }
    }
  }

  /// Una sola línea: "HOLA, NOMBRE!"
  List<String> _linesFor(String text) {
    final hi = RegExp(
      r'^(¡?\s*(HOLA|CHAU)\s*,?\s*)(.+)$',
      caseSensitive: false,
    ).firstMatch(text);
    if (hi != null) {
      final verb = (hi.group(2) ?? 'HOLA').toUpperCase();
      var name = (hi.group(3) ?? '').trim();
      if (name.endsWith('!')) {
        name = name.substring(0, name.length - 1).trim();
      }
      return ['$verb, $name!'];
    }
    return [text];
  }

  double _measure(String line, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(
        text: line,
        style: TextStyle(
          fontFamily: Px.font,
          fontSize: fontSize,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return tp.width;
  }

  void _rebuildLetters() {
    for (final l in List<_LetterSprite>.from(_letters)) {
      l.removeFromParent();
    }
    _letters.clear();
    if (_full.isEmpty) return;

    final maxW = max(64.0, game.size.x * 0.9);
    final lines = _linesFor(_full);
    final line = lines.first;

    var fontSize = min(22.0, game.scale * 7.2);
    fontSize = max(10.0, fontSize);
    while (fontSize > 8.0 && _measure(line, fontSize) > maxW) {
      fontSize -= 0.5;
    }

    // Espaciado compacto (no letra a letra con huecos raros).
    final spacing = fontSize * 0.78;
    final totalW = max(0, line.length - 1) * spacing;

    for (var i = 0; i < line.length; i++) {
      final letter = _LetterSprite(
        char: line[i],
        index: i,
        fontSize: fontSize,
      )..position = Vector2(-totalW / 2 + i * spacing, 0);
      _letters.add(letter);
      add(letter);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2(size.x / 2, size.y * _yFactor);
    if (isLoaded) _rebuildLetters();
  }

  @override
  void update(double dt) {
    _t += dt;
    _acc += dt;
    if (_shown < _letters.length && _acc > 0.06) {
      _acc = 0;
      _shown++;
    }
    final hue = (_t / 10) % 1;
    for (var i = 0; i < _letters.length; i++) {
      final letter = _letters[i];
      letter.revealed = i < _shown;
      if (!letter.revealed) continue;
      letter.scale.setValues(1, 1);
      letter.hue = hue;
    }
  }
}

class _LetterSprite extends TextComponent {
  _LetterSprite({
    required String char,
    required this.index,
    required this.fontSize,
  }) : super(
          text: char,
          anchor: Anchor.center,
          textRenderer: TextPaint(
            style: TextStyle(
              fontFamily: Px.font,
              fontSize: fontSize,
              color: Px.text,
              shadows: [
                Shadow(
                  offset: Offset(fontSize / 5, fontSize / 5),
                  color: const Color(0xFF000000),
                ),
              ],
            ),
          ),
        );

  final int index;
  final double fontSize;
  double hue = 0;
  bool revealed = false;

  @override
  void render(Canvas canvas) {
    if (!revealed) return;
    final c = Px.spectrum(hue);
    textRenderer = TextPaint(
      style: TextStyle(
        fontFamily: Px.font,
        fontSize: fontSize,
        color: c,
        shadows: [
          Shadow(
            offset: Offset(fontSize / 5, fontSize / 5),
            color: const Color(0xFF000000),
          ),
        ],
      ),
    );
    super.render(canvas);
  }
}

/// Velo negro puro del splash de marca.
class _IntroVeil extends PositionComponent
    with HasGameReference<LoginBackgroundGame>, HasPaint {
  _IntroVeil({double opacity = 1})
      : super(priority: 90, anchor: Anchor.topLeft) {
    paint.color = const Color(0xFF000000).withValues(alpha: opacity);
  }

  void revealCity({bool fast = false}) {
    removeWhere((c) => c is Effect);
    add(
      OpacityEffect.to(
        0,
        EffectController(
          duration: fast ? 0.45 : 1.2,
          curve: Curves.easeInOutCubic,
        ),
        onComplete: removeFromParent,
      ),
    );
  }

  @override
  void onMount() {
    super.onMount();
    size = game.size.clone();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size.clone();
  }

  @override
  void render(Canvas canvas) {
    // Cubre toda la pantalla aunque size aún no esté listo.
    final s = size.x > 0 && size.y > 0 ? size : game.size;
    canvas.drawRect(Offset.zero & Size(s.x, s.y), paint);
  }
}

/// Splash:
/// 1) Negro puro
/// 2) GRIDLY RGB en el centro (celular / tablet)
/// 3) Hold
/// 4) Sube al logo (arriba) + se revela la ciudad; el form queda arriba
class _BrandMark extends PositionComponent
    with HasGameReference<LoginBackgroundGame> {
  _BrandMark({
    required this.onCityCue,
    required this.onSettled,
    required this.logoYFactor,
    required this.logoFont,
  }) : super(anchor: Anchor.center, priority: 100);

  final void Function() onCityCue;
  final void Function() onSettled;
  final double logoYFactor;
  final double logoFont;

  static const _word = 'GRIDLY';
  static const _blackHold = 0.9;
  static const _letterGap = 0.15;
  static const _holdAfter = 0.85;

  final List<_BrandLetter> _letters = [];
  double _t = 0;
  int _phase = -1; // -1 black · 0 type · 1 hold · 2 fly · 3 done
  int _shown = 0;
  bool _flyStarted = false;
  bool _visible = true;
  late double _heroFont;

  /// Centro exacto (splash).
  Vector2 get _center => Vector2(game.size.x / 2, game.size.y / 2);

  /// Logo arriba, siempre centrado en X (phone / tablet).
  Vector2 get _logoPos => Vector2(game.size.x / 2, game.size.y * logoYFactor);

  double get _logoSize {
    final short = min(game.size.x, game.size.y);
    return (short * 0.075).clamp(logoFont.toDouble(), 44.0);
  }

  @override
  Future<void> onLoad() async {
    position = _center;
    _heroFont = (min(game.size.x, game.size.y) * 0.12).clamp(34.0, 64.0);
    _buildHero();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_phase >= 3) {
      position = _logoPos;
      _rebuildAsLogo();
    } else if (_phase != 2) {
      position = _center;
      if (_phase >= 0 && isLoaded) {
        _heroFont = (min(size.x, size.y) * 0.12).clamp(34.0, 64.0);
        final shown = _shown;
        _buildHero();
        for (var i = 0; i < shown && i < _letters.length; i++) {
          _letters[i].revealed = true;
        }
        _shown = shown;
      }
    }
  }

  void setVisible(bool v) {
    _visible = v;
    for (final l in _letters) {
      l.revealed = v && l.revealed;
    }
  }

  void skipToLogo() {
    removeWhere((c) => c is Effect);
    for (final l in _letters) {
      l.removeWhere((c) => c is Effect);
    }
    position = _logoPos;
    scale.setValues(1, 1);
    _rebuildAsLogo();
    _phase = 3;
    _flyStarted = true;
  }

  void _buildHero() {
    for (final l in List<_BrandLetter>.from(_letters)) {
      l.removeFromParent();
    }
    _letters.clear();
    final spacing = _heroFont * 1.12;
    final totalW = (_word.length - 1) * spacing;
    for (var i = 0; i < _word.length; i++) {
      final letter = _BrandLetter(
        char: _word[i],
        index: i,
        fontSize: _heroFont,
      )
        ..position = Vector2(-totalW / 2 + i * spacing, 0)
        ..scale.setValues(1, 1)
        ..revealed = false;
      _letters.add(letter);
      add(letter);
    }
  }

  void _rebuildAsLogo() {
    if (!_visible) return;
    for (final l in List<_BrandLetter>.from(_letters)) {
      l.removeFromParent();
    }
    _letters.clear();
    final font = _logoSize;
    final spacing = font * 1.1;
    final totalW = (_word.length - 1) * spacing;
    for (var i = 0; i < _word.length; i++) {
      final letter = _BrandLetter(
        char: _word[i],
        index: i,
        fontSize: font,
      )
        ..position = Vector2(-totalW / 2 + i * spacing, 0)
        ..scale.setValues(1, 1)
        ..revealed = true;
      _letters.add(letter);
      add(letter);
    }
  }

  void _revealHeroNext() {
    if (_shown >= _letters.length) return;
    _letters[_shown].revealed = true;
    _shown++;
  }

  void _flyBackToLogo() {
    if (_flyStarted) return;
    _flyStarted = true;
    _phase = 2;
    onCityCue();

    final endScale = (_logoSize / _heroFont).clamp(0.52, 0.78);

    add(
      MoveToEffect(
        _logoPos,
        EffectController(duration: 1.0, curve: Curves.easeInOutCubic),
      ),
    );
    add(
      ScaleEffect.to(
        Vector2.all(endScale),
        EffectController(duration: 1.0, curve: Curves.easeInOutCubic),
        onComplete: () {
          if (!isMounted) return;
          scale.setValues(1, 1);
          position = _logoPos;
          _rebuildAsLogo();
          _phase = 3;
          onSettled();
        },
      ),
    );
  }

  @override
  void update(double dt) {
    if (!_visible) return;
    _t += dt;

    if (_phase == -1) {
      if (_t >= _blackHold) {
        _phase = 0;
        _t = 0;
      }
      return;
    }

    if (_phase == 0) {
      // Mantener centrado mientras escribe.
      position = _center;
      final nextAt = _shown * _letterGap;
      if (_shown < _word.length && _t >= nextAt) _revealHeroNext();
      if (_shown >= _word.length) {
        _phase = 1;
        _t = 0;
      }
    }

    if (_phase == 1) {
      position = _center;
      if (_t >= _holdAfter) _flyBackToLogo();
    }

    if (_phase == 3) {
      position = _logoPos;
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_visible) return;
    super.render(canvas);
  }
}

class _BrandLetter extends TextComponent {
  _BrandLetter({
    required String char,
    required this.index,
    required this.fontSize,
  }) : super(
          text: char,
          anchor: Anchor.center,
          textRenderer: TextPaint(
            style: TextStyle(
              fontFamily: Px.font,
              fontSize: fontSize,
              color: Px.text,
            ),
          ),
        );

  final int index;
  final double fontSize;
  bool revealed = false;

  @override
  void render(Canvas canvas) {
    if (!revealed) return;
    final c = RgbClock.I.gridlyLetter(index);
    textRenderer = TextPaint(
      style: TextStyle(
        fontFamily: Px.font,
        fontSize: fontSize,
        color: c,
        shadows: [
          Shadow(
            offset: Offset(fontSize / 7, fontSize / 7),
            color: const Color(0xFF000000),
          ),
        ],
      ),
    );
    super.render(canvas);
  }
}

/// Autos en la calzada: más grandes que el personaje bit.
class _TrafficLane extends Component
    with HasGameReference<LoginBackgroundGame> {
  _TrafficLane() : super(priority: 5);

  final Random _rng = Random();
  double _acc = 0.8;

  @override
  void update(double dt) {
    if (!game._cityReady) return;
    if (game.playBrandIntro && game._veil != null && game._veil!.isMounted) {
      if (game._speed < 0.15) return;
    }
    _acc += dt;
    final gap = (2.0 / max(0.45, game._speed)).clamp(1.2, 2.6);
    if (_acc < gap) return;
    _acc = 0;
    final fromLeft = _rng.nextBool();
    final colors = [
      const Color(0xFFE85D4C),
      const Color(0xFF4D8BFF),
      const Color(0xFFF0C14A),
      const Color(0xFF3BFF9E),
      const Color(0xFFC77DFF),
      const Color(0xFFFF8A3D),
    ];
    game.world.add(
      _PixelCar(
        color: colors[_rng.nextInt(colors.length)],
        fromLeft: fromLeft,
        speed:
            (42 + _rng.nextDouble() * 30) * game.scale * max(0.55, game._speed),
      ),
    );
  }
}

class _PixelCar extends PositionComponent
    with HasGameReference<LoginBackgroundGame> {
  _PixelCar({
    required this.color,
    required this.fromLeft,
    required this.speed,
  }) : super(anchor: Anchor.bottomCenter, priority: 6);

  final Color color;
  final bool fromLeft;
  final double speed;
  late final double _u;

  @override
  Future<void> onLoad() async {
    // Más grandes que el avatar (~12.5*scale de alto).
    _u = max(2.2, game.scale * 1.55);
    size = Vector2(_u * 16, _u * 9);
    position = Vector2(
      fromLeft ? -size.x : game.size.x + size.x,
      game._roadY,
    );
  }

  @override
  void update(double dt) {
    final dir = fromLeft ? 1.0 : -1.0;
    position.x += dir * speed * dt;
    position.x += dir * 12 * game._speed * game.scale * dt;
    position.y = game._roadY;
    if (position.x < -size.x * 2 || position.x > game.size.x + size.x * 2) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final u = _u;
    final body = Paint()..color = color;
    final dark =
        Paint()..color = Color.lerp(color, const Color(0xFF000000), 0.35)!;
    final glass = Paint()..color = const Color(0xFF9AD8F5);
    final wheel = Paint()..color = const Color(0xFF141418);
    final light = Paint()
      ..color = fromLeft ? const Color(0xFFFFE08A) : const Color(0xFFFF6B6B);

    canvas.drawRect(Rect.fromLTWH(u, u * 3.0, u * 14, u * 3.6), body);
    canvas.drawRect(Rect.fromLTWH(u * 4, u * 1.0, u * 7.5, u * 2.6), dark);
    canvas.drawRect(Rect.fromLTWH(u * 4.5, u * 1.3, u * 2.8, u * 1.8), glass);
    canvas.drawRect(Rect.fromLTWH(u * 8.2, u * 1.3, u * 2.8, u * 1.8), glass);
    canvas.drawRect(Rect.fromLTWH(u * 2.5, u * 6.0, u * 2.8, u * 2.0), wheel);
    canvas.drawRect(Rect.fromLTWH(u * 11, u * 6.0, u * 2.8, u * 2.0), wheel);
    final lx = fromLeft ? u * 14.2 : u * 0.3;
    canvas.drawRect(Rect.fromLTWH(lx, u * 3.8, u * 1.5, u * 1.3), light);
  }
}
