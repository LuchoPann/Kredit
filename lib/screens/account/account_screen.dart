import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
              background: const _ProfileBanner(),
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
                const _VersionTile(),

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

class _ProfileBanner extends ConsumerWidget {
  const _ProfileBanner();

  Future<void> _pickImage(BuildContext context, WidgetRef ref, ImageSource source) async {
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(
        source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85,
      );
      if (picked == null) return;
      if (!context.mounted) return;
      final accent = Theme.of(context).colorScheme.primary;
      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recortar foto',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: accent,
            lockAspectRatio: true,
          ),
          IOSUiSettings(title: 'Recortar foto', aspectRatioLockEnabled: true),
        ],
      );
      if (cropped == null) return;
      await ref.read(themePreferencesProvider.notifier).setAvatarFromFile(cropped.path);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo cargar la imagen.')),
        );
      }
    }
  }

  Future<void> _showAvatarOptions(BuildContext context, WidgetRef ref, bool hasAvatar) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de galería'),
              onTap: () { Navigator.pop(ctx); _pickImage(context, ref, ImageSource.gallery); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () { Navigator.pop(ctx); _pickImage(context, ref, ImageSource.camera); },
            ),
            if (hasAvatar)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                title: const Text('Quitar imagen', style: TextStyle(color: AppColors.danger)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref.read(themePreferencesProvider.notifier).clearAvatar();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editName(BuildContext context, WidgetRef ref, String current) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar nombre de perfil'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Tu nombre'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Guardar')),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      await ref.read(themePreferencesProvider.notifier).setProfileName(result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(themePreferencesProvider);
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    final avatarPath = prefs.avatarPath;
    final effectiveAvatarBg = applyBgToneToAccent(
      resolveEffectiveAccent(prefs.accentColor, prefs.isDarkMode),
      prefs.bgTone,
      prefs.isDarkMode,
    );

    return Container(
      color: kredit.bgCard,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showAvatarOptions(context, ref, avatarPath != null),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: effectiveAvatarBg,
                    backgroundImage: avatarPath != null ? FileImage(File(avatarPath)) : null,
                    child: avatarPath == null
                        ? Icon(Icons.person_outline_rounded,
                            size: 44, color: legibleForegroundOn(effectiveAvatarBg))
                        : null,
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: kredit.bgCard, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_outlined, size: 14, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _editName(context, ref, prefs.profileName),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    prefs.profileName.isNotEmpty ? prefs.profileName : 'Mi perfil',
                    style: TextStyle(
                      fontSize: KreditTextSize.heading,
                      fontWeight: FontWeight.w700,
                      color: kredit.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.edit_outlined, size: 14, color: kredit.textTertiary),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Kredit · Mis créditos',
              style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
            ),
            const SizedBox(height: 8),
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

class _VersionTile extends StatefulWidget {
  const _VersionTile();

  @override
  State<_VersionTile> createState() => _VersionTileState();
}

class _VersionTileState extends State<_VersionTile> {
  String _version = '…';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = '${info.version} (build ${info.buildNumber})');
    });
  }

  @override
  Widget build(BuildContext context) => _SettingsTile(
        icon: Icons.tag_rounded,
        title: 'Versión',
        subtitle: _version,
        showChevron: false,
        onTap: () {},
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
