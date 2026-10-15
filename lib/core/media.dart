import 'dart:math';

import 'test_env.dart' if (dart.library.io) 'test_env_io.dart';

/// Medios de la demo: imágenes de internet + videos locales (assets).
///
/// Los clips usan MP4 embebidos porque muchos links públicos (p. ej. Google
/// sample bucket) devuelven 403 y media_kit marca "no disponible".
class MediaEnv {
  MediaEnv._();

  /// Falso solo en `flutter test` (VM). En Chrome y en Windows es verdadero.
  static bool get online => !isFlutterTest;

  /// Imagen estable por semilla.
  static String picsum(String seed, {int w = 800, int h = 800}) =>
      'https://picsum.photos/seed/$seed/$w/$h';

  /// Videos locales empaquetados en la app (siempre reproducibles).
  static const sampleVideos = <String>[
    'asset:///assets/videos/clip1.mp4',
    'asset:///assets/videos/clip2.mp4',
    'asset:///assets/videos/clip3.mp4',
    'asset:///assets/videos/clip4.mp4',
    'asset:///assets/videos/clip5.mp4',
    'asset:///assets/videos/clip6.mp4',
  ];

  static final _rnd = Random();

  static String randomImage({int w = 800, int h = 800}) =>
      picsum('pg${_rnd.nextInt(99999)}', w: w, h: h);

  static String randomVideo() =>
      sampleVideos[_rnd.nextInt(sampleVideos.length)];

  static bool isUrl(String s) {
    final t = s.trim();
    if (t.startsWith('asset:///') || t.startsWith('file://')) return true;
    final u = Uri.tryParse(t);
    return u != null &&
        (u.scheme == 'http' || u.scheme == 'https') &&
        u.host.isNotEmpty;
  }

  static bool looksLikeVideo(String url) {
    final p = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
    return p.endsWith('.mp4') ||
        p.endsWith('.webm') ||
        p.endsWith('.mov') ||
        p.endsWith('.m3u8') ||
        p.endsWith('.mkv');
  }

  /// URI lista para media_kit (asset / http / https / file).
  static String playableUri(String url) {
    final t = url.trim();
    if (t.startsWith('asset:///') ||
        t.startsWith('http://') ||
        t.startsWith('https://') ||
        t.startsWith('file://')) {
      return t;
    }
    // Ruta de asset tipo assets/videos/x.mp4
    if (t.startsWith('assets/')) return 'asset:///$t';
    return t;
  }
}
