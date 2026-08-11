import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the first-run "Welcome to Kredit" onboarding screen has
/// already been shown. Persisted via `shared_preferences`, following the
/// same pattern as `theme_provider.dart` / `notification_settings_provider.dart`
/// / `app_lock_provider.dart`. Defaults to `false` (not shown yet) until
/// `_load()` resolves, then reflects the persisted flag.
const _kOnboardingShownKey = 'onboarding_shown';

class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_kOnboardingShownKey) ?? false;
  }

  Future<void> markShown() async {
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingShownKey, true);
  }
}

/// `true` once the welcome/onboarding screen has been shown and dismissed
/// (or on a prior run). See `main.dart`'s `AppLockGate` for how this gates
/// showing `WelcomeScreen` vs `RootScaffold`.
final onboardingProvider = StateNotifierProvider<OnboardingNotifier, bool>(
  (ref) => OnboardingNotifier(),
);
