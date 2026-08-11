import '../data/models/credit.dart';
import '../utils/credit_display_utils.dart';

/// Result of scanning all credits for the closest upcoming due date.
///
/// Mirrors the logic in `dashboard_screen.dart`'s private `_buildUpcomingItems`
/// (loans: earliest unpaid installment; cards: current cycle due date via
/// `getNextDueDate`), kept here as a small reusable helper so other
/// non-widget code (e.g. the home screen widget sync service) doesn't need
/// to duplicate or import screen-layer private functions.
class UpcomingPayment {
  final Credit credit;
  final DateTime dueDate;
  final double amount;

  UpcomingPayment({
    required this.credit,
    required this.dueDate,
    required this.amount,
  });
}

/// Finds the credit with the closest upcoming due date across [credits],
/// or null if none have a pending due date (e.g. all installments paid and
/// no card has an outstanding balance).
UpcomingPayment? findNextUpcomingPayment(List<Credit> credits) {
  UpcomingPayment? closest;

  for (final c in credits) {
    if (c is LoanCredit) {
      final unpaid = c.installments.where((i) => !i.paid).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      if (unpaid.isEmpty) continue;
      final first = unpaid.first;
      final due = DateTime.parse(first.dueDate);
      if (closest == null || due.isBefore(closest.dueDate)) {
        closest = UpcomingPayment(credit: c, dueDate: due, amount: first.amount);
      }
    } else if (c is CardCredit && c.currentBalance > 0) {
      final due = getNextDueDate(c);
      if (due == null) continue;
      if (closest == null || due.isBefore(closest.dueDate)) {
        closest = UpcomingPayment(
          credit: c,
          dueDate: due,
          amount: c.currentBalance,
        );
      }
    }
  }

  return closest;
}
