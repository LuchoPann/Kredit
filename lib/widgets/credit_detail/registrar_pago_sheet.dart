import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/credit.dart';
import '../../data/models/installment.dart';
import '../../data/models/pago_realizado.dart';
import '../../domain/date_utils.dart';
import '../../providers/credits_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/pagos_realizados_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/credit_display_utils.dart';
import '../../utils/currency_input_formatter.dart';

class RegistrarPagoSheet extends ConsumerStatefulWidget {
  final LoanCredit credit;
  final Installment installment;

  const RegistrarPagoSheet({
    super.key,
    required this.credit,
    required this.installment,
  });

  static Future<void> show(
    BuildContext context,
    LoanCredit credit,
    Installment installment,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => RegistrarPagoSheet(credit: credit, installment: installment),
    );
  }

  @override
  ConsumerState<RegistrarPagoSheet> createState() => _RegistrarPagoSheetState();
}

class _RegistrarPagoSheetState extends ConsumerState<RegistrarPagoSheet> {
  late final TextEditingController _montoCtrl;
  late final TextEditingController _notaCtrl;
  late DateTime _fecha;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _montoCtrl = TextEditingController(
      text: CurrencyInputFormatter.format(widget.installment.amount),
    );
    _notaCtrl = TextEditingController();
    _fecha = DateTime.now();
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _notaCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final raw = CurrencyInputFormatter.unformat(_montoCtrl.text);
    final monto = double.tryParse(raw);
    if (monto == null || monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto válido.')),
      );
      return;
    }

    setState(() => _saving = true);

    final db = ref.read(databaseProvider);
    final pago = PagoRealizado(
      creditId: widget.credit.id,
      fecha: toDateStr(_fecha),
      monto: monto,
      tipo: PagoRealizadoTipo.cuota,
      numeroCuota: widget.installment.number,
      nota: _notaCtrl.text.trim(),
    );

    await db.insertPagoRealizado(pago);

    if (!widget.installment.paid) {
      await ref
          .read(creditsProvider.notifier)
          .toggleInstallmentPaid(widget.credit.id, widget.installment.number);
    }

    ref.invalidate(pagosRealizadosProvider(widget.credit.id));

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago registrado')),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    final inst = widget.installment;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.card,
        right: AppSpacing.card,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.card,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Registrar pago — Cuota #${inst.number}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Proyectado: ${formatCOP(inst.amount)} · Vence ${formatDate(inst.dueDate)}',
            style: TextStyle(fontSize: AppTextSize.body, color: kredit.textTertiary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _montoCtrl,
            decoration: const InputDecoration(
              labelText: 'Monto real pagado',
              prefixText: r'$ ',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [const CurrencyInputFormatter()],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(AppRadius.tile),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Fecha de pago',
                suffixIcon: Icon(Icons.calendar_today_outlined),
              ),
              child: Text(formatDate(toDateStr(_fecha))),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notaCtrl,
            decoration: const InputDecoration(
              labelText: 'Nota (opcional)',
              hintText: 'Ej: pago parcial, banco X...',
            ),
            maxLines: 1,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Registrar pago'),
          ),
        ],
      ),
    );
  }
}
