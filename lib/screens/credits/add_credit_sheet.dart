import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/card_movement.dart';
import '../../data/models/credit.dart';
import '../../data/models/installment.dart';
import '../../domain/bank_detector.dart';
import '../../utils/currency_input_formatter.dart';
import '../../domain/card_calculator.dart';
import '../../domain/date_utils.dart';
import '../../domain/entity_templates.dart';
import '../../domain/interest_rate.dart';
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

/// Full-screen "Registrar Nuevo Crédito" form, mirroring #modal-add-credit
/// in legacy_pwa/index.html (~L494-648) and saveCredit() in app.js
/// (~L420-514).
class AddCreditSheet extends ConsumerStatefulWidget {
  const AddCreditSheet({super.key});

  @override
  ConsumerState<AddCreditSheet> createState() => _AddCreditSheetState();
}

class _AddCreditSheetState extends ConsumerState<AddCreditSheet> {
  final _formKey = GlobalKey<FormState>();

  String _type = CreditType.loan;
  String _color = '#00F2FE';
  bool _saving = false;

  // Stepper state (Tarea 1). Only the fields belonging to the current step
  // are mounted under the single Form below, so `_formKey.currentState!
  // .validate()` naturally scopes itself to what's visible on screen while
  // the controllers (declared on State, not on the widget tree) stay alive
  // across steps.
  int _currentStep = 0;
  static const int _lastStep = 2;

  final _nameCtrl = TextEditingController();
  final _lenderCtrl = TextEditingController(text: 'Bancolombia');
  final _notesCtrl = TextEditingController();

  // Loan fields
  final _locationCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _installmentsCtrl = TextEditingController();
  final _quotaCtrl = TextEditingController();
  // Fase 5 / pedido directo: permite registrar un crédito que ya llevaba
  // cuotas pagadas antes de existir en la app (ej. un préstamo que empezó
  // hace 2 meses). Marca las primeras N cuotas generadas como pagadas al
  // guardar — ver `_markAdvancedInstallments`.
  final _paidInstallmentsCtrl = TextEditingController();
  final _interestCtrl = TextEditingController();
  String _interestRateType = InterestRateType.effectiveAnnual;
  String _frequency = CreditFrequency.monthly;
  DateTime? _startDate;

  String? _selectedLenderPreset = 'Bancolombia';

  // Sub-entity refine step (e.g. Falabella -> CMR Falabella / Banco
  // Falabella): tracks the label of whichever sub-brand the user picked, so
  // the dropdown stays selected across rebuilds. Reset whenever the parent
  // entity changes (see the lender dropdown's onChanged below).
  String? _selectedSubEntityLabel;

  // Card fields
  final _limitCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController(text: '0');
  final _cutoffDayCtrl = TextEditingController(text: '15');
  final _paymentOffsetCtrl = TextEditingController(text: '20');
  final _managementFeeCtrl = TextEditingController(text: '0');
  String _managementFeeFrequency = ManagementFeeFrequency.monthly;

  // Tarea "plantillas por entidad": tracks whether the user manually picked
  // a cutoff/payment-offset value, so the entity-template autofill never
  // overwrites something they already chose (same "don't stomp user input"
  // pattern as `_suggestQuota`). Both fields ship pre-filled with generic
  // defaults (15 / 20), so we can't rely on "field is empty" alone.
  bool _cutoffDayTouched = false;
  bool _paymentOffsetTouched = false;
  String? _entityTemplateNote;

