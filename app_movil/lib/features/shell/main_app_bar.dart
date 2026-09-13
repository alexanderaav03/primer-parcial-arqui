import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Ícono de campana con un punto rojo decorativo (todavía no hay backend de
/// notificaciones - por ahora solo confirma que "no hay nada nuevo").
class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Notificaciones',
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tienes notificaciones nuevas')),
        );
      },
      icon: Badge(
        backgroundColor: Theme.of(context).colorScheme.error,
        smallSize: 9,
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}

/// AppBar compartido por las pantallas principales del ShellRoute (Inicio,
/// Clientes, Ejercicios, Mis rutinas). Se integra con el fondo de la
/// pantalla (sin elevación) y, si la paleta activa define un
/// `headerGradient` (ver AppGradients en core/theme.dart), lo pinta detrás
/// del título - hoy solo la paleta "Energético" lo trae.
///
/// No se usa en Perfil ni en las pantallas de detalle a pantalla completa
/// (esas mantienen su AppBar normal, con botón de volver y sin campana).
class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const MainAppBar({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final gradient = Theme.of(context).extension<AppGradients>()?.headerGradient;

    return AppBar(
      title: Text(title),
      backgroundColor: gradient != null ? Colors.transparent : null,
      flexibleSpace: gradient != null
          ? Container(decoration: BoxDecoration(gradient: gradient))
          : null,
      actions: const [NotificationBellButton()],
    );
  }
}
