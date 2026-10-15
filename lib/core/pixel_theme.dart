import 'dart:math';

import 'package:flutter/material.dart';

/// Temas de Gridly. Cambia con [GridTheme.I.setTheme].
enum GridThemeId { dark, light, pink, ocean, sunset }

class GridPalette {
  const GridPalette({
    required this.id,
    required this.name,
    required this.bg,
    required this.panel,
    required this.panelLight,
    required this.border,
    required this.accent,
    required this.accentDim,
    required this.accentDark,
    required this.magenta,
    required this.text,
    required this.textDim,
    required this.danger,
    required this.gold,
    required this.online,
    required this.idle,
    required this.offline,
    required this.rgb,
    required this.brightness,
  });

  final GridThemeId id;
  final String name;
  final Color bg;
  final Color panel;
  final Color panelLight;
  final Color border;
  final Color accent;
  final Color accentDim;
  final Color accentDark;
  final Color magenta;
  final Color text;
  final Color textDim;
  final Color danger;
  final Color gold;
  final Color online;
  final Color idle;
  final Color offline;
  final List<Color> rgb;
  final Brightness brightness;
}

/// Controlador global de tema.
class GridTheme extends ChangeNotifier {
  GridTheme._();
  static final GridTheme I = GridTheme._();

  GridThemeId _id = GridThemeId.dark;
  GridThemeId get id => _id;
  GridPalette get palette => palettes[_id]!;

