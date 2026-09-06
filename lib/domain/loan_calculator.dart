import 'dart:math' as math;

import '../data/models/credit.dart';
import '../data/models/installment.dart';
import '../data/models/loan_abono.dart';
import 'date_utils.dart';
import 'interest_rate.dart';

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

/// One step of a French-amortization schedule: how much of a given quota
/// pays down principal vs. how much is interest on the outstanding balance.
class _FrenchStep {
  final double principal;
  final double interest;
  const _FrenchStep(this.principal, this.interest);
}

/// Pure French ("sistema francés") amortization engine: cuota fija, interés
/// decreciente, principal creciente — the standard model for Colombian
/// consumer/libre-inversión credit, replacing the old linear interest split.
///
/// For each of [count] periods: `interest = balance * periodRate`,
/// `principal = quotaAmount - interest`, `balance -= principal`. When
/// [periodRate] is 0 this degenerates to the old zero-interest behavior
/// (principal == quotaAmount every period).
///
/// Decision — quota insufficient to cover interest (negative amortization,
/// i.e. `quotaAmount < balance * periodRate`): rather than let the schedule
/// run away (balance growing forever, `count` still bounded so it can never
/// hang, but the numbers would be nonsensical), `principal` is capped at 0
/// for that period. The quota is treated as "interest-only" that period and
/// the balance simply doesn't shrink; whatever isn't recovered gets rolled
/// into later periods and ultimately absorbed by the final settling step
/// below. This never produces a negative principal or an infinite loan —
/// it's a soft, visible symptom (the schedule won't reach $0 through normal
/// principal reduction) rather than a crash or a silently wrong number.
///
/// The final period always settles the loan to exactly $0: its principal is
/// set to whatever balance remains (not `quotaAmount - interest`), so
/// rounding never leaves a residual owed or overpaid.
List<_FrenchStep> _amortizeFrench({
  required double principal,
  required int count,
  required double quotaAmount,
  required double periodRate,
}) {
  final steps = <_FrenchStep>[];
  var balance = principal;
  for (var i = 0; i < count; i++) {
    final isLast = i == count - 1;
    final interest = periodRate > 0 ? balance * periodRate : 0.0;
    double p;
    if (isLast) {
      p = balance;
    } else {
      p = quotaAmount - interest;
      if (p < 0) p = 0; // see decision note above
    }
    balance -= p;
    if (balance < 0) balance = 0;
    steps.add(_FrenchStep(p, interest));
  }
  return steps;
}

/// Builds a loan's installment schedule using real French amortization
/// (replaces the old linear-interest port of app.js's buildLoanInstallments,
/// app.js ~L388-418): interest is computed on the outstanding balance each
/// period, so it decreases over time while the principal portion grows,
/// rather than splitting a flat total interest evenly across every quota.
///
/// [interestRate]/[interestRateType] follow the same convention as
/// `CardCredit` (see `interest_rate.dart`): the rate as the lender quotes it
/// (E.A./E.M./nominal monthly), normalized here to the correct per-period
/// rate for [frequency] via `periodicRateFrom`. `interestRate == 0` (the
/// default) falls back to the old zero-interest behavior.
///
/// Splits each fixed quota into principal + interest so early payments can
/// waive the not-yet-accrued interest portion (see applyInstallmentPayment).
List<Installment> buildLoanInstallments({
  required double totalAmount,
  required int totalInstallments,
  required double quotaAmount,
  required String frequency,
  required String startDate,
  double interestRate = 0,
  String interestRateType = InterestRateType.effectiveAnnual,
}) {
  final start = parseDateStr(startDate);
  final periodRate = periodicRateFrom(interestRate, interestRateType, frequency);
  final steps = _amortizeFrench(
    principal: totalAmount,
    count: totalInstallments,
    quotaAmount: quotaAmount,
    periodRate: periodRate,
  );

  final installments = <Installment>[];
  for (var i = 1; i <= totalInstallments; i++) {
    final due = _stepDueDate(start, frequency, i - 1);
    final step = steps[i - 1];
    installments.add(Installment(
      number: i,
      dueDate: toDateStr(due),
      amount: step.principal + step.interest,
      principal: step.principal,
      interest: step.interest,
      paid: false,
      paymentDate: null,
      interestWaived: false,
    ));
  }
  return installments;
}

