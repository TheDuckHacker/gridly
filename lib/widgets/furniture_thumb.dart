import 'package:flutter/material.dart';

import '../core/pixel_theme.dart';
import '../core/room.dart';
import 'local_image.dart' if (dart.library.io) 'local_image_io.dart';

/// Miniatura de un mueble del catálogo (para el editor de la habitación).
class FurnitureThumb extends StatelessWidget {
  const FurnitureThumb({super.key, required this.type, this.size = 48});
  final String type;
  final double size;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: RgbClock.I,
    builder:
        (_, __) => CustomPaint(
          size: Size.square(size),
          painter: _ThumbPainter(Furniture.catalog[type]!, RgbClock.I.at(0)),
        ),
  );
}

class _ThumbPainter extends CustomPainter {
  _ThumbPainter(this.f, this.glow);
  final Furniture f;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = (size.width / f.w).clamp(0.5, size.height / f.h);
    final w = f.w * cell, h = f.h * cell;
    canvas.translate((size.width - w) / 2, (size.height - h) / 2);
    Furniture.paint(canvas, f, cell, glowColor: f.glow != null ? glow : null);
  }

  @override
  bool shouldRepaint(_ThumbPainter old) => old.glow != glow || old.f != f;
}

/// Banner de perfil (degradado + patrón pixel).
class PixelBanner extends StatelessWidget {
  const PixelBanner({
    super.key,
    required this.index,
    this.height = 110,
    this.child,
    this.imageUrl,
  });
  final int index;
  final double height;
  final Widget? child;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colors = RoomPalettes.banners[index % RoomPalettes.banners.length];
    Widget? photo;
    final url = imageUrl;
    if (url != null) {
      photo =
          url.startsWith('http')
              ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              )
              : localFileImage(url);
    }
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          if (photo != null) photo,
          if (url == null) CustomPaint(painter: _BannerPattern()),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _BannerPattern extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0x22000000);
    const c = 6.0;
    for (var y = 0.0; y < size.height; y += c * 2) {
      for (
        var x = (y ~/ (c * 2)).isEven ? 0.0 : c;
        x < size.width;
        x += c * 2
      ) {
        canvas.drawRect(Rect.fromLTWH(x, y, c, c), p);
      }
    }
    // Scanlines suaves.
    final s = Paint()..color = const Color(0x11000000);
    for (var y = 0.0; y < size.height; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), s);
    }
  }

  @override
  bool shouldRepaint(_BannerPattern old) => false;
}
