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
import '../../widgets/notification_settings_tile.dart';
import '../../widgets/security_settings_tile.dart';
import 'backup_settings_screen.dart';
import 'how_it_works_screen.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  void _openSheet(BuildContext context, String title, Widget content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              content,
            ],
          ),
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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Header colapsable con foto de perfil ──
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _ProfileBanner(profileName: prefs.profileName, kredit: kredit),
              collapseMode: CollapseMode.parallax,
            ),
            title: Text(
              prefs.profileName.isNotEmpty ? prefs.profileName : 'Cuenta',
              style: const TextStyle(fontSize: KreditTextSize.body, fontWeight: FontWeight.w700),
            ),
          ),

          // ── Lista plana de opciones ──
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 8),

                // ── PERSONALIZACIÓN ──
                _SectionDivider(label: 'Personalización', kredit: kredit),
                _SettingsTile(
                  icon: Icons.palette_outlined,
                  title: 'Apariencia',
                  subtitle: '${prefs.isDarkMode ? 'Oscuro' : 'Claro'} · $bgToneLabel',
                  onTap: () => _openSheet(
                    context,
                    'Apariencia',
                    Consumer(
                      builder: (ctx, ref, _) {
                        final p = ref.watch(themePreferencesProvider);
                        final kredit2 = Theme.of(ctx).extension<KreditColors>()!;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SheetTitle('Apariencia', kredit2),
                            const SizedBox(height: 20),
                            _SheetLabel('MODO DE PANTALLA', kredit2),
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
                            _SheetLabel('COLOR DE ACENTO', kredit2),
                            const SizedBox(height: 8),
                            const AccentColorPicker(),
                            const SizedBox(height: 20),
                            _SheetLabel('TONO DE FONDO', kredit2),
                            const SizedBox(height: 8),
                            const BgTonePicker(),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                _Divider(kredit),

                // ── CUENTA ──
                _SectionDivider(label: 'Cuenta', kredit: kredit),
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notificaciones',
                  subtitle: notifSubtitle,
                  onTap: () => _openSheet(
                    context,
                    'Notificaciones',
                    Consumer(builder: (ctx, ref2, _) {
                      final kredit2 = Theme.of(ctx).extension<KreditColors>()!;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SheetTitle('Notificaciones', kredit2),
                          const SizedBox(height: 8),
                          _SheetLabel('RECORDATORIOS DE PAGO', kredit2),
                          const SizedBox(height: 8),
                          const NotificationSettingsTile(),
                          const SizedBox(height: 20),
                          _SheetLabel('PRUEBA', kredit2),
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
                            style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 46)),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
                _Divider(kredit),
                _SettingsTile(
                  icon: Icons.storage_outlined,
                  title: 'Datos y respaldos',
                  subtitle: 'Exportar, importar y respaldo automático',
                  onTap: () => _openSheet(
                    context,
                    'Datos y respaldos',
                    Consumer(builder: (ctx, ref2, _) {
                      final kredit2 = Theme.of(ctx).extension<KreditColors>()!;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SheetTitle('Datos y respaldos', kredit2),
                          const SizedBox(height: 16),
                          const DataToolsCard(),
                          const SizedBox(height: 20),
                          _SheetLabel('RESPALDO AUTOMÁTICO', kredit2),
                          const SizedBox(height: 8),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => const BackupSettingsScreen()),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                                child: Row(children: [
                                  Icon(Icons.backup_outlined,
                                      size: 20, color: kredit2.textSecondary),
                                  const SizedBox(width: 14),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                        Text('Configurar respaldo automático',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: kredit2.textPrimary)),
                                        Text('Frecuencia, hora y carpeta destino',
                                            style: TextStyle(
                                                fontSize: 12, color: kredit2.textTertiary)),
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
                _Divider(kredit),
                _SettingsTile(
                  icon: Icons.lock_outline,
                  title: 'Seguridad',
                  subtitle: 'Bloqueo con PIN o biometría',
                  onTap: () => _openSheet(
                    context,
                    'Seguridad',
                    Consumer(builder: (ctx, _, _) {
                      final kredit2 = Theme.of(ctx).extension<KreditColors>()!;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SheetTitle('Seguridad', kredit2),
                          const SizedBox(height: 8),
                          _SheetLabel('BLOQUEO DE APP', kredit2),
                          const SizedBox(height: 8),
                          const SecuritySettingsTile(),
                        ],
                      );
                    }),
                  ),
                ),

                // ── INFORMACIÓN ──
                _SectionDivider(label: 'Información', kredit: kredit),
                _SettingsTile(
                  icon: Icons.help_outline,
                  title: 'Cómo funciona Kredit',
                  subtitle: 'Guía rápida de la app',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HowItWorksScreen()),
                  ),
                ),
                _Divider(kredit),
                _SettingsTile(
                  icon: Icons.tag_rounded,
                  title: 'Versión',
                  subtitle: '1.0.0',
                  showChevron: false,
                  onTap: () {},
                ),

                // ── ZONA DE RIESGO ──
                _SectionDivider(label: 'Zona de riesgo', kredit: kredit, danger: true),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: KreditSpacing.card, vertical: 4),
                  child: const DangerZoneCard(),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets de apoyo ──────────────────────────────────────────────────────────

class _ProfileBanner extends StatelessWidget {
  final String profileName;
  final KreditColors kredit;

  const _ProfileBanner({required this.profileName, required this.kredit});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: kredit.bgCard,
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            // Avatar
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.15),
                    border: Border.all(color: accent.withValues(alpha: 0.4), width: 2.5),
                  ),
                  child: Icon(Icons.person_outline_rounded,
                      size: 44, color: accent.withValues(alpha: 0.7)),
                ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: kredit.bgCard, width: 2),
                  ),
                  child: const Icon(Icons.edit_outlined, size: 12, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              profileName.isNotEmpty ? profileName : 'Mi perfil',
              style: TextStyle(
                fontSize: KreditTextSize.heading,
                fontWeight: FontWeight.w700,
                color: kredit.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Kredit · Mis créditos',
              style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String label;
  final KreditColors kredit;
  final bool danger;

  const _SectionDivider({required this.label, required this.kredit, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : kredit.textTertiary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(KreditSpacing.card, 20, KreditSpacing.card, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: KreditTextSize.caption,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final KreditColors kredit;
  const _Divider(this.kredit);

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: KreditSpacing.card + KreditIconSize.small + 16,
      endIndent: KreditSpacing.card,
      color: kredit.borderCard,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showChevron;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: KreditSpacing.card, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: KreditIconSize.small, color: kredit.textSecondary),
              const SizedBox(width: 16),
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
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                          fontSize: KreditTextSize.caption,
                          color: kredit.textTertiary),
                    ),
                  ],
                ),
              ),
              if (showChevron)
                Icon(Icons.chevron_right,
                    size: KreditIconSize.small, color: kredit.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  final String text;
  final KreditColors kredit;
  const _SheetTitle(this.text, this.kredit);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: KreditTextSize.heading,
          fontWeight: FontWeight.w700,
          color: kredit.textPrimary,
        ),
      );
}

class _SheetLabel extends StatelessWidget {
  final String text;
  final KreditColors kredit;
  const _SheetLabel(this.text, this.kredit);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: KreditTextSize.caption,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: kredit.textTertiary,
        ),
      );
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
