import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/widgets.dart';
import '../models/registro_progreso.dart';
import 'progreso_provider.dart';

/// Historial de sesiones que el cliente registró para un ejercicio puntual
/// de su rutina -gráfico de peso realizado + lista, ambos en orden
/// cronológico-. La usan tanto el instructor (para ver si el cliente
/// cumple y si el peso sube) como el propio cliente ("Ver mi progreso") -el
/// backend ya decide con su token quién puede ver qué-.
class HistorialProgresoScreen extends ConsumerWidget {
  final int rutinaId;
  final int detalleId;
  final String ejercicioNombre;

  const HistorialProgresoScreen({
    super.key,
    required this.rutinaId,
    required this.detalleId,
    required this.ejercicioNombre,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalleRef = (rutinaId: rutinaId, detalleId: detalleId);
    final registrosAsync = ref.watch(registrosProgresoProvider(detalleRef));

    return Scaffold(
      appBar: AppBar(title: Text('Progreso: $ejercicioNombre')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(registrosProgresoProvider(detalleRef).future),
        child: registrosAsync.when(
          loading: () => const LoadingView(message: 'Cargando historial...'),
          error: (error, _) => AsyncErrorView(
            message: friendlyMessage(error),
            onRetry: () => ref.invalidate(registrosProgresoProvider(detalleRef)),
          ),
          data: (registros) {
            if (registros.isEmpty) {
              return const EmptyView(
                message: 'Este cliente todavía no registró ninguna sesión de este ejercicio.',
                icon: Icons.history,
              );
            }

            // El backend devuelve más reciente primero; para leer la
            // progresión (¿el peso va subiendo?) de arriba hacia abajo -y
            // en el gráfico, de izquierda a derecha- acá se muestra en
            // orden cronológico.
            final cronologico = registros.reversed.toList();

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: cronologico.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) return _GraficoProgreso(registros: cronologico);
                return _RegistroCard(registro: cronologico[index - 1]);
              },
            );
          },
        ),
      ),
    );
  }
}

/// Peso realizado (eje Y) contra fecha (eje X). Con un solo registro se ve
/// el punto solo, sin línea -fl_chart no dibuja segmentos con un solo spot,
/// así que no hace falta un caso especial para eso-.
class _GraficoProgreso extends StatelessWidget {
  final List<RegistroProgreso> registros;

  const _GraficoProgreso({required this.registros});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final spots = [
      for (var i = 0; i < registros.length; i++) FlSpot(i.toDouble(), registros[i].pesoRealizado.toDouble()),
    ];

    final pesos = registros.map((r) => r.pesoRealizado.toDouble()).toList();
    final pesoMin = pesos.reduce((a, b) => a < b ? a : b);
    final pesoMax = pesos.reduce((a, b) => a > b ? a : b);
    final rango = pesoMax - pesoMin;
    // Si todos los registros tienen el mismo peso (o hay uno solo), el
    // rango da 0: se agrega un margen fijo para que el eje Y no colapse.
    final margen = rango > 0 ? rango * 0.2 : (pesoMax > 0 ? pesoMax * 0.2 : 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text('Peso realizado (kg)', style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (registros.length - 1).clamp(1, double.infinity).toDouble(),
                  minY: (pesoMin - margen).clamp(0, double.infinity),
                  maxY: pesoMax + margen,
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.round();
                          if (index < 0 || index >= registros.length) return const SizedBox.shrink();
                          final fecha = registros[index].fecha;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${fecha.day}/${fecha.month}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      color: colorScheme.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: colorScheme.primary.withValues(alpha: 0.1)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegistroCard extends StatelessWidget {
  final RegistroProgreso registro;

  const _RegistroCard({required this.registro});

  String _formatFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year} $hora:$minuto';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event_available, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Text(_formatFecha(registro.fecha), style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                InfoBadge(label: '${registro.seriesRealizadas} series'),
                InfoBadge(label: '${registro.repeticionesRealizadas} reps'),
                InfoBadge(label: '${registro.pesoRealizado} kg'),
              ],
            ),
            if (registro.nota != null && registro.nota!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              IconTextRow(icon: Icons.sticky_note_2_outlined, label: registro.nota!),
            ],
          ],
        ),
      ),
    );
  }
}
