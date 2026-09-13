DESCRIPCIÓN DETALLADA DEL PROYECTO
BANCO DE EJERCICIOS - ARQUITECTURA DE MICROSERVICIOS
==================================================

1. CONTEXTO Y OBJETIVO
-----------------------
Sistema donde un instructor gestiona un banco de ejercicios y crea rutinas
personalizadas para sus clientes, asignando ejercicios del banco con
parámetros específicos (series, repeticiones, peso, descansos) para cada
rutina. Arquitectura de microservicios obligatoria (Cliente -> Gateway ->
Microservicio -> Datos), siguiendo el mismo patrón de capas visto en el
ejemplo del profesor (caso Pedido/DetallePedido/Producto).

Confirmado por pizarra del profesor (foto): una Rutina (ej. "Rutina 1,
21/08/2026 - 26/08/2026") se conecta a varios ejercicios (X, Y, Z) —
relación N:M vía tabla intermedia, igual que Pedido -> DetallePedido -> Producto.

2. ENTIDADES Y CAMPOS
-----------------------

INSTRUCTOR
- id (PK)
- nombre
- especialidad
- email
- password_hash
- rol                     "instructor"

CLIENTE
- id (PK)
- instructor_id (FK -> Instructor)
- nombre
- objetivo
- email
- password_hash
- rol                     "cliente"

EJERCICIO  (banco de ejercicios, pertenece a un instructor)
- id (PK)
- instructor_id (FK -> Instructor)
- nombre                  ej. "Sentadilla", "Remo de espalda en máquina", "Gemelos en máquina"
- descripcion             texto explicando para qué sirve / qué músculos trabaja
- imagen_url              foto/ilustración del ejercicio (nullable, subida a Supabase Storage)
- video_url               link a video demostrativo (nullable, subido a Supabase Storage)
- tiene_ejemplo_completo  boolean -> true solo para los 10 ejercicios "estrella"
                          con foto + video reales; el resto queda en false

  NOTA IMPORTANTE (regla de negocio confirmada por el usuario):
  De todo el banco de ejercicios, SOLO 10 tendrán foto de ejemplo y video
  reales cargados. El resto de ejercicios existen en el banco pero sin
  media (imagen_url y video_url quedan null/vacíos).

RUTINA
- id (PK)
- cliente_id (referencia a Cliente, SIN FK real -> otro microservicio)
- nombre                  ej. "Rutina 1"
- fecha_inicio            ej. 21/08/2026
- fecha_fin               ej. 26/08/2026

DETALLE_RUTINA  (tabla intermedia Rutina <-> Ejercicio, con parámetros
                 propios de ESA asignación, no del ejercicio en general)
- id (PK)
- rutina_id (FK -> Rutina)
- ejercicio_id (referencia a Ejercicio, SIN FK real -> otro microservicio)
- repeticiones            ej. 12
- series                  ej. 3
- peso                    ej. 20 kg
- descanso_serie          ej. "1 min"
- descanso_ejercicio      ej. "2 min"
- rpe                     escala de esfuerzo percibido, ej. 6

3. ARQUITECTURA (confirmada por diagramas del profesor)
-----------------------------------------------------
Cliente (app móvil) -> API Gateway -> Microservicios (cada uno con su
propia base de datos, NO compartida)

  App móvil
      |
  API Gateway  (enruta + valida token JWT antes de reenviar; hace el
                "join" entre rutina/detalle y los datos del ejercicio
                antes de devolver la respuesta a la app)
      |
      +--> ms-ejercicios  (puerto 8001, DB propia)
      |        capas: Controller -> Servicio -> Dao -> Entidad
      |        entidades: Instructor, Cliente, Ejercicio
      |        maneja login/registro y emite el JWT
      |        sube/gestiona imagen_url y video_url vía Supabase Storage
      |
      +--> ms-rutinas     (puerto 8002, DB propia)
               capas: Controller -> Servicio -> Dao -> Entidad
               entidades: Rutina, DetalleRutina
               valida ejercicio_id llamando por HTTP a ms-ejercicios
               (nunca accede a esa base de datos directamente)
               si ms-ejercicios no responde, devuelve error controlado
               (503), nunca una excepción sin manejar

  DECISIÓN CONFIRMADA: el "join" entre DetalleRutina y los datos del
  Ejercicio (nombre, foto, video) lo arma el GATEWAY, no la app móvil.
  La app recibe la rutina ya con el detalle completo de cada ejercicio
  incluido, sin tener que hacer múltiples llamadas por su cuenta.

4. TECNOLOGÍAS (definidas)
-----------------------------------------------------
- Backend (gateway + ms-ejercicios + ms-rutinas): Python + FastAPI
  - Capas: router -> service -> repository (dao) -> models
  - Comunicación entre servicios: httpx (async)
- Base de datos: PostgreSQL, una instancia/schema por microservicio
  (sin FK real entre bases de datos distintas)
- Almacenamiento de imágenes/videos: Supabase Storage (bucket público
  para los 10 ejercicios con ejemplo completo)
- Autenticación: JWT simple, dos roles únicamente ("instructor" y
  "cliente") — login/registro vive en ms-ejercicios, el gateway valida
  el token en cada request y lo reenvía al microservicio correspondiente
- App móvil (cliente): Flutter
- Contenerización: Docker (Dockerfile por servicio) + docker-compose.yml
  para levantar gateway + ms-ejercicios + ms-rutinas + 2 Postgres juntos
- Deploy académico: local con docker-compose (nivel 1, prioridad para
  mañana); GCP Cloud Run + Artifact Registry + Cloud SQL como opción
  nivel 2 si sobra tiempo

5. MANEJO DE ERRORES ENTRE SERVICIOS
-----------------------------------------------------
- Si ms-ejercicios no responde cuando ms-rutinas necesita validar un
  ejercicio_id, o cuando el gateway necesita armar el join, se devuelve
  un error 503 con mensaje claro ("servicio de ejercicios no disponible"),
  nunca una excepción cruda sin capturar
- Mismo criterio para el gateway hacia cualquiera de los 2 microservicios

6. DATOS SEMILLA (SEED) PARA LA DEMO
-----------------------------------------------------
- Carpeta independiente `/seed` (o `/scripts/seed`) en la raíz del
  proyecto, separada del código de cada servicio
- Script(s) que precargan: 1 instructor, 2-3 clientes, los 10 ejercicios
  con media completa + el resto del banco sin media, y 1-2 rutinas de
  ejemplo con su detalle ya armado
- Objetivo: la demo del profe es mostrar el sistema ya poblado, no crear
  todo en vivo con riesgo de que algo falle en la sustentación

7. DOCKER / DOCKER COMPOSE
-----------------------------------------------------
- Un Dockerfile simple por servicio (gateway, ms-ejercicios, ms-rutinas)
- docker-compose.yml en la raíz levantando los 3 servicios + 2 Postgres
- IMPORTANTE: dentro de docker-compose, los servicios se llaman entre sí
  por NOMBRE DE SERVICIO (ej. http://ms-ejercicios:8001), nunca por
  localhost — el código no debe tener localhost hardcodeado

8. VARIABLES DE ENTORNO Y SECRETOS
-----------------------------------------------------
Cada servicio maneja su configuración sensible mediante variables de
entorno (.env), nunca hardcodeadas en el código. Los archivos .env NO
se suben al repositorio (deben estar en .gitignore).

Gateway (.env):
  JWT_SECRET=<mismo valor que en ms-ejercicios>
  MS_EJERCICIOS_URL=http://ms-ejercicios:8001
  MS_RUTINAS_URL=http://ms-rutinas:8002

ms-ejercicios (.env):
  DATABASE_URL=postgresql://user:password@db-ejercicios:5432/ejercicios
  JWT_SECRET=<clave secreta para firmar/validar tokens>
  JWT_EXPIRE_MINUTES=60
  SUPABASE_URL=<url del proyecto Supabase>
  SUPABASE_KEY=<service_role o anon key, según el caso>
  SUPABASE_BUCKET=ejercicios-media

ms-rutinas (.env):
  DATABASE_URL=postgresql://user:password@db-rutinas:5432/rutinas
  MS_EJERCICIOS_URL=http://ms-ejercicios:8001

Notas:
- JWT_SECRET debe ser idéntico entre el gateway y ms-ejercicios (quien
  emite el token) para que la validación funcione correctamente
- Incluir un archivo .env.example (sin valores reales) en cada carpeta
  de servicio, para que cualquiera pueda levantar el proyecto sabiendo
  qué variables necesita definir
- Las claves de Supabase y el JWT_SECRET nunca se comparten en chats,
  commits ni documentación — solo en el .env local de cada máquina

9. FUERA DE ALCANCE (para la entrega de mañana)
-----------------------------------------------------
- Documentación del proyecto (la hace otro compañero)
- Roles adicionales o permisos granulares (solo instructor/cliente, sin
  sub-roles ni permisos por módulo)
- Deploy real en la nube (a menos que sobre tiempo tras Docker Compose local)
- Media completa para todos los ejercicios (solo 10 la tendrán)

10. PENDIENTE DE DEFINIR
-----------------------------------------------------
- Lista final de los 10 ejercicios "con ejemplo completo" (nombre + foto + video)


11. ORGANIZACIÓN DE CARPETAS (monorepo)
-----------------------------------------------------
banco-ejercicios/
├── docker-compose.yml
├── .gitignore
│
├── gateway/
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── .env.example
│   └── app/
│       ├── main.py
│       ├── config.py
│       ├── routers/
│       │   ├── ejercicios.py      # forward + join hacia ms-ejercicios
│       │   └── rutinas.py         # forward + join rutina+detalle+ejercicio
│       ├── services/
│       │   └── proxy_service.py   # lógica de reenvío httpx + manejo 503
│       └── middlewares/
│           └── auth_middleware.py # validación JWT
│
├── ms-ejercicios/
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── .env.example
│   └── app/
│       ├── main.py
│       ├── config.py
│       ├── models/                # SQLAlchemy: Instructor, Cliente, Ejercicio
│       ├── schemas/                # Pydantic
│       ├── routers/
│       │   ├── auth.py             # login/registro, emite JWT
│       │   ├── instructores.py
│       │   ├── clientes.py
│       │   └── ejercicios.py
│       ├── services/                # lógica de negocio
│       ├── repositories/            # DAO
│       └── storage/
│           └── supabase_client.py   # upload imagen_url/video_url
│
├── ms-rutinas/
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── .env.example
│   └── app/
│       ├── main.py
│       ├── config.py
│       ├── models/                  # SQLAlchemy: Rutina, DetalleRutina
│       ├── schemas/
│       ├── routers/
│       │   ├── rutinas.py
│       │   └── detalles.py
│       ├── services/
│       ├── repositories/
│       └── clients/
│           └── ejercicios_client.py # httpx hacia ms-ejercicios
│
├── seed/
│   ├── seed_ejercicios.py           # 10 ejercicios con media + resto sin media
│   ├── seed_instructor_clientes.py
│   └── seed_rutinas.py
│
└── movil/
    └── (proyecto Flutter)


12. AUTORIZACIÓN POR ROL
-----------------------------------------------------
- Cada endpoint obtiene id y rol desde el JWT decodificado (nunca del
  body/query que manda el cliente)
- Rol "cliente": solo puede ver/crear/editar sus propios datos
  (cliente_id debe coincidir con el id del token, no con lo que la
  request pida ver)
- Rol "instructor": puede ver/gestionar sus propios clientes, ejercicios
  y las rutinas de sus clientes
- Sin sistema de permisos granular más allá de esta validación básica

13. CORS
-----------------------------------------------------
- Habilitado en el Gateway con allow_origins=["*"] (abierto), suficiente
  para el contexto académico y evita bloqueos con la app Flutter o
  pruebas desde Swagger en otra máquina
- No es la configuración recomendada para producción real, solo para
  esta entrega

14. HEALTHCHECKS Y ORDEN DE ARRANQUE (Docker Compose)
-----------------------------------------------------
- Cada servicio (gateway, ms-ejercicios, ms-rutinas) expone un endpoint
  GET /health que devuelve 200 OK cuando está listo
- En docker-compose.yml: ms-rutinas y gateway usan depends_on con
  condition: service_healthy sobre ms-ejercicios (y sus respectivas DBs),
  para evitar que arranquen antes de que sus dependencias estén listas

15. MIGRACIONES DE BASE DE DATOS
-----------------------------------------------------
- Sin Alembic — se usa Base.metadata.create_all() al arrancar cada
  servicio para crear las tablas automáticamente (suficiente para el
  alcance y tiempo de esta entrega)

16. DOCUMENTACIÓN API (SWAGGER)
-----------------------------------------------------
- /docs (Swagger UI) queda habilitado y accesible en cada microservicio,
  útil para mostrar los endpoints en la sustentación sin depender
  100% de que la app móvil funcione perfecto