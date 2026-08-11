import 'dart:math' as math;

import '../data/models/credit.dart';
import '../data/models/installment.dart';
import 'date_utils.dart';

/// Badge state for an installment, mirroring getInstallmentStatus() in
/// app.js (~L168).
enum InstallmentState { paid, overdue, warning, pending }

class InstallmentStatus {
  final String cssClass; // "badge-paid" | "badge-overdue" | "badge-pending"
  final String label;
  final InstallmentState state;

  const InstallmentStatus({
    required this.cssClass,
    required this.label,
    required this.state,
  });
}

/// Port of getInstallmentStatus (app.js ~L168-181).
InstallmentStatus getInstallmentStatus(Installment inst) {
  if (inst.paid) {
    return const InstallmentStatus(
      cssClass: 'badge-paid',
      label: 'Pagado',
      state: InstallmentState.paid,
    );
  }

  final daysDiff = getDaysDifference(inst.dueDate);
  if (daysDiff < 0) {
    return InstallmentStatus(
      cssClass: 'badge-overdue',
      label: 'Vencido (${daysDiff.abs()}d)',
      state: InstallmentState.overdue,
    );
  } else if (daysDiff <= 3) {
    return InstallmentStatus(
      cssClass: 'badge-overdue',
      label: daysDiff == 0 ? 'Hoy' : 'En ${daysDiff}d',
      state: InstallmentState.warning,
    );
  } else {
    return InstallmentStatus(
      cssClass: 'badge-pending',
      label: 'En ${daysDiff}d',
      state: InstallmentState.pending,
    );
  }
}

/// Adds [count] occurrences of [frequency] to [start], matching the
/// due-date stepping loop used identically in buildLoanInstallments and
/// generateDemoInstallments (app.js ~L396-404 / ~L119-127).
DateTime _stepDueDate(DateTime start, String frequency, int occurrenceIndex) {
  switch (frequency) {
    case CreditFrequency.weekly:
      return start.add(Duration(days: occurrenceIndex * 7));
    case CreditFrequency.biweekly:
      return start.add(Duration(days: occurrenceIndex * 14));
    case CreditFrequency.monthly:
    default:
      // DateTime's month rollover matches JS `Date.setMonth` semantics: if
      // the day-of-month overflows the target month, it rolls into the
      // following month(s). We replicate that by constructing directly.
      final totalMonth0 = (start.month - 1) + occurrenceIndex;
      final year = start.year + totalMonth0 ~/ 12;
      final month = totalMonth0 % 12 + 1;
      return DateTime(year, month, start.day);
  }
}

/// Port of buildLoanInstallments (app.js ~L388-418).
///
/// Splits each fixed quota into principal + interest so early payments can
/// waive the not-yet-accrued interest portion (see applyInstallmentPayment).
List<Installment> buildLoanInstallments({
  required double totalAmount,
  required int totalInstallments,
  required double quotaAmount,
  required String frequency,
  required String startDate,
}) {
  final start = parseDateStr(startDate);

  final totalInterest =
      math.max(0.0, (quotaAmount * totalInstallments) - totalAmount);
  final interestPerInstallment =
      totalInstallments > 0 ? totalInterest / totalInstallments : 0.0;
  final principalPerInstallment = quotaAmount - interestPerInstallment;

  final installments = <Installment>[];
  for (var i = 1; i <= totalInstallments; i++) {
    final due = _stepDueDate(start, frequency, i - 1);
    installments.add(Installment(
      number: i,
      dueDate: toDateStr(due),
      amount: quotaAmount,
      principal: principalPerInstallment,
      interest: interestPerInstallment,
      paid: false,
      paymentDate: null,
      interestWaived: false,
    ));
  }
  return installments;
}

/// Port of applyInstallmentPayment (app.js ~L627-648).
///
/// Paying BEFORE the due date waives the interest portion of that quota
/// entirely (it was never "causado"/accrued yet) — this only applies to
/// loan/cupo installments, never to credit cards, whose interest accrues on
/// the revolving balance independent of any single quota's due date.
void applyInstallmentPayment(Installment inst, bool paid) {
  if (paid) {
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final due = parseDateStr(inst.dueDate);
    final paidEarly = todayMidnight.isBefore(due);

    if (paidEarly && inst.interest > 0) {
      inst.interestWaived = true;
      inst.amount = inst.principal;
    }
    inst.paid = true;
    inst.paymentDate = DateTime.now().toIso8601String();
  } else {
    if (inst.interestWaived) {
      inst.amount = inst.principal + inst.interest;
      inst.interestWaived = false;
    }
    inst.paid = false;
    inst.paymentDate = null;
  }
}

/// Port of getCreditRemainingBalance for loan credits (app.js ~L1332-1336):
/// sum of the `amount` of every installment not yet marked paid.
double getLoanRemainingBalance(LoanCredit credit) {
  return credit.installments
      .where((i) => !i.paid)
      .fold(0.0, (sum, i) => sum + i.amount);
}

/// Marks every unpaid installment of [credit] as paid (markAllInstallments,
/// app.js ~L1596-1612), using the same early-payment interest-waiving rule.
void markAllInstallments(LoanCredit credit) {
  for (final inst in credit.installments) {
    if (!inst.paid) applyInstallmentPayment(inst, true);
  }
}

/// True if the loan still has any unpaid installment (drives the
/// active/completed filter, app.js ~L1049-1051 / ~L900).
bool loanHasUnpaid(LoanCredit credit) =>
    credit.installments.any((i) => !i.paid);
