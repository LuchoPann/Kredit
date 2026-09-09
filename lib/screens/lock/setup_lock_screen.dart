import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_lock_provider.dart';
import '../../theme/app_theme.dart';

/// "Seguridad" setup screen, reached from Cuenta. Lets the user pick a
/// lock method (none / biometric if available / PIN); choosing PIN asks
/// for the digits twice to confirm before saving.
class SetupLockScreen extends ConsumerStatefulWidget {
  const SetupLockScreen({super.key});

  @override
  ConsumerState<SetupLockScreen> createState() => _SetupLockScreenState();
}

class _SetupLockScreenState extends ConsumerState<SetupLockScreen> {
  bool? _biometricAvailable;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final available = await ref.read(appLockProvider.notifier).canUseBiometrics();
    if (mounted) setState(() => _biometricAvailable = available);
  }

  Future<void> _selectNone() async {
    await ref.read(appLockProvider.notifier).disableLock();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bloqueo desactivado')),
      );
    }
  }

  Future<void> _selectBiometric() async {
    await ref.read(appLockProvider.notifier).enableBiometric();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bloqueo biométrico activado')),
      );
    }
  }

  Future<void> _selectPin() async {
    final pin = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _PinSetupFlow()),
    );
    if (pin != null) {
      await ref.read(appLockProvider.notifier).setupPin(pin);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN configurado')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final method = ref.watch(appLockProvider).method;
    final kredit = Theme.of(context).extension<KreditColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Seguridad')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Elige cómo proteger el acceso a Kredit al abrir la app.',
            style: TextStyle(color: kredit.textSecondary),
          ),
          const SizedBox(height: KreditSpacing.section),
          Divider(height: 1, color: kredit.borderCard),
          _LockOptionTile(
            icon: Icons.lock_open_outlined,
            title: 'Ninguno',
            subtitle: 'La app abre directamente',
            selected: method == LockMethod.none,
            onTap: _selectNone,
          ),
          Divider(height: 1, color: kredit.borderCard),
          _LockOptionTile(
            icon: Icons.fingerprint,
            title: 'Biometría',
            subtitle: _biometricAvailable == false
                ? 'No disponible en este dispositivo'
                : 'Huella dactilar o reconocimiento facial',
            selected: method == LockMethod.biometric,
            enabled: _biometricAvailable == true,
            onTap: () {
              if (_biometricAvailable == true) _selectBiometric();
            },
          ),
          Divider(height: 1, color: kredit.borderCard),
          _LockOptionTile(
            icon: Icons.pin_outlined,
            title: 'PIN',
            subtitle: 'Código numérico de 4 a 6 dígitos',
            selected: method == LockMethod.pin,
            onTap: _selectPin,
          ),
          Divider(height: 1, color: kredit.borderCard),
        ],
      ),
    );
  }
}

