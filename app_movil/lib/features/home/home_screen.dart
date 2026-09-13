import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/date_format.dart';
import '../../core/widgets.dart';
import '../auth/auth_provider.dart';
import '../clientes/cliente_card.dart';
import '../clientes/clientes_provider.dart';
import '../ejercicios/ejercicios_provider.dart';
import '../rutinas/rutina_card.dart';
import '../rutinas/rutinas_provider.dart';
import '../shell/main_app_bar.dart';

/// Dashboard: primera tab, tanto para instructor como para cliente.
/// Solo lee de los providers que ya existen (clientes, ejercicios, rutinas) -
/// no agrega llamadas nuevas al gateway.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authProvider).usuario;

    if (usuario == null) {
      // No debería ocurrir (vive dentro del shell autenticado), pero evita
      // un crash si se reconstruye justo durante el logout.
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      appBar: const MainAppBar(title: 'Inicio'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Hola, ${usuario.nombre}', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(formatFechaHoy(), style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          if (usuario.esInstructor) const _ResumenInstructor() else _ResumenCliente(clienteId: usuario.id),
        ],
      ),
    );
  }
}

class _ResumenInstructor extends ConsumerWidget {
  const _ResumenInstructor();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientesAsync = ref.watch(clientesProvider);
    final ejerciciosAsync = ref.watch(ejerciciosBancoProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.people,
                label: 'Clientes',
                count: clientesAsync.whenOrNull(data: (c) => c.length),
                onTap: () => context.go('/clientes'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.fitness_center,
                label: 'Ejercicios en tu banco',
                count: ejerciciosAsync.whenOrNull(data: (e) => e.length),
                onTap: () => context.go('/ejercicios'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SeccionHeader(titulo: 'Clientes recientes', onVerTodos: () => context.go('/clientes')),
        const SizedBox(height: 8),
        clientesAsync.when(
          loading: () => const LoadingView(message: 'Cargando clientes...'),
          error: (error, _) => AsyncErrorView(
            message: friendlyMessage(error),
            onRetry: () => ref.invalidate(clientesProvider),
          ),
          data: (clientes) {
            if (clientes.isEmpty) {
              return const EmptyView(
                message: 'Todavía no tienes clientes registrados.',
                icon: Icons.people_outline,
              );
            }
            return Column(
              children: [
                for (final cliente in clientes.take(3)) ...[
                  ClienteCard(
                    cliente: cliente,
                    onTap: () => context.push('/clientes/${cliente.id}/rutinas', extra: cliente.nombre),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ResumenCliente extends ConsumerWidget {
  final int clienteId;

  const _ResumenCliente({required this.clienteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rutinasAsync = ref.watch(rutinasProvider(clienteId));

    return rutinasAsync.when(
      loading: () => const LoadingView(message: 'Cargando tus rutinas...'),
      error: (error, _) => AsyncErrorView(
        message: friendlyMessage(error),
        onRetry: () => ref.invalidate(rutinasProvider(clienteId)),
      ),
      data: (rutinas) {
        final activas = rutinas.where((r) => esRutinaActiva(r.fechaFin)).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(child: _Stat(valor: '${rutinas.length}', etiqueta: 'Rutinas totales')),
                    Container(
                      width: 1,
                      height: 40,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                    Expanded(child: _Stat(valor: '$activas', etiqueta: 'Activas')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _SeccionHeader(titulo: 'Tus rutinas recientes', onVerTodos: () => context.go('/rutinas/mias')),
            const SizedBox(height: 8),
            if (rutinas.isEmpty)
              const EmptyView(
                message: 'Todavía no tienes rutinas asignadas.',
                icon: Icons.event_note_outlined,
              )
            else
              Column(
                children: [
                  for (final rutina in rutinas.take(3)) ...[
                    RutinaCard(rutina: rutina, onTap: () => context.push('/rutinas/${rutina.id}/detalle')),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
          ],
        );
      },
    );
  }
}

class _SeccionHeader extends StatelessWidget {
  final String titulo;
  final VoidCallback onVerTodos;

  const _SeccionHeader({required this.titulo, required this.onVerTodos});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.titleMedium),
        TextButton(onPressed: onVerTodos, child: const Text('Ver todos')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? count;
  final VoidCallback onTap;

  const _StatCard({required this.icon, required this.label, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colorScheme.primary, size: 28),
              const SizedBox(height: 12),
              Text(count?.toString() ?? '…', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String valor;
  final String etiqueta;

  const _Stat({required this.valor, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(valor, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(etiqueta, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
