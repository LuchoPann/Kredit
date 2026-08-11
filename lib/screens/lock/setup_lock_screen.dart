import 'package:flutter/material.dart';
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
          _LockOptionTile(
            icon: Icons.lock_open_outlined,
            title: 'Ninguno',
            subtitle: 'La app abre directamente',
            selected: method == LockMethod.none,
            onTap: _selectNone,
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          _LockOptionTile(
            icon: Icons.pin_outlined,
            title: 'PIN',
            subtitle: 'Código numérico de 4 a 6 dígitos',
            selected: method == LockMethod.pin,
            onTap: _selectPin,
          ),
        ],
      ),
    );
  }
}

/// Selectable row for a lock method: a filled/bordered container that
/// visibly distinguishes "selected" (accent border + filled radio +
/// primary text) from "unselected" (subtle border + outline radio +
/// secondary text), plus a dimmed state when biometrics aren't available.
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
      child: Material(
        color: kredit.bgCard,
        borderRadius: BorderRadius.circular(KreditRadius.card),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(KreditRadius.card),
          child: Container(
            padding: const EdgeInsets.all(KreditSpacing.card),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(KreditRadius.card),
              border: Border.all(
                color: selected ? accent : kredit.borderCard,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? accent.withValues(alpha: 0.12)
                        : kredit.bgSecondary,
                  ),
                  child: Icon(icon, size: 20, color: selected ? accent : contentColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: contentColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(color: kredit.textSecondary, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? accent : kredit.borderCard,
                      width: 1.5,
                    ),
                  ),
                  child: selected
                      ? Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Two-step PIN entry: first pass captures the PIN, second confirms it
/// matches. Pops with the confirmed PIN string, or null if cancelled.
class _PinSetupFlow extends StatefulWidget {
  const _PinSetupFlow();

  @override
  State<_PinSetupFlow> createState() => _PinSetupFlowState();
}

class _PinSetupFlowState extends State<_PinSetupFlow> {
  String? _firstPin;
  String _input = '';
  bool _error = false;

  bool get _confirming => _firstPin != null;

  void _onDigit(String d) {
    if (_input.length >= 6) return;
    setState(() {
      _input += d;
      _error = false;
    });
  }

  void _onBackspace() {
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  void _onSubmit() {
    if (_input.length < 4) return;
    if (!_confirming) {
      setState(() {
        _firstPin = _input;
        _input = '';
      });
    } else {
      if (_input == _firstPin) {
        Navigator.of(context).pop(_input);
      } else {
        setState(() {
          _error = true;
          _input = '';
          _firstPin = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Scaffold(
      appBar: AppBar(title: Text(_confirming ? 'Confirma tu PIN' : 'Crea un PIN')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _confirming ? 'Ingresa el PIN de nuevo' : 'Ingresa 4 a 6 dígitos',
                style: TextStyle(color: kredit.textSecondary),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final filled = i < _input.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _error
                          ? AppColors.danger
                          : (filled ? kredit.textPrimary : Colors.transparent),
                      border: Border.all(
                        color: _error ? AppColors.danger : AppColors.borderActive,
                      ),
                    ),
                  );
                }),
              ),
              if (_error) ...[
                const SizedBox(height: 12),
                const Text(
                  'Los PIN no coinciden, intenta de nuevo',
                  style: TextStyle(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: (MediaQuery.of(context).size.width * 0.7).clamp(220.0, 300.0),
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final d in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
                      _SetupPadButton(label: d, onTap: () => _onDigit(d)),
                    const SizedBox.shrink(),
                    _SetupPadButton(label: '0', onTap: () => _onDigit('0')),
                    _SetupPadButton(
                      icon: Icons.backspace_outlined,
                      onTap: _onBackspace,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _input.length >= 4 ? _onSubmit : null,
                child: Text(_confirming ? 'Confirmar' : 'Continuar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetupPadButton extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  const _SetupPadButton({this.label, this.icon, required this.onTap});

  @override
  State<_SetupPadButton> createState() => _SetupPadButtonState();
}

class _SetupPadButtonState extends State<_SetupPadButton> {
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
        shape: const CircleBorder(),
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
                    style: TextStyle(fontSize: 22, color: kredit.textPrimary),
                  )
                : Icon(widget.icon, color: kredit.textPrimary),
          ),
        ),
      ),
    );
  }
}
