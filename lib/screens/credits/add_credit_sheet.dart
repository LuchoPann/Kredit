import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/card_movement.dart';
import '../../data/models/credit.dart';
import '../../domain/card_calculator.dart';
import '../../domain/date_utils.dart';
import '../../domain/entity_templates.dart';
import '../../domain/loan_calculator.dart';
import '../../providers/credits_provider.dart';
import '../../theme/app_theme.dart';

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

const List<String> _presetCards = [
  'Cuenta Débito Bancolombia',
  'Nequi',
  'DaviPlata',
  'RappiCuenta / Débito',
  'Lulo Bank',
  'Cuenta de Ahorros',
  'Efectivo',
  'Otra...',
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
  final _cardCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _installmentsCtrl = TextEditingController();
  final _quotaCtrl = TextEditingController();
  final _interestCtrl = TextEditingController();
  String _frequency = CreditFrequency.monthly;
  DateTime? _startDate;

  String? _selectedLenderPreset = 'Bancolombia';
  String? _selectedLocationPreset;
  String? _selectedCardPreset;

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
      _cardCtrl,
      _amountCtrl,
      _installmentsCtrl,
      _quotaCtrl,
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

  // Port of calcSuggestedQuota (app.js ~L370-383): only auto-fills the
  // quota field if the user hasn't typed anything into it yet.
  void _suggestQuota() {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    final installments = int.tryParse(_installmentsCtrl.text);
    if (amount != null && installments != null && installments > 0) {
      if (_quotaCtrl.text.trim().isEmpty) {
        _quotaCtrl.text = (amount / installments).toStringAsFixed(2);
      }
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
    if (rate > 60) {
      return 'Esa tasa parece alta para una E.A. — ¿la ingresaste como mensual por error? '
          'Una E.A. típica en Colombia ronda 15%-45%.';
    }
    if (_type == CreditType.card && rate > 0 && rate < 3) {
      return 'Esa tasa parece baja para una tarjeta de crédito — verifica que sea la E.A. correcta.';
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
      _cardCtrl,
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
          FilledButton(
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
      final creditLimit = double.tryParse(_limitCtrl.text.replaceAll(',', '.')) ?? 0;
      final currentBalance = double.tryParse(_balanceCtrl.text.replaceAll(',', '.')) ?? 0;
      final cutoffDay = int.tryParse(_cutoffDayCtrl.text) ?? 1;
      final paymentDueOffsetDays = int.tryParse(_paymentOffsetCtrl.text) ?? 20;
      final interestRate = double.tryParse(_interestCtrl.text.replaceAll(',', '.')) ?? 0;
      final managementFee = double.tryParse(_managementFeeCtrl.text.replaceAll(',', '.')) ?? 0;

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
      final totalAmount = double.parse(_amountCtrl.text.replaceAll(',', '.'));
      final totalInstallments = int.parse(_installmentsCtrl.text);
      final quotaAmount = double.parse(_quotaCtrl.text.replaceAll(',', '.'));
      final interestRate = double.tryParse(_interestCtrl.text.replaceAll(',', '.')) ?? 0;
      final startDateStr = toDateStr(_startDate!);

      final installments = buildLoanInstallments(
        totalAmount: totalAmount,
        totalInstallments: totalInstallments,
        quotaAmount: quotaAmount,
        frequency: _frequency,
        startDate: startDateStr,
      );

      credit = LoanCredit(
        id: id,
        name: name,
        lender: lender,
        color: _color,
        notes: notes,
        location: _locationCtrl.text.trim(),
        card: _cardCtrl.text.trim(),
        totalAmount: totalAmount,
        quotaAmount: quotaAmount,
        totalInstallments: totalInstallments,
        frequency: _frequency,
        startDate: startDateStr,
        interestRate: interestRate,
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
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar el crédito: $e')),
        );
      }
    }
  }

  static const _stepTitles = ['Tipo y Datos Básicos', 'Datos Financieros', 'Color y Confirmación'];

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
                  children: switch (_currentStep) {
                    0 => _step1BasicData(kredit),
                    1 => _step2FinancialData(kredit),
                    _ => _step3ColorNotesConfirm(kredit),
                  },
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
    return [
      const Text('Tipo de Crédito', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: CreditType.loan, label: Text('Préstamo / Cuotas Fijas')),
          ButtonSegment(value: CreditType.card, label: Text('Tarjeta de Crédito')),
        ],
        selected: {_type},
        onSelectionChanged: (s) {
          setState(() => _type = s.first);
          _applyEntityTemplate();
        },
      ),
      const SizedBox(height: 4),
      Text(
        'Cuotas fijas: pagas lo mismo cada vez, con fecha de fin definida. '
        'Tarjeta: saldo que sube y baja, con corte y fecha límite cada mes.',
        style: TextStyle(fontSize: 11, color: kredit.textTertiary),
      ),
      const SizedBox(height: 20),
      Divider(color: kredit.borderCard),
      const SizedBox(height: 4),
      const Text('Datos Básicos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
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
                  setState(() {});
                  _applyEntityTemplate();
                },
              ),
            ),
          ],
        ],
      ),
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
              const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(suggestion.text, style: const TextStyle(fontSize: 11)),
              ),
              TextButton(
                onPressed: () => setState(() => _type = CreditType.loan),
                child: const Text('Cambiar a Préstamo', style: TextStyle(fontSize: 10)),
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
      const Text('Datos Financieros', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      if (_type == CreditType.loan) ..._loanFields(),
      if (_type == CreditType.card) ..._cardFields(),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _step3ColorNotesConfirm(KreditColors kredit) {
    return [
      const Text('Color de Tarjeta / Identificador', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 10,
        children: AppColors.accentOptions.map((c) {
          final hex = '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
          final selected = hex.toUpperCase() == _color.toUpperCase();
          return GestureDetector(
            onTap: () => setState(() => _color = hex),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? kredit.textPrimary : kredit.borderCard,
                  width: selected ? 3 : 1,
                ),
              ),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _notesCtrl,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Indicaciones del Crédito / Comentarios',
          hintText: 'Ej. Garantía guardada en la gaveta, seguro incluido...',
        ),
      ),
      const SizedBox(height: 20),
      Divider(color: kredit.borderCard),
      const SizedBox(height: 12),
      Row(
        children: [
          Icon(Icons.fact_check_outlined, size: 14, color: kredit.textTertiary),
          const SizedBox(width: 6),
          const Text('Confirmación', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        'Revisa que todo esté correcto antes de registrar el crédito.',
        style: TextStyle(fontSize: 11, color: kredit.textTertiary),
      ),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(KreditSpacing.tile),
        decoration: BoxDecoration(
          color: kredit.bgSecondary,
          border: Border.all(color: kredit.borderCard),
          borderRadius: BorderRadius.circular(KreditRadius.tile),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _summaryRows(),
        ),
      ),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _summaryRows() {
    final name = _nameCtrl.text.trim().isEmpty ? '(sin nombre)' : _nameCtrl.text.trim();
    final lender = _lenderCtrl.text.trim().isEmpty ? '(sin definir)' : _lenderCtrl.text.trim();
    final typeLabel = _type == CreditType.card ? 'Tarjeta de Crédito' : 'Préstamo / Cuotas Fijas';

    if (_type == CreditType.card) {
      final limit = _limitCtrl.text.trim().isEmpty ? '0' : _limitCtrl.text.trim();
      final balance = _balanceCtrl.text.trim().isEmpty ? '0' : _balanceCtrl.text.trim();
      final cutoff = _cutoffDayCtrl.text.trim().isEmpty ? '—' : 'Día ${_cutoffDayCtrl.text.trim()}';
      final offset = _paymentOffsetCtrl.text.trim().isEmpty ? '—' : '${_paymentOffsetCtrl.text.trim()} días después del corte';
      return [
        _SummaryRow(label: 'Nombre', value: name),
        _SummaryRow(label: 'Tipo', value: typeLabel),
        _SummaryRow(label: 'Entidad', value: lender),
        _SummaryRow(label: 'Límite', value: '\$$limit'),
        _SummaryRow(label: 'Saldo actual', value: '\$$balance'),
        _SummaryRow(label: 'Corte', value: cutoff),
        _SummaryRow(label: 'Fecha límite', value: offset),
      ];
    }

    final amount = _amountCtrl.text.trim().isEmpty ? '0' : _amountCtrl.text.trim();
    final installments = _installmentsCtrl.text.trim().isEmpty ? '—' : _installmentsCtrl.text.trim();
    final quota = _quotaCtrl.text.trim().isEmpty ? '0' : _quotaCtrl.text.trim();
    final startDate = _startDate == null ? '(sin definir)' : toDateStr(_startDate!);
    return [
      _SummaryRow(label: 'Nombre', value: name),
      _SummaryRow(label: 'Tipo', value: typeLabel),
      _SummaryRow(label: 'Entidad', value: lender),
      _SummaryRow(label: 'Monto financiado', value: '\$$amount'),
      _SummaryRow(label: 'Cuotas', value: installments),
      _SummaryRow(label: 'Valor cuota', value: '\$$quota'),
      _SummaryRow(label: 'Primer pago', value: startDate),
    ];
  }

  List<Widget> _loanFields() {
    return [
      const SizedBox(height: 12),
      _SectionCard(
        label: 'DÓNDE Y CON QUÉ',
        icon: Icons.storefront_outlined,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedLocationPreset,
                      decoration: const InputDecoration(labelText: 'Comercio / Establecimiento'),
                      items: _presetLocations
                          .map((loc) => DropdownMenuItem(value: loc, child: Text(loc)))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedLocationPreset = v;
                          if (v != null && v != 'Otro...') {
                            _locationCtrl.text = v == 'Ninguno / Prestamista' ? '' : v;
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
                        decoration: const InputDecoration(
                          labelText: 'Escribir libre',
                          hintText: 'Ej. Tienda de la esquina...',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCardPreset,
                      decoration: const InputDecoration(labelText: 'Cuenta de Pago / Cargo'),
                      items: _presetCards
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedCardPreset = v;
                          if (v != null && v != 'Otra...') {
                            _cardCtrl.text = v;
                          } else if (v == 'Otra...') {
                            _cardCtrl.clear();
                          }
                        });
                      },
                    ),
                    if (_selectedCardPreset == 'Otra...') ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _cardCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Escribir libre',
                          hintText: 'Ej. Cuenta Banco Popular...',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
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
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Monto Financiado (\$)', hintText: 'Ej. 1500000'),
                  onChanged: (_) => _suggestQuota(),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').replaceAll(',', '.'));
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
                  onChanged: (_) => _suggestQuota(),
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
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _quotaCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Valor de la Cuota (\$)',
                    hintText: () {
                      final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
                      final n = int.tryParse(_installmentsCtrl.text);
                      if (amount != null && n != null && n > 0) {
                        return 'Sugerido: \$${(amount / n).toStringAsFixed(2)}';
                      }
                      return 'Ej. 125000';
                    }(),
                  ),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                    if (n == null || n <= 0) return 'Requerido';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _interestCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Interés anual (%)',
                        hintText: 'Opcional (Ej. 28)',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    if (_interestRateWarning != null) _InterestRateWarningHint(text: _interestRateWarning!),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 12),
      _SectionCard(
        label: 'FECHA Y FRECUENCIA',
        icon: Icons.event_repeat_outlined,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _frequency,
                  decoration: const InputDecoration(labelText: 'Frecuencia de Cuotas'),
                  items: const [
                    DropdownMenuItem(value: CreditFrequency.monthly, child: Text('Mensual')),
                    DropdownMenuItem(value: CreditFrequency.biweekly, child: Text('Quincenal (14 días)')),
                    DropdownMenuItem(value: CreditFrequency.weekly, child: Text('Semanal')),
                  ],
                  onChanged: (v) => setState(() => _frequency = v ?? CreditFrequency.monthly),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _pickStartDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Fecha de Primer Pago'),
                    child: Text(_startDate == null ? 'Selecciona una fecha' : toDateStr(_startDate!)),
                  ),
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
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Límite Total de la Tarjeta (\$)', hintText: 'Ej. 3000000'),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                    if (n == null || n < 0) return 'Requerido';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _balanceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Saldo Actual de Deuda (\$)', hintText: 'Ej. 500000'),
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
              style: TextStyle(fontSize: 11, color: Theme.of(context).extension<KreditColors>()!.textTertiary),
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
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Cuota de Mantenimiento (\$)',
                    hintText: 'Ej. 15000 (0 si no cobra)',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
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
          const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.warning),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: kredit.textTertiary),
            ),
          ),
        ],
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
                    ? Icon(Icons.check, size: 14, color: Theme.of(context).scaffoldBackgroundColor)
                    : Text(
                        '${step + 1}',
                        style: TextStyle(
                          fontSize: 12,
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
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kredit.textPrimary),
          ),
        ],
      ),
    );
  }
}

/// Boxed section used to visually separate a related cluster of fields
/// within a step (e.g. "monto/cuotas" vs. "fecha/frecuencia") instead of
/// letting them all run together in one long column.
class _SectionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({required this.label, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KreditSpacing.tile),
      decoration: BoxDecoration(
        color: kredit.bgSecondary,
        border: Border.all(color: kredit.borderCard),
        borderRadius: BorderRadius.circular(KreditRadius.tile),
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
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: kredit.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
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
            child: Text(label, style: TextStyle(fontSize: 12, color: kredit.textTertiary)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kredit.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
