class EjercicioDetalle {
  final int detalleId;
  final int ejercicioId;
  final String nombre;
  final String descripcion;
  final String? imagenUrl;
  final String? videoUrl;
  final bool tieneEjemploCompleto;
  final int repeticiones;
  final int series;
  final int sesionesPorSemana;
  final num peso;
  final String descansoSerie;
  final String descansoEjercicio;
  final int rpe;

  const EjercicioDetalle({
    required this.detalleId,
    required this.ejercicioId,
    required this.nombre,
    required this.descripcion,
    required this.imagenUrl,
    required this.videoUrl,
    required this.tieneEjemploCompleto,
    required this.repeticiones,
    required this.series,
    required this.sesionesPorSemana,
    required this.peso,
    required this.descansoSerie,
    required this.descansoEjercicio,
    required this.rpe,
  });

  factory EjercicioDetalle.fromJson(Map<String, dynamic> json) => EjercicioDetalle(
        detalleId: json['detalle_id'] as int,
        ejercicioId: json['ejercicio_id'] as int,
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String,
        imagenUrl: json['imagen_url'] as String?,
        videoUrl: json['video_url'] as String?,
        tieneEjemploCompleto: json['tiene_ejemplo_completo'] as bool,
        repeticiones: json['repeticiones'] as int,
        series: json['series'] as int,
        sesionesPorSemana: json['sesiones_por_semana'] as int,
        peso: json['peso'] as num,
        descansoSerie: json['descanso_serie'] as String,
        descansoEjercicio: json['descanso_ejercicio'] as String,
        rpe: json['rpe'] as int,
      );
}

class RutinaDetalle {
  final int id;
  final int clienteId;
  final String nombre;
  final String fechaInicio;
  final String fechaFin;
  final List<EjercicioDetalle> ejercicios;

  const RutinaDetalle({
    required this.id,
    required this.clienteId,
    required this.nombre,
    required this.fechaInicio,
    required this.fechaFin,
    required this.ejercicios,
  });

  factory RutinaDetalle.fromJson(Map<String, dynamic> json) => RutinaDetalle(
        id: json['id'] as int,
        clienteId: json['cliente_id'] as int,
        nombre: json['nombre'] as String,
        fechaInicio: json['fecha_inicio'] as String,
        fechaFin: json['fecha_fin'] as String,
        ejercicios: (json['ejercicios'] as List<dynamic>)
            .map((e) => EjercicioDetalle.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
