import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/snackbar.dart';
import 'core/theme.dart';
import 'core/theme_provider.dart';
import 'features/auth/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Se resuelven antes de runApp para que la app arranque ya sabiendo si hay
  // una sesión guardada y qué tema eligió el usuario (evita un splash/flash
  // hacia /login o hacia el tema default).
  final container = ProviderContainer();
  await container.read(authProvider.notifier).restoreSession();
  await container.read(themeOptionProvider.notifier).restore();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeOption = ref.watch(themeOptionProvider);

    return MaterialApp.router(
      title: 'Banco de Ejercicios',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: themeFor(themeOption),
      routerConfig: router,
    );
  }
}
