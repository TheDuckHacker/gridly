import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';

import '../core/pixel_theme.dart';
import '../widgets/pixel_avatar.dart';
import 'avatar_component.dart';

/// Tarima RGB para el editor de avatar y la vista previa de "Crear": rejilla
/// de fondo, suelo con luz RGB, partículas y el avatar al centro.
class AvatarStageGame extends FlameGame {
  AvatarStageGame({required AvatarConfig config, bool showCampfire = false})
    : _config = config;

  AvatarConfig _config;

  late final PixelAvatarComponent avatar;
  final Random _rng = Random();
  double t = 0;

  double get cell => (size.y / 40).clamp(2.0, 8.0);

  @override
  Color backgroundColor() => Px.panel;

  @override
  Future<void> onLoad() async {
    world.add(_Ground());
    avatar = PixelAvatarComponent(config: _config, cellSize: cell);
    world.add(avatar);
    world.add(TimerComponent(period: 0.6, repeat: true, onTick: _spark));
    camera.viewfinder.anchor = Anchor.topLeft;
    _layout();
    avatar.setMood(AvatarMood.wave);
  }

  @override
  void update(double dt) {
    super.update(dt);
    t += dt;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) _layout();
  }

  void _layout() {
    final groundY = size.y - 6 * cell;
    avatar
      ..cell = cell
      ..position = Vector2(size.x * 0.5, groundY);
  }

  void setConfig(AvatarConfig config) {
    _config = config;
    if (isLoaded) {
      avatar.config = config;
      avatar.setMood(AvatarMood.jump);
    }
  }

  void _spark() {
    if (size.x == 0) return;
    final c = Px.rgb[_rng.nextInt(Px.rgb.length)];
    world.add(
      ParticleSystemComponent(
        position: Vector2(
          _rng.nextDouble() * size.x,
          size.y * (0.3 + _rng.nextDouble() * 0.5),
        ),
        particle: MovingParticle(
          to: Vector2((_rng.nextDouble() - 0.5) * 30, -20),
          lifespan: 3,
          child: ComputedParticle(
            renderer: (canvas, p) {
              final a =
                  sin(p.progress * pi) * (0.5 + 0.5 * sin(p.progress * 20));
              canvas.drawRect(
                Rect.fromLTWH(0, 0, cell * 0.8, cell * 0.8),
                Paint()..color = c.withValues(alpha: a.clamp(0, 1)),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Ground extends PositionComponent with HasGameReference<AvatarStageGame> {
  _Ground() : super(priority: -10);

  @override
  void render(Canvas canvas) {
    final g = game;
    final c = g.cell;
    final s = g.size;
    final groundY = s.y - 6 * c;
    // Suelo con franja RGB.
    final n = (s.x / (c * 2)).ceil();
    for (var i = 0; i < n; i++) {
      canvas.drawRect(
        Rect.fromLTWH(i * c * 2, groundY, c * 2 + 0.5, c),
        Paint()..color = Px.spectrumStep(i / n - g.t / 4),
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(0, groundY + c, s.x, 5 * c),
      Paint()..color = Px.panelLight,
    );
    // Rejilla de fondo tenue estilo "escenario".
    final grid =
        Paint()
          ..color = Px.border.withValues(alpha: 0.5)
          ..strokeWidth = 1;
    for (var x = 0.0; x < s.x; x += c * 4) {
      canvas.drawLine(Offset(x, 0), Offset(x, groundY), grid);
    }
    for (var y = 0.0; y < groundY; y += c * 4) {
      canvas.drawLine(Offset(0, y), Offset(s.x, y), grid);
    }
  }
}
