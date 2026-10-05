import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/credit.dart';
import '../../data/models/installment.dart';
import '../../data/models/loan_abono.dart';
import '../../domain/date_utils.dart';
import '../../domain/loan_calculator.dart';
import '../../providers/credits_provider.dart';
import '../../theme/app_theme.dart';
import '../loan_abono_sheet.dart';
import '../../utils/credit_display_utils.dart';
import '../../utils/currency_input_formatter.dart';
import 'status_badge.dart';
import '../kredit_bottom_dialogs.dart';

/// Cronograma de cuotas, grouped by urgency instead of a flat chronological
/// list — with many installments a plain list becomes a monotonous scroll
/// where the handful of cuotas that actually need attention (overdue / due
/// soon) get buried among dozens of future ones. Grouping into
/// Vencidas → Próximas → Futuras → Pagadas lets a user answer "am I behind"
/// in one glance, and the paid section collapses by default since it's
/// historical record, not something to act on.
class ScheduleTab extends ConsumerStatefulWidget {
  final LoanCredit credit;
  // Cuando un credito de cupo comercial agrupa varias compras, el
  // Cronograma se muestra dentro de una tarjeta colapsable de un
  // ListView externo — este debe encogerse a su contenido (nunca asumir
  // que tiene toda la pantalla disponible via Expanded) en ese caso.
  final bool shrinkWrap;

  const ScheduleTab({super.key, required this.credit, this.shrinkWrap = false});

  @override
  ConsumerState<ScheduleTab> createState() => _ScheduleTabState();
}

double _sumAmount(List<Installment> insts) =>
    insts.fold(0.0, (s, i) => s + i.amount);

Future<void> _markAllPaid(
  BuildContext context,
  WidgetRef ref,
  LoanCredit credit,
  int unpaidCount,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(creditsProvider.notifier).markAllInstallmentsPaid(credit.id);
    messenger.showSnackBar(
      SnackBar(content: Text('$unpaidCount cuota(s) registradas como pagadas')),
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('No se pudo registrar el pago total: $e')),
    );
  }
}

class _ScheduleTabState extends ConsumerState<ScheduleTab> {
  bool _paidExpanded = false;
  bool _abonosExpanded = true;

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final credit = widget.credit;
    final unpaidCount = credit.installments.where((i) => !i.paid).length;

    final hasOverdue = credit.installments.any(
      (i) =>
          !i.paid && getInstallmentStatus(i).state == InstallmentState.overdue,
    );

