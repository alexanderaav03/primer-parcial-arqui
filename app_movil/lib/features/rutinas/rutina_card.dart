import 'package:flutter/material.dart';

import '../../core/date_format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../models/rutina.dart';

/// Card de una rutina (ícono de calendario + nombre + rango de fechas +
/// badge Activa/Finalizada). La usan RutinasScreen (lista completa) y
/// HomeScreen (resumen reciente del cliente).
class RutinaCard extends StatelessWidget {
  final Rutina rutina;
  final VoidCallback onTap;

  /// Ícono de eliminar opcional -solo la vista del instructor en
  /// RutinasScreen lo pasa; en el resumen de HomeScreen se omite-.
  final VoidCallback? onDelete;

  const RutinaCard({super.key, required this.rutina, required this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final activa = esRutinaActiva(rutina.fechaFin);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rutina.nombre, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      formatRangoFechas(rutina.fechaInicio, rutina.fechaFin),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    InfoBadge(
                      label: activa ? 'Activa' : 'Finalizada',
                      color: activa
                          ? AppColors.success
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 20, color: Theme.of(context).colorScheme.error),
                  tooltip: 'Eliminar rutina',
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                ),
              Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}
