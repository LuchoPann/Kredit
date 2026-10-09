import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_lock_provider.dart';
import '../../providers/credits_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../kredit_bottom_dialogs.dart';

class DangerZoneCard extends ConsumerWidget {
  const DangerZoneCard({super.key});

  Future<void> _confirmAndClear(BuildContext context, WidgetRef ref) async {
    final firstConfirm = await showAppConfirmSheet(
      context,
      title: 'Borrar base de datos',
      message: '¿Estás seguro de que quieres borrar TODOS tus créditos? Esta acción no se puede deshacer.',
      confirmLabel: 'Continuar',
      isDanger: true,
      icon: Icons.warning_amber_rounded,
    );
    if (firstConfirm != true || !context.mounted) return;

    final secondConfirm = await showAppConfirmSheet(
      context,
      title: 'Última confirmación',
      message: 'Esta es tu última oportunidad para cancelar. Todos tus créditos, cuotas y movimientos se eliminarán permanentemente. ¿Continuar?',
      confirmLabel: 'Borrar todo',
      isDanger: true,
      icon: Icons.delete_forever_outlined,
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
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final kredit = Theme.of(ctx).extension<AppThemeColors>()!;
        String? pinError;
        return StatefulBuilder(
          builder: (ctx, setState) => Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: kredit.borderCard,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Icon(Icons.lock_outline, size: 28, color: AppColors.danger),
                const SizedBox(height: 12),
                Text('Confirma tu PIN',
                    style: TextStyle(fontSize: AppTextSize.heading, fontWeight: FontWeight.w700, color: kredit.textPrimary)),
                const SizedBox(height: 8),
                Text('Ingresa tu PIN para confirmar que quieres borrar todo.',
                    style: TextStyle(fontSize: AppTextSize.body, color: kredit.textSecondary)),
                const SizedBox(height: 16),
                TextField(
                  controller: pinCtrl,
                  autofocus: true,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'PIN',
                    errorText: pinError,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () async {
                    final ok = await ref.read(appLockProvider.notifier).verifyPin(pinCtrl.text);
                    if (ok) {
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    } else {
                      setState(() => pinError = 'PIN incorrecto');
                    }
                  },
                  child: const Text('Confirmar'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 46)),
                  child: Text('Cancelar', style: TextStyle(color: kredit.textSecondary)),
                ),
              ],
            ),
          ),
        );
      },
    );
    return confirmed == true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.22)),
        ),
        child: Material(
          color: Colors.transparent,
          child: _buildContent(context, ref),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _confirmAndClear(context, ref),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.tile),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.delete_forever_outlined, size: AppIconSize.small, color: AppColors.danger),
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
                    style: TextStyle(fontSize: AppTextSize.body, color: Theme.of(context).extension<AppThemeColors>()!.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'IRREVERSIBLE',
                    style: TextStyle(
                      fontSize: AppTextSize.body,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: AppIconSize.small, color: AppColors.danger.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}
