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
import '../../widgets/card_design_painter.dart';
import '../../widgets/interest_rate_type_field.dart';
import '../../widgets/kredit_section_card.dart';
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
  CardDesign? _cardDesign;
  bool _saving = false;
  bool _hasChanges = false;
  bool? _oneInstallmentInterestPolicy;
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
    _cardDesign = CardDesign.fromKey(widget.credit.cardDesign);
    if (widget.credit is CardCredit) {
      _oneInstallmentInterestPolicy =
          (widget.credit as CardCredit).oneInstallmentInterestPolicy;
    }
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

  // Fase 9 del roadmap ("alerta de cupo menor al saldo al editar tarjeta"):
  // non-blocking — a user lowering their limit below what they already owe
  // is a valid real-world case (the bank cut it), so this only informs,
  // it never prevents saving (unlike `_quotaTooLowWarning` below, which
  // does block because that case is never legitimate).
  String? get _insufficientLimitWarning {
    final credit = widget.credit;
    if (credit is! CardCredit) return null;
    final newLimit = double.tryParse(CurrencyInputFormatter.unformat(_limitCtrl.text));
    if (newLimit == null || newLimit <= 0) return null;
    if (newLimit >= credit.currentBalance) return null;
    return 'El nuevo límite (${CurrencyInputFormatter.format(newLimit)}) es menor que tu saldo '
        'actual (${CurrencyInputFormatter.format(credit.currentBalance)}). Puedes guardarlo así '
        '— por ejemplo si el banco te bajó el cupo — pero tu cupo disponible quedará en \$0.';
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
    credit.cardDesign = _cardDesign?.name;

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
      credit.oneInstallmentInterestPolicy = _oneInstallmentInterestPolicy;
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
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Form(
            key: _formKey,
            child: widget.credit is CardCredit
                ? _buildCardLayout(context, widget.credit as CardCredit, kredit, scrollController)
                : _buildLoanLayout(context, widget.credit as LoanCredit, kredit, scrollController),
          );
        },
      ),
    );
  }

  // ── shared helpers ───────────────────────────────────────────────────────

  Widget _buildHandle(KreditColors kredit) => Center(
        child: Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: kredit.borderCard,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _buildTypeHeader(
    BuildContext context,
    String title,
    IconData icon,
    String typeLabel,
    KreditColors kredit,
  ) {
    final accent = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(icon, size: KreditIconSize.micro, color: accent),
            const SizedBox(width: 6),
            Text(
              typeLabel,
              style: TextStyle(
                fontSize: KreditTextSize.caption,
                color: accent,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(width: 8),
            Container(width: 1, height: 12, color: kredit.borderCard),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.credit.name,
                style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreviewContainer(
    BuildContext context,
    Credit previewCredit,
    String previewLabel,
    KreditColors kredit,
  ) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            previewLabel,
            style: TextStyle(
              fontSize: KreditTextSize.caption,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Se actualiza en tiempo real mientras editas',
            style: TextStyle(fontSize: 11, color: kredit.textTertiary),
          ),
          const SizedBox(height: 12),
          RepaintBoundary(child: WalletCard(credit: previewCredit)),
        ],
      ),
    );
  }

  Widget _buildNotesSection() => KreditSectionCard(
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
            onChanged: (_) => setState(() => _hasChanges = true),
          ),
        ],
      );

  Widget _buildSaveButton() => FilledButton.icon(
        onPressed: (_hasChanges && !_saving) ? _save : null,
        icon: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.check_circle_outline_rounded),
        label: Text(_saving
            ? 'Guardando...'
            : _hasChanges
                ? 'Guardar Cambios'
                : 'Sin cambios'),
        style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
      );

  Widget _buildLenderDropdown(KreditColors kredit, {required String label}) =>
      DropdownButtonFormField<String>(
        isExpanded: true,
        style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textPrimary),
        initialValue: _selectedLenderPreset,
        decoration: InputDecoration(labelText: label, isDense: true),
        items: _presetLenders
            .map((l) => DropdownMenuItem(
                  value: l,
                  child: Text(l, style: const TextStyle(fontSize: KreditTextSize.body)),
                ))
            .toList(),
        onChanged: (v) {
          setState(() {
            _selectedLenderPreset = v;
            _hasChanges = true;
            if (v != null && v != 'Otro...') {
              _lenderCtrl.text = v;
              final lower = v.toLowerCase();
              if (lower.contains('nequi')) { _color = '#DA0081'; }
              else if (lower.contains('nu')) { _color = '#820AD1'; }
              else if (lower.contains('bancolombia')) { _color = '#FFDD00'; }
              else if (lower.contains('davivienda') || lower.contains('daviplata')) { _color = '#E4032E'; }
              else if (lower.contains('bbva')) { _color = '#004481'; }
              else if (lower.contains('rappi')) { _color = '#FE3F23'; }
              else if (lower.contains('lulo')) { _color = '#00E28A'; }
              else if (lower.contains('popular')) { _color = '#00875A'; }
              else if (lower.contains('occidente')) { _color = '#00205B'; }
              else if (lower.contains('villas')) { _color = '#0055A5'; }
              else if (lower.contains('itaú') || lower.contains('itau')) { _color = '#EC7000'; }
              else if (lower.contains('tuya') || lower.contains('exito')) { _color = '#FFD100'; }
            } else if (v == 'Otro...') {
              _lenderCtrl.clear();
            }
          });
        },
        validator: (_) => (_lenderCtrl.text.trim().isEmpty) ? 'Requerido' : null,
      );

  // ── tarjeta layout ───────────────────────────────────────────────────────

  Widget _buildCardLayout(
    BuildContext context,
    CardCredit card,
    KreditColors kredit,
    ScrollController scrollController,
  ) {
    final previewCredit = CardCredit(
      id: card.id,
      name: _nameCtrl.text.isEmpty ? card.name : _nameCtrl.text,
      lender: _lenderCtrl.text.isEmpty ? card.lender : _lenderCtrl.text,
      creditLimit: card.creditLimit,
      currentBalance: card.currentBalance,
      cutoffDay: int.tryParse(_cutoffDayCtrl.text) ?? card.cutoffDay,
      paymentDueOffsetDays: int.tryParse(_paymentOffsetCtrl.text) ?? card.paymentDueOffsetDays,
      interestRate: double.tryParse(_interestCardCtrl.text.replaceAll(',', '.')) ?? card.interestRate,
      interestRateType: _interestRateType,
      managementFee: card.managementFee,
      managementFeeFrequency: card.managementFeeFrequency,
      cycleCount: card.cycleCount,
      lastAccrualCutoff: card.lastAccrualCutoff,
      quotaId: card.quotaId,
      color: _color,
      movements: card.movements,
      cardDesign: _cardDesign?.name,
    );

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(KreditSpacing.card),
      children: [
        _buildHandle(kredit),
        _buildTypeHeader(
          context,
          'Editar Tarjeta',
          Icons.credit_card_rounded,
          'Tarjeta de Crédito',
          kredit,
        ),
        const SizedBox(height: 20),
        _buildPreviewContainer(context, previewCredit, 'VISTA PREVIA DE TARJETA', kredit),
        const SizedBox(height: 16),

        // ── IDENTIDAD ──────────────────────────────────────────────────────
        KreditSectionCard(
          label: 'IDENTIDAD',
          icon: Icons.badge_outlined,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameCtrl,
                    style: const TextStyle(fontSize: KreditTextSize.body),
                    decoration: const InputDecoration(labelText: 'Nombre / Alias', isDense: true),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    onChanged: (_) => setState(() => _hasChanges = true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildLenderDropdown(kredit, label: 'Banco emisor')),
              ],
            ),
            if (_selectedLenderPreset == 'Otro...') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _lenderCtrl,
                decoration: const InputDecoration(
                  labelText: 'Escribir libre',
                  hintText: 'Ej. PrestaYa...',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                onChanged: (_) => setState(() => _hasChanges = true),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // ── CUPO Y SALDO ───────────────────────────────────────────────────
        KreditSectionCard(
          label: 'CUPO Y SALDO',
          icon: Icons.credit_card_outlined,
          children: [
            TextFormField(
              controller: _limitCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: const [CurrencyInputFormatter()],
              decoration: const InputDecoration(labelText: 'Límite Total (\$)', isDense: true),
              onChanged: (_) => setState(() => _hasChanges = true),
            ),
            if (_insufficientLimitWarning != null)
              _EditInterestRateWarningHint(text: _insufficientLimitWarning!),
            const SizedBox(height: 12),
            _readOnlyField(
              'Saldo actual',
              CurrencyInputFormatter.format(card.currentBalance),
              Icons.account_balance_wallet_outlined,
              kredit,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── CICLO DE FACTURACIÓN ───────────────────────────────────────────
        KreditSectionCard(
          label: 'CICLO DE FACTURACIÓN',
          icon: Icons.event_repeat_rounded,
          children: [
            _warningBanner(
              'Cambiar el día de corte afecta los extractos futuros. Los ya cerrados no se modifican.',
              kredit,
            ),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textPrimary),
                    initialValue: (int.tryParse(_cutoffDayCtrl.text) ?? 15).clamp(1, 31),
                    decoration: const InputDecoration(labelText: 'Día de Corte', isDense: true),
                    items: List.generate(31, (i) => i + 1)
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(
                                'Día $d',
                                style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textPrimary),
                              ),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() { _cutoffDayCtrl.text = v.toString(); _hasChanges = true; });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textPrimary),
                    initialValue: (int.tryParse(_paymentOffsetCtrl.text) ?? 20).clamp(1, 30),
                    decoration: const InputDecoration(labelText: 'Días para Pagar', isDense: true),
                    items: List.generate(30, (i) => i + 1)
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text('$d días', style: const TextStyle(fontSize: KreditTextSize.body)),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() { _paymentOffsetCtrl.text = v.toString(); _hasChanges = true; });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── TASAS Y COBROS ─────────────────────────────────────────────────
        KreditSectionCard(
          label: 'TASAS Y COBROS',
          icon: Icons.percent_rounded,
          children: [
            _warningBanner(
              'Los intereses ya acumulados no se recalculan. La nueva tasa aplica desde el siguiente extracto.',
              kredit,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _interestCardCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Interés (%)', isDense: true),
                    onChanged: (_) => setState(() => _hasChanges = true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InterestRateTypeField(
                    value: _interestRateType,
                    onChanged: (v) => setState(() { _interestRateType = v; _hasChanges = true; }),
                  ),
                ),
              ],
            ),
            if (_interestRateWarning != null)
              _EditInterestRateWarningHint(text: _interestRateWarning!),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _managementFeeCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [CurrencyInputFormatter()],
                    decoration: const InputDecoration(labelText: 'Cuota de Manejo (\$)', isDense: true),
                    onChanged: (_) => setState(() => _hasChanges = true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textPrimary),
                    initialValue: _managementFeeFrequency,
                    decoration: const InputDecoration(labelText: 'Frecuencia', isDense: true),
                    items: const [
                      DropdownMenuItem(
                        value: ManagementFeeFrequency.monthly,
                        child: Text('Mensual', style: TextStyle(fontSize: KreditTextSize.body)),
                      ),
                      DropdownMenuItem(
                        value: ManagementFeeFrequency.annual,
                        child: Text('Anual', style: TextStyle(fontSize: KreditTextSize.body)),
                      ),
                    ],
                    onChanged: (v) => setState(() {
                      _managementFeeFrequency = v ?? ManagementFeeFrequency.monthly;
                      _hasChanges = true;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COMPRAS A 1 CUOTA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: kredit.textTertiary,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<bool?>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  segments: const [
                    ButtonSegment(value: null, label: Text('Desconocido')),
                    ButtonSegment(value: true, label: Text('Sin interés')),
                    ButtonSegment(value: false, label: Text('Con interés')),
                  ],
                  selected: {_oneInstallmentInterestPolicy},
                  onSelectionChanged: (s) => setState(() {
                    _oneInstallmentInterestPolicy = s.first;
                    _hasChanges = true;
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  'Si pagas a tiempo, ¿la tarjeta cobra interés en compras a 1 cuota?',
                  style: TextStyle(fontSize: 11, color: kredit.textTertiary),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        _buildNotesSection(),
        const SizedBox(height: 24),
        _buildSaveButton(),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── cupo / préstamo layout ───────────────────────────────────────────────

  Widget _buildLoanLayout(
    BuildContext context,
    LoanCredit loan,
    KreditColors kredit,
    ScrollController scrollController,
  ) {
    final isVoucher = loan.quotaId != null;

    final previewCredit = LoanCredit(
      id: loan.id,
      name: _nameCtrl.text.isEmpty ? loan.name : _nameCtrl.text,
      lender: _lenderCtrl.text.isEmpty ? loan.lender : _lenderCtrl.text,
      totalAmount: loan.totalAmount,
      quotaAmount: loan.quotaAmount,
      interestRate: loan.interestRate,
      interestRateType: loan.interestRateType,
      totalInstallments: loan.totalInstallments,
      startDate: loan.startDate,
      frequency: loan.frequency,
      color: _color,
      location: _locationCtrl.text,
      installments: loan.installments,
      abonos: loan.abonos,
      quotaId: loan.quotaId,
      interestUnknown: loan.interestUnknown,
      earlyPaymentWaivesInterest: loan.earlyPaymentWaivesInterest,
      cardDesign: _cardDesign?.name,
    );

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(KreditSpacing.card),
      children: [
        _buildHandle(kredit),
        _buildTypeHeader(
          context,
          isVoucher ? 'Editar Cupo' : 'Editar Crédito',
          isVoucher ? Icons.storefront_rounded : Icons.account_balance_wallet_rounded,
          isVoucher ? 'Cupo de Tienda' : 'Crédito',
          kredit,
        ),
        const SizedBox(height: 20),
        _buildPreviewContainer(
          context,
          previewCredit,
          isVoucher ? 'VISTA PREVIA DEL VOUCHER' : 'VISTA PREVIA DEL CRÉDITO',
          kredit,
        ),
        const SizedBox(height: 16),

        // ── IDENTIDAD (voucher) / DATOS BÁSICOS (préstamo) ─────────────────
        KreditSectionCard(
          label: isVoucher ? 'CUPO DE TIENDA' : 'DATOS BÁSICOS',
          icon: isVoucher ? Icons.storefront_outlined : Icons.badge_outlined,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameCtrl,
                    style: const TextStyle(fontSize: KreditTextSize.body),
                    decoration: InputDecoration(
                      labelText: isVoucher ? 'Nombre del cupo' : 'Nombre del Crédito',
                      isDense: true,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    onChanged: (_) => setState(() => _hasChanges = true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLenderDropdown(
                    kredit,
                    label: isVoucher ? 'Tienda / Comercio' : 'Banco / Prestamista',
                  ),
                ),
              ],
            ),
            if (_selectedLenderPreset == 'Otro...') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _lenderCtrl,
                decoration: InputDecoration(
                  labelText: 'Escribir libre',
                  hintText: isVoucher ? 'Ej. Tienda artesanal...' : 'Ej. PrestaYa...',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                onChanged: (_) => setState(() => _hasChanges = true),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // ── ESTABLECIMIENTO (solo préstamos sin quotaId) ───────────────────
        if (!isVoucher) ...[
          KreditSectionCard(
            label: 'DÓNDE Y CON QUÉ',
            icon: Icons.storefront_outlined,
            children: [
              DropdownButtonFormField<String>(
                isExpanded: true,
                style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textPrimary),
                initialValue: _selectedLocationPreset,
                decoration: const InputDecoration(
                  labelText: 'Comercio / Establecimiento',
                  isDense: true,
                ),
                items: _presetLocations
                    .map((loc) => DropdownMenuItem(
                          value: loc,
                          child: Text(loc, style: const TextStyle(fontSize: KreditTextSize.body)),
                        ))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedLocationPreset = v;
                    _hasChanges = true;
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
                  onChanged: (_) => setState(() => _hasChanges = true),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
        ],

        // ── MONTO Y CUOTA ──────────────────────────────────────────────────
        KreditSectionCard(
          label: 'MONTO Y CUOTA',
          icon: Icons.request_quote_outlined,
          children: [
            _warningBanner(
              'Cambiar la tasa afecta las cuotas futuras. Las ya pagadas no se recalculan.',
              kredit,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _interestCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Interés (%)', isDense: true),
                    onChanged: (_) => setState(() => _hasChanges = true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InterestRateTypeField(
                    value: _interestRateType,
                    onChanged: (v) => setState(() { _interestRateType = v; _hasChanges = true; }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quotaCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: const [CurrencyInputFormatter()],
              decoration: const InputDecoration(labelText: 'Valor Cuota (\$)'),
              onChanged: (_) => setState(() => _hasChanges = true),
            ),
            const SizedBox(height: 6),
            Text(
              'Normalmente se recalcula sola según monto, cuotas e interés, pero puedes sobreescribirla manualmente si renegociaste con el banco.',
              style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _buildNotesSection(),
        const SizedBox(height: 24),
        _buildSaveButton(),
        const SizedBox(height: 8),
      ],
    );
  }
}

Widget _warningBanner(String message, KreditColors kredit) => Container(
  margin: const EdgeInsets.only(bottom: 12),
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.amber.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: Colors.amber.withValues(alpha: 0.40)),
  ),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          message,
          style: TextStyle(fontSize: 12, color: kredit.textSecondary),
        ),
      ),
    ],
  ),
);

Widget _readOnlyField(
  String label,
  String value,
  IconData icon,
  KreditColors kredit,
) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: kredit.bgCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kredit.borderCard),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: kredit.textTertiary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: kredit.textTertiary),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 14, color: kredit.textSecondary),
              ),
            ],
          ),
          const Spacer(),
          Icon(Icons.lock_outline, size: 14, color: kredit.textTertiary),
        ],
      ),
    );

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
            size: KreditIconSize.small,
            color: AppColors.warning,
          ),
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
