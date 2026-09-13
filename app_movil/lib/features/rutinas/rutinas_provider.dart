import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../models/ejercicio_detalle.dart';
import '../models/rutina.dart';

final rutinasProvider = FutureProvider.autoDispose.family<List<Rutina>, int>((ref, clienteId) async {
  final dio = ref.watch(apiClientProvider);
  final response = await dio.get(
    '/api/rutinas',
    queryParameters: {'cliente_id': clienteId},
  );
  final data = response.data as List<dynamic>;
  return data.map((e) => Rutina.fromJson(e as Map<String, dynamic>)).toList();
});

final rutinaDetalleProvider = FutureProvider.autoDispose.family<RutinaDetalle, int>((ref, rutinaId) async {
  final dio = ref.watch(apiClientProvider);
  final response = await dio.get('/api/rutinas/$rutinaId/detalle');
  return RutinaDetalle.fromJson(response.data as Map<String, dynamic>);
});

/// POST /api/rutinas (solo instructor). El caller debe invalidar
/// [rutinasProvider] del cliente correspondiente después de crear para que
/// la lista se refresque.
Future<Rutina> crearRutina(
  WidgetRef ref, {
  required int clienteId,
  required String nombre,
  required String fechaInicio,
  required String fechaFin,
}) async {
  final dio = ref.read(apiClientProvider);
  final response = await dio.post(
    '/api/rutinas',
    data: {
      'cliente_id': clienteId,
      'nombre': nombre,
      'fecha_inicio': fechaInicio,
      'fecha_fin': fechaFin,
    },
  );
  return Rutina.fromJson(response.data as Map<String, dynamic>);
}

/// POST /api/rutinas/{id}/detalles (solo instructor). Devuelve el
/// detalle_id creado -el caller ya tiene el resto de los datos, los mismos
/// que acaba de enviar, para actualizar su lista local en pantalla-.
Future<int> agregarDetalle(
  WidgetRef ref, {
  required int rutinaId,
  required int ejercicioId,
  required int repeticiones,
  required int series,
  required int sesionesPorSemana,
  required num peso,
  required String descansoSerie,
  required String descansoEjercicio,
  required int rpe,
}) async {
  final dio = ref.read(apiClientProvider);
  final response = await dio.post(
    '/api/rutinas/$rutinaId/detalles',
    data: {
      'ejercicio_id': ejercicioId,
      'repeticiones': repeticiones,
      'series': series,
      'sesiones_por_semana': sesionesPorSemana,
      'peso': peso,
      'descanso_serie': descansoSerie,
      'descanso_ejercicio': descansoEjercicio,
      'rpe': rpe,
    },
  );
  final data = response.data as Map<String, dynamic>;
  return data['detalle_id'] as int;
}

/// PUT /api/rutinas/{rutina_id}/detalles/{detalle_id} (solo instructor
/// dueño). El backend acepta edición parcial, pero acá se manda el
/// formulario completo porque la pantalla de edición ya precarga todos los
/// valores actuales y permite tocar cualquiera. El caller debe invalidar
/// [rutinaDetalleProvider] para que la lista muestre los valores nuevos.
Future<void> editarDetalle(
  WidgetRef ref, {
  required int rutinaId,
  required int detalleId,
  required int repeticiones,
  required int series,
  required int sesionesPorSemana,
  required num peso,
  required String descansoSerie,
  required String descansoEjercicio,
  required int rpe,
}) async {
  final dio = ref.read(apiClientProvider);
  await dio.put(
    '/api/rutinas/$rutinaId/detalles/$detalleId',
    data: {
      'repeticiones': repeticiones,
      'series': series,
      'sesiones_por_semana': sesionesPorSemana,
      'peso': peso,
      'descanso_serie': descansoSerie,
      'descanso_ejercicio': descansoEjercicio,
      'rpe': rpe,
    },
  );
}

/// PUT /api/rutinas/{id} (solo instructor dueño del cliente). El backend
/// aplica la misma validación de solapamiento de fechas que la creación
/// -excluyendo esta propia rutina-. El caller debe invalidar
/// [rutinaDetalleProvider] (y [rutinasProvider] del cliente) para refrescar.
Future<Rutina> editarRutina(
  WidgetRef ref, {
  required int rutinaId,
  required String nombre,
  required String fechaInicio,
  required String fechaFin,
}) async {
  final dio = ref.read(apiClientProvider);
  final response = await dio.put(
    '/api/rutinas/$rutinaId',
    data: {
      'nombre': nombre,
      'fecha_inicio': fechaInicio,
      'fecha_fin': fechaFin,
    },
  );
  return Rutina.fromJson(response.data as Map<String, dynamic>);
}

/// DELETE /api/rutinas/{rutina_id}/detalles/{detalle_id} (solo instructor
/// dueño). El caller debe invalidar [rutinaDetalleProvider] para que
/// desaparezca de la lista.
Future<void> eliminarDetalle(
  WidgetRef ref, {
  required int rutinaId,
  required int detalleId,
}) async {
  final dio = ref.read(apiClientProvider);
  await dio.delete('/api/rutinas/$rutinaId/detalles/$detalleId');
}

/// DELETE /api/rutinas/{id} (solo instructor dueño del cliente). El backend
/// responde 409 si la rutina ya tiene progreso registrado -ese mensaje ya
/// viene listo para mostrar tal cual, vía friendlyMessage-; si no, borra la
/// rutina y sus detalles en cascada. El caller debe invalidar
/// [rutinasProvider] del cliente correspondiente tras un borrado exitoso.
Future<void> eliminarRutina(WidgetRef ref, {required int rutinaId}) async {
  final dio = ref.read(apiClientProvider);
  await dio.delete('/api/rutinas/$rutinaId');
}
