import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/card_movement.dart';
import '../../data/models/credit.dart';
import '../../domain/date_utils.dart';
import '../../providers/credits_provider.dart';
import '../../theme/app_theme.dart';
import '../card_movement_sheet.dart';
import '../../utils/credit_display_utils.dart';
import '../kredit_bottom_dialogs.dart';


/// Returns the closing cutoff date (YYYY-MM-DD) of the billing cycle that
/// contains [movementDate], given [cutoffDay]. Used to group movements by
/// extracto instead of calendar month.
///
/// Cutoff day opens the new period at 00:00, so a purchase on the cutoff day
/// itself belongs to the NEW extracto (the one that just opened).
/// If the movement falls strictly before [cutoffDay] of its month → the cycle
/// closes on cutoffDay of that same month.
/// If the movement falls on or after [cutoffDay] → the cycle closes on cutoffDay
/// of the FOLLOWING month.
String _cycleKeyFor(String movementDate, int cutoffDay) {
  if (movementDate.length < 10) return movementDate;
  final d = DateTime.tryParse(movementDate);
  if (d == null) return movementDate;
  final clampedCutoff = cutoffDay.clamp(1, 28);
  DateTime cycleEnd;
  if (d.day < clampedCutoff) {
    cycleEnd = DateTime(d.year, d.month, clampedCutoff);
  } else {
    final nextMonth = d.month == 12 ? 1 : d.month + 1;
    final nextYear = d.month == 12 ? d.year + 1 : d.year;
    cycleEnd = DateTime(nextYear, nextMonth, clampedCutoff);
  }
  return toDateStr(cycleEnd);
}

/// Movement history grouped by billing cycle (extracto) — each group shows
/// what the cardholder owes for one statement period, mirroring how the bank
/// presents the information.
class MovementsTab extends ConsumerWidget {
  final CardCredit credit;

  const MovementsTab({super.key, required this.credit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final movements = credit.movements.reversed.toList();

    // Group by billing cycle (extracto closing date), most-recent-first.
    final groups = <String, List<CardMovement>>{};
    for (final m in movements) {
      final key = _cycleKeyFor(m.date, credit.cutoffDay);
      groups.putIfAbsent(key, () => []).add(m);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(KreditSpacing.card),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => CardMovementSheet.show(
                    context,
                    creditId: credit.id,
                    movementType: CardMovementType.charge,
                  ),
                  icon: const Icon(Icons.shopping_bag_outlined, size: KreditIconSize.small),
                  label: const Text('Nueva compra'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => CardMovementSheet.show(
                    context,
                    creditId: credit.id,
                    movementType: CardMovementType.payment,
                  ),
                  icon: const Icon(Icons.payments_outlined, size: KreditIconSize.small),
                  label: const Text('Pagar tarjeta'),
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Movimientos',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: kredit.textPrimary,
              ),
            ),
          ),
        ),
        Expanded(
          child: movements.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: KreditIconSize.large,
                          color: kredit.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sin movimientos registrados',
                          style: TextStyle(
                            fontSize: KreditTextSize.body,
                            fontWeight: FontWeight.w600,
                            color: kredit.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Los cargos y pagos que registres aparecerán aquí.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: KreditTextSize.body,
                            color: kredit.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(KreditSpacing.card),
                  children: [
                    for (var i = 0; i < groups.entries.length; i++)
                      _CycleGroup(
                        creditId: credit.id,
                        cycleEndDate: groups.keys.elementAt(i),
                        cutoffDay: credit.cutoffDay,
                        movements: groups.values.elementAt(i),
                        allMovements: credit.movements,
                        collapsible: groups.length > 1,
                        initiallyExpanded: i == 0,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

const _monthsEs = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

/// Builds a human-readable "6 Sep – 5 Oct" range label for a billing cycle
/// that ends on [cycleEnd], given [cutoffDay].
String _cycleRangeLabel(DateTime cycleEnd, int cutoffDay) {
  final clampedCutoff = cutoffDay.clamp(1, 28);
  // Cycle start = cutoffDay of the previous month (cutoff day opens the new
  // period at 00:00; the prior period's last day is cutoffDay - 1).
  final prevMonth = cycleEnd.month == 1 ? 12 : cycleEnd.month - 1;
  final prevYear = cycleEnd.month == 1 ? cycleEnd.year - 1 : cycleEnd.year;
  final startDay = clampedCutoff;
  final endDay = clampedCutoff > 1 ? clampedCutoff - 1 : 28;
  final startMonthLabel = _monthsEs[(prevMonth - 1).clamp(0, 11)];
  final endMonthLabel = _monthsEs[(cycleEnd.month - 1).clamp(0, 11)];
  if (prevMonth == cycleEnd.month && prevYear == cycleEnd.year) {
    return '$startDay–$endDay $endMonthLabel ${cycleEnd.year}';
  }
  return '$startDay $startMonthLabel – $endDay $endMonthLabel ${cycleEnd.year}';
}

class _CycleGroup extends StatefulWidget {
  final String creditId;
  final String cycleEndDate; // "YYYY-MM-DD" of the cycle's closing cutoff
  final int cutoffDay;
  final List<CardMovement> movements;
  final List<CardMovement> allMovements;
  final bool collapsible;
  final bool initiallyExpanded;

  const _CycleGroup({
    required this.creditId,
    required this.cycleEndDate,
    required this.cutoffDay,
    required this.movements,
    required this.allMovements,
    this.collapsible = false,
    this.initiallyExpanded = true,
  });

  @override
  State<_CycleGroup> createState() => _CycleGroupState();
}

class _CycleGroupState extends State<_CycleGroup> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    final cycleEnd = DateTime.tryParse(widget.cycleEndDate);
    final label = cycleEnd != null
        ? _cycleRangeLabel(cycleEnd, widget.cutoffDay)
        : widget.cycleEndDate;

    final charges = widget.movements
        .where((m) => m.type != CardMovementType.payment)
        .fold(0.0, (s, m) => s + m.amount);
    final payments = widget.movements
        .where((m) => m.type == CardMovementType.payment)
        .fold(0.0, (s, m) => s + m.amount);
    final net = charges - payments;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Extracto header ───────────────────────────────────────────────
          GestureDetector(
            onTap: widget.collapsible
                ? () => setState(() => _expanded = !_expanded)
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: kredit.bgCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: KreditIconSize.small, color: kredit.textTertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EXTRACTO',
                          style: TextStyle(
                            fontSize: KreditTextSize.body,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: kredit.textTertiary,
                          ),
                        ),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: KreditTextSize.body,
                            fontWeight: FontWeight.w600,
                            color: kredit.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (charges > 0)
                        Text(
                          formatCOP(charges),
                          style: TextStyle(
                            fontSize: KreditTextSize.heading,
                            fontWeight: FontWeight.w800,
                            color: kredit.textPrimary,
                          ),
                        ),
                      if (payments > 0)
                        Text(
                          '–${formatCOP(payments)}',
                          style: TextStyle(
                            fontSize: KreditTextSize.body,
                            fontWeight: FontWeight.w600,
                            color: accent,
                          ),
                        ),
                      if (charges > 0 && payments > 0)
                        Text(
                          'Neto: ${formatCOP(net.abs())}',
                          style: TextStyle(
                            fontSize: KreditTextSize.body,
                            color: kredit.textTertiary,
                          ),
                        ),
                    ],
                  ),
                  if (widget.collapsible) ...[
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.expand_more,
                          size: KreditIconSize.small, color: kredit.textTertiary),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // ── Movement rows ─────────────────────────────────────────────────
          if (_expanded) ...[
            const SizedBox(height: 6),
            for (var i = 0; i < widget.movements.length; i++) ...[
              _MovementTile(
                creditId: widget.creditId,
                movement: widget.movements[i],
                movementIndex: widget.allMovements.indexOf(widget.movements[i]),
              ),
              if (i != widget.movements.length - 1)
                Divider(height: 1, color: kredit.borderCard),
            ],
          ],
        ],
      ),
    );
  }
}

