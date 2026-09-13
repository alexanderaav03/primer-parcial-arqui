import 'package:banco_ejercicios_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Prueba end-to-end real contra el gateway dockerizado (no mocks):
/// login instructor -> clientes -> rutinas de un cliente -> detalle de
/// rutina -> logout -> login cliente -> sus propias rutinas -> detalle.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('flujo completo instructor + cliente contra el gateway real', (tester) async {
    app.main();

    // 1) Pantalla de login (el arranque hace una lectura async de
    // secure storage antes de pintar nada, así que esperamos con reintentos
    // en vez de un pumpAndSettle único que podría volver antes de tiempo).
    await tester.waitFor(find.text('Ingresar'));
    await tester.takeScreenshot('01_login');

    // 2) Login como instructor -> aterriza en el tab "Inicio" (dashboard)
    await tester.enterText(find.byType(TextFormField).at(0), 'carlos@gym.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'test1234');
    await tester.tap(find.text('Ingresar'));

    await tester.waitFor(find.text('Hola, Carlos Mendez'));
    expect(find.text('Clientes recientes'), findsOneWidget);
    await tester.takeScreenshot('02_inicio_instructor');

    // 2b) Tab "Clientes" -> lista completa
    // (usamos tapTab: en Inicio, "Clientes" también es el label de la stat
    // card, así que find.text('Clientes') a secas matchearía 2 widgets)
    await tester.tapTab('Clientes');
    await tester.pumpAndSettle();
    await tester.waitFor(find.text('Mis clientes'));

    expect(find.text('Ana Rojas'), findsOneWidget);
    expect(find.text('Luis Paz'), findsOneWidget);
    expect(find.text('Marta Vega'), findsOneWidget);
    expect(find.text('Objetivo: Perder grasa'), findsOneWidget);
    await tester.takeScreenshot('02c_clientes_instructor');

    // 3) Tap en Ana Rojas -> sus rutinas
    await tester.tap(find.text('Ana Rojas'));
    await tester.pumpAndSettle();
    await tester.waitFor(find.text('Rutina Semana 1'));

    expect(find.text('Ana Rojas'), findsOneWidget); // titulo del AppBar
    await tester.takeScreenshot('03_rutinas_de_ana');

    // 4) Tap en la rutina -> detalle con los 3 ejercicios sembrados
    await tester.tap(find.text('Rutina Semana 1'));
    await tester.pumpAndSettle();
    await tester.waitFor(find.text('Sentadilla'));

    expect(find.text('Extension de Cuadriceps'), findsOneWidget);
    expect(find.text('Gemelos en Maquina'), findsOneWidget);
    expect(find.text('3 series'), findsWidgets);
    expect(find.text('12 reps'), findsWidgets);
    expect(find.text('RPE 6'), findsWidgets);
    expect(find.text('Ver video'), findsWidgets);
    await tester.takeScreenshot('04_detalle_rutina_instructor');

    // 5) Volver dos veces y cerrar sesión (ahora vive en el tab "Perfil")
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.waitFor(find.text('Mis clientes'));
    await tester.tapTab('Perfil');
    await tester.pumpAndSettle();
    await tester.waitFor(find.text('Cerrar sesión'));
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    await tester.waitFor(find.text('Ingresar'));
    await tester.takeScreenshot('05_logout_vuelve_a_login');

    // 6) Login como el propio cliente Ana -> aterriza en "Inicio"
    await tester.enterText(find.byType(TextFormField).at(0), 'ana@test.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'test1234');
    await tester.tap(find.text('Ingresar'));

    await tester.waitFor(find.text('Hola, Ana Rojas'));
    expect(find.text('Tus rutinas recientes'), findsOneWidget);
    expect(find.text('Rutina Semana 1'), findsOneWidget);
    await tester.takeScreenshot('06_inicio_cliente');

    // 6b) Tab "Mis rutinas" -> misma lista, pantalla completa
    await tester.tapTab('Mis rutinas');
    await tester.pumpAndSettle();
    await tester.waitFor(find.text('Mis rutinas'));
    expect(find.text('Rutina Semana 1'), findsOneWidget);
    await tester.takeScreenshot('06c_mis_rutinas_cliente');

    await tester.tap(find.text('Rutina Semana 1'));
    await tester.pumpAndSettle();
    await tester.waitFor(find.text('Sentadilla'));

    expect(find.text('Extension de Cuadriceps'), findsOneWidget);
    expect(find.text('Gemelos en Maquina'), findsOneWidget);
    await tester.takeScreenshot('07_detalle_rutina_cliente');
  });
}

extension _RobustWait on WidgetTester {
  /// Pumpea en pequeños pasos hasta que [finder] encuentre algo o se agote
  /// [timeout]. Más confiable que pumpAndSettle() justo después de un
  /// cold start o de un request de red real al gateway.
  Future<void> waitFor(Finder finder, {Duration timeout = const Duration(seconds: 30)}) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await pump(const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) return;
    }
    // Último intento (para que el mensaje de fallo sea el de `expect`, no un timeout mudo).
    await pumpAndSettle();
  }

  /// Tapea un tab del BottomNavigationBar por su label, buscando SOLO
  /// dentro de la barra: algunos labels (ej. "Clientes") también aparecen
  /// como texto en el contenido de la pantalla (la stat card de Inicio),
  /// así que find.text(label) a secas podría matchear más de un widget.
  Future<void> tapTab(String label) async {
    final finder = find.descendant(
      of: find.byType(BottomNavigationBar),
      matching: find.text(label),
    );
    await tap(finder);
  }

  Future<void> takeScreenshot(String name) async {
    final binding = IntegrationTestWidgetsFlutterBinding.instance;
    await binding.convertFlutterSurfaceToImage();
    await pump();
    await binding.takeScreenshot(name);
  }
}
