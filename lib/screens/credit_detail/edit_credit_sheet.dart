import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/credit.dart';
import '../../domain/card_calculator.dart';
import '../../domain/interest_rate.dart';
import '../../utils/currency_input_formatter.dart';
import '../../domain/loan_calculator.dart';
import '../../providers/credits_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/interest_rate_type_field.dart';
import '../../widgets/wallet_card.dart';

const List<String> _presetLenders = [
  'Bancolombia',
  'Nequi',
  'Nu (Nubank)',
  'Davivienda',
  'DaviPlata',
  'BBVA',
  'RappiCard',
  'Lulo Bank',
  'Banco de Bogotá',
  'Banco Falabella',
  'Scotiabank Colpatria',
  'Banco Popular',
  'Banco AV Villas',
  'Banco de Occidente',
  'Itaú',
  'Tarjeta Tuya / Éxito',
  'Otro...',
];

const List<String> _presetLocations = [
  'Ninguno / Prestamista',
  'Almacenes Éxito',
  'Alkosto / Ktronix',
  'Falabella',
  'Mercado Libre',
  'Amazon',
  'Jumbo / Metro',
  'Olímpica',
  'Apple Store',
  'Samsung Store',
  'Claro / Movistar',
  'Otro...',
];


/// "Editar Información del Crédito" form, mirroring #modal-edit-credit in
/// legacy_pwa/index.html (~L650-759) and updateCreditData() in app.js
/// (~L556-611). The credit type cannot be changed here.
class EditCreditSheet extends ConsumerStatefulWidget {
  final Credit credit;

  const EditCreditSheet({super.key, required this.credit});

  static Future<void> show(BuildContext context, Credit credit) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => EditCreditSheet(credit: credit),
    );
  }

  @override
  ConsumerState<EditCreditSheet> createState() => _EditCreditSheetState();
}

class _EditCreditSheetState extends ConsumerState<EditCreditSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _color;
  bool _saving = false;
  late String? _selectedLenderPreset =
      _presetLenders.contains(widget.credit.lender)
      ? widget.credit.lender
      : 'Otro...';
  late String? _selectedLocationPreset = () {
    if (widget.credit is! LoanCredit) return null;
    final loc = (widget.credit as LoanCredit).location ?? '';
    return _presetLocations.contains(loc)
        ? loc
        : (loc.isEmpty ? 'Ninguno / Prestamista' : 'Otro...');
  }();
  late final _nameCtrl = TextEditingController(text: widget.credit.name);
  late final _lenderCtrl = TextEditingController(text: widget.credit.lender);
  late final _notesCtrl = TextEditingController(
    text: widget.credit.notes ?? '',
  );

  // Loan
  late final _locationCtrl = TextEditingController(
    text: widget.credit is LoanCredit
        ? (widget.credit as LoanCredit).location ?? ''
        : '',
  );
  late final _quotaCtrl = TextEditingController(
    text: widget.credit is LoanCredit
        ? CurrencyInputFormatter.format(
            (widget.credit as LoanCredit).quotaAmount,
          )
        : '',
  );
  late final _interestCtrl = TextEditingController(
    text: widget.credit.isLoan
        ? (widget.credit as LoanCredit).interestRate.toString()
        : '',
  );

  // Card
  late final _limitCtrl = TextEditingController(
    text: widget.credit is CardCredit
        ? CurrencyInputFormatter.format(
            (widget.credit as CardCredit).creditLimit,
          )
        : '',
  );
  late final _interestCardCtrl = TextEditingController(
    text: widget.credit is CardCredit
        ? (widget.credit as CardCredit).interestRate.toString()
        : '',
  );
  late final _cutoffDayCtrl = TextEditingController(
    text: widget.credit is CardCredit
        ? (widget.credit as CardCredit).cutoffDay.toString()
        : '',
  );
  late final _paymentOffsetCtrl = TextEditingController(
    text: widget.credit is CardCredit
        ? (widget.credit as CardCredit).paymentDueOffsetDays.toString()
        : '',
  );
  late final _managementFeeCtrl = TextEditingController(
    text: widget.credit is CardCredit
        ? CurrencyInputFormatter.format(
            (widget.credit as CardCredit).managementFee,
          )
        : '',
  );
  late String _managementFeeFrequency = widget.credit is CardCredit
      ? (widget.credit as CardCredit).managementFeeFrequency
      : ManagementFeeFrequency.monthly;
  late String _interestRateType = widget.credit is CardCredit
      ? (widget.credit as CardCredit).interestRateType
      : widget.credit is LoanCredit
      ? (widget.credit as LoanCredit).interestRateType
      : InterestRateType.effectiveAnnual;

  @override
  void initState() {
    super.initState();
    _color = widget.credit.color ?? '#00F2FE';
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _lenderCtrl,
      _notesCtrl,
      _locationCtrl,
      _quotaCtrl,
      _interestCtrl,
      _limitCtrl,
      _interestCardCtrl,
      _cutoffDayCtrl,
      _paymentOffsetCtrl,
      _managementFeeCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // Non-blocking heads-up when the card's interest rate looks implausible
  // for the selected periodicity (e.g. "24" typed while "Mensual" is
  // selected). See `rateInconsistencyWarning` for the thresholds.
  String? get _interestRateWarning {
    final rate = double.tryParse(_interestCardCtrl.text.replaceAll(',', '.'));
    if (rate == null) return null;
    return rateInconsistencyWarning(rate, _interestRateType);
  }

  // Real bug fix: if the entered quota doesn't even cover the current
  // period's interest on the outstanding balance, the loan would never
  // amortize principal (interest-only forever, balance stuck or growing).
  // Computed BEFORE any mutation so it reflects the values the user is
  // about to save (new rate/type if changed, current remaining principal).
  String? _quotaTooLowWarning(LoanCredit credit, double newQuota) {
    final paidPrincipal =
        credit.installments.where((i) => i.paid).fold(0.0, (s, i) => s + i.principal);
    final remainingPrincipal = math.max(0.0, credit.totalAmount - paidPrincipal);
    final periodRate = periodicRateFrom(
      double.tryParse(_interestCtrl.text.replaceAll(',', '.')) ?? credit.interestRate,
      _interestRateType,
      credit.frequency,
    );
    if (periodRate <= 0) return null;
    final interestOnly = remainingPrincipal * periodRate;
    if (newQuota > interestOnly) return null;
    return 'Con una cuota de ${CurrencyInputFormatter.format(newQuota)} no se cubre ni '
        'siquiera el interés del período actual (${CurrencyInputFormatter.format(interestOnly)}). '
        'A este ritmo el crédito nunca se terminará de pagar: el capital nunca baja. '
        '¿Deseas continuar de todas formas?';
  }

  Future<bool> _confirmQuotaTooLow(String message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cuota insuficiente'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Guardar de todas formas'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final credit = widget.credit;
    // Loan-quota safety check must happen BEFORE mutating the credit (it
    // needs the pre-edit remaining principal) and before flipping _saving.
    var loanReprorated = false;
    if (credit is LoanCredit) {
      final newQuota = double.tryParse(
        CurrencyInputFormatter.unformat(_quotaCtrl.text),
      );
      final newInterestRate =
          double.tryParse(_interestCtrl.text.replaceAll(',', '.')) ?? 0;
      loanReprorated = (newQuota != null && newQuota != credit.quotaAmount) ||
          newInterestRate != credit.interestRate ||
          _interestRateType != credit.interestRateType;
      if (newQuota != null) {
        final warning = _quotaTooLowWarning(credit, newQuota);
        if (warning != null) {
          final proceed = await _confirmQuotaTooLow(warning);
          if (!proceed) return;
        }
      }
    }

    setState(() => _saving = true);

    credit.name = _nameCtrl.text.trim();
    credit.lender = _lenderCtrl.text.trim();
    credit.color = _color;
    credit.notes = _notesCtrl.text.trim();

    if (credit is CardCredit) {
      credit.creditLimit =
          double.tryParse(CurrencyInputFormatter.unformat(_limitCtrl.text)) ??
          0;
      final newCardRate =
          double.tryParse(_interestCardCtrl.text.replaceAll(',', '.')) ?? 0;
      if (newCardRate != credit.interestRate ||
          _interestRateType != credit.interestRateType) {
        // Close out interest already accrued under the OLD rate up to today
        // BEFORE overwriting it, so the new rate never gets back-applied to
        // cycles that already closed under the old one (see
        // applyRateChangeAt's doc comment for the full rationale).
        applyRateChangeAt(credit, DateTime.now());
      }
      credit.interestRate = newCardRate;
      credit.interestRateType = _interestRateType;
      credit.cutoffDay = int.tryParse(_cutoffDayCtrl.text) ?? 1;
      credit.paymentDueOffsetDays = int.tryParse(_paymentOffsetCtrl.text) ?? 20;
      credit.managementFee =
          double.tryParse(
            CurrencyInputFormatter.unformat(_managementFeeCtrl.text),
          ) ??
          0;
      credit.managementFeeFrequency = _managementFeeFrequency;
    } else if (credit is LoanCredit) {
      credit.location = _locationCtrl.text.trim();
      final newQuota = double.tryParse(
        CurrencyInputFormatter.unformat(_quotaCtrl.text),
      );
      final newInterestRate =
          double.tryParse(_interestCtrl.text.replaceAll(',', '.')) ?? 0;
      reprorateUnpaidInstallments(
        credit,
        newQuota: newQuota,
        newInterestRate: newInterestRate,
        newInterestRateType: _interestRateType,
      );
    }

    try {
      await ref.read(creditsProvider.notifier).updateCredit(credit);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loanReprorated
                  ? 'Crédito actualizado — cuotas futuras recalculadas '
                      '(estimado, confirma el valor real con tu banco)'
                  : 'Crédito actualizado correctamente',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar los cambios: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCard = widget.credit is CardCredit;
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(KreditSpacing.card),
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
                Text(
                  'Editar Información del Crédito',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                // Live preview of the card as user edits lender/name
                Builder(
                  builder: (context) {
                    final loan = widget.credit is LoanCredit
                        ? widget.credit as LoanCredit
                        : null;
                    final previewCredit = loan != null
                        ? LoanCredit(
                            id: loan.id,
                            name: _nameCtrl.text.isEmpty
                                ? loan.name
                                : _nameCtrl.text,
                            lender: _lenderCtrl.text.isEmpty
                                ? loan.lender
                                : _lenderCtrl.text,
                            totalAmount: loan.totalAmount,
                            quotaAmount: loan.quotaAmount,
                            interestRate: loan.interestRate,
                            interestRateType: loan.interestRateType,
                            totalInstallments: loan.totalInstallments,
                            startDate: loan.startDate,
                            frequency: loan.frequency,
                            color: _color,
                            location: _locationCtrl.text,
                            // Carry over the real schedule/history so the
                            // preview's "DEUDA RESTANTE" reflects the actual
                            // remaining balance instead of defaulting to $0
                            // (LoanCredit's installments param is optional
                            // and empty unless explicitly passed).
                            installments: loan.installments,
                            abonos: loan.abonos,
                          )
                        : CardCredit(
                            id: widget.credit.id,
                            name: _nameCtrl.text.isEmpty
                                ? widget.credit.name
                                : _nameCtrl.text,
                            lender: _lenderCtrl.text.isEmpty
                                ? widget.credit.lender
                                : _lenderCtrl.text,
                            creditLimit:
                                (widget.credit as CardCredit).creditLimit,
                            currentBalance:
                                (widget.credit as CardCredit).currentBalance,
                            cutoffDay: int.tryParse(_cutoffDayCtrl.text) ?? 15,
                            paymentDueOffsetDays:
                                int.tryParse(_paymentOffsetCtrl.text) ?? 20,
                            interestRate:
                                (widget.credit as CardCredit).interestRate,
                            interestRateType:
                                (widget.credit as CardCredit).interestRateType,
                            managementFee:
                                (widget.credit as CardCredit).managementFee,
                            managementFeeFrequency: (widget.credit as CardCredit)
                                .managementFeeFrequency,
                            cycleCount:
                                (widget.credit as CardCredit).cycleCount,
                            lastAccrualCutoff:
                                (widget.credit as CardCredit).lastAccrualCutoff,
                            color: _color,
                            // Carry over real movement history so the preview
                            // reflects the actual current balance/cupo.
                            movements: (widget.credit as CardCredit).movements,
                          );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'VISTA PREVIA DE TARJETA',
                          style: TextStyle(
                            fontSize: KreditTextSize.label,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        WalletCard(credit: previewCredit),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
                // "Datos Básicos" ahora es una tarjeta sutil más — antes
                // flotaba sin ninguna agrupación visual mientras el resto
                // del sheet (Datos Financieros y sus _EditSectionCard) sí
                // la tenía, rompiendo la separación consistente.
                _EditSectionCard(
                  label: 'DATOS BÁSICOS',
                  icon: Icons.badge_outlined,
                  children: [
                    // Nombre y Banco lado a lado — reduce el espacio
                    // vertical que ocupaban antes uno debajo del otro.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nombre del Crédito',
                              isDense: true,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Requerido'
                                : null,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                              isExpanded: true,
                            initialValue: _selectedLenderPreset,
                            decoration: const InputDecoration(
                              labelText: 'Banco / Prestamista',
                              isDense: true,
                            ),
                            items: _presetLenders
                                .map(
                                  (l) => DropdownMenuItem(value: l, child: Text(l)),
                                )
                                .toList(),
                            onChanged: (v) {
                              setState(() {
                                _selectedLenderPreset = v;
                                if (v != null && v != 'Otro...') {
                                  _lenderCtrl.text = v;
                                  final lower = v.toLowerCase();
                                  if (lower.contains('nequi')) {
                                    _color = '#DA0081';
                                  } else if (lower.contains('nu')) {
                                    _color = '#820AD1';
                                  } else if (lower.contains('bancolombia')) {
                                    _color = '#FFDD00';
                                  } else if (lower.contains('davivienda') ||
                                      lower.contains('daviplata')) {
                                    _color = '#E4032E';
                                  } else if (lower.contains('bbva')) {
                                    _color = '#004481';
                                  } else if (lower.contains('rappi')) {
                                    _color = '#FE3F23';
                                  } else if (lower.contains('lulo')) {
                                    _color = '#00E28A';
                                  } else if (lower.contains('popular')) {
                                    _color = '#00875A';
                                  } else if (lower.contains('occidente')) {
                                    _color = '#00205B';
                                  } else if (lower.contains('villas')) {
                                    _color = '#0055A5';
                                  } else if (lower.contains('itaú') ||
                                      lower.contains('itau')) {
                                    _color = '#EC7000';
                                  } else if (lower.contains('tuya') ||
                                      lower.contains('exito')) {
                                    _color = '#FFD100';
                                  }
                                } else if (v == 'Otro...') {
                                  _lenderCtrl.clear();
                                }
                              });
                            },
                            validator: (_) => (_lenderCtrl.text.trim().isEmpty)
                                ? 'Requerido'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    if (_selectedLenderPreset == 'Otro...') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _lenderCtrl,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Escribir libre',
                          hintText: 'Ej. PrestaYa...',
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.request_quote_outlined,
                      size: 14,
                      color: kredit.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Datos Financieros',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: KreditTextSize.bodyLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!isCard) ...[
                  _EditSectionCard(
                    label: 'DÓNDE Y CON QUÉ',
                    icon: Icons.storefront_outlined,
                    children: [
                      DropdownButtonFormField<String>(
                          isExpanded: true,
                        initialValue: _selectedLocationPreset,
                        decoration: const InputDecoration(
                          labelText: 'Comercio / Establecimiento',
                        ),
                        items: _presetLocations
                            .map(
                              (loc) => DropdownMenuItem(
                                value: loc,
                                child: Text(loc),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedLocationPreset = v;
                            if (v != null && v != 'Otro...') {
                              _locationCtrl.text =
                                  v == 'Ninguno / Prestamista' ? '' : v;
                            } else if (v == 'Otro...') {
                              _locationCtrl.clear();
                            }
                          });
                        },
                      ),
                      if (_selectedLocationPreset == 'Otro...') ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _locationCtrl,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Escribir libre',
                            hintText: 'Ej. Tienda de la esquina...',
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  _EditSectionCard(
                    label: 'MONTO Y CUOTA',
                    icon: Icons.request_quote_outlined,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _interestCtrl,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Interés anual (%)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InterestRateTypeField(
                              value: _interestRateType,
                              onChanged: (v) =>
                                  setState(() => _interestRateType = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _quotaCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: const [CurrencyInputFormatter()],
                        decoration: const InputDecoration(
                          labelText: 'Valor Cuota (\$)',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Normalmente se recalcula sola según monto, cuotas e '
                        'interés, pero puedes sobreescribirla manualmente si '
                        'renegociaste con el banco.',
                        style: TextStyle(
                          fontSize: KreditTextSize.label,
                          color: kredit.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  _EditSectionCard(
                    label: 'LÍMITE E INTERÉS',
                    icon: Icons.credit_card_outlined,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _limitCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: const [CurrencyInputFormatter()],
                              decoration: const InputDecoration(
                                labelText: 'Límite Total (\$)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _interestCardCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Interés anual (%)',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InterestRateTypeField(
                        value: _interestRateType,
                        onChanged: (v) => setState(() => _interestRateType = v),
                      ),
                      if (_interestRateWarning != null)
                        _EditInterestRateWarningHint(
                          text: _interestRateWarning!,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _EditSectionCard(
                    label: 'CORTE Y FECHA DE PAGO',
                    icon: Icons.event_available_outlined,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue:
                                  int.tryParse(_cutoffDayCtrl.text) ?? 15,
                              decoration: const InputDecoration(
                                labelText: 'Día de Corte',
                              ),
                              items: List.generate(31, (i) => i + 1)
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d,
                                      child: Text('Día $d de cada mes'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(
                                    () => _cutoffDayCtrl.text = v.toString(),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue:
                                  int.tryParse(_paymentOffsetCtrl.text) ?? 20,
                              decoration: const InputDecoration(
                                labelText: 'Días Hasta Fecha Límite',
                              ),
                              items: [10, 15, 20, 25, 30, 35, 40]
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d,
                                      child: Text('$d días después del corte'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(
                                    () =>
                                        _paymentOffsetCtrl.text = v.toString(),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _EditSectionCard(
                    label: 'MANTENIMIENTO',
                    icon: Icons.percent_outlined,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _managementFeeCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: const [CurrencyInputFormatter()],
                              decoration: const InputDecoration(
                                labelText: 'Cuota de Mantenimiento (\$)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                                isExpanded: true,
                              initialValue: _managementFeeFrequency,
                              decoration: const InputDecoration(
                                labelText: 'Frecuencia de Cobro',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: ManagementFeeFrequency.monthly,
                                  child: Text('Mensual'),
                                ),
                                DropdownMenuItem(
                                  value: ManagementFeeFrequency.annual,
                                  child: Text('Anual'),
                                ),
                              ],
                              onChanged: (v) => setState(
                                () => _managementFeeFrequency =
                                    v ?? ManagementFeeFrequency.monthly,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                // Su propia tarjeta, como el resto del sheet — antes era un
                // TextFormField suelto con el subrayado default de Material,
                // que quedaba flotando sin relación clara con el texto
                // arriba. Con la tarjeta como contenedor, el borde interno
                // ya no hace falta (InputBorder.none): el propio cuadro
                // cumple ese rol.
                _EditSectionCard(
                  label: 'NOTAS',
                  icon: Icons.sticky_note_2_outlined,
                  children: [
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Indicaciones, comentarios, garantía...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Guardando...' : 'Guardar Cambios'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Groups a related cluster of fields within the edit form (e.g.
/// "monto/cuota" vs. "corte/fecha de pago") inside a subtle card — same
/// soft-surface language as `_DashboardSectionCard` in dashboard_screen.dart
/// (bgCard background, KreditRadius.card, near-invisible border) instead of
/// a bare typographic heading + hairline divider. With several of these
/// sections stacked in one long scrolling sheet, a faint box per group reads
/// as a clearer separation than a divider alone — the user specifically
/// asked for this after finding the plain divider version hard to scan.
class _EditSectionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Widget> children;

  const _EditSectionCard({
    required this.label,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KreditSpacing.card),
      decoration: BoxDecoration(
        color: kredit.bgCard,
        borderRadius: BorderRadius.circular(KreditRadius.card),
        border: Border.all(color: kredit.borderCard.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: kredit.textTertiary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: KreditTextSize.label,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: kredit.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

/// Small amber/warning hint shown below the interest-rate field when
/// [rateInconsistencyWarning] flags a likely periodicity mix-up. Purely
/// informational — never blocks saving.
class _EditInterestRateWarningHint extends StatelessWidget {
  final String text;
  const _EditInterestRateWarningHint({required this.text});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 14,
            color: AppColors.warning,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: KreditTextSize.label, color: kredit.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}