class _MovementTile extends ConsumerWidget {
  final String creditId;
  final CardMovement movement;
  final int movementIndex;

  const _MovementTile({
    required this.creditId,
    required this.movement,
    required this.movementIndex,
  });

  Future<bool> _confirmDelete(BuildContext context) async {
    return showKreditConfirmSheet(
      context,
      title: 'Eliminar movimiento',
      message: '¿Eliminar "${_labelFor(movement.type)}" por ${formatCOP(movement.amount)}? El saldo de la tarjeta se recalculará. Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      isDanger: true,
      icon: Icons.delete_outline,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final m = movement;
    final isCredit = m.type == CardMovementType.payment;
    final accent = Theme.of(context).colorScheme.primary;
    // Payments (money coming off the balance) get the accent color +
    // downward arrow; charges/interest/fees (money added to the balance)
    // share a neutral upward treatment so the sign of each line is legible
    // without reading the amount text.
    return Dismissible(
      key: ValueKey('card-movement-$movementIndex-${m.date}-${m.amount}-${m.type}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) async {
        final messenger = ScaffoldMessenger.of(context);
        try {
          await ref.read(creditsProvider.notifier).deleteMovement(creditId, movementIndex);
          messenger.showSnackBar(
            const SnackBar(content: Text('Movimiento eliminado')),
          );
        } catch (e) {
          debugPrint('deleteMovement failed: $e');
          messenger.showSnackBar(
            const SnackBar(content: Text('No se pudo eliminar el movimiento.')),
          );
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.12),
        child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
      ),
      child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Icon(
            _iconFor(m.type),
            size: KreditIconSize.small,
            color: isCredit ? accent : kredit.textTertiary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _labelFor(m.type),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: KreditTextSize.body,
                    color: kredit.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  m.note.isNotEmpty ? m.note : formatDate(m.date),
                  style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (m.type == CardMovementType.charge && m.chargeInstallments != null && m.chargeInstallments! > 1)
                  Text(
                    '${m.chargeInstallments} cuotas',
                    style: TextStyle(fontSize: 11, color: kredit.textTertiary),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isCredit ? '-' : '+'}${formatCOP(m.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: KreditTextSize.body,
              color: isCredit ? accent : kredit.textPrimary,
            ),
          ),
        ],
      ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case CardMovementType.payment:
        return Icons.arrow_downward;
      case CardMovementType.interest:
        return Icons.percent;
      case CardMovementType.fee:
        return Icons.receipt_long;
      default:
        return Icons.arrow_upward;
    }
  }

  String _labelFor(String type) {
    switch (type) {
      case CardMovementType.payment:
        return 'Pago';
      case CardMovementType.interest:
        return 'Interés';
      case CardMovementType.fee:
        return 'Cuota de mantenimiento';
      default:
        return 'Cargo/Compra';
    }
  }
}
