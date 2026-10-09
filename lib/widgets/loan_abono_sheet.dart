import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/loan_calculator.dart';
import '../providers/credits_provider.dart';
import '../theme/app_theme.dart';
import '../utils/currency_input_formatter.dart';

/// Bottom sheet to register an "abono extra" (manual extra payment) on a
/// loan/cupo credit, mirroring the visual style of CardMovementSheet.
class LoanAbonoSheet extends ConsumerStatefulWidget {
  final String creditId;

  const LoanAbonoSheet({super.key, required this.creditId});

  static Future<void> show(BuildContext context, {required String creditId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: LoanAbonoSheet(creditId: creditId),
        ),
      ),
    );
  }

  @override
  ConsumerState<LoanAbonoSheet> createState() => _LoanAbonoSheetState();
}

class _LoanAbonoSheetState extends ConsumerState<LoanAbonoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _saving = false;
  // Default to reducirCuota: more common as a default in personal-finance
  // apps (lower payments going forward feels more immediately useful than a
  // shorter term), while still letting the user pick reducirPlazo.
  AbonoStrategy _strategy = AbonoStrategy.reducirCuota;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final amount = double.parse(CurrencyInputFormatter.unformat(_amountCtrl.text));
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final abono = await ref.read(creditsProvider.notifier).registerLoanAbono(
            widget.creditId,
            amount,
            note: _noteCtrl.text.trim(),
            strategy: _strategy,
          );
      if (mounted) {
        navigator.pop();
        final skipped = abono.installmentsSkipped;
        final message = abono.wasCapped
            ? 'Se aplicaron \$${abono.amount.toStringAsFixed(0)} de los '
                '\$${abono.requestedAmount.toStringAsFixed(0)} solicitados — '
                '¡crédito saldado por completo!'
            : 'Abono de \$${abono.amount.toStringAsFixed(0)} registrado'
                '${skipped > 0 ? ' — $skipped cuota(s) adelantada(s)' : ''}'
                '. Cronograma recalculado (estimado): confirma el valor real '
                'de las próximas cuotas con tu banco.';
        messenger.showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        messenger.showSnackBar(
          SnackBar(content: Text('No se pudo registrar el abono: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: kredit.borderCard,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.savings_outlined, size: KreditIconSize.small, color: accent),
                ),
                const SizedBox(width: 10),
                Text('Registrar Abono Extra', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'MONTO',
              style: TextStyle(
                fontSize: KreditTextSize.body,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: kredit.textTertiary,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: const [CurrencyInputFormatter()],
              autofocus: true,
              style: const TextStyle(fontSize: KreditTextSize.emphasis, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(prefixText: '\$ ', hintText: 'Ej. 500.000'),
              validator: (v) {
                final n = double.tryParse(CurrencyInputFormatter.unformat(v ?? ''));
                if (n == null || n <= 0) return 'Ingresa un monto válido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Nota / Descripción (opcional)',
                hintText: 'Ej. Abono con bono de fin de año',
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'QUÉ HACER CON EL SALDO',
              style: TextStyle(
                fontSize: KreditTextSize.body,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: kredit.textTertiary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Reducir cuota'),
                    selected: _strategy == AbonoStrategy.reducirCuota,
                    onSelected: (_) =>
                        setState(() => _strategy = AbonoStrategy.reducirCuota),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Reducir plazo'),
                    selected: _strategy == AbonoStrategy.reducirPlazo,
                    onSelected: (_) =>
                        setState(() => _strategy = AbonoStrategy.reducirPlazo),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _strategy == AbonoStrategy.reducirCuota
                  ? 'Mismo número de cuotas restantes, pero cada una más barata.'
                  : 'Misma cuota mensual, pero el crédito termina antes.',
              style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Guardando...' : 'Guardar Abono'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