    final overdue = <Installment>[];
    final dueSoon = <Installment>[];
    final upcoming = <Installment>[];
    final paid = <Installment>[];
    for (final inst in credit.installments) {
      if (inst.paid) {
        paid.add(inst);
        continue;
      }
      final state = getInstallmentStatus(inst).state;
      if (state == InstallmentState.overdue) {
        overdue.add(inst);
      } else if (state == InstallmentState.warning) {
        dueSoon.add(inst);
      } else {
        upcoming.add(inst);
      }
    }

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Cronograma de Cuotas ($unpaidCount)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: kredit.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                // Secondary action: when there's an overdue installment,
                // "Pago total" is the priority move, so this reads as
                // text-only to keep it visually subordinate (same
                // primary/secondary convention as add_credit_sheet.dart's
                // step controls and wallet_card.dart's actions).
                child: hasOverdue
                    ? TextButton.icon(
                        onPressed: unpaidCount == 0
                            ? null
                            : () => LoanAbonoSheet.show(
                                context,
                                creditId: credit.id,
                              ),
                        icon: const Icon(
                          Icons.savings_outlined,
                          size: KreditIconSize.small,
                        ),
                        label: const Text('Abono Extra'),
                      )
                    : OutlinedButton.icon(
                        onPressed: unpaidCount == 0
                            ? null
                            : () => LoanAbonoSheet.show(
                                context,
                                creditId: credit.id,
                              ),
                        icon: const Icon(
                          Icons.savings_outlined,
                          size: KreditIconSize.small,
                        ),
                        label: const Text('Abono Extra'),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                // Primary action once an installment is overdue: filled
                // style signals this is the recommended next step to
                // catch up, matching the app's filled-button-for-primary
                // convention.
                child: hasOverdue
                    ? FilledButton.icon(
                        onPressed: unpaidCount == 0
                            ? null
                            : () => _markAllPaid(
                                context,
                                ref,
                                credit,
                                unpaidCount,
                              ),
                        icon: const Icon(
                          Icons.check,
                          size: KreditIconSize.small,
                        ),
                        label: const Text('Pago total'),
                      )
                    : OutlinedButton.icon(
                        onPressed: unpaidCount == 0
                            ? null
                            : () => _markAllPaid(
                                context,
                                ref,
                                credit,
                                unpaidCount,
                              ),
                        icon: const Icon(
                          Icons.check,
                          size: KreditIconSize.small,
                        ),
                        label: const Text('Pago total'),
                      ),
              ),
            ],
          ),
        ],
      ),
    );

    final body = ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shrinkWrap: widget.shrinkWrap,
      physics: widget.shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      children: [
        if (overdue.isNotEmpty)
          _SectionGroup(
            title: 'Vencidas',
            count: overdue.length,
            total: _sumAmount(overdue),
            emphasized: true,
            children: overdue
                .map((i) => _InstallmentTile(credit: credit, inst: i))
                .toList(),
          ),
        if (dueSoon.isNotEmpty)
          _SectionGroup(
            title: 'Próximas',
            count: dueSoon.length,
            total: _sumAmount(dueSoon),
            children: dueSoon
                .map((i) => _InstallmentTile(credit: credit, inst: i))
                .toList(),
          ),
        if (upcoming.isNotEmpty)
          _SectionGroup(
            title: 'Futuras',
            count: upcoming.length,
            total: _sumAmount(upcoming),
            children: upcoming
                .map((i) => _InstallmentTile(credit: credit, inst: i))
                .toList(),
          ),
        if (paid.isNotEmpty)
          _SectionGroup(
            title: 'Pagadas',
            count: paid.length,
            total: _sumAmount(paid),
            collapsible: true,
            expanded: _paidExpanded,
            onToggle: () => setState(() => _paidExpanded = !_paidExpanded),
            children: paid
                .map((i) => _InstallmentTile(credit: credit, inst: i))
                .toList(),
          ),
        if (credit.abonos.isNotEmpty)
          _SectionGroup(
            title: 'Abonos Registrados',
            count: credit.abonos.length,
            total: credit.abonos.fold(0.0, (s, a) => s + a.amount),
            collapsible: true,
            expanded: _abonosExpanded,
            onToggle: () => setState(() => _abonosExpanded = !_abonosExpanded),
            children: credit.abonos.reversed
                .map(
                  (a) => _AbonoTile(
                    creditId: credit.id,
                    abono: a,
                    // Solo el ÚLTIMO abono (primero en esta lista
                    // invertida) tiene una comparación antes/ahora
                    // exacta contra el estado actual del crédito.
                    impact: identical(a, credit.abonos.last)
                        ? computeLastAbonoImpact(credit)
                        : null,
                  ),
                )
                .toList(),
          ),
      ],
    );

    if (widget.shrinkWrap) {
      return Column(children: [header, body]);
    }
    return Column(
      children: [
        header,
        Expanded(child: body),
      ],
    );
  }
}

class _AbonoTile extends ConsumerWidget {
  final String creditId;
  final LoanAbono abono;
  final LastAbonoImpact? impact;

