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
import '../../domain/date_utils.dart';
import '../../domain/entity_templates.dart';
import '../../domain/interest_rate.dart';
import '../../domain/loan_calculator.dart';
import '../../providers/commercial_quotas_provider.dart';
import '../../providers/credits_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/credit_display_utils.dart';
import '../../widgets/account/voucher_pattern_picker.dart';
import '../../widgets/card_design_painter.dart';
import '../../widgets/interest_rate_type_field.dart';
import '../../widgets/kredit_section_card.dart';
import '../../widgets/voucher_pattern.dart';
import '../../widgets/wallet_card.dart';

part 'add_credit_sheet_widgets.dart';

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
  VoucherPattern _selectedVoucherPattern = VoucherPattern.diagonalLines;
  CardDesign? _selectedCardDesign;
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

  // Selects all text on tap so a default value (e.g. "0") is fully replaced
  // on the first keystroke instead of the cursor landing at the end.
  static void _selectAll(TextEditingController ctrl) {
    ctrl.selection =
        TextSelection(baseOffset: 0, extentOffset: ctrl.text.length);
  }

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
  final _cardInitInstCtrl = TextEditingController();
  final _cardPaidInstCtrl = TextEditingController();

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

  // Modo de creación: null = selector, 'tienda' | 'banco' | 'tarjeta' | 'prestamo'
  // 'banco' es un paso intermedio donde el usuario elige banco + subtipo.
  String? _mode;

  // Subtipo dentro del flujo 'banco': 'tarjeta' | 'avance' (null hasta elegir)
  String? _bancoSubType;

  // Card fields
  final _limitCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController(text: '0');
  final _cutoffDayCtrl = TextEditingController(text: '15');
  final _paymentOffsetCtrl = TextEditingController(text: '20');
  final _managementFeeCtrl = TextEditingController(text: '0');
  String _managementFeeFrequency = ManagementFeeFrequency.monthly;

  // Nuevos campos para flujo tarjeta
  int _cutoffDayInt = 15;
  // Days between cut date and payment due date (offset, not absolute day)
  int _tarjetaPaymentOffsetDays = 7;
  bool? _oneInstallmentInterestPolicy; // null=indeterminado, true/false=elegido

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
      _cardInitInstCtrl,
      _cardPaidInstCtrl,
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
    final discard = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final kredit = Theme.of(ctx).extension<KreditColors>()!;
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: kredit.borderCard,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Icon(Icons.delete_outline, size: KreditIconSize.large, color: AppColors.danger),
                const SizedBox(height: 12),
                Text(
                  '¿Descartar este crédito?',
                  style: TextStyle(fontSize: KreditTextSize.heading, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Los datos no guardados se perderán.',
                  style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Descartar'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Seguir editando'),
                  ),
                ),
              ],
            ),
          ),
        )));
      },
    );
    return discard ?? false;
  }

  /// Modal para crear una nueva entidad (banco / tienda / app).
  /// [forcedType]: si se pasa, fija el tipo y oculta el selector de tipo.
  void _showNewEntitySheet(KreditColors kredit, {String? forcedType}) {
    // Estado local del sheet — no afecta el padre hasta que el user confirma.
    var localType = forcedType ?? _newEntityType;
    String? localPreset = _newEntityPreset;
    final brandCtrl = TextEditingController(text: _newEntityBrandCtrl.text);
    final limitCtrl = TextEditingController(text: _newEntityLimitCtrl.text);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: StatefulBuilder(
            builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 0,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).extension<KreditColors>()!.borderCard,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Nueva entidad',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                // Selector de tipo — oculto cuando el tipo está forzado
                if (forcedType == null)
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
                  onTap: () => _selectAll(limitCtrl),
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
        ),
      ),
    );
  }

  // Tarea 1: advance to the next step, validating only the fields that are
  // currently mounted (i.e. those belonging to `_currentStep`).
  void _nextStep() {
    // Modo null → mostrar selector de modo; no hay "Siguiente" real
    if (_mode == null) return;

    // Flujo banco: paso 0 → transicionar a tarjeta/prestamo en step 1
    if (_mode == 'banco' && _currentStep == 0) {
      if (_lenderCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona un banco')),
        );
        return;
      }
      if (_bancoSubType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Elige si es Tarjeta o Avance / Adelanto')),
        );
        return;
      }
      setState(() {
        _mode = _bancoSubType == 'tarjeta' ? 'tarjeta' : 'prestamo';
        _type = _bancoSubType == 'tarjeta' ? CreditType.card : CreditType.loan;
        _stepDirection = 1;
        _currentStep = 1;
      });
      return;
    }

    // Validación por flujo y paso
    if (_mode == 'tienda') {
      if (_currentStep == 0 && _selectedEntityId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Elige a qué entidad pertenece este crédito')),
        );
        return;
      }
      if (_currentStep == 1) {
        final quota = double.tryParse(CurrencyInputFormatter.unformat(_quotaCtrl.text));
        if (quota == null || quota <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Completa el monto y el número de cuotas')),
          );
          return;
        }
      }
      if (_currentStep == 2 && _startDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona la fecha de primer pago')),
        );
        return;
      }
    }

    if (_mode == 'tarjeta') {
      if (_currentStep == 0 && _lenderCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona un banco')),
        );
        return;
      }
    }

    if (_mode == 'prestamo') {
      if (_currentStep == 0 && _lenderCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona un banco')),
        );
        return;
      }
      if (_currentStep == 1) {
        final quota = double.tryParse(CurrencyInputFormatter.unformat(_quotaCtrl.text));
        if (quota == null || quota <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Completa el monto y el número de cuotas')),
          );
          return;
        }
      }
      if (_currentStep == 2 && _startDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona la fecha de primer pago')),
        );
        return;
      }
    }

    final isValid = _formKey.currentState?.validate() ?? true;
    if (!isValid) return;

    if (_currentStep < _lastStep) {
      setState(() {
        _stepDirection = 1;
        _currentStep++;
      });
    }
  }

  void _setMode(String mode) {
    setState(() {
      _mode = mode;
      _type = mode == 'tarjeta' ? CreditType.card : CreditType.loan;
      _currentStep = 0;
      _stepDirection = 1;
      if (mode == 'banco') {
        _bancoSubType = null;
        _lenderCtrl.text = 'Bancolombia';
        _selectedLenderPreset = 'Bancolombia';
      } else if (mode == 'tarjeta' || mode == 'prestamo') {
        _lenderCtrl.text = 'Bancolombia';
        _selectedLenderPreset = 'Bancolombia';
      }
    });
  }

  void _backToModeSelector() {
    setState(() {
      _mode = null;
      _type = CreditType.loan;
      _currentStep = 0;
      _stepDirection = -1;
    });
  }

  void _previousStep() {
    if (_mode != null && _currentStep == 0) {
      _backToModeSelector();
      return;
    }
    // Tarjeta/préstamo step 1 viniendo del flujo 'banco': retroceder a 'banco' step 0
    if ((_mode == 'tarjeta' || _mode == 'prestamo') && _currentStep == 1 && _bancoSubType != null) {
      setState(() {
        _mode = 'banco';
        _stepDirection = -1;
        _currentStep = 0;
      });
      return;
    }
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
                voucherPattern: _mode == 'tienda' ? _selectedVoucherPattern.name : null,
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

      // Para el flujo de tarjeta nuevo, usar los dropdowns int en lugar de los text controllers
      final effectiveCutoffDay = _mode == 'tarjeta' ? _cutoffDayInt : cutoffDay;
      final effectivePaymentDueDay = 0; // derived from offset, not stored as absolute

      final cardCredit = CardCredit(
        id: id,
        name: name,
        lender: lender,
        color: null,
        notes: notes,
        creditLimit: creditLimit,
        currentBalance: currentBalance,
        cutoffDay: effectiveCutoffDay,
        paymentDueOffsetDays: _mode == 'tarjeta' ? _tarjetaPaymentOffsetDays : paymentDueOffsetDays,
        paymentDueDay: effectivePaymentDueDay,
        oneInstallmentInterestPolicy: _oneInstallmentInterestPolicy,
        interestRate: interestRate,
        interestRateType: _interestRateType,
        managementFee: managementFee,
        managementFeeFrequency: _managementFeeFrequency,
        quotaId: quotaId,
        cardDesign: _selectedCardDesign?.name,
        movements: currentBalance > 0
            ? [
                CardMovement(
                  date: toDateStr(_startDate ?? DateTime.now()),
                  type: CardMovementType.charge,
                  amount: currentBalance,
                  note: 'Saldo inicial registrado',
                  chargeInstallments: (int.tryParse(_cardInitInstCtrl.text.trim()) ?? 1) > 1
                      ? int.tryParse(_cardInitInstCtrl.text.trim())
                      : null,
                ),
              ]
            : [],
      );
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
        color: null,
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
        cardDesign: null,
      );
    }

    try {
      await ref.read(creditsProvider.notifier).addCredit(credit);
      if (_mode == 'tienda' && quotaId != null && _selectedEntityId != '__new__') {
        final quotas = ref.read(commercialQuotasProvider).value ?? [];
        final existingQuota = quotas.where((q) => q.id == quotaId).firstOrNull;
        if (existingQuota != null) {
          existingQuota.voucherPattern = _selectedVoucherPattern.name;
          await ref.read(commercialQuotasProvider.notifier).upsert(existingQuota);
        }
      }
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

  int get _lastStep => switch (_mode) {
    'tienda' => 3,
    'banco' => 0,
    'tarjeta' => 3,
    'prestamo' => 3,
    _ => 4,
  };

  List<String> get _stepTitles => switch (_mode) {
    'tienda' => const ['Entidad', 'Datos compra', 'Fechas', 'Confirmar'],
    'banco' => const ['Banco y tipo'],
    'tarjeta' => const ['Banco', 'Cupo y finanzas', 'Ciclo de pago', 'Confirmar'],
    'prestamo' => const ['Banco', 'Datos y condiciones', 'Fechas', 'Confirmar'],
    _ => const ['Entidad', 'Tipo de crédito', 'Monto y cuotas', 'Fecha de pago', 'Confirmación'],
  };

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
              // RepaintBoundary isolates the continuous animation repaints from
              // the step content below — without it every animation frame forces
              // a full-screen repaint.
              RepaintBoundary(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  child: _mode == null
                      ? _InitialStepIndicator(kredit: kredit)
                      : _StepProgress(
                          currentStep: _currentStep,
                          titles: _stepTitles,
                          kredit: kredit,
                        ),
                ),
              ),
              Expanded(
                child: RepaintBoundary(
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
                      final entering = child.key == ValueKey('${_mode}_$_currentStep');
                      final sign = entering ? _stepDirection : -_stepDirection;
                      final offsetAnimation = Tween<Offset>(
                        begin: Offset(1.0 * sign, 0),
                        end: Offset.zero,
                      ).animate(animation);
                      return SlideTransition(position: offsetAnimation, child: child);
                    },
                    // Builder lets us compute the step item list once and pass
                    // it to ListView.builder, which defers Element/State
                    // creation to when each item scrolls into view — avoids
                    // the first-render jank from simultaneous initState() calls
                    // on all TextFormField and DropdownButtonFormField widgets.
                    child: Builder(builder: (context) {
                      final stepItems = switch (_mode) {
                        null => _stepModeSelector(kredit),
                        'banco' => _stepBancoSelector(kredit),
                        'tienda' => switch (_currentStep) {
                          0 => _step0EntitySelection(kredit),
                          1 => _stepTiendaDatos(kredit),
                          2 => _stepTiendaFechas(kredit),
                          _ => _stepTiendaConfirmar(kredit),
                        },
                        'tarjeta' => switch (_currentStep) {
                          0 => _stepTarjetaBanco(kredit),
                          1 => _stepTarjetaCupoFinanzas(kredit),
                          2 => _stepTarjetaCiclo(kredit),
                          _ => _stepTarjetaConfirmar(kredit),
                        },
                        'prestamo' => switch (_currentStep) {
                          0 => _stepPrestamoBanco(kredit),
                          1 => _stepPrestamoDataCondiciones(kredit),
                          2 => _stepPrestamoFechas(kredit),
                          _ => _stepPrestamoConfirmar(kredit),
                        },
                        _ => _stepModeSelector(kredit),
                      };
                      return ListView.builder(
                        key: ValueKey('${_mode}_$_currentStep'),
                        padding: const EdgeInsets.all(KreditSpacing.card),
                        // Pre-build items 300px below the viewport so they are
                        // ready before the user scrolls to them.
                        cacheExtent: 300,
                        itemCount: stepItems.length,
                        itemBuilder: (_, i) => stepItems[i],
                      );
                    }),
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
    // AnimatedSize absorbs the height jump when controls appear/disappear so
    // the AnimatedSwitcher above isn't interrupted by a layout change.
    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      child: _mode == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : _previousStep,
                      child: Text(_currentStep == 0 ? '← Cambiar tipo' : 'Atrás'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // flex:1 → same width as the back button (equal halves).
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving
                          ? null
                          : (_mode == 'banco' || _currentStep < _lastStep
                              ? _nextStep
                              : _save),
                      child: Text(
                        _saving
                            ? 'Guardando...'
                            : (_mode == 'banco' || _currentStep < _lastStep
                                ? 'Siguiente'
                                : _saveLabel),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String get _saveLabel => switch (_mode) {
    'tienda' => 'Registrar compra',
    'tarjeta' => 'Registrar tarjeta',
    'prestamo' => 'Registrar préstamo',
    _ => 'Registrar Crédito',
  };

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
        style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
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
            fontSize: KreditTextSize.body,
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
        onTap: () => _showNewEntitySheet(kredit, forcedType: EntityType.store),
      ),
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
        style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
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
        style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
      ),
      const SizedBox(height: 12),
      if (_mode == 'tienda') ...[
        StatefulBuilder(
          builder: (context, setLocal) {
            final credit = _buildPreviewCredit();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (credit != null) ...[
                  const Text(
                    'VISTA PREVIA DE VOUCHER',
                    style: TextStyle(fontSize: KreditTextSize.body, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 8),
                  RepaintBoundary(child: WalletCard(credit: credit, previewPattern: _selectedVoucherPattern)),
                  const SizedBox(height: 16),
                ],
                Text(
                  'DISEÑO DE VOUCHER',
                  style: TextStyle(
                    fontSize: KreditTextSize.body,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: kredit.textTertiary,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showVoucherPatternPickerSheet(
                        context,
                        current: _selectedVoucherPattern,
                        onSelected: (p) {
                          setState(() => _selectedVoucherPattern = p);
                          setLocal(() {});
                        },
                      );
                    },
                    icon: const Icon(Icons.style_outlined, size: KreditIconSize.small),
                    label: Text(_selectedVoucherPattern.label),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ],
      Text(
        'DETALLES DEL CRÉDITO',
        style: TextStyle(
          fontSize: KreditTextSize.body,
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
        final cutoffDay = _mode == 'tarjeta' ? _cutoffDayInt : (int.tryParse(_cutoffDayCtrl.text) ?? 15);
        final paymentDueDay = 0;
        final paymentDueOffsetDays = _mode == 'tarjeta' ? _tarjetaPaymentOffsetDays : (int.tryParse(_paymentOffsetCtrl.text) ?? 20);
        final interestRate = double.tryParse(_interestCtrl.text.replaceAll(',', '.')) ?? 0;
        final managementFee = double.tryParse(CurrencyInputFormatter.unformat(_managementFeeCtrl.text)) ?? 0;
        return CardCredit(
          id: 'preview',
          name: name,
          lender: lender,
          color: null,
          notes: _notesCtrl.text.trim(),
          creditLimit: creditLimit,
          currentBalance: currentBalance,
          cutoffDay: cutoffDay,
          paymentDueOffsetDays: paymentDueOffsetDays,
          paymentDueDay: paymentDueDay,
          oneInstallmentInterestPolicy: _oneInstallmentInterestPolicy,
          interestRate: interestRate,
          interestRateType: _interestRateType,
          managementFee: managementFee,
          managementFeeFrequency: _managementFeeFrequency,
          cardDesign: _selectedCardDesign?.name,
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
        color: null,
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
        quotaId: _mode == 'tienda' ? 'preview-quota' : (_selectedEntityId != null && _selectedEntityId != 'none') ? 'preview-quota' : null,
        interestUnknown: _interestUnknown,
        earlyPaymentWaivesInterest: _earlyPaymentWaivesInterest,
        cardDesign: null,
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
  List<Widget> _loanFieldsCore({bool hideSwitch = false}) {
    return [
      const SizedBox(height: 12),
      KreditSectionCard(
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
                  onTap: () => _selectAll(_amountCtrl),
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
                  onTap: () => _selectAll(_installmentsCtrl),
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
          if (!hideSwitch)
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
                  fontSize: KreditTextSize.body,
                  color: Theme.of(context).extension<KreditColors>()!.textTertiary,
                ),
              ),
            )
          else ...[
            TextFormField(
              controller: _interestCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onTap: () => _selectAll(_interestCtrl),
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
            _eduHint(
              text: '¿Dónde encuentro la tasa?',
              detail: 'Búscala en tu contrato de compra, en el extracto de la tienda, o en la app/web del almacén. Suele aparecer como "tasa de interés mensual" o "EA". Si no la tienes, activa "Tasa desconocida" en Opciones.',
              icon: Icons.search_outlined,
            ),
          ],
          if (!hideSwitch)
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
      KreditSectionCard(
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
            onTap: () => _selectAll(_paidInstallmentsCtrl),
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

  // Paso 3 (tarjeta): costo de la tarjeta + notas — separado del cupo/corte
  // para no apilar 3 tarjetas de sección en una sola pantalla.
  List<Widget> _cardFieldsExtra() {
    return [
      const SizedBox(height: 12),
      KreditSectionCard(
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
                      onTap: () => _selectAll(_interestCtrl),
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
                  keyboardType: TextInputType.number,
                  inputFormatters: const [CurrencyInputFormatter()],
                  onTap: () => _selectAll(_managementFeeCtrl),
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

  // ─── Selector de modo ────────────────────────────────────────────────────

  List<Widget> _stepModeSelector(KreditColors kredit) {
    return [
      Text(
        '¿Qué quieres registrar?',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: KreditTextSize.body, color: kredit.textPrimary),
      ),
      const SizedBox(height: 6),
      Text(
        'Elige el tipo de crédito que vas a agregar.',
        style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
      ),
      const SizedBox(height: 20),
      _ModeCard(
        icon: Icons.store_outlined,
        title: 'Cupo de tienda',
        subtitle: 'Totto, Lili Pink, Éxito, Alkosto...',
        onTap: () => _setMode('tienda'),
        kredit: kredit,
      ),
      const SizedBox(height: 12),
      _ModeCard(
        icon: Icons.account_balance_outlined,
        title: 'Banco',
        subtitle: 'Tarjeta de crédito o avance / préstamo',
        onTap: () => _setMode('banco'),
        kredit: kredit,
      ),
    ];
  }

  List<Widget> _stepBancoSelector(KreditColors kredit) {
    return [
      Text(
        '¿Con qué banco?',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: KreditTextSize.body, color: kredit.textPrimary),
      ),
      const SizedBox(height: 4),
      Text(
        'Selecciona el banco y el tipo de producto.',
        style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
      ),
      const SizedBox(height: 20),
      KreditSectionCard(
        label: 'BANCO Y PRODUCTO',
        icon: Icons.account_balance_outlined,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedLenderPreset,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Banco'),
            items: _presetLenders
                .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                .toList(),
            onChanged: (val) {
              if (val == null) return;
              setState(() {
                _lenderCtrl.text = val;
                _selectedLenderPreset = val;
                _cutoffDayTouched = false;
                _paymentOffsetTouched = false;
                _oneInstallmentInterestPolicy = null;
              });
              _applyEntityTemplate();
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Tipo de producto',
            style: TextStyle(fontSize: KreditTextSize.body, fontWeight: FontWeight.w600, color: kredit.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SubTypeChip(
                  label: 'Tarjeta de crédito',
                  icon: Icons.credit_card_outlined,
                  selected: _bancoSubType == 'tarjeta',
                  onTap: () => setState(() => _bancoSubType = 'tarjeta'),
                  kredit: kredit,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IgnorePointer(
                      child: Opacity(
                        opacity: 0.45,
                        child: _SubTypeChip(
                          label: 'Avance / Préstamo',
                          icon: Icons.attach_money_outlined,
                          selected: false,
                          onTap: () {},
                          kredit: kredit,
                        ),
                      ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade700,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Próximamente',
                          style: TextStyle(
                            fontSize: KreditTextSize.caption,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 12),
      KreditSectionCard(
        label: 'PERSONALIZAR',
        icon: Icons.edit_outlined,
        children: [
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre personalizado del crédito (Opcional)',
              hintText: 'Ej: La de viajes, Libre inversión...',
            ),
          ),
        ],
      ),
    ];
  }

  Widget _eduHint({
    required String text,
    String? detail,
    IconData icon = Icons.lightbulb_outline,
  }) {
    if (detail == null) {
      return Builder(builder: (ctx) {
        final kredit = Theme.of(ctx).extension<KreditColors>()!;
        final accent = Theme.of(ctx).colorScheme.primary;
        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: 0.15)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: KreditIconSize.small, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textSecondary, height: 1.45),
                ),
              ),
            ],
          ),
        );
      });
    }
    return _EduHintExpansion(text: text, detail: detail, icon: icon);
  }

  Widget _heroStatCol(KreditColors kredit, String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: KreditTextSize.caption,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: kredit.textTertiary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: KreditTextSize.body,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _stepTiendaDatos(KreditColors kredit) {
    return [
      Builder(builder: (ctx) {
        final entityName = _lenderCtrl.text.trim();
        final title = entityName.isNotEmpty ? 'Tu compra en $entityName' : 'Datos de la compra';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: KreditTextSize.heading),
            ),
            const SizedBox(height: 4),
            Text(
              'Ingresa el monto, cuotas y condiciones del crédito.',
              style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
            ),
          ],
        );
      }),
      const SizedBox(height: 12),
      KreditSectionCard(
        label: 'NOMBRE DE LA COMPRA',
        icon: Icons.label_outline,
        children: [
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre (opcional)',
              hintText: 'Ej: Celular, Bolso viaje, Ropa niños...',
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Builder(builder: (ctx) {
        final accent = Theme.of(ctx).colorScheme.primary;
        final kredit2 = Theme.of(ctx).extension<KreditColors>()!;
        final amount = double.tryParse(CurrencyInputFormatter.unformat(_amountCtrl.text));
        final inst = int.tryParse(_installmentsCtrl.text);
        final cuota = double.tryParse(CurrencyInputFormatter.unformat(_quotaCtrl.text));
        if (amount == null || amount <= 0) return const SizedBox(height: 16);
        final totalToPay = cuota != null && inst != null && cuota > 0 && inst > 0 ? cuota * inst : null;
        final totalInterest = totalToPay != null ? (totalToPay - amount).clamp(0.0, double.infinity) : null;
        final capitalPct = totalToPay != null && totalToPay > 0 ? (amount / totalToPay).clamp(0.0, 1.0) : null;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VALOR FINANCIADO',
                style: TextStyle(
                  fontSize: KreditTextSize.caption,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                  color: accent.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatCOP(amount),
                style: TextStyle(
                  fontSize: KreditTextSize.hero,
                  fontWeight: FontWeight.w800,
                  color: accent,
                  height: 1.1,
                ),
              ),
              if (cuota != null && cuota > 0 && inst != null && inst > 0 && totalToPay != null) ...[
                const SizedBox(height: 12),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      _heroStatCol(kredit2, 'CUOTA', formatCOP(cuota), accent),
                      VerticalDivider(color: kredit2.borderCard, width: 24),
                      _heroStatCol(kredit2, 'CUOTAS', '$inst', kredit2.textSecondary),
                      VerticalDivider(color: kredit2.borderCard, width: 24),
                      _heroStatCol(kredit2, 'TOTAL', formatCOP(totalToPay), kredit2.textSecondary),
                    ],
                  ),
                ),
                if (totalInterest != null && totalInterest > 0 && capitalPct != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(
                      children: [
                        Container(height: 6, color: kredit2.borderCard),
                        FractionallySizedBox(
                          widthFactor: capitalPct,
                          child: Container(height: 6, color: accent),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        'Capital ${(capitalPct * 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: KreditTextSize.caption, color: accent, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text(
                        'Interés ${((1 - capitalPct) * 100).toStringAsFixed(0)}%  ·  ${formatCOP(totalInterest)}',
                        style: TextStyle(fontSize: KreditTextSize.caption, color: Colors.orange.shade400, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ] else ...[
                const SizedBox(height: 6),
                Text(
                  'Ingresa cuotas y valor de cuota para ver el resumen',
                  style: TextStyle(fontSize: KreditTextSize.body, color: kredit2.textTertiary),
                ),
              ],
            ],
          ),
        );
      }),
      ..._loanFieldsCore(hideSwitch: true),
      const SizedBox(height: 8),
      KreditSectionCard(
        label: 'OPCIONES',
        icon: Icons.tune_outlined,
        children: [
          _InterestUnknownRow(
            interestUnknown: _interestUnknown,
            onChanged: (v) => setState(() => _interestUnknown = v),
          ),
          if (!_interestUnknown) ...[
            const SizedBox(height: 8),
            _EarlyPaymentRow(
              earlyPaymentWaivesInterest: _earlyPaymentWaivesInterest,
              onChanged: (v) => setState(() => _earlyPaymentWaivesInterest = v),
            ),
          ],
        ],
      ),
    ];
  }

  List<Widget> _stepTiendaFechas(KreditColors kredit) {
    return [
      const Text(
        'Fecha y frecuencia',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: KreditTextSize.heading),
      ),
      const SizedBox(height: 4),
      Text(
        'Configura cuándo y con qué frecuencia pagas.',
        style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
      ),
      const SizedBox(height: 12),
      KreditSectionCard(
        label: 'FRECUENCIA DE PAGO',
        icon: Icons.repeat_outlined,
        children: [
          Text(
            '¿Cada cuánto vence tu cuota?',
            style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textSecondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final entry in [
                (CreditFrequency.monthly, 'Mensual', Icons.calendar_month_outlined),
                (CreditFrequency.biweekly, 'Quincenal', Icons.date_range_outlined),
                (CreditFrequency.weekly, 'Semanal', Icons.view_week_outlined),
              ]) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _frequency = entry.$1);
                      _recalcSuggestedQuota();
                    },
                    child: Builder(builder: (ctx) {
                      final accent = Theme.of(ctx).colorScheme.primary;
                      final selected = _frequency == entry.$1;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: selected ? accent.withValues(alpha: 0.12) : Colors.transparent,
                          border: Border.all(
                            color: selected ? accent : kredit.borderCard,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(entry.$3, size: KreditIconSize.small, color: selected ? accent : kredit.textTertiary),
                            const SizedBox(height: 4),
                            Text(
                              entry.$2,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: KreditTextSize.body,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                color: selected ? accent : kredit.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                if (entry.$1 != CreditFrequency.weekly) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
      const SizedBox(height: 12),
      KreditSectionCard(
        label: 'PRIMER PAGO',
        icon: Icons.event_outlined,
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
            'La fecha del primer vencimiento — la ves en tu contrato o primer recibo.',
            style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
          ),
          const SizedBox(height: 8),
          Builder(builder: (ctx) {
            final kredit2 = Theme.of(ctx).extension<KreditColors>()!;
            if (_startDate != null) return const SizedBox.shrink();
            return GestureDetector(
              onTap: () => setState(() => _startDate = DateTime.now()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  border: Border.all(color: kredit2.borderCard),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.today_outlined, size: KreditIconSize.small, color: kredit2.textTertiary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No recuerdo la fecha — usar fecha de hoy',
                        style: TextStyle(fontSize: KreditTextSize.body, color: kredit2.textSecondary),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: KreditIconSize.micro, color: kredit2.textTertiary),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          Divider(height: 1, color: kredit.borderCard.withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _paidInstallmentsCtrl,
            keyboardType: TextInputType.number,
            onTap: () => _selectAll(_paidInstallmentsCtrl),
            decoration: const InputDecoration(
              labelText: '¿Ya venías pagando? (opcional)',
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
      const SizedBox(height: 12),
      Builder(builder: (context) {
        final accent = Theme.of(context).colorScheme.primary;
        final inst = int.tryParse(_installmentsCtrl.text) ?? 0;
        final cuota = double.tryParse(CurrencyInputFormatter.unformat(_quotaCtrl.text)) ?? 0;
        if (_startDate == null || inst <= 0 || cuota <= 0) return const SizedBox.shrink();
        final dates = <DateTime>[];
        DateTime current = _startDate!;
        for (int i = 0; i < inst && i < 3; i++) {
          dates.add(current);
          current = DateTime(current.year, current.month + 1, current.day);
        }
        const monthsEs = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
        String fmt(DateTime d) => '${d.day} ${monthsEs[d.month - 1]} ${d.year}';
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kredit.borderCard),
            color: kredit.bgCard,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: accent.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    Icon(Icons.event_outlined, size: KreditIconSize.small, color: accent),
                    const SizedBox(width: 8),
                    Text(
                      'Primeros pagos · $inst cuotas en total',
                      style: TextStyle(fontSize: KreditTextSize.body, fontWeight: FontWeight.w700, color: accent),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    for (int i = 0; i < dates.length; i++) ...[
                      Row(
                        children: [
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == 0 ? accent : accent.withValues(alpha: 0.15),
                            ),
                            alignment: Alignment.center,
                            child: Text('${i + 1}',
                                style: TextStyle(
                                  fontSize: KreditTextSize.body,
                                  fontWeight: FontWeight.w700,
                                  color: i == 0 ? Colors.white : accent,
                                )),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              fmt(dates[i]),
                              style: TextStyle(fontSize: KreditTextSize.body, fontWeight: FontWeight.w600, color: kredit.textPrimary),
                            ),
                          ),
                          Text(
                            formatCOP(cuota),
                            style: TextStyle(fontSize: KreditTextSize.body, fontWeight: FontWeight.w700, color: kredit.textSecondary),
                          ),
                        ],
                      ),
                      if (i < dates.length - 1 || inst > 3)
                        Padding(
                          padding: const EdgeInsets.only(left: 14),
                          child: Container(width: 1, height: 16, color: kredit.borderCard),
                        ),
                    ],
                    if (inst > 3) ...[
                      Row(
                        children: [
                          Container(
                            width: 28,
                            alignment: Alignment.center,
                            child: Text('···', style: TextStyle(color: kredit.textTertiary, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 12),
                          Text('${inst - 3} cuotas más', style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    ];
  }

  List<Widget> _stepTiendaConfirmar(KreditColors kredit) {
    return [
      ..._step4ColorNotesConfirm(kredit),
    ];
  }

  // ─── Tarjeta: steps 0-4 ──────────────────────────────────────────────────

  List<Widget> _stepTarjetaBanco(KreditColors kredit) {
    return [
      Text(
        '¿En qué banco tienes la tarjeta?',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: KreditTextSize.heading, color: kredit.textPrimary),
      ),
      const SizedBox(height: 4),
      Text(
        'Selecciona el banco emisor de tu tarjeta.',
        style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
      ),
      const SizedBox(height: 16),
      KreditSectionCard(
        label: 'BANCO EMISOR',
        icon: Icons.account_balance_outlined,
        children: [
          _BankChipPicker(
            banks: _presetLenders,
            selectedBank: _lenderCtrl.text.trim().isEmpty ? null : _lenderCtrl.text.trim(),
            onSelected: (bank) {
              setState(() {
                _lenderCtrl.text = bank;
                _selectedLenderPreset = bank;
                _cutoffDayTouched = false;
                _paymentOffsetTouched = false;
                _oneInstallmentInterestPolicy = null;
              });
              _applyEntityTemplate();
            },
            kredit: kredit,
          ),
        ],
      ),
      const SizedBox(height: 12),
      KreditSectionCard(
        label: 'PERSONALIZAR',
        icon: Icons.edit_outlined,
        children: [
          TextFormField(
            controller: _lenderCtrl,
            decoration: const InputDecoration(
              labelText: 'Banco (editable)',
              hintText: 'Ej. Bancolombia, Davienda, Falabella...',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre personalizado (opcional)',
              hintText: 'Ej: La de viajes, Tarjeta principal...',
            ),
          ),
        ],
      ),
    ];
  }


  Widget _inlineStat(String label, String value, KreditColors kredit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary)),
        Text(value, style: TextStyle(fontSize: KreditTextSize.heading, fontWeight: FontWeight.w800, color: kredit.textPrimary)),
      ],
    );
  }

  List<Widget> _stepTarjetaCupoFinanzas(KreditColors kredit) {
    final accent = Theme.of(context).colorScheme.primary;
    final limitVal = double.tryParse(CurrencyInputFormatter.unformat(_limitCtrl.text)) ?? 0;
    final balanceVal = double.tryParse(CurrencyInputFormatter.unformat(_balanceCtrl.text)) ?? 0;
    final available = (limitVal - balanceVal).clamp(0.0, double.infinity);
    final usedPct = limitVal > 0 ? (balanceVal / limitVal).clamp(0.0, 1.0) : null;
    final availPct = usedPct != null ? 1.0 - usedPct : null;
    final hasLimit = limitVal > 0;
    final isOverLimit = hasLimit && balanceVal > limitVal;
    final heroColor = isOverLimit
        ? Colors.red.shade400
        : (usedPct != null && usedPct > 0.85 ? Colors.orange.shade400 : accent);
    final rateText = _interestCtrl.text.trim();
    final hasRate = double.tryParse(rateText.replaceAll(',', '.')) != null &&
        (double.tryParse(rateText.replaceAll(',', '.')) ?? 0) > 0;
    final feeVal = double.tryParse(CurrencyInputFormatter.unformat(_managementFeeCtrl.text)) ?? 0;
    final hasFee = feeVal > 0;

    return [
      // ── Título ────────────────────────────────────────────────────────────
      Builder(builder: (ctx) {
        final bankName = _lenderCtrl.text.trim();
        final title = bankName.isNotEmpty ? 'Cupo y finanzas en $bankName' : 'Cupo y finanzas';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: KreditTextSize.heading)),
            const SizedBox(height: 4),
            Text(
              'Todos los campos son opcionales — completa lo que conozcas.',
              style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
            ),
          ],
        );
      }),
      const SizedBox(height: 16),

      // ── Hero: aparece solo cuando hay datos ───────────────────────────────
      if (hasLimit || balanceVal > 0) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.18)),
          ),
          child: hasLimit && balanceVal > 0
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('DISPONIBLE',
                                  style: TextStyle(fontSize: KreditTextSize.caption, fontWeight: FontWeight.w600,
                                      letterSpacing: 1.1, color: accent.withValues(alpha: 0.7))),
                              const SizedBox(height: 2),
                              Text(formatCOP(available),
                                  style: TextStyle(fontSize: KreditTextSize.hero, fontWeight: FontWeight.w800,
                                      color: heroColor, height: 1.0),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        Text('${((availPct ?? 0) * 100).toStringAsFixed(0)}% libre',
                            style: TextStyle(fontSize: KreditTextSize.body, fontWeight: FontWeight.w700, color: heroColor)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(children: [
                        Container(height: 5, color: kredit.borderCard),
                        FractionallySizedBox(
                          widthFactor: (availPct ?? 0.0).clamp(0.0, 1.0),
                          child: Container(height: 5, color: heroColor),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _heroStatCol(kredit, 'DEUDA', formatCOP(balanceVal),
                            isOverLimit ? Colors.red.shade400 : kredit.textSecondary),
                        VerticalDivider(color: kredit.borderCard, width: 20),
                        _heroStatCol(kredit, 'CUPO TOTAL', formatCOP(limitVal), kredit.textSecondary),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Icon(hasLimit ? Icons.credit_score_outlined : Icons.warning_amber_rounded,
                        size: KreditIconSize.small,
                        color: hasLimit ? accent : Colors.orange.shade400),
                    const SizedBox(width: 8),
                    Text(
                      hasLimit ? 'Cupo: ${formatCOP(limitVal)} — sin deuda registrada' : 'Deuda: ${formatCOP(balanceVal)} — cupo no especificado',
                      style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
      ],

      // ── Campos cupo y deuda (sin card wrapper) ────────────────────────────
      KreditSectionCard(
        label: 'CUPO Y DEUDA',
        icon: Icons.credit_card_outlined,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _limitCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [CurrencyInputFormatter()],
                  onTap: () => _selectAll(_limitCtrl),
                  decoration: const InputDecoration(labelText: 'Cupo aprobado', hintText: 'Opcional'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _balanceCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [CurrencyInputFormatter()],
                  onTap: () => _selectAll(_balanceCtrl),
                  decoration: const InputDecoration(labelText: 'Deuda actual', hintText: '0'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          // ── Deuda inicial inline (solo si hay saldo) ──────────────────
          if (balanceVal > 0) ...[
            const SizedBox(height: 14),
            Divider(color: kredit.borderCard, height: 1),
            const SizedBox(height: 14),
            Text('Detalle de la deuda inicial',
                style: TextStyle(fontSize: KreditTextSize.body, fontWeight: FontWeight.w600, color: kredit.textSecondary)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cardInitInstCtrl,
                    keyboardType: TextInputType.number,
                    onTap: () => _selectAll(_cardInitInstCtrl),
                    decoration: const InputDecoration(
                      labelText: 'Total cuotas',
                      hintText: 'Vacío = rotativa',
                      suffixText: 'cuotas',
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final n = int.tryParse(v.trim());
                      if (n == null || n < 1) return 'Número inválido';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cardPaidInstCtrl,
                    keyboardType: TextInputType.number,
                    onTap: () => _selectAll(_cardPaidInstCtrl),
                    decoration: const InputDecoration(
                      labelText: 'Ya pagadas',
                      hintText: 'Ej. 3',
                      suffixText: 'pagadas',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final paid = int.tryParse(v.trim());
                      if (paid == null || paid < 0) return 'Número inválido';
                      final total = int.tryParse(_cardInitInstCtrl.text.trim());
                      if (total != null && paid > total) return 'Supera el total';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: _pickStartDate,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Inicio de la deuda',
                  hintText: 'Hoy si no lo recuerdas',
                  suffixIcon: Icon(Icons.calendar_month_outlined),
                  isDense: true,
                ),
                child: Text(
                  _startDate != null
                      ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                      : 'Hoy (por defecto)',
                  style: TextStyle(fontSize: KreditTextSize.body,
                      color: _startDate != null ? null : kredit.textTertiary),
                ),
              ),
            ),
          ],
        ],
      ),

      // ── Condiciones: un solo card compacto ────────────────────────────────
      const SizedBox(height: 12),
      KreditSectionCard(
        label: 'CONDICIONES',
        icon: Icons.tune_outlined,
        children: [
          // Tasa + tipo lado a lado
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _interestCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Tasa de interés',
                    hintText: 'Opcional',
                    suffixText: '%',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InterestRateTypeField(
                  value: _interestRateType,
                  onChanged: (v) => setState(() => _interestRateType = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: kredit.borderCard, height: 1),
          const SizedBox(height: 12),
          // 1 cuota sin interés — label + 3 chips en fila
          Row(
            children: [
              Expanded(
                child: Text('Sin interés a 1 cuota',
                    style: TextStyle(fontSize: KreditTextSize.body, fontWeight: FontWeight.w600, color: kredit.textPrimary)),
              ),
              const SizedBox(width: 8),
              for (final option in [
                (label: 'Sí', value: true as bool?),
                (label: 'No', value: false as bool?),
                (label: 'No sé', value: null as bool?),
              ]) ...[
                GestureDetector(
                  onTap: () => setState(() => _oneInstallmentInterestPolicy = option.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    margin: const EdgeInsets.only(left: 6),
                    decoration: BoxDecoration(
                      color: _oneInstallmentInterestPolicy == option.value
                          ? accent.withValues(alpha: 0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _oneInstallmentInterestPolicy == option.value
                            ? accent : kredit.borderCard,
                        width: _oneInstallmentInterestPolicy == option.value ? 1.5 : 1,
                      ),
                    ),
                    child: Text(option.label,
                        style: TextStyle(
                          fontSize: KreditTextSize.body,
                          fontWeight: FontWeight.w600,
                          color: _oneInstallmentInterestPolicy == option.value
                              ? accent : kredit.textTertiary,
                        )),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: kredit.borderCard, height: 1),
          const SizedBox(height: 12),
          // Cuota de manejo — campo directo opcional
          TextFormField(
            controller: _managementFeeCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: const [CurrencyInputFormatter()],
            onTap: () => _selectAll(_managementFeeCtrl),
            decoration: const InputDecoration(
              labelText: 'Cuota de manejo',
              hintText: '0 si no aplica',
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (hasFee) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              isExpanded: true,
              style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textPrimary),
              initialValue: _managementFeeFrequency,
              decoration: const InputDecoration(labelText: 'Frecuencia de cobro'),
              items: const [
                DropdownMenuItem(value: ManagementFeeFrequency.monthly, child: Text('Mensual')),
                DropdownMenuItem(value: ManagementFeeFrequency.annual, child: Text('Anual')),
              ],
              onChanged: (v) => setState(() => _managementFeeFrequency = v ?? ManagementFeeFrequency.monthly),
            ),
          ],
        ],
      ),
      const SizedBox(height: 12),
      KreditSectionCard(
        label: 'NOMBRE DE LA COMPRA',
        icon: Icons.label_outline,
        children: [
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre (opcional)',
              hintText: 'Ej: La de viajes, Tarjeta principal...',
            ),
          ),
        ],
      ),
    ];
  }

  // ── Ciclo timeline visual ────────────────────────────────────────────────
  Widget _buildCicloTimelineCard(KreditColors kredit, Color accent, int dueDay) {
    final wraps = dueDay <= _cutoffDayInt;
    // Colors for each segment
    final spendColor = const Color(0xFF4CAF93); // teal/green: spending period
    final payColor   = accent;                   // accent: payment window

    // Fractions along the 1-31 axis
    double frac(int day) => (day - 1) / 30.0;
    final cutFrac  = frac(_cutoffDayInt);
    final dueFrac  = frac(dueDay);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kredit.borderCard),
        color: kredit.bgCard,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header strip ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: accent.withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(Icons.timeline_rounded, size: KreditIconSize.small, color: accent),
                const SizedBox(width: 8),
                Text('Así funciona tu ciclo de facturación',
                    style: TextStyle(fontSize: KreditTextSize.body, fontWeight: FontWeight.w700, color: accent)),
              ],
            ),
          ),
          // ── Big numbers ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                _cycleStat('DÍA $_cutoffDayInt', 'CORTE', spendColor, kredit),
                Expanded(
                  child: Center(
                    child: Column(
                      children: [
                        Text('$_tarjetaPaymentOffsetDays días',
                            style: TextStyle(fontSize: KreditTextSize.body, fontWeight: FontWeight.w700, color: kredit.textSecondary)),
                        Text('de plazo', style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary)),
                      ],
                    ),
                  ),
                ),
                _cycleStat('DÍA $dueDay', wraps ? 'LÍMITE (mes sig.)' : 'LÍMITE DE PAGO', payColor, kredit, alignEnd: true),
              ],
            ),
          ),
          // ── Timeline bar ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: LayoutBuilder(builder: (ctx, box) {
              final w = box.maxWidth;
              final cutX  = w * cutFrac;
              final dueX  = w * dueFrac;
              const barH      = 10.0;
              const labelH    = 14.0; // text line height above the dashed bar
              const labelGap  = 4.0;  // gap between label and dashed bar
              const nextH     = 5.0;  // height of the dashed "next cycle" bar
              const nextGap   = 8.0;  // gap between dashed bar and main bar
              const tickH     = labelH + labelGap + nextH + nextGap; // total above main bar
              const dotR      = 5.5;
              const totalH    = tickH + barH + 68.0;

              return SizedBox(
                height: totalH,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ── Próximo ciclo: label arriba, barra punteada abajo ─
                    // Texto visible encima
                    Positioned(
                      top: 0,
                      left: (cutX + 4).clamp(0, w - 130),
                      child: Text(
                        'Nuevo extracto →',
                        style: TextStyle(
                          fontSize: KreditTextSize.caption,
                          fontWeight: FontWeight.w600,
                          color: spendColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    // Barra punteada debajo del label
                    Positioned(
                      top: labelH + labelGap,
                      left: cutX,
                      right: 0,
                      child: Row(
                        children: List.generate(
                          30,
                          (i) => Expanded(
                            child: Container(
                              height: nextH,
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              decoration: BoxDecoration(
                                color: spendColor.withValues(alpha: i == 0 ? 0.85 : (0.6 - i * 0.015).clamp(0.1, 1.0)),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // ── Full bar background ──────────────────────────────
                    Positioned(
                      top: tickH,
                      left: 0,
                      right: 0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Container(height: barH, color: kredit.borderCard),
                      ),
                    ),
                    // ── Spending segment (1 → corte) ─────────────────────
                    Positioned(
                      top: tickH,
                      left: 0,
                      width: cutX.clamp(0, w),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), bottomLeft: Radius.circular(6)),
                        child: Container(height: barH, color: spendColor.withValues(alpha: 0.75)),
                      ),
                    ),
                    // ── Payment segment (corte → límite, no-wrap) ────────
                    if (!wraps && dueX > cutX)
                      Positioned(
                        top: tickH,
                        left: cutX,
                        width: (dueX - cutX).clamp(0, w - cutX),
                        child: Container(height: barH, color: payColor.withValues(alpha: 0.6)),
                      ),
                    // ── Wrap: payment segment right side (corte → 31) ────
                    if (wraps)
                      Positioned(
                        top: tickH,
                        left: cutX,
                        right: 0,
                        child: Container(height: barH, color: payColor.withValues(alpha: 0.6)),
                      ),
                    // ── Wrap: payment segment left side (1 → límite) ─────
                    if (wraps && dueX > 0)
                      Positioned(
                        top: tickH,
                        left: 0,
                        width: dueX.clamp(0, w),
                        child: Container(height: barH, color: payColor.withValues(alpha: 0.35)),
                      ),

                    // ── Tick: corte ──────────────────────────────────────
                    Positioned(
                      top: 0,
                      left: cutX - 1,
                      child: Container(width: 2, height: tickH + barH + 4, color: spendColor),
                    ),
                    Positioned(
                      top: tickH - dotR + barH / 2,
                      left: cutX - dotR,
                      child: Container(
                        width: dotR * 2, height: dotR * 2,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: spendColor,
                            border: Border.all(color: kredit.bgCard, width: 2)),
                      ),
                    ),
                    // ── Tick: límite ─────────────────────────────────────
                    Positioned(
                      top: 0,
                      left: dueX - 1,
                      child: Container(width: 2, height: tickH + barH + 4, color: payColor),
                    ),
                    Positioned(
                      top: tickH - dotR + barH / 2,
                      left: dueX - dotR,
                      child: Container(
                        width: dotR * 2, height: dotR * 2,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: payColor,
                            border: Border.all(color: kredit.bgCard, width: 2)),
                      ),
                    ),

                    // ── Label: corte ─────────────────────────────────────
                    Positioned(
                      top: tickH + barH + 8,
                      left: (cutX - 26).clamp(0, w - 52),
                      width: 52,
                      child: Text('Corte\nDía $_cutoffDayInt',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: KreditTextSize.caption, fontWeight: FontWeight.w600, color: spendColor, height: 1.3)),
                    ),
                    // ── Label: límite ─────────────────────────────────────
                    Positioned(
                      top: tickH + barH + 8,
                      left: (dueX - 26).clamp(0, w - 52),
                      width: 52,
                      child: Text(wraps ? 'Límite\n(mes sig.)' : 'Límite\nDía $dueDay',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: KreditTextSize.caption, fontWeight: FontWeight.w600, color: payColor, height: 1.3)),
                    ),
                    // ── Day-1 label ──────────────────────────────────────
                    Positioned(
                      top: tickH + barH + 8,
                      left: 0,
                      child: Text('1', style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary)),
                    ),
                    // ── Day-31 label ─────────────────────────────────────
                    Positioned(
                      top: tickH + barH + 8,
                      right: 0,
                      child: Text('31', style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary)),
                    ),
                    // ── HOY marker ───────────────────────────────────────
                    Builder(builder: (ctx) {
                      final today = DateTime.now();
                      final todayFrac = (today.day - 1) / 30.0;
                      final todayX = w * todayFrac;
                      final todayColor = Theme.of(ctx).colorScheme.onSurface;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Línea vertical
                          Positioned(
                            top: tickH - 2,
                            left: todayX - 1,
                            child: Container(
                              width: 2,
                              height: barH + 4,
                              color: todayColor.withValues(alpha: 0.85),
                            ),
                          ),
                          // Dot
                          Positioned(
                            top: tickH - dotR + barH / 2,
                            left: todayX - dotR,
                            child: Container(
                              width: dotR * 2,
                              height: dotR * 2,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: todayColor,
                                border: Border.all(color: kredit.bgCard, width: 2),
                              ),
                            ),
                          ),
                          // Label "Hoy · Día X"
                          Positioned(
                            top: tickH + barH + 8,
                            left: (todayX - 20).clamp(0, w - 44),
                            width: 44,
                            child: Text(
                              'Hoy\nDía ${today.day}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: KreditTextSize.caption,
                                fontWeight: FontWeight.w700,
                                color: todayColor,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              );
            }),
          ),
          // ── Legend chips ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _legendChip(spendColor, 'Período de compras', kredit),
                _legendChip(payColor, 'Plazo de pago', kredit),
                _legendChip(spendColor.withValues(alpha: 0.45), 'Próximo extracto', kredit),
              ],
            ),
          ),
          // ── Educational explanation ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              children: [
                _cicloExplainRow(
                  icon: Icons.shopping_cart_outlined,
                  color: spendColor,
                  title: 'Período de compras',
                  desc: 'Todo lo que compres desde el día $_cutoffDayInt del mes anterior hasta el día ${_cutoffDayInt > 1 ? _cutoffDayInt - 1 : 31} de este mes se incluye en tu extracto.',
                  kredit: kredit,
                ),
                const SizedBox(height: 10),
                _cicloExplainRow(
                  icon: Icons.receipt_long_outlined,
                  color: spendColor,
                  title: 'Día de corte — día $_cutoffDayInt',
                  desc: 'Cierre del extracto. Tienes hasta las 23:59 de este día para hacer compras y que queden en el extracto actual. A partir del día siguiente, las compras ya van al próximo ciclo.',
                  kredit: kredit,
                ),
                const SizedBox(height: 10),
                _cicloExplainRow(
                  icon: Icons.autorenew_rounded,
                  color: spendColor.withValues(alpha: 0.75),
                  title: '¿Cuándo es el siguiente corte?',
                  desc: 'El ciclo se repite cada mes: el día $_cutoffDayInt de cada mes cierra el extracto (tienes hasta las 23:59 de ese día para que una compra quede en el extracto actual). Las compras del día ${_cutoffDayInt + 1} en adelante ya van al próximo extracto, y tendrás hasta el día $dueDay${wraps ? ' del mes siguiente' : ''} para pagarlo.',
                  kredit: kredit,
                ),
                const SizedBox(height: 10),
                _cicloExplainRow(
                  icon: Icons.hourglass_bottom_rounded,
                  color: payColor,
                  title: 'Plazo de pago — $_tarjetaPaymentOffsetDays días',
                  desc: 'Tienes $_tarjetaPaymentOffsetDays días para pagar tu extracto. Si pagas antes del límite, evitas intereses de mora.',
                  kredit: kredit,
                ),
                const SizedBox(height: 10),
                _cicloExplainRow(
                  icon: Icons.warning_amber_rounded,
                  color: payColor,
                  title: wraps ? 'Fecha límite — día $dueDay (mes siguiente)' : 'Fecha límite — día $dueDay',
                  desc: 'Fecha máxima de pago. Si no pagas antes de esta fecha, se generan intereses de mora y posible reporte negativo.',
                  kredit: kredit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cycleStat(String day, String label, Color color, KreditColors kredit, {bool alignEnd = false}) =>
      Column(
        crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(day, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color, letterSpacing: -1)),
          Text(label, style: TextStyle(fontSize: KreditTextSize.body, fontWeight: FontWeight.w600, color: kredit.textTertiary, letterSpacing: 0.8)),
        ],
      );

  Widget _legendChip(Color color, String label, KreditColors kredit) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textSecondary)),
        ],
      );

  Widget _cicloExplainRow({required IconData icon, required Color color, required String title, required String desc, required KreditColors kredit}) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: KreditIconSize.small, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: KreditTextSize.body, fontWeight: FontWeight.w700, color: kredit.textPrimary)),
                const SizedBox(height: 3),
                Text(desc, style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary, height: 1.45)),
              ],
            ),
          ),
        ],
      );

  List<Widget> _stepTarjetaCiclo(KreditColors kredit) {
    final accent = Theme.of(context).colorScheme.primary;
    final dueDay = ((_cutoffDayInt - 1 + _tarjetaPaymentOffsetDays) % 31) + 1;
    return [
      Text(
        'Ciclo de facturación',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: KreditTextSize.heading, color: kredit.textPrimary),
      ),
      const SizedBox(height: 4),
      Text(
        'Encuentra estos datos en tu extracto bancario.',
        style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
      ),
      const SizedBox(height: 16),
      KreditSectionCard(
        label: 'FECHAS DEL CICLO',
        icon: Icons.calendar_month_outlined,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Día de corte', style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textSecondary)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textPrimary),
                      initialValue: _cutoffDayInt.clamp(1, 31),
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                      items: List.generate(31, (i) => i + 1)
                          .map((d) => DropdownMenuItem(value: d, child: Text('Día $d', style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textPrimary))))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() { _cutoffDayInt = v; _cutoffDayCtrl.text = v.toString(); _cutoffDayTouched = true; });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Días para pagar', style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textSecondary)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textPrimary),
                      initialValue: _tarjetaPaymentOffsetDays.clamp(1, 30),
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                      items: List.generate(30, (i) => i + 1)
                          .map((d) => DropdownMenuItem(value: d, child: Text('$d ${d == 1 ? 'día' : 'días'}', style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textPrimary))))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() { _tarjetaPaymentOffsetDays = v; _paymentOffsetTouched = true; });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Builder(builder: (ctx) {
            final dueDay2 = ((_cutoffDayInt - 1 + _tarjetaPaymentOffsetDays) % 31) + 1;
            final wraps2 = dueDay2 <= _cutoffDayInt;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_available_outlined,
                      size: KreditIconSize.small, color: Theme.of(ctx).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Fecha límite: día $dueDay2${wraps2 ? ' del mes siguiente' : ' del mismo mes'}',
                    style: TextStyle(
                      fontSize: KreditTextSize.body,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(ctx).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          _eduHint(
            text: 'Lo encuentras en tu extracto como "Fecha límite de pago" o "Fecha de pago".',
            icon: Icons.receipt_outlined,
          ),
        ],
      ),
      const SizedBox(height: 16),
      _buildCicloTimelineCard(kredit, accent, dueDay),
      const SizedBox(height: 12),
      KreditSectionCard(
        label: 'NOTAS',
        icon: Icons.sticky_note_2_outlined,
        children: [
          TextFormField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notas (opcional)',
              hintText: 'Condiciones especiales, número de contrato...',
            ),
          ),
        ],
      ),
      if (_entityTemplateNote != null) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kredit.bgCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kredit.borderCard),
          ),
          child: Text(
            _entityTemplateNote!,
            style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textSecondary),
          ),
        ),
      ],
    ];
  }

  List<Widget> _stepTarjetaConfirmar(KreditColors kredit) {
    final lender = _lenderCtrl.text.trim().isEmpty ? '(sin definir)' : _lenderCtrl.text.trim();
    final limitVal = double.tryParse(CurrencyInputFormatter.unformat(_limitCtrl.text)) ?? 0;
    final balanceVal = double.tryParse(CurrencyInputFormatter.unformat(_balanceCtrl.text)) ?? 0;
    final rateVal = double.tryParse(_interestCtrl.text.replaceAll(',', '.')) ?? 0;
    final feeVal = double.tryParse(CurrencyInputFormatter.unformat(_managementFeeCtrl.text)) ?? 0;
    return [
      Text(
        'Confirmar tarjeta',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: KreditTextSize.heading, color: kredit.textPrimary),
      ),
      const SizedBox(height: 12),
      StatefulBuilder(
        builder: (context, setLocal) {
          final previewCredit = _buildPreviewCredit();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (previewCredit != null) ...[
                const Text(
                  'VISTA PREVIA DE TARJETA',
                  style: TextStyle(fontSize: KreditTextSize.body, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                const SizedBox(height: 8),
                RepaintBoundary(child: WalletCard(credit: previewCredit)),
                const SizedBox(height: 16),
              ],
              Text(
                'DISEÑO DE TARJETA',
                style: TextStyle(
                  fontSize: KreditTextSize.body,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: kredit.textTertiary,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final bank = detectBank(lender: lender);
                    final gradient = expandedGradientFor(bank.cssClass, null);
                    showCardDesignPicker(
                      context,
                      current: _selectedCardDesign,
                      c1: gradient.first,
                      c2: gradient[gradient.length ~/ 2],
                      c3: gradient.last,
                      onSelected: (d) {
                        setState(() => _selectedCardDesign = d);
                        setLocal(() {});
                      },
                    );
                  },
                  icon: const Icon(Icons.palette_outlined, size: KreditIconSize.small),
                  label: Text(_selectedCardDesign?.label ?? 'Seleccionar diseño'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
      KreditSectionCard(
        label: 'RESUMEN',
        icon: Icons.summarize_outlined,
        children: [
          _SummaryGrid(items: [
            (label: 'Banco', value: lender),
            if (_nameCtrl.text.trim().isNotEmpty) (label: 'Nombre', value: _nameCtrl.text.trim()),
            if (limitVal > 0) (label: 'Cupo', value: formatCOP(limitVal)),
            (label: 'Deuda actual', value: formatCOP(balanceVal)),
            if (limitVal > 0) (label: 'Disponible', value: formatCOP((limitVal - balanceVal).clamp(0, double.infinity))),
            (label: 'Corte', value: 'Día $_cutoffDayInt'),
            (label: 'Límite de pago', value: '$_tarjetaPaymentOffsetDays días después (día ${((_cutoffDayInt - 1 + _tarjetaPaymentOffsetDays) % 31) + 1})'),
            (label: 'Tasa', value: rateVal > 0 ? '${_interestCtrl.text}% ${const {'effectiveAnnual': 'E.A.', 'effectiveMonthly': 'E.M.', 'nominalMonthly': 'N.M.'}[_interestRateType] ?? _interestRateType}' : 'No especificada'),
            (label: '1 cuota sin interés', value: _oneInstallmentInterestPolicy == null ? 'Sin configurar' : (_oneInstallmentInterestPolicy! ? 'Sí' : 'No')),
            if (feeVal > 0) (label: 'Cuota de manejo', value: '${formatCOP(feeVal)} / $_managementFeeFrequency'),
            if (balanceVal > 0 && _cardInitInstCtrl.text.trim().isNotEmpty)
              (label: 'Cuotas deuda inicial', value: '${_cardInitInstCtrl.text.trim()} cuotas${_cardPaidInstCtrl.text.trim().isNotEmpty ? ' (${_cardPaidInstCtrl.text.trim()} pagadas)' : ''}'),
            if (balanceVal > 0 && _startDate != null)
              (label: 'Inicio de deuda', value: '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'),
          ]),
        ],
      ),
      const SizedBox(height: 12),
    ];
  }

  // ─── Préstamo: steps 0-4 ─────────────────────────────────────────────────

  List<Widget> _stepPrestamoBanco(KreditColors kredit) {
    return [
      Text(
        '¿Dónde tienes el préstamo?',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: KreditTextSize.body, color: kredit.textPrimary),
      ),
      const SizedBox(height: 4),
      Text(
        'Selecciona el banco que te otorgó el préstamo.',
        style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
      ),
      const SizedBox(height: 16),
      KreditSectionCard(
        label: 'ENTIDAD',
        icon: Icons.account_balance_outlined,
        children: [
          _BankChipPicker(
            banks: _presetLenders,
            selectedBank: _lenderCtrl.text.trim().isEmpty ? null : _lenderCtrl.text.trim(),
            onSelected: (bank) => setState(() {
              _lenderCtrl.text = bank;
              _selectedLenderPreset = bank;
            }),
            kredit: kredit,
          ),
        ],
      ),
      const SizedBox(height: 12),
      KreditSectionCard(
        label: 'PERSONALIZAR',
        icon: Icons.edit_outlined,
        children: [
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre personalizado del crédito (Opcional)',
              hintText: 'Ej: Libre inversión, Vehículo...',
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _stepPrestamoDataCondiciones(KreditColors kredit) {
    return [
      Text(
        'Datos y condiciones',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: KreditTextSize.body, color: kredit.textPrimary),
      ),
      const SizedBox(height: 4),
      Text(
        'Monto, cuotas y condiciones del préstamo.',
        style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
      ),
      const SizedBox(height: 16),
      KreditSectionCard(
        label: 'MONTO Y CUOTAS',
        icon: Icons.request_quote_outlined,
        children: _loanFieldsCore(),
      ),
      const SizedBox(height: 12),
      KreditSectionCard(
        label: 'FRECUENCIA Y EXTRAS',
        icon: Icons.tune_outlined,
        children: [
          ..._frequencySelector(kredit),
          const SizedBox(height: 16),
          _EarlyPaymentRow(
            earlyPaymentWaivesInterest: _earlyPaymentWaivesInterest,
            onChanged: (v) => setState(() => _earlyPaymentWaivesInterest = v),
          ),
        ],
      ),
    ];
  }

  List<Widget> _stepPrestamoFechas(KreditColors kredit) {
    return [
      Text(
        'Fechas',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: KreditTextSize.body, color: kredit.textPrimary),
      ),
      const SizedBox(height: 4),
      Text(
        'Indica cuándo fue la primera cuota.',
        style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
      ),
      ..._step3ScheduleAndExtras(kredit),
    ];
  }

  List<Widget> _stepPrestamoConfirmar(KreditColors kredit) {
    return [
      Text(
        'Confirmar préstamo',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: KreditTextSize.body, color: kredit.textPrimary),
      ),
      const SizedBox(height: 12),
      ..._step4ColorNotesConfirm(kredit),
    ];
  }

  // ─── Helpers compartidos ─────────────────────────────────────────────────

  List<Widget> _frequencySelector(KreditColors kredit) {
    return [
      Text('Frecuencia de pago', style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textSecondary)),
      const SizedBox(height: 6),
      Wrap(
        spacing: 8,
        children: [
          for (final freq in [CreditFrequency.monthly, CreditFrequency.biweekly, CreditFrequency.weekly])
            ChoiceChip(
              label: Text(switch (freq) { CreditFrequency.monthly => 'Mensual', CreditFrequency.biweekly => 'Quincenal', _ => 'Semanal' }),
              selected: _frequency == freq,
              onSelected: (_) => setState(() => _frequency = freq),
            ),
        ],
      ),
    ];
  }
}

