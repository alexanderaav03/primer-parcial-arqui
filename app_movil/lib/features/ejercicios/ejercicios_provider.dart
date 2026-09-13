import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../models/ejercicio_banco.dart';

final ejerciciosBancoProvider = FutureProvider.autoDispose<List<EjercicioBanco>>((ref) async {
  final dio = ref.watch(apiClientProvider);
  final response = await dio.get('/api/ejercicios');
  final data = response.data as List<dynamic>;
  return data.map((e) => EjercicioBanco.fromJson(e as Map<String, dynamic>)).toList();
});

/// POST /api/ejercicios (solo instructor). El caller debe invalidar
/// [ejerciciosBancoProvider] después de crear para que la lista se refresque.
Future<EjercicioBanco> crearEjercicio(
  WidgetRef ref, {
  required String nombre,
  required String descripcion,
  String? imagenUrl,
  String? videoUrl,
  int? repeticionesSugeridas,
  int? seriesSugeridas,
  num? pesoSugerido,
  String? descansoSerieSugerido,
  String? descansoEjercicioSugerido,
  int? rpeSugerido,
}) async {
  final dio = ref.read(apiClientProvider);
  final response = await dio.post(
    '/api/ejercicios',
    data: {
      'nombre': nombre,
      'descripcion': descripcion,
      'imagen_url': imagenUrl,
      'video_url': videoUrl,
      'repeticiones_sugeridas': repeticionesSugeridas,
      'series_sugeridas': seriesSugeridas,
      'peso_sugerido': pesoSugerido,
      'descanso_serie_sugerido': descansoSerieSugerido,
      'descanso_ejercicio_sugerido': descansoEjercicioSugerido,
      'rpe_sugerido': rpeSugerido,
    },
  );
  return EjercicioBanco.fromJson(response.data as Map<String, dynamic>);
}
