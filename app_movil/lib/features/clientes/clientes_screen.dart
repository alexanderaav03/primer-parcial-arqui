import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/widgets.dart';
import '../auth/auth_provider.dart';
import '../models/cliente.dart';
import '../shell/main_app_bar.dart';
import 'cliente_card.dart';
import 'clientes_provider.dart';

/// Tab del instructor: lista de sus clientes. Tap en uno -> sus rutinas.
class ClientesScreen extends ConsumerStatefulWidget {
  const ClientesScreen({super.key});

  @override
  ConsumerState<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends ConsumerState<ClientesScreen> {
  final _busquedaCtrl = TextEditingController();
  String _busqueda = '';

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmarYEliminar(Cliente cliente) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: Text('¿Eliminar a ${cliente.nombre}? Esta acción no se puede deshacer'),
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
      await eliminarCliente(ref, clienteId: cliente.id);
      ref.invalidate(clientesProvider);
    } on DioException catch (e) {
      // Si el backend responde 409, friendlyMessage ya devuelve el detail
      // del servidor tal cual (explica por qué no se pudo eliminar).
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyMessage(e))));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ocurrió un error inesperado')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientesAsync = ref.watch(clientesProvider);
    final esInstructor = ref.watch(authProvider).usuario?.esInstructor ?? false;

    return Scaffold(
      appBar: const MainAppBar(title: 'Mis clientes'),
      floatingActionButton: esInstructor
          ? FloatingActionButton(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              tooltip: 'Nuevo cliente',
              onPressed: () => context.push('/clientes/nuevo'),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          SearchField(
            controller: _busquedaCtrl,
            hintText: 'Buscar cliente...',
            onChanged: (value) => setState(() => _busqueda = value),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(clientesProvider.future),
              child: clientesAsync.when(
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

                  final filtro = _busqueda.trim().toLowerCase();
                  final filtrados = filtro.isEmpty
                      ? clientes
                      : clientes.where((c) => c.nombre.toLowerCase().contains(filtro)).toList();

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
                      final cliente = filtrados[index];
                      return ClienteCard(
                        cliente: cliente,
                        onTap: () => context.push(
                          '/clientes/${cliente.id}/rutinas',
                          extra: cliente.nombre,
                        ),
                        onEdit: () => context.push(
                          '/clientes/${cliente.id}/editar',
                          extra: cliente,
                        ),
                        onDelete: () => _confirmarYEliminar(cliente),
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
