import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/widget_privacy_provider.dart';
import '../screens/lock/setup_lock_screen.dart';
import '../theme/app_theme.dart';

/// "Seguridad" section for the Cuenta screen: the app-lock entry point
/// (navigating to [SetupLockScreen]) plus the home screen widget privacy
/// toggle. Kept as its own widget (instead of inlined in
/// account_screen.dart) to keep the integration there to a single-line
/// insertion, since that file may be under concurrent edit.
class SecuritySettingsTile extends ConsumerWidget {
  const SecuritySettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final showAmounts = ref.watch(widgetPrivacyProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.security_outlined, color: kredit.textSecondary),
          title: const Text('Seguridad'),
          subtitle: const Text('Bloqueo con biometría o PIN al abrir la app'),
          trailing: Icon(Icons.chevron_right, color: kredit.textTertiary),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SetupLockScreen()),
            );
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: Icon(
            showAmounts ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: kredit.textSecondary,
          ),
          title: const Text('Mostrar montos en el widget'),
          subtitle: const Text(
            'El widget de pantalla de inicio es visible sin desbloquear la app. '
            'Desactivado, muestra solo texto genérico sin cifras.',
          ),
          value: showAmounts,
          onChanged: (v) => ref.read(widgetPrivacyProvider.notifier).setShowAmounts(v),
        ),
      ],
    );
  }
}
