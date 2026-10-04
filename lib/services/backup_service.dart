import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class BackupService {
  /// Ruta destino: /storage/emulated/0/Kredit/backups/
  /// Retorna null si no se otorga permiso o no hay almacenamiento externo.
  static Future<Directory?> getBackupDirectory() async {
    if (Platform.isAndroid) {
      bool granted = false;

      // Android 11+ (API 30+): MANAGE_EXTERNAL_STORAGE
      final manageStatus = await Permission.manageExternalStorage.status;
      if (manageStatus.isGranted) {
        granted = true;
      } else {
        final req = await Permission.manageExternalStorage.request();
        if (req.isGranted) {
          granted = true;
        } else {
          // Android < 10 fallback: WRITE_EXTERNAL_STORAGE
          final storageReq = await Permission.storage.request();
          granted = storageReq.isGranted;
        }
      }

      if (!granted) return null;
    }

    final externalDir = await getExternalStorageDirectory();
    if (externalDir == null) return null;

    // getExternalStorageDirectory() → /storage/emulated/0/Android/data/<pkg>/files
    // Subir 4 niveles para llegar a /storage/emulated/0
    final storageRoot = externalDir.parent.parent.parent.parent;
    final backupDir = Directory('${storageRoot.path}/Kredit/backups');
    await backupDir.create(recursive: true);
    return backupDir;
  }

  /// Guarda [json] en Kredit/backups/.
  /// [newFile]=true → kredit_backup_<timestamp>.json
  /// [newFile]=false → kredit_backup.json (sobreescribe)
  static Future<File?> saveBackup(String json, {bool newFile = false}) async {
    try {
      final dir = await getBackupDirectory();
      if (dir == null) return null;
      final name = newFile
          ? 'kredit_backup_${DateTime.now().millisecondsSinceEpoch}.json'
          : 'kredit_backup.json';
      final file = File('${dir.path}/$name');
      await file.writeAsString(json);
      return file;
    } catch (e) {
      debugPrint('BackupService.saveBackup failed: $e');
      return null;
    }
  }
}
