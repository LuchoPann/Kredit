import 'dart:math' as math;

import '../data/models/credit.dart';
import '../data/models/installment.dart';
import '../data/models/loan_abono.dart';
import 'date_utils.dart';
import 'interest_rate.dart';

/// Badge state for an installment, mirroring getInstallmentStatus() in
/// app.js (~L168).
enum InstallmentState { paid, overdue, warning, pending }

/// The two real-world strategies a bank offers after an abono a capital —
/// see [applyLoanAbono].
enum AbonoStrategy {
  /// Same fixed quota, fewer remaining installments (the loan ends sooner).
  reducirPlazo,

  /// Same number of remaining installments, a lower fixed quota (each
  /// future cuota gets cheaper).
  reducirCuota,
}

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
/// IMPORTANT — no longer unconditionally safe: this rebuilds the ENTIRE
/// schedule from the base fields, discarding any manual adjustment that
/// isn't reflected in them (e.g. applyLoanAbono's reamortization, or
/// registerInstallmentActualPayment's principal nudge to the next
/// installment). Callers MUST check `credit.scheduleManuallyAdjusted` first
/// and skip this call entirely when it's true — see
/// `CreditsNotifier.build()` in lib/providers/credits_provider.dart, which
/// only calls this for loans where the flag is still false. It remains
/// idempotent and deterministic for loans where the flag is false (running
/// it again on installments already produced by the French engine
/// reproduces the exact same numbers), which is what let earlier versions
/// of this app call it unconditionally on every load before any stored
/// "migrated"/"adjusted" flag existed.
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
  credit.scheduleManuallyAdjusted = true;
  final unpaid = credit.installments.where((i) => !i.paid).toList()
    ..sort((a, b) => a.number.compareTo(b.number));

  if (diff > 0 && unpaid.isEmpty) {
    // Paid LESS than calculated on what was the last pending installment —
    // there's no next installment left to fold the shortfall into. Losing
    // it silently would mark the loan "fully paid" at $0 despite money
    // still being owed, so instead append a new installment carrying the
    // shortfall as pending principal (no interest — this is just an
    // unresolved balance, not a new accrual period).
    final last =
        credit.installments.reduce((a, b) => a.number > b.number ? a : b);
    credit.installments.add(Installment(
      number: last.number + 1,
      dueDate: inst.dueDate,
      amount: diff,
      principal: diff,
      interest: 0,
      paid: false,
    ));
    return;
  }
  // diff < 0 (paid MORE than calculated) with no installment left to apply
  // the surplus to: discarded, same as applyLoanAbono does when a payment
  // covers more than the outstanding balance — no negative cuota is ever
  // created.
  _applyPrincipalAdjustment(unpaid, diff);
}

/// Standard PMT (fixed-installment) formula: the periodic payment that
/// amortizes [principal] over [count] periods at [periodRate] per period.
/// Degenerates to a straight division when [periodRate] is 0 (matches
/// `_amortizeFrench`'s zero-rate behavior).
double _pmt(double principal, int count, double periodRate) {
  if (count <= 0) return 0;
  if (periodRate <= 0) return principal / count;
  final factor = math.pow(1 + periodRate, count);
  return principal * periodRate * factor / (factor - 1);
}

/// Inverse of [_pmt]: given a FIXED [quotaAmount] and [periodRate], how many
/// periods does it take to amortize [principal] down to (approximately) $0?
/// Returns `null` if the quota doesn't even cover one period's interest
/// (negative amortization — the balance would never shrink) or if it would
/// take an unreasonable number of periods (nothing sane converges within
/// [maxPeriods]), so the caller can fall back to a safer strategy instead of
/// hanging or producing nonsense.
int? _periodsToPayoff(
  double principal,
  double quotaAmount,
  double periodRate, {
  int maxPeriods = 1200,
}) {
  if (principal <= 0) return 0;
  var balance = principal;
  for (var n = 1; n <= maxPeriods; n++) {
    final interest = periodRate > 0 ? balance * periodRate : 0.0;
    final principalPortion = quotaAmount - interest;
    if (principalPortion <= 0) return null;
    balance -= principalPortion;
    if (balance <= 1e-6) return n;
  }
  return null;
}

