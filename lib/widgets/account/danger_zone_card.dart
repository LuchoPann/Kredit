import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/credits_provider.dart';
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
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continuar', style: TextStyle(color: AppColors.danger)),
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
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar todo', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
    if (secondConfirm != true) return;

    try {
      await ref.read(creditsProvider.notifier).clearAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Base de datos borrada')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo borrar la base de datos: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Card(
      elevation: 0,
      color: Color.alphaBlend(
        AppColors.danger.withValues(alpha: 0.06),
        kredit.bgCard,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KreditRadius.card),
        side: BorderSide(color: AppColors.danger.withValues(alpha: 0.55)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(KreditRadius.card),
        onTap: () => _confirmAndClear(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(KreditSpacing.card),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.delete_forever_outlined, color: AppColors.danger),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Borrar Base de Datos', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      'Elimina todos tus créditos de forma permanente',
                      style: TextStyle(fontSize: 12, color: kredit.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(KreditRadius.chip),
                      ),
                      child: const Text(
                        'Irreversible',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.danger),
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
      ),
    );
  }
}
