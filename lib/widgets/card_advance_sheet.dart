import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/credit.dart';
import '../domain/card_calculator.dart';
import '../providers/credits_provider.dart';
import '../theme/app_theme.dart';
import '../utils/credit_display_utils.dart';
import '../utils/currency_input_formatter.dart';
import 'kredit_section_card.dart';

/// Bottom sheet for registering a cash advance (avance) on a card credit.
class CardAdvanceSheet extends ConsumerStatefulWidget {
  final CardCredit credit;

  const CardAdvanceSheet({super.key, required this.credit});

  static void show(BuildContext context, {required CardCredit credit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: CardAdvanceSheet(credit: credit),
        ),
      ),
    );
  }

  @override
  ConsumerState<CardAdvanceSheet> createState() => _CardAdvanceSheetState();
}

class _CardAdvanceSheetState extends ConsumerState<CardAdvanceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _installmentsCtrl = TextEditingController();
  final _interestRateCtrl = TextEditingController();
  final _commissionCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  DateTime _advanceDate = DateTime.now();
  DateTime? _firstPaymentDate;
  String? _destination; // null = ninguno
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _installmentsCtrl.dispose();
    _interestRateCtrl.dispose();
    _commissionCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate({required bool isFirstPayment}) async {
    final initial = isFirstPayment ? (_firstPaymentDate ?? DateTime.now()) : _advanceDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isFirstPayment) {
        _firstPaymentDate = picked;
      } else {
        _advanceDate = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final amount = double.parse(CurrencyInputFormatter.unformat(_amountCtrl.text));
    final installments = int.tryParse(_installmentsCtrl.text.trim());
    final interestRate = double.tryParse(_interestRateCtrl.text.trim().replaceAll(',', '.'));
    final commission = double.tryParse(CurrencyInputFormatter.unformat(_commissionCtrl.text));
    final note = _noteCtrl.text.trim();

    try {
      await ref.read(creditsProvider.notifier).registerAdvance(
            widget.credit.id,
            amount: amount,
            date: _fmt(_advanceDate),
            installments: installments,
            interestRate: interestRate,
            commission: commission,
            firstPaymentDate: _firstPaymentDate != null ? _fmt(_firstPaymentDate!) : null,
            destination: _destination,
            note: note,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avance registrado')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo registrar el avance. Intenta de nuevo.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    final available = getCardAvailableLimit(widget.credit);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
                      Icons.payments_rounded,
                      size: KreditIconSize.small,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Registrar avance',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          widget.credit.name,
                          style: TextStyle(
                            fontSize: KreditTextSize.body,
                            color: kredit.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Cupo disponible: ${formatCOP(available)}',
                style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textSecondary),
              ),
              const SizedBox(height: 20),

              // Monto
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
                style: const TextStyle(
                  fontSize: KreditTextSize.emphasis,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  prefixText: '\$ ',
                  hintText: 'Ej. 500.000',
                ),
                validator: (v) {
                  final n = double.tryParse(CurrencyInputFormatter.unformat(v ?? ''));
                  if (n == null || n <= 0) return 'Ingresa un monto válido';
                  return null;
                },
              ),
              const SizedBox(height: 4),
              Text(
                'Disponible: ${formatCOP(available)}',
                style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
              ),
              const SizedBox(height: 20),

              // Condiciones
              KreditSectionCard(
                label: 'Condiciones (opcionales)',
                children: [
                  TextFormField(
                    controller: _installmentsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Número de cuotas',
                      hintText: 'Ej. 12',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _interestRateCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Tasa de interés %',
                      hintText: 'Ej. 2.5',
                      suffixText: '%',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _commissionCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [CurrencyInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Comisión',
                      hintText: 'Ej. 15.000',
                      prefixText: '\$ ',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Fechas
              KreditSectionCard(
                label: 'Fechas',
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.calendar_today_rounded, size: KreditIconSize.small, color: accent),
                    title: const Text('Fecha del avance'),
                    subtitle: Text(_fmt(_advanceDate)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _pickDate(isFirstPayment: false),
                  ),
                  Divider(height: 1, color: kredit.borderCard),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.event_rounded, size: KreditIconSize.small, color: accent),
                    title: const Text('Primera fecha de pago'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_firstPaymentDate != null ? _fmt(_firstPaymentDate!) : 'No definida'),
                        Text(
                          'Sugerido según el ciclo de tu tarjeta',
                          style: TextStyle(
                            fontSize: KreditTextSize.body,
                            color: kredit.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _pickDate(isFirstPayment: true),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Destino
              Text(
                'DESTINO (OPCIONAL)',
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
                children: ['Efectivo', 'Transferencia', 'Otro'].map((label) {
                  final selected = _destination == label;
                  return ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _destination = selected ? null : label);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Notas
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notas',
                  hintText: 'Ej. Avance en cajero Bancolombia',
                ),
              ),
              const SizedBox(height: 24),

              // Botón
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Guardando...' : 'Registrar avance'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
