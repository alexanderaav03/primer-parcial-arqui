import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/clientes/clientes_screen.dart';
import '../features/clientes/crear_cliente_screen.dart';
import '../features/clientes/editar_cliente_screen.dart';
import '../features/ejercicios/editar_ejercicio_screen.dart';
import '../features/ejercicios/ejercicio_detalle_screen.dart';
import '../features/ejercicios/ejercicios_screen.dart';
import '../features/home/home_screen.dart';
import '../features/models/cliente.dart';
import '../features/models/ejercicio_banco.dart';
import '../features/models/ejercicio_detalle.dart';
import '../features/perfil/perfil_screen.dart';
import '../features/progreso/historial_progreso_screen.dart';
import '../features/rutinas/agregar_ejercicio_rutina_screen.dart';
import '../features/rutinas/crear_rutina_screen.dart';
import '../features/rutinas/editar_rutina_screen.dart';
import '../features/rutinas/rutina_detalle_screen.dart';
import '../features/rutinas/rutinas_screen.dart';
import '../features/shell/home_shell.dart';

/// Se reconstruye cada vez que cambia authProvider (login/logout), que es
/// justo cuando necesitamos recalcular a dónde debe ir el usuario.
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final enLogin = state.matchedLocation == '/login';

      if (!auth.isAuthenticated) {
        return enLogin ? null : '/login';
      }

      if (enLogin) {
        return '/inicio';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Tabs principales: persisten el BottomNavigationBar del HomeShell.
      ShellRoute(
        builder: (context, state, child) => HomeShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/inicio',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/clientes',
            builder: (context, state) => const ClientesScreen(),
          ),
          GoRoute(
            path: '/ejercicios',
            builder: (context, state) => const EjerciciosScreen(),
          ),
          GoRoute(
            path: '/perfil',
            builder: (context, state) => const PerfilScreen(),
          ),
          GoRoute(
            path: '/rutinas/mias',
            builder: (context, state) {
              final usuario = auth.usuario!;
              return RutinasScreen(clienteId: usuario.id, titulo: 'Mis rutinas');
            },
          ),
        ],
      ),

      // Pantallas de "drill-down": se abren a pantalla completa, sin bottom nav.
      GoRoute(
        path: '/clientes/nuevo',
        builder: (context, state) => const CrearClienteScreen(),
      ),
      GoRoute(
        path: '/clientes/:clienteId/editar',
        builder: (context, state) {
          final cliente = state.extra as Cliente;
          return EditarClienteScreen(cliente: cliente);
        },
      ),
      GoRoute(
        path: '/clientes/:clienteId/rutinas/nueva',
        builder: (context, state) {
          final clienteId = int.parse(state.pathParameters['clienteId']!);
          return CrearRutinaScreen(clienteId: clienteId);
        },
      ),
      GoRoute(
        path: '/rutinas/:rutinaId/agregar-ejercicios',
        builder: (context, state) {
          final rutinaId = int.parse(state.pathParameters['rutinaId']!);
          final clienteId = int.parse(state.uri.queryParameters['clienteId']!);
          return AgregarEjercicioRutinaScreen(rutinaId: rutinaId, clienteId: clienteId);
        },
      ),
      GoRoute(
        path: '/ejercicios/:ejercicioId',
        builder: (context, state) {
          final ejercicioId = int.parse(state.pathParameters['ejercicioId']!);
          return EjercicioDetalleScreen(ejercicioId: ejercicioId);
        },
      ),
      GoRoute(
        path: '/ejercicios/:ejercicioId/editar',
        builder: (context, state) {
          final ejercicio = state.extra as EjercicioBanco;
          return EditarEjercicioScreen(ejercicio: ejercicio);
        },
      ),
      GoRoute(
        path: '/rutinas/:rutinaId/editar',
        builder: (context, state) {
          final rutina = state.extra as RutinaDetalle;
          return EditarRutinaScreen(rutina: rutina);
        },
      ),
      GoRoute(
        path: '/clientes/:clienteId/rutinas',
        builder: (context, state) {
          final clienteId = int.parse(state.pathParameters['clienteId']!);
          final titulo = state.extra as String? ?? 'Rutinas';
          return RutinasScreen(clienteId: clienteId, titulo: titulo);
        },
      ),
      GoRoute(
        path: '/rutinas/:rutinaId/detalle',
        builder: (context, state) {
          final rutinaId = int.parse(state.pathParameters['rutinaId']!);
          return RutinaDetalleScreen(rutinaId: rutinaId);
        },
      ),
      GoRoute(
        path: '/rutinas/:rutinaId/detalles/:detalleId/progreso',
        builder: (context, state) {
          final rutinaId = int.parse(state.pathParameters['rutinaId']!);
          final detalleId = int.parse(state.pathParameters['detalleId']!);
          final nombre = state.extra as String? ?? 'Ejercicio';
          return HistorialProgresoScreen(rutinaId: rutinaId, detalleId: detalleId, ejercicioNombre: nombre);
        },
      ),
    ],
  );
});