/// Selectable row for a lock method — follows the app's "sin cajas" list
/// language (see `_UpcomingRow` / `CreditCardTile`): no bordered container,
/// consecutive rows separated by the caller with a hairline `Divider`.
/// "Selected" is communicated through icon/text color and weight plus a
/// small filled circular accent trailing the row (the same small-accent
/// idiom used elsewhere, e.g. the urgency dot on the dashboard); a dimmed
/// opacity marks the row unavailable (biometrics not supported).
class _LockOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _LockOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    final contentColor = enabled ? kredit.textPrimary : kredit.textTertiary;

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 4,
          ),
          child: Row(
            children: [
              Icon(icon, size: KreditIconSize.small, color: selected ? accent : contentColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: contentColor,
                        fontSize: KreditTextSize.body,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: kredit.textSecondary, fontSize: KreditTextSize.caption),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (selected)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                )
              else if (enabled)
                Icon(Icons.chevron_right, size: KreditIconSize.small, color: kredit.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two-step PIN entry using the device's native keyboard:
/// first pass captures the PIN, second confirms it matches.
/// Pops with the confirmed PIN string, or null if cancelled.
class _PinSetupFlow extends StatefulWidget {
  const _PinSetupFlow();

  @override
  State<_PinSetupFlow> createState() => _PinSetupFlowState();
}

class _PinSetupFlowState extends State<_PinSetupFlow>
    with SingleTickerProviderStateMixin {
  final _pinCtrl = TextEditingController();
  final _pinFocus = FocusNode();
  late final AnimationController _shakeCtrl;

  String? _firstPin;
  bool _error = false;

  bool get _confirming => _firstPin != null;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _pinFocus.requestFocus();
        }
      });
    });
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    _pinFocus.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onPinChanged(String value) {
    if (value.length > 6) {
      _pinCtrl.text = value.substring(0, 6);
      _pinCtrl.selection =
          TextSelection.collapsed(offset: _pinCtrl.text.length);
      return;
    }
    setState(() => _error = false);

    // If reaching 6 digits, optionally auto-submit
    if (value.length == 6) {
      _onSubmit();
    }
  }

  Future<void> _onSubmit() async {
    final input = _pinCtrl.text;
    if (input.length < 4) return;

    if (!_confirming) {
      setState(() {
        _firstPin = input;
        _pinCtrl.clear();
        _error = false;
      });
      _pinFocus.requestFocus();
    } else {
      if (input == _firstPin) {
        Navigator.of(context).pop(input);
      } else {
        setState(() {
          _error = true;
        });
        _shakeCtrl.forward(from: 0);
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          setState(() {
            _pinCtrl.clear();
            _firstPin = null;
            _error = false;
          });
          _pinFocus.requestFocus();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(_confirming ? 'Confirma tu PIN' : 'Crea un PIN'),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _pinFocus.requestFocus(),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Icon ───────────────────────────────────────────────────────
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kredit.bgCard,
                    border: Border.all(color: kredit.borderCard, width: 1.5),
                  ),
                  child: Icon(
                    Icons.pin_outlined,
                    size: KreditIconSize.large,
                    color: kredit.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Subtitle ───────────────────────────────────────────────────
                Text(
                  _confirming
                      ? 'Ingresa el PIN de nuevo para confirmar'
                      : 'Ingresa de 4 a 6 dígitos',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kredit.textSecondary, fontSize: KreditTextSize.body),
                ),
                const SizedBox(height: 36),

                // ── Interactive PIN dots with transparent layered TextField ────
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _shakeCtrl,
                      builder: (context, child) {
                        final t = _shakeCtrl.value;
                        final offset = (t == 0 || t == 1)
                            ? 0.0
                            : _shakeSin(t * 4 * 3.1416) * 14 * (1 - t);
                        return Transform.translate(
                          offset: Offset(offset, 0),
                          child: child,
                        );
                      },
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _pinCtrl,
                        builder: (_, value, _) {
                          final len = value.text.length;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(6, (i) {
                              final filled = i < len;
                              final isActive = i == len;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                curve: Curves.easeOut,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 9),
                                width: filled ? 20 : 18,
                                height: filled ? 20 : 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _error
                                      ? AppColors.danger
                                      : (filled
                                          ? kredit.textPrimary
                                          : Colors.transparent),
                                  border: Border.all(
                                    color: _error
                                        ? AppColors.danger
                                        : (filled
                                            ? kredit.textPrimary
                                            : isActive
                                                ? accent
                                                : kredit.borderCard),
                                    width: isActive && !_error ? 2.5 : 2,
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ),
                    // Layered TextField to trigger native system keyboard
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.01,
                        child: TextField(
                          controller: _pinCtrl,
                          focusNode: _pinFocus,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
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
                          onChanged: _onPinChanged,
                          onSubmitted: (_) => _onSubmit(),
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Error message ──────────────────────────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _error
                      ? const Padding(
                          key: ValueKey('err'),
                          padding: EdgeInsets.only(top: 16),
                          child: Text(
                            'Los PIN no coinciden, intenta de nuevo',
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

                // ── Action Button ──────────────────────────────────────────────
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _pinCtrl,
                  builder: (_, value, _) {
                    final canSubmit = value.text.length >= 4;
                    return FilledButton(
                      onPressed: canSubmit ? _onSubmit : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                      ),
                      child: Text(_confirming ? 'Confirmar PIN' : 'Continuar'),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // ── Fallback button if keyboard gets dismissed ─────────────────
                TextButton.icon(
                  onPressed: () => _pinFocus.requestFocus(),
                  icon: Icon(Icons.keyboard_outlined,
                      size: KreditIconSize.small, color: kredit.textTertiary),
                  label: Text(
                    'Abrir teclado',
                    style: TextStyle(color: kredit.textTertiary, fontSize: KreditTextSize.caption),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
  return 4 * (pi * xs - xs * xs.abs()) / denom;
}
