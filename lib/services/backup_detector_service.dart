import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/export_import.dart';
import 'backup_service.dart';

/// Metadata about a discovered backup file on disk.
class BackupInfo {
  final String path;
  final DateTime date;
  final int creditCount;
  final bool isAuto;

  const BackupInfo({
    required this.path,
    required this.date,
    required this.creditCount,
    required this.isAuto,
  });

  String get label => isAuto ? 'Automático' : 'Manual';
}

/// Scans known backup locations and returns usable Kredit backup files.
///
/// Tolerance: fields added in schema v12 (e.g. notificationDaysBefore,
/// categoria) are nullable — importStateFromJson reads them with `as int?`
/// / `as String?` so older backups that lack them just get null defaults,
/// which is safe and means no data loss on restore.
class BackupDetectorService {
  /// Returns all valid backups found, sorted by date descending (newest first).
  Future<List<BackupInfo>> findAvailableBackups() async {
    final results = <BackupInfo>[];

    // 1. App documents dir — some exports end up here via share_plus temp
    try {
      final appDocs = await getApplicationDocumentsDirectory();
      await _scanDir(appDocs, isAuto: false, results: results);
    } catch (_) {}

    // 2. Kredit/backups/ in external storage (auto-backup default path)
    try {
      final dir = await _getAutoBackupDir();
      if (dir != null && await dir.exists()) {
        await _scanDir(dir, isAuto: true, results: results);
      }
    } catch (_) {}

    // 3. Custom path if set
    try {
      final prefs = await SharedPreferences.getInstance();
      final custom = prefs.getString(kBackupCustomPathPref);
      if (custom != null && custom.isNotEmpty) {
        final customDir = Directory('$custom/Kredit/backups');
        if (await customDir.exists()) {
          await _scanDir(customDir, isAuto: true, results: results);
        }
      }
    } catch (_) {}

    // Deduplicate by path and sort newest first
    final seen = <String>{};
    final unique = results.where((b) => seen.add(b.path)).toList();
    unique.sort((a, b) => b.date.compareTo(a.date));
    return unique;
  }

  Future<ImportedBackup> loadBackup(String path) async {
    final content = await File(path).readAsString();
    return importStateFromJson(content);
  }

  Future<void> _scanDir(
    Directory dir, {
    required bool isAuto,
    required List<BackupInfo> results,
  }) async {
    final entities = await dir.list().toList();
    for (final entity in entities) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last.toLowerCase();
      if (!name.endsWith('.json')) continue;
      if (!name.contains('kredit') && !name.contains('backup') && !name.contains('respaldo')) continue;
      try {
        final content = await entity.readAsString();
        final imported = importStateFromJson(content);
        final stat = await entity.stat();
        // Prefer exportedAt from envelope, fall back to file modification time
        final decoded = _tryDecodeDate(content) ?? stat.modified;
        results.add(BackupInfo(
          path: entity.path,
          date: decoded,
          creditCount: imported.credits.length,
          isAuto: isAuto,
        ));
      } catch (_) {
        // Not a valid Kredit backup — skip
      }
    }
  }

  DateTime? _tryDecodeDate(String json) {
    try {
      final idx = json.indexOf('"exportedAt"');
      if (idx == -1) return null;
      final start = json.indexOf('"', idx + 12) + 1;
      final end = json.indexOf('"', start);
      return DateTime.tryParse(json.substring(start, end));
    } catch (_) {
      return null;
    }
  }

  Future<Directory?> _getAutoBackupDir() async {
    if (!Platform.isAndroid) return null;
    final externalDir = await getExternalStorageDirectory();
    if (externalDir == null) return null;
    final storageRoot = externalDir.parent.parent.parent.parent;
    return Directory('${storageRoot.path}/Kredit/backups');
  }
}
