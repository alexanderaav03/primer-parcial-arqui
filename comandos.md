# Terminal 1
cd C:\xampp\htdocs\gym
docker-compose up

# Terminal 2
cd C:\xampp\htdocs\gym\app_movil
flutter run -d R9JN7145S9J --dart-define=GATEWAY_BASE_URL=http://192.168.0.11:8000

# Terminal 3
adb connect 192.168.0.10:42203
cd C:\xampp\htdocs\gym\app_movil
flutter run -d 192.168.0.10:42203 --dart-define=GATEWAY_BASE_URL=http://192.168.0.11:8000

# Terminal 4
adb pair 192.168.0.13:42627 519382
adb connect 192.168.0.13:39151
flutter run -d 192.168.0.13:42627 --dart-define=GATEWAY_BASE_URL=http://192.168.0.11:8000

RECONECTAR WIFI DEBUGGING (ya emparejado antes, misma red)
============================================================

1. Celular: Ajustes -> Opciones de desarrollador ->
   activar "Depuracion inalambrica" (si estaba apagada)

2. Entrar a "Depuracion inalambrica" -> ver la IP:PUERTO que muestra
   en la pantalla principal (NO la de emparejar)

3. PowerShell:
   adb connect <IP>:<PUERTO>

4. flutter devices
   -> copiar el id que aparece (IP:puerto)

5. flutter run -d "<ese_id>" --dart-define=GATEWAY_BASE_URL=http://192.168.0.11:8000

Si "adb connect" falla o dice error de auth -> hay que re-emparejar
(volver a "Vincular con codigo de emparejamiento" + adb pair).