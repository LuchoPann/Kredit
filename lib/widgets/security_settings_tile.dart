import 'package:flutter/material.dart';

import '../screens/lock/setup_lock_screen.dart';
import '../theme/app_theme.dart';

/// "Seguridad" entry point for the Cuenta screen, navigating to
/// [SetupLockScreen]. Kept as its own widget (instead of inlined in
/// account_screen.dart) to keep the integration there to a single-line
/// insertion, since that file may be under concurrent edit.
class SecuritySettingsTile extends StatelessWidget {
  const SecuritySettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Card(
      elevation: 0,
      child: ListTile(
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
    );
  }
}