  static const palettes = <GridThemeId, GridPalette>{
    GridThemeId.dark: GridPalette(
      id: GridThemeId.dark,
      name: 'OSCURO',
      bg: Color(0xFF0A0A12),
      panel: Color(0xFF13131E),
      panelLight: Color(0xFF1C1C2B),
      border: Color(0xFF2B2B40),
      accent: Color(0xFF3BFF9E),
      accentDim: Color(0xFF1FD6FF),
      accentDark: Color(0xFF7B5CFF),
      magenta: Color(0xFFFF3BD4),
      text: Color(0xFFF2F2FF),
      textDim: Color(0xFF9B9BBF),
      danger: Color(0xFFFF4D6D),
      gold: Color(0xFFFFD23B),
      online: Color(0xFF3BFF9E),
      idle: Color(0xFFFFD23B),
      offline: Color(0xFF55557A),
      brightness: Brightness.dark,
      rgb: [
        Color(0xFFFF3B5C),
        Color(0xFFFF8A1F),
        Color(0xFFFFE31A),
        Color(0xFF3BFF9E),
        Color(0xFF1FD6FF),
        Color(0xFF4D6BFF),
        Color(0xFF9D4DFF),
        Color(0xFFFF3BD4),
      ],
    ),
    GridThemeId.light: GridPalette(
      id: GridThemeId.light,
      name: 'CLARO',
      bg: Color(0xFFF4F1EA),
      panel: Color(0xFFFFFFFF),
      panelLight: Color(0xFFECE7DC),
      border: Color(0xFFC8BFAE),
      accent: Color(0xFF0D9F6E),
      accentDim: Color(0xFF1A7A9C),
      accentDark: Color(0xFF5B4B8A),
      magenta: Color(0xFFC2185B),
      text: Color(0xFF1A1A1A),
      textDim: Color(0xFF6B6570),
      danger: Color(0xFFD32F2F),
      gold: Color(0xFFC9A227),
      online: Color(0xFF0D9F6E),
      idle: Color(0xFFC9A227),
      offline: Color(0xFF9E9E9E),
      brightness: Brightness.light,
      rgb: [
        Color(0xFFE53935),
        Color(0xFFFB8C00),
        Color(0xFFFDD835),
        Color(0xFF43A047),
        Color(0xFF00ACC1),
        Color(0xFF3949AB),
        Color(0xFF8E24AA),
        Color(0xFFD81B60),
      ],
    ),
    GridThemeId.pink: GridPalette(
      id: GridThemeId.pink,
      name: 'ROSA',
      bg: Color(0xFF1A0F14),
      panel: Color(0xFF2A1520),
      panelLight: Color(0xFF3A1F2E),
      border: Color(0xFF5A3348),
      accent: Color(0xFFFF6B9D),
      accentDim: Color(0xFFFFB4D0),
      accentDark: Color(0xFFE91E8C),
      magenta: Color(0xFFFF3D8A),
      text: Color(0xFFFFF0F5),
      textDim: Color(0xFFC9A0B0),
      danger: Color(0xFFFF4D6D),
      gold: Color(0xFFFFD4A3),
      online: Color(0xFFFF6B9D),
      idle: Color(0xFFFFD4A3),
      offline: Color(0xFF6A4555),
      brightness: Brightness.dark,
      rgb: [
        Color(0xFFFF6B9D),
        Color(0xFFFF8FB5),
        Color(0xFFFFB4D0),
        Color(0xFFE91E8C),
        Color(0xFFFF3D8A),
        Color(0xFFFFC0CB),
        Color(0xFFFF9EC7),
        Color(0xFFFF5C8A),
      ],
    ),
    GridThemeId.ocean: GridPalette(
      id: GridThemeId.ocean,
      name: 'OCÉANO',
      bg: Color(0xFF06141C),
      panel: Color(0xFF0C2230),
      panelLight: Color(0xFF143344),
      border: Color(0xFF1F4D63),
      accent: Color(0xFF2DE2C5),
      accentDim: Color(0xFF4FC3F7),
      accentDark: Color(0xFF0288D1),
      magenta: Color(0xFF7C4DFF),
      text: Color(0xFFE8F7FF),
      textDim: Color(0xFF8AADC0),
      danger: Color(0xFFFF6B6B),
      gold: Color(0xFFFFD166),
      online: Color(0xFF2DE2C5),
      idle: Color(0xFFFFD166),
      offline: Color(0xFF4A6A7A),
      brightness: Brightness.dark,
      rgb: [
        Color(0xFF2DE2C5),
        Color(0xFF4FC3F7),
        Color(0xFF0288D1),
        Color(0xFF26A69A),
        Color(0xFF80DEEA),
        Color(0xFF5C6BC0),
        Color(0xFF7C4DFF),
        Color(0xFF00BCD4),
      ],
    ),
    GridThemeId.sunset: GridPalette(
      id: GridThemeId.sunset,
      name: 'ATARDECER',
      bg: Color(0xFF1A100C),
      panel: Color(0xFF2A1A12),
      panelLight: Color(0xFF3A2618),
      border: Color(0xFF5A3A28),
      accent: Color(0xFFFF8A3D),
      accentDim: Color(0xFFFFC14D),
      accentDark: Color(0xFFE85D04),
      magenta: Color(0xFFFF5E7A),
      text: Color(0xFFFFF4EA),
      textDim: Color(0xFFC9A890),
      danger: Color(0xFFFF4D4D),
      gold: Color(0xFFFFD23B),
      online: Color(0xFFFF8A3D),
      idle: Color(0xFFFFD23B),
      offline: Color(0xFF6A5040),
      brightness: Brightness.dark,
      rgb: [
        Color(0xFFFF5E7A),
        Color(0xFFFF8A3D),
        Color(0xFFFFC14D),
        Color(0xFFFFD23B),
        Color(0xFFE85D04),
        Color(0xFFFF6B4A),
        Color(0xFFFFAB76),
        Color(0xFFFF3D5A),
      ],
    ),
  };

  void setTheme(GridThemeId id) {
    if (_id == id) return;
    _id = id;
    notifyListeners();
  }
}

/// Acceso a colores del tema activo (antes eran const fijos).
abstract final class Px {
  static GridPalette get _p => GridTheme.I.palette;

