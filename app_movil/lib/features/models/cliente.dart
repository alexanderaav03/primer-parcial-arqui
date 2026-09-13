class Cliente {
  final int id;
  final String nombre;
  final String objetivo;

  const Cliente({required this.id, required this.nombre, required this.objetivo});

  factory Cliente.fromJson(Map<String, dynamic> json) => Cliente(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        objetivo: json['objetivo'] as String,
      );
}
