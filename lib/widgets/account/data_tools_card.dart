import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/credit.dart';
import '../../domain/date_utils.dart';
import '../../domain/export_import.dart';
import '../../providers/credits_provider.dart';
import '../../providers/last_backup_provider.dart';
import '../../theme/app_theme.dart';

/// Exportar/Importar datos card. Restructured (visual-only, same
/// export/import actions and callbacks) as two explicit, self-contained
/// option rows with an icon, a "reversible" cue and a one-line explainer
/// each — instead of a bare two-`ListTile` stack that gave "importar"
/// (which replaces all local data) the same visual weight as "exportar"
/// (which is fully safe). Mirrors the option-row language used by
/// `notification_settings_tile.dart`'s `_FrequencyOption`, kept local here
/// since the two aren't quite the same shape (no "selected" state).
class DataToolsCard extends ConsumerWidget {
  const DataToolsCard({super.key});

  /// Warns before sharing the plain-text backup: the JSON contains full
  /// financial details (amounts, rates, credit names) unencrypted, and the
  /// export flow hands it straight to the OS share sheet, so this is the
  /// only checkpoint before it could end up in a chat, email, etc.
  Future<bool> _confirmUnencryptedShare(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Compartir respaldo sin cifrar'),
        content: const Text(
          'Este archivo contiene tus datos financieros completos sin cifrar '
          '(montos, tasas, nombres de crédito). Solo compártelo por canales '
          'que confíes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final confirmed = await _confirmUnencryptedShare(context);
    if (!confirmed) return;
    if (!context.mounted) return;
    try {
      final credits = ref.read(creditsProvider).value ?? [];
      final json = exportStateToJson(credits);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/kredit_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(json);
      await Share.shareXFiles([XFile(file.path)], text: 'Respaldo de Kredit');
      await ref.read(lastBackupProvider.notifier).markBackedUpNow();
    } catch (e) {
      debugPrint('exportData failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo exportar el respaldo.')),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
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

    List<Credit> imported;
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar datos'),
        content: Text(
          'Se encontraron ${imported.length} créditos en el archivo. Esto '
          'reemplazará TODOS tus datos actuales. ¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reemplazar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(creditsProvider.notifier).replaceAll(imported);
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
  Widget build(BuildContext context, WidgetRef ref) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final lastBackup = ref.watch(lastBackupProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tus datos viven solo en este dispositivo. Puedes respaldarlos '
          'o restaurarlos en cualquier momento.',
          style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
        ),
        const SizedBox(height: 6),
        Text(
          lastBackup == null
              ? 'Aun no has hecho un respaldo.'
              : 'Ultimo respaldo: ${formatDate(toDateStr(lastBackup))}.',
          style: TextStyle(
            fontSize: KreditTextSize.caption,
            fontWeight: FontWeight.w600,
            color: lastBackup == null ? kredit.textTertiary : kredit.success,
          ),
        ),
        const SizedBox(height: 12),
        _DataToolOption(
          icon: Icons.upload_file_outlined,
          title: 'Exportar datos',
          subtitle: 'Guarda un respaldo JSON de todos tus créditos',
          tag: 'No modifica nada',
          onTap: () => _exportData(context, ref),
        ),
        Divider(height: 16, color: kredit.borderCard),
        _DataToolOption(
          icon: Icons.download_outlined,
          title: 'Importar datos',
          subtitle: 'Carga un respaldo JSON y reemplaza tus datos actuales',
          tag: 'Reemplaza tus datos',
          tagIsWarning: true,
          onTap: () => _importData(context, ref),
        ),
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
                    style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textSecondary),
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
                        fontSize: KreditTextSize.caption,
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
