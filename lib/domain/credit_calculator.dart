import '../data/models/credit.dart';
import 'card_calculator.dart';
import 'loan_calculator.dart';

/// Type-dispatching port of getCreditRemainingBalance (app.js ~L1332-1336):
/// revolving cards use their tracked currentBalance; loan/cupo credits sum
/// the amount of every unpaid installment.
double getCreditRemainingBalance(Credit credit) {
  if (credit is CardCredit) return getCardRemainingBalance(credit);
  if (credit is LoanCredit) return getLoanRemainingBalance(credit);
  throw ArgumentError('Unknown credit subtype: ${credit.runtimeType}');
}

/// True if [credit] still has outstanding debt — drives the active/completed
/// filter (app.js ~L1049-1051, ~L900, ~L1524).
bool creditHasUnpaid(Credit credit) {
  if (credit is CardCredit) return credit.currentBalance > 0;
  if (credit is LoanCredit) return loanHasUnpaid(credit);
  throw ArgumentError('Unknown credit subtype: ${credit.runtimeType}');
}

/// Total actually borrowed/invested (renderSettings, app.js ~L1529-1535):
/// loans use the financed amount; cards use the sum of real charges ever
/// made (their limit is just a ceiling, not money spent).
double getTotalBorrowed(List<Credit> credits) {
  var sum = 0.0;
  for (final c in credits) {
    if (c is CardCredit) {
      final charged = c.movements
          .where((m) => m.type == 'charge')
          .fold(0.0, (s, m) => s + m.amount);
      sum += charged;
    } else if (c is LoanCredit) {
      sum += c.totalAmount;
    }
  }
  return sum;
}
