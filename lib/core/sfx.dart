import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

/// Sonidos cortos de UI (tap / éxito / error).
/// En web/tests, si el plugin falla, se desactiva sin tumbar la app.
class Sfx {
  Sfx._();
  static final Sfx I = Sfx._();

  AudioPlayer? _tap;
  AudioPlayer? _ok;
  AudioPlayer? _err;
  bool _ready = false;
  bool _unavailable = false;

  static bool _isWidgetTest() {
    return WidgetsBinding.instance.runtimeType.toString().contains(
      'TestWidgets',
    );
  }

  Future<void> init() async {
    if (_ready || _unavailable || _isWidgetTest()) return;
    try {
      _tap = AudioPlayer();
      _ok = AudioPlayer();
      _err = AudioPlayer();
      await Future.wait([
        _tap!.setReleaseMode(ReleaseMode.stop),
        _ok!.setReleaseMode(ReleaseMode.stop),
        _err!.setReleaseMode(ReleaseMode.stop),
        _tap!.setVolume(0.55),
        _ok!.setVolume(0.7),
        _err!.setVolume(0.6),
      ]);
      _ready = true;
    } catch (e) {
      debugPrint('Sfx desactivado: $e');
      _unavailable = true;
      _tap = null;
      _ok = null;
      _err = null;
    }
  }

  Future<void> _safePlay(Future<void> Function() run) async {
    if (_unavailable) return;
    try {
      await init();
      if (_unavailable) return;
      await run();
    } catch (e) {
      debugPrint('Sfx play falló: $e');
      _unavailable = true;
    }
  }

  Future<void> tap() => _safePlay(() async {
    if (_tap == null) return;
    await _tap!.stop();
    await _tap!.play(AssetSource('sounds/tap.wav'));
  });

  Future<void> success() => _safePlay(() async {
    if (_ok == null) return;
    await _ok!.stop();
    await _ok!.play(AssetSource('sounds/success.wav'));
  });

  Future<void> error() => _safePlay(() async {
    if (_err == null) return;
    await _err!.stop();
    await _err!.play(AssetSource('sounds/error.wav'));
  });

  Future<void> dispose() async {
    try {
      await _tap?.dispose();
      await _ok?.dispose();
      await _err?.dispose();
    } catch (_) {}
    _tap = null;
    _ok = null;
    _err = null;
    _ready = false;
  }
}
