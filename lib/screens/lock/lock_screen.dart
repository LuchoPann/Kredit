import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_lock_provider.dart';
import '../../theme/app_theme.dart';

/// Blocking screen shown when [appLockProvider.isLocked] is true.
///
/// Biometric: attempts automatically on show with a manual "Reintentar"
/// fallback.
/// PIN: uses the device's native numeric keyboard (via a hidden [TextField])
/// so the user gets their phone's own keypad, with haptics and autocomplete
/// disabled.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen>
    with TickerProviderStateMixin {
  // ── PIN state ──────────────────────────────────────────────────────────────
  final _pinCtrl = TextEditingController();
  final _pinFocus = FocusNode();
  bool _error = false;
  bool _authenticating = false;

  // ── PIN backoff countdown ────────────────────────────────────────────────
  Timer? _countdownTimer;
  Duration _remainingLockout = Duration.zero;

  // ── Animations ─────────────────────────────────────────────────────────────
  late final AnimationController _shakeCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncLockoutCountdown();
      _maybeAutoBiometric();
    });
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    _pinFocus.dispose();
    _shakeCtrl.dispose();
    _pulseCtrl.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// Starts (or restarts) a 1s ticker reflecting `pinLockedUntil` from the
  /// provider, so the lock screen shows a live "intenta de nuevo en Xs"
  /// countdown instead of a static message.
  void _syncLockoutCountdown() {
    final until = ref.read(appLockProvider).pinLockedUntil;
    _countdownTimer?.cancel();
    if (until == null) {
      setState(() => _remainingLockout = Duration.zero);
      return;
    }
    void tick() {
      final remaining = until.difference(DateTime.now().toUtc());
      if (!mounted) return;
      if (remaining.isNegative || remaining == Duration.zero) {
        setState(() => _remainingLockout = Duration.zero);
        _countdownTimer?.cancel();
      } else {
        setState(() => _remainingLockout = remaining);
      }
    }

    tick();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  /// See [_NativePinField._showKeyboard]'s doc comment: `requestFocus()`
  /// alone doesn't reopen the native keyboard once it's already been
  /// dismissed while the field kept focus, so fall back to asking the
  /// platform directly in that case.
  void _showPinKeyboard() {
    if (!_pinFocus.hasFocus) {
      _pinFocus.requestFocus();
    } else {
      SystemChannels.textInput.invokeMethod('TextInput.show');
    }
  }

  Future<void> _maybeAutoBiometric() async {
    final method = ref.read(appLockProvider).method;
    if (method == LockMethod.biometric) {
      await _tryBiometric();
    } else if (method == LockMethod.pin) {
      // Small post-frame delay ensures the keyboard service is ready to accept focus on Android
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _pinFocus.requestFocus();
        }
      });
    }
  }

  Future<void> _tryBiometric() async {
    if (_authenticating) return;
    setState(() => _authenticating = true);
    await ref.read(appLockProvider.notifier).authenticateWithBiometrics();
    if (mounted) setState(() => _authenticating = false);
  }

  Future<void> _onPinChanged(String value) async {
    if (_remainingLockout > Duration.zero) {
      // Ignore input entirely while a backoff is active.
      _pinCtrl.clear();
      return;
    }
    if (value.length > 6) {
      _pinCtrl.text = value.substring(0, 6);
      _pinCtrl.selection =
          TextSelection.collapsed(offset: _pinCtrl.text.length);
      return;
    }
    setState(() => _error = false);

    // Auto-verify at ≥4 digits; keep going up to 6 if wrong
    if (value.length >= 4) {
      final ok = await ref.read(appLockProvider.notifier).verifyPin(value);
      if (ok) return; // provider navigates away
      _syncLockoutCountdown();
      if (_remainingLockout > Duration.zero) {
        // Just entered a fresh backoff period: clear the field and let the
        // countdown UI take over instead of showing a generic PIN error.
        if (mounted) {
          _pinCtrl.clear();
          setState(() => _error = false);
        }
        return;
      }
      if (value.length == 6) {
        setState(() => _error = true);
        _shakeCtrl.forward(from: 0);
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          _pinCtrl.clear();
          setState(() => _error = false);
        }
      }
    }
  }

  String _formatLockoutMessage(Duration remaining) {
    final totalSeconds = remaining.inSeconds + 1; // ceil for a friendlier countdown
    if (totalSeconds >= 60) {
      final minutes = totalSeconds ~/ 60;
      final seconds = totalSeconds % 60;
      final secondsPart = seconds > 0 ? ' ${seconds}s' : '';
      return 'Demasiados intentos. Intenta de nuevo en ${minutes}m$secondsPart.';
    }
    return 'Demasiados intentos. Intenta de nuevo en ${totalSeconds}s.';
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockProvider);
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final isPinMode = lockState.method == LockMethod.pin;

    return Scaffold(
      backgroundColor: kredit.bgPrimary,
      // Tapping anywhere re-focuses the hidden field (PIN mode)
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: isPinMode && _remainingLockout == Duration.zero
            ? _showPinKeyboard
            : null,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Lock / PIN icon ────────────────────────────────────────
                  Container(
                    width: 80,
                    height: 80,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kredit.bgCard,
                      border: Border.all(color: kredit.borderCard, width: 1.5),
                    ),
                    child: Icon(
                      isPinMode ? Icons.pin_outlined : Icons.lock_outline,
                      size: KreditIconSize.large,
                      color: kredit.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Title ──────────────────────────────────────────────────
                  Text(
                    'Kredit bloqueado',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: KreditTextSize.emphasis,
                      fontWeight: FontWeight.bold,
                      color: kredit.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isPinMode
                        ? 'Ingresa tu PIN para continuar'
                        : 'Verifica tu identidad para continuar',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kredit.textSecondary, fontSize: KreditTextSize.body),
                  ),
                  const SizedBox(height: 40),

                  // ── Mode-specific widget ───────────────────────────────────
                  if (!isPinMode)
                    _BiometricPrompt(
                      authenticating: _authenticating,
                      pulseAnimation: _pulseCtrl,
                      onRetry: _tryBiometric,
                    )
                  else
                    _NativePinField(
                      controller: _pinCtrl,
                      focusNode: _pinFocus,
                      error: _error,
                      shakeAnimation: _shakeCtrl,
                      onChanged: _onPinChanged,
                      lockoutMessage: _remainingLockout > Duration.zero
                          ? _formatLockoutMessage(_remainingLockout)
                          : null,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PIN entry — dots indicator + hidden TextField → native keyboard
// ─────────────────────────────────────────────────────────────────────────────

class _NativePinField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool error;
  final Animation<double> shakeAnimation;
  final Future<void> Function(String) onChanged;
  /// Non-null while a PIN backoff is active; shown instead of the normal
  /// "PIN incorrecto" message, and disables the field entirely.
  final String? lockoutMessage;

  const _NativePinField({
    required this.controller,
    required this.focusNode,
    required this.error,
    required this.shakeAnimation,
    required this.onChanged,
    this.lockoutMessage,
  });

  /// Reliably re-opens the native soft keyboard for [focusNode]. Just
  /// calling `focusNode.requestFocus()` is a no-op — and the keyboard stays
  /// closed — whenever the field ALREADY has focus but the user dismissed
  /// the OS keyboard manually (swiped it down, tapped outside then back):
  /// Flutter only asks the platform to show the keyboard on an actual focus
  /// change, not on a redundant request. Explicitly invoking the
  /// `TextInput.show` platform method covers that case.
  void _showKeyboard() {
    if (!focusNode.hasFocus) {
      focusNode.requestFocus();
    } else {
      SystemChannels.textInput.invokeMethod('TextInput.show');
    }
  }

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    final isLockedOut = lockoutMessage != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Interactive PIN dots with transparent layered TextField ────────
        Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: shakeAnimation,
              builder: (context, child) {
                final t = shakeAnimation.value;
                final offset = (t == 0 || t == 1)
                    ? 0.0
                    : _shakeSin(t * 4 * 3.1416) * 14 * (1 - t);
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                );
              },
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (_, value, _) {
                  final len = value.text.length;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (i) {
                      final filled = i < len;
                      final isActive = i == len; // next-to-fill
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 9),
                        width: filled ? 20 : 18,
                        height: filled ? 20 : 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: error
                              ? AppColors.danger
                              : (filled ? kredit.textPrimary : Colors.transparent),
                          border: Border.all(
                            color: error
                                ? AppColors.danger
                                : (filled
                                    ? kredit.textPrimary
                                    : isActive
                                        ? accent
                                        : kredit.borderCard),
                            width: isActive && !error ? 2.5 : 2,
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
            // Layered TextField over the dots: triggers system soft keyboard reliably
            Positioned.fill(
              child: Opacity(
                opacity: 0.01,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: !isLockedOut,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 6,
                  obscureText: true,
                  autofocus: true,
                  showCursor: false,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    isCollapsed: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: onChanged,
                ),
              ),
            ),
          ],
        ),

        // ── Error / lockout / feedback message ──────────────────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLockedOut
              ? Padding(
                  key: const ValueKey('lockout'),
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    lockoutMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: KreditTextSize.caption,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : error
                  ? const Padding(
                      key: ValueKey('err'),
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                        'PIN incorrecto, intenta de nuevo',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontSize: KreditTextSize.caption,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : const SizedBox(key: ValueKey('ok'), height: 16),
        ),

        const SizedBox(height: 28),

        // ── Tap-to-open-keyboard area ──────────────────────────────────────
        GestureDetector(
          onTap: isLockedOut ? null : _showKeyboard,
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, _) => AnimatedOpacity(
              opacity: (!isLockedOut && value.text.isEmpty) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.keyboard_outlined,
                      size: KreditIconSize.small, color: kredit.textTertiary),
                  const SizedBox(width: 6),
                  Text(
                    'Toca para ingresar tu PIN',
                    style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── Fallback button if keyboard gets dismissed ─────────────────────
        TextButton.icon(
          onPressed: isLockedOut ? null : _showKeyboard,
          icon: Icon(Icons.keyboard_outlined,
              size: KreditIconSize.small, color: kredit.textTertiary),
          label: Text(
            'Abrir teclado',
            style: TextStyle(color: kredit.textTertiary, fontSize: KreditTextSize.caption),
          ),
        ),
      ],
    );
  }
}

