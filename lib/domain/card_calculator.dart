import 'dart:math' as math;

import '../data/models/card_movement.dart';
import '../data/models/credit.dart';
import 'date_utils.dart';

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
  if (lastCutoff.isAfter(today)) {
    final prevMonthRef = DateTime(today.year, today.month - 1, 1);
    lastCutoff = cutoffDateForMonth(
        prevMonthRef.year, prevMonthRef.month, cutoffDay);
  }
  final nextMonthRef = DateTime(lastCutoff.year, lastCutoff.month + 1, 1);
  final nextCutoff =
      cutoffDateForMonth(nextMonthRef.year, nextMonthRef.month, cutoffDay);

  final offset = credit.paymentDueOffsetDays;
  final dueDate = lastCutoff.add(Duration(days: offset));

  return CardCycleDates(
    lastCutoff: lastCutoff,
    nextCutoff: nextCutoff,
    dueDate: dueDate,
  );
}

double _round2(double v) => (v * 100).round() / 100;

/// Port of accrueCardCredit (app.js ~L703-756).
///
/// Applies simple daily interest (E.A./365, NOT monthly compounding) and the
/// management fee for every billing cycle closed since `lastAccrualCutoff`,
/// bringing `currentBalance` up to date. Idempotent (safe to call on every
/// app load) and capped at 36 cycles per call as a safety net against
/// runaway loops.
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
  final dailyRate =
      credit.interestRate != 0 ? (credit.interestRate / 100 / 365) : 0.0;

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

/// Port of registerCardMovement (app.js ~L763-773), minus the
/// persistence/save call which belongs to the data layer, not domain logic.
void registerCardMovement(
  CardCredit credit,
  String type,
  double amount, [
  String note = '',
]) {
  final delta = type == CardMovementType.payment ? -amount.abs() : amount.abs();
  credit.currentBalance =
      math.max(0.0, _round2(credit.currentBalance + delta));
  credit.movements.add(CardMovement(
    date: toDateStr(DateTime.now()),
    type: type,
    amount: amount.abs(),
    note: note,
  ));
}

/// Port of getCreditRemainingBalance for card credits (app.js ~L1332-1336).
double getCardRemainingBalance(CardCredit credit) => credit.currentBalance;

/// Available credit limit (renderCardDetailPanel, app.js ~L1469).
double getCardAvailableLimit(CardCredit credit) =>
    math.max(0.0, credit.creditLimit - credit.currentBalance);