  // Autofills the card's cutoff day / payment offset from `entity_templates.dart`
  // when the lender text matches a known entity — only if the user hasn't
  // manually touched those fields yet. Purely a suggested starting point
  // (not official bank data); the user can always overwrite it.
  void _applyEntityTemplate() {
    if (_type != CreditType.card) return;
    final template = matchEntityTemplate(_lenderCtrl.text);
    if (template == null) {
      setState(() => _entityTemplateNote = null);
      return;
    }
    var applied = false;
    if (!_cutoffDayTouched && template.typicalCutoffDay != null) {
      _cutoffDayCtrl.text = template.typicalCutoffDay.toString();
      applied = true;
    }
    if (!_paymentOffsetTouched && template.typicalPaymentOffsetDays != null) {
      _paymentOffsetCtrl.text = template.typicalPaymentOffsetDays.toString();
      applied = true;
    }
    setState(() {
      _entityTemplateNote = applied
          ? 'Sugerido según patrón típico de ${_lenderCtrl.text.trim()}, verifica en tu estado de cuenta.'
              '${template.note.isNotEmpty ? ' ${template.note}' : ''}'
          : null;
    });
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _lenderCtrl,
      _notesCtrl,
      _locationCtrl,
      _amountCtrl,
      _installmentsCtrl,
      _quotaCtrl,
      _paidInstallmentsCtrl,
      _interestCtrl,
      _limitCtrl,
      _balanceCtrl,
      _cutoffDayCtrl,
      _paymentOffsetCtrl,
      _managementFeeCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // Fixed-installment ("cuota fija") amount under French amortization:
  // PMT = amount * i / (1 - (1+i)^-n), where `i` is the *periodic* rate for
  // the loan's chosen frequency (weekly/biweekly/monthly), reusing
  // `periodicRateFrom` from interest_rate.dart so this always agrees with
  // whatever rate periodicity/frequency conversion the rest of the app
  // uses. Falls back to simple division (amount / n) when there's no
  // interest rate at all, matching the old (pre-formula) suggestion.
  double? _calcSuggestedQuota() {
    final amount = double.tryParse(CurrencyInputFormatter.unformat(_amountCtrl.text));
    final installments = int.tryParse(_installmentsCtrl.text);
    if (amount == null || amount <= 0 || installments == null || installments <= 0) {
      return null;
    }
    final rate = double.tryParse(_interestCtrl.text.replaceAll(',', '.'));
    if (rate == null || rate <= 0) {
      return amount / installments;
    }
    final i = periodicRateFrom(rate, _interestRateType, _frequency);
    if (i <= 0) return amount / installments;
    final denom = 1 - math.pow(1 + i, -installments);
    if (denom <= 0) return amount / installments;
    return amount * i / denom;
  }

  // Live-recalculates the quota (French amortization / PMT) whenever
  // monto/cuotas/tasa/frecuencia/tipo-de-tasa change. The quota field is
  // read-only in this form (the user cannot override it manually — see
  // the "Valor de la Cuota" field below), so this simply keeps `_quotaCtrl`
  // in sync with whatever the calculator suggests.
  void _recalcSuggestedQuota() {
    final suggested = _calcSuggestedQuota();
    if (suggested != null) {
      _quotaCtrl.text = CurrencyInputFormatter.format(suggested);
    }
    setState(() {});
  }

  // Port of checkTypeSuggestion (app.js ~L340-354).
  ({bool show, String text})? get _typeSuggestion {
    if (_type != CreditType.card) return null;
    final lender = _lenderCtrl.text.toLowerCase();
    final isNequi = lender.contains('nequi');
    final isDaviplata = lender.contains('daviplata');
    if (!isNequi && !isDaviplata) return null;
    final text = isNequi
        ? 'Nequi no opera con tarjeta de crédito rotativa: su producto es de cuotas fijas. Te recomendamos registrarlo como Préstamo / Cuotas fijas.'
        : 'DaviPlata ofrece dos productos distintos: el Nanocrédito (cuotas fijas) y la tarjeta de crédito rotativa. Si tienes el Nanocrédito, es mejor registrarlo como Préstamo / Cuotas fijas.';
    return (show: true, text: text);
  }

  // Non-blocking heads-up for a possibly mis-entered interest rate. The
  // field is labeled as an annual/E.A. rate, but it's common in Colombia
  // to accidentally type the monthly rate instead (or vice versa for a
  // card). This never blocks saving — it's purely informational, shown
  // with the same style as the entity-template hint above.
  //
  // Thresholds: a typical Colombian E.A. runs ~15%-45%; anything above
  // ~60% is far more plausible as a monthly rate that was typed into the
  // annual field (monthly rates of 1.5%-4% compound to roughly that
  // range annually, but people often type the raw monthly number, e.g.
  // "36" meaning 3% monthly). For cards specifically, real E.A. rates
  // rarely dip below 3%, so anything lower likely means the field holds
  // a monthly rate or was left at a placeholder-like value.
  String? get _interestRateWarning {
    final rate = double.tryParse(_interestCtrl.text.replaceAll(',', '.'));
    if (rate == null) return null;
    if (_type == CreditType.card) {
      final typeAware = rateInconsistencyWarning(rate, _interestRateType);
      if (typeAware != null) return typeAware;
      if (_interestRateType == InterestRateType.effectiveAnnual && rate > 0 && rate < 3) {
        return 'Esa tasa parece baja para una tarjeta de crédito — verifica que sea la E.A. correcta.';
      }
      return null;
    }
    if (rate > 60) {
      return 'Esa tasa parece alta para una E.A. — ¿la ingresaste como mensual por error? '
          'Una E.A. típica en Colombia ronda 15%-45%.';
    }
    return null;
  }

  // Tarea 2: whether the user has typed/selected anything worth warning
  // about before discarding the form.
  bool get _hasUnsavedData {
    final textControllers = [
      _nameCtrl,
      _lenderCtrl,
      _notesCtrl,
      _locationCtrl,
      _amountCtrl,
      _installmentsCtrl,
      _quotaCtrl,
      _interestCtrl,
      _limitCtrl,
      _cutoffDayCtrl,
      _paymentOffsetCtrl,
    ];
    if (textControllers.any((c) => c.text.trim().isNotEmpty)) return true;
    if (_balanceCtrl.text.trim().isNotEmpty && _balanceCtrl.text.trim() != '0') return true;
    if (_managementFeeCtrl.text.trim().isNotEmpty && _managementFeeCtrl.text.trim() != '0') {
      return true;
    }
    if (_startDate != null) return true;
    return false;
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Descartar este crédito?'),
        content: const Text('Los datos no guardados se perderán.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  // Tarea 1: advance to the next step, validating only the fields that are
  // currently mounted (i.e. those belonging to `_currentStep`).
  void _nextStep() {
    final isValid = _formKey.currentState?.validate() ?? true;
    if (!isValid) return;
    if (_currentStep == 1 && _type == CreditType.loan && _startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la fecha de primer pago')),
      );
      return;
    }
    if (_currentStep < _lastStep) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 15),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_type == CreditType.loan && _startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la fecha de primer pago')),
      );
      return;
    }
    setState(() => _saving = true);

