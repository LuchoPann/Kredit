import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'last_backup_at';

/// Persisted timestamp (ISO 8601 string) of the last successful export, or
/// null if the user has never exported. Read once on startup (mirrors
/// `notification_settings_provider.dart`'s load-then-hold pattern) and
/// updated by `DataToolsCard` right after a successful `Share.shareXFiles`
/// call — Tarea 4 del roadmap ("mostrar ultimo respaldo").
class LastBackupNotifier extends StateNotifier<DateTime?> {
  LastBackupNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) state = DateTime.tryParse(raw);
  }

  Future<void> markBackedUpNow() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, now.toIso8601String());
    state = now;
  }
}

final lastBackupProvider =
    StateNotifierProvider<LastBackupNotifier, DateTime?>(
  (ref) => LastBackupNotifier(),
);
