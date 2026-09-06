import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the Android home screen widget (see
/// `lib/services/home_widget_service.dart` and
/// `android/.../KreditHomeWidgetProvider.kt`) is allowed to show real
/// amounts (total debt / next payment sum) on the lock screen / home
/// screen, which is visible WITHOUT unlocking the app — even when the user
/// has PIN/biometric app-lock enabled (see `security_settings_tile.dart`).
///
/// Defaults to `false` (privacy-by-default): the widget still updates, but
/// with generic, amount-free text until the user explicitly opts in.
///
/// Follows the same `shared_preferences`-backed `StateNotifier` pattern as
/// `theme_provider.dart` / `notification_settings_provider.dart`.
const _kShowAmountsInWidgetKey = 'pref_show_amounts_in_widget';

class WidgetPrivacyNotifier extends StateNotifier<bool> {
  WidgetPrivacyNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_kShowAmountsInWidgetKey) ?? false;
  }

  Future<void> setShowAmounts(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShowAmountsInWidgetKey, value);
  }
}

final widgetPrivacyProvider =
    StateNotifierProvider<WidgetPrivacyNotifier, bool>(
  (ref) => WidgetPrivacyNotifier(),
);
