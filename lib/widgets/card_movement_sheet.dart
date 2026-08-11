import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/card_movement.dart';
import '../providers/credits_provider.dart';
import '../theme/app_theme.dart';

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
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final amount = double.parse(_amountCtrl.text.replaceAll(',', '.'));
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
          SnackBar(content: Text('No se pudo registrar el movimiento: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCharge = widget.movementType == CardMovementType.charge;
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
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
                    size: 18,
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
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: kredit.textTertiary,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(prefixText: '\$ ', hintText: 'Ej. 80000'),
              validator: (v) {
                final n = double.tryParse((v ?? '').replaceAll(',', '.'));
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
              'Sugerencias rápidas',
              style: TextStyle(fontSize: 11, color: kredit.textTertiary),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: (isCharge
                      ? ['Supermercado', 'Tecnología', 'Restaurante', 'Servicios públicos', 'Gasolina']
                      : ['Pago mensual de cuota', 'Abono extraordinario', 'Pago desde Nequi', 'Pago desde Bancolombia'])
                  .map((preset) => ActionChip(
                        label: Text(preset, style: const TextStyle(fontSize: 11)),
                        onPressed: () {
                          setState(() => _noteCtrl.text = preset);
                        },
                      ))
                  .toList(),
            ),
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
