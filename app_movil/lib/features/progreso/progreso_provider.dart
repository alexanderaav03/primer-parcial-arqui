import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../models/registro_progreso.dart';

typedef DetalleRef = ({int rutinaId, int detalleId});

/// GET /rutinas/{rutina_id}/detalles/{detalle_id}/registros. Instructor
/// dueño o cliente dueño. Viene ordenado por fecha descendente (más
/// reciente primero) -tal cual lo devuelve el backend-.
final registrosProgresoProvider = FutureProvider.autoDispose.family<List<RegistroProgreso>, DetalleRef>(
  (ref, params) async {
    final dio = ref.watch(apiClientProvider);
    final response = await dio.get('/api/rutinas/${params.rutinaId}/detalles/${params.detalleId}/registros');
    final data = response.data as List<dynamic>;
    return data.map((e) => RegistroProgreso.fromJson(e as Map<String, dynamic>)).toList();
  },
);

/// POST /rutinas/{rutina_id}/detalles/{detalle_id}/registros (solo cliente
/// dueño). El caller debe invalidar [registrosProgresoProvider] con el mismo
/// [DetalleRef] para que el badge de conteo y el historial se refresquen.
Future<RegistroProgreso> crearRegistro(
  WidgetRef ref, {
  required int rutinaId,
  required int detalleId,
  required int seriesRealizadas,
  required int repeticionesRealizadas,
  required num pesoRealizado,
  String? nota,
}) async {
  final dio = ref.read(apiClientProvider);
  final response = await dio.post(
    '/api/rutinas/$rutinaId/detalles/$detalleId/registros',
    data: {
      'series_realizadas': seriesRealizadas,
      'repeticiones_realizadas': repeticionesRealizadas,
      'peso_realizado': pesoRealizado,
      'nota': nota,
    },
  );
  return RegistroProgreso.fromJson(response.data as Map<String, dynamic>);
}
