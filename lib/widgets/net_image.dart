import 'package:flutter/material.dart';

import '../core/media.dart';
import '../core/pixel_theme.dart';
import 'local_image.dart' if (dart.library.io) 'local_image_io.dart';
import 'pixel_ui.dart';

/// Imagen desde internet (o archivo local) con carga pixel y respaldo.
///
/// - `url`: link http(s) de la imagen.
/// - `localPath`: foto del dispositivo (tiene prioridad sobre `url`).
/// - `fallback`: qué mostrar si no hay red / falla la carga.
class NetImage extends StatelessWidget {
  const NetImage({
    super.key,
    this.url,
    this.localPath,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  final String? url;
  final String? localPath;
  final BoxFit fit;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final fb = fallback ?? const _PixelPlaceholder(broken: true);
    if (localPath != null) {
      return localFileImage(localPath!) ?? fb;
    }
    if (url == null || !MediaEnv.online) return fb;
    return Image.network(
      url!,
      fit: fit,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        final total = progress.expectedTotalBytes;
        final value =
            total == null ? null : progress.cumulativeBytesLoaded / total;
        return _PixelPlaceholder(progress: value);
      },
      errorBuilder: (_, __, ___) => fb,
    );
  }
}

class _PixelPlaceholder extends StatelessWidget {
  const _PixelPlaceholder({this.progress, this.broken = false});
  final double? progress;
  final bool broken;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Px.panel,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PixelGlyph(
              kind: PixelGlyphKind.image,
              color: broken ? Px.textDim : Px.accent,
              size: 28,
            ),
            const SizedBox(height: 10),
            if (!broken)
              SizedBox(
                width: 120,
                height: 6,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Px.border,
                  color: Px.accent,
                  minHeight: 6,
                ),
              )
            else
              Text('SIN IMAGEN', style: Px.label(6, Px.textDim)),
          ],
        ),
      ),
    );
  }
}
