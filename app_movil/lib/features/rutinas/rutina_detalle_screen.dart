import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/date_format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../auth/auth_provider.dart';
import '../models/ejercicio_detalle.dart';
import '../progreso/progreso_provider.dart';
import '../progreso/registrar_progreso_sheet.dart';
import 'rutinas_provider.dart';

class RutinaDetalleScreen extends ConsumerWidget {
  final int rutinaId;

  const RutinaDetalleScreen({super.key, required this.rutinaId});

  Future<void> _confirmarYEliminar(BuildContext context, WidgetRef ref, EjercicioDetalle ejercicio) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quitar ejercicio'),
        content: Text('¿Quitar este ejercicio de la rutina?\n\n${ejercicio.nombre}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Quitar', style: TextStyle(color: Theme.of(dialogContext).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await eliminarDetalle(ref, rutinaId: rutinaId, detalleId: ejercicio.detalleId);
      ref.invalidate(rutinaDetalleProvider(rutinaId));
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyMessage(e))));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ocurrió un error inesperado')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalleAsync = ref.watch(rutinaDetalleProvider(rutinaId));
    final esInstructor = ref.watch(authProvider).usuario?.esInstructor ?? false;
    final detalleCargado = detalleAsync.whenOrNull(data: (d) => d);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de rutina'),
        actions: [
          if (esInstructor && detalleCargado != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar rutina',
              onPressed: () => context.push('/rutinas/$rutinaId/editar', extra: detalleCargado),
            ),
        ],
      ),
      floatingActionButton: (esInstructor && detalleCargado != null)
          ? FloatingActionButton(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              tooltip: 'Agregar ejercicio',
              onPressed: () async {
                await context.push(
                  '/rutinas/$rutinaId/agregar-ejercicios?clienteId=${detalleCargado.clienteId}',
                );
                ref.invalidate(rutinaDetalleProvider(rutinaId));
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: detalleAsync.when(
        loading: () => const LoadingView(message: 'Cargando rutina...'),
        error: (error, _) => AsyncErrorView(
          message: friendlyMessage(error),
          onRetry: () => ref.invalidate(rutinaDetalleProvider(rutinaId)),
        ),
        data: (detalle) {
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(detalle.nombre, style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_month, size: 18, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            formatRangoFechas(detalle.fechaInicio, detalle.fechaFin),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (detalle.ejercicios.isEmpty)
                const EmptyView(
                  message: 'Esta rutina todavía no tiene ejercicios.',
                  icon: Icons.fitness_center_outlined,
                )
              else
                ...detalle.ejercicios.map(
                  (ejercicio) => _EjercicioCard(
                    rutinaId: rutinaId,
                    ejercicio: ejercicio,
                    esInstructor: esInstructor,
                    onDelete: esInstructor ? () => _confirmarYEliminar(context, ref, ejercicio) : null,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _EjercicioCard extends ConsumerWidget {
  final int rutinaId;
  final EjercicioDetalle ejercicio;
  final bool esInstructor;
  final VoidCallback? onDelete;

  const _EjercicioCard({
    required this.rutinaId,
    required this.ejercicio,
    required this.esInstructor,
    this.onDelete,
  });

  Future<void> _abrirVideo(BuildContext context) async {
    final uri = Uri.tryParse(ejercicio.videoUrl ?? '');
    if (uri == null) return;

    final abierto = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!abierto && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el video')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalleRef = (rutinaId: rutinaId, detalleId: ejercicio.detalleId);
    final registrosAsync = ref.watch(registrosProgresoProvider(detalleRef));
    final sesionesRegistradas = registrosAsync.whenOrNull(data: (registros) => registros.length) ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EjercicioImagen(imagenUrl: ejercicio.imagenUrl),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        ejercicio.nombre,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (esInstructor)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Editar ejercicio',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => context.push(
                          '/rutinas/$rutinaId/detalles/${ejercicio.detalleId}/editar',
                          extra: ejercicio,
                        ),
                      ),
                    if (onDelete != null)
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                        tooltip: 'Quitar de la rutina',
                        visualDensity: VisualDensity.compact,
                        onPressed: onDelete,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  ejercicio.descripcion,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    InfoBadge(label: '${ejercicio.series} series'),
                    InfoBadge(label: '${ejercicio.repeticiones} reps'),
                    InfoBadge(label: '${ejercicio.sesionesPorSemana}x por semana'),
                    InfoBadge(label: '${ejercicio.peso} kg'),
                    InfoBadge(label: 'RPE ${ejercicio.rpe}'),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    IconTextRow(icon: Icons.timer_outlined, label: 'Descanso serie: ${ejercicio.descansoSerie}'),
                    IconTextRow(icon: Icons.timer, label: 'Descanso ejercicio: ${ejercicio.descansoEjercicio}'),
                  ],
                ),
                if (ejercicio.videoUrl != null) ...[
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => _abrirVideo(context),
                    icon: const Icon(Icons.play_circle_fill),
                    label: const Text('Ver video'),
                  ),
                ],
                if (sesionesRegistradas > 0) ...[
                  const SizedBox(height: 10),
                  InfoBadge(
                    icon: Icons.check_circle,
                    color: AppColors.success,
                    label: sesionesRegistradas == 1
                        ? '1 sesión registrada'
                        : '$sesionesRegistradas sesiones registradas',
                  ),
                ],
                const SizedBox(height: 10),
                if (!esInstructor) ...[
                  FilledButton.icon(
                    onPressed: () => mostrarRegistrarProgresoSheet(context, rutinaId: rutinaId, ejercicio: ejercicio),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Marcar como hecho'),
                  ),
                  if (sesionesRegistradas > 0) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => context.push(
                        '/rutinas/$rutinaId/detalles/${ejercicio.detalleId}/progreso',
                        extra: ejercicio.nombre,
                      ),
                      icon: const Icon(Icons.show_chart),
                      label: const Text('Ver mi progreso'),
                    ),
                  ],
                ] else
                  OutlinedButton.icon(
                    onPressed: () => context.push(
                      '/rutinas/$rutinaId/detalles/${ejercicio.detalleId}/progreso',
                      extra: ejercicio.nombre,
                    ),
                    icon: const Icon(Icons.show_chart),
                    label: const Text('Ver progreso'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
