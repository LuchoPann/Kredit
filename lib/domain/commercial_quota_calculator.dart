import '../data/models/commercial_quota.dart';
import '../data/models/credit.dart';
import 'credit_calculator.dart';
import 'loan_calculator.dart';

/// How much of [quota]'s limit is still free, given every purchase
/// (LoanCredit) tagged with this quota's id.
///
/// Uses [getLoanRemainingPrincipal] — interest is a cost of borrowing, not a
/// consumption of the credit limit. A $500k purchase on a $1M cupo leaves
/// $500k available regardless of how much interest has accrued on that purchase.
///
/// Deliberately not clamped to zero: a negative result is real information
/// (the user is over their registered limit) and the UI decides how to
/// warn about it, not this function.
double quotaAvailable(CommercialQuota quota, List<LoanCredit> allLoans) {
  final usedByUnpaid = allLoans
      .where((l) => l.quotaId == quota.id)
      .where(creditHasUnpaid)
      .fold(0.0, (sum, p) => sum + getLoanRemainingPrincipal(p));
  return quota.limit - usedByUnpaid;
}