  static Color get bg => _p.bg;
  static Color get panel => _p.panel;
  static Color get panelLight => _p.panelLight;
  static Color get border => _p.border;
  static Color get accent => _p.accent;
  static Color get accentDim => _p.accentDim;
  static Color get accentDark => _p.accentDark;
  static Color get magenta => _p.magenta;
  static Color get text => _p.text;
  static Color get textDim => _p.textDim;
  static Color get danger => _p.danger;
  static Color get gold => _p.gold;
  static Color get online => _p.online;
  static Color get idle => _p.idle;
  static Color get offline => _p.offline;
  static List<Color> get rgb => _p.rgb;

  static Color spectrum(double t) {
    final list = rgb;
    final x = (t % 1 + 1) % 1 * list.length;
    final i = x.floor() % list.length;
    return Color.lerp(list[i], list[(i + 1) % list.length], x - x.floorToDouble())!;
  }

  static Color spectrumStep(double t) {
    final list = rgb;
    return list[((t % 1 + 1) % 1 * list.length).floor() % list.length];
  }

  static const font = 'PressStart2P';

  static TextStyle title([double size = 11, Color? color]) =>
      TextStyle(
        fontFamily: font,
        fontSize: size,
        color: color ?? text,
        height: 1.6,
      );

  static TextStyle label([double size = 7, Color? color]) =>
      TextStyle(
        fontFamily: font,
        fontSize: size,
        color: color ?? textDim,
        height: 1.6,
      );

  static TextStyle get body =>
      TextStyle(color: text, fontSize: 14, height: 1.35);
  static TextStyle get bodyDim =>
      TextStyle(color: textDim, fontSize: 12, height: 1.35);

  static ThemeData theme() {
    final p = _p;
    final dark = p.brightness == Brightness.dark;
    return ThemeData(
      brightness: p.brightness,
      useMaterial3: true,
      scaffoldBackgroundColor: p.bg,
      colorScheme:
          dark
              ? ColorScheme.dark(
                primary: p.accent,
                secondary: p.accentDim,
                tertiary: p.magenta,
                surface: p.panel,
                error: p.danger,
              )
              : ColorScheme.light(
                primary: p.accent,
                secondary: p.accentDim,
                tertiary: p.magenta,
                surface: p.panel,
                error: p.danger,
              ),
      splashFactory: InkSparkle.splashFactory,
      textTheme: TextTheme(bodyMedium: body),
    );
  }
}

/// Reloj global para acentos RGB (en movimiento continuo).
class RgbClock extends ChangeNotifier {
  RgbClock._() {
    Stream<void>.periodic(const Duration(milliseconds: 80)).listen((_) {
      t += 0.018;
      notifyListeners();
    });
  }
  static final RgbClock I = RgbClock._();
  double t = 0;

  Color at(double offset) => Px.spectrum(t + offset);

  /// Misma fórmula para splash y logo GRIDLY (letra i).
  Color gridlyLetter(int i) => at(i * 0.12);
}

/// Marco pixelado RGB animado alrededor de [child].
class RgbFrame extends StatelessWidget {
  const RgbFrame({
    super.key,
    required this.child,
    this.thickness = 3,
    this.segment = 8,
    this.padding = EdgeInsets.zero,
    this.fill,
    this.speed = 1,
    this.stepped = true,
  });

  final Widget child;
  final double thickness;
  final double segment;
  final EdgeInsets padding;
  final Color? fill;
  final double speed;
  final bool stepped;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([RgbClock.I, GridTheme.I]),
      builder:
          (_, __) => CustomPaint(
            painter: _RgbBorderPainter(
              t: RgbClock.I.t * speed,
              thickness: thickness,
              segment: segment,
              fill: fill ?? Px.panel,
              stepped: stepped,
            ),
            child: Padding(
              padding: EdgeInsets.all(thickness) + padding,
              child: child,
            ),
          ),
    );
  }
}

