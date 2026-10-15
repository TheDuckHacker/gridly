import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/particles.dart';
import 'package:flame/text.dart';
import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/painting.dart';

import '../core/pixel_theme.dart';
import '../widgets/pixel_avatar.dart';

enum AvatarMood { idle, walk, wave, dance, jump, sad, happy, sit, sleep, phone, pc }

/// Avatar pixel-art como componente de Flame.
///
/// Dibuja la rejilla 16x16 compartida con [AvatarRenderer] y le da vida con
/// el motor: respiración en reposo, ciclo de caminata (frames de piernas),
/// saludo, baile, salto con polvo, burbujas de diálogo y desplazamiento a un
/// punto con [walkTo].
class PixelAvatarComponent extends PositionComponent with TapCallbacks {
  PixelAvatarComponent({
    required this.config,
    required double cellSize,
    super.position,
    super.priority = 10,
    this.onTap,
    this.name,
  }) : _cell = cellSize,
       super(size: Vector2.all(cellSize * 16), anchor: Anchor.bottomCenter);

  AvatarConfig config;
  double _cell;
  final void Function()? onTap;

  /// Nombre a mostrar encima (opcional).
  final String? name;

  AvatarMood _mood = AvatarMood.idle;
  AvatarMood get mood => _mood;
  /// Sonrisa encima del mood (p. ej. caminar + feliz al crear perfil).
  bool _smile = false;
  bool get smiling => _smile;
  double _t = 0;
  int _legFrame = 0;
  double _legTimer = 0;

  /// Velocidad del ciclo de caminata (1 = normal). Sirve para sincronizar
  /// el paso con el fondo que se mueve.
  double walkRate = 1;

  final Random _rng = Random();
  _Bubble? _bubble;
  TextComponent? _nameTag;

  double get cell => _cell;
  set cell(double v) {
    _cell = v;
    size = Vector2.all(v * 16);
    _nameTag?.position = Vector2(size.x / 2, -v * 1.5);
  }

  /// Mira a la izquierda (-1) o a la derecha (1). El volteo se aplica solo al
  /// dibujo del cuerpo (no a los hijos: nombre y burbuja siguen legibles).
  int _facing = 1;
  int get facing => _facing;
  set facing(int dir) => _facing = dir < 0 ? -1 : 1;
  TimerComponent? _danceTimer;
  TimerComponent? _waveTimer;

