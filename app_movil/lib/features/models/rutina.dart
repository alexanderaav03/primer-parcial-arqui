class Rutina {
  final int id;
  final int clienteId;
  final String nombre;
  final String fechaInicio;
  final String fechaFin;

  const Rutina({
    required this.id,
    required this.clienteId,
    required this.nombre,
    required this.fechaInicio,
    required this.fechaFin,
  });

  factory Rutina.fromJson(Map<String, dynamic> json) => Rutina(
        id: json['id'] as int,
        clienteId: json['cliente_id'] as int,
        nombre: json['nombre'] as String,
        fechaInicio: json['fecha_inicio'] as String,
        fechaFin: json['fecha_fin'] as String,
      );
}
