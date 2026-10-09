import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/backup_detector_provider.dart';
import '../providers/credits_provider.dart';
import '../services/backup_detector_service.dart';
import '../theme/app_theme.dart';

/// Opens the backup restore bottom sheet.
///
/// [onlyIfEmpty]: when true (startup auto-check), only shows the sheet if
/// the app currently has 0 credits. When false (manual trigger), always shows.
Future<void> showBackupRestoreSheet(
  BuildContext context,
  WidgetRef ref, {
  bool onlyIfEmpty = false,
}) async {
  final backups = await BackupDetectorService().findAvailableBackups();
  if (backups.isEmpty) {
    if (!onlyIfEmpty && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontraron respaldos en el dispositivo.')),
      );
    }
    return;
  }

  if (onlyIfEmpty) {
    final credits = ref.read(creditsProvider).value ?? [];
    if (credits.isNotEmpty) return;
  }

  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => ProviderScope(
      parent: ProviderScope.containerOf(context),
      child: _BackupRestoreSheet(backups: backups),
    ),
  );
}

class _BackupRestoreSheet extends ConsumerStatefulWidget {
  final List<BackupInfo> backups;
  const _BackupRestoreSheet({required this.backups});

  @override
  ConsumerState<_BackupRestoreSheet> createState() => _BackupRestoreSheetState();
}

class _BackupRestoreSheetState extends ConsumerState<_BackupRestoreSheet> {
  BackupInfo? _selected;
  bool _loading = false;

  String _fmtDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays == 1) return 'Ayer, ${DateFormat('HH:mm').format(dt)}';
    return DateFormat('d MMM y · HH:mm', 'es').format(dt);
  }

  Future<void> _restore(BackupInfo info) async {
    setState(() => _loading = true);
    try {
      final imported = await BackupDetectorService().loadBackup(info.path);
      await ref.read(creditsProvider.notifier).replaceAll(
            imported.credits,
            newQuotas: imported.quotas,
          );
      if (mounted) {
        ref.invalidate(backupDetectorProvider);
        Navigator.of(context).pop();
        final n = imported.credits.length;
        final q = imported.quotas.length;
        final msg = StringBuffer('Datos restaurados: $n crédito${n == 1 ? '' : 's'}');
        if (q > 0) {
          msg.write(', $q cupo${q == 1 ? '' : 's'} de tienda');
        } else {
          // Check if any credit had a quotaId — backup predates cupos feature
          final hadQuotas = imported.credits.any((c) => c.quotaId != null);
          if (hadQuotas) {
            msg.write('. Los cupos de tienda no estaban en este respaldo — créalos de nuevo');
          }
        }
        msg.write('.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg.toString()),
            duration: Duration(seconds: q == 0 && imported.credits.any((c) => c.quotaId != null) ? 6 : 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo restaurar el respaldo.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final single = widget.backups.length == 1;
    final toRestore = single ? widget.backups.first : _selected;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: kredit.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kredit.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(KreditRadius.chip),
                ),
                child: Icon(Icons.cloud_done_outlined, color: kredit.success, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      single ? 'Se encontró un respaldo' : 'Se encontraron ${widget.backups.length} respaldos',
                      style: TextStyle(
                        fontSize: KreditTextSize.heading,
                        fontWeight: FontWeight.w700,
                        color: kredit.textPrimary,
                      ),
                    ),
                    Text(
                      single
                          ? '¿Deseas restaurar tus datos desde este respaldo?'
                          : 'Elige el respaldo que quieres usar',
                      style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Single backup: compact card
          if (single) ...[
            _BackupCard(
              info: widget.backups.first,
              selected: true,
              fmtDate: _fmtDate,
              onTap: null,
              kredit: kredit,
            ),
          ],

          // Multiple backups: radio list
          if (!single) ...[
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.38,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.backups.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final info = widget.backups[i];
                  return _BackupCard(
                    info: info,
                    selected: _selected == info,
                    fmtDate: _fmtDate,
                    onTap: () => setState(() => _selected = info),
                    kredit: kredit,
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _loading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Ignorar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: (_loading || toRestore == null)
                      ? null
                      : () => _restore(toRestore),
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.restore_outlined),
                  label: Text(single ? 'Restaurar' : 'Restaurar seleccionado'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BackupCard extends StatelessWidget {
  final BackupInfo info;
  final bool selected;
  final String Function(DateTime) fmtDate;
  final VoidCallback? onTap;
  final KreditColors kredit;

  const _BackupCard({
    required this.info,
    required this.selected,
    required this.fmtDate,
    required this.onTap,
    required this.kredit,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final borderColor = selected
        ? accent
        : kredit.borderCard;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.07) : Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(KreditRadius.tile),
          border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            if (onTap != null) ...[
              Radio<bool>(
                value: true,
                groupValue: selected,
                onChanged: (_) => onTap?.call(),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 4),
            ],
            Icon(
              info.isAuto ? Icons.cloud_sync_outlined : Icons.save_outlined,
              size: KreditIconSize.small,
              color: info.isAuto ? kredit.success : accent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        info.label,
                        style: TextStyle(
                          fontSize: KreditTextSize.body,
                          fontWeight: FontWeight.w700,
                          color: kredit.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: kredit.textTertiary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(KreditRadius.chip),
                        ),
                        child: Text(
                          '${info.creditCount} crédito${info.creditCount == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: KreditTextSize.caption,
                            color: kredit.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fmtDate(info.date),
                    style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
