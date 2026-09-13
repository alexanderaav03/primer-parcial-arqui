class Usuario {
  final int id;
  final String nombre;
  final String rol; // "instructor" | "cliente"

  /// TODO: POST /api/auth/login hoy NO devuelve email (auth_service.login()
  /// en ms-ejercicios arma UsuarioResponse solo con id/nombre/rol, aunque el
  /// schema sí lo permite). Este campo queda listo para cuando se agregue -
  /// mientras tanto siempre llega null.
  final String? email;

  const Usuario({required this.id, required this.nombre, required this.rol, this.email});

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        rol: json['rol'] as String,
        email: json['email'] as String?,
      );

  bool get esInstructor => rol == 'instructor';
}
