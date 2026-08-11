import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../main.dart' show RootScaffold;
import '../../providers/notification_settings_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_theme.dart';
import '../lock/setup_lock_screen.dart';

/// First-run welcome screen shown once (gated by `onboardingProvider` in
/// `main.dart`'s `AppLockGate`) before the user ever sees `RootScaffold`.
/// Explains the two preloaded "EJEMPLO" demo credits and offers optional,
/// skippable shortcuts to enable PIN/biometric lock and due-date
/// notifications. Tapping "Empezar" marks onboarding as shown and replaces
/// this screen with `RootScaffold`.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  void _finish(BuildContext context, WidgetRef ref) {
    ref.read(onboardingProvider.notifier).markShown();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RootScaffold()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsEnabled = ref.watch(notificationSettingsProvider).enabled;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Icon(Icons.account_balance_wallet_rounded,
                  size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                '¡Bienvenido a Kredit!',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Controla tus créditos y tarjetas en un solo lugar, sin conexión.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _InfoCard(
                      step: 1,
                      icon: Icons.explore_outlined,
                      iconColor: theme.colorScheme.primary,
                      title: 'Créditos de ejemplo',
                      description:
                          'Precargamos 2 créditos con el distintivo "EJEMPLO" para que explores '
                          'la aplicación. Puedes editarlos o eliminarlos como a cualquier otro crédito, '
                          'cuando quieras.',
                    ),
                    const SizedBox(height: 16),
                    _InfoCard(
                      step: 2,
                      icon: Icons.lock_outline,
                      iconColor: theme.colorScheme.primary,
                      title: 'Protege tu información',
                      description:
                          'Activa un PIN o desbloqueo biométrico para que solo tú accedas '
                          'a tus créditos. Es totalmente opcional.',
                      trailing: OutlinedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SetupLockScreen(),
                          ),
                        ),
                        child: const Text('Activar PIN/Biometría'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InfoCard(
                      step: 3,
                      icon: Icons.notifications_outlined,
                      iconColor: theme.colorScheme.primary,
                      title: 'No te pierdas un vencimiento',
                      description:
                          'Recibe un aviso local unos días antes del vencimiento de una cuota.',
                      trailing: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(child: Text('Notificaciones de vencimiento')),
                          Switch(
                            value: notificationsEnabled,
                            onChanged: (value) => ref
                                .read(notificationSettingsProvider.notifier)
                                .setEnabled(value),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: KreditSpacing.section),
              Divider(color: theme.extension<KreditColors>()!.borderCard, height: 1),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _finish(context, ref),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(KreditRadius.tile),
                  ),
                ),
                child: const Text(
                  'Empezar',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.step,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    this.trailing,
  });

  final int step;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kredit = theme.extension<KreditColors>()!;
    return Card(
      elevation: 0,
      color: kredit.bgCard,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KreditRadius.card),
        side: BorderSide(color: kredit.borderCard),
      ),
      child: Padding(
        padding: const EdgeInsets.all(KreditSpacing.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(KreditRadius.chip),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: kredit.borderCard),
                  ),
                  child: Text(
                    '$step',
                    style: TextStyle(
                      color: kredit.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(description, style: theme.textTheme.bodyMedium),
            if (trailing != null) ...[
              const SizedBox(height: 14),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
