import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted preference for local due-date notifications: whether they're
/// enabled at all, how many days before a due date to warn the user, at
/// what time of day, and whether to repeat the reminder every day in that
/// window (instead of a single one-shot notification on day `daysBefore`).
/// Follows the same `shared_preferences`-backed `StateNotifier` pattern as
/// `theme_provider.dart`'s `ThemePreferencesNotifier`.
class NotificationSettings {
  final bool enabled;
  final int daysBefore;
  final TimeOfDay reminderTime;
  final bool repeatDaily;

  const NotificationSettings({
    required this.enabled,
    required this.daysBefore,
    required this.reminderTime,
    required this.repeatDaily,
  });

  NotificationSettings copyWith({
    bool? enabled,
    int? daysBefore,
    TimeOfDay? reminderTime,
    bool? repeatDaily,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      daysBefore: daysBefore ?? this.daysBefore,
      reminderTime: reminderTime ?? this.reminderTime,
      repeatDaily: repeatDaily ?? this.repeatDaily,
    );
  }

  static const defaults = NotificationSettings(
    enabled: true,
    daysBefore: 3,
    reminderTime: TimeOfDay(hour: 9, minute: 0),
    repeatDaily: false,
  );
}

const _kEnabledKey = 'pref_notifications_enabled';
const _kDaysBeforeKey = 'pref_notifications_days_before';
const _kReminderHourKey = 'pref_notifications_hour';
const _kReminderMinuteKey = 'pref_notifications_minute';
const _kRepeatDailyKey = 'pref_notifications_repeat_daily';

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier() : super(NotificationSettings.defaults) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_kEnabledKey);
    final daysBefore = prefs.getInt(_kDaysBeforeKey);
    final hour = prefs.getInt(_kReminderHourKey);
    final minute = prefs.getInt(_kReminderMinuteKey);
    final repeatDaily = prefs.getBool(_kRepeatDailyKey);
    state = NotificationSettings(
      enabled: enabled ?? NotificationSettings.defaults.enabled,
      daysBefore: daysBefore ?? NotificationSettings.defaults.daysBefore,
      reminderTime: (hour != null && minute != null)
          ? TimeOfDay(hour: hour, minute: minute)
          : NotificationSettings.defaults.reminderTime,
      repeatDaily: repeatDaily ?? NotificationSettings.defaults.repeatDaily,
    );
  }

  Future<void> setEnabled(bool value) async {
    state = state.copyWith(enabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabledKey, value);
  }

  Future<void> setDaysBefore(int days) async {
    final clamped = days.clamp(1, 7);
    state = state.copyWith(daysBefore: clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kDaysBeforeKey, clamped);
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    state = state.copyWith(reminderTime: time);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kReminderHourKey, time.hour);
    await prefs.setInt(_kReminderMinuteKey, time.minute);
  }

  Future<void> setRepeatDaily(bool value) async {
    state = state.copyWith(repeatDaily: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRepeatDailyKey, value);
  }
}

final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
  (ref) => NotificationSettingsNotifier(),
);