/// Re-derives the NOT-yet-paid installments of [credit] with the French
/// amortization engine, continuing from the actual remaining principal
/// (`totalAmount` minus principal already paid off) — used whenever the
/// user edits the quota, the interest rate (or its periodicity), or the
/// total financed amount of an existing loan. Already-paid installments are
/// left completely untouched (their historical principal/interest split
/// stands). Generalizes the old `reprorateUnpaidInstallments` (formerly in
/// edit_credit_sheet.dart), which only handled a quota change under the
/// linear-interest model.
///
/// No-op if none of the optional new values actually differ from the
/// credit's current ones.
void reprorateUnpaidInstallments(
  LoanCredit credit, {
  double? newQuota,
  double? newInterestRate,
  String? newInterestRateType,
  double? newTotalAmount,
}) {
  final quotaChanged = newQuota != null && newQuota != credit.quotaAmount;
  final rateChanged = newInterestRate != null && newInterestRate != credit.interestRate;
  final rateTypeChanged =
      newInterestRateType != null && newInterestRateType != credit.interestRateType;
  final totalChanged = newTotalAmount != null && newTotalAmount != credit.totalAmount;
  if (!quotaChanged && !rateChanged && !rateTypeChanged && !totalChanged) return;

  if (newQuota != null) credit.quotaAmount = newQuota;
  if (newInterestRate != null) credit.interestRate = newInterestRate;
  if (newInterestRateType != null) credit.interestRateType = newInterestRateType;
  if (newTotalAmount != null) credit.totalAmount = newTotalAmount;

  final paid = credit.installments.where((i) => i.paid).toList();
  final unpaid = credit.installments.where((i) => !i.paid).toList()
    ..sort((a, b) => a.number.compareTo(b.number));
  if (unpaid.isEmpty) return;

  final paidPrincipal = paid.fold(0.0, (s, i) => s + i.principal);
  final remainingPrincipal = math.max(0.0, credit.totalAmount - paidPrincipal);
  final periodRate =
      periodicRateFrom(credit.interestRate, credit.interestRateType, credit.frequency);

  final steps = _amortizeFrench(
    principal: remainingPrincipal,
    count: unpaid.length,
    quotaAmount: credit.quotaAmount,
    periodRate: periodRate,
  );

  for (var i = 0; i < unpaid.length; i++) {
    final inst = unpaid[i];
    final step = steps[i];
    inst.principal = step.principal;
    inst.interest = step.interest;
    inst.amount = step.principal + step.interest;
    inst.interestWaived = false;
  }
}

