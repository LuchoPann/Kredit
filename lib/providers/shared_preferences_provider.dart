import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pre-loaded in main() and injected via ProviderScope.overrides so that
/// providers that need SharedPreferences never have to await getInstance()
/// during the first frame — eliminating the black-screen flash on startup.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);
