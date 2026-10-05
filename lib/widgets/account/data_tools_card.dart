import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/date_utils.dart';
import '../../domain/export_import.dart';
import '../../providers/commercial_quotas_provider.dart';
import '../../providers/credits_provider.dart';
import '../../providers/last_backup_provider.dart';
import '../../services/backup_service.dart';
import '../kredit_bottom_dialogs.dart';
import '../../theme/app_theme.dart';

/// Exportar/Importar datos card. Restructured (visual-only, same
/// export/import actions and callbacks) as two explicit, self-contained
/// option rows with an icon, a "reversible" cue and a one-line explainer
/// each — instead of a bare two-`ListTile` stack that gave "importar"
/// (which replaces all local data) the same visual weight as "exportar"
/// (which is fully safe). Mirrors the option-row language used by
/// `notification_settings_tile.dart`'s `_FrequencyOption`, kept local here
/// since the two aren't quite the same shape (no "selected" state).
class DataToolsCard extends ConsumerStatefulWidget {
  const DataToolsCard({super.key});

  @override
  ConsumerState<DataToolsCard> createState() => _DataToolsCardState();
}

class _DataToolsCardState extends ConsumerState<DataToolsCard> {
  bool _autoBackupEnabled = false;
  String _autoFrequency = 'weekly';

  @override
  void initState() {
    super.initState();
    _loadAutoBackupPrefs();
  }

  Future<void> _loadAutoBackupPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _autoBackupEnabled = prefs.getBool('backup_enabled') ?? false;
        _autoFrequency = prefs.getString('backup_frequency') ?? 'weekly';
      });
    }
  }

  Future<void> _toggleAutoBackup(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('backup_enabled', value);
    if (mounted) setState(() => _autoBackupEnabled = value);
  }

  String get _frequencyLabel => switch (_autoFrequency) {
        'daily' => 'diario',
        'biweekly' => 'quincenal',
        'monthly' => 'mensual',
        _ => 'semanal',
      };

  /// Warns before sharing the plain-text backup: the JSON contains full
  /// financial details (amounts, rates, credit names) unencrypted, and the
  /// export flow hands it straight to the OS share sheet, so this is the
  /// only checkpoint before it could end up in a chat, email, etc.
  Future<bool> _confirmUnencryptedShare() async {
    return showKreditConfirmSheet(
      context,
      title: 'Compartir respaldo sin cifrar',
      message: 'Este archivo contiene tus datos financieros completos sin cifrar (montos, tasas, nombres de crédito). Solo compártelo por canales que confíes.',
      confirmLabel: 'Continuar',
      isDanger: false,
      icon: Icons.lock_open_outlined,
    );
  }

  Future<void> _exportData() async {
    final confirmed = await _confirmUnencryptedShare();
    if (!confirmed) return;
    if (!mounted) return;
    try {
      final credits = ref.read(creditsProvider).value ?? [];
      final quotas = ref.read(commercialQuotasProvider).value ?? [];
      final json = exportStateToJson(credits, quotas);

      // Intentar guardar en Kredit/backups/ (almacenamiento principal)
      File? savedFile = await BackupService.saveBackup(json, newFile: true);

      if (savedFile != null) {
        await ref.read(lastBackupProvider.notifier).markBackedUpNow();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Respaldo guardado en Kredit/backups/${savedFile.uri.pathSegments.last}'),
              action: SnackBarAction(
                label: 'Compartir',
                onPressed: () => Share.shareXFiles([XFile(savedFile.path)], text: 'Respaldo de Kredit'),
              ),
            ),
          );
        }
      } else {
        // Fallback: share vía hoja de compartir si no hay permiso de almacenamiento
        final dir = await getTemporaryDirectory();
        final tempFile = File('${dir.path}/kredit_backup_${DateTime.now().millisecondsSinceEpoch}.json');
        await tempFile.writeAsString(json);
        await Share.shareXFiles([XFile(tempFile.path)], text: 'Respaldo de Kredit');
        await ref.read(lastBackupProvider.notifier).markBackedUpNow();
      }
    } catch (e) {
      debugPrint('exportData failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo exportar el respaldo.')),
        );
      }
    }
  }

  Future<void> _importData() async {
    String content;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) return;
      final file = File(result.files.single.path!);
      content = await file.readAsString();
    } catch (e) {
      debugPrint('importData read failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo leer el archivo.')),
        );
      }
      return;
    }

    ImportedBackup imported;
    try {
      imported = importStateFromJson(content);
    } catch (e) {
      debugPrint('importData parse failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El archivo no tiene un formato válido de respaldo.')),
        );
      }
      return;
    }

    if (!context.mounted) return;
    final confirmed = await showKreditConfirmSheet(
      context,
      title: 'Importar datos',
      message: 'Se encontraron ${imported.credits.length} créditos en el archivo. Esto reemplazará TODOS tus datos actuales. ¿Deseas continuar?',
      confirmLabel: 'Reemplazar',
      isDanger: true,
      icon: Icons.download_outlined,
    );
    if (confirmed == true) {
      try {
        await ref.read(creditsProvider.notifier).replaceAll(
              imported.credits,
              newQuotas: imported.quotas,
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Datos importados correctamente')),
          );
        }
      } catch (e) {
        debugPrint('importData replaceAll failed: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo importar el respaldo.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    final lastBackup = ref.watch(lastBackupProvider);
    final backupOk = lastBackup != null;

    // Color por antigüedad: verde <24h, ámbar <7d, rojo ≥7d
    Color statusColor;
    String statusLabel;
    if (!backupOk) {
      statusColor = AppColors.warning;
      statusLabel = 'Sin respaldo — se recomienda exportar una copia ahora.';
    } else {
      final age = DateTime.now().difference(lastBackup);
      if (age.inHours < 24) {
        statusColor = kredit.success;
        statusLabel = age.inHours < 1
            ? 'Último respaldo: hace menos de una hora.'
            : 'Último respaldo: hace ${age.inHours}h.';
      } else if (age.inDays < 7) {
        statusColor = AppColors.warning;
        statusLabel = 'Último respaldo: ${formatDate(toDateStr(lastBackup))}.';
      } else {
        statusColor = kredit.error;
        statusLabel = 'Último respaldo: ${formatDate(toDateStr(lastBackup))} — considera hacer uno nuevo.';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.cloud_sync_outlined, size: KreditIconSize.small, color: kredit.textTertiary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tus datos viven solo en este dispositivo. Expórtalos para hacer un respaldo o importa uno para restaurar.',
                style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Estado del respaldo con color semántico por antigüedad
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(KreditRadius.tile),
            border: Border.all(color: statusColor.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              Icon(
                backupOk ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                size: 15,
                color: statusColor,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  statusLabel,
                  style: TextStyle(fontSize: KreditTextSize.body, fontWeight: FontWeight.w600, color: statusColor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _DataToolOption(
          icon: Icons.upload_file_outlined,
          title: 'Exportar datos',
          subtitle: 'Guarda un respaldo JSON de todos tus créditos',
          tag: 'No modifica nada',
          onTap: _exportData,
        ),
        Divider(height: 16, color: kredit.borderCard),
        _DataToolOption(
          icon: Icons.download_outlined,
          title: 'Importar datos',
          subtitle: 'Carga un respaldo JSON y reemplaza tus datos actuales',
          tag: 'Reemplaza tus datos',
          tagIsWarning: true,
          onTap: _importData,
        ),
        Divider(height: 16, color: kredit.borderCard),
        // Respaldo automático inline con toggle
        Row(
          children: [
            Icon(
              Icons.backup_outlined,
              size: KreditIconSize.small,
              color: _autoBackupEnabled ? accent : kredit.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Respaldo automático',
                    style: TextStyle(
                      color: kredit.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: KreditTextSize.body,
                    ),
                  ),
                  Text(
                    _autoBackupEnabled
                        ? 'Activo · $_frequencyLabel · al abrir la app'
                        : 'Desactivado — solo respaldos manuales',
                    style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
                  ),
                ],
              ),
            ),
            Switch(
              value: _autoBackupEnabled,
              onChanged: _toggleAutoBackup,
            ),
          ],
        ),
        if (_autoBackupEnabled) ...[
          const SizedBox(height: 4),
          InkWell(
            borderRadius: BorderRadius.circular(KreditRadius.tile),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BackupSettingsScreen()),
              );
              _loadAutoBackupPrefs();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                children: [
                  Icon(Icons.settings_outlined, size: 16, color: kredit.textTertiary),
                  const SizedBox(width: 8),
                  Text(
                    'Configurar frecuencia, hora y carpeta',
                    style: TextStyle(fontSize: KreditTextSize.body, color: accent),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, size: KreditIconSize.small, color: kredit.textTertiary),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DataToolOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String tag;
  final bool tagIsWarning;
  final VoidCallback onTap;

  const _DataToolOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.onTap,
    this.tagIsWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final tagColor = tagIsWarning ? AppColors.warning : kredit.textTertiary;
    return InkWell(
      borderRadius: BorderRadius.circular(KreditRadius.tile),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: KreditIconSize.small, color: kredit.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: kredit.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: KreditTextSize.body,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: tagColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(KreditRadius.chip),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: KreditTextSize.body,
                        fontWeight: FontWeight.w600,
                        color: tagColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: KreditIconSize.small, color: kredit.textTertiary),
          ],
        ),
      ),
    );
  }
}
