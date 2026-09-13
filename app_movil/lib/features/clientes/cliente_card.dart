import 'package:flutter/material.dart';

import '../../core/widgets.dart';
import '../models/cliente.dart';

/// Card de un cliente (avatar de iniciales + nombre + objetivo). La usan
/// tanto ClientesScreen (lista completa) como HomeScreen (resumen reciente).
class ClienteCard extends StatelessWidget {
  final Cliente cliente;
  final VoidCallback onTap;

  /// Ícono de editar opcional -solo ClientesScreen lo pasa; en el resumen
  /// de HomeScreen se omite para no sobrecargar esa vista rápida-.
  final VoidCallback? onEdit;

  const ClienteCard({super.key, required this.cliente, required this.onTap, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              InitialsAvatar(nombre: cliente.nombre),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cliente.nombre, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Objetivo: ${cliente.objetivo}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Editar cliente',
                  visualDensity: VisualDensity.compact,
                  onPressed: onEdit,
                ),
              Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}
