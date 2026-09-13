import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/widgets.dart';
import '../auth/auth_provider.dart';
import '../models/ejercicio_banco.dart';
import 'ejercicio_detalle_provider.dart';
import 'ejercicios_provider.dart';

class EjercicioDetalleScreen extends ConsumerWidget {
  final int ejercicioId;

  const EjercicioDetalleScreen({super.key, required this.ejercicioId});

  Future<void> _abrirVideo(BuildContext context, String videoUrl) async {
    final uri = Uri.tryParse(videoUrl);
    if (uri == null) return;

    final abierto = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!abierto && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el video')),
      );
    }
  }

  Future<void> _confirmarYEliminar(BuildContext context, WidgetRef ref) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar ejercicio'),
        content: const Text(
          '¿Eliminar este ejercicio del banco? Esta acción no se puede deshacer',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Eliminar', style: TextStyle(color: Theme.of(dialogContext).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await eliminarEjercicio(ref, ejercicioId: ejercicioId);
      ref.invalidate(ejerciciosBancoProvider);
      if (context.mounted) context.pop();
    } on DioException catch (e) {
      // Si el backend responde 409, friendlyMessage ya devuelve el detail
      // del servidor tal cual (explica por qué no se pudo eliminar).
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
    final ejercicioAsync = ref.watch(ejercicioDetalleProvider(ejercicioId));
    final esInstructor = ref.watch(authProvider).usuario?.esInstructor ?? false;
    final ejercicioCargado = ejercicioAsync.whenOrNull(data: (e) => e);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de ejercicio'),
        actions: [
          if (esInstructor && ejercicioCargado != null) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar ejercicio',
              onPressed: () => context.push('/ejercicios/$ejercicioId/editar', extra: ejercicioCargado),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar ejercicio',
              onPressed: () => _confirmarYEliminar(context, ref),
            ),
          ],
        ],
      ),
      body: ejercicioAsync.when(
        loading: () => const LoadingView(message: 'Cargando ejercicio...'),
        error: (error, _) => AsyncErrorView(
          message: friendlyMessage(error),
          onRetry: () => ref.invalidate(ejercicioDetalleProvider(ejercicioId)),
        ),
        data: (ejercicio) {
          // Si tiene_ejemplo_completo es false, mostramos el placeholder
          // aunque imagen_url viniera con algo -por diseño esos ejercicios
          // todavía no tienen media real que mostrar.
          final imagenUrl = ejercicio.tieneEjemploCompleto ? ejercicio.imagenUrl : null;

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EjercicioImagen(imagenUrl: imagenUrl, height: 220),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ejercicio.nombre, style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 10),
                          if (!ejercicio.tieneEjemploCompleto) ...[
                            const InfoBadge(
                              icon: Icons.info_outline,
                              label: 'Sin ejemplo visual todavía',
                            ),
                            const SizedBox(height: 12),
                          ],
                          Text(ejercicio.descripcion, style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 20),
                          if (ejercicio.tieneValoresSugeridos)
                            _ValoresSugeridos(ejercicio: ejercicio)
                          else
                            Text(
                              'Sin valores de referencia todavía',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                            ),
                          if (ejercicio.videoUrl != null) ...[
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () => _abrirVideo(context, ejercicio.videoUrl!),
                              icon: const Icon(Icons.play_circle_fill),
                              label: const Text('Ver video'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Chips con los valores de referencia del banco -distintos de los que
/// tendría este ejercicio dentro de una rutina puntual, por eso el label
/// "Sugerido" arriba deja claro que es un valor por defecto, no asignado-.
class _ValoresSugeridos extends StatelessWidget {
  final EjercicioBanco ejercicio;

  const _ValoresSugeridos({required this.ejercicio});

  @override
  Widget build(BuildContext context) {
    final descansos = [
      if (ejercicio.descansoSerieSugerido != null)
        IconTextRow(icon: Icons.timer_outlined, label: 'Descanso serie: ${ejercicio.descansoSerieSugerido}'),
      if (ejercicio.descansoEjercicioSugerido != null)
        IconTextRow(icon: Icons.timer, label: 'Descanso ejercicio: ${ejercicio.descansoEjercicioSugerido}'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sugerido', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (ejercicio.seriesSugeridas != null) InfoBadge(label: '${ejercicio.seriesSugeridas} series'),
            if (ejercicio.repeticionesSugeridas != null) InfoBadge(label: '${ejercicio.repeticionesSugeridas} reps'),
            if (ejercicio.pesoSugerido != null) InfoBadge(label: '${ejercicio.pesoSugerido} kg'),
            if (ejercicio.rpeSugerido != null) InfoBadge(label: 'RPE ${ejercicio.rpeSugerido}'),
          ],
        ),
        if (descansos.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 16, runSpacing: 4, children: descansos),
        ],
      ],
    );
  }
}