  @override
  Future<void> onLoad() async {
    if (name != null) {
      _nameTag = TextComponent(
        text: name!,
        anchor: Anchor.bottomCenter,
        position: Vector2(size.x / 2, -_cell * 1.5),
        textRenderer: TextPaint(
          style: TextStyle(
            fontFamily: Px.font,
            fontSize: max(6, _cell * 1.6),
            color: Px.text,
            shadows: const [
              Shadow(color: Color(0xFF000000), offset: Offset(1, 1)),
            ],
          ),
        ),
      );
      add(_nameTag!);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_mood == AvatarMood.walk) {
      _legTimer += dt;
      if (_legTimer > 0.13 / walkRate.clamp(0.2, 4)) {
        _legTimer = 0;
        _legFrame = (_legFrame + 1) % 4;
      }
    } else {
      _legFrame = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    // save/restore: los hijos (nombre, burbuja) se dibujan después con el
    // mismo canvas y no deben heredar el volteo.
    canvas.save();
    if (_facing < 0) {
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }
    // Respiración suave (medio pixel), no un salto de celda entera.
    final breathe = _mood == AvatarMood.idle && (_t % 1.4) > 0.7;
    if (breathe) canvas.translate(0, _cell * 0.35);
    final leg = switch (_legFrame) {
      1 => 1,
      3 => 2,
      _ => 0,
    };
    // Sin levantar el sprite al caminar (si no, parece que flota).
    if (_mood == AvatarMood.sit || _mood == AvatarMood.pc) {
      canvas.translate(0, _cell * 2);
    }
    if (_mood == AvatarMood.sleep) {
      canvas.translate(0, _cell * 4);
    }
    AvatarRenderer.paint(
      canvas,
      _cell,
      config,
      legFrame: (_mood == AvatarMood.sit ||
              _mood == AvatarMood.pc ||
              _mood == AvatarMood.sleep)
          ? 1
          : leg,
      wave: false,
      walking: _mood == AvatarMood.walk,
      happy: _smile ||
          _mood == AvatarMood.happy ||
          _mood == AvatarMood.jump,
    );
    if (_mood == AvatarMood.sleep) {
      final z = Paint()..color = const Color(0xFFEDEDF5);
      canvas.drawRect(Rect.fromLTWH(11 * _cell, 1 * _cell, _cell, _cell), z);
      canvas.drawRect(Rect.fromLTWH(13 * _cell, 0, _cell * 1.4, _cell * 1.4), z);
    }
    if (_mood == AvatarMood.phone) {
      final p = Paint()..color = const Color(0xFF3BFF9E);
      canvas.drawRect(
        Rect.fromLTWH(11 * _cell, 9 * _cell, _cell * 2.2, _cell * 3.2),
        p,
      );
    }
    if (_mood == AvatarMood.pc) {
      final p = Paint()..color = const Color(0xFF4D6BFF);
      canvas.drawRect(
        Rect.fromLTWH(4 * _cell, 6 * _cell, _cell * 5, _cell * 3.5),
        p,
      );
    }
    if (_mood == AvatarMood.sad) {
      final p = Paint()..color = const Color(0xFF9AD8F5);
      final y = 4 * _cell + ((_t * 6) % 3) * _cell;
      canvas.drawRect(Rect.fromLTWH(13 * _cell, y, _cell, _cell * 0.5), p);
    }
    // Feliz: brillos en los ojos.
    if (_smile || _mood == AvatarMood.happy || _mood == AvatarMood.jump) {
      final spark = Paint()..color = const Color(0xFFFFFFFF);
      canvas.drawRect(
        Rect.fromLTWH(5 * _cell, 5 * _cell, _cell * 0.55, _cell * 0.55),
        spark,
      );
      canvas.drawRect(
        Rect.fromLTWH(9 * _cell, 5 * _cell, _cell * 0.55, _cell * 0.55),
        spark,
      );
    }
    canvas.restore();
  }

  void setSmile(bool value) => _smile = value;

  bool get isHopping => children.any((c) => c is _HopEffectTag);

  //cambia el estado del avatar segun el parametro 

  void setMood(AvatarMood mood) {
    if (_mood == mood) return;
    _mood = mood;
    // No cortar hop/walk: si se corta a medias, el avatar “se baja” de la acera.
    removeWhere(
      (c) => c is Effect && c is! _WalkEffectTag && c is! _HopEffectTag,
    );
    _danceTimer?.removeFromParent();
    _danceTimer = null;
    _waveTimer?.removeFromParent();
    _waveTimer = null;
    scale = Vector2.all(1);
    angle = 0;
    switch (mood) {
      case AvatarMood.idle:
      case AvatarMood.sad:
      case AvatarMood.happy:
      case AvatarMood.walk:
      case AvatarMood.sit:
      case AvatarMood.sleep:
      case AvatarMood.phone:
      case AvatarMood.pc:
        break;
      case AvatarMood.wave:
        // Solo el sprite mueve el brazo; sin sacudir todo el cuerpo.
        _waveTimer = TimerComponent(
          period: 1.0,
          removeOnFinish: true,
          onTick: () {
            if (_mood == AvatarMood.wave) setMood(AvatarMood.walk);
          },
        );
        add(_waveTimer!);
        break;
      case AvatarMood.dance:
        add(
          MoveByEffect(
            Vector2(0, -_cell * 2),
            InfiniteEffectController(ZigzagEffectController(period: 0.45)),
          ),
        );
        // Se gira cada dos beats.
        _danceTimer = TimerComponent(
          period: 0.10,
          repeat: true,
          onTick: () => _facing = -_facing,
        );
        add(_danceTimer!);
        add(
          RotateEffect.by(
            0.12,
            InfiniteEffectController(ZigzagEffectController(period: 0.9)),
          ),
        );
        break;
      case AvatarMood.jump:
        _dust();
        add(
          MoveByEffect(
            Vector2(0, -_cell * 6),
            EffectController(
              duration: 0.28,
              reverseDuration: 0.28,
              curve: Curves.easeOut,
            ),
            onComplete: () {
              _dust();
              // Tras saltar vuelve a caminar (no se queda quieto).
              if (_mood == AvatarMood.jump) setMood(AvatarMood.walk);
            },
          ),
        );
        break;
    }
  }

  /// Salto corto sin cortar el mood (sigue la animación de caminar).
  void hop() {
    // Evita apilar hops que desalinean los pies de la acera.
    removeWhere((c) => c is _HopEffectTag);
    _dust();
    add(
      _HopEffectTag(
        Vector2(0, -_cell * 4),
        EffectController(
          duration: 0.22,
          reverseDuration: 0.22,
          curve: Curves.easeOut,
        ),
        onComplete: _dust,
      ),
    );
  }

  /// Camina hasta [target] (posición de los pies) a [speed] px/s.
  void walkTo(
    Vector2 target, {
    double speed = 60,
    void Function()? onArrive,
    bool arriveIdle = true,
  }) {
    removeWhere((c) => c is _WalkEffectTag);
    final dx = target.x - position.x;
    if (dx.abs() > 0.5) facing = dx < 0 ? -1 : 1;
    setMood(AvatarMood.walk);
    final dist = position.distanceTo(target);
    add(
      _WalkEffectTag(
        target,
        EffectController(duration: max(0.05, dist / speed)),
        onComplete: () {
          if (arriveIdle) setMood(AvatarMood.idle);
          onArrive?.call();
        },
      ),
    );
  }

  /// Burbuja de diálogo sobre la cabeza durante [seconds].
  void say(String text, {double seconds = 3}) {
    _bubble?.removeFromParent();
    _bubble = _Bubble(
      text,
      cell: _cell,
      position: Vector2(size.x / 2, -_cell * (name != null ? 4 : 1.5)),
    );
    add(_bubble!);
    add(
      TimerComponent(
        period: seconds,
        removeOnFinish: true,
        onTick: () {
          _bubble?.removeFromParent();
          _bubble = null;
        },
      ),
    );
    final low = text.toLowerCase();
    if (low.contains('hola') &&
        _mood != AvatarMood.sit &&
        _mood != AvatarMood.sleep &&
        _mood != AvatarMood.walk &&
        _mood != AvatarMood.pc) {
      setMood(AvatarMood.wave);
    }
  }

  void _dust() {
    parent?.add(
      ParticleSystemComponent(
        position: position.clone(),
        priority: priority - 1,
        particle: Particle.generate(
          count: 8,
          lifespan: 0.5,
          generator: (i) {
            final angle = pi + (i / 8) * pi;
            return AcceleratedParticle(
              speed: Vector2(cos(angle), sin(angle) * 0.4) * 40 * _cell / 4,
              child: _Dust(size: _cell, color: Px.spectrumStep(i / 8)),
            );
          },
        ),
      ),
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    onTap?.call();
    if (_mood == AvatarMood.idle) setMood(AvatarMood.jump);
  }

  /// Un emote aleatorio (para reacciones en el chat / clips).
  void randomEmote() {
    const moods = [AvatarMood.wave, AvatarMood.jump];
    setMood(moods[_rng.nextInt(moods.length)]);
  }
}

/// MoveToEffect marcado para no cancelarlo al cambiar de ánimo.
class _WalkEffectTag extends MoveToEffect {
  _WalkEffectTag(super.destination, super.controller, {super.onComplete});
}

class _HopEffectTag extends MoveByEffect {
  _HopEffectTag(super.offset, super.controller, {super.onComplete});
}

class _Dust extends Particle {
  _Dust({required this.size, required this.color});
  final double size;
  final Color color;
  final Paint _p = Paint();

  @override
  void render(Canvas canvas) {
    _p.color = color.withValues(alpha: 1 - progress);
    canvas.drawRect(Rect.fromLTWH(-size / 2, -size / 2, size, size), _p);
  }
}

/// Burbuja de diálogo pixelada.
class _Bubble extends PositionComponent {
  _Bubble(this.text, {required this.cell, required Vector2 position})
    : super(position: position, anchor: Anchor.bottomCenter, priority: 50);
  final String text;
  final double cell;
  late final TextPainter _tp;

  @override
  Future<void> onLoad() async {
    _tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: Px.font,
          fontSize: max(6, cell * 1.6),
          color: Px.bg,
          height: 1.4,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 3,
      ellipsis: '…',
    )..layout(maxWidth: cell * 40);
    size = Vector2(_tp.width + cell * 2, _tp.height + cell * 2 + cell);
    add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(duration: 0.15, curve: Curves.easeOutBack),
      ),
    );
    scale = Vector2.all(0.2);
  }

  @override
  void render(Canvas canvas) {
    final p = Paint()..color = Px.text;
    final w = size.x, h = size.y - cell;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), p);
    // Piquito.
    canvas.drawRect(Rect.fromLTWH(w / 2 - cell / 2, h, cell, cell), p);
    final border = Paint()..color = Px.bg;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, 1), border);
    _tp.paint(canvas, Offset(cell, cell));
  }
}