  const _AbonoTile({required this.creditId, required this.abono, this.impact});

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showKreditConfirmSheet(
      context,
      title: 'Eliminar abono',
      message: '¿Eliminar el abono de ${formatCOP(abono.amount)}? Las cuotas que este abono adelantó volverán a marcarse como pendientes. Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      isDanger: true,
      icon: Icons.delete_outline,
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(creditsProvider.notifier).deleteLoanAbono(creditId, abono);
      messenger.showSnackBar(const SnackBar(content: Text('Abono eliminado')));
    } catch (e) {
      debugPrint('deleteLoanAbono failed: $e');
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar el abono.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  abono.installmentsSkipped > 0
                      ? '${abono.installmentsSkipped} cuota(s) adelantada(s)'
                      : 'Abono a capital',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: KreditTextSize.body,
                    color: kredit.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  abono.note.isNotEmpty ? abono.note : formatDate(abono.date),
                  style: TextStyle(
                    fontSize: KreditTextSize.body,
                    color: kredit.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (impact != null && impact!.hasAnyImpact) ...[
                  const SizedBox(height: 4),
                  if (impact!.hasQuotaChange)
                    Text(
                      'Cuota bajó de ${formatCOP(impact!.quotaBefore!)} a '
                      '${formatCOP(impact!.quotaAfter!)}',
                      style: TextStyle(
                        fontSize: KreditTextSize.body,
                        fontWeight: FontWeight.w600,
                        color: kredit.success,
                      ),
                    ),
                  if (impact!.installmentsSaved > 0)
                    Text(
                      'Terminas ${impact!.installmentsSaved} cuota'
                      '${impact!.installmentsSaved == 1 ? '' : 's'} antes',
                      style: TextStyle(
                        fontSize: KreditTextSize.body,
                        fontWeight: FontWeight.w600,
                        color: kredit.success,
                      ),
                    ),
                  if (impact!.estimatedInterestSaving > 0)
                    Text(
                      'Ahorras aproximadamente '
                      '${formatCOP(impact!.estimatedInterestSaving)} en '
                      'intereses estimados',
                      style: TextStyle(
                        fontSize: KreditTextSize.body,
                        fontWeight: FontWeight.w600,
                        color: kredit.success,
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (impact != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: kredit.success.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Reciente',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: kredit.success,
                    ),
                  ),
                ),
              Text(
                '-${formatCOP(abono.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: KreditTextSize.body,
                  color: accent,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              size: KreditIconSize.small,
              color: kredit.textTertiary,
            ),
            visualDensity: VisualDensity.compact,
            onPressed: () => _confirmAndDelete(context, ref),
          ),
        ],
      ),
    );
  }
}

class _SectionGroup extends StatelessWidget {
  final String title;
  final int count;
  final double total;
  final List<Widget> children;
  final bool emphasized;
  final bool collapsible;
  final bool expanded;
  final VoidCallback? onToggle;

  const _SectionGroup({
    required this.title,
    required this.count,
    required this.total,
    required this.children,
    this.emphasized = false,
    this.collapsible = false,
    this.expanded = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final showChildren = !collapsible || expanded;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: collapsible ? onToggle : null,
            borderRadius: BorderRadius.circular(KreditRadius.chip),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: KreditTextSize.body,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: emphasized
                          ? kredit.textPrimary
                          : kredit.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '($count)',
                    style: TextStyle(
                      fontSize: KreditTextSize.body,
                      fontWeight: FontWeight.w600,
                      color: kredit.textTertiary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatCOP(total),
                    style: TextStyle(
                      // Slightly larger than the section label/count next to
                      // it — this is a real money figure someone scans for
                      // ("how much is overdue"), not just decorative meta.
                      fontSize: KreditTextSize.body,
                      fontWeight: FontWeight.w700,
                      color: emphasized
                          ? kredit.textPrimary
                          : kredit.textSecondary,
                    ),
                  ),
                  if (collapsible) ...[
                    const SizedBox(width: 6),
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      size: KreditIconSize.small,
                      color: kredit.textTertiary,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (showChildren) Divider(height: 1, color: kredit.borderCard),
          if (showChildren)
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1)
                Divider(height: 1, color: kredit.borderCard),
            ],
        ],
      ),
    );
  }
}

class _InstallmentTile extends ConsumerWidget {
  final LoanCredit credit;
  final Installment inst;

