import 'dart:math' as math;

import '../data/models/card_movement.dart';
import '../data/models/credit.dart';
import 'date_utils.dart';
import 'interest_rate.dart';

/// Card cycle engine, ported from app.js's "CREDIT CARD CYCLE ENGINE"
/// section (~L668-773).

int _clampCutoffDay(int cutoffDay) => math.min(math.max(cutoffDay, 1), 31);

/// Last day-of-month for [year]/[month] (1-indexed month).
int _lastDayOfMonth(int year, int month) {
  // Day 0 of the next month == last day of this month (mirrors
  // `new Date(year, month + 1, 0)` in JS, where JS months are 0-indexed).
  return DateTime(year, month + 1, 0).day;
}

/// Port of cutoffDateForMonth (app.js ~L671-674). [month] is 1-indexed here
/// (unlike the JS original's 0-indexed `month` param) to match Dart's
/// DateTime convention; callers pass Dart month numbers directly.
DateTime cutoffDateForMonth(int year, int month, int cutoffDay) {
  final lastDay = _lastDayOfMonth(year, month);
  return DateTime(year, month, math.min(cutoffDay, lastDay));
}

class CardCycleDates {
  final DateTime lastCutoff;
  final DateTime nextCutoff;
  final DateTime dueDate;

  const CardCycleDates({
    required this.lastCutoff,
    required this.nextCutoff,
    required this.dueDate,
  });
}

/// Port of getCardCycleDates (app.js ~L678-697).
CardCycleDates getCardCycleDates(CardCredit credit, [DateTime? refDate]) {
  final ref = refDate ?? DateTime.now();
  final today = DateTime(ref.year, ref.month, ref.day);
  final cutoffDay = _clampCutoffDay(credit.cutoffDay);

  var lastCutoff = cutoffDateForMonth(today.year, today.month, cutoffDay);
  // Cutoff day opens the new period at 00:00 — so if today IS the cutoff,
  // the prior cycle already closed and lastCutoff must move to the previous month.
  if (!lastCutoff.isBefore(today)) {
    final prevMonthRef = DateTime(today.year, today.month - 1, 1);
    lastCutoff = cutoffDateForMonth(
        prevMonthRef.year, prevMonthRef.month, cutoffDay);
  }
  final nextMonthRef = DateTime(lastCutoff.year, lastCutoff.month + 1, 1);
  final nextCutoff =
      cutoffDateForMonth(nextMonthRef.year, nextMonthRef.month, cutoffDay);

  final DateTime dueDate;
  if (credit.paymentDueDay > 0) {
    // paymentDueDay es un día del mes: el vencimiento cae ese día en el mes
    // siguiente al último corte (ej: corte sep 15 → pago oct 5).
    final dueMonth = DateTime(lastCutoff.year, lastCutoff.month + 1, 1);
    final lastDayOfDueMonth = _lastDayOfMonth(dueMonth.year, dueMonth.month);
    dueDate = DateTime(
      dueMonth.year,
      dueMonth.month,
      math.min(credit.paymentDueDay, lastDayOfDueMonth),
    );
  } else {
    // Fallback para registros no migrados: offset en días desde el último corte.
    dueDate = lastCutoff.add(Duration(days: credit.paymentDueOffsetDays));
  }

  return CardCycleDates(
    lastCutoff: lastCutoff,
    nextCutoff: nextCutoff,
    dueDate: dueDate,
  );
}

double _round2(double v) => (v * 100).round() / 100;

/// Port of accrueCardCredit (app.js ~L703-756).
///
/// Applies simple daily interest (no compounding within/across cycles) and
/// the management fee for every billing cycle closed since
/// `lastAccrualCutoff`, bringing `currentBalance` up to date. The daily rate
/// is derived from `credit.interestRate` normalized per how the user says
/// it's expressed (`credit.interestRateType` — E.A., E.M., or simple
/// monthly; see `interest_rate.dart`), so the entity that quoted the rate
/// never needs to be known here. Idempotent (safe to call on every app
/// load) and capped at 36 cycles per call as a safety net against runaway
/// loops.
void accrueCardCredit(CardCredit credit, [DateTime? now]) {
  final today = now ?? DateTime.now();
  final todayMidnight = DateTime(today.year, today.month, today.day);

  if (credit.lastAccrualCutoff == null) {
    // First run: anchor to the most recent cutoff without back-charging
    // historical interest.
    final dates = getCardCycleDates(credit, todayMidnight);
    credit.lastAccrualCutoff = toDateStr(dates.lastCutoff);
    return;
  }

  final cutoffDay = _clampCutoffDay(credit.cutoffDay);
  final dailyRate = dailyRateFrom(credit.interestRate, credit.interestRateType);

  var cursorStr = credit.lastAccrualCutoff!;
  var safety = 0;
  while (safety < 36) {
    final cursor = parseDateStr(cursorStr);
    final nextRef = DateTime(cursor.year, cursor.month + 1, 1);
    final next = cutoffDateForMonth(nextRef.year, nextRef.month, cutoffDay);
    if (next.isAfter(todayMidnight)) break;

    final daysInCycle = next.difference(cursor).inDays;
    if (credit.currentBalance > 0 && dailyRate > 0) {
      final interestAmt =
          _round2(credit.currentBalance * dailyRate * daysInCycle);
      credit.currentBalance = _round2(credit.currentBalance + interestAmt);
      credit.movements.add(CardMovement(
        date: toDateStr(next),
        type: CardMovementType.interest,
        amount: interestAmt,
        note: 'Interés corriente (${daysInCycle}d × tasa diaria)',
      ));
    }

    credit.cycleCount++;
    final fee = credit.managementFee;
    if (fee > 0) {
      final freq = credit.managementFeeFrequency;
      final chargeFee =
          freq == ManagementFeeFrequency.annual ? (credit.cycleCount % 12 == 0) : true;
      if (chargeFee) {
        credit.currentBalance = _round2(credit.currentBalance + fee);
        credit.movements.add(CardMovement(
          date: toDateStr(next),
          type: CardMovementType.fee,
          amount: fee,
          note: 'Cuota de manejo',
        ));
      }
    }

    cursorStr = toDateStr(next);
    safety++;
  }
  credit.lastAccrualCutoff = cursorStr;
}

