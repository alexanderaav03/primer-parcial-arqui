import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/theme_provider.dart';
import '../../core/widgets.dart';
import '../auth/auth_provider.dart';

class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authProvider).usuario;
    final textTheme = Theme.of(context).textTheme;

    if (usuario == null) {
      // No debería ocurrir (esta pantalla vive dentro del shell autenticado),
      // pero evita un crash si por algo se reconstruye durante el logout.
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Column(
            children: [
              InitialsAvatar(nombre: usuario.nombre, radius: 48),
              const SizedBox(height: 16),
              Text(usuario.nombre, style: textTheme.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              InfoBadge(
                icon: usuario.esInstructor ? Icons.badge_outlined : Icons.person_outline,
                label: usuario.esInstructor ? 'Instructor' : 'Cliente',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // TODO: POST /api/auth/login no devuelve email hoy (ver
                  // features/models/usuario.dart) - queda "No disponible aún"
                  // hasta que el backend lo incluya en la respuesta de login.
                  _InfoRow(icon: Icons.email_outlined, label: 'Email', valor: usuario.email),
                  const Divider(height: 1),
                  if (usuario.esInstructor)
                    // TODO: requiere exponer GET /api/instructores/me a través
                    // del gateway (hoy existe en ms-ejercicios pero el gateway
                    // no lo proxea) para poder traer la especialidad.
                    const _InfoRow(icon: Icons.workspace_premium_outlined, label: 'Especialidad', valor: null)
                  else
                    // TODO: no existe hoy un endpoint que permita a un cliente
                    // consultar su propio objetivo (GET /api/clientes es
                    // solo-instructor). Falta algo tipo GET /api/clientes/me.
                    const _InfoRow(icon: Icons.flag_outlined, label: 'Objetivo', valor: null),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _AparienciaCard(),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            label: Text('Cerrar sesión', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Theme.of(context).colorScheme.error),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}

class _AparienciaCard extends ConsumerWidget {
  const _AparienciaCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seleccionado = ref.watch(themeOptionProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apariencia', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _OpcionTema(
                    label: 'Energético',
                    color: AppColors.energeticPrimary,
                    seleccionado: seleccionado == AppThemeOption.energetic,
                    onTap: () => ref.read(themeOptionProvider.notifier).select(AppThemeOption.energetic),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OpcionTema(
                    label: 'Premium',
                    color: AppColors.premiumPrimary,
                    seleccionado: seleccionado == AppThemeOption.premium,
                    onTap: () => ref.read(themeOptionProvider.notifier).select(AppThemeOption.premium),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OpcionTema extends StatelessWidget {
  final String label;
  final Color color;
  final bool seleccionado;
  final VoidCallback onTap;

  const _OpcionTema({
    required this.label,
    required this.color,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = seleccionado ? color : colorScheme.onSurface.withValues(alpha: 0.15);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: seleccionado ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: seleccionado ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? valor;

  const _InfoRow({required this.icon, required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    final disponible = valor != null && valor!.trim().isNotEmpty;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 2),
                Text(
                  disponible ? valor! : 'No disponible aún',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: disponible ? colorScheme.onSurface : null,
                        fontStyle: disponible ? FontStyle.normal : FontStyle.italic,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
