import 'package:flutter/material.dart';

import 'date_format.dart';
import 'theme.dart';

/// Buscador simple para filtrar una lista ya cargada en memoria (clientes,
/// ejercicios del banco) - no dispara ninguna llamada al backend.
class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  const SearchField({super.key, required this.controller, required this.hintText, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
        ),
      ),
    );
  }
}

/// Campo "tappable" con la forma de un TextFormField que abre un
/// DatePicker al tocarlo. Lo usan crear/editar rutina.
class DateField extends StatelessWidget {
  final String label;
  final DateTime? fecha;
  final VoidCallback onTap;

  const DateField({super.key, required this.label, required this.fecha, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_month_outlined),
        ),
        child: Text(
          fecha != null ? formatFechaVisual(fecha!) : 'Selecciona una fecha',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

/// Spinner + mensaje, para no dejar un CircularProgressIndicator solo
/// en medio de la pantalla sin contexto de qué está cargando.
class LoadingView extends StatelessWidget {
  final String message;

  const LoadingView({super.key, this.message = 'Cargando...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Estado de error reutilizable para las pantallas que consumen un
/// `FutureProvider` (clientes, rutinas, detalle de rutina).
class AsyncErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const AsyncErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

/// Estado vacío amigable (en vez de una pantalla en blanco).
class EmptyView extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyView({super.key, required this.message, this.icon = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

String _initialsFor(String nombre) {
  final partes = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (partes.isEmpty) return '?';
  if (partes.length == 1) {
    return partes.first.substring(0, partes.first.length >= 2 ? 2 : 1).toUpperCase();
  }
  return (partes.first[0] + partes[1][0]).toUpperCase();
}

Color _avatarColorFor(String nombre) {
  final hash = nombre.codeUnits.fold<int>(0, (acumulado, c) => acumulado + c);
  return AppColors.avatarPalette[hash % AppColors.avatarPalette.length];
}

/// Avatar circular con las iniciales del nombre y un color estable
/// derivado del propio nombre (mismo nombre -> mismo color siempre).
class InitialsAvatar extends StatelessWidget {
  final String nombre;
  final double radius;

  const InitialsAvatar({super.key, required this.nombre, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _avatarColorFor(nombre),
      child: Text(
        _initialsFor(nombre),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.65,
        ),
      ),
    );
  }
}

/// Imagen de un ejercicio (banner ancho) con el mismo fallback en toda la
/// app: si no hay [imagenUrl] o falla la carga, un placeholder tintado con
/// el color primario del tema activo y un ícono de gimnasio. La usan tanto
/// el detalle de rutina como el detalle de ejercicio individual.
class EjercicioImagen extends StatelessWidget {
  final String? imagenUrl;
  final double height;

  const EjercicioImagen({super.key, required this.imagenUrl, this.height = 160});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (imagenUrl == null) {
      return _placeholder(colorScheme, Icons.fitness_center);
    }

    return Image.network(
      imagenUrl!,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          height: height,
          child: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
        );
      },
      errorBuilder: (context, error, stackTrace) => _placeholder(colorScheme, Icons.broken_image_outlined),
    );
  }

  Widget _placeholder(ColorScheme colorScheme, IconData icon) {
    return Container(
      height: height,
      width: double.infinity,
      color: colorScheme.primary.withValues(alpha: 0.1),
      child: Icon(icon, size: 56, color: colorScheme.primary),
    );
  }
}

/// Ícono pequeño + texto, para datos secundarios como los descansos
/// ("Descanso serie: 1 min"). Más discreto que [InfoBadge] -sin fondo-.
class IconTextRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const IconTextRow({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

/// Badge pequeño tipo "chip" para datos como series/reps/peso/RPE, o
/// para estados (ej. "Activa"/"Finalizada") pasando un [color] propio.
class InfoBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;

  const InfoBadge({super.key, required this.label, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final tono = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tono.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: tono),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: tono,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