/// Recomputes every installment of [credit] from scratch using the French
/// amortization engine, based on its base fields (totalAmount, quotaAmount,
/// totalInstallments, frequency, startDate, interestRate/Type) — preserving
/// which installments were already marked paid (matched by installment
/// `number`) along with their paymentDate/interestWaived flag.
///
/// Migration approach: this app has no installed base of real user data yet
/// (only local/demo credits), so rather than a one-shot schema-version
/// migration with "old vs. new engine" bookkeeping, this recomputation is
/// simply idempotent and deterministic — running it again on installments
/// already produced by the French engine reproduces the exact same numbers.
/// That lets `CreditsNotifier.build()` call it unconditionally on every app
/// load (mirroring `accrueCardCredit`'s always-run pattern) and persist only
/// when the result actually changed, instead of needing any stored
/// "migrated" flag.
List<Installment> recomputeLoanInstallments(LoanCredit credit) {
  final fresh = buildLoanInstallments(
    totalAmount: credit.totalAmount,
    totalInstallments: credit.totalInstallments,
    quotaAmount: credit.quotaAmount,
    frequency: credit.frequency,
    startDate: credit.startDate,
    interestRate: credit.interestRate,
    interestRateType: credit.interestRateType,
  );

  final byNumber = {for (final i in credit.installments) i.number: i};
  for (final inst in fresh) {
    final old = byNumber[inst.number];
    if (old != null && old.paid) {
      inst.paid = true;
      inst.paymentDate = old.paymentDate;
      if (old.interestWaived) {
        inst.interestWaived = true;
        inst.amount = inst.principal;
      }
    }
  }
  return fresh;
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

/// Applies a manual extra payment ("abono extra") to [loan], reducing debt
/// outside the normal fixed-installment schedule (inspired by the UX idea —
/// not code — of MyExpenses' manual transaction entry).
///
/// Strategy (deliberately simple, NOT a full reamortization of the credit):
/// 1. Take the unpaid installments in chronological order (by number).
/// 2. `quotasSkipped = floor(amount / quotaAmount)` whole quotas get marked
///    paid via [applyInstallmentPayment], reusing its existing early-payment
///    interest-waiving rule (today vs. the installment's due date) rather
///    than inventing a separate discount rule here.
/// 3. Any remainder (`amount - quotasSkipped * quotaAmount`) that doesn't
///    reach a full quota is applied directly against the *principal* of the
///    next unpaid installment (if one remains): its `principal` is reduced
///    by the remainder and its `amount` recomputed as
///    `principal + interest`, leaving the already-accrued interest portion
///    untouched. This is an approximation — it does not reamortize the rest
///    of the schedule to reflect the lower principal, it just shrinks that
///    one upcoming quota. If the remainder exceeds that installment's
///    principal, it's capped so the principal never goes negative (no
///    complex "credit in favor" carry-over is generated).
/// 4. If [amount] is greater than or equal to the loan's total outstanding
///    balance ([getLoanRemainingBalance]), the abono is capped to exactly
///    that balance instead of silently discarding the surplus: every unpaid
///    installment is marked paid via [markAllInstallments] (settling the
///    loan at $0), and the returned [LoanAbono.amount] reflects the amount
///    actually applied (the old balance), not the amount requested — the
///    caller can compare it against [LoanAbono.requestedAmount] /
///    [LoanAbono.wasCapped] to tell the user their loan was paid off with
///    money left over.
///
/// Returns the [LoanAbono] record the caller should append to
/// `loan.abonos` and persist.
/// Applies a signed principal adjustment to the earliest of [unpaid]
/// (chronologically first, i.e. `unpaid.first`) — shared by the abono
/// remainder step in [applyLoanAbono] and by
/// [registerInstallmentActualPayment] for over/under-payment relative to the
/// calculated cuota. A positive [amount] reduces that installment's
/// principal (money already covered ahead of schedule); a negative amount
/// increases it (a shortfall still owed). The reduction is capped so
/// principal never goes negative; a no-op if [unpaid] is empty.
void _applyPrincipalAdjustment(List<Installment> unpaid, double amount) {
  if (unpaid.isEmpty || amount == 0) return;
  final next = unpaid.first;
  if (amount > 0) {
    final reduction = math.min(amount, next.principal);
    next.principal -= reduction;
  } else {
    next.principal += -amount;
  }
  next.amount = next.principal + next.interest;
}

/// Registers that installment [inst] of [credit] was actually paid for
/// [actualAmount] instead of its calculated amount — e.g. the bank's real
/// statement charged a slightly different number due to rounding, fees, or
/// its own internal policies (see the "no es el número exacto del banco"
/// disclaimer in how_it_works_screen.dart). Marks the installment paid
/// (reusing [applyInstallmentPayment]'s existing early-payment
/// interest-waiving rule), and folds the DIFFERENCE between what Kredit
/// calculated and what was actually paid into the next unpaid installment's
/// principal — same mechanism as the abono remainder step in
/// [applyLoanAbono] — so paying less than expected increases what's still
/// owed going forward, and paying more reduces it, instead of the
/// discrepancy silently vanishing.
///
/// This is an approximation, same caveat as [applyLoanAbono]: it nudges only
/// the very next installment rather than reamortizing the whole remaining
/// schedule — treat the result as an estimate, not a bank-verified number.
void registerInstallmentActualPayment(
  LoanCredit credit,
  Installment inst,
  double actualAmount,
) {
  final calculatedAmount = inst.amount;
  applyInstallmentPayment(inst, true);
  final diff = calculatedAmount - actualAmount;
  if (diff == 0) return;
  final unpaid = credit.installments.where((i) => !i.paid).toList()
    ..sort((a, b) => a.number.compareTo(b.number));
  _applyPrincipalAdjustment(unpaid, diff);
}

LoanAbono applyLoanAbono(LoanCredit loan, double amount, {String note = ''}) {
  if (amount <= 0) {
    throw ArgumentError('El monto del abono debe ser mayor a cero');
  }

  final unpaid = loan.installments.where((i) => !i.paid).toList()
    ..sort((a, b) => a.number.compareTo(b.number));
  if (unpaid.isEmpty) {
    throw ArgumentError('No hay cuotas pendientes para aplicar el abono');
  }

  final remainingBalance = getLoanRemainingBalance(loan);
  if (amount >= remainingBalance) {
    markAllInstallments(loan);
    return LoanAbono(
      date: toDateStr(DateTime.now()),
      amount: remainingBalance,
      note: note,
      installmentsSkipped: unpaid.length,
      requestedAmount: amount,
    );
  }

  final quotasSkipped =
      loan.quotaAmount > 0 ? (amount / loan.quotaAmount).floor() : 0;
  final clampedSkip = math.min(quotasSkipped, unpaid.length);

  for (var i = 0; i < clampedSkip; i++) {
    applyInstallmentPayment(unpaid[i], true);
  }

  final remainder = amount - clampedSkip * loan.quotaAmount;
  if (remainder > 0 && clampedSkip < unpaid.length) {
    _applyPrincipalAdjustment(unpaid.sublist(clampedSkip), remainder);
  }

  return LoanAbono(
    date: toDateStr(DateTime.now()),
    amount: amount,
    note: note,
    installmentsSkipped: clampedSkip,
  );
}

/// Best-effort reversal of a previously-applied [abono], for correcting a
/// mis-registered "abono extra". Lets a user delete the abono record and get
/// the schedule back in a sane state without a full reamortization engine.
///
/// - If the abono fully settled the loan ([LoanAbono.wasCapped] or its
///   amount matches what [applyLoanAbono] applies when it caps to the
///   remaining balance), every installment [markAllInstallments] marked
///   paid is unmarked.
/// - Otherwise, the highest-numbered currently-paid installments (up to
///   [LoanAbono.installmentsSkipped]) are unmarked, since abonos always pay
///   off the lowest-numbered unpaid installments first — so the most
///   recently-applied abono's skips are the highest-numbered paid ones.
///
/// This is an approximation, not an exact undo: it does not restore a
/// partial principal reduction the abono may have applied to the next
/// installment after its full skips (that adjustment isn't tracked
/// separately from the installment's current state), and if other
/// abonos/manual payments happened after this one, unmarking "the highest
/// paid installments" may not be exactly the ones this abono touched. It is
/// intended for correcting an abono shortly after registering it, not for
/// rewriting arbitrary history.
void reverseLoanAbono(LoanCredit loan, LoanAbono abono) {
  if (abono.wasCapped) {
    for (final inst in loan.installments) {
      inst.paid = false;
      inst.paymentDate = null;
      inst.interestWaived = false;
    }
    return;
  }

  final paid = loan.installments.where((i) => i.paid).toList()
    ..sort((a, b) => b.number.compareTo(a.number));
  var toUnmark = abono.installmentsSkipped;
  for (final inst in paid) {
    if (toUnmark <= 0) break;
    inst.paid = false;
    inst.paymentDate = null;
    inst.interestWaived = false;
    toUnmark--;
  }
}
