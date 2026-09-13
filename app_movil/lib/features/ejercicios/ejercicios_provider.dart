import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../models/ejercicio_banco.dart';

final ejerciciosBancoProvider = FutureProvider.autoDispose<List<EjercicioBanco>>((ref) async {
  final dio = ref.watch(apiClientProvider);
  final response = await dio.get('/api/ejercicios');
  final data = response.data as List<dynamic>;
  return data.map((e) => EjercicioBanco.fromJson(e as Map<String, dynamic>)).toList();
});
