import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/notification_settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/account/accent_color_picker.dart';
import '../../widgets/account/bg_tone_picker.dart';
import '../../widgets/account/danger_zone_card.dart';
import '../../widgets/account/data_tools_card.dart';
import '../../widgets/account/profile_header.dart';
import '../../widgets/account/section_header.dart';
import '../../widgets/kredit_section_card.dart';
import '../../widgets/notification_settings_tile.dart';
import '../../widgets/security_settings_tile.dart';
import 'backup_settings_screen.dart';
import 'how_it_works_screen.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  void _openSheet(BuildContext context, Widget child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(themePreferencesProvider);
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final notifSettings = ref.watch(notificationSettingsProvider);

    final bgToneLabel = switch (prefs.bgTone) {
      'cool' => 'Nube',
      'warm' => 'Arena',
      _ => 'Puro',
    };

    final notifSubtitle = notifSettings.enabled
        ? '${notifSettings.daysBefore} día${notifSettings.daysBefore == 1 ? '' : 's'} antes · ${notifSettings.reminderTime.format(context)}'
        : 'Desactivadas';

    Widget navTile({
      required IconData icon,
      required String title,
      String? subtitle,
      required VoidCallback onTap,
      Color? iconColor,
      bool showChevron = true,
    }) =>
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(KreditRadius.tile),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Row(
                children: [
                  Icon(icon, size: KreditIconSize.small, color: iconColor ?? kredit.textSecondary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: KreditTextSize.body,
                            fontWeight: FontWeight.w600,
                            color: kredit.textPrimary,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showChevron)
                    Icon(Icons.chevron_right, size: KreditIconSize.small, color: kredit.textTertiary),
                ],
              ),
            ),
          ),
        );

    Widget divider() => Divider(height: 1, color: kredit.borderCard);

    return Scaffold(
      appBar: AppBar(title: const Text('Cuenta')),
      body: ListView(
        padding: const EdgeInsets.all(KreditSpacing.card),
        children: [
          ProfileHeader(profileName: prefs.profileName),
          const SizedBox(height: KreditSpacing.section),

          // ── APARIENCIA ──
          KreditSectionCard(
            label: 'APARIENCIA',
            icon: Icons.palette_outlined,
            children: [
              navTile(
                icon: prefs.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                title: 'Modo de pantalla',
                subtitle: prefs.isDarkMode ? 'Oscuro' : 'Claro',
                onTap: () => _openSheet(
                  context,
                  Consumer(
                    builder: (ctx, ref, _) {
                      final p = ref.watch(themePreferencesProvider);
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Modo de pantalla',
                              style: TextStyle(fontSize: KreditTextSize.heading, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            secondary: Icon(p.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
                            title: const Text('Modo oscuro'),
                            subtitle: Text(p.isDarkMode ? 'Tema oscuro activo' : 'Tema claro activo'),
                            value: p.isDarkMode,
                            onChanged: (v) =>
                                ref.read(themePreferencesProvider.notifier).setIsDarkMode(v),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              divider(),
              navTile(
                icon: Icons.color_lens_outlined,
                title: 'Color de acento',
                subtitle: 'Personaliza el color principal',
                onTap: () => _openSheet(
                  context,
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Color de acento',
                          style: TextStyle(fontSize: KreditTextSize.heading, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      const AccentColorPicker(),
                    ],
                  ),
                ),
              ),
              divider(),
              navTile(
                icon: Icons.layers_outlined,
                title: 'Tono de fondo',
                subtitle: bgToneLabel,
                onTap: () => _openSheet(
                  context,
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tono de fondo',
                          style: TextStyle(fontSize: KreditTextSize.heading, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      const BgTonePicker(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: KreditSpacing.section),

          // ── NOTIFICACIONES ──
          KreditSectionCard(
            label: 'NOTIFICACIONES',
            icon: Icons.notifications_outlined,
            children: [
              navTile(
                icon: Icons.notifications_active_outlined,
                title: 'Recordatorios de pago',
                subtitle: notifSubtitle,
                onTap: () => _openSheet(
                  context,
                  SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recordatorios de pago',
                            style: TextStyle(
                                fontSize: KreditTextSize.heading, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 16),
                        const NotificationSettingsTile(),
                      ],
                    ),
                  ),
                ),
              ),
              divider(),
              navTile(
                icon: Icons.send_outlined,
                title: 'Probar notificación',
                subtitle: 'Envía una notificación de prueba ahora',
                onTap: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enviando notificación de prueba…')),
                  );
                  try {
                    final service = ref.read(notificationServiceProvider);
                    await service.showTestNotification();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al enviar notificación: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: KreditSpacing.section),

          // ── DATOS Y RESPALDOS ──
          KreditSectionCard(
            label: 'DATOS Y RESPALDOS',
            icon: Icons.storage_outlined,
            children: [
              Consumer(
                builder: (ctx, ref, _) => Column(
                  children: [
                    navTile(
                      icon: Icons.upload_file_outlined,
                      title: 'Exportar datos',
                      subtitle: 'Comparte tu respaldo JSON',
                      onTap: () => _openSheet(
                        ctx,
                        Consumer(
                          builder: (innerCtx, innerRef, _) => Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Datos',
                                  style: TextStyle(
                                      fontSize: KreditTextSize.heading, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 16),
                              const DataToolsCard(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    divider(),
                    navTile(
                      icon: Icons.download_outlined,
                      title: 'Importar datos',
                      subtitle: 'Restaura desde un archivo',
                      onTap: () => _openSheet(
                        ctx,
                        Consumer(
                          builder: (innerCtx, innerRef, _) => Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Datos',
                                  style: TextStyle(
                                      fontSize: KreditTextSize.heading, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 16),
                              const DataToolsCard(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    divider(),
                    _BackupAutoTile(navTile: navTile),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: KreditSpacing.section),

          // ── SEGURIDAD ──
          KreditSectionCard(
            label: 'SEGURIDAD',
            icon: Icons.security_outlined,
            children: [
              navTile(
                icon: Icons.lock_outline,
                title: 'Bloqueo de app',
                subtitle: 'PIN o biometría',
                onTap: () => _openSheet(
                  context,
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Seguridad',
                          style: TextStyle(fontSize: KreditTextSize.heading, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      const SecuritySettingsTile(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: KreditSpacing.section),

          // ── ACERCA DE ──
          KreditSectionCard(
            label: 'ACERCA DE',
            icon: Icons.info_outlined,
            children: [
              navTile(
                icon: Icons.help_outline,
                title: 'Cómo funciona Kredit',
                subtitle: 'Guía rápida de la app',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HowItWorksScreen()),
                ),
              ),
              divider(),
              navTile(
                icon: Icons.tag_rounded,
                title: 'Versión',
                subtitle: '1.0.0',
                onTap: () {},
                showChevron: false,
              ),
            ],
          ),
          const SizedBox(height: KreditSpacing.section),

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

/// Tile de respaldo automático que lee el estado actual de SharedPreferences
/// para mostrar el subtítulo dinámico sin necesitar un provider adicional.
class _BackupAutoTile extends StatefulWidget {
  final Widget Function({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    bool showChevron,
  }) navTile;

  const _BackupAutoTile({required this.navTile});

  @override
  State<_BackupAutoTile> createState() => _BackupAutoTileState();
}

class _BackupAutoTileState extends State<_BackupAutoTile> {
  String _subtitle = 'Cargando…';

  @override
  void initState() {
    super.initState();
    _loadSubtitle();
  }

  Future<void> _loadSubtitle() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('backup_enabled') ?? false;
    if (!enabled) {
      if (mounted) setState(() => _subtitle = 'Desactivado');
      return;
    }
    final freq = prefs.getString('backup_frequency') ?? 'weekly';
    final mode = prefs.getString('backup_mode') ?? 'overwrite';
    final freqLabel = switch (freq) {
      'daily' => 'Diario',
      'biweekly' => 'Quincenal',
      'monthly' => 'Mensual',
      _ => 'Semanal',
    };
    final modeLabel = mode == 'new_file' ? 'Archivo nuevo' : 'Sobreescribir';
    if (mounted) setState(() => _subtitle = '$freqLabel · $modeLabel');
  }

  @override
  Widget build(BuildContext context) {
    return widget.navTile(
      icon: Icons.backup_outlined,
      title: 'Respaldo automático',
      subtitle: _subtitle,
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BackupSettingsScreen()),
        );
        _loadSubtitle(); // refresh after returning
      },
    );
  }
}
