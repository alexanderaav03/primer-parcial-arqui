/// Configuración de entorno de la app.
///
/// La URL base del gateway se puede sobreescribir sin tocar el código,
/// pasando `--dart-define=GATEWAY_BASE_URL=...` al correr o compilar:
///
///   flutter run -d chrome                                            (usa http://localhost:8000)
///   flutter run -d emulator-5554 --dart-define=GATEWAY_BASE_URL=http://10.0.2.2:8000
///   flutter run -d `device_id` --dart-define=GATEWAY_BASE_URL=http://192.168.1.50:8000
///
/// Referencia rápida de qué host usar según dónde corra la app:
/// - Web / Windows / mismo equipo que el gateway -> http://localhost:8000
/// - Emulador Android                             -> http://10.0.2.2:8000 (alias del host)
/// - Dispositivo físico en la misma red Wi-Fi      -> http://`IP-LAN-de-tu-PC`:8000
class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'GATEWAY_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
}
