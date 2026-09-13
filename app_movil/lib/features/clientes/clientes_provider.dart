import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../models/cliente.dart';

final clientesProvider = FutureProvider.autoDispose<List<Cliente>>((ref) async {
  final dio = ref.watch(apiClientProvider);
  final response = await dio.get('/api/clientes');
  final data = response.data as List<dynamic>;
  return data.map((e) => Cliente.fromJson(e as Map<String, dynamic>)).toList();
});

/// POST /api/clientes (solo instructor). No es un provider en sí -clientes_provider
/// solo expone la lista vía FutureProvider- sino una función que reusa el mismo
/// apiClientProvider; el caller es responsable de invalidar [clientesProvider]
/// después de un alta exitosa para que la lista se refresque.
Future<Cliente> crearCliente(
  WidgetRef ref, {
  required String nombre,
  required String objetivo,
  required String email,
  required String password,
}) async {
  final dio = ref.read(apiClientProvider);
  final response = await dio.post(
    '/api/clientes',
    data: {
      'nombre': nombre,
      'objetivo': objetivo,
      'email': email,
      'password': password,
    },
  );
  return Cliente.fromJson(response.data as Map<String, dynamic>);
}

/// PUT /api/clientes/{id} (solo instructor, y solo si el cliente le
/// pertenece). Igual que [crearCliente], el caller debe invalidar
/// [clientesProvider] después de editar para que la lista se refresque.
Future<Cliente> editarCliente(
  WidgetRef ref, {
  required int clienteId,
  required String nombre,
  required String objetivo,
}) async {
  final dio = ref.read(apiClientProvider);
  final response = await dio.put(
    '/api/clientes/$clienteId',
    data: {
      'nombre': nombre,
      'objetivo': objetivo,
    },
  );
  return Cliente.fromJson(response.data as Map<String, dynamic>);
}
