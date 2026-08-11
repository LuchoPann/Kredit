import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/account/accent_color_picker.dart';
import '../../widgets/account/bg_tone_picker.dart';
import '../../widgets/account/danger_zone_card.dart';
import '../../widgets/account/data_tools_card.dart';
import '../../widgets/account/profile_header.dart';
import '../../widgets/account/section_header.dart';
import '../../widgets/account/shadowed_card.dart';
import '../../widgets/notification_settings_tile.dart';
import '../../widgets/security_settings_tile.dart';
import 'how_it_works_screen.dart';

/// "Cuenta" screen: profile, stats, personalization, data tools and danger
/// zone. Port of legacy_pwa `#view-settings` (index.html + app.js
/// renderSettings ~L1524-1560, exportData/importData ~L1615-1658,
/// clearAllData ~L1660-1669).
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(themePreferencesProvider);
    final kredit = Theme.of(context).extension<KreditColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Cuenta')),
      body: ListView(
        padding: const EdgeInsets.all(KreditSpacing.card),
        children: [
          ProfileHeader(profileName: prefs.profileName),
          const SizedBox(height: KreditSpacing.section),
          sectionHeader(Icons.palette_outlined, 'Personalización'),
          const SizedBox(height: KreditSpacing.tile),
          const AccentColorPicker(),
          const SizedBox(height: KreditSpacing.card),
          ShadowedCard(
            child: SwitchListTile(
              secondary: Icon(prefs.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
              title: const Text('Modo Oscuro'),
              subtitle: Text(prefs.isDarkMode ? 'Tema oscuro activo' : 'Tema claro activo'),
              value: prefs.isDarkMode,
              onChanged: (v) => ref.read(themePreferencesProvider.notifier).setIsDarkMode(v),
            ),
          ),
          const SizedBox(height: KreditSpacing.card),
          const BgTonePicker(),
          const SizedBox(height: KreditSpacing.section),
          sectionHeader(Icons.notifications_outlined, 'Notificaciones'),
          const SizedBox(height: KreditSpacing.tile),
          const NotificationSettingsTile(),
          const SizedBox(height: KreditSpacing.section),
          sectionHeader(Icons.security_outlined, 'Seguridad'),
          const SizedBox(height: KreditSpacing.tile),
          const SecuritySettingsTile(),
          const SizedBox(height: KreditSpacing.section),
          sectionHeader(
            Icons.storage_outlined,
            'Datos',
            subtitle: 'Respaldá o restaurá tu información local',
          ),
          const SizedBox(height: KreditSpacing.tile),
          const DataToolsCard(),
          const SizedBox(height: KreditSpacing.section),
          sectionHeader(Icons.help_outline, 'Ayuda'),
          const SizedBox(height: KreditSpacing.tile),
          ShadowedCard(
            child: ListTile(
              leading: Icon(Icons.help_outline, color: kredit.textSecondary),
              title: const Text('Cómo funciona Kredit'),
              subtitle: const Text('Guía rápida de la app y sus pantallas'),
              trailing: Icon(Icons.chevron_right, color: kredit.textTertiary),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HowItWorksScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: KreditSpacing.section),
          sectionHeader(
            Icons.warning_amber_rounded,
            'Zona de riesgo',
            color: AppColors.danger,
            subtitle: 'Acciones permanentes — no se pueden deshacer',
          ),
          const SizedBox(height: KreditSpacing.tile),
          const DangerZoneCard(),
          const SizedBox(height: KreditSpacing.section),
        ],
      ),
    );
  }
}
