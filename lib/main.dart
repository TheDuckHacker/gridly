import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';

import 'core/media.dart';
import 'core/nav.dart';
import 'core/pixel_theme.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Errores async de plugins (p. ej. audioplayers en web) no tumbar la app.
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    final e = details.exception;
    if (e is MissingPluginException) {
      debugPrint('Plugin ausente (ignorado): $e');
      return;
    }
    previous?.call(details);
  };

  try {
    if (MediaEnv.online) {
      MediaKit.ensureInitialized();
    }
  } catch (e) {
    debugPrint('MediaKit init falló: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GridTheme.I,
      builder: (_, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Gridly',
          theme: Px.theme(),
          navigatorObservers: [routeObserver],
          home: const LoginScreen(playIntro: true),
          builder: (context, child) {
            return ListenableBuilder(
              listenable: GridTheme.I,
              builder: (_, __) => child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}
