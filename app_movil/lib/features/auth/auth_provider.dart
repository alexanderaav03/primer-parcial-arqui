import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/api_client.dart';
import '../models/usuario.dart';

class AuthState {
  final String? token;
  final Usuario? usuario;

  const AuthState({this.token, this.usuario});

  bool get isAuthenticated => token != null && usuario != null;
}

class _StorageKeys {
  static const token = 'auth_token';
  static const usuarioId = 'auth_usuario_id';
  static const usuarioNombre = 'auth_usuario_nombre';
  static const usuarioRol = 'auth_usuario_rol';
  static const usuarioEmail = 'auth_usuario_email';
}

class AuthNotifier extends Notifier<AuthState> {
  final _storage = const FlutterSecureStorage();

  @override
  AuthState build() => const AuthState();

  /// Se llama una vez al arrancar la app (antes de runApp) para recuperar
  /// una sesión ya guardada y evitar pedir login de nuevo en cada apertura.
  Future<void> restoreSession() async {
    final token = await _storage.read(key: _StorageKeys.token);
    final id = await _storage.read(key: _StorageKeys.usuarioId);
    final nombre = await _storage.read(key: _StorageKeys.usuarioNombre);
    final rol = await _storage.read(key: _StorageKeys.usuarioRol);
    final email = await _storage.read(key: _StorageKeys.usuarioEmail);

    if (token != null && id != null && nombre != null && rol != null) {
      state = AuthState(
        token: token,
        usuario: Usuario(id: int.parse(id), nombre: nombre, rol: rol, email: email),
      );
    }
  }

  Future<void> login(String email, String password) async {
    final dio = ref.read(apiClientProvider);
    final response = await dio.post(
      '/api/auth/login',
      data: {'email': email, 'password': password},
    );

    final data = response.data as Map<String, dynamic>;
    final token = data['access_token'] as String;
    final usuario = Usuario.fromJson(data['usuario'] as Map<String, dynamic>);

    await _storage.write(key: _StorageKeys.token, value: token);
    await _storage.write(key: _StorageKeys.usuarioId, value: usuario.id.toString());
    await _storage.write(key: _StorageKeys.usuarioNombre, value: usuario.nombre);
    await _storage.write(key: _StorageKeys.usuarioRol, value: usuario.rol);
    if (usuario.email != null) {
      await _storage.write(key: _StorageKeys.usuarioEmail, value: usuario.email);
    }

    state = AuthState(token: token, usuario: usuario);
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    state = const AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
