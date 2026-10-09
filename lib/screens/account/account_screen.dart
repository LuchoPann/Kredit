import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/changelog.dart';
import '../../providers/notification_settings_provider.dart';
import '../../widgets/whats_new_sheet.dart';
import '../../providers/theme_provider.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/account/accent_color_picker.dart';
import '../../widgets/account/bg_tone_picker.dart';
import '../../widgets/account/danger_zone_card.dart';
import '../../widgets/account/data_tools_card.dart';
import '../../widgets/notification_settings_tile.dart';
import 'backup_settings_screen.dart';
import 'how_it_works_screen.dart';
import '../lock/setup_lock_screen.dart';
import '../../providers/widget_privacy_provider.dart';
import '../../utils/nav_utils.dart';
import '../../widgets/kredit_bottom_dialogs.dart';

part 'account_screen_widgets.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  void _openSheet(BuildContext context, Widget content, {double initial = 0.6}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: initial,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (ctx, scrollController) => SheetNavHost(
          scrollController: scrollController,
          rootContent: content,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(themePreferencesProvider);
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
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
              background: const _ProfileBanner(),
              collapseMode: CollapseMode.parallax,
            ),
            title: Text(
              prefs.profileName.isNotEmpty ? prefs.profileName : 'Cuenta',
              style: const TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w700),
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
                    Consumer(
                      builder: (ctx, ref, _) {
                        final p = ref.watch(themePreferencesProvider);
                        final accent = Theme.of(ctx).colorScheme.primary;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SheetHeader(
                              icon: Icons.palette_outlined,
                              iconColor: accent,
                              title: 'Apariencia',
                              subtitle: 'Personaliza el aspecto visual de Krezium',
                            ),
                            const SizedBox(height: 24),
                            _SheetLabel('MODO DE PANTALLA', Theme.of(ctx).extension<AppThemeColors>()!),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _ModeOption(
                                    icon: Icons.light_mode_outlined,
                                    label: 'Claro',
                                    selected: !p.isDarkMode,
                                    onTap: () => ref.read(themePreferencesProvider.notifier).setIsDarkMode(false),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _ModeOption(
                                    icon: Icons.dark_mode_outlined,
                                    label: 'Oscuro',
                                    selected: p.isDarkMode,
                                    onTap: () => ref.read(themePreferencesProvider.notifier).setIsDarkMode(true),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _SheetLabel('COLOR DE ACENTO', Theme.of(ctx).extension<AppThemeColors>()!),
                            const SizedBox(height: 10),
                            const AccentColorPicker(),
                            const SizedBox(height: 24),
                            _SheetLabel('TONO DE FONDO', Theme.of(ctx).extension<AppThemeColors>()!),
                            const SizedBox(height: 10),
                            const BgTonePicker(),
                            const SizedBox(height: 8),
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
                    Consumer(builder: (ctx, ref2, _) {
                      final kredit2 = Theme.of(ctx).extension<AppThemeColors>()!;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SheetHeader(
                            icon: Icons.notifications_outlined,
                            iconColor: Colors.amber.shade600,
                            title: 'Notificaciones',
                            subtitle: 'Recordatorios automáticos de vencimiento',
                          ),
                          const SizedBox(height: 24),
                          _SheetLabel('RECORDATORIOS DE PAGO', kredit2),
                          const SizedBox(height: 10),
                          const NotificationSettingsTile(),
                          const SizedBox(height: 24),
                          _SheetLabel('PRUEBA', kredit2),
                          const SizedBox(height: 10),
                          _ActionTile(
                            icon: Icons.send_outlined,
                            title: 'Enviar notificación de prueba',
                            subtitle: 'Verifica que las alertas funcionan',
                            onTap: () async {
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
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    }),
                    initial: 0.65,
                  ),
                ),
                _Divider(kredit),
                _SettingsTile(
                  icon: Icons.storage_outlined,
                  title: 'Datos y respaldos',
                  subtitle: 'Exportar, importar y respaldo automático',
                  onTap: () => _openSheet(
                    context,
                    Consumer(builder: (ctx, ref2, _) {
                      final accent = Theme.of(ctx).colorScheme.primary;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SheetHeader(
                            icon: Icons.storage_outlined,
                            iconColor: accent,
                            title: 'Datos y respaldos',
                            subtitle: 'Tus datos viven solo en este dispositivo',
                          ),
                          const SizedBox(height: 16),
                          const DataToolsCard(),
                          const SizedBox(height: 8),
                        ],
                      );
                    }),
                    initial: 0.75,
                  ),
                ),
                _Divider(kredit),
                _SettingsTile(
                  icon: Icons.lock_outline,
                  title: 'Seguridad',
                  subtitle: 'Bloqueo con PIN o biometría',
                  onTap: () => _openSheet(
                    context,
                    Consumer(builder: (ctx, ref2, _) {
                      final kredit2 = Theme.of(ctx).extension<AppThemeColors>()!;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SheetHeader(
                            icon: Icons.lock_outline,
                            iconColor: Colors.orange,
                            title: 'Seguridad',
                            subtitle: 'Protege el acceso a tus datos financieros',
                          ),
                          const SizedBox(height: 24),
                          _SheetLabel('BLOQUEO DE APP', kredit2),
                          const SizedBox(height: 10),
                          const SetupLockBody(),
                          const SizedBox(height: 16),
                          _SheetLabel('WIDGET', kredit2),
                          const SizedBox(height: 4),
                          Builder(builder: (ctx2) {
                            final showAmounts = ref2.watch(widgetPrivacyProvider);
                            return SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              secondary: Icon(
                                showAmounts
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: kredit2.textSecondary,
                              ),
                              title: const Text('Mostrar montos en el widget'),
                              subtitle: const Text(
                                'El widget de pantalla de inicio es visible sin desbloquear la app. '
                                'Desactivado, muestra solo texto genérico sin cifras.',
                              ),
                              value: showAmounts,
                              onChanged: (v) =>
                                  ref2.read(widgetPrivacyProvider.notifier).setShowAmounts(v),
                            );
                          }),
                          const SizedBox(height: 8),
                        ],
                      );
                    }),
                  ),
                ),

                // ── INFORMACIÓN ──
                _SectionDivider(label: 'Información', kredit: kredit),
                _SettingsTile(
                  icon: Icons.help_outline,
                  title: 'Cómo funciona Krezium',
                  subtitle: 'Guía rápida de la app',
                  onTap: () => Navigator.of(context).push(
                    slidePageRoute((_) => const HowItWorksScreen()),
                  ),
                ),
                _Divider(kredit),
                const _VersionTile(),

                // ── ZONA DE RIESGO ──
                _SectionDivider(label: 'Zona de riesgo', kredit: kredit, danger: true),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.card, vertical: 4),
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