    final id = 'credit_${DateTime.now().millisecondsSinceEpoch}';
    final name = _nameCtrl.text.trim();
    final lender = _lenderCtrl.text.trim();
    final notes = _notesCtrl.text.trim();

    Credit credit;
    if (_type == CreditType.card) {
      final creditLimit = double.tryParse(CurrencyInputFormatter.unformat(_limitCtrl.text)) ?? 0;
      final currentBalance = double.tryParse(CurrencyInputFormatter.unformat(_balanceCtrl.text)) ?? 0;
      final cutoffDay = int.tryParse(_cutoffDayCtrl.text) ?? 1;
      final paymentDueOffsetDays = int.tryParse(_paymentOffsetCtrl.text) ?? 20;
      final interestRate = double.tryParse(_interestCtrl.text.replaceAll(',', '.')) ?? 0;
      final managementFee = double.tryParse(CurrencyInputFormatter.unformat(_managementFeeCtrl.text)) ?? 0;

      final cardCredit = CardCredit(
        id: id,
        name: name,
        lender: lender,
        color: _color,
        notes: notes,
        creditLimit: creditLimit,
        currentBalance: currentBalance,
        cutoffDay: cutoffDay,
        paymentDueOffsetDays: paymentDueOffsetDays,
        interestRate: interestRate,
        interestRateType: _interestRateType,
        managementFee: managementFee,
        managementFeeFrequency: _managementFeeFrequency,
        movements: currentBalance > 0
            ? [
                CardMovement(
                  date: toDateStr(DateTime.now()),
                  type: CardMovementType.charge,
                  amount: currentBalance,
                  note: 'Saldo inicial registrado',
                ),
              ]
            : [],
      );
      // Initializes lastAccrualCutoff without back-charging (app.js ~L459).
      accrueCardCredit(cardCredit);
      credit = cardCredit;
    } else {
      final totalAmount = double.parse(CurrencyInputFormatter.unformat(_amountCtrl.text));
      final totalInstallments = int.parse(_installmentsCtrl.text);
      final quotaAmount = double.parse(CurrencyInputFormatter.unformat(_quotaCtrl.text));
      final interestRate = double.tryParse(_interestCtrl.text.replaceAll(',', '.')) ?? 0;
      final startDateStr = toDateStr(_startDate!);

      final installments = buildLoanInstallments(
        totalAmount: totalAmount,
        totalInstallments: totalInstallments,
        quotaAmount: quotaAmount,
        frequency: _frequency,
        startDate: startDateStr,
        interestRate: interestRate,
        interestRateType: _interestRateType,
      );
      _markAdvancedInstallments(installments);

      credit = LoanCredit(
        id: id,
        name: name,
        lender: lender,
        color: _color,
        notes: notes,
        location: _locationCtrl.text.trim(),
        totalAmount: totalAmount,
        quotaAmount: quotaAmount,
        totalInstallments: totalInstallments,
        frequency: _frequency,
        startDate: startDateStr,
        interestRate: interestRate,
        interestRateType: _interestRateType,
        installments: installments,
      );
    }