/// Reamortizes [unpaid] in place against [newPrincipal], keeping the same
/// number of installments but deriving a fresh (lower) fixed quota via
/// [_pmt] — the "reducir cuota" strategy. Updates `loan.quotaAmount` to the
/// new value so it stays consistent with what the schedule now reflects.
void _reamortizeReducirCuota(
  LoanCredit loan,
  List<Installment> unpaid,
  double newPrincipal,
  double periodRate,
) {
  final newQuota = _pmt(newPrincipal, unpaid.length, periodRate);
  loan.quotaAmount = newQuota;
  final steps = _amortizeFrench(
    principal: newPrincipal,
    count: unpaid.length,
    quotaAmount: newQuota,
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

/// Applies a manual extra payment ("abono extra") to [loan], reducing debt
/// outside the normal fixed-installment schedule (inspired by the UX idea —
/// not code — of MyExpenses' manual transaction entry).
///
/// Real reamortization, mirroring what a Colombian bank actually offers
/// after an abono a capital:
/// 1. If [amount] covers the entire outstanding balance
///    ([getLoanRemainingBalance]), behavior is unchanged from before: the
///    abono is capped to that balance, every unpaid installment is marked
///    paid via [markAllInstallments], and [LoanAbono.wasCapped] /
///    [LoanAbono.requestedAmount] tell the caller if there was a surplus.
/// 2. Otherwise, the new outstanding PRINCIPAL is
///    `(totalAmount - principal already paid off) - amount` — the full
///    abono comes straight off capital, no "whole quotas that fit" carve-out
///    like the old approximation used.
/// 3. [strategy] decides how the remaining unpaid installments are
///    rebuilt from that lower principal:
///    - [AbonoStrategy.reducirCuota]: same number of installments, a fresh
///      (lower) fixed quota derived via the PMT formula — every future cuota
///      gets cheaper. Reuses the same `_amortizeFrench` engine
///      [reprorateUnpaidInstallments] uses.
///    - [AbonoStrategy.reducirPlazo]: same fixed quota (`loan.quotaAmount`
///      unchanged), fewer installments — the minimum period count that
///      amortizes the new principal to $0 is found (inverse-PMT search) and
///      any now-unneeded trailing installments are dropped from
///      `loan.installments`. Falls back to [AbonoStrategy.reducirCuota] if
///      that quota can't even cover the first period's interest (or would
///      take an unreasonable number of periods) — never crashes, never
///      hangs, never produces a schedule that doesn't reach $0.
/// 4. Already-paid installments are left completely untouched, same as
///    [reprorateUnpaidInstallments] already does.
///
/// Returns the [LoanAbono] record the caller should append to
/// `loan.abonos` and persist. `installmentsSkipped` reflects how many
/// installments were actually dropped from the schedule ([reducirPlazo]
/// only) — it is 0 for [reducirCuota], since that strategy keeps the same
/// count of installments (each just cheaper).
LoanAbono applyLoanAbono(
  LoanCredit loan,
  double amount, {
  String note = '',
  AbonoStrategy strategy = AbonoStrategy.reducirCuota,
}) {
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
    loan.scheduleManuallyAdjusted = true;
    return LoanAbono(
      date: toDateStr(DateTime.now()),
      amount: remainingBalance,
      note: note,
      installmentsSkipped: unpaid.length,
      requestedAmount: amount,
    );
  }

  final paidPrincipal =
      loan.installments.where((i) => i.paid).fold(0.0, (s, i) => s + i.principal);
  final currentRemainingPrincipal =
      math.max(0.0, loan.totalAmount - paidPrincipal);
  final newRemainingPrincipal =
      math.max(0.0, currentRemainingPrincipal - amount);
  final periodRate =
      periodicRateFrom(loan.interestRate, loan.interestRateType, loan.frequency);

  var installmentsDropped = 0;
  if (strategy == AbonoStrategy.reducirPlazo) {
    final n = _periodsToPayoff(
      newRemainingPrincipal,
      loan.quotaAmount,
      periodRate,
    );
    if (n != null && n > 0) {
      final clampedN = math.min(n, unpaid.length);
      final keep = unpaid.sublist(0, clampedN);
      final drop = unpaid.sublist(clampedN);
      final steps = _amortizeFrench(
        principal: newRemainingPrincipal,
        count: clampedN,
        quotaAmount: loan.quotaAmount,
        periodRate: periodRate,
      );
      for (var i = 0; i < keep.length; i++) {
        final inst = keep[i];
        final step = steps[i];
        inst.principal = step.principal;
        inst.interest = step.interest;
        inst.amount = step.principal + step.interest;
        inst.interestWaived = false;
      }
      if (drop.isNotEmpty) {
        loan.installments.removeWhere((inst) => drop.contains(inst));
        installmentsDropped = drop.length;
      }
    } else {
      // Fallback: the fixed quota doesn't even cover the first period's
      // interest (or the search didn't converge) — reducing the term isn't
      // possible without an absurd/negative-amortizing schedule, so fall
      // back to the always-safe reducirCuota strategy instead of crashing.
      _reamortizeReducirCuota(loan, unpaid, newRemainingPrincipal, periodRate);
    }
  } else {
    _reamortizeReducirCuota(loan, unpaid, newRemainingPrincipal, periodRate);
  }

  loan.scheduleManuallyAdjusted = true;
  return LoanAbono(
    date: toDateStr(DateTime.now()),
    amount: amount,
    note: note,
    installmentsSkipped: installmentsDropped,
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

/// Illustrative usury-rate ceiling (E.A.) reused from the same 35% threshold
/// `rateInconsistencyWarning` in `interest_rate.dart` already uses as its
/// "clearly past the real Superfinanciera usury ceiling" cutoff — see that
/// function's doc comment for the sourcing. Reused here (rather than
/// introducing a second magic number) as the cap on estimated mora rates.
const double _usuryCeilingEA = 35;

/// Estimates the extra "interés moratorio" (late-payment interest) a bank
/// would typically charge on an overdue installment, ON TOP OF the ordinary
/// amount already in `inst.amount`. This is a SIMPLIFIED ESTIMATE ONLY:
///
/// - It applies simple (non-compounded) daily interest on the installment's
///   outstanding amount, at a daily mora rate derived from the loan's
///   ordinary rate scaled by [moraRateMultiplier] (banks commonly charge a
///   materially higher rate on mora than on the ordinary balance) and capped
///   at [_usuryCeilingEA] (E.A.) converted to a daily rate — real regulated
///   lenders cannot legally charge more than the usury ceiling even on
///   mora.
/// - Real banks differ: some compound the mora daily or monthly, some add
///   fixed collection/cobranza fees on top, some apply a flat mora rate set
///   by policy rather than a multiple of the ordinary rate. This function
///   does NOT attempt to replicate any specific bank's exact formula — it
///   is meant purely as an illustrative "heads up, mora is probably costing
///   you around this much" estimate, never as a bank-verified figure (same
///   "no es el número exacto del banco" caveat as the rest of the
///   amortization engine).
///
/// Returns 0 if [inst] is already paid, or if it isn't overdue as of [asOf]
/// (defaults to `DateTime.now()`).
double estimateMoraInterest(
  LoanCredit loan,
  Installment inst, {
  DateTime? asOf,
  double moraRateMultiplier = 1.5,
}) {
  if (inst.paid) return 0.0;

  final now = asOf ?? DateTime.now();
  final nowMidnight = DateTime(now.year, now.month, now.day);
  final due = parseDateStr(inst.dueDate);
  final dueMidnight = DateTime(due.year, due.month, due.day);
  if (!nowMidnight.isAfter(dueMidnight)) return 0.0;

  final daysLate = nowMidnight.difference(dueMidnight).inDays;

  final ordinaryDaily = dailyRateFrom(loan.interestRate, loan.interestRateType);
  final usuryDailyCeiling =
      dailyRateFrom(_usuryCeilingEA, InterestRateType.effectiveAnnual);
  var moraDaily = ordinaryDaily * moraRateMultiplier;
  if (moraDaily > usuryDailyCeiling) moraDaily = usuryDailyCeiling;

  return inst.amount * moraDaily * daysLate;
}
