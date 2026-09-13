import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/widgets.dart';
import '../models/ejercicio_banco.dart';
import '../shell/main_app_bar.dart';
import 'ejercicios_provider.dart';

/// Banco de ejercicios propio del instructor. Hoy es de solo lectura;
/// queda como base para agregar crear/editar más adelante.
class EjerciciosScreen extends ConsumerStatefulWidget {
  const EjerciciosScreen({super.key});

  @override
  ConsumerState<EjerciciosScreen> createState() => _EjerciciosScreenState();
}

class _EjerciciosScreenState extends ConsumerState<EjerciciosScreen> {
  final _busquedaCtrl = TextEditingController();
  String _busqueda = '';

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ejerciciosAsync = ref.watch(ejerciciosBancoProvider);

    return Scaffold(
      appBar: const MainAppBar(title: 'Mis ejercicios'),
      body: Column(
        children: [
          SearchField(
            controller: _busquedaCtrl,
            hintText: 'Buscar ejercicio...',
            onChanged: (value) => setState(() => _busqueda = value),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(ejerciciosBancoProvider.future),
              child: ejerciciosAsync.when(
                loading: () => const LoadingView(message: 'Cargando ejercicios...'),
                error: (error, _) => AsyncErrorView(
                  message: friendlyMessage(error),
                  onRetry: () => ref.invalidate(ejerciciosBancoProvider),
                ),
                data: (ejercicios) {
                  if (ejercicios.isEmpty) {
                    return const EmptyView(
                      message: 'Todavía no tienes ejercicios en tu banco.',
                      icon: Icons.fitness_center_outlined,
                    );
                  }

                  final filtro = _busqueda.trim().toLowerCase();
                  final filtrados = filtro.isEmpty
                      ? ejercicios
                      : ejercicios.where((e) => e.nombre.toLowerCase().contains(filtro)).toList();

                  if (filtrados.isEmpty) {
                    return const EmptyView(
                      message: 'No se encontraron resultados',
                      icon: Icons.search_off,
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    itemCount: filtrados.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final ejercicio = filtrados[index];
                      return _EjercicioBancoCard(
                        ejercicio: ejercicio,
                        onTap: () => context.push('/ejercicios/${ejercicio.id}'),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EjercicioBancoCard extends StatelessWidget {
  final EjercicioBanco ejercicio;
  final VoidCallback onTap;

  const _EjercicioBancoCard({required this.ejercicio, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ejercicio.imagenUrl != null
                    ? Image.network(
                        ejercicio.imagenUrl!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _placeholder(colorScheme),
                      )
                    : _placeholder(colorScheme),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ejercicio.nombre, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      ejercicio.descripcion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    InfoBadge(
                      icon: ejercicio.tieneEjemploCompleto ? Icons.check_circle_outline : Icons.info_outline,
                      label: ejercicio.tieneEjemploCompleto ? 'Con ejemplo' : 'Sin ejemplo',
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme colorScheme) {
    return Container(
      width: 64,
      height: 64,
      color: colorScheme.primary.withValues(alpha: 0.1),
      child: Icon(Icons.fitness_center, color: colorScheme.primary),
    );
  }
}
