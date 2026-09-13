import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/widgets.dart';
import '../auth/auth_provider.dart';
import '../shell/main_app_bar.dart';
import 'rutina_card.dart';
import 'rutinas_provider.dart';

/// Lista de rutinas de un cliente.
///
/// Es la misma pantalla para dos casos de uso:
/// - El instructor viendo las rutinas de uno de sus clientes (título = nombre del cliente).
/// - El cliente viendo sus propias rutinas (título = "Mis rutinas").
class RutinasScreen extends ConsumerWidget {
  final int clienteId;
  final String titulo;

  const RutinasScreen({super.key, required this.clienteId, required this.titulo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rutinasAsync = ref.watch(rutinasProvider(clienteId));
    final auth = ref.watch(authProvider);
    final esVistaPropia = auth.usuario != null && !auth.usuario!.esInstructor;

    final esInstructor = auth.usuario?.esInstructor ?? false;

    return Scaffold(
      // "Mis rutinas" (tab del cliente) usa el AppBar principal con
      // campana; la vista del instructor sobre un cliente puntual es un
      // drill-down (llega con push, con botón de volver) y mantiene el
      // AppBar normal, sin campana.
      appBar: esVistaPropia ? MainAppBar(title: titulo) : AppBar(title: Text(titulo)),
      floatingActionButton: esInstructor
          ? FloatingActionButton(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              tooltip: 'Nueva rutina',
              onPressed: () => context.push('/clientes/$clienteId/rutinas/nueva'),
              child: const Icon(Icons.add),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(rutinasProvider(clienteId).future),
        child: rutinasAsync.when(
          loading: () => const LoadingView(message: 'Cargando rutinas...'),
          error: (error, _) => AsyncErrorView(
            message: friendlyMessage(error),
            onRetry: () => ref.invalidate(rutinasProvider(clienteId)),
          ),
          data: (rutinas) {
            if (rutinas.isEmpty) {
              return EmptyView(
                icon: Icons.event_note_outlined,
                message: esVistaPropia
                    ? 'Todavía no tienes rutinas asignadas.'
                    : 'Este cliente todavía no tiene rutinas.',
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: rutinas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final rutina = rutinas[index];
                return RutinaCard(
                  rutina: rutina,
                  onTap: () => context.push('/rutinas/${rutina.id}/detalle'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
