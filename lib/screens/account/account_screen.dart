import 'dart:io';

import 'package:flutter/material.dart';
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
import '../../widgets/security_settings_tile.dart';
import 'backup_settings_screen.dart';
import 'how_it_works_screen.dart';
import '../../utils/nav_utils.dart';
import '../../widgets/kredit_bottom_dialogs.dart';

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
                              subtitle: 'Personaliza el aspecto visual de Kredit',
                            ),
                            const SizedBox(height: 24),
                            _SheetLabel('MODO DE PANTALLA', Theme.of(ctx).extension<KreditColors>()!),
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
                            _SheetLabel('COLOR DE ACENTO', Theme.of(ctx).extension<KreditColors>()!),
                            const SizedBox(height: 10),
                            const AccentColorPicker(),
                            const SizedBox(height: 24),
                            _SheetLabel('TONO DE FONDO', Theme.of(ctx).extension<KreditColors>()!),
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
                      final kredit2 = Theme.of(ctx).extension<KreditColors>()!;
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
                      final kredit2 = Theme.of(ctx).extension<KreditColors>()!;
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
                          const SecuritySettingsTile(),
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
                  title: 'Cómo funciona Kredit',
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
    final result = await showKreditInputSheet(
      context,
      title: 'Nombre de perfil',
      initialValue: current,
      hint: 'Tu nombre',
      confirmLabel: 'Guardar',
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Logo outline diagonal de fondo
          Positioned(
            right: -40,
            bottom: -20,
            child: Transform.rotate(
              angle: -0.47, // ~27 grados en radianes
              child: Opacity(
                opacity: 0.055,
                child: Image.asset(
                  'assets/icons/KREDIT_OUTLINE.png',
                  width: 260,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          SafeArea(
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
        ],
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

class _SheetHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _SheetHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: KreditTextSize.emphasis,
                  fontWeight: FontWeight.w800,
                  color: kredit.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: KreditTextSize.caption,
                  color: kredit.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    return Material(
      color: kredit.bgCard,
      borderRadius: BorderRadius.circular(KreditRadius.tile),
      child: InkWell(
        borderRadius: BorderRadius.circular(KreditRadius.tile),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 12),
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
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: KreditTextSize.caption,
                        color: kredit.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: KreditIconSize.small, color: kredit.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.10) : kredit.bgCard,
          borderRadius: BorderRadius.circular(KreditRadius.tile),
          border: Border.all(
            color: selected ? accent : kredit.borderCard,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 26,
              color: selected ? accent : kredit.textSecondary,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: KreditTextSize.body,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? accent : kredit.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
      if (mounted) setState(() => _version = info.version.isNotEmpty ? info.version : changelog.first.version);
    }).catchError((_) {
      if (mounted) setState(() => _version = changelog.first.version);
    });
  }

  @override
  Widget build(BuildContext context) => _SettingsTile(
        icon: Icons.tag_rounded,
        title: 'Versión',
        subtitle: _version,
        showChevron: false,
        onTap: () => showWhatsNewSheet(context),
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
          slidePageRoute((_) => const BackupSettingsScreen()),
        );
        _loadSubtitle(); // refresh after returning
      },
    );
  }
}

// ── Navegación interna de sheets ─────────────────────────────────────────────

/// InheritedWidget que expone push/pop a cualquier descendiente del sheet.
class SheetNav extends InheritedWidget {
  final void Function(String title, Widget page) push;
  final VoidCallback pop;
  final bool canPop;

  const SheetNav({
    super.key,
    required this.push,
    required this.pop,
    required this.canPop,
    required super.child,
  });

  static SheetNav of(BuildContext context) {
    final nav = context.dependOnInheritedWidgetOfExactType<SheetNav>();
    assert(nav != null, 'SheetNav no encontrado en el árbol');
    return nav!;
  }

  @override
  bool updateShouldNotify(SheetNav old) =>
      canPop != old.canPop;
}

/// Host del sheet que gestiona la pila de páginas con slide lateral.
class SheetNavHost extends StatefulWidget {
  final ScrollController scrollController;
  final Widget rootContent;

  const SheetNavHost({
    super.key,
    required this.scrollController,
    required this.rootContent,
  });

  @override
  State<SheetNavHost> createState() => SheetNavHostState();
}

class SheetNavHostState extends State<SheetNavHost> {
  final List<({String title, Widget page})> _stack = [];
  int _direction = 1;

  void _push(String title, Widget page) {
    setState(() {
      _direction = 1;
      _stack.add((title: title, page: page));
    });
  }

  void _pop() {
    if (_stack.isEmpty) return;
    setState(() {
      _direction = -1;
      _stack.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final canPop = _stack.isNotEmpty;
    final currentTitle = canPop ? _stack.last.title : null;

    return SheetNav(
      push: _push,
      pop: _pop,
      canPop: canPop,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            children: [
              // Handle pill — siempre visible
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kredit.borderCard,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Barra de título / back cuando hay sub-página
              if (canPop)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                        onPressed: _pop,
                        tooltip: 'Volver',
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          currentTitle ?? '',
                          style: const TextStyle(
                            fontSize: KreditTextSize.heading,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Contenido animado
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  reverseDuration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final entering =
                        child.key == ValueKey(_stack.length);
                    final sign = entering ? _direction : -_direction;
                    final offset = Tween<Offset>(
                      begin: Offset(sign.toDouble(), 0),
                      end: Offset.zero,
                    ).animate(animation);
                    return SlideTransition(position: offset, child: child);
                  },
                  child: KeyedSubtree(
                    key: ValueKey(_stack.length),
                    child: ListView(
                      controller: canPop ? null : widget.scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      children: [
                        canPop ? _stack.last.page : widget.rootContent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
