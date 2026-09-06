import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/credits_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class DangerZoneCard extends ConsumerWidget {
  const DangerZoneCard({super.key});

  Future<void> _confirmAndClear(BuildContext context, WidgetRef ref) async {
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Borrar base de datos'),
        content: const Text(
          '¿Estás seguro de que quieres borrar TODOS tus créditos? Esta acción '
          'no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (firstConfirm != true || !context.mounted) return;

    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Última confirmación'),
        content: const Text(
          'Esta es tu última oportunidad para cancelar. Todos tus créditos, '
          'cuotas y movimientos se eliminarán permanentemente. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar todo'),
          ),
        ],
      ),
    );
    if (secondConfirm != true) return;

    try {
      await ref.read(creditsProvider.notifier).clearAll();
      await ref.read(themePreferencesProvider.notifier).clearAvatar();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Base de datos borrada')),
        );
      }
    } catch (e) {
      debugPrint('clearAll failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo borrar la base de datos. Intenta de nuevo.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // No boxed card — matches the borderless typographic language used
    // elsewhere in "Cuenta", but the destructive action still gets a
    // distinctive treatment via the danger color on its icon/title/tag,
    // which is enough to read as "different" without a red border.
    return InkWell(
      onTap: () => _confirmAndClear(context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.delete_forever_outlined, color: AppColors.danger),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Borrar Base de Datos',
                    style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Elimina todos tus créditos de forma permanente',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).extension<KreditColors>()!.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'IRREVERSIBLE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: AppColors.danger.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}
