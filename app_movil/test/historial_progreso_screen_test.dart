import 'package:banco_ejercicios_app/features/models/registro_progreso.dart';
import 'package:banco_ejercicios_app/features/progreso/historial_progreso_screen.dart';
import 'package:banco_ejercicios_app/features/progreso/progreso_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

RegistroProgreso _registro(int id, DateTime fecha, num peso) => RegistroProgreso(
      id: id,
      detalleRutinaId: 1,
      fecha: fecha,
      seriesRealizadas: 3,
      repeticionesRealizadas: 10,
      pesoRealizado: peso,
      nota: null,
    );

Future<void> _pumpConRegistros(WidgetTester tester, List<RegistroProgreso> registros) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        registrosProgresoProvider((rutinaId: 1, detalleId: 1)).overrideWith((ref) async => registros),
      ],
      child: const MaterialApp(
        home: HistorialProgresoScreen(rutinaId: 1, detalleId: 1, ejercicioNombre: 'Sentadilla'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sin registros muestra el EmptyView y no el gráfico', (tester) async {
    await _pumpConRegistros(tester, []);

    expect(find.text('Este cliente todavía no registró ninguna sesión de este ejercicio.'), findsOneWidget);
    expect(find.byType(LayoutBuilder), findsNothing); // fl_chart usa LayoutBuilder internamente
  });

  testWidgets('un solo registro dibuja el gráfico sin romper (punto sin línea)', (tester) async {
    await _pumpConRegistros(tester, [_registro(1, DateTime(2026, 9, 1), 20)]);

    expect(find.text('Peso realizado (kg)'), findsOneWidget);
    expect(find.text('20 kg'), findsOneWidget);
  });

  testWidgets('varios registros con el mismo peso no rompen el eje Y (rango 0)', (tester) async {
    await _pumpConRegistros(tester, [
      _registro(1, DateTime(2026, 9, 1), 20),
      _registro(2, DateTime(2026, 9, 3), 20),
    ]);

    expect(find.text('Peso realizado (kg)'), findsOneWidget);
    expect(find.text('20 kg'), findsNWidgets(2));
  });

  testWidgets('varios registros con pesos distintos muestran el gráfico y la lista', (tester) async {
    await _pumpConRegistros(tester, [
      _registro(1, DateTime(2026, 9, 1), 20),
      _registro(2, DateTime(2026, 9, 3), 22.5),
      _registro(3, DateTime(2026, 9, 5), 25),
    ]);

    expect(find.text('Peso realizado (kg)'), findsOneWidget);
    expect(find.text('20 kg'), findsOneWidget);
    expect(find.text('22.5 kg'), findsOneWidget);
    expect(find.text('25 kg'), findsOneWidget);
  });
}