/// Decaying horizontal sine wave for the shake animation.
double _shakeSin(double x) {
  const pi = 3.14159265358979;
  x = x % (2 * pi);
  final xs = x - pi;
  final denom = 5 * pi * pi - 4 * xs * (pi - xs.abs());
  if (denom == 0) return 0;
  return -((16 * xs * (pi - xs.abs())) / denom);
}

// ─────────────────────────────────────────────────────────────────────────────
// Biometric prompt
// ─────────────────────────────────────────────────────────────────────────────

class _BiometricPrompt extends StatelessWidget {
  final bool authenticating;
  final Animation<double> pulseAnimation;
  final VoidCallback onRetry;

  const _BiometricPrompt({
    required this.authenticating,
    required this.pulseAnimation,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: AnimatedBuilder(
            animation: pulseAnimation,
            builder: (context, child) {
              final t = pulseAnimation.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  if (authenticating)
                    Opacity(
                      opacity: (1 - t).clamp(0.0, 1.0),
                      child: Container(
                        width: 64 + (36 * t),
                        height: 64 + (36 * t),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: accent, width: 1.5),
                        ),
                      ),
                    ),
                  child!,
                ],
              );
            },
            child: Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kredit.bgCard,
                border: Border.all(
                  color: authenticating ? accent : kredit.borderCard,
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.fingerprint,
                size: KreditIconSize.large,
                color: authenticating ? accent : kredit.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          authenticating
              ? 'Verificando...'
              : 'Autenticación biométrica requerida',
          textAlign: TextAlign.center,
          style: TextStyle(color: kredit.textSecondary, fontSize: KreditTextSize.body),
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: authenticating ? null : onRetry,
          icon: const Icon(Icons.fingerprint, size: KreditIconSize.small),
          label: const Text('Reintentar'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(KreditRadius.tile),
            ),
          ),
        ),
      ],
    );
  }
}
