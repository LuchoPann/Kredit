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
    final kredit = theme.extension<KreditColors>()!;
    final accentColor = theme.colorScheme.primary;
    final ctaForeground = legibleForegroundOn(accentColor);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Icon(Icons.account_balance_wallet_rounded,
                  size: KreditIconSize.large, color: accentColor),
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
                    _InfoItem(
                      icon: Icons.explore_outlined,
                      iconColor: accentColor,
                      title: 'Créditos de ejemplo',
                      description:
                          'Precargamos 2 créditos con el distintivo "EJEMPLO" para que explores '
                          'la aplicación. Puedes editarlos o eliminarlos como a cualquier otro crédito, '
                          'cuando quieras.',
                    ),
                    Divider(height: 1, color: kredit.borderCard),
                    _InfoItem(
                      icon: Icons.lock_outline,
                      iconColor: accentColor,
                      title: 'Protege tu información',
                      description:
                          'Activa un PIN o desbloqueo biométrico para que solo tú accedas '
                          'a tus créditos, con bloqueo temporal tras varios intentos '
                          'fallidos. Es totalmente opcional, y el widget de inicio '
                          'oculta tus montos por defecto.',
                      trailing: OutlinedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SetupLockScreen(),
                          ),
                        ),
                        child: const Text('Activar PIN/Biometría'),
                      ),
                    ),
                    Divider(height: 1, color: kredit.borderCard),
                    _InfoItem(
                      icon: Icons.notifications_outlined,
                      iconColor: accentColor,
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
              Divider(color: kredit.borderCard, height: 1),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _finish(context, ref),
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: ctaForeground,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(KreditRadius.tile),
                  ),
                ),
                child: Text(
                  'Empezar',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: KreditTextSize.body,
                    color: ctaForeground,
                  ),
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

/// A single onboarding point expressed purely through typography — a small
/// circular accent behind the icon, a bold title, and a description below.
/// No surrounding box; items are separated by hairline `Divider`s instead
/// of stacked bordered cards.
class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: KreditIconSize.small),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
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
    );
  }
}
