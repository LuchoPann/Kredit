import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/card_movement.dart';
import '../data/models/credit.dart';
import '../domain/card_calculator.dart';
import '../providers/credits_provider.dart';
import '../theme/app_theme.dart';
import '../utils/credit_display_utils.dart';
import '../utils/currency_input_formatter.dart';

/// Bottom sheet to register a charge/payment on a card credit, mirroring
/// #modal-card-movement in legacy_pwa/index.html (~L762-784) and
/// saveCardMovement in app.js.
class CardMovementSheet extends ConsumerStatefulWidget {
  final String creditId;
  final String movementType; // CardMovementType.charge | .payment

  const CardMovementSheet({
    super.key,
    required this.creditId,
    required this.movementType,
  });

  static Future<void> show(
    BuildContext context, {
    required String creditId,
    required String movementType,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CardMovementSheet(
        creditId: creditId,
        movementType: movementType,
      ),
    );
  }

  @override
  ConsumerState<CardMovementSheet> createState() => _CardMovementSheetState();
}

class _CardMovementSheetState extends ConsumerState<CardMovementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountCtrl.removeListener(_onAmountChanged);
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _onAmountChanged() => setState(() {});

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final amount = double.parse(CurrencyInputFormatter.unformat(_amountCtrl.text));
    try {
      await ref.read(creditsProvider.notifier).registerMovement(
            widget.creditId,
            widget.movementType,
            amount,
            _noteCtrl.text.trim(),
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.movementType == CardMovementType.payment
                  ? 'Pago registrado'
                  : 'Cargo registrado',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        debugPrint('registerMovement failed: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo registrar el movimiento. Intenta de nuevo.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCharge = widget.movementType == CardMovementType.charge;
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;

    // Non-blocking overlimit warning: Colombian card issuers sometimes allow
    // a charge that pushes the balance past the credit limit (with a fee),
    // so this only informs — it never disables the save button.
    double? overlimitBy;
    if (isCharge) {
      final credits = ref.watch(creditsProvider).value ?? [];
      final credit = credits.whereType<CardCredit>().where((c) => c.id == widget.creditId).firstOrNull;
      final amount = double.tryParse(CurrencyInputFormatter.unformat(_amountCtrl.text));
      if (credit != null && amount != null && amount > 0) {
        final available = getCardAvailableLimit(credit);
        if (amount > available) {
          overlimitBy = amount - available;
        }
      }
    }
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
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
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: kredit.borderCard,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // --- Header: icon badge + title, so the movement type reads at
            // a glance instead of only through the plain text title.
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
                  child: Icon(
                    isCharge ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    size: KreditIconSize.small,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  isCharge ? 'Registrar Cargo/Compra' : 'Registrar Pago',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'MONTO',
              style: TextStyle(
                fontSize: KreditTextSize.caption,
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
              decoration: const InputDecoration(prefixText: '\$ ', hintText: 'Ej. 80.000'),
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
                labelText: 'Nota / Descripción',
                hintText: 'Ej. Compra en supermercado, Pago desde Nequi',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'SUGERENCIAS RÁPIDAS',
              style: TextStyle(
                fontSize: KreditTextSize.caption,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: kredit.textTertiary,
              ),
            ),
            const SizedBox(height: 4),
            Divider(height: 1, color: kredit.borderCard),
            const SizedBox(height: 4),
            // Sugerencias como texto tocable en vez de chips con fondo:
            // jerarquía tipográfica + puntos separadores, sin cajas.
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final preset in (isCharge
                    ? const ['Supermercado', 'Tecnología', 'Restaurante', 'Servicios públicos', 'Gasolina']
                    : const ['Pago mensual de cuota', 'Abono extraordinario', 'Pago desde Nequi', 'Pago desde Bancolombia']))
                  Padding(
                    padding: const EdgeInsets.only(right: 12, top: 6),
                    child: InkWell(
                      onTap: () => setState(() => _noteCtrl.text = preset),
                      child: Text(
                        preset,
                        style: TextStyle(
                          fontSize: KreditTextSize.caption,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (overlimitBy != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: KreditIconSize.small,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Este cargo supera el cupo disponible por ${formatCOP(overlimitBy)}. '
                        'Algunos bancos permiten sobrecupo con un cargo adicional; revisa las '
                        'condiciones de tu tarjeta antes de continuar.',
                        style: TextStyle(
                          fontSize: KreditTextSize.caption,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Guardando...' : 'Guardar Movimiento'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
