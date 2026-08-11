import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/card_movement.dart';
import '../../data/models/credit.dart';
import '../../domain/card_calculator.dart';
import '../../domain/date_utils.dart';
import '../../theme/app_theme.dart';
import '../card_movement_sheet.dart';
import '../wallet_card.dart';
import 'stat_box.dart';

const _monthsEs = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

/// Movement history grouped by calendar month — lets a cardholder answer
/// "how much did I charge this month vs last" at a glance instead of
/// scanning a flat chronological list.
class MovementsTab extends ConsumerWidget {
  final CardCredit credit;

  const MovementsTab({super.key, required this.credit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final dates = getCardCycleDates(credit);
    final movements = credit.movements.reversed.toList();

    // Group by "YYYY-MM" of the movement date, preserving the
    // most-recent-first order already established above.
    final groups = <String, List<CardMovement>>{};
    for (final m in movements) {
      final key = m.date.length >= 7 ? m.date.substring(0, 7) : m.date;
      groups.putIfAbsent(key, () => []).add(m);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(KreditSpacing.card),
          child: Column(
            children: [
              // Available limit is the number a cardholder scans for first —
              // full-width hero tile, cutoff/due dates as supporting detail.
              StatBox(
                label: 'Límite Disponible',
                value: formatCurrency(getCardAvailableLimit(credit)),
                icon: Icons.account_balance_wallet_outlined,
                emphasized: true,
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: StatBox(
                      label: 'Próxima Fecha de Corte',
                      value: toDateStr(dates.nextCutoff),
                      icon: Icons.event_repeat,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatBox(
                      label: 'Fecha Límite de Pago',
                      value: toDateStr(dates.dueDate),
                      icon: Icons.event_available,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => CardMovementSheet.show(
                        context,
                        creditId: credit.id,
                        movementType: CardMovementType.charge,
                      ),
                      icon: const Icon(Icons.arrow_upward, size: 16),
                      label: const Text('Cargo/Compra'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => CardMovementSheet.show(
                        context,
                        creditId: credit.id,
                        movementType: CardMovementType.payment,
                      ),
                      icon: const Icon(Icons.arrow_downward, size: 16),
                      label: const Text('Registrar Pago'),
                    ),
                  ),
                ],
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
              style: TextStyle(fontWeight: FontWeight.w700, color: kredit.textPrimary),
            ),
          ),
        ),
        Expanded(
          child: movements.isEmpty
              ? Center(
                  child: Text('Sin movimientos registrados', style: TextStyle(color: kredit.textSecondary)),
                )
              : ListView(
                  padding: const EdgeInsets.all(KreditSpacing.card),
                  children: [
                    for (final entry in groups.entries)
                      _MonthGroup(monthKey: entry.key, movements: entry.value),
                  ],
                ),
        ),
      ],
    );
  }
}

class _MonthGroup extends StatelessWidget {
  final String monthKey; // "YYYY-MM"
  final List<CardMovement> movements;

  const _MonthGroup({required this.monthKey, required this.movements});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final parts = monthKey.split('-').map(int.tryParse).toList();
    final label = parts.length == 2 && parts[0] != null && parts[1] != null
        ? '${_monthsEs[(parts[1]! - 1).clamp(0, 11)]} ${parts[0]}'
        : monthKey;
    final charged = movements
        .where((m) => m.type != CardMovementType.payment)
        .fold(0.0, (s, m) => s + m.amount);
    final paid = movements
        .where((m) => m.type == CardMovementType.payment)
        .fold(0.0, (s, m) => s + m.amount);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: kredit.textSecondary,
                  ),
                ),
                const Spacer(),
                if (charged > 0)
                  Text(
                    '+${formatCurrency(charged)}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kredit.textPrimary),
                  ),
                if (charged > 0 && paid > 0) const SizedBox(width: 8),
                if (paid > 0)
                  Text(
                    '-${formatCurrency(paid)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          for (final m in movements) _MovementTile(movement: m),
        ],
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  final CardMovement movement;

  const _MovementTile({required this.movement});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final m = movement;
    final isCredit = m.type == CardMovementType.payment;
    final accent = Theme.of(context).colorScheme.primary;
    // Payments (money coming off the balance) get the accent color +
    // downward arrow; charges/interest/fees (money added to the balance)
    // share a neutral upward treatment so the sign of each line is legible
    // without reading the amount text.
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: (isCredit ? accent : kredit.textTertiary).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _iconFor(m.type),
                size: 18,
                color: isCredit ? accent : kredit.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _labelFor(m.type),
                    style: TextStyle(fontWeight: FontWeight.w600, color: kredit.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    m.note.isNotEmpty ? m.note : formatDate(m.date),
                    style: TextStyle(fontSize: 12, color: kredit.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${isCredit ? '-' : '+'}${formatCurrency(m.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
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
