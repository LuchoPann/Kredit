import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shared_preferences_provider.dart';

const _kOnboardingShownKey = 'onboarding_shown';

/// Synchronous — SharedPreferences is pre-loaded in main() so build() never
/// suspends and onboardingProvider.isLoading is never true.
class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.read(sharedPreferencesProvider).getBool(_kOnboardingShownKey) ?? false;
  }

  Future<void> markShown() async {
    state = true;
    await ref.read(sharedPreferencesProvider).setBool(_kOnboardingShownKey, true);
  }
}

final onboardingProvider = NotifierProvider<OnboardingNotifier, bool>(
  OnboardingNotifier.new,
);
