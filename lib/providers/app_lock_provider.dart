import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shared_preferences_provider.dart';

/// App-lock method chosen by the user. Persisted (the *method*, not the
/// secret) via `shared_preferences`, following the same pattern as
/// `theme_provider.dart` / `notification_settings_provider.dart`. The PIN
/// itself is never stored in plain text — only its salted SHA-256 hash,
/// kept in `flutter_secure_storage` (Android Keystore-backed).
enum LockMethod { none, biometric, pin }

class AppLockState {
  final LockMethod method;
  final bool isLocked;

  /// Timestamp (UTC) until which PIN retries are refused, or `null` when no
  /// backoff is currently active. Biometric auth is never affected by this —
  /// it has its own OS-level throttling/lockout and is a separate credential.
  final DateTime? pinLockedUntil;

  const AppLockState({
    required this.method,
    required this.isLocked,
    this.pinLockedUntil,
  });

  AppLockState copyWith({
    LockMethod? method,
    bool? isLocked,
    DateTime? pinLockedUntil,
    bool clearPinLockedUntil = false,
  }) {
    return AppLockState(
      method: method ?? this.method,
      isLocked: isLocked ?? this.isLocked,
      pinLockedUntil:
          clearPinLockedUntil ? null : (pinLockedUntil ?? this.pinLockedUntil),
    );
  }

  static const initial = AppLockState(method: LockMethod.none, isLocked: false);
}

const _kLockMethodKey = 'pref_lock_method';
const _kPinHashKey = 'secure_pin_hash';
const _kPinFailedAttemptsKey = 'secure_pin_failed_attempts';
const _kPinLockedUntilKey = 'secure_pin_locked_until';

/// Consecutive failed PIN attempts allowed before the first backoff kicks in.
const int kPinMaxAttemptsBeforeBackoff = 5;

/// Backoff duration applied after each failed attempt once the threshold is
/// exceeded, indexed by "how many backoff periods have already elapsed"
/// (0 = first lockout). Starts short (30s) and doubles up to a 5-minute cap
/// so a local-only brute force is throttled without ever feeling like a
/// punitive wipe — this is a local, non-networked app, so the threat model
/// is "someone briefly has the unlocked phone in hand", not a remote
/// attacker who can afford to wait out a few minutes per guess.
const List<Duration> kPinBackoffSteps = [
  Duration(seconds: 30),
  Duration(seconds: 60),
  Duration(seconds: 120),
  Duration(seconds: 240),
  Duration(minutes: 5), // cap — stays at 5 min for every subsequent failure
];

// Fixed app-wide salt: acceptable here because this is a single-user local
// app (no multi-tenant secrets to separate) — see task spec. Only makes the
// stored hash resistant to generic rainbow tables, not a security boundary
// on its own.
const _kPinSalt = 'kredit_app_local_pin_salt_v1';

class AppLockNotifier extends StateNotifier<AppLockState> with WidgetsBindingObserver {
  AppLockNotifier(this._prefs)
      : _secureStorage = const FlutterSecureStorage(),
        _localAuth = LocalAuthentication(),
        super(AppLockState.initial) {
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth;

  Future<void> _load() async {
    final raw = _prefs.getString(_kLockMethodKey);
    final method = LockMethod.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => LockMethod.none,
    );
    final pinLockedUntil = await _readPinLockedUntil();
    // Locked by default whenever a lock method is configured; the user
    // must authenticate once per app launch.
    state = AppLockState(
      method: method,
      isLocked: method != LockMethod.none,
      pinLockedUntil: pinLockedUntil,
    );
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode('$_kPinSalt:$pin');
    return sha256.convert(bytes).toString();
  }

  Future<int> _readFailedAttempts() async {
    final raw = await _secureStorage.read(key: _kPinFailedAttemptsKey);
    return int.tryParse(raw ?? '') ?? 0;
  }

  /// Reads the persisted PIN lockout deadline, if one is still in the
  /// future. A past or missing deadline is treated as "not locked" (and,
  /// when past, cleared from storage) so the backoff never outlives the
  /// interval it was meant to enforce.
  Future<DateTime?> _readPinLockedUntil() async {
    final raw = await _secureStorage.read(key: _kPinLockedUntilKey);
    if (raw == null) return null;
    final millis = int.tryParse(raw);
    if (millis == null) return null;
    final until = DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    if (until.isAfter(DateTime.now().toUtc())) return until;
    await _secureStorage.delete(key: _kPinLockedUntilKey);
    return null;
  }

  Future<void> _resetPinBackoff() async {
    await _secureStorage.delete(key: _kPinFailedAttemptsKey);
    await _secureStorage.delete(key: _kPinLockedUntilKey);
  }

  Future<void> setupPin(String pin) async {
    await _secureStorage.write(key: _kPinHashKey, value: _hashPin(pin));
    await _resetPinBackoff();
    await _prefs.setString(_kLockMethodKey, LockMethod.pin.name);
    state = state.copyWith(
      method: LockMethod.pin,
      isLocked: false,
      clearPinLockedUntil: true,
    );
  }

  /// Verifies [pin] against the stored hash, enforcing a temporary backoff
  /// after [kPinMaxAttemptsBeforeBackoff] consecutive failures. Returns
  /// `false` without even checking the PIN while a backoff is active — the
  /// caller (lock screen) should read [AppLockState.pinLockedUntil] to show
  /// remaining time rather than treat this as a normal "wrong PIN".
  Future<bool> verifyPin(String pin) async {
    final activeLockout = await _readPinLockedUntil();
    if (activeLockout != null) {
      state = state.copyWith(pinLockedUntil: activeLockout);
      return false;
    }

    final storedHash = await _secureStorage.read(key: _kPinHashKey);
    if (storedHash == null) return false;
    final matches = storedHash == _hashPin(pin);

    if (matches) {
      await _resetPinBackoff();
      state = state.copyWith(isLocked: false, clearPinLockedUntil: true);
      return true;
    }

    final failedAttempts = await _readFailedAttempts() + 1;
    await _secureStorage.write(
      key: _kPinFailedAttemptsKey,
      value: '$failedAttempts',
    );

    if (failedAttempts >= kPinMaxAttemptsBeforeBackoff) {
      final stepIndex =
          (failedAttempts - kPinMaxAttemptsBeforeBackoff).clamp(
        0,
        kPinBackoffSteps.length - 1,
      );
      final until = DateTime.now().toUtc().add(kPinBackoffSteps[stepIndex]);
      await _secureStorage.write(
        key: _kPinLockedUntilKey,
        value: '${until.millisecondsSinceEpoch}',
      );
      state = state.copyWith(pinLockedUntil: until);
    }

    return false;
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
    await _prefs.setString(_kLockMethodKey, LockMethod.biometric.name);
    state = state.copyWith(method: LockMethod.biometric, isLocked: false);
  }

  Future<void> disableBiometric() async {
    if (state.method != LockMethod.biometric) return;
    await disableLock();
  }

  Future<void> disableLock() async {
    await _prefs.setString(_kLockMethodKey, LockMethod.none.name);
    await _secureStorage.delete(key: _kPinHashKey);
    await _resetPinBackoff();
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
  (ref) => AppLockNotifier(ref.read(sharedPreferencesProvider)),
);

