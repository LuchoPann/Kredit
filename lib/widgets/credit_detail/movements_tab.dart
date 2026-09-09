import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/card_movement.dart';
import '../../data/models/credit.dart';
import '../../domain/card_calculator.dart';
import '../../domain/date_utils.dart';
import '../../providers/credits_provider.dart';
import '../../theme/app_theme.dart';
import '../card_movement_sheet.dart';
import '../../utils/credit_display_utils.dart';
import 'stat_box.dart';

const _monthsEs = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
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
                value: formatCOP(getCardAvailableLimit(credit)),
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
                      icon: const Icon(Icons.arrow_upward, size: KreditIconSize.small),
                      label: const Text('Cargo/Compra'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    // Filled/primary here, matching the same priority given
                    // to "Registrar Pago" in summary_tab.dart's quick
                    // actions — paying down the balance is the recommended
                    // action, registering a new charge is secondary.
                    child: FilledButton.icon(
                      onPressed: () => CardMovementSheet.show(
                        context,
                        creditId: credit.id,
                        movementType: CardMovementType.payment,
                      ),
                      icon: const Icon(Icons.arrow_downward, size: KreditIconSize.small),
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
                            fontSize: KreditTextSize.caption,
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
                    for (final entry in groups.entries)
                      _MonthGroup(
                        creditId: credit.id,
                        monthKey: entry.key,
                        movements: entry.value,
                        allMovements: credit.movements,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _MonthGroup extends StatelessWidget {
  final String creditId;
  final String monthKey; // "YYYY-MM"
  final List<CardMovement> movements;
  final List<CardMovement> allMovements;

  const _MonthGroup({
    required this.creditId,
    required this.monthKey,
    required this.movements,
    required this.allMovements,
  });

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
                    fontSize: KreditTextSize.caption,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: kredit.textSecondary,
                  ),
                ),
                const Spacer(),
                if (charged > 0)
                  Text(
                    '+${formatCOP(charged)}',
                    style: TextStyle(
                      fontSize: KreditTextSize.caption,
                      fontWeight: FontWeight.w700,
                      color: kredit.textPrimary,
                    ),
                  ),
                if (charged > 0 && paid > 0) const SizedBox(width: 8),
                if (paid > 0)
                  Text(
                    '-${formatCOP(paid)}',
                    style: TextStyle(
                      fontSize: KreditTextSize.caption,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          for (var i = 0; i < movements.length; i++) ...[
            _MovementTile(
              creditId: creditId,
              movement: movements[i],
              movementIndex: allMovements.indexOf(movements[i]),
            ),
            if (i != movements.length - 1)
              Divider(height: 1, color: kredit.borderCard),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar movimiento'),
        content: Text(
          '¿Eliminar "${_labelFor(movement.type)}" por ${formatCOP(movement.amount)}? '
          'El saldo de la tarjeta se recalculará. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    return confirmed == true;
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
                  style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
