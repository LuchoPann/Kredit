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
                icon: Icons.palette_outlined,
                title: 'Apariencia',
                subtitle: '${prefs.isDarkMode ? 'Oscuro' : 'Claro'} · $bgToneLabel',
                onTap: () => _openSheet(
                  context,
                  Consumer(
                    builder: (ctx, ref, _) {
                      final p = ref.watch(themePreferencesProvider);
                      final kredit2 = Theme.of(ctx).extension<KreditColors>()!;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Apariencia',
                            style: TextStyle(
                              fontSize: KreditTextSize.heading,
                              fontWeight: FontWeight.w700,
                              color: kredit2.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Modo claro/oscuro
                          Text(
                            'MODO DE PANTALLA',
                            style: TextStyle(
                              fontSize: KreditTextSize.caption,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: kredit2.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            secondary: Icon(
                              p.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                              color: kredit2.textSecondary,
                            ),
                            title: Text(
                              p.isDarkMode ? 'Modo oscuro' : 'Modo claro',
                              style: TextStyle(fontWeight: FontWeight.w600, color: kredit2.textPrimary),
                            ),
                            subtitle: Text(
                              p.isDarkMode ? 'Tema oscuro activo' : 'Tema claro activo',
                              style: TextStyle(color: kredit2.textTertiary),
                            ),
                            value: p.isDarkMode,
                            onChanged: (v) =>
                                ref.read(themePreferencesProvider.notifier).setIsDarkMode(v),
                          ),
                          const SizedBox(height: 20),
                          // Acento
                          Text(
                            'COLOR DE ACENTO',
                            style: TextStyle(
                              fontSize: KreditTextSize.caption,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: kredit2.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const AccentColorPicker(),
                          const SizedBox(height: 20),
                          // Tono de fondo
                          Text(
                            'TONO DE FONDO',
                            style: TextStyle(
                              fontSize: KreditTextSize.caption,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: kredit2.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const BgTonePicker(),
                        ],
                      );
                    },
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
                icon: Icons.notifications_outlined,
                title: 'Notificaciones',
                subtitle: notifSubtitle,
                onTap: () => _openSheet(
                  context,
                  Consumer(builder: (ctx, ref2, _) {
                    final kredit2 = Theme.of(ctx).extension<KreditColors>()!;
                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Notificaciones',
                              style: TextStyle(fontSize: KreditTextSize.heading, fontWeight: FontWeight.w700, color: kredit2.textPrimary)),
                          const SizedBox(height: 8),
                          Text('RECORDATORIOS DE PAGO',
                              style: TextStyle(fontSize: KreditTextSize.caption, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: kredit2.textTertiary)),
                          const SizedBox(height: 8),
                          const NotificationSettingsTile(),
                          const SizedBox(height: 20),
                          Text('PRUEBA',
                              style: TextStyle(fontSize: KreditTextSize.caption, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: kredit2.textTertiary)),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Enviando notificación de prueba…')),
                              );
                              try {
                                final service = ref2.read(notificationServiceProvider);
                                await service.showTestNotification();
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.send_outlined, size: 18),
                            label: const Text('Probar notificación ahora'),
                            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 46)),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: KreditSpacing.section),

          // ── DATOS Y RESPALDOS ──
          KreditSectionCard(
            label: 'DATOS Y RESPALDOS',
            icon: Icons.storage_outlined,
            children: [
              navTile(
                icon: Icons.storage_outlined,
                title: 'Datos y respaldos',
                subtitle: 'Exportar, importar y respaldo automático',
                onTap: () => _openSheet(
                  context,
                  Consumer(builder: (ctx, ref2, _) {
                    final kredit2 = Theme.of(ctx).extension<KreditColors>()!;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Datos y respaldos',
                            style: TextStyle(fontSize: KreditTextSize.heading, fontWeight: FontWeight.w700, color: kredit2.textPrimary)),
                        const SizedBox(height: 16),
                        const DataToolsCard(),
                        const SizedBox(height: 20),
                        Text('RESPALDO AUTOMÁTICO',
                            style: TextStyle(fontSize: KreditTextSize.caption, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: kredit2.textTertiary)),
                        const SizedBox(height: 8),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const BackupSettingsScreen()),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                              child: Row(children: [
                                Icon(Icons.backup_outlined, size: 20, color: kredit2.textSecondary),
                                const SizedBox(width: 14),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('Configurar respaldo automático',
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kredit2.textPrimary)),
                                  Text('Frecuencia, modo y próximo respaldo',
                                      style: TextStyle(fontSize: 12, color: kredit2.textTertiary)),
                                ])),
                                Icon(Icons.chevron_right, size: 18, color: kredit2.textTertiary),
                              ]),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
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
                icon: Icons.security_outlined,
                title: 'Seguridad',
                subtitle: 'Bloqueo con PIN o biometría',
                onTap: () => _openSheet(
                  context,
                  Consumer(builder: (ctx, _, _) {
                    final kredit2 = Theme.of(ctx).extension<KreditColors>()!;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Seguridad',
                            style: TextStyle(fontSize: KreditTextSize.heading, fontWeight: FontWeight.w700, color: kredit2.textPrimary)),
                        const SizedBox(height: 8),
                        Text('BLOQUEO DE APP',
                            style: TextStyle(fontSize: KreditTextSize.caption, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: kredit2.textTertiary)),
                        const SizedBox(height: 8),
                        const SecuritySettingsTile(),
                      ],
                    );
                  }),
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
