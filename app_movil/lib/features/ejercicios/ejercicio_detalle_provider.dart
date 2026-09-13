import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../models/ejercicio_banco.dart';

/// GET /api/ejercicios/{id} devuelve exactamente el mismo shape que la
/// lista GET /api/ejercicios, así que reusamos el modelo EjercicioBanco
/// en vez de crear uno nuevo.
final ejercicioDetalleProvider = FutureProvider.autoDispose.family<EjercicioBanco, int>((ref, ejercicioId) async {
  final dio = ref.watch(apiClientProvider);
  final response = await dio.get('/api/ejercicios/$ejercicioId');
  return EjercicioBanco.fromJson(response.data as Map<String, dynamic>);
});

/// PUT /api/ejercicios/{id} (solo instructor dueño). Es un reemplazo
/// completo -el body debe traer todos los campos, incluidos imagen_url y
/// video_url actuales si no se quieren perder-. El caller debe invalidar
/// [ejercicioDetalleProvider] (y [ejerciciosBancoProvider] si la lista ya
/// está cargada) después de editar.
Future<EjercicioBanco> editarEjercicio(
  WidgetRef ref, {
  required int ejercicioId,
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
  final response = await dio.put(
    '/api/ejercicios/$ejercicioId',
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

/// DELETE /api/ejercicios/{id} (solo instructor dueño). El backend responde
/// 409 si el ejercicio está en uso en algún DetalleRutina existente -ese
/// mensaje ya viene listo para mostrar tal cual, vía friendlyMessage-.
Future<void> eliminarEjercicio(WidgetRef ref, {required int ejercicioId}) async {
  final dio = ref.read(apiClientProvider);
  await dio.delete('/api/ejercicios/$ejercicioId');
}