/// Closes out any interest already accrued under the CURRENT
/// `interestRate`/`interestRateType` up to [changeDate], anchoring
/// `lastAccrualCutoff` there, so that a caller can safely overwrite the rate
/// fields right after calling this and know the new rate will only ever be
/// applied to cycles that close AFTER [changeDate].
///
/// This fixes a real financial bug: without this step, editing a card's
/// rate after the app has been unopened for several billing cycles would
/// cause the next `accrueCardCredit` call to charge the NEW rate
/// retroactively over interest that, in reality, accrued under the OLD
/// rate.
///
/// Call this BEFORE mutating `credit.interestRate` /
/// `credit.interestRateType` — it reads the credit's current (pre-edit)
/// rate to accrue whatever full cycles have elapsed, exactly like a normal
/// `accrueCardCredit` call would, just capped at [changeDate] instead of
/// "today".
///
/// Known limitation (documented, not fixed here): the engine has no
/// intra-cycle daily-balance tracking, so a rate change that lands in the
/// MIDDLE of an open cycle cannot be prorated by days. That cycle — the one
/// still open at [changeDate] — is left untouched here (its cutoff hasn't
/// arrived yet) and will be accrued in full, with whichever rate is current
/// at the time its cutoff is reached, on a later `accrueCardCredit` call.
/// This is the same simplification the engine already makes for ordinary
/// accrual; this function only prevents the strictly worse case of
/// retroactively re-rating cycles that already closed.
void applyRateChangeAt(CardCredit credit, DateTime changeDate) {
  // No prior accrual anchor yet (brand-new card, or never opened since
  // creation): nothing has accrued under the old rate, so there is nothing
  // to close out. `accrueCardCredit` will set the initial anchor on its own
  // next run.
  if (credit.lastAccrualCutoff == null) return;
  accrueCardCredit(credit, changeDate);
}

/// Port of registerCardMovement (app.js ~L763-773), minus the
/// persistence/save call which belongs to the data layer, not domain logic.
void registerCardMovement(
  CardCredit credit,
  String type,
  double amount, {
  String note = '',
  String? categoria,
  int? chargeInstallments,
}) {
  final delta = type == CardMovementType.payment ? -amount.abs() : amount.abs();
  credit.currentBalance =
      math.max(0.0, _round2(credit.currentBalance + delta));
  credit.movements.add(CardMovement(
    date: toDateStr(DateTime.now()),
    type: type,
    amount: amount.abs(),
    note: note,
    categoria: categoria,
    chargeInstallments: type == CardMovementType.charge ? chargeInstallments : null,
  ));
}

/// Removes a previously-registered movement (identified by its index within
/// `credit.movements`, most-recent-first order not assumed — callers must
/// pass the index into the underlying `credit.movements` list) and reverses
/// its effect on `currentBalance`, undoing exactly what [registerCardMovement]
/// (or [accrueCardCredit], for interest/fee entries) applied when it was
/// created. Lets a user correct a mis-registered charge/payment/interest/fee
/// without leaving the balance out of sync with the visible history.
void deleteCardMovement(CardCredit credit, int index) {
  if (index < 0 || index >= credit.movements.length) return;
  final removed = credit.movements[index];
  // Payments reduced the balance (delta = -amount); every other type
  // (charge/interest/fee) increased it (delta = +amount). Reversing means
  // applying the opposite delta.
  final delta = removed.type == CardMovementType.payment
      ? removed.amount.abs()
      : -removed.amount.abs();
  credit.currentBalance = math.max(0.0, _round2(credit.currentBalance + delta));
  credit.movements.removeAt(index);
}

/// Port of getCreditRemainingBalance for card credits (app.js ~L1332-1336).
double getCardRemainingBalance(CardCredit credit) => credit.currentBalance;

/// Available credit limit (renderCardDetailPanel, app.js ~L1469).
double getCardAvailableLimit(CardCredit credit) =>
    math.max(0.0, credit.creditLimit - credit.currentBalance);