    try {
      await ref.read(creditsProvider.notifier).addCredit(credit);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$name" registrado con éxito')),
        );
      }
    } catch (e) {
      debugPrint('addCredit failed: $e');
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar el crédito. Intenta de nuevo.')),
        );
      }
    }
  }

  // Marks the first N installments (whatever the user typed in "Cuotas ya
  // pagadas") as paid, with paymentDate set to each one's own dueDate — a
  // reasonable historical stand-in since we don't know the real payment
  // dates for a credit that pre-dates its registration in the app. Clamped
  // to totalInstallments so a typo can't skip past the schedule's end.
  void _markAdvancedInstallments(List<Installment> installments) {
    final paidCount = int.tryParse(_paidInstallmentsCtrl.text.trim()) ?? 0;
    if (paidCount <= 0) return;
    final n = math.min(paidCount, installments.length);
    for (var i = 0; i < n; i++) {
      installments[i].paid = true;
      installments[i].paymentDate = installments[i].dueDate;
    }
  }

  static const _stepTitles = ['Tipo y Datos Básicos', 'Datos Financieros', 'Confirmación'];

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return PopScope(
      canPop: !_hasUnsavedData,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final discard = await _confirmDiscard();
        if (discard && mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Registrar Nuevo Crédito')),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              _StepProgress(
                currentStep: _currentStep,
                titles: _stepTitles,
                kredit: kredit,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(KreditSpacing.card),
                  children: [
                    ...switch (_currentStep) {
                      0 => _step1BasicData(kredit),
                      1 => _step2FinancialData(kredit),
                      _ => _step3ColorNotesConfirm(kredit),
                    },
                  ],
                ),
              ),
              _buildControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : _previousStep,
                child: const Text('Atrás'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: _saving
                  ? null
                  : (_currentStep < _lastStep ? _nextStep : _save),
              child: Text(
                _saving
                    ? 'Guardando...'
                    : (_currentStep < _lastStep ? 'Siguiente' : 'Registrar Crédito'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _step1BasicData(KreditColors kredit) {
    final suggestion = _typeSuggestion;
    final subEntityOptions = subEntitiesForLender(_lenderCtrl.text);
    return [
      const Text('¿Qué quieres registrar?', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      _CreditTypePicker(
        selectedType: _type,
        onChanged: (value) {
          setState(() => _type = value);
          _applyEntityTemplate();
        },
      ),
      const SizedBox(height: 20),
      Divider(color: kredit.borderCard),
      const SizedBox(height: 4),
      const Text('Datos Básicos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: KreditTextSize.body)),
      const SizedBox(height: 8),
      TextFormField(
        controller: _nameCtrl,
        decoration: InputDecoration(
          labelText: _type == CreditType.card
              ? 'Nombre de la Tarjeta'
              : 'Nombre del Crédito (¿Qué compraste?)',
          hintText: 'Ej. Nevera, Préstamo coche, iPhone',
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
      ),
      const SizedBox(height: 12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: _selectedLenderPreset == 'Otro...' ? 1 : 2,
            child: DropdownButtonFormField<String>(
                isExpanded: true,
              initialValue: _selectedLenderPreset,
              decoration: InputDecoration(
                labelText: _type == CreditType.card ? 'Banco / Entidad Emisora' : 'Banco / Prestamista',
              ),
              items: _presetLenders
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _selectedLenderPreset = v;
                  _selectedSubEntityLabel = null;
                  if (v != null && v != 'Otro...') {
                    _lenderCtrl.text = v;
                    final lower = v.toLowerCase();
                    if (lower.contains('nequi')) {
                      _color = '#DA0081';
                    } else if (lower.contains('nu')) {
                      _color = '#820AD1';
                    } else if (lower.contains('bancolombia')) {
                      _color = '#FFDD00';
                    } else if (lower.contains('davivienda') || lower.contains('daviplata')) {
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
                    } else if (lower.contains('itaú') || lower.contains('itau')) {
                      _color = '#EC7000';
                    } else if (lower.contains('tuya') || lower.contains('exito')) {
                      _color = '#FFD100';
                    }
                  } else if (v == 'Otro...') {
                    _lenderCtrl.clear();
                  }
                });
                _applyEntityTemplate();
              },
              validator: (_) => (_lenderCtrl.text.trim().isEmpty) ? 'Requerido' : null,
            ),
          ),
          if (_selectedLenderPreset == 'Otro...') ...[
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: _lenderCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Escribir libre',
                  hintText: 'Ej. PrestaYa...',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                onChanged: (_) {
                  setState(() => _selectedSubEntityLabel = null);
                  _applyEntityTemplate();
                },
              ),
            ),
          ],
        ],
      ),
      if (subEntityOptions.isNotEmpty) ...[
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
            isExpanded: true,
          initialValue: _selectedSubEntityLabel,
          decoration: const InputDecoration(
            labelText: 'Sub-marca / Producto (opcional)',
            hintText: 'Ej. CMR Falabella vs. Banco Falabella',
          ),
          items: subEntityOptions
              .map((s) => DropdownMenuItem(value: s.label, child: Text(s.label)))
              .toList(),
          onChanged: (v) {
            setState(() {
              _selectedSubEntityLabel = v;
              final option = subEntityOptions.firstWhere((s) => s.label == v);
              _lenderCtrl.text = option.lenderText;
            });
            _applyEntityTemplate();
          },
        ),
      ],
      if (suggestion != null) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(KreditSpacing.tile),
          decoration: BoxDecoration(
            color: kredit.bgSecondary,
            border: Border.all(color: kredit.borderCard),
            borderRadius: BorderRadius.circular(KreditRadius.tile),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: KreditIconSize.small, color: AppColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(suggestion.text, style: const TextStyle(fontSize: KreditTextSize.caption)),
              ),
              TextButton(
                onPressed: () => setState(() => _type = CreditType.loan),
                child: const Text('Cambiar a Préstamo', style: TextStyle(fontSize: KreditTextSize.caption)),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _step2FinancialData(KreditColors kredit) {
    return [
      const Text('Datos Financieros', style: TextStyle(fontWeight: FontWeight.w700, fontSize: KreditTextSize.body)),
      if (_type == CreditType.loan) ..._loanFields(),
      if (_type == CreditType.card) ..._cardFields(),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _step3ColorNotesConfirm(KreditColors kredit) {
    return [
      Row(
        children: [
          Icon(Icons.fact_check_outlined, size: KreditIconSize.small, color: kredit.textTertiary),
          const SizedBox(width: 6),
          const Text('Confirmación', style: TextStyle(fontWeight: FontWeight.w700, fontSize: KreditTextSize.body)),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        'Revisa que todo esté correcto antes de registrar el crédito.',
        style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
      ),
      const SizedBox(height: 12),
      ..._previewCard(),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _summaryRows(),
      ),
      const SizedBox(height: 12),
    ];
  }

  // Live preview of how this credit will look once saved, mirroring the
  // "VISTA PREVIA DE TARJETA" block in edit_credit_sheet.dart so create and
  // edit stay visually consistent. Only rendered once the fields needed to
  // build a Credit are actually present — falls back to nothing (just the
  // text summary below) if the data isn't parseable yet.
  List<Widget> _previewCard() {
    final credit = _buildPreviewCredit();
    if (credit == null) return const [];
    return [
      const Text(
        'VISTA PREVIA DE TARJETA',
        style: TextStyle(fontSize: KreditTextSize.caption, fontWeight: FontWeight.bold, letterSpacing: 0.8),
      ),
      const SizedBox(height: 8),
      WalletCard(credit: credit),
      const SizedBox(height: 16),
    ];
  }

  // Builds a throwaway Credit from the current form state purely for the
  // step-3 preview — never persisted. Returns null when the data isn't
  // complete/parseable enough to render a meaningful card (the real
  // validation/build happens in `_save`).
  Credit? _buildPreviewCredit() {
    final name = _nameCtrl.text.trim().isEmpty ? '(sin nombre)' : _nameCtrl.text.trim();
    final lender = _lenderCtrl.text.trim().isEmpty ? '(sin definir)' : _lenderCtrl.text.trim();
    try {
      if (_type == CreditType.card) {
        final creditLimit = double.tryParse(CurrencyInputFormatter.unformat(_limitCtrl.text)) ?? 0;
        final currentBalance = double.tryParse(CurrencyInputFormatter.unformat(_balanceCtrl.text)) ?? 0;
        final cutoffDay = int.tryParse(_cutoffDayCtrl.text) ?? 15;
        final paymentDueOffsetDays = int.tryParse(_paymentOffsetCtrl.text) ?? 20;
        final interestRate = double.tryParse(_interestCtrl.text.replaceAll(',', '.')) ?? 0;
        final managementFee = double.tryParse(CurrencyInputFormatter.unformat(_managementFeeCtrl.text)) ?? 0;
        return CardCredit(
          id: 'preview',
          name: name,
          lender: lender,
          color: _color,
          notes: _notesCtrl.text.trim(),
          creditLimit: creditLimit,
          currentBalance: currentBalance,
          cutoffDay: cutoffDay,
          paymentDueOffsetDays: paymentDueOffsetDays,
          interestRate: interestRate,
          interestRateType: _interestRateType,
          managementFee: managementFee,
          managementFeeFrequency: _managementFeeFrequency,
        );
      }
      if (_startDate == null) return null;
      final totalAmount = double.tryParse(CurrencyInputFormatter.unformat(_amountCtrl.text));
      final totalInstallments = int.tryParse(_installmentsCtrl.text);
      final quotaAmount = double.tryParse(CurrencyInputFormatter.unformat(_quotaCtrl.text));
      if (totalAmount == null || totalInstallments == null || quotaAmount == null) return null;
      final interestRate = double.tryParse(_interestCtrl.text.replaceAll(',', '.')) ?? 0;
      final startDateStr = toDateStr(_startDate!);
      final installments = buildLoanInstallments(
        totalAmount: totalAmount,
        totalInstallments: totalInstallments,
        quotaAmount: quotaAmount,
        frequency: _frequency,
        startDate: startDateStr,
        interestRate: interestRate,
        interestRateType: _interestRateType,
      );
      _markAdvancedInstallments(installments);
      return LoanCredit(
        id: 'preview',
        name: name,
        lender: lender,
        color: _color,
        notes: _notesCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        totalAmount: totalAmount,
        quotaAmount: quotaAmount,
        totalInstallments: totalInstallments,
        frequency: _frequency,
        startDate: startDateStr,
        interestRate: interestRate,
        interestRateType: _interestRateType,
        installments: installments,
      );
    } catch (_) {
      return null;
    }
  }

  List<Widget> _summaryRows() {
    final name = _nameCtrl.text.trim().isEmpty ? '(sin nombre)' : _nameCtrl.text.trim();
    final lender = _lenderCtrl.text.trim().isEmpty ? '(sin definir)' : _lenderCtrl.text.trim();
    final typeLabel = _type == CreditType.card ? 'Tarjeta de Crédito' : 'Préstamo / Cuotas Fijas';

    if (_type == CreditType.card) {
      final limitText = _limitCtrl.text.trim();
      final limitValue = double.tryParse(CurrencyInputFormatter.unformat(limitText));
      final limit = (limitText.isEmpty || limitValue == null || limitValue == 0)
          ? 'No definido'
          : '\$$limitText';
      final balance = _balanceCtrl.text.trim().isEmpty ? '\$0' : '\$${_balanceCtrl.text.trim()}';
      final cutoff = _cutoffDayCtrl.text.trim().isEmpty ? '—' : 'Día ${_cutoffDayCtrl.text.trim()}';
      final offset = _paymentOffsetCtrl.text.trim().isEmpty ? '—' : '${_paymentOffsetCtrl.text.trim()} días después del corte';
      return [
        _SummaryRow(label: 'Nombre', value: name),
        _SummaryRow(label: 'Tipo', value: typeLabel),
        _SummaryRow(label: 'Entidad', value: lender),
        _SummaryRow(label: 'Límite', value: limit),
        _SummaryRow(label: 'Saldo actual', value: balance),
        _SummaryRow(label: 'Corte', value: cutoff),
        _SummaryRow(label: 'Fecha límite', value: offset),
      ];
    }

    final amount = _amountCtrl.text.trim().isEmpty ? '0' : _amountCtrl.text.trim();
    final installments = _installmentsCtrl.text.trim().isEmpty ? '—' : _installmentsCtrl.text.trim();
    final quota = _quotaCtrl.text.trim().isEmpty ? '0' : _quotaCtrl.text.trim();
    final startDate = _startDate == null ? '(sin definir)' : formatDate(toDateStr(_startDate!));
    final paidCount = int.tryParse(_paidInstallmentsCtrl.text.trim()) ?? 0;
    return [
      _SummaryRow(label: 'Nombre', value: name),
      _SummaryRow(label: 'Tipo', value: typeLabel),
      _SummaryRow(label: 'Entidad', value: lender),
      _SummaryRow(label: 'Monto financiado', value: '\$$amount'),
      _SummaryRow(label: 'Cuotas', value: installments),
      _SummaryRow(label: 'Valor cuota', value: '\$$quota'),
      _SummaryRow(label: 'Primer pago', value: startDate),
      if (paidCount > 0) _SummaryRow(label: 'Cuotas ya pagadas', value: '$paidCount'),
    ];
  }

  List<Widget> _loanFields() {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return [
      const SizedBox(height: 12),
      _CollapsibleSection(
        title: 'Detalles adicionales (opcional)',
        icon: Icons.more_horiz,
        children: [
          TextFormField(
            controller: _locationCtrl,
            decoration: const InputDecoration(
              labelText: 'Comercio / Establecimiento',
              hintText: 'Ej. Almacenes Éxito, Falabella...',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notas / Indicaciones',
              hintText: 'Ej. Garantía guardada en la gaveta, seguro incluido...',
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _SectionCard(
        label: 'MONTO Y CUOTAS',
        icon: Icons.request_quote_outlined,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [CurrencyInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Monto Financiado (\$)', hintText: 'Ej. 1.500.000'),
                  onChanged: (_) => _recalcSuggestedQuota(),
                  validator: (v) {
                    final n = double.tryParse(CurrencyInputFormatter.unformat(v ?? ''));
                    if (n == null || n <= 0) return 'Requerido';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _installmentsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cantidad de Cuotas', hintText: 'Ej. 12'),
                  onChanged: (_) => _recalcSuggestedQuota(),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Requerido';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _interestCtrl,
            style: const TextStyle(fontSize: KreditTextSize.body),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Interés anual (%)',
              hintText: 'Opcional (Ej. 28)',
            ),
            onChanged: (_) => _recalcSuggestedQuota(),
          ),
          if (_interestRateWarning != null) _InterestRateWarningHint(text: _interestRateWarning!),
          const SizedBox(height: 12),
          InterestRateTypeField(
            value: _interestRateType,
            onChanged: (v) {
              setState(() => _interestRateType = v);
              _recalcSuggestedQuota();
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _quotaCtrl,
            enabled: false,
            style: const TextStyle(fontSize: KreditTextSize.body),
            keyboardType: TextInputType.number,
            inputFormatters: const [CurrencyInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'Valor de la Cuota (\$) — calculado automáticamente',
              hintText: 'Se calcula al ingresar monto, cuotas e interés',
            ),
            validator: (v) {
              final n = double.tryParse(CurrencyInputFormatter.unformat(v ?? ''));
              if (n == null || n <= 0) return 'Completa monto y cuotas para calcularla';
              return null;
            },
          ),
          const SizedBox(height: 6),
          Text(
            'Valor aproximado, calculado con base en el monto, las cuotas y el interés ingresados.',
            style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _paidInstallmentsCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Cuotas ya pagadas (opcional)',
              hintText: 'Ej. 2, si ya llevas 2 cuotas pagadas',
            ),
            onChanged: (_) => setState(() {}),
            validator: (v) {
              final text = v?.trim() ?? '';
              if (text.isEmpty) return null;
              final n = int.tryParse(text);
              if (n == null || n < 0) return 'Debe ser un número válido';
              final total = int.tryParse(_installmentsCtrl.text);
              if (total != null && n > total) return 'No puede superar el total de cuotas';
              return null;
            },
          ),
          const SizedBox(height: 6),
          Text(
            'Si este crédito ya llevaba cuotas pagadas antes de registrarlo aquí, indica '
            'cuántas — se marcarán como pagadas desde la primera.',
            style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _SectionCard(
        label: 'FECHA Y FRECUENCIA',
        icon: Icons.event_repeat_outlined,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                        isExpanded: true,
                      initialValue: _frequency,
                      decoration: const InputDecoration(labelText: 'Frecuencia de Cuotas'),
                      items: const [
                        DropdownMenuItem(value: CreditFrequency.monthly, child: Text('Mensual')),
                        DropdownMenuItem(value: CreditFrequency.biweekly, child: Text('Quincenal (14 días)')),
                        DropdownMenuItem(value: CreditFrequency.weekly, child: Text('Semanal')),
                      ],
                      onChanged: (v) {
                        setState(() => _frequency = v ?? CreditFrequency.monthly);
                        _recalcSuggestedQuota();
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '¿Cada cuánto vence una cuota? La mayoría de créditos son mensuales.',
                      style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: _pickStartDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Fecha de Primer Pago'),
                        child: Text(_startDate == null ? 'Selecciona una fecha' : formatDate(toDateStr(_startDate!))),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'La fecha en que vence (o venció) tu primera cuota — la ves en tu '
                      'contrato o primer recibo.',
                      style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ];
  }

  List<Widget> _cardFields() {
    return [
      const SizedBox(height: 12),
      _SectionCard(
        label: 'LÍMITE Y SALDO',
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
                    labelText: 'Límite de la tarjeta (opcional)',
                    hintText: 'Ej. 3.000.000 — déjalo vacío si no lo sabes',
                  ),
                  // Optional: an empty limit is saved as 0 and the views
                  // that depend on a real limit (cupo disponible, %
                  // utilizado) show "No definido" instead of computing
                  // against a limit of $0 — see wallet_card.dart/
                  // summary_tab.dart. Still rejects a negative number if
                  // the user does type something implausible.
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = double.tryParse(CurrencyInputFormatter.unformat(v));
                    if (n == null || n < 0) return 'Debe ser un número válido';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _balanceCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [CurrencyInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Saldo actual de deuda (opcional)',
                    hintText: 'Ej. 500.000',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = double.tryParse(CurrencyInputFormatter.unformat(v));
                    if (n == null || n < 0) return 'Debe ser un número válido';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 12),
      _SectionCard(
        label: 'CORTE Y FECHA DE PAGO',
        icon: Icons.event_available_outlined,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: int.tryParse(_cutoffDayCtrl.text) ?? 15,
                  decoration: const InputDecoration(labelText: 'Día de Corte'),
                  items: List.generate(31, (i) => i + 1)
                      .map((d) => DropdownMenuItem(value: d, child: Text('Día $d de cada mes')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _cutoffDayCtrl.text = v.toString();
                        _cutoffDayTouched = true;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: int.tryParse(_paymentOffsetCtrl.text) ?? 20,
                  decoration: const InputDecoration(labelText: 'Días para pagar después del corte'),
                  items: [10, 15, 20, 25, 30, 35, 40]
                      .map((d) => DropdownMenuItem(value: d, child: Text('$d días después')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _paymentOffsetCtrl.text = v.toString();
                        _paymentOffsetTouched = true;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          if (_entityTemplateNote != null) ...[
            const SizedBox(height: 6),
            Text(
              _entityTemplateNote!,
              style: TextStyle(fontSize: KreditTextSize.caption, color: Theme.of(context).extension<KreditColors>()!.textTertiary),
            ),
          ],
        ],
      ),
      const SizedBox(height: 12),
      _SectionCard(
        label: 'INTERÉS Y MANTENIMIENTO',
        icon: Icons.percent_outlined,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _interestCtrl,
                      style: const TextStyle(fontSize: KreditTextSize.body),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Interés anual (%)',
                        hintText: 'Opcional',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    if (_interestRateWarning != null) _InterestRateWarningHint(text: _interestRateWarning!),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _managementFeeCtrl,
                  style: const TextStyle(fontSize: KreditTextSize.body),
                  keyboardType: TextInputType.number,
                  inputFormatters: const [CurrencyInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Cuota de Mantenimiento (\$)',
                    hintText: 'Ej. 15.000 (0 si no cobra)',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InterestRateTypeField(
            value: _interestRateType,
            onChanged: (v) => setState(() => _interestRateType = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
              isExpanded: true,
            style: TextStyle(fontSize: KreditTextSize.body, color: Theme.of(context).extension<KreditColors>()!.textPrimary),
            initialValue: _managementFeeFrequency,
            decoration: const InputDecoration(labelText: 'Frecuencia de Cobro de Mantenimiento'),
            items: const [
              DropdownMenuItem(value: ManagementFeeFrequency.monthly, child: Text('Mensual')),
              DropdownMenuItem(value: ManagementFeeFrequency.annual, child: Text('Anual')),
            ],
            onChanged: (v) => setState(() => _managementFeeFrequency = v ?? ManagementFeeFrequency.monthly),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _CollapsibleSection(
        title: 'Detalles adicionales (opcional)',
        icon: Icons.more_horiz,
        children: [
          TextFormField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notas / Indicaciones',
              hintText: 'Ej. Garantía guardada en la gaveta, seguro incluido...',
            ),
          ),
        ],
      ),
    ];
  }
}

/// Non-blocking hint shown under the interest rate field when the entered
/// value looks like it might be mismatched (monthly vs. E.A.), with the
/// same small warning-icon-plus-text treatment used for the Nequi/DaviPlata
/// type suggestion.
class _InterestRateWarningHint extends StatelessWidget {
  final String text;
  const _InterestRateWarningHint({required this.text});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: KreditIconSize.small, color: AppColors.warning),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditTypePicker extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onChanged;

  const _CreditTypePicker({
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CreditTypeOption(
          selected: selectedType == CreditType.loan,
          icon: Icons.payments_outlined,
          title: 'Préstamo / Cupo en cuotas',
          subtitle: 'Pagas cuotas fijas y existe una fecha estimada de finalización.',
          onTap: () => onChanged(CreditType.loan),
        ),
        const SizedBox(height: 10),
        _CreditTypeOption(
          selected: selectedType == CreditType.card,
          icon: Icons.credit_card_outlined,
          title: 'Tarjeta de crédito',
          subtitle: 'Maneja saldo rotativo, fecha de corte, fecha límite y cupo disponible.',
          onTap: () => onChanged(CreditType.card),
        ),
      ],
    );
  }
}

class _CreditTypeOption extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CreditTypeOption({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    return Material(
      color: selected ? accent.withValues(alpha: 0.12) : kredit.bgCard,
      borderRadius: BorderRadius.circular(KreditRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(KreditRadius.card),
        child: Container(
          padding: const EdgeInsets.all(KreditSpacing.card),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(KreditRadius.card),
            border: Border.all(
              color: selected ? accent : kredit.borderCard,
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: KreditIconSize.small, color: selected ? accent : kredit.textTertiary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: KreditTextSize.body,
                        fontWeight: FontWeight.w800,
                        color: kredit.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: KreditTextSize.caption,
                        color: kredit.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: KreditIconSize.small,
                color: selected ? accent : kredit.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Numbered step indicator for the 3-step form (Tarea 1): a circle per step
/// (filled = done, outlined-accent = current, dim = upcoming) joined by
/// connector lines, plus the current step's title underneath — clearer than
/// a plain progress bar about *which* step you're on vs. how many remain.
class _StepProgress extends StatelessWidget {
  final int currentStep;
  final List<String> titles;
  final KreditColors kredit;

  const _StepProgress({
    required this.currentStep,
    required this.titles,
    required this.kredit,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(titles.length * 2 - 1, (i) {
              if (i.isOdd) {
                final connectorDone = (i ~/ 2) < currentStep;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: connectorDone ? accent : kredit.borderCard,
                  ),
                );
              }
              final step = i ~/ 2;
              final done = step < currentStep;
              final current = step == currentStep;
              return Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? accent : kredit.bgSecondary,
                  border: Border.all(
                    color: (done || current) ? accent : kredit.borderCard,
                    width: current ? 2 : 1,
                  ),
                ),
                child: done
                    ? Icon(Icons.check, size: KreditIconSize.small, color: Theme.of(context).scaffoldBackgroundColor)
                    : Text(
                        '${step + 1}',
                        style: TextStyle(
                          fontSize: KreditTextSize.body,
                          fontWeight: FontWeight.w700,
                          color: current ? accent : kredit.textTertiary,
                        ),
                      ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'Paso ${currentStep + 1} de ${titles.length}: ${titles[currentStep]}',
            style: TextStyle(fontSize: KreditTextSize.body, fontWeight: FontWeight.w600, color: kredit.textPrimary),
          ),
        ],
      ),
    );
  }
}

/// Typographic section separator used to group a related cluster of fields
/// within a step (e.g. "monto/cuotas" vs. "fecha/frecuencia") — a small
/// uppercase heading over a hairline [Divider] instead of a decorative
/// bordered box, matching the "sin cajas" visual language used across the
/// app (see dashboard_screen.dart).
class _SectionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({required this.label, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: KreditIconSize.small, color: kredit.textTertiary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: KreditTextSize.caption,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: kredit.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Divider(height: 1, color: kredit.borderCard),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

/// Collapsible "Detalles adicionales (opcional)" group for secondary fields
/// (comercio/cuenta de pago/notas) that most users don't need to touch —
/// closed by default so the form reads shorter, but one tap away. Built as
/// a typographic header + hairline [Divider] that expands/collapses (same
/// "sin cajas" language as [_SectionCard]), not a boxed [Card], so it fits
/// the app's established visual system.
class _CollapsibleSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _CollapsibleSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Theme(
      // Strip the default ExpansionTile dividers/ink so it reads as plain
      // typography over a hairline, matching _SectionCard's look.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 12),
        expandedAlignment: Alignment.centerLeft,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: kredit.textTertiary,
        collapsedIconColor: kredit.textTertiary,
        title: Row(
          children: [
            Icon(icon, size: KreditIconSize.small, color: kredit.textTertiary),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: KreditTextSize.caption,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: kredit.textTertiary,
              ),
            ),
          ],
        ),
        children: children,
      ),
    );
  }
}

/// One "label: value" row used inside the step-3 confirmation summary.
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: KreditTextSize.body, fontWeight: FontWeight.w600, color: kredit.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
