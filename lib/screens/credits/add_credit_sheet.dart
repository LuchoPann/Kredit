import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/card_movement.dart';
import '../../data/models/commercial_quota.dart';
import '../../data/models/credit.dart';
import '../../data/models/installment.dart';
import '../../domain/bank_detector.dart';
import '../../utils/currency_input_formatter.dart';
import '../../domain/card_calculator.dart';
import '../../domain/commercial_quota_calculator.dart';
import '../../domain/credit_calculator.dart' show creditHasUnpaid;
import '../../domain/date_utils.dart';
import '../../domain/entity_templates.dart';
import '../../domain/interest_rate.dart';
import '../../domain/loan_calculator.dart';
import '../../providers/commercial_quotas_provider.dart';
import '../../providers/credits_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/credit_display_utils.dart';
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
  // +1 avanzando (desliza desde la derecha), -1 retrocediendo (desde la
  // izquierda) — para que el slide del asistente se sienta como moverse
  // físicamente entre pasos y no como un corte seco.
  int _stepDirection = 1;
  static const int _lastStep = 4;

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

  // Cupo comercial (Totto, Lili Pink, Éxito CrediCompras...): esta compra
  // es opcionalmente parte de un cupo ya registrado, o de uno nuevo creado
  // aquí mismo. `_isCommercialQuotaPurchase` es opt-in y por defecto false
  // — no afecta en nada un préstamo bancario normal.
  // Entity-first (paso 0): null = no elegida, 'none' = sin entidad,
  // '__new__' = nueva entidad, cualquier otro = id de quota existente.
  String? _selectedEntityId;
  String _newEntityType = EntityType.store;
  String? _newEntityPreset; // preset del dropdown cuando tipo es banco/app
  final _newEntityBrandCtrl = TextEditingController();
  final _newEntityLimitCtrl = TextEditingController();

  // Tasa opcional: el usuario puede no conocerla, y Kredit nunca debe
  // sintetizar una tasa falsa en su lugar (ver ROADMAP_KREDIT.md).
  bool _interestUnknown = false;
  bool _earlyPaymentWaivesInterest = false;

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
      _newEntityBrandCtrl,
      _newEntityLimitCtrl,
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

  // Opcion A del diseno "Una entidad, un registro": aviso (no bloqueo) si
  // ya existe un credito ACTIVO del mismo tipo (prestamo/cupo vs tarjeta) y
  // el mismo banco detectado. No impide crear otro — hay casos reales donde
  // el usuario si tiene dos productos distintos de la misma entidad (dos
  // tarjetas, o usa el cupo de otra persona) — solo evita la duplicacion
  // accidental. Se excluye 'bank-generic' (el fallback para lenders no
  // reconocidos) para no disparar falsos positivos entre dos entidades
  // "Otro..." distintas que caerian en el mismo cssClass generico.
  Credit? get _duplicateActiveCredit {
    final lenderText = _lenderCtrl.text.trim();
    if (lenderText.isEmpty) return null;
    final targetBank = detectBank(lender: lenderText);
    if (targetBank.cssClass == 'bank-generic') return null;
    final credits = ref.watch(creditsProvider).valueOrNull ?? const [];
    for (final c in credits) {
      final isSameType = _type == CreditType.card ? c is CardCredit : c is LoanCredit;
      if (!isSameType || !creditHasUnpaid(c)) continue;
      final existingBank = detectBank(
        lender: c.lender,
        card: c is LoanCredit ? c.card : null,
      );
      if (existingBank.cssClass == targetBank.cssClass) return c;
    }
    return null;
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

  // Aviso no bloqueante: si esta compra dejaría el cupo de una tienda en
  // negativo, se lo decimos al usuario pero nunca le impedimos continuar.
  String? get _overLimitWarning {
    if (_selectedEntityId == null || _selectedEntityId == 'none' || _type != CreditType.loan) return null;
    final amount = double.tryParse(CurrencyInputFormatter.unformat(_amountCtrl.text));
    if (amount == null || amount <= 0) return null;

    double limit;
    List<LoanCredit> existingPurchases;
    if (_selectedEntityId == '__new__') {
      final parsedLimit =
          double.tryParse(CurrencyInputFormatter.unformat(_newEntityLimitCtrl.text));
      if (parsedLimit == null) return null;
      limit = parsedLimit;
      existingPurchases = const [];
    } else {
      final quotas = ref.read(commercialQuotasProvider).valueOrNull ?? const [];
      CommercialQuota? quota;
      for (final q in quotas) {
        if (q.id == _selectedEntityId) {
          quota = q;
          break;
        }
      }
      if (quota == null) return null;
      if (quota.entityType != EntityType.store) return null;
      limit = quota.limit;
      existingPurchases = (ref.read(creditsProvider).valueOrNull ?? const [])
          .whereType<LoanCredit>()
          .where((c) => c.quotaId == _selectedEntityId)
          .toList();
    }
    final available = quotaAvailable(
      CommercialQuota(id: '', brand: '', limit: limit),
      existingPurchases,
    );
    if (available - amount < 0) {
      return 'Esta compra deja tu cupo en negativo (disponible: ${formatCOP(available)}).';
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
      _newEntityBrandCtrl,
      _newEntityLimitCtrl,
    ];
    if (textControllers.any((c) => c.text.trim().isNotEmpty)) return true;
    if (_selectedEntityId != null) return true;
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

  /// Modal para crear una nueva entidad (banco / tienda / app).
  void _showNewEntitySheet(KreditColors kredit) {
    // Estado local del sheet — no afecta el padre hasta que el user confirma.
    var localType = _newEntityType;
    String? localPreset = _newEntityPreset;
    final brandCtrl = TextEditingController(text: _newEntityBrandCtrl.text);
    final limitCtrl = TextEditingController(text: _newEntityLimitCtrl.text);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 4,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Nueva entidad',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                // Selector de tipo
                Row(
                  children: [
                    for (final t in [EntityType.bank, EntityType.store, EntityType.app]) ...[
                      Expanded(
                        child: _EntityTypePill(
                          label: _entityTypeLabel(t),
                          icon: _entityIcon(t),
                          selected: localType == t,
                          onTap: () => setModal(() {
                            localType = t;
                            localPreset = null;
                            brandCtrl.clear();
                          }),
                        ),
                      ),
                      if (t != EntityType.app) const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                // Banco / app: dropdown de presets
                if (localType != EntityType.store) ...[
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: localPreset,
                    decoration: InputDecoration(
                      labelText: localType == EntityType.bank ? 'Banco / Entidad emisora' : 'App o plataforma',
                    ),
                    hint: Text(localType == EntityType.bank ? 'Ej. Bancolombia, Davivienda' : 'Ej. Addi, Rapicredit'),
                    items: _presetLenders.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                    onChanged: (v) {
                      setModal(() {
                        localPreset = v;
                        if (v != null && v != 'Otro...') {
                          brandCtrl.text = v;
                        } else if (v == 'Otro...') {
                          brandCtrl.clear();
                        }
                      });
                    },
                    validator: (_) => brandCtrl.text.trim().isEmpty ? 'Requerido' : null,
                  ),
                  if (localPreset == 'Otro...') ...[
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: brandCtrl,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: localType == EntityType.bank ? 'Nombre del banco' : 'Nombre de la app',
                        hintText: 'Escríbelo aquí...',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                  ],
                ] else
                  TextFormField(
                    controller: brandCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la tienda',
                      hintText: 'Ej. Totto, Lili Pink',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: limitCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [CurrencyInputFormatter()],
                  decoration: InputDecoration(
                    labelText: localType == EntityType.store ? 'Cupo aprobado' : 'Cupo o límite total (opcional)',
                    hintText: 'Ej. 3.000.000',
                  ),
                  validator: (v) {
                    if (localType == EntityType.store) {
                      final n = double.tryParse(CurrencyInputFormatter.unformat(v ?? ''));
                      if (n == null || n <= 0) return 'Requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    setState(() {
                      _newEntityType = localType;
                      _newEntityPreset = localPreset;
                      _newEntityBrandCtrl.text = brandCtrl.text.trim();
                      _newEntityLimitCtrl.text = limitCtrl.text;
                      _lenderCtrl.text = brandCtrl.text.trim();
                      _selectedEntityId = '__new__';
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Confirmar entidad'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Tarea 1: advance to the next step, validating only the fields that are
  // currently mounted (i.e. those belonging to `_currentStep`).
  void _nextStep() {
    if (_currentStep == 0 && _selectedEntityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige a qué entidad pertenece este crédito')),
      );
      return;
    }
    final isValid = _formKey.currentState?.validate() ?? true;
    if (!isValid) return;
    // La cuota calculada ya no tiene un campo visible propio (vive en el
    // panel grande de arriba) — se valida acá en vez de con un
    // TextFormField.validator oculto.
    if (_currentStep == 2 && _type == CreditType.loan) {
      final quota = double.tryParse(CurrencyInputFormatter.unformat(_quotaCtrl.text));
      if (quota == null || quota <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Completa el monto y el número de cuotas para calcular el valor de la cuota')),
        );
        return;
      }
    }
    if (_currentStep == 3 && _type == CreditType.loan && _startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la fecha de primer pago')),
      );
      return;
    }
    if (_currentStep < _lastStep) {
      setState(() {
        _stepDirection = 1;
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _stepDirection = -1;
        _currentStep--;
      });
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

    // Resuelve la entidad (aplica a loan y card por igual).
    String? quotaId;
    if (_selectedEntityId != null && _selectedEntityId != 'none') {
      if (_selectedEntityId == '__new__') {
        quotaId = 'quota_${DateTime.now().millisecondsSinceEpoch}';
        final entityLimit = double.tryParse(
                CurrencyInputFormatter.unformat(_newEntityLimitCtrl.text)) ??
            0;
        await ref.read(commercialQuotasProvider.notifier).upsert(
              CommercialQuota(
                id: quotaId,
                brand: _newEntityBrandCtrl.text.trim(),
                limit: entityLimit,
                entityType: _newEntityType,
              ),
            );
      } else {
        quotaId = _selectedEntityId;
      }
    }

    Credit credit;
    if (_type == CreditType.card) {
      final creditLimit =
          double.tryParse(CurrencyInputFormatter.unformat(_limitCtrl.text)) ?? 0;
      final currentBalance =
          double.tryParse(CurrencyInputFormatter.unformat(_balanceCtrl.text)) ?? 0;
      final cutoffDay = int.tryParse(_cutoffDayCtrl.text) ?? 1;
      final paymentDueOffsetDays = int.tryParse(_paymentOffsetCtrl.text) ?? 20;
      final interestRate =
          double.tryParse(_interestCtrl.text.replaceAll(',', '.')) ?? 0;
      final managementFee =
          double.tryParse(CurrencyInputFormatter.unformat(_managementFeeCtrl.text)) ?? 0;

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
        quotaId: quotaId,
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
      final totalAmount =
          double.parse(CurrencyInputFormatter.unformat(_amountCtrl.text));
      final totalInstallments = int.parse(_installmentsCtrl.text);
      final quotaAmount =
          double.parse(CurrencyInputFormatter.unformat(_quotaCtrl.text));
      final interestRate = _interestUnknown
          ? 0.0
          : double.tryParse(_interestCtrl.text.replaceAll(',', '.')) ?? 0;
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
        quotaId: quotaId,
        interestUnknown: _interestUnknown,
        earlyPaymentWaivesInterest: _earlyPaymentWaivesInterest,
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

  // Getter (no static const) porque el título del paso 2/3 depende del tipo
  // de crédito elegido en el paso 1 — separar "Datos Financieros" en dos
  // pasos más chicos (en vez de un único paso con 4-5 bloques apilados) es
  // la mejora de UX pedida: menos densidad visual por pantalla.
  List<String> get _stepTitles => _type == CreditType.card
      ? const ['Tu entidad', 'Tipo de crédito', 'Cupo de la tarjeta', 'Interés y costos', 'Confirmación']
      : const ['Tu entidad', 'Tipo de crédito', 'Monto y cuotas', 'Fecha de pago', 'Confirmación'];

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
                child: ClipRect(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    // Slide de pantalla completa (no un desplazamiento
                    // sutil): el paso saliente se esconde del todo hacia un
                    // lado mientras el nuevo entra del todo desde el otro —
                    // la sensación de "moverse" físicamente entre pasos que
                    // se pidió, no un detalle apenas perceptible. Duración
                    // media (420ms) para que se note sin sentirse lenta.
                    transitionBuilder: (child, animation) {
                      final entering = child.key == ValueKey(_currentStep);
                      final sign = entering ? _stepDirection : -_stepDirection;
                      final offsetAnimation = Tween<Offset>(
                        begin: Offset(1.0 * sign, 0),
                        end: Offset.zero,
                      ).animate(animation);
                      return SlideTransition(position: offsetAnimation, child: child);
                    },
                    child: ListView(
                      key: ValueKey(_currentStep),
                      padding: const EdgeInsets.all(KreditSpacing.card),
                      children: [
                        ...switch (_currentStep) {
                          0 => _step0EntitySelection(kredit),
                          1 => _step1BasicData(kredit),
                          2 => _step2FinancialCore(kredit),
                          3 => _step3ScheduleAndExtras(kredit),
                          _ => _step4ColorNotesConfirm(kredit),
                        },
                      ],
                    ),
                  ),
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

  IconData _entityIcon(String type) => switch (type) {
        EntityType.bank => Icons.account_balance_outlined,
        EntityType.store => Icons.storefront_outlined,
        _ => Icons.phone_android_outlined,
      };

  String _entityTypeLabel(String type) => switch (type) {
        EntityType.bank => 'Banco',
        EntityType.store => 'Tienda',
        _ => 'App / Plataforma',
      };

  String _entityTypeForId(String entityId) {
    if (entityId == '__new__') return _newEntityType;
    final quotas = ref.read(commercialQuotasProvider).valueOrNull ?? const [];
    for (final q in quotas) {
      if (q.id == entityId) return q.entityType;
    }
    return EntityType.store;
  }

  List<Widget> _step0EntitySelection(KreditColors kredit) {
    final quotas = ref.watch(commercialQuotasProvider).valueOrNull ?? const [];
    return [
      const Text(
        '¿Dónde tienes este crédito?',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: KreditTextSize.heading),
      ),
      const SizedBox(height: 4),
      Text(
        'Elige la entidad donde tienes el crédito que vas a registrar.',
        style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
      ),
      const SizedBox(height: 16),
      _NoEntityCard(
        selected: _selectedEntityId == 'none',
        onTap: () => setState(() {
          _selectedEntityId = 'none';
          if (_selectedLenderPreset != null && _selectedLenderPreset != 'Otro...') {
            _lenderCtrl.text = _selectedLenderPreset!;
          }
        }),
      ),
      if (quotas.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text(
          'TUS ENTIDADES',
          style: TextStyle(
            fontSize: KreditTextSize.caption,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: kredit.textTertiary,
          ),
        ),
        const SizedBox(height: 10),
        // PageView: cada entidad ocupa todo el ancho disponible.
        // Leer créditos fuera del builder evita ref.watch por item.
        Builder(builder: (ctx) {
          final allCredits = ref.watch(creditsProvider).valueOrNull ?? const [];
          final loans = allCredits.whereType<LoanCredit>().toList();
          // Ancho de la tarjeta = ancho disponible; alto = ancho/1.9.
          return LayoutBuilder(builder: (ctx, constraints) {
            final cardW = constraints.maxWidth;
            final cardH = (cardW / 1.9).ceilToDouble();
            return SizedBox(
              height: cardH,
              child: PageView.builder(
                itemCount: quotas.length,
                padEnds: false,
                pageSnapping: true,
                itemBuilder: (ctx, i) {
                  final q = quotas[i];
                  return Padding(
                    padding: EdgeInsets.only(
                      right: i < quotas.length - 1 ? 12 : 0,
                    ),
                    child: _EntityPickerCard(
                      quota: q,
                      selected: _selectedEntityId == q.id,
                      allLoans: loans,
                      onTap: () => setState(() {
                        _selectedEntityId = q.id;
                        _lenderCtrl.text = q.brand;
                      }),
                    ),
                  );
                },
              ),
            );
          });
        }),
        if (quotas.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: quotas
                  .map((q) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _selectedEntityId == q.id ? 16 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: _selectedEntityId == q.id
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                        ),
                      ))
                  .toList(),
            ),
          ),
      ],
      const SizedBox(height: 8),
      _AddEntityButton(
        selected: _selectedEntityId == '__new__',
        entityName: _selectedEntityId == '__new__' && _newEntityBrandCtrl.text.trim().isNotEmpty
            ? _newEntityBrandCtrl.text.trim()
            : null,
        onTap: () => _showNewEntitySheet(kredit),
      ),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _step1BasicData(KreditColors kredit) {
    final suggestion = _typeSuggestion;
    final subEntityOptions = subEntitiesForLender(_lenderCtrl.text);
    final hasEntity = _selectedEntityId != null && _selectedEntityId != 'none';
    return [
      const Text(
        '¿Qué quieres registrar?',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: KreditTextSize.heading),
      ),
      const SizedBox(height: 4),
      Text(
        'Elige el tipo de crédito para adaptar los campos que siguen.',
        style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
      ),
      const SizedBox(height: 14),
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
      if (hasEntity) ...[
        // Entidad elegida en paso 0 — chip read-only con botón Cambiar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: kredit.bgCard,
            borderRadius: BorderRadius.circular(KreditRadius.tile),
            border: Border.all(color: kredit.borderCard),
          ),
          child: Row(
            children: [
              Icon(
                _entityIcon(_selectedEntityId == '__new__' ? _newEntityType : _entityTypeForId(_selectedEntityId!)),
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _selectedEntityId == '__new__'
                      ? (_newEntityBrandCtrl.text.trim().isEmpty ? 'Nueva entidad' : _newEntityBrandCtrl.text.trim())
                      : _lenderCtrl.text,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _stepDirection = -1;
                  _currentStep = 0;
                }),
                child: const Text('Cambiar'),
              ),
            ],
          ),
        ),
      ] else ...[
        // Sin entidad: dropdown de banco/prestamista como antes
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
        Builder(
          builder: (context) {
            final duplicate = _duplicateActiveCredit;
            if (duplicate == null) return const SizedBox.shrink();
            final typeLabel = _type == CreditType.card ? 'una tarjeta' : 'un cupo';
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.all(KreditSpacing.tile),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(KreditRadius.tile),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, size: KreditIconSize.small, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ya tienes $typeLabel activo con esta entidad: "${duplicate.name}". '
                          'Si es tuyo, ábrelo en vez de crear otro. Si es de otra persona (ej. lo '
                          'usas prestado), puedes seguir y crear este como uno distinto.',
                          style: const TextStyle(fontSize: KreditTextSize.caption),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed('/credit-detail', arguments: duplicate.id);
                      },
                      child: const Text('Abrir el que ya tengo', style: TextStyle(fontSize: KreditTextSize.caption)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      ], // end else (sin entidad)
      const SizedBox(height: 12),
    ];
  }


  // Paso 2: solo el bloque financiero "duro" — lo mínimo que se necesita
  // antes de poder calcular algo (monto/cupo, cuotas, tasa). Todo lo demás
  // (fecha, frecuencia, casos opcionales) se movió al paso 3 para no
  // apilar 4-5 bloques en una sola pantalla.
  List<Widget> _step2FinancialCore(KreditColors kredit) {
    return [
      Text(
        _type == CreditType.card ? 'Cupo de la tarjeta' : 'Monto y cuotas',
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: KreditTextSize.heading),
      ),
      const SizedBox(height: 4),
      Text(
        _type == CreditType.card
            ? 'Cuánto cupo tiene tu tarjeta y cuánto debes hoy.'
            : 'Cuánto vas a financiar, en cuántas cuotas y a qué tasa.',
        style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
      ),
      const SizedBox(height: 16),
      _LiveFinancialHero(
        type: _type,
        quotaText: _quotaCtrl.text,
        limitText: _limitCtrl.text,
        balanceText: _balanceCtrl.text,
      ),
      const SizedBox(height: 20),
      if (_type == CreditType.loan) ..._loanFieldsCore(),
      if (_type == CreditType.card) ..._cardFieldsCore(),
      const SizedBox(height: 12),
    ];
  }

  // Paso 3: casos opcionales y de calendario — separado del paso 2 para
  // que cada pantalla del formulario tenga un propósito único y quepa
  // cómoda sin scroll excesivo.
  List<Widget> _step3ScheduleAndExtras(KreditColors kredit) {
    return [
      Text(
        _type == CreditType.card ? 'Interés y costos' : 'Fecha de pago',
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: KreditTextSize.heading),
      ),
      const SizedBox(height: 4),
      Text(
        _type == CreditType.card
            ? 'Cuánto te cobra la tarjeta por usarla.'
            : 'Cuándo empieza a pagarse y con qué frecuencia.',
        style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
      ),
      if (_type == CreditType.loan) ..._loanFieldsSchedule(),
      if (_type == CreditType.card) ..._cardFieldsExtra(),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _step4ColorNotesConfirm(KreditColors kredit) {
    return [
      const Text(
        '¡Ya casi está!',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: KreditTextSize.heading),
      ),
      const SizedBox(height: 4),
      Text(
        'Revisa que todo esté correcto antes de registrar el crédito.',
        style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
      ),
      const SizedBox(height: 12),
      ..._previewCard(),
      Text(
        'DETALLES DEL CRÉDITO',
        style: TextStyle(
          fontSize: KreditTextSize.caption,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: kredit.textTertiary,
        ),
      ),
      const SizedBox(height: 8),
      _SummaryGrid(items: _summaryRows()),
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
        // Sin esto, la vista previa nunca mostraba el voucher genérico
        // para una compra de cupo comercial — quotaId solo se resolvía
        // realmente en _save(). Cualquier valor no nulo basta aquí: el
        // preview solo necesita saber que ES una compra de cupo, el id
        // real (nuevo o existente) se resuelve al guardar.
        quotaId: (_selectedEntityId != null && _selectedEntityId != 'none') ? 'preview-quota' : null,
        interestUnknown: _interestUnknown,
        earlyPaymentWaivesInterest: _earlyPaymentWaivesInterest,
      );
    } catch (_) {
      return null;
    }
  }

  List<({String label, String value})> _summaryRows() {
    final name = _nameCtrl.text.trim().isEmpty ? '(sin nombre)' : _nameCtrl.text.trim();
    final lender = _lenderCtrl.text.trim().isEmpty ? '(sin definir)' : _lenderCtrl.text.trim();
    final typeLabel = _type == CreditType.card ? 'Tarjeta de Crédito' : 'Préstamo / Cuotas Fijas';

    final entityName = _selectedEntityId == '__new__'
        ? (_newEntityBrandCtrl.text.trim().isEmpty ? 'Nueva entidad' : _newEntityBrandCtrl.text.trim())
        : lender;

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
        (label: 'Nombre', value: name),
        (label: 'Tipo', value: typeLabel),
        if (_selectedEntityId != null && _selectedEntityId != 'none')
          (label: 'Entidad', value: entityName)
        else
          (label: 'Entidad', value: lender),
        (label: 'Límite', value: limit),
        (label: 'Saldo actual', value: balance),
        (label: 'Corte', value: cutoff),
        (label: 'Fecha límite', value: offset),
      ];
    }

    final amount = _amountCtrl.text.trim().isEmpty ? '0' : _amountCtrl.text.trim();
    final installments = _installmentsCtrl.text.trim().isEmpty ? '—' : _installmentsCtrl.text.trim();
    final quota = _quotaCtrl.text.trim().isEmpty ? '0' : _quotaCtrl.text.trim();
    final startDate = _startDate == null ? '(sin definir)' : formatDate(toDateStr(_startDate!));
    final paidCount = int.tryParse(_paidInstallmentsCtrl.text.trim()) ?? 0;
    return [
      (label: 'Nombre', value: name),
      (label: 'Tipo', value: typeLabel),
      if (_selectedEntityId != null && _selectedEntityId != 'none')
        (label: 'Entidad', value: entityName)
      else
        (label: 'Entidad', value: lender),
      (label: 'Monto financiado', value: '\$$amount'),
      (label: 'Cuotas', value: installments),
      (label: 'Valor cuota', value: '\$$quota'),
      (label: 'Primer pago', value: startDate),
      if (paidCount > 0) (label: 'Cuotas ya pagadas', value: '$paidCount'),
    ];
  }

  // Paso 2 (préstamo): solo lo indispensable para poder calcular la cuota.
  List<Widget> _loanFieldsCore() {
    return [
      const SizedBox(height: 12),
      _SectionCard(
        label: 'DATOS DEL CRÉDITO',
        icon: Icons.request_quote_outlined,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [CurrencyInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Monto a financiar', hintText: 'Ej. 1.500.000'),
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
                  decoration: const InputDecoration(labelText: 'Número de cuotas', hintText: 'Ej. 12'),
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
          if (_overLimitWarning != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _InterestRateWarningHint(text: _overLimitWarning!),
            ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('No conozco la tasa'),
            subtitle: const Text('Kredit solo hará seguimiento de cuotas, sin calcular interés'),
            value: _interestUnknown,
            onChanged: (v) => setState(() {
              _interestUnknown = v;
              if (v) _interestCtrl.clear();
            }),
          ),
          if (_interestUnknown)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Cuenta sin intereses registrados',
                style: TextStyle(
                  fontSize: KreditTextSize.caption,
                  color: Theme.of(context).extension<KreditColors>()!.textTertiary,
                ),
              ),
            )
          else ...[
            TextFormField(
              controller: _interestCtrl,
              style: const TextStyle(fontSize: KreditTextSize.heading),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Interés anual',
                hintText: 'Opcional — ej. 28%',
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
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Si pago antes de la fecha de pago, no cobran interés'),
            value: _earlyPaymentWaivesInterest,
            onChanged: (v) => setState(() => _earlyPaymentWaivesInterest = v),
          ),
        ],
      ),
    ];
  }

  // Paso 3 (préstamo): calendario de pagos + casos opcionales, separado del
  // paso 2 para que cada pantalla tenga un único propósito y quepa sin
  // scroll excesivo.
  List<Widget> _loanFieldsSchedule() {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return [
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
                      style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
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
                      style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: kredit.borderCard.withValues(alpha: 0.6)),
          const SizedBox(height: 16),
          // Caso opcional, pero siempre visible en vez de ir escondido tras
          // un desplegable — si el usuario ya venía pagando este crédito
          // antes de registrarlo, el dato está ahí, a la vista, sin tener
          // que buscarlo.
          TextFormField(
            controller: _paidInstallmentsCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '¿Ya venías pagando este crédito? (opcional)',
              hintText: 'Cuántas cuotas ya pagaste, ej. 2',
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
        ],
      ),
    ];
  }

  // Paso 2 (tarjeta): cupo y ciclo de facturación — lo indispensable.
  List<Widget> _cardFieldsCore() {
    return [
      const SizedBox(height: 12),
      _SectionCard(
        label: 'DATOS DE LA TARJETA',
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
                  onChanged: (_) => setState(() {}),
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
                  onChanged: (_) => setState(() {}),
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
                  // Unión con la lista fija: algunas plantillas de banco
                  // (ver entity_templates.dart, p. ej. Bancolombia = 21)
                  // usan valores fuera de [10,15,20,25,30,35,40] — sin esto
                  // el DropdownButtonFormField crashea con "there should be
                  // exactly one item with value X" al autocompletar esa
                  // entidad.
                  items:
                      ({10, 15, 20, 25, 30, 35, 40, int.tryParse(_paymentOffsetCtrl.text) ?? 20}.toList()
                            ..sort())
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
    ];
  }

  // Paso 3 (tarjeta): costo de la tarjeta + notas — separado del cupo/corte
  // para no apilar 3 tarjetas de sección en una sola pantalla.
  List<Widget> _cardFieldsExtra() {
    return [
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
                      style: const TextStyle(fontSize: KreditTextSize.heading),
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
                  style: const TextStyle(fontSize: KreditTextSize.heading),
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
            style: TextStyle(fontSize: KreditTextSize.heading, color: Theme.of(context).extension<KreditColors>()!.textPrimary),
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

/// Panel editorial que reacciona en vivo a lo que el usuario va tecleando en
/// el paso 2 — mismo lenguaje visual que el "DEUDA TOTAL" del dashboard
/// (cifra protagonista en `KreditTextSize.hero`, eyebrow en mayúsculas), en
/// vez de que el paso se sienta solo como una fila de campos rellenables.
/// Para préstamo muestra el valor de cuota ya calculado; para tarjeta,
/// el cupo disponible resultante de límite menos saldo actual.
class _LiveFinancialHero extends StatelessWidget {
  final String type;
  final String quotaText;
  final String limitText;
  final String balanceText;

  const _LiveFinancialHero({
    required this.type,
    required this.quotaText,
    required this.limitText,
    required this.balanceText,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;

    if (type == CreditType.card) {
      final limit = double.tryParse(CurrencyInputFormatter.unformat(limitText)) ?? 0;
      final balance = double.tryParse(CurrencyInputFormatter.unformat(balanceText)) ?? 0;
      final hasLimit = limit > 0;
      final available = hasLimit ? (limit - balance).clamp(0, limit) : 0.0;
      final usage = hasLimit ? (balance / limit).clamp(0.0, 1.0) : 0.0;
      final usageColor = usage >= 0.85 ? kredit.danger : (usage >= 0.65 ? kredit.warning : accent);

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
            Text(
              'CUPO DISPONIBLE',
              style: TextStyle(
                fontSize: KreditTextSize.caption,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: kredit.textTertiary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasLimit ? formatCOP(available.toDouble()) : '—',
              style: const TextStyle(
                fontSize: KreditTextSize.hero,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: hasLimit ? usage : 0,
                minHeight: 5,
                backgroundColor: kredit.borderCard.withValues(alpha: 0.55),
                valueColor: AlwaysStoppedAnimation<Color>(usageColor),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasLimit
                  ? 'Usas ${(usage * 100).round()}% de tu cupo de ${formatCOP(limit)}'
                  : 'Ingresa el límite para ver tu cupo disponible',
              style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
            ),
          ],
        ),
      );
    }

    final quota = double.tryParse(CurrencyInputFormatter.unformat(quotaText)) ?? 0;
    final hasQuota = quota > 0;

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
          Text(
            'VALOR DE LA CUOTA',
            style: TextStyle(
              fontSize: KreditTextSize.caption,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: kredit.textTertiary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasQuota ? formatCOP(quota) : '—',
            style: const TextStyle(
              fontSize: KreditTextSize.hero,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasQuota
                ? 'Valor aproximado, calculado con base en el monto, las cuotas y el interés ingresados.'
                : 'Completa los datos de abajo para calcularla automáticamente.',
            style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected ? accent.withValues(alpha: 0.16) : kredit.bgSecondary,
                  borderRadius: BorderRadius.circular(KreditRadius.tile),
                ),
                child: Icon(icon, size: KreditIconSize.small, color: selected ? accent : kredit.textTertiary),
              ),
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

/// One "label: value" row used inside the step-3 confirmation summary.
/// Tarjeta de resumen del paso 4: dos columnas de datos alineadas a la
/// izquierda (etiqueta arriba, valor abajo) con una línea interna muy tenue
/// que solo marca la separación de columnas — no una tabla de "etiqueta a
/// la izquierda, valor a la derecha" como antes, que se sentía más a
/// formulario que a resumen visual.
class _SummaryGrid extends StatelessWidget {
  final List<({String label, String value})> items;

  const _SummaryGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final left = <({String label, String value})>[];
    final right = <({String label, String value})>[];
    for (var i = 0; i < items.length; i++) {
      (i.isEven ? left : right).add(items[i]);
    }

    Widget column(List<({String label, String value})> data) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < data.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              _SummaryTile(label: data[i].label, value: data[i].value),
            ],
          ],
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KreditSpacing.card),
      decoration: BoxDecoration(
        color: kredit.bgCard,
        borderRadius: BorderRadius.circular(KreditRadius.card),
        border: Border.all(color: kredit.borderCard.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: column(left)),
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: kredit.borderCard.withValues(alpha: 0.4),
          ),
          Expanded(child: column(right)),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: kredit.textTertiary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontSize: KreditTextSize.body, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

/// Tarjeta visual "Sin entidad específica" — diseño de voucher abstracto dashed.
class _NoEntityCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _NoEntityCard({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.08) : kredit.bgCard,
          borderRadius: BorderRadius.circular(KreditRadius.card),
          border: Border.all(
            color: selected ? accent : kredit.borderCard,
            width: selected ? 1.5 : 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(KreditRadius.tile),
                border: Border.all(
                  color: selected ? accent.withValues(alpha: 0.4) : kredit.borderCard,
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
                color: kredit.bgSecondary,
              ),
              child: Icon(
                Icons.credit_card_off_outlined,
                size: KreditIconSize.small,
                color: selected ? accent : kredit.textTertiary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sin entidad específica',
                    style: TextStyle(
                      fontSize: KreditTextSize.body,
                      fontWeight: FontWeight.w700,
                      color: selected ? accent : kredit.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Registra el crédito sin vincularlo a una entidad.',
                    style: TextStyle(
                      fontSize: KreditTextSize.caption,
                      color: kredit.textTertiary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? accent : kredit.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón CTA centrado para registrar una nueva entidad.
class _AddEntityButton extends StatelessWidget {
  final bool selected;
  final String? entityName; // nombre configurado si ya se confirmó una entidad
  final VoidCallback onTap;

  const _AddEntityButton({
    required this.selected,
    required this.onTap,
    this.entityName,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    final hasEntity = selected && entityName != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(KreditRadius.card),
          gradient: selected
              ? LinearGradient(
                  colors: [accent.withValues(alpha: 0.18), accent.withValues(alpha: 0.08)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : kredit.bgCard,
          border: Border.all(
            color: selected ? accent : kredit.borderCard,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? accent : kredit.bgSecondary,
              ),
              child: Icon(
                hasEntity ? Icons.check : Icons.add,
                size: 18,
                color: selected ? Colors.black : kredit.textTertiary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasEntity ? entityName! : 'Nueva entidad',
                    style: TextStyle(
                      fontSize: KreditTextSize.body,
                      fontWeight: FontWeight.w800,
                      color: selected ? accent : kredit.textPrimary,
                    ),
                  ),
                  Text(
                    hasEntity ? 'Toca para editar' : 'Banco, tienda o app',
                    style: TextStyle(
                      fontSize: KreditTextSize.caption,
                      color: kredit.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: selected ? accent : kredit.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _EntityTypePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _EntityTypePill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.14) : kredit.bgSecondary,
          borderRadius: BorderRadius.circular(KreditRadius.tile),
          border: Border.all(
            color: selected ? accent : kredit.borderCard,
            width: selected ? 1.3 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: selected ? accent : kredit.textTertiary),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: KreditTextSize.caption,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? accent : kredit.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta/voucher visual de una entidad en el picker del paso 0.
/// Usa [EntityCardFace] — mismo visual que WalletCard pero con disponible
/// dentro de la tarjeta, sin deuda restante.
class _EntityPickerCard extends StatelessWidget {
  final CommercialQuota quota;
  final bool selected;
  final List<LoanCredit> allLoans;
  final VoidCallback onTap;

  const _EntityPickerCard({
    required this.quota,
    required this.selected,
    required this.allLoans,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Cara de tarjeta/voucher con disponible dentro.
          EntityCardFace(quota: quota, allLoans: allLoans),
          // Anillo de selección superpuesto.
          if (selected)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: accent, width: 2.5),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          // Check en la esquina superior derecha.
          Positioned(
            top: 8,
            right: 8,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: selected
                  ? Container(
                      key: const ValueKey('check'),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: const Icon(Icons.check, size: 14, color: Colors.black),
                    )
                  : Container(
                      key: const ValueKey('empty'),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.35),
                        border: Border.all(color: Colors.white54, width: 1),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
