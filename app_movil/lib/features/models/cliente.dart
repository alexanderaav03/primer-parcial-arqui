class Cliente {
  final int id;
  final String nombre;
  final String objetivo;
  final double? peso;
  final double? altura;

  const Cliente({
    required this.id,
    required this.nombre,
    required this.objetivo,
    this.peso,
    this.altura,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) => Cliente(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        objetivo: json['objetivo'] as String,
        peso: (json['peso'] as num?)?.toDouble(),
        altura: (json['altura'] as num?)?.toDouble(),
      );
}