class _RgbBorderPainter extends CustomPainter {
  _RgbBorderPainter({
    required this.t,
    required this.thickness,
    required this.segment,
    required this.fill,
    required this.stepped,
  });
  final double t;
  final double thickness;
  final double segment;
  final Color? fill;
  final bool stepped;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    if (fill != null) {
      p.color = fill!;
      canvas.drawRect(Offset.zero & size, p);
    }
    final perim = 2 * (size.width + size.height);
    final n = max(8, (perim / segment).floor());
    final segLen = perim / n;
    for (var i = 0; i < n; i++) {
      final d = i * segLen;
      final f = d / perim;
      p.color = stepped ? Px.spectrumStep(f - t) : Px.spectrum(f - t);
      canvas.drawRect(_segmentRect(d, segLen, size), p);
    }
  }

  Rect _segmentRect(double d, double len, Size s) {
    final th = thickness;
    if (d < s.width) {
      return Rect.fromLTWH(d, 0, min(len, s.width - d) + 0.5, th);
    }
    d -= s.width;
    if (d < s.height) {
      return Rect.fromLTWH(s.width - th, d, th, min(len, s.height - d) + 0.5);
    }
    d -= s.height;
    if (d < s.width) {
      return Rect.fromLTWH(s.width - d - len, s.height - th, len + 0.5, th);
    }
    d -= s.width;
    return Rect.fromLTWH(0, s.height - d - len, th, len + 0.5);
  }

  @override
  bool shouldRepaint(_RgbBorderPainter old) => old.t != t || old.fill != fill;
}

/// Texto con degradado RGB en movimiento.
class RgbText extends StatelessWidget {
  const RgbText(this.text, {super.key, this.style, this.textAlign});
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([RgbClock.I, GridTheme.I]),
      builder:
          (_, __) => ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback:
                (r) => LinearGradient(
                  colors: [for (var i = 0; i < 5; i++) RgbClock.I.at(i / 5)],
                ).createShader(r),
            child: Text(text, style: style ?? Px.title(), textAlign: textAlign),
          ),
    );
  }
}

/// Barra de progreso RGB pixelada.
class RgbBar extends StatelessWidget {
  const RgbBar({super.key, required this.value, this.height = 10});
  final double value;
  final double height;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([RgbClock.I, GridTheme.I]),
    builder:
        (_, __) => Container(
          height: height,
          decoration: BoxDecoration(
            border: Border.all(color: Px.border, width: 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value.clamp(0, 1),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [for (var i = 0; i < 4; i++) RgbClock.I.at(i / 8)],
                ),
              ),
            ),
          ),
        ),
  );
}

/// Selector visual de temas.
class ThemePickerSheet extends StatelessWidget {
  const ThemePickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GridTheme.I,
      builder: (_, __) {
        return PixelThemePanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('TEMA', style: Px.title(8)),
              const SizedBox(height: 6),
              Text('Cambia los colores de toda la app', style: Px.bodyDim),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in GridTheme.palettes.values)
                    _ThemeSwatch(
                      palette: p,
                      selected: GridTheme.I.id == p.id,
                      onTap: () => GridTheme.I.setTheme(p.id),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

/// Panel mínimo sin depender de pixel_ui (evita import circular).
class PixelThemePanel extends StatelessWidget {
  const PixelThemePanel({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(2),
      color: Px.border,
      child: Container(
        color: Px.panel,
        padding: const EdgeInsets.all(14),
        child: child,
      ),
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({
    required this.palette,
    required this.selected,
    required this.onTap,
  });
  final GridPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: palette.panel,
          border: Border.all(
            color: selected ? palette.accent : palette.border,
            width: selected ? 3 : 2,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                for (final c in [palette.bg, palette.accent, palette.magenta])
                  Expanded(
                    child: Container(height: 18, color: c),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              palette.name,
              style: TextStyle(
                fontFamily: Px.font,
                fontSize: 6,
                color: palette.text,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
