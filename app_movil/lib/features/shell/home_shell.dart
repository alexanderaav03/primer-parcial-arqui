import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_provider.dart';

class _TabDef {
  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _TabDef({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

const _tabsInstructor = [
  _TabDef(path: '/inicio', label: 'Inicio', icon: Icons.home_outlined, selectedIcon: Icons.home),
  _TabDef(path: '/clientes', label: 'Clientes', icon: Icons.people_outline, selectedIcon: Icons.people),
  _TabDef(path: '/ejercicios', label: 'Ejercicios', icon: Icons.fitness_center_outlined, selectedIcon: Icons.fitness_center),
  _TabDef(path: '/perfil', label: 'Perfil', icon: Icons.person_outline, selectedIcon: Icons.person),
];

const _tabsCliente = [
  _TabDef(path: '/inicio', label: 'Inicio', icon: Icons.home_outlined, selectedIcon: Icons.home),
  _TabDef(path: '/rutinas/mias', label: 'Mis rutinas', icon: Icons.event_note_outlined, selectedIcon: Icons.event_note),
  _TabDef(path: '/perfil', label: 'Perfil', icon: Icons.person_outline, selectedIcon: Icons.person),
];

/// Scaffold con BottomNavigationBar que envuelve las pantallas principales,
/// para que la app se sienta completa y sea fácil sumar tabs después.
/// Las pantallas de "drill-down" (rutinas de un cliente puntual, detalle de
/// una rutina) viven fuera del shell -se abren a pantalla completa, sin nav-.
class HomeShell extends ConsumerWidget {
  final Widget child;
  final String location;

  const HomeShell({super.key, required this.child, required this.location});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final esInstructor = ref.watch(authProvider).usuario?.esInstructor ?? false;
    final tabs = esInstructor ? _tabsInstructor : _tabsCliente;

    final currentIndex = tabs.indexWhere((tab) => location.startsWith(tab.path));

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex < 0 ? 0 : currentIndex,
        onTap: (index) => context.go(tabs[index].path),
        items: [
          for (final tab in tabs)
            BottomNavigationBarItem(
              icon: Icon(tab.icon),
              activeIcon: Icon(tab.selectedIcon),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}
