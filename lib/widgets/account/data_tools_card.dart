import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/credit.dart';
import '../../domain/export_import.dart';
import '../../providers/credits_provider.dart';
import '../../theme/app_theme.dart';
import 'shadowed_card.dart';

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

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final credits = ref.read(creditsProvider).value ?? [];
      final json = exportStateToJson(credits);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/kredit_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(json);
      await Share.shareXFiles([XFile(file.path)], text: 'Respaldo de Kredit');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo exportar: $e')),
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo leer el archivo: $e')),
        );
      }
      return;
    }

    List<Credit> imported;
    try {
      imported = importStateFromJson(content);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Archivo inválido: $e')),
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
          FilledButton(
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo importar: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return ShadowedCard(
      child: Padding(
        padding: const EdgeInsets.all(KreditSpacing.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tus datos viven solo en este dispositivo. Puedes respaldarlos '
              'o restaurarlos en cualquier momento.',
              style: TextStyle(fontSize: 12, color: kredit.textTertiary),
            ),
            const SizedBox(height: KreditSpacing.tile),
            _DataToolOption(
              icon: Icons.upload_file_outlined,
              title: 'Exportar datos',
              subtitle: 'Guarda un respaldo JSON de todos tus créditos',
              tag: 'No modifica nada',
              onTap: () => _exportData(context, ref),
            ),
            const SizedBox(height: 8),
            _DataToolOption(
              icon: Icons.download_outlined,
              title: 'Importar datos',
              subtitle: 'Carga un respaldo JSON y reemplaza tus datos actuales',
              tag: 'Reemplaza tus datos',
              tagIsWarning: true,
              onTap: () => _importData(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single selectable-looking (but non-selection) action row: icon + title +
/// explanatory subtitle + a small tag calling out whether the action is
/// inert ("No modifica nada") or destructive to existing local data
/// ("Reemplaza tus datos") — the visual cue `data_tools_card.dart` lacked
/// before this rework, distinct from (and one step less severe than) the
/// full red-bordered treatment `danger_zone_card.dart` uses for permanent
/// deletion.
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
    final tagColor = tagIsWarning ? kredit.textPrimary : kredit.textTertiary;
    return InkWell(
      borderRadius: BorderRadius.circular(KreditRadius.tile),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(KreditSpacing.tile),
        decoration: BoxDecoration(
          color: kredit.bgSecondary,
          borderRadius: BorderRadius.circular(KreditRadius.tile),
          border: Border.all(color: kredit.borderCard),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: kredit.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: kredit.textPrimary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: kredit.textSecondary)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: tagColor.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(KreditRadius.chip),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: tagColor),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: kredit.textTertiary),
          ],
        ),
      ),
    );
  }
}
