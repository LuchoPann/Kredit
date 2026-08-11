import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-lock method chosen by the user. Persisted (the *method*, not the
/// secret) via `shared_preferences`, following the same pattern as
/// `theme_provider.dart` / `notification_settings_provider.dart`. The PIN
/// itself is never stored in plain text — only its salted SHA-256 hash,
/// kept in `flutter_secure_storage` (Android Keystore-backed).
enum LockMethod { none, biometric, pin }

class AppLockState {
  final LockMethod method;
  final bool isLocked;

  const AppLockState({required this.method, required this.isLocked});

  AppLockState copyWith({LockMethod? method, bool? isLocked}) {
    return AppLockState(
      method: method ?? this.method,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  static const initial = AppLockState(method: LockMethod.none, isLocked: false);
}

const _kLockMethodKey = 'pref_lock_method';
const _kPinHashKey = 'secure_pin_hash';

// Fixed app-wide salt: acceptable here because this is a single-user local
// app (no multi-tenant secrets to separate) — see task spec. Only makes the
// stored hash resistant to generic rainbow tables, not a security boundary
// on its own.
const _kPinSalt = 'kredit_app_local_pin_salt_v1';

class AppLockNotifier extends StateNotifier<AppLockState> with WidgetsBindingObserver {
  AppLockNotifier()
      : _secureStorage = const FlutterSecureStorage(),
        _localAuth = LocalAuthentication(),
        super(AppLockState.initial) {
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLockMethodKey);
    final method = LockMethod.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => LockMethod.none,
    );
    // Locked by default whenever a lock method is configured; the user
    // must authenticate once per app launch.
    state = AppLockState(method: method, isLocked: method != LockMethod.none);
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode('$_kPinSalt:$pin');
    return sha256.convert(bytes).toString();
  }

  Future<void> setupPin(String pin) async {
    await _secureStorage.write(key: _kPinHashKey, value: _hashPin(pin));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLockMethodKey, LockMethod.pin.name);
    state = state.copyWith(method: LockMethod.pin, isLocked: false);
  }

  Future<bool> verifyPin(String pin) async {
    final storedHash = await _secureStorage.read(key: _kPinHashKey);
    if (storedHash == null) return false;
    final matches = storedHash == _hashPin(pin);
    if (matches) {
      state = state.copyWith(isLocked: false);
    }
    return matches;
  }

  Future<bool> canUseBiometrics() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return supported && canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: 'Autentícate para acceder a Kredit',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      if (ok) {
        state = state.copyWith(isLocked: false);
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<void> enableBiometric() async {
    final available = await canUseBiometrics();
    if (!available) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLockMethodKey, LockMethod.biometric.name);
    state = state.copyWith(method: LockMethod.biometric, isLocked: false);
  }

  Future<void> disableBiometric() async {
    if (state.method != LockMethod.biometric) return;
    await disableLock();
  }

  Future<void> disableLock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLockMethodKey, LockMethod.none.name);
    await _secureStorage.delete(key: _kPinHashKey);
    state = const AppLockState(method: LockMethod.none, isLocked: false);
  }

  // Re-lock on returning from background: if a lock method is active,
  // going to `paused` (backgrounded) and back to `resumed` re-arms
  // `isLocked`. Wired here via WidgetsBindingObserver rather than in
  // main.dart so the behavior travels with the provider regardless of
  // which widget tree currently hosts it.
  bool _wasBackgrounded = false;

  @override
  // ignore: avoid_renaming_method_parameters
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (state.method == LockMethod.none) return;
    if (appState == AppLifecycleState.paused) {
      _wasBackgrounded = true;
    } else if (appState == AppLifecycleState.resumed && _wasBackgrounded) {
      _wasBackgrounded = false;
      if (!state.isLocked) {
        state = state.copyWith(isLocked: true);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

final appLockProvider = StateNotifierProvider<AppLockNotifier, AppLockState>(
  (ref) => AppLockNotifier(),
);

