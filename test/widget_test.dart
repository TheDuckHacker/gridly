import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prueba/core/app_state.dart';
import 'package:prueba/core/pixel_theme.dart';
import 'package:prueba/game/login_background_game.dart';
import 'package:prueba/game/room_game.dart';
import 'package:prueba/screens/home_shell.dart';
import 'package:prueba/screens/login_screen.dart';
import 'package:prueba/screens/room_editor_screen.dart';
import 'package:prueba/main.dart';

/// El GameWidget programa frames continuamente, así que no se puede usar
/// pumpAndSettle; avanzamos el reloj a mano. Se ejecuta dentro de runAsync
/// para que Flame pueda cargar las imágenes de assets (I/O real).
Future<void> pumpFor(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 100);
  var elapsed = Duration.zero;
  while (elapsed < total) {
    await tester.pump(step);
    await Future<void>.delayed(const Duration(milliseconds: 1));
    elapsed += step;
  }
}

Future<void> pumpLogin(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(theme: Px.theme(), home: const LoginScreen()),
  );
  await tester.pump();
}

void main() {
  testWidgets('splash muestra intro de marca y permite entrar', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const MyApp());
      await tester.pump();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('TOCA PARA ENTRAR'), findsOneWidget);

      await tester.tap(find.text('TOCA PARA ENTRAR'));
      await pumpFor(tester, const Duration(milliseconds: 1200));
      expect(find.text('CONTINUAR'), findsOneWidget);
    });
  });

  testWidgets('muestra la pantalla de login con la escena de Flame', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() async {
      await pumpLogin(tester);

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(GameWidget<LoginBackgroundGame>), findsOneWidget);

      await pumpFor(tester, const Duration(milliseconds: 2200));
      expect(find.text('CONTINUAR'), findsOneWidget);
      expect(find.text('CELULAR'), findsOneWidget);
    });
  });

  testWidgets('valida celular vacío al intentar entrar', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() async {
      await pumpLogin(tester);
      await pumpFor(tester, const Duration(milliseconds: 2200));

      await tester.tap(find.text('CONTINUAR'));
      await tester.pump();

      expect(find.text('Mínimo 8 dígitos'), findsOneWidget);
    });
  });

  testWidgets('entrar con celular válido dispara la celebración', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() async {
      await pumpLogin(tester);
      await pumpFor(tester, const Duration(milliseconds: 2200));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '5551234567');
      await tester.tap(find.text('CONTINUAR'));
      await pumpFor(tester, const Duration(milliseconds: 2200));

      expect(find.text('VERIFICAR'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.tap(find.text('VERIFICAR'));
      await pumpFor(tester, const Duration(milliseconds: 1200));

      expect(find.text('ENTRAR'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'Ana');
      await tester.tap(find.text('ENTRAR'));
      await tester.pump();

      await pumpFor(tester, const Duration(milliseconds: 5600));
      expect(find.byType(HomeShell), findsOneWidget);
      expect(find.text('GRIDLY'), findsOneWidget);
      expect(AppState.I.username, 'Ana');
      expect(AppState.I.phone, '5551234567');
    });
  });

  testWidgets('la red social navega entre pestañas con escenas Flame', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(theme: Px.theme(), home: const HomeShell()),
      );
      await pumpFor(tester, const Duration(milliseconds: 400));
      expect(find.text('GRIDLY'), findsOneWidget);

      await tester.tap(find.text('CLIPS'));
      await pumpFor(tester, const Duration(milliseconds: 400));
      expect(find.text('PARA TI'), findsOneWidget);
      expect(find.text('SIGUIENDO'), findsOneWidget);

      await tester.tap(find.text('CREAR'));
      await pumpFor(tester, const Duration(milliseconds: 400));
      expect(find.text('FOTO'), findsOneWidget);
      expect(find.text('VIDEO'), findsOneWidget);
      expect(find.text('HISTORIA'), findsOneWidget);

      await tester.tap(find.text('AMIGOS'));
      await pumpFor(tester, const Duration(milliseconds: 400));
      expect(find.textContaining('AMIGOS'), findsWidgets);
      expect(find.text('SUGERIDOS'), findsOneWidget);

      await tester.tap(find.byTooltip('Tu perfil'));
      await pumpFor(tester, const Duration(milliseconds: 400));
      expect(find.text('CLOSET'), findsOneWidget);
      expect(find.text('DECORAR'), findsOneWidget);
      expect(find.text('HABITACIÓN'), findsOneWidget);
    });
  });

  testWidgets('la habitación se decora y se guarda', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(theme: Px.theme(), home: const RoomEditorScreen()),
      );
      await pumpFor(tester, const Duration(milliseconds: 400));
      final before = AppState.I.room.items.length;

      await tester.tap(find.text('PLANTA'));
      await tester.pump();
      final gameBox = tester.getRect(find.byType(GameWidget<RoomGame>));
      await tester.tapAt(Offset(gameBox.center.dx, gameBox.bottom - 20));
      await pumpFor(tester, const Duration(milliseconds: 300));

      await tester.tap(find.text('GUARDAR'));
      await pumpFor(tester, const Duration(milliseconds: 300));
      expect(AppState.I.room.items.length, before + 1);
      expect(AppState.I.room.items.last.type, 'plant');
    });
  });
}
