import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth_provider.dart';
import 'config.dart';
import 'snackbar.dart';

/// Error "traducido" a un mensaje entendible para el usuario.
/// Se guarda dentro de [DioException.error] para que las pantallas puedan
/// mostrarlo directamente sin volver a interpretar códigos HTTP.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Devuelve un mensaje amigable a partir de cualquier error capturado en un
/// `AsyncValue.error` o en un `catch`.
String friendlyMessage(Object error) {
  if (error is DioException && error.error is ApiException) {
    return (error.error as ApiException).message;
  }
  return 'Ocurrió un error inesperado';
}

final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = ref.read(authProvider).token;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        final statusCode = error.response?.statusCode;
        final huboToken = error.requestOptions.headers.containsKey('Authorization');
        String message;
        var mostrarSnackbarGlobal = true;

        if (statusCode == 401 && huboToken) {
          // Sesión que ya estaba autenticada expiró o el token es inválido:
          // limpiamos la sesión guardada y el router redirige solo a /login.
          message = 'Sesión expirada, inicia sesión de nuevo';
          ref.read(authProvider.notifier).logout();
        } else if (statusCode == 401) {
          // 401 sin token previo = intento de login con credenciales malas.
          // La pantalla de login ya muestra el error inline, evitamos duplicar.
          message = 'Email o contraseña incorrectos';
          mostrarSnackbarGlobal = false;
        } else if (statusCode == 503) {
          final data = error.response?.data;
          message = (data is Map && data['error'] != null)
              ? data['error'].toString()
              : 'Servicio no disponible, intenta de nuevo';
        } else if (statusCode != null) {
          final data = error.response?.data;
          message = (data is Map && data['detail'] != null)
              ? data['detail'].toString()
              : 'Error del servidor ($statusCode)';
        } else {
          message = 'No se pudo conectar con el servidor';
        }

        if (mostrarSnackbarGlobal) {
          showGlobalMessage(message);
        }

        handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: ApiException(message, statusCode: statusCode),
          ),
        );
      },
    ),
  );

  return dio;
});
