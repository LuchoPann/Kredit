import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/credit_calculator.dart';
import '../../providers/credits_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/credit_display_utils.dart';
import '../../widgets/account/accent_color_picker.dart';
import '../../widgets/account/bg_tone_picker.dart';
import '../../widgets/account/danger_zone_card.dart';
import '../../widgets/account/data_tools_card.dart';
import '../../widgets/account/profile_header.dart';
import '../../widgets/account/section_header.dart';
import '../../widgets/kredit_section_card.dart';
import '../../widgets/notification_settings_tile.dart';
import '../../widgets/security_settings_tile.dart';
import 'how_it_works_screen.dart';

/// "Cuenta" screen: profile, stats, personalization, data tools and danger
/// zone. Port of legacy_pwa `#view-settings` (index.html + app.js
/// renderSettings ~L1524-1560, exportData/importData ~L1615-1658,
/// clearAllData ~L1660-1669).
/// Resumen aditivo bajo el perfil: cuántos créditos activos y cuánto queda
/// pendiente en total, para dar contexto financiero de un vistazo sin bajar
/// a otra pestaña — puramente informativo, no modifica ningún dato.
class _AccountQuickSummary extends ConsumerWidget {
  const _AccountQuickSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditsAsync = ref.watch(creditsProvider);
    final credits = creditsAsync.valueOrNull;
    if (credits == null || credits.isEmpty) return const SizedBox.shrink();
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final active = credits.where(creditHasUnpaid).length;
    final totalPending = credits.fold<double>(
      0,
      (sum, c) => sum + getCreditRemainingBalance(c),
    );

    return Row(
      children: [
        Icon(Icons.account_balance_wallet_outlined, size: KreditIconSize.small, color: kredit.textTertiary),
        const SizedBox(width: 6),
        Text(
          '$active ${active == 1 ? 'crédito activo' : 'créditos activos'} · ${formatCOP(totalPending)} pendiente',
          style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

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
          const SizedBox(height: KreditSpacing.tile),
          const _AccountQuickSummary(),
          const SizedBox(height: KreditSpacing.section),
          KreditSectionCard(
            children: [
              sectionHeader('Personalización'),
              const SizedBox(height: KreditSpacing.tile),
              const AccentColorPicker(),
              const SizedBox(height: KreditSpacing.card),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(prefs.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
                title: const Text('Modo Oscuro'),
                subtitle: Text(prefs.isDarkMode ? 'Tema oscuro activo' : 'Tema claro activo'),
                value: prefs.isDarkMode,
                onChanged: (v) => ref.read(themePreferencesProvider.notifier).setIsDarkMode(v),
              ),
              const SizedBox(height: KreditSpacing.card),
              const BgTonePicker(),
            ],
          ),
          const SizedBox(height: KreditSpacing.section),
          KreditSectionCard(
            children: [
              sectionHeader('Notificaciones'),
              const SizedBox(height: KreditSpacing.tile),
              const NotificationSettingsTile(),
            ],
          ),
          const SizedBox(height: KreditSpacing.section),
          KreditSectionCard(
            children: [
              sectionHeader('Seguridad'),
              const SizedBox(height: KreditSpacing.tile),
              const SecuritySettingsTile(),
            ],
          ),
          const SizedBox(height: KreditSpacing.section),
          KreditSectionCard(
            children: [
              sectionHeader(
                'Datos',
                subtitle: 'Respalda o restaura tu información local',
              ),
              const SizedBox(height: KreditSpacing.tile),
              const DataToolsCard(),
            ],
          ),
          const SizedBox(height: KreditSpacing.section),
          KreditSectionCard(
            children: [
              sectionHeader('Ayuda'),
              const SizedBox(height: KreditSpacing.tile),
              // Material transparente: mismo fix que en dashboard_screen.dart
              // — el ink splash del ListTile queda oculto detras del
              // DecoratedBox de KreditSectionCard sin este Material de por
              // medio (warning real de Flutter, verificado en dispositivo).
              Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
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
            ],
          ),
          const SizedBox(height: KreditSpacing.section),
          // Zona de riesgo se deja fuera del patrón de tarjeta sutil: es
          // contenido destructivo cuyo color de peligro (título + botones en
          // AppColors.danger dentro de DangerZoneCard) ya es la señal visual
          // distintiva que necesita — meterlo en la misma caja bgCard/borderCard
          // neutra que el resto de secciones "normales" diluiría esa señal en
          // vez de reforzarla.
          sectionHeader(
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
