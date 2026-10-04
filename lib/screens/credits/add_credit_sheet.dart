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
import '../../widgets/account/voucher_pattern_picker.dart';
import '../../widgets/interest_rate_type_field.dart';
import '../../widgets/kredit_section_card.dart';
import '../../widgets/voucher_pattern.dart';
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
  VoucherPattern _selectedVoucherPattern = VoucherPattern.diagonalLines;
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
    final discard = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) {
        final kredit = Theme.of(ctx).extension<KreditColors>()!;
        return SafeArea(
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
        );
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
        cardDesign: null,
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
    'tarjeta' => 4,
    'prestamo' => 3,
    _ => 4,
  };

  List<String> get _stepTitles => switch (_mode) {
    'tienda' => const ['Entidad', 'Datos compra', 'Fechas', 'Confirmar'],
    'banco' => const ['Banco y tipo'],
    'tarjeta' => const ['Banco', 'Cupo y deuda', 'Condiciones', 'Ciclo de pago', 'Confirmar'],
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
                          1 => _stepTarjetaCupoDeuda(kredit),
                          2 => _stepTarjetaCondiciones(kredit),
                          3 => _stepTarjetaCiclo(kredit),
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
          cardDesign: null,
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

  // Paso 2 (tarjeta): cupo y ciclo de facturación — lo indispensable.
  List<Widget> _cardFieldsCore() {
    return [
      const SizedBox(height: 12),
      KreditSectionCard(
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
                  onTap: () => _selectAll(_limitCtrl),
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
                  onTap: () => _selectAll(_balanceCtrl),
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
      KreditSectionCard(
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
              style: TextStyle(fontSize: KreditTextSize.body, color: Theme.of(context).extension<KreditColors>()!.textTertiary),
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
            value: _selectedLenderPreset,
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
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: KreditTextSize.body, color: kredit.textPrimary),
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
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre personalizado del crédito (Opcional)',
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

  List<Widget> _stepTarjetaCupoDeuda(KreditColors kredit) {
    final accent = Theme.of(context).colorScheme.primary;
    final limitText = _limitCtrl.text.trim();
    final limitVal = double.tryParse(CurrencyInputFormatter.unformat(limitText)) ?? 0;
    final balanceVal = double.tryParse(CurrencyInputFormatter.unformat(_balanceCtrl.text)) ?? 0;
    final available = (limitVal - balanceVal).clamp(0, double.infinity).toDouble();
    final pct = limitVal > 0 ? (balanceVal / limitVal).clamp(0.0, 1.0) : null;
    final hasLimit = limitVal > 0;
    return [
      Text(
        'Cupo y saldo actual',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: KreditTextSize.body, color: kredit.textPrimary),
      ),
      const SizedBox(height: 4),
      Text(
        'El cupo es opcional — puedes dejarlo vacío si no lo conoces.',
        style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
      ),
      const SizedBox(height: 16),
      // ── Visualizador de cupo ──────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero: disponible (el número que más importa) ──────────────
            Text(
              hasLimit ? 'DISPONIBLE' : 'DEUDA ACTUAL',
              style: TextStyle(
                fontSize: KreditTextSize.body,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: kredit.textTertiary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hasLimit ? formatCOP(available) : formatCOP(balanceVal),
              style: TextStyle(
                fontSize: KreditTextSize.hero,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
                color: hasLimit
                    ? (pct != null && pct > 0.85 ? Colors.red.shade400 : accent)
                    : (balanceVal == 0 ? kredit.textTertiary : kredit.textPrimary),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            // ── Barra de utilización ──────────────────────────────────────
            if (pct != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 10,
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: kredit.borderCard,
                    color: pct > 0.85 ? Colors.red.shade400 : accent,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // ── Stats secundarios inline ──────────────────────────────
              Row(
                children: [
                  _inlineStat('Deuda', formatCOP(balanceVal), kredit),
                  Container(
                    width: 1, height: 14,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    color: kredit.borderCard,
                  ),
                  _inlineStat('Cupo total', formatCOP(limitVal), kredit),
                  const Spacer(),
                  Text(
                    '${(pct * 100).round()}% usado',
                    style: TextStyle(
                      fontSize: KreditTextSize.heading,
                      fontWeight: FontWeight.w800,
                      color: pct > 0.85 ? Colors.red.shade400 : kredit.textSecondary,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                hasLimit
                    ? 'Ingresa la deuda para ver el disponible'
                    : 'Ingresa el cupo para ver el disponible',
                style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),
      KreditSectionCard(
        label: 'CUPO DEL CRÉDITO',
        icon: Icons.credit_card_outlined,
        children: [
          TextFormField(
            controller: _limitCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: const [CurrencyInputFormatter()],
            onTap: () => _selectAll(_limitCtrl),
            decoration: const InputDecoration(
              labelText: 'Cupo aprobado (opcional)',
              hintText: 'Ej. 5.000.000',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _balanceCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: const [CurrencyInputFormatter()],
            onTap: () => _selectAll(_balanceCtrl),
            decoration: const InputDecoration(
              labelText: 'Deuda actual',
              hintText: '0 si no tienes deuda',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    ];
  }

  List<Widget> _stepTarjetaCondiciones(KreditColors kredit) {
    final rateText = _interestCtrl.text.trim();
    final hasRate = double.tryParse(rateText.replaceAll(',', '.')) != null &&
        (double.tryParse(rateText.replaceAll(',', '.')) ?? 0) > 0;
    final feeVal = double.tryParse(CurrencyInputFormatter.unformat(_managementFeeCtrl.text)) ?? 0;
    final hasFee = feeVal > 0;
    return [
      Text(
        'Condiciones financieras',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: KreditTextSize.body, color: kredit.textPrimary),
      ),
      const SizedBox(height: 4),
      Text(
        'Todos los campos son opcionales — puedes continuar sin ellos.',
        style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
      ),
      const SizedBox(height: 12),
      KreditSectionCard(
        label: 'TASA DE INTERÉS',
        icon: Icons.percent_outlined,
        children: [
          TextFormField(
            controller: _interestCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Tasa de interés (opcional)',
              hintText: 'Vacío si no la conoces',
              suffixText: '%',
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (hasRate) ...[
            const SizedBox(height: 8),
            InterestRateTypeField(
              value: _interestRateType,
              onChanged: (v) => setState(() => _interestRateType = v),
            ),
          ],
          _eduHint(
            text: '¿Dónde encuentro mi tasa?',
            detail: 'Está en tu extracto bancario, en la app de tu banco, o en la carta de aprobación de la tarjeta. Suele llamarse "Tasa de interés corriente" o "Interés por mora". Puedes dejar este campo vacío si no la conoces.',
            icon: Icons.search_outlined,
          ),
        ],
      ),
      const SizedBox(height: 12),
      KreditSectionCard(
        label: 'COMPRAS A 1 CUOTA',
        icon: Icons.shopping_cart_checkout_outlined,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sin interés si paga a tiempo',
                      style: TextStyle(fontWeight: FontWeight.w600, color: kredit.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _oneInstallmentInterestPolicy == null
                          ? 'Sin configurar — actívalo si aplica'
                          : 'Tu tarjeta ${_oneInstallmentInterestPolicy! ? 'no cobra' : 'sí cobra'} interés en compras a 1 cuota pagadas a tiempo.',
                      style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textSecondary),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _oneInstallmentInterestPolicy ?? false,
                onChanged: (v) => setState(() => _oneInstallmentInterestPolicy = v),
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          _eduHint(
            text: '¿Qué significa "a 1 cuota"?',
            detail: 'Cuando diferidas a 1 cuota y pagas antes del límite, muchas tarjetas no cobran interés. Si tu tarjeta tiene esta condición, activa el switch. Así Kredit calculará correctamente tus cargos.',
            icon: Icons.info_outline,
          ),
        ],
      ),
      const SizedBox(height: 12),
      KreditSectionCard(
        label: 'CUOTA DE MANEJO',
        icon: Icons.receipt_long_outlined,
        children: [
          TextFormField(
            controller: _managementFeeCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: const [CurrencyInputFormatter()],
            onTap: () => _selectAll(_managementFeeCtrl),
            decoration: const InputDecoration(
              labelText: 'Cuota de manejo (opcional)',
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
                  desc: 'Se genera tu estado de cuenta. Tu deuda queda "congelada" y empieza el plazo para pagar. Al mismo tiempo, tus nuevas compras ya empiezan a contar para el próximo extracto.',
                  kredit: kredit,
                ),
                const SizedBox(height: 10),
                _cicloExplainRow(
                  icon: Icons.autorenew_rounded,
                  color: spendColor.withValues(alpha: 0.75),
                  title: '¿Cuándo es el siguiente corte?',
                  desc: 'El ciclo se repite cada mes: el día $_cutoffDayInt de cada mes se genera un nuevo extracto. Las compras que hagas desde el día $_cutoffDayInt de este mes hasta el día $_cutoffDayInt del siguiente mes aparecerán en ese próximo extracto, y tendrás hasta el día $dueDay${wraps ? ' del mes siguiente' : ''} para pagarlo.',
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
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: KreditTextSize.body, color: kredit.textPrimary),
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
                      value: _cutoffDayInt.clamp(1, 31),
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
                      value: _tarjetaPaymentOffsetDays.clamp(1, 30),
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
          Text(
            '→ límite día ${((_cutoffDayInt - 1 + _tarjetaPaymentOffsetDays) % 31) + 1} del mes',
            style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
          ),
          const SizedBox(height: 6),
          _eduHint(
            text: 'Lo encuentras en tu extracto como "Fecha límite de pago" o "Fecha de pago".',
            icon: Icons.receipt_outlined,
          ),
          const SizedBox(height: 12),
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
      const SizedBox(height: 16),
      _buildCicloTimelineCard(kredit, accent, dueDay),
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
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: KreditTextSize.body, color: kredit.textPrimary),
      ),
      const SizedBox(height: 12),
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
            (label: 'Límite de pago', value: '${_tarjetaPaymentOffsetDays} días después (día ${((_cutoffDayInt - 1 + _tarjetaPaymentOffsetDays) % 31) + 1})'),
            (label: 'Tasa', value: rateVal > 0 ? '${_interestCtrl.text}% ${const {'effectiveAnnual': 'E.A.', 'effectiveMonthly': 'E.M.', 'nominalMonthly': 'N.M.'}[_interestRateType] ?? _interestRateType}' : 'No especificada'),
            (label: '1 cuota sin interés', value: _oneInstallmentInterestPolicy == null ? 'Sin configurar' : (_oneInstallmentInterestPolicy! ? 'Sí' : 'No')),
            if (feeVal > 0) (label: 'Cuota de manejo', value: '${formatCOP(feeVal)} / $_managementFeeFrequency'),
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

// ─── Widgets nuevos ─────────────────────────────────────────────────────────

class _SubTypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final KreditColors kredit;

  const _SubTypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.kredit,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.12) : kredit.bgCard,
          border: Border.all(
            color: selected ? accent : kredit.borderCard,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: KreditIconSize.medium, color: selected ? accent : kredit.textSecondary),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: KreditTextSize.body,
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

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final KreditColors kredit;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.kredit,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kredit.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kredit.borderCard),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: KreditIconSize.medium),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: KreditTextSize.heading, fontWeight: FontWeight.w700, color: kredit.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: kredit.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _BankChipPicker extends StatelessWidget {
  final List<String> banks;
  final String? selectedBank;
  final ValueChanged<String> onSelected;
  final KreditColors kredit;

  const _BankChipPicker({
    required this.banks,
    required this.selectedBank,
    required this.onSelected,
    required this.kredit,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: banks.map((bank) {
        final selected = selectedBank == bank;
        return FilterChip(
          label: Text(bank),
          selected: selected,
          onSelected: (_) => onSelected(bank),
          selectedColor: accent.withValues(alpha: 0.15),
          checkmarkColor: accent,
          labelStyle: TextStyle(
            color: selected ? accent : kredit.textPrimary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }
}

class _InterestUnknownRow extends StatelessWidget {
  final bool interestUnknown;
  final ValueChanged<bool> onChanged;
  const _InterestUnknownRow({required this.interestUnknown, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: interestUnknown,
      onChanged: onChanged,
      title: Text('Tasa desconocida', style: TextStyle(fontWeight: FontWeight.w600, color: kredit.textPrimary)),
      subtitle: Text('Kredit no mostrará tasa ni calculará intereses.', style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textSecondary)),
    );
  }
}

class _EarlyPaymentRow extends StatelessWidget {
  final bool earlyPaymentWaivesInterest;
  final ValueChanged<bool> onChanged;
  const _EarlyPaymentRow({required this.earlyPaymentWaivesInterest, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: earlyPaymentWaivesInterest,
      onChanged: onChanged,
      title: Text('Pago anticipado sin interés', style: TextStyle(fontWeight: FontWeight.w600, color: kredit.textPrimary)),
      subtitle: Text('Actívalo si la entidad condona el interés al pagar antes del vencimiento.', style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textSecondary)),
    );
  }
}

/// Non-blocking hint shown under the interest rate field when the entered
/// value looks like it might be mismatched (monthly vs. E.A.), with the
/// same small warning-icon-plus-text treatment used for the Nequi/DaviPlata
/// type suggestion. when the entered
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
              style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
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
                fontSize: KreditTextSize.body,
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
              style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
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
              fontSize: KreditTextSize.body,
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
            style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
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
                        fontSize: KreditTextSize.body,
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
/// Barra de progreso animada. Cuando el número de pasos cambia de 1 → N, los
/// puntos adicionales "ruedan" hacia la derecha revelándose uno a uno desde
// ══════════════════════════════════════════════════════════════════════════════
// Step progress header — sequential fill animations
//
// _InitialStepIndicator (mode == null):
//   1. Dot "0" fills with accent left→right (300ms)
//   2. Future-line expands left→right (220ms)
//   3. Chevrons march →→→ (repeat 1100ms)
//
// _StepProgress (mode != null):
//   _fill: continuous float where dot[i] fills at [2i..2i+1], line[i→i+1] fills
//   at [2i+1..2i+2]. Advancing: line fills L→R then dot fills. Retreating: dot
//   unfills then line shrinks R→L (widthFactor going 1→0 with Alignment.centerLeft).
//   Duration 420ms matches view AnimatedSwitcher so both feel synchronized.
// ══════════════════════════════════════════════════════════════════════════════

class _InitialStepIndicator extends StatefulWidget {
  final KreditColors kredit;
  const _InitialStepIndicator({required this.kredit});

  @override
  State<_InitialStepIndicator> createState() => _InitialStepIndicatorState();
}

class _InitialStepIndicatorState extends State<_InitialStepIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _dotCtrl;
  late final AnimationController _lineCtrl;
  late final AnimationController _arrowCtrl;
  late final Animation<double> _dotAnim;
  late final Animation<double> _lineAnim;
  late final List<Animation<double>> _chevronAnims;

  @override
  void initState() {
    super.initState();
    _dotCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _lineCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _arrowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _dotAnim = CurvedAnimation(parent: _dotCtrl, curve: Curves.easeOutCubic);
    _lineAnim = CurvedAnimation(parent: _lineCtrl, curve: Curves.easeOutCubic);
    _chevronAnims = List.generate(3, (i) {
      final start = i / 3.0;
      final end = (i + 1) / 3.0;
      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 0.08, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
          weight: 40,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.08).chain(CurveTween(curve: Curves.easeIn)),
          weight: 60,
        ),
      ]).animate(CurvedAnimation(parent: _arrowCtrl, curve: Interval(start, end)));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _dotCtrl.forward();
      if (!mounted) return;
      await _lineCtrl.forward();
      if (!mounted) return;
      _arrowCtrl.repeat();
    });
  }

  @override
  void dispose() {
    _dotCtrl.dispose();
    _lineCtrl.dispose();
    _arrowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final kredit = widget.kredit;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          // Dot "0" fills with accent color
          AnimatedBuilder(
            animation: _dotAnim,
            builder: (context, _) => Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(kredit.bgSecondary, accent, _dotAnim.value),
                border: Border.all(
                  color: Color.lerp(kredit.borderCard, accent, _dotAnim.value)!,
                  width: 1.5,
                ),
              ),
              child: Text(
                '0',
                style: TextStyle(
                  fontSize: KreditTextSize.body,
                  fontWeight: FontWeight.w800,
                  color: Color.lerp(kredit.textTertiary, scaffoldBg, _dotAnim.value),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Line fills left→right — static Container passed as child so
          // AnimatedBuilder only rebuilds the Align wrapper, not the fill.
          Expanded(
            child: AnimatedBuilder(
              animation: _lineAnim,
              child: Container(height: 1.5, color: kredit.borderCard),
              builder: (context, child) => Align(
                alignment: Alignment.centerLeft,
                widthFactor: _lineAnim.value,
                child: child,
              ),
            ),
          ),
          // Chevrons: FadeTransition is layer-based (no widget rebuild per
          // frame) and the icons are pre-built once as the static child tree.
          FadeTransition(
            opacity: _lineAnim,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => FadeTransition(
                  opacity: _chevronAnims[i],
                  child: Icon(Icons.chevron_right_rounded, size: KreditIconSize.medium, color: accent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepProgress extends StatefulWidget {
  final int currentStep;
  final List<String> titles;
  final KreditColors kredit;

  const _StepProgress({
    required this.currentStep,
    required this.titles,
    required this.kredit,
  });

  @override
  State<_StepProgress> createState() => _StepProgressState();
}

class _StepProgressState extends State<_StepProgress>
    with TickerProviderStateMixin {
  // _fill: dot[i] fills at [2i..2i+1], line[i→i+1] fills at [2i+1..2i+2]
  late final AnimationController _fillCtrl;
  late final Animation<double> _fillCurved;
  late final AnimationController _expandCtrl;
  late final Animation<double> _expandCurved;
  late List<String> _displayTitles;

  double _fillFrom = 0.0;
  double _fillTo = 0.0;

  double get _fill =>
      _fillFrom + (_fillTo - _fillFrom) * _fillCurved.value;

  double _dotFill(int i) => (_fill - 2 * i).clamp(0.0, 1.0);
  double _lineFill(int i) => (_fill - (2 * i + 1)).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _displayTitles = widget.titles;
    _fillFrom = 0.0;
    _fillTo = (2 * widget.currentStep + 1).toDouble();

    _fillCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _fillCurved =
        CurvedAnimation(parent: _fillCtrl, curve: Curves.easeInOutCubic);

    _expandCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _expandCurved =
        CurvedAnimation(parent: _expandCtrl, curve: Curves.easeOutCubic);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fillCtrl.forward();
      if (widget.titles.length > 1) _expandCtrl.forward();
    });
  }

  @override
  void didUpdateWidget(_StepProgress old) {
    super.didUpdateWidget(old);

    if (old.currentStep != widget.currentStep) {
      _fillFrom = _fill;
      _fillTo = (2 * widget.currentStep + 1).toDouble();
      _fillCtrl.forward(from: 0);
    }

    if (old.titles.length != widget.titles.length) {
      if (widget.titles.length > old.titles.length) {
        setState(() => _displayTitles = widget.titles);
        _expandCtrl.forward(from: 0);
      } else {
        _expandCtrl.reverse().whenComplete(() {
          if (mounted) setState(() => _displayTitles = widget.titles);
        });
      }
    } else if (_displayTitles != widget.titles) {
      setState(() => _displayTitles = widget.titles);
    }
  }

  @override
  void dispose() {
    _fillCtrl.dispose();
    _expandCtrl.dispose();
    super.dispose();
  }

  Widget _buildDot(BuildContext context, int step, Color accent) {
    final fill = _dotFill(step);
    final done = step < widget.currentStep;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final kredit = widget.kredit;
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.lerp(kredit.bgSecondary, accent, fill),
        border: Border.all(
          color: Color.lerp(kredit.borderCard, accent, fill)!,
          width: 1.5,
        ),
      ),
      child: done
          ? Icon(Icons.check,
              size: KreditIconSize.small,
              color: Color.lerp(kredit.textTertiary, scaffoldBg, fill))
          : Text(
              '${step + 1}',
              style: TextStyle(
                fontSize: KreditTextSize.body,
                fontWeight: FontWeight.w700,
                color: Color.lerp(kredit.textTertiary, scaffoldBg, fill),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final kredit = widget.kredit;
    final n = _displayTitles.length;

    // LayoutBuilder wraps AnimatedBuilder so the layout pass only runs when
    // constraints change — not on every animation frame (60 fps).
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: n <= 1
          ? Align(
              alignment: Alignment.centerLeft,
              child: AnimatedBuilder(
                animation: _fillCtrl,
                builder: (ctx, _) => _buildDot(ctx, 0, accent),
              ),
            )
          : LayoutBuilder(builder: (ctx, constraints) {
              final segments = n - 1;
              // Dot 0 (24px) is outside the Expanded area, so subtract it
              // before distributing the remaining space among connectors and
              // dots 1..n-1. Without this, the inner SizedBox is 24px wider
              // than the Expanded, causing an overflow warning in debug mode.
              final innerW = constraints.maxWidth - 24.0;
              final connW = (innerW - segments * 24.0) / segments.toDouble();
              return AnimatedBuilder(
                animation: Listenable.merge([_fillCtrl, _expandCtrl]),
                builder: (ctx2, _) => Row(
                  children: [
                    _buildDot(ctx2, 0, accent),
                    Expanded(
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: _expandCurved.value,
                          child: SizedBox(
                            width: innerW,
                            child: Row(
                              children: [
                                for (int i = 1; i < n; i++) ...[
                                  // Connector line: grey base + accent fill L→R
                                  SizedBox(
                                    width: connW,
                                    child: Stack(
                                      children: [
                                        Container(height: 2, color: kredit.borderCard),
                                        FractionallySizedBox(
                                          widthFactor: _lineFill(i - 1),
                                          alignment: Alignment.centerLeft,
                                          child: Container(height: 2, color: accent),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _buildDot(ctx2, i, accent),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
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
            fontSize: KreditTextSize.body,
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
                      fontSize: KreditTextSize.body,
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
              size: KreditIconSize.medium,
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
                size: KreditIconSize.small,
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
                      fontSize: KreditTextSize.body,
                      color: kredit.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: KreditIconSize.micro,
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
            Icon(icon, size: KreditIconSize.small, color: selected ? accent : kredit.textTertiary),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: KreditTextSize.body,
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
                      child: const Icon(Icons.check, size: KreditIconSize.micro, color: Colors.black),
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

class _EduHintExpansion extends StatefulWidget {
  final String text;
  final String detail;
  final IconData icon;
  const _EduHintExpansion({required this.text, required this.detail, required this.icon});
  @override
  State<_EduHintExpansion> createState() => _EduHintExpansionState();
}

class _EduHintExpansionState extends State<_EduHintExpansion> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(widget.icon, size: KreditIconSize.small, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.text,
                    style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textSecondary, height: 1.45),
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(Icons.keyboard_arrow_down, size: KreditIconSize.small, color: accent),
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 1,
                color: accent.withValues(alpha: 0.15),
              ),
              const SizedBox(height: 8),
              Text(
                widget.detail,
                style: TextStyle(
                  fontSize: KreditTextSize.body,
                  color: kredit.textTertiary,
                  height: 1.55,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

