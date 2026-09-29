import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../widgets/voucher_pattern.dart';
import 'shared_preferences_provider.dart';

/// Background tone options, ported from app.js's `data-bg-theme` values
/// (applyBgTheme ~L299-322) and the corresponding CSS variants in
/// style.css (~L36-46).
class BgTone {
  static const pure = 'pure';
  static const cool = 'cool';
  static const warm = 'warm';
}

/// Persisted user preferences for the "Cuenta"/settings screen: accent
/// color, profile name, and background tone.
///
/// Equivalent to the PWA's `localStorage`-backed prefs
/// (accentColor/profileName/bgTheme). Persistence uses `shared_preferences`.
class AppPreferences {
  final Color accentColor;
  final String profileName;
  final String bgTone;
  final bool isDarkMode;
  final String? avatarPath;
  final VoucherPattern voucherPattern;

  const AppPreferences({
    required this.accentColor,
    required this.profileName,
    required this.bgTone,
    required this.isDarkMode,
    this.avatarPath,
    this.voucherPattern = VoucherPattern.diagonalLines,
  });

  AppPreferences copyWith({
    Color? accentColor,
    String? profileName,
    String? bgTone,
    bool? isDarkMode,
    String? avatarPath,
    bool clearAvatarPath = false,
    VoucherPattern? voucherPattern,
  }) {
    return AppPreferences(
      accentColor: accentColor ?? this.accentColor,
      profileName: profileName ?? this.profileName,
      bgTone: bgTone ?? this.bgTone,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      avatarPath: clearAvatarPath ? null : (avatarPath ?? this.avatarPath),
      voucherPattern: voucherPattern ?? this.voucherPattern,
    );
  }

  static const defaults = AppPreferences(
    accentColor: AppColors.accentPrimaryDefault,
    profileName: 'Mi Control',
    bgTone: BgTone.pure,
    isDarkMode: true,
    avatarPath: null,
    voucherPattern: VoucherPattern.diagonalLines,
  );
}

const _kAccentColorKey = 'pref_accent_color';
const _kProfileNameKey = 'pref_profile_name';
const _kBgToneKey = 'pref_bg_tone';
const _kIsDarkModeKey = 'pref_is_dark_mode';
const _kAvatarPathKey = 'pref_avatar_path';
const _kVoucherPatternKey = 'pref_voucher_pattern';

/// Fixed filename for the locally-stored profile picture, kept inside the
/// app's sandboxed documents directory. Overwritten each time the user picks
/// a new image.
const String kAvatarFileName = 'profile_avatar.jpg';

class ThemePreferencesNotifier extends StateNotifier<AppPreferences> {
  final SharedPreferences _prefs;

  ThemePreferencesNotifier(SharedPreferences prefs)
      : _prefs = prefs,
        super(_loadSync(prefs)) {
    _validateAvatarPath(prefs);
  }

  /// Synchronous initial load — SharedPreferences is pre-loaded in main() so
  /// the first state is already correct on the very first frame (no flash).
  static AppPreferences _loadSync(SharedPreferences prefs) {
    final accentValue = prefs.getInt(_kAccentColorKey);
    final name = prefs.getString(_kProfileNameKey);
    final bgTone = prefs.getString(_kBgToneKey);
    final isDark = prefs.getBool(_kIsDarkModeKey);
    final avatarPath = prefs.getString(_kAvatarPathKey);
    final voucherPatternName = prefs.getString(_kVoucherPatternKey);
    return AppPreferences(
      accentColor: accentValue != null
          ? Color(accentValue)
          : AppPreferences.defaults.accentColor,
      profileName: name ?? AppPreferences.defaults.profileName,
      bgTone: bgTone ?? AppPreferences.defaults.bgTone,
      isDarkMode: isDark ?? AppPreferences.defaults.isDarkMode,
      avatarPath: avatarPath,
      voucherPattern: VoucherPattern.fromName(voucherPatternName),
    );
  }

  /// Secondary async check: if the saved avatar path no longer exists on disk
  /// (e.g. app reinstall), clear it. Runs after the first frame.
  Future<void> _validateAvatarPath(SharedPreferences prefs) async {
    final avatarPath = state.avatarPath;
    if (avatarPath != null && !await File(avatarPath).exists()) {
      state = state.copyWith(clearAvatarPath: true);
      await prefs.remove(_kAvatarPathKey);
    }
  }

  Future<void> setVoucherPattern(VoucherPattern pattern) async {
    state = state.copyWith(voucherPattern: pattern);
    await _prefs.setString(_kVoucherPatternKey, pattern.name);
  }

  Future<void> setAccentColor(Color color) async {
    state = state.copyWith(accentColor: color);
    // ignore: deprecated_member_use
    await _prefs.setInt(_kAccentColorKey, color.value);
  }

  Future<void> setProfileName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(profileName: trimmed);
    await _prefs.setString(_kProfileNameKey, trimmed);
  }

  Future<void> setBgTone(String tone) async {
    state = state.copyWith(bgTone: tone);
    await _prefs.setString(_kBgToneKey, tone);
  }

  Future<void> setIsDarkMode(bool isDark) async {
    state = state.copyWith(isDarkMode: isDark);
    await _prefs.setBool(_kIsDarkModeKey, isDark);
  }

  /// Copies [sourceFilePath] (e.g. the path returned by image_picker) into
  /// the app's sandboxed documents directory under a fixed filename,
  /// overwriting any previously saved avatar, and persists its path.
  Future<void> setAvatarFromFile(String sourceFilePath) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final destPath = p.join(docsDir.path, kAvatarFileName);
    final destFile = File(destPath);
    if (await destFile.exists()) {
      await destFile.delete();
    }
    await File(sourceFilePath).copy(destPath);
    state = state.copyWith(avatarPath: destPath);
    await _prefs.setString(_kAvatarPathKey, destPath);
  }

  /// Deletes the saved avatar file (if any) and clears the preference.
  Future<void> clearAvatar() async {
    final path = state.avatarPath;
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    state = state.copyWith(clearAvatarPath: true);
    await _prefs.remove(_kAvatarPathKey);
  }
}

/// Global preferences provider. Watch `ref.watch(themePreferencesProvider)`
/// to react to accent/profile/bg-tone changes; `.accentColor` is fed
/// into `buildAppTheme(accent: ...)` at the MaterialApp root in main.dart.
final themePreferencesProvider =
    StateNotifierProvider<ThemePreferencesNotifier, AppPreferences>(
  (ref) => ThemePreferencesNotifier(ref.read(sharedPreferencesProvider)),
);