  const _InstallmentTile({required this.credit, required this.inst});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final status = getInstallmentStatus(inst);
    final isOverdue = !inst.paid && status.state == InstallmentState.overdue;
    final mora = isOverdue ? estimateMoraInterest(credit, inst) : 0.0;
    final daysLate = isOverdue ? -getDaysDifference(inst.dueDate) : 0;
    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        if (inst.paid) {
          // Un-marking a paid cuota: no amount to ask for, just revert.
          ref
              .read(creditsProvider.notifier)
              .toggleInstallmentPaid(credit.id, inst.number);
        } else {
          _RegisterPaymentSheet.show(context, creditId: credit.id, inst: inst);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: inst.paid ? kredit.success : Colors.transparent,
                border: Border.all(
                  color: inst.paid ? kredit.success : kredit.textTertiary,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(KreditRadius.chip),
              ),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: inst.paid ? 1 : 0,
                child: const Icon(
                  Icons.check,
                  size: KreditIconSize.small,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cuota ${inst.number} — ${formatCOP(inst.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: KreditTextSize.body,
                      color: kredit.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Vence: ${formatDate(inst.dueDate)}',
                    style: TextStyle(
                      fontSize: KreditTextSize.body,
                      color: kredit.textSecondary,
                    ),
                  ),
                  if (mora > 0) ...[
                    const SizedBox(height: 3),
                    Tooltip(
                      message:
                          'Estimado, no el valor real: la mora exacta '
                          'depende de las políticas de cada entidad. '
                          'Confírmala con tu banco.',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: KreditIconSize.small,
                            color: kredit.warning,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '+ ~${formatCOP(mora)} de mora estimada '
                              '($daysLate días de atraso)',
                              style: TextStyle(
                                fontSize: KreditTextSize.body,
                                fontWeight: FontWeight.w600,
                                color: kredit.warning,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            StatusBadge(status: status),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet shown when tapping an unpaid cuota — lets the user register
/// the amount ACTUALLY paid, pre-filled with Kredit's calculated amount but
/// editable, for the (expected, common) case where the bank's real charge
/// differs slightly due to rounding, fees, or its own internal policies (see
/// the disclaimer in how_it_works_screen.dart). If the typed amount differs
/// from the calculated one, the difference is folded into the next unpaid
/// installment's principal — same mechanism as an "abono extra" — via
/// [registerInstallmentActualPayment]. Kept in the "sin cajas" visual
/// language (typography + Divider, no Container/border), matching
/// LoanAbonoSheet.
class _RegisterPaymentSheet extends ConsumerStatefulWidget {
  final String creditId;
  final Installment inst;

  const _RegisterPaymentSheet({required this.creditId, required this.inst});

  static Future<void> show(
    BuildContext context, {
    required String creditId,
    required Installment inst,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: _RegisterPaymentSheet(creditId: creditId, inst: inst),
        ),
      ),
    );
  }

  @override
  ConsumerState<_RegisterPaymentSheet> createState() =>
      _RegisterPaymentSheetState();
}

class _RegisterPaymentSheetState extends ConsumerState<_RegisterPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _amountCtrl = TextEditingController(
    text: CurrencyInputFormatter.format(widget.inst.amount),
  );
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  double? get _typedAmount =>
      double.tryParse(CurrencyInputFormatter.unformat(_amountCtrl.text));

  double get _diff => widget.inst.amount - (_typedAmount ?? widget.inst.amount);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final actualAmount = _typedAmount!;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(creditsProvider.notifier)
          .registerInstallmentPayment(
            widget.creditId,
            widget.inst.number,
            actualAmount,
          );
      if (mounted) {
        navigator.pop();
        final message = _diff.abs() < 0.5
            ? 'Cuota ${widget.inst.number} registrada como pagada'
            : 'Cuota ${widget.inst.number} registrada por '
                  '${formatCOP(actualAmount)} — la diferencia con el valor '
                  'calculado (${formatCOP(widget.inst.amount)}) se aplicó como '
                  'estimado a la siguiente cuota pendiente.';
        messenger.showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        messenger.showSnackBar(
          SnackBar(content: Text('No se pudo registrar el pago: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 0,
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
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: kredit.borderCard,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
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
                    Icons.check_circle_outline,
                    size: KreditIconSize.small,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Registrar Pago — Cuota ${widget.inst.number}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: kredit.borderCard),
            const SizedBox(height: 16),
            Text(
              'Valor calculado por Kredit: ${formatCOP(widget.inst.amount)}',
              style: TextStyle(
                fontSize: KreditTextSize.body,
                color: kredit.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'MONTO REALMENTE PAGADO',
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
              decoration: const InputDecoration(prefixText: '\$ '),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final n = double.tryParse(
                  CurrencyInputFormatter.unformat(v ?? ''),
                );
                if (n == null || n <= 0) return 'Ingresa un monto válido';
                return null;
              },
            ),
            if (_diff.abs() >= 0.5) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: KreditIconSize.small,
                    color: kredit.textTertiary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _diff > 0
                          ? 'Pagaste ${formatCOP(_diff)} menos de lo calculado — ese '
                                'faltante (estimado) se sumará al capital de la siguiente '
                                'cuota pendiente.'
                          : 'Pagaste ${formatCOP(-_diff)} más de lo calculado — ese '
                                'excedente (estimado) se restará del capital de la '
                                'siguiente cuota pendiente.',
                      style: TextStyle(
                        fontSize: KreditTextSize.body,
                        color: kredit.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Guardando...' : 'Registrar Pago'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
