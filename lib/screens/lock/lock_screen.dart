import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_lock_provider.dart';
import '../../theme/app_theme.dart';

/// Blocking screen shown when `appLockProvider.isLocked` is true. For
/// `LockMethod.biometric`, attempts authentication automatically on show
/// with a manual "Reintentar" fallback; for `LockMethod.pin`, a simple
/// numeric keypad accepts a 4-6 digit PIN with error feedback on mismatch.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen>
    with TickerProviderStateMixin {
  String _pinInput = '';
  bool _error = false;
  bool _authenticating = false;

  late final AnimationController _shakeController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoBiometric());
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _maybeAutoBiometric() async {
    final method = ref.read(appLockProvider).method;
    if (method == LockMethod.biometric) {
      await _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    if (_authenticating) return;
    setState(() => _authenticating = true);
    await ref.read(appLockProvider.notifier).authenticateWithBiometrics();
    if (mounted) setState(() => _authenticating = false);
  }

  Future<void> _onDigit(String digit) async {
    if (_pinInput.length >= 6) return;
    setState(() {
      _pinInput += digit;
      _error = false;
    });
    if (_pinInput.length >= 4) {
      // Allow a short window for further digits (up to 6) before
      // auto-submitting, mirroring a typical PIN-pad UX: submit once the
      // user pauses, but only after the minimum length is reached — here
      // simplified to auto-submit as soon as 4 digits are entered if that
      // already verifies; otherwise wait for more digits up to 6.
      final ok = await ref.read(appLockProvider.notifier).verifyPin(_pinInput);
      if (!ok) {
        if (_pinInput.length == 6) {
          setState(() {
            _error = true;
            _pinInput = '';
          });
          _shakeController.forward(from: 0);
        }
        // else: keep waiting for more digits in case it's a longer PIN
      }
    }
  }

  void _onBackspace() {
    if (_pinInput.isEmpty) return;
    setState(() {
      _pinInput = _pinInput.substring(0, _pinInput.length - 1);
      _error = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockProvider);
    final kredit = Theme.of(context).extension<KreditColors>()!;

    return Scaffold(
      backgroundColor: kredit.bgPrimary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: kredit.borderCard, width: 1.5),
                      ),
                      child: Icon(Icons.lock_outline, size: 32, color: kredit.textPrimary),
                    ),
                    const SizedBox(height: KreditSpacing.section),
                    Text(
                      'Kredit bloqueado',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: kredit.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lockState.method == LockMethod.biometric
                          ? 'Verifica tu identidad para continuar'
                          : 'Ingresa tu PIN para continuar',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kredit.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 40),
                    if (lockState.method == LockMethod.biometric)
                      _BiometricPrompt(
                        authenticating: _authenticating,
                        pulseAnimation: _pulseController,
                        onRetry: _tryBiometric,
                      )
                    else if (lockState.method == LockMethod.pin)
                      _PinPad(
                        pinLength: _pinInput.length,
                        error: _error,
                        shakeAnimation: _shakeController,
                        onDigit: _onDigit,
                        onBackspace: _onBackspace,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

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
      children: [
        SizedBox(
          width: 88,
          height: 88,
          child: AnimatedBuilder(
            animation: pulseAnimation,
            builder: (context, child) {
              // Expanding, fading ring that loops while waiting on the
              // biometric prompt, so "esperando autenticación" reads as an
              // active process rather than a static icon.
              final t = pulseAnimation.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  if (authenticating)
                    Opacity(
                      opacity: (1 - t).clamp(0.0, 1.0),
                      child: Container(
                        width: 56 + (32 * t),
                        height: 56 + (32 * t),
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
              width: 64,
              height: 64,
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
                size: 32,
                color: authenticating ? accent : kredit.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          authenticating ? 'Verificando...' : 'Autenticación biométrica requerida',
          style: TextStyle(color: kredit.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: authenticating ? null : onRetry,
          icon: const Icon(Icons.fingerprint, size: 18),
          label: const Text('Reintentar'),
          style: OutlinedButton.styleFrom(
            foregroundColor: kredit.textPrimary,
            side: BorderSide(color: kredit.borderCard),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(KreditRadius.tile),
            ),
          ),
        ),
      ],
    );
  }
}

class _PinPad extends StatelessWidget {
  final int pinLength;
  final bool error;
  final Animation<double> shakeAnimation;
  final void Function(String) onDigit;
  final VoidCallback onBackspace;

  const _PinPad({
    required this.pinLength,
    required this.error,
    required this.shakeAnimation,
    required this.onDigit,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: shakeAnimation,
          builder: (context, child) {
            // Decaying horizontal shake: a few oscillations that settle by
            // the end of the animation, common "wrong PIN" feedback.
            final t = shakeAnimation.value;
            final offset = (t == 0 || t == 1)
                ? 0.0
                : math.sin(t * 4 * math.pi) * 12 * (1 - t);
            return Transform.translate(offset: Offset(offset, 0), child: child);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) {
              final filled = i < pinLength;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 7),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: error
                      ? AppColors.danger
                      : (filled ? kredit.textPrimary : Colors.transparent),
                  border: Border.all(
                    color: error ? AppColors.danger : AppColors.borderActive,
                    width: 1.5,
                  ),
                ),
              );
            }),
          ),
        ),
        SizedBox(
          height: 32,
          child: error
              ? Center(
                  child: Text(
                    'PIN incorrecto',
                    style: TextStyle(color: AppColors.danger, fontSize: 13),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            final padWidth =
                (MediaQuery.of(context).size.width * 0.7).clamp(220.0, 300.0);
            return SizedBox(
              width: padWidth,
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.3,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final d in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
                    _PadButton(label: d, onTap: () => onDigit(d)),
                  const SizedBox.shrink(),
                  _PadButton(label: '0', onTap: () => onDigit('0')),
                  _PadButton(
                    icon: Icons.backspace_outlined,
                    onTap: onBackspace,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PadButton extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  const _PadButton({this.label, this.icon, required this.onTap});

  @override
  State<_PadButton> createState() => _PadButtonState();
}

class _PadButtonState extends State<_PadButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return AnimatedScale(
      scale: _pressed ? 0.9 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: Material(
        color: kredit.bgCard,
        shape: CircleBorder(side: BorderSide(color: kredit.borderCard)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: widget.onTap,
          onTapDown: (_) => _setPressed(true),
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) => _setPressed(false),
          child: Center(
            child: widget.label != null
                ? Text(
                    widget.label!,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: kredit.textPrimary,
                    ),
                  )
                : Icon(widget.icon, color: kredit.textSecondary),
          ),
        ),
      ),
    );
  }
}
