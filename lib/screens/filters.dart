import 'dart:math';

import 'package:flutter/material.dart';

import '../core/pixel_theme.dart';

/// Filtros pixel / retro para fotos del feed y crear.
class PixelFilter extends StatelessWidget {
  const PixelFilter({super.key, required this.name, required this.child});

  final String name;
  final Widget child;

  static const names = [
    'Normal',
    'Neon',
    'Night',
    'Warm',
    'CRT',
    'Mono',
  ];

  static ColorFilter? _filterFor(String name) {
    switch (name) {
      case 'Neon':
        return const ColorFilter.matrix(<double>[
          1.2, 0.1, 0.3, 0, 10,
          0.05, 1.15, 0.35, 0, 5,
          0.25, 0.15, 1.4, 0, 20,
          0, 0, 0, 1, 0,
        ]);
      case 'Night':
        return const ColorFilter.matrix(<double>[
          0.7, 0.1, 0.2, 0, -10,
          0.05, 0.75, 0.25, 0, 5,
          0.15, 0.2, 1.1, 0, 25,
          0, 0, 0, 1, 0,
        ]);
      case 'Warm':
        return const ColorFilter.matrix(<double>[
          1.25, 0.1, 0, 0, 15,
          0.05, 1.05, 0, 0, 5,
          0, 0.05, 0.85, 0, -5,
          0, 0, 0, 1, 0,
        ]);
      case 'CRT':
        return const ColorFilter.matrix(<double>[
          1.1, 0.05, 0.15, 0, 0,
          0.05, 1.0, 0.1, 0, 0,
          0.1, 0.1, 1.2, 0, 10,
          0, 0, 0, 1, 0,
        ]);
      case 'Mono':
        return const ColorFilter.matrix(<double>[
          0.33, 0.59, 0.11, 0, 0,
          0.33, 0.59, 0.11, 0, 0,
          0.33, 0.59, 0.11, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = _filterFor(name);
    Widget out = child;
    if (f != null) {
      out = ColorFiltered(colorFilter: f, child: out);
    }
    if (name == 'CRT') {
      out = Stack(
        fit: StackFit.expand,
        children: [
          out,
          const Positioned.fill(child: CustomPaint(painter: _Scanlines())),
        ],
      );
    }
    if (name == 'Neon') {
      out = Stack(
        fit: StackFit.expand,
        children: [
          out,
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Px.accent.withValues(alpha: 0.12),
                    Colors.transparent,
                    Px.magenta.withValues(alpha: 0.14),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
    return out;
  }
}

class _Scanlines extends CustomPainter {
  const _Scanlines();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0x22000000);
    final step = max(2.0, size.height / 90);
    for (var y = 0.0; y < size.height; y += step * 2) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, step), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
