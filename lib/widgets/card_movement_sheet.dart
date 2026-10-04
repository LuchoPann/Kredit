import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/card_movement.dart';
import '../data/models/credit.dart';
import '../domain/card_calculator.dart';
import '../providers/credits_provider.dart';
import '../theme/app_theme.dart';
import '../utils/credit_display_utils.dart';
import '../utils/currency_input_formatter.dart';

/// Bottom sheet to register a charge/payment on a card credit.
class CardMovementSheet extends ConsumerStatefulWidget {
  final String creditId;
  final String movementType;

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
      backgroundColor: Colors.transparent,
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

  String _mesEs(int m) =>
      const ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'][m - 1];

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

    final credits = ref.watch(creditsProvider).value ?? [];
    final credit = credits.whereType<CardCredit>().where((c) => c.id == widget.creditId).firstOrNull;

    double? overlimitBy;
    if (isCharge && credit != null) {
      final amount = double.tryParse(CurrencyInputFormatter.unformat(_amountCtrl.text));
      if (amount != null && amount > 0) {
        final available = getCardAvailableLimit(credit);
        if (amount > available) overlimitBy = amount - available;
      }
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
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
            // Header
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
                  isCharge ? 'Nueva compra' : 'Registrar pago',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isCharge
                  ? 'Registra lo que compraste con la tarjeta — suma a tu saldo.'
                  : 'Registra lo que le pagaste al banco — reduce tu saldo.',
              style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
            ),
            // Contexto de extracto
            if (credit != null) ...[
              const SizedBox(height: 12),
              Builder(builder: (ctx) {
                final dates = getCardCycleDates(credit);
                if (isCharge) {
                  final cutoffLabel = '${dates.nextCutoff.day} de ${_mesEs(dates.nextCutoff.month)}';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accent.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.receipt_long_outlined, size: KreditIconSize.small, color: accent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Esta compra aparecerá en el extracto que cierra el $cutoffLabel.',
                            style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textSecondary, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  final cutoffLabel = '${dates.lastCutoff.day} de ${_mesEs(dates.lastCutoff.month)}';
                  final dueLabel = '${dates.dueDate.day} de ${_mesEs(dates.dueDate.month)}';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accent.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, size: KreditIconSize.small, color: accent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Estás pagando el extracto cerrado el $cutoffLabel. Fecha límite: $dueLabel.',
                            style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textSecondary, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              }),
            ],
            // Monto + Nota agrupados
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kredit.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kredit.borderCard),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    decoration: const InputDecoration(prefixText: '\$ ', hintText: 'Ej. 80.000'),
                    validator: (v) {
                      final n = double.tryParse(CurrencyInputFormatter.unformat(v ?? ''));
                      if (n == null || n <= 0) return 'Ingresa un monto válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nota / Descripción',
                      hintText: 'Ej. Compra en supermercado, Pago desde Nequi',
                    ),
                  ),
                ],
              ),
            ),
            // Sugerencias como chips
            const SizedBox(height: 16),
            Text(
              'SUGERENCIAS',
              style: TextStyle(
                fontSize: KreditTextSize.body,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: kredit.textTertiary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in (isCharge
                    ? const ['Supermercado', 'Tecnología', 'Restaurante', 'Servicios públicos', 'Gasolina']
                    : const ['Pago mensual', 'Pago total del extracto', 'Abono parcial', 'Pago mínimo']))
                  GestureDetector(
                    onTap: () => setState(() => _noteCtrl.text = preset),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: kredit.borderCard),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        preset,
                        style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textSecondary),
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
                    Icon(Icons.info_outline, size: KreditIconSize.small, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Este cargo supera el cupo disponible por ${formatCOP(overlimitBy)}. '
                        'Algunos bancos permiten sobrecupo con un cargo adicional; revisa las '
                        'condiciones de tu tarjeta antes de continuar.',
                        style: TextStyle(fontSize: KreditTextSize.body, color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
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
        ),
      ),
    );
  }
}
