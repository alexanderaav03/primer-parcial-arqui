/// Un registro de que el cliente completó una sesión de un ejercicio de su
/// rutina, con los valores reales que hizo (pueden diferir de lo planeado
/// en DetalleRutina). GET /rutinas/{id}/detalles/{id}/registros,
/// POST del mismo path.
class RegistroProgreso {
  final int id;
  final int detalleRutinaId;
  final DateTime fecha;
  final int seriesRealizadas;
  final int repeticionesRealizadas;
  final num pesoRealizado;
  final String? nota;

  const RegistroProgreso({
    required this.id,
    required this.detalleRutinaId,
    required this.fecha,
    required this.seriesRealizadas,
    required this.repeticionesRealizadas,
    required this.pesoRealizado,
    required this.nota,
  });

  factory RegistroProgreso.fromJson(Map<String, dynamic> json) => RegistroProgreso(
        id: json['id'] as int,
        detalleRutinaId: json['detalle_rutina_id'] as int,
        fecha: DateTime.parse(json['fecha'] as String),
        seriesRealizadas: json['series_realizadas'] as int,
        repeticionesRealizadas: json['repeticiones_realizadas'] as int,
        pesoRealizado: json['peso_realizado'] as num,
        nota: json['nota'] as String?,
      );
}
