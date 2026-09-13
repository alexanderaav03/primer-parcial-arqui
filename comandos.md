# Requisitos previos (una sola vez)
- Tener Docker Desktop instalado y corriendo
- Tener Flutter instalado
- Clonar el repo: git clone https://github.com/alexanderaav03/primer-parcial-arqui.git
- Tener el celular conectado por USB con depuración USB activada (o por wifi con adb connect)

# Terminal 1 — levantar backend
cd gym
docker-compose up

# Terminal 2 — poblar la base de datos (SOLO la primera vez)
pip install sqlalchemy psycopg2-binary python-dotenv passlib
python seed/seed_instructor_clientes.py --docker
python seed/seed_ejercicios.py --docker
python seed/seed_rutinas.py --docker

# Terminal 3 — correr la app móvil
cd app_movil
flutter devices
# copiar el ID que aparece para SU celular 
flutter run -d 15187705CJ007699  --dart-define=GATEWAY_BASE_URL=http://<IP-DE-SU-PC>:8000