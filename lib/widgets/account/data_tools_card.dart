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

class DataToolsCard extends ConsumerStatefulWidget {
  const DataToolsCard({super.key});

  @override
  ConsumerState<DataToolsCard> createState() => _DataToolsCardState();
}

class _DataToolsCardState extends ConsumerState<DataToolsCard> {
  bool _autoBackupEnabled = false;
  String _autoFrequency = 'weekly';
  int _hour = 8;
  int _minute = 0;
  String? _customPath;
  String _backupMode = 'append';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _autoBackupEnabled = prefs.getBool('backup_enabled') ?? false;
      _autoFrequency = prefs.getString('backup_frequency') ?? 'weekly';
      _hour = prefs.getInt('backup_hour') ?? 8;
      _minute = prefs.getInt('backup_minute') ?? 0;
      _customPath = prefs.getString('backup_custom_path');
      _backupMode = prefs.getString('backup_mode') ?? 'append';
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('backup_enabled', _autoBackupEnabled);
    await prefs.setString('backup_frequency', _autoFrequency);
    await prefs.setInt('backup_hour', _hour);
    await prefs.setInt('backup_minute', _minute);
    if (_customPath != null) {
      await prefs.setString('backup_custom_path', _customPath!);
    } else {
      await prefs.remove('backup_custom_path');
    }
    await prefs.setString('backup_mode', _backupMode);
  }

  String _nextBackupLabel() {
    final now = DateTime.now();
    DateTime next;
    switch (_autoFrequency) {
      case 'daily':
        next = DateTime(now.year, now.month, now.day + 1, _hour, _minute);
        break;
      case 'monthly':
        next = DateTime(now.year, now.month + 1, now.day, _hour, _minute);
        break;
      default: // weekly
        next = now.add(const Duration(days: 7));
        next = DateTime(next.year, next.month, next.day, _hour, _minute);
    }
    final diff = next.difference(now);
    final h = _hour.toString().padLeft(2, '0');
    final m = _minute.toString().padLeft(2, '0');
    if (diff.inHours < 24) return 'Hoy a las $h:$m';
    if (diff.inDays == 1) return 'Mañana a las $h:$m';
    return '${formatDate(toDateStr(next))} a las $h:$m';
  }

  Future<bool> _confirmUnencryptedShare() async {
    return showAppConfirmSheet(
      context,
      title: 'Compartir respaldo sin cifrar',
      message:
          'Este archivo contiene tus datos financieros completos sin cifrar (montos, tasas, nombres de crédito). Solo compártelo por canales que confíes.',
      confirmLabel: 'Continuar',
      isDanger: false,
      icon: Icons.lock_open_outlined,
    );
  }

  Future<void> _exportData() async {
    final confirmed = await _confirmUnencryptedShare();
    if (!confirmed || !mounted) return;
    try {
      final credits = ref.read(creditsProvider).value ?? [];
      final quotas = ref.read(commercialQuotasProvider).value ?? [];
      final json = exportStateToJson(credits, quotas);
      File? savedFile = await BackupService.saveBackup(json, newFile: true);
      if (savedFile != null) {
        await ref.read(lastBackupProvider.notifier).markBackedUpNow();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Respaldo guardado en Krezium/backups/${savedFile.uri.pathSegments.last}'),
              action: SnackBarAction(
                label: 'Compartir',
                onPressed: () =>
                    Share.shareXFiles([XFile(savedFile.path)], text: 'Respaldo de Krezium'),
              ),
            ),
          );
        }
      } else {
        final dir = await getTemporaryDirectory();
        final tempFile = File(
            '${dir.path}/kredit_backup_${DateTime.now().millisecondsSinceEpoch}.json');
        await tempFile.writeAsString(json);
        await Share.shareXFiles([XFile(tempFile.path)], text: 'Respaldo de Krezium');
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
      final result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result == null || result.files.single.path == null) return;
      content = await File(result.files.single.path!).readAsString();
    } catch (e) {
      if (mounted) {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El archivo no tiene un formato válido de respaldo.')),
        );
      }
      return;
    }
    if (!mounted) return;
    final confirmed = await showAppConfirmSheet(
      context,
      title: 'Importar datos',
      message:
          'Se encontraron ${imported.credits.length} créditos en el archivo. Esto reemplazará TODOS tus datos actuales. ¿Deseas continuar?',
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Datos importados correctamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo importar el respaldo.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    final lastBackup = ref.watch(lastBackupProvider);
    final backupOk = lastBackup != null;

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
        statusColor = kredit.danger;
        statusLabel =
            'Último respaldo: ${formatDate(toDateStr(lastBackup))} — considera hacer uno nuevo.';
      }
    }

    final h = _hour.toString().padLeft(2, '0');
    final m = _minute.toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Banner de estado ─────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.tile),
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
                  style: TextStyle(
                    fontSize: AppTextSize.body,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── RESPALDO AUTOMÁTICO ──────────────────────────────────────────
        Text(
          'RESPALDO AUTOMÁTICO',
          style: TextStyle(
            fontSize: AppTextSize.caption,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: kredit.textTertiary,
          ),
        ),
        const SizedBox(height: 6),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Activar respaldo automático',
            style: TextStyle(
              fontSize: AppTextSize.body,
              fontWeight: FontWeight.w600,
              color: kredit.textPrimary,
            ),
          ),
          subtitle: Text(
            _autoBackupEnabled ? 'Al abrir la app, según la frecuencia elegida' : 'Solo respaldos manuales',
            style: TextStyle(fontSize: AppTextSize.caption, color: kredit.textTertiary),
          ),
          value: _autoBackupEnabled,
          onChanged: (v) {
            setState(() => _autoBackupEnabled = v);
            _savePrefs();
          },
        ),
        if (_autoBackupEnabled) ...[
          const SizedBox(height: 4),
          // Frecuencia — SegmentedButton que ocupa todo el ancho
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'daily', label: Text('Diario')),
                ButtonSegment(value: 'weekly', label: Text('Semanal')),
                ButtonSegment(value: 'monthly', label: Text('Mensual')),
              ],
              selected: {_autoFrequency},
              onSelectionChanged: (s) {
                setState(() => _autoFrequency = s.first);
                _savePrefs();
              },
            ),
          ),
          const SizedBox(height: 4),
          // Hora del respaldo
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.schedule_outlined, size: AppIconSize.small, color: kredit.textTertiary),
            title: Text('Hora del respaldo',
                style: TextStyle(fontSize: AppTextSize.body, color: kredit.textPrimary)),
            trailing: Text('$h:$m',
                style: TextStyle(
                    fontSize: AppTextSize.body,
                    fontWeight: FontWeight.w700,
                    color: accent)),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: _hour, minute: _minute),
              );
              if (picked != null) {
                setState(() {
                  _hour = picked.hour;
                  _minute = picked.minute;
                });
                _savePrefs();
              }
            },
          ),
          // Próximo respaldo
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.event_outlined, size: AppIconSize.small, color: kredit.textTertiary),
            title: Text('Próximo respaldo',
                style: TextStyle(fontSize: AppTextSize.body, color: kredit.textPrimary)),
            subtitle: Text(_nextBackupLabel(),
                style: TextStyle(fontSize: AppTextSize.caption, color: kredit.textTertiary)),
          ),
        ],
        const SizedBox(height: 16),

        // ── CONFIGURACIÓN GENERAL ────────────────────────────────────────
        Text(
          'CONFIGURACIÓN',
          style: TextStyle(
            fontSize: AppTextSize.caption,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: kredit.textTertiary,
          ),
        ),
        const SizedBox(height: 6),
        // Carpeta de destino
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.folder_outlined, size: AppIconSize.small, color: kredit.textTertiary),
          title: Text('Carpeta de destino',
              style: TextStyle(fontSize: AppTextSize.body, color: kredit.textPrimary)),
          subtitle: Text(
            _customPath != null ? '$_customPath/Krezium/backups/' : 'Predeterminada: Krezium/backups/',
            style: TextStyle(fontSize: AppTextSize.caption, color: kredit.textTertiary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: _customPath != null
              ? IconButton(
                  icon: Icon(Icons.close, size: 16, color: kredit.textTertiary),
                  tooltip: 'Restablecer',
                  onPressed: () {
                    setState(() => _customPath = null);
                    _savePrefs();
                  },
                )
              : Icon(Icons.chevron_right, size: AppIconSize.small, color: kredit.textTertiary),
          onTap: () async {
            final path = await FilePicker.platform.getDirectoryPath();
            if (path != null) {
              setState(() => _customPath = path);
              _savePrefs();
            }
          },
        ),
        // Modo de archivo — SegmentedButton interactivo
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.file_copy_outlined,
                      size: AppIconSize.small, color: kredit.textTertiary),
                  const SizedBox(width: 8),
                  Text(
                    'Modo de archivo',
                    style: TextStyle(
                        fontSize: AppTextSize.body,
                        fontWeight: FontWeight.w600,
                        color: kredit.textPrimary),
                  ),
                  const Spacer(),
                  Text(
                    _backupMode == 'replace'
                        ? 'Sobreescribe el mismo'
                        : 'Uno por cada respaldo',
                    style: TextStyle(
                        fontSize: AppTextSize.caption,
                        color: kredit.textTertiary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'append',
                      label: Text('Por fecha'),
                      icon: Icon(Icons.calendar_today_outlined),
                    ),
                    ButtonSegment(
                      value: 'replace',
                      label: Text('Reemplazar'),
                      icon: Icon(Icons.sync_outlined),
                    ),
                  ],
                  selected: {_backupMode},
                  onSelectionChanged: (s) {
                    setState(() => _backupMode = s.first);
                    _savePrefs();
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Botones Importar (izq.) / Exportar (der.) ────────────────────
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _importData,
                icon: const Icon(Icons.download_outlined),
                label: const Text('Importar'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 50),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: _exportData,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Exportar'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 50),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
