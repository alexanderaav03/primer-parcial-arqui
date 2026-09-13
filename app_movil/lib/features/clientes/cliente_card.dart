import 'package:flutter/material.dart';

import '../../core/widgets.dart';
import '../models/cliente.dart';

/// Card de un cliente (avatar de iniciales + nombre + objetivo). La usan
/// tanto ClientesScreen (lista completa) como HomeScreen (resumen reciente).
class ClienteCard extends StatelessWidget {
  final Cliente cliente;
  final VoidCallback onTap;

  /// Íconos de editar/eliminar opcionales -solo ClientesScreen los pasa; en
  /// el resumen de HomeScreen se omiten para no sobrecargar esa vista rápida-.
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ClienteCard({
    super.key,
    required this.cliente,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

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
                    if (_pesoAltura(cliente) != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _pesoAltura(cliente)!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                      ),
                    ],
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
              if (onDelete != null)
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 20, color: Theme.of(context).colorScheme.error),
                  tooltip: 'Eliminar cliente',
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

/// "72 kg - 1.75 m" si hay al menos un valor; null si ambos son null
/// (para no mostrar texto vacío ni "null" en pantalla). Altura se guarda en
/// cm (ver crear/editar_cliente_screen) y se muestra convertida a metros.
String? _pesoAltura(Cliente cliente) {
  final partes = <String>[];
  if (cliente.peso != null) partes.add('${formatNumeroSinDecimales(cliente.peso)} kg');
  if (cliente.altura != null) partes.add('${(cliente.altura! / 100).toStringAsFixed(2)} m');
  if (partes.isEmpty) return null;
  return partes.join(' - ');
}
