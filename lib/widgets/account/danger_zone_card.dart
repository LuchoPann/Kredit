import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_lock_provider.dart';
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
    if (secondConfirm != true || !context.mounted) return;

    // Re-verify with whatever lock method the user already has configured
    // (PIN or biometric) as one more speed bump before an irreversible
    // wipe — no lock configured (LockMethod.none) skips straight through,
    // since there's nothing to re-check.
    final lockMethod = ref.read(appLockProvider).method;
    if (lockMethod != LockMethod.none) {
      final reauthed = await _reauthenticate(context, ref, lockMethod);
      if (!reauthed || !context.mounted) return;
    }

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

  /// Re-checks the user's own PIN/biometric — whichever [method] they
  /// already have configured — right before the wipe actually runs. For
  /// biometric, delegates straight to the OS prompt. For PIN, shows a small
  /// dialog reusing [AppLockNotifier.verifyPin] (so the same brute-force
  /// backoff from the lock screen applies here too) and lets the user retry
  /// on a wrong PIN instead of just failing the whole flow.
  Future<bool> _reauthenticate(BuildContext context, WidgetRef ref, LockMethod method) async {
    if (method == LockMethod.biometric) {
      return ref.read(appLockProvider.notifier).authenticateWithBiometrics();
    }
    final pinCtrl = TextEditingController();
    String? error;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Confirma tu PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ingresa tu PIN para confirmar que quieres borrar todo.'),
              const SizedBox(height: 12),
              TextField(
                controller: pinCtrl,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'PIN',
                  errorText: error,
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              onPressed: () async {
                final ok = await ref.read(appLockProvider.notifier).verifyPin(pinCtrl.text);
                if (ok) {
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } else {
                  setState(() => error = 'PIN incorrecto');
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
    return confirmed == true;
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
                    style: TextStyle(fontSize: KreditTextSize.caption, color: Theme.of(context).extension<KreditColors>()!.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'IRREVERSIBLE',
                    style: TextStyle(
                      fontSize: KreditTextSize.caption,
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
