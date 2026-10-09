import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/backup_detector_service.dart';

final backupDetectorProvider = FutureProvider<List<BackupInfo>>((ref) async {
  return BackupDetectorService().findAvailableBackups();
});
