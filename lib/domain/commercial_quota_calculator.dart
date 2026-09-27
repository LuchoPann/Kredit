import '../data/models/commercial_quota.dart';
import '../data/models/credit.dart';
import 'credit_calculator.dart';

/// How much of [quota]'s limit is still free, given every purchase
/// (LoanCredit) tagged with this quota's id. Fully reuses the existing
/// balance/unpaid logic from credit_calculator.dart — a cupo comercial is
/// never a new kind of financial math, just a grouping over LoanCredits.
///
/// Deliberately not clamped to zero: a negative result is real information
/// (the user is over their registered limit) and the UI decides how to
/// warn about it, not this function.
double quotaAvailable(CommercialQuota quota, List<LoanCredit> allLoans) {
  final usedByUnpaid = allLoans
      .where((l) => l.quotaId == quota.id)
      .where(creditHasUnpaid)
      .fold(0.0, (sum, p) => sum + getCreditRemainingBalance(p));
  return quota.limit - usedByUnpaid;
}
