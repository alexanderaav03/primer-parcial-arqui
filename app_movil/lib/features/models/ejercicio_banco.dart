/// Un ejercicio del banco propio del instructor (GET /api/ejercicios,
/// GET /api/ejercicios/{id}). No confundir con [EjercicioDetalle], que es
/// el ejercicio ya en el contexto de una rutina (con series/repeticiones/
/// peso/rpe propios de esa rutina, no del banco).
class EjercicioBanco {
  final int id;
  final String nombre;
  final String descripcion;
  final String? imagenUrl;
  final String? videoUrl;
  final bool tieneEjemploCompleto;

  /// Valores de referencia sugeridos del banco -independientes de
  /// cualquier rutina-. Todos nulos si el ejercicio no tiene ejemplo
  /// completo (los 5 sin media del seed).
  final int? repeticionesSugeridas;
  final int? seriesSugeridas;
  final num? pesoSugerido;
  final String? descansoSerieSugerido;
  final String? descansoEjercicioSugerido;
  final int? rpeSugerido;

  const EjercicioBanco({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.imagenUrl,
    required this.videoUrl,
    required this.tieneEjemploCompleto,
    required this.repeticionesSugeridas,
    required this.seriesSugeridas,
    required this.pesoSugerido,
    required this.descansoSerieSugerido,
    required this.descansoEjercicioSugerido,
    required this.rpeSugerido,
  });

  factory EjercicioBanco.fromJson(Map<String, dynamic> json) => EjercicioBanco(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String,
        imagenUrl: json['imagen_url'] as String?,
        videoUrl: json['video_url'] as String?,
        tieneEjemploCompleto: json['tiene_ejemplo_completo'] as bool,
        repeticionesSugeridas: json['repeticiones_sugeridas'] as int?,
        seriesSugeridas: json['series_sugeridas'] as int?,
        pesoSugerido: json['peso_sugerido'] as num?,
        descansoSerieSugerido: json['descanso_serie_sugerido'] as String?,
        descansoEjercicioSugerido: json['descanso_ejercicio_sugerido'] as String?,
        rpeSugerido: json['rpe_sugerido'] as int?,
      );

  /// Hay al menos un valor de referencia cargado -útil para decidir si
  /// mostrar la sección "Valores sugeridos" en el detalle-.
  bool get tieneValoresSugeridos =>
      repeticionesSugeridas != null ||
      seriesSugeridas != null ||
      pesoSugerido != null ||
      descansoSerieSugerido != null ||
      descansoEjercicioSugerido != null ||
      rpeSugerido != null;
}
