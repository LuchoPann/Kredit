import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kredit/data/models/card_movement.dart';
import 'package:kredit/data/models/credit.dart';
import 'package:kredit/domain/card_calculator.dart';
import 'package:kredit/domain/date_utils.dart';

void main() {
  group('cutoffDateForMonth', () {
    test('clamps to last day of February (non-leap year)', () {
      final d = cutoffDateForMonth(2026, 2, 31);
      expect(d, DateTime(2026, 2, 28));
    });

    test('clamps to last day of February (leap year)', () {
      final d = cutoffDateForMonth(2028, 2, 30);
      expect(d, DateTime(2028, 2, 29));
    });

    test('clamps to last day of a 30-day month', () {
      final d = cutoffDateForMonth(2026, 4, 31);
      expect(d, DateTime(2026, 4, 30));
    });

    test('keeps cutoffDay unchanged for 31-day months', () {
      final d = cutoffDateForMonth(2026, 1, 31);
      expect(d, DateTime(2026, 1, 31));
    });
  });

  group('getCardCycleDates', () {
    test('computes last/next cutoff and due date relative to ref date', () {
      final credit = CardCredit(
        id: 'card1',
        name: 'Test',
        lender: 'Bank',
        cutoffDay: 15,
        paymentDueOffsetDays: 20,
      );
      final dates = getCardCycleDates(credit, DateTime(2026, 3, 20));
      expect(dates.lastCutoff, DateTime(2026, 3, 15));
      expect(dates.nextCutoff, DateTime(2026, 4, 15));
      expect(dates.dueDate, DateTime(2026, 3, 15).add(const Duration(days: 20)));
    });

    test('rolls back to previous month when ref date is before this month cutoff', () {
      final credit = CardCredit(
        id: 'card1',
        name: 'Test',
        lender: 'Bank',
        cutoffDay: 15,
        paymentDueOffsetDays: 20,
      );
      final dates = getCardCycleDates(credit, DateTime(2026, 3, 5));
      expect(dates.lastCutoff, DateTime(2026, 2, 15));
      expect(dates.nextCutoff, DateTime(2026, 3, 15));
    });

    group('paymentDueDay', () {
      test('uses paymentDueDay when > 0, ignores paymentDueOffsetDays', () {
        // corte día 15, pago día 5 del mes siguiente
        final credit = CardCredit(
          id: 'c1', name: 'T', lender: 'B',
          cutoffDay: 15,
          paymentDueDay: 5,
          paymentDueOffsetDays: 999, // debe ser ignorado
        );
        // ref 2026-09-20: último corte fue sep 15 → pago oct 5
        final dates = getCardCycleDates(credit, DateTime(2026, 9, 20));
        expect(dates.dueDate, DateTime(2026, 10, 5));
      });

      test('falls back to paymentDueOffsetDays when paymentDueDay == 0', () {
        final credit = CardCredit(
          id: 'c2', name: 'T', lender: 'B',
          cutoffDay: 15,
          paymentDueDay: 0, // no migrado
          paymentDueOffsetDays: 20,
        );
        // ref 2026-09-20: último corte sep 15 + 20 días = oct 5
        final dates = getCardCycleDates(credit, DateTime(2026, 9, 20));
        expect(dates.dueDate, DateTime(2026, 10, 5));
      });

      test('paymentDueDay handles month wrap (día 5 del mes siguiente al corte)', () {
        final credit = CardCredit(
          id: 'c3', name: 'T', lender: 'B',
          cutoffDay: 28,
          paymentDueDay: 5,
          paymentDueOffsetDays: 0,
        );
        // ref 2026-09-30: último corte sep 28 → pago oct 5
        final dates = getCardCycleDates(credit, DateTime(2026, 9, 30));
        expect(dates.dueDate, DateTime(2026, 10, 5));
      });

      test('paymentDueDay clamps to last day of month (día 31 en mes de 30 días)', () {
        final credit = CardCredit(
          id: 'c4', name: 'T', lender: 'B',
          cutoffDay: 1,
          paymentDueDay: 31,
          paymentDueOffsetDays: 0,
        );
        // ref 2026-09-05: último corte sep 1 → pago en oct → oct tiene 31 días → oct 31
        final dates = getCardCycleDates(credit, DateTime(2026, 9, 5));
        expect(dates.dueDate, DateTime(2026, 10, 31));
      });

      test('paymentDueDay 31 in month of 30 days clamps to 30', () {
        final credit = CardCredit(
          id: 'c5', name: 'T', lender: 'B',
          cutoffDay: 1,
          paymentDueDay: 31,
          paymentDueOffsetDays: 0,
        );
        // ref 2026-04-05: último corte abr 1 → pago en mayo → mayo tiene 31 → mayo 31
        // Pero si último corte fuera mar 1 → pago abr → abr tiene 30 → abr 30
        final dates = getCardCycleDates(credit, DateTime(2026, 3, 5));
        // último corte fue mar 1, pago es abr que tiene 30 días → abr 30
        expect(dates.dueDate, DateTime(2026, 4, 30));
      });
    });
  });

  group('accrueCardCredit', () {
    test('first call just anchors lastAccrualCutoff without charging interest', () {
      final credit = CardCredit(
        id: 'c1',
        name: 'Test',
        lender: 'Bank',
        currentBalance: 1000,
        interestRate: 36.5, // -> daily rate 0.1%
        cutoffDay: 1,
      );
      accrueCardCredit(credit, DateTime(2026, 3, 10));
      expect(credit.lastAccrualCutoff, isNotNull);
      expect(credit.currentBalance, 1000);
      expect(credit.movements, isEmpty);
    });

    test('accrues effective daily interest (from E.A.) for a single closed cycle', () {
      final credit = CardCredit(
        id: 'c1',
        name: 'Test',
        lender: 'Bank',
        currentBalance: 1000,
        // dailyRate = (1.365)^(1/365) - 1 ~= 0.00085284 (effectiveAnnual, the default).
        interestRate: 36.5,
        cutoffDay: 1,
        lastAccrualCutoff: '2026-02-01',
      );
      // Next cutoff after 2026-02-01 is 2026-03-01 -> 28 days in cycle (2026 not leap).
      accrueCardCredit(credit, DateTime(2026, 3, 5));

      // interest = round(1000 * 0.00085284... * 28) = 23.88
      expect(credit.currentBalance, closeTo(1023.88, 1e-9));
      expect(credit.movements, hasLength(1));
      expect(credit.movements[0].type, 'interest');
      expect(credit.movements[0].amount, closeTo(23.88, 1e-9));
      expect(credit.lastAccrualCutoff, '2026-03-01');
    });

    test('accrues compounding-free-per-cycle simple interest across multiple cycles', () {
      final credit = CardCredit(
        id: 'c1',
        name: 'Test',
        lender: 'Bank',
        currentBalance: 1000,
        interestRate: 36.5,
        cutoffDay: 1,
        lastAccrualCutoff: '2026-01-01',
      );
      // Cycles: Jan01->Feb01 (31d), Feb01->Mar01 (28d), Mar01->Apr01 (31d)
      accrueCardCredit(credit, DateTime(2026, 4, 5));

      expect(credit.movements.where((m) => m.type == 'interest'), hasLength(3));
      // dailyRate = (1.365)^(1/365) - 1 ~= 0.00085284
      // cycle 1: 1000 * dailyRate * 31 = 26.44 -> balance 1026.44
      // cycle 2: 1026.44 * dailyRate * 28 = 24.51 -> balance 1050.95
      // cycle 3: 1050.95 * dailyRate * 31 = 27.79 -> balance 1078.74
      expect(credit.currentBalance, closeTo(1078.74, 1e-2));
      expect(credit.lastAccrualCutoff, '2026-04-01');
    });

    test('does not charge interest when balance is zero', () {
      final credit = CardCredit(
        id: 'c1',
        name: 'Test',
        lender: 'Bank',
        currentBalance: 0,
        interestRate: 36.5,
        cutoffDay: 1,
        lastAccrualCutoff: '2026-02-01',
      );
      accrueCardCredit(credit, DateTime(2026, 3, 5));
      expect(credit.currentBalance, 0);
      expect(credit.movements.where((m) => m.type == 'interest'), isEmpty);
    });

    test('is idempotent: a second call with the same "now" charges nothing further', () {
      final credit = CardCredit(
        id: 'c1',
        name: 'Test',
        lender: 'Bank',
        currentBalance: 1000,
        interestRate: 36.5,
        cutoffDay: 1,
        lastAccrualCutoff: '2026-02-01',
      );
      accrueCardCredit(credit, DateTime(2026, 3, 5));
      final balanceAfterFirst = credit.currentBalance;
      final movementsAfterFirst = credit.movements.length;

      accrueCardCredit(credit, DateTime(2026, 3, 5));
      expect(credit.currentBalance, balanceAfterFirst);
      expect(credit.movements.length, movementsAfterFirst);
    });

    test('monthly management fee is charged every closed cycle', () {
      final credit = CardCredit(
        id: 'c1',
        name: 'Test',
        lender: 'Bank',
        currentBalance: 0,
        interestRate: 0,
        managementFee: 15,
        managementFeeFrequency: ManagementFeeFrequency.monthly,
        cutoffDay: 1,
        lastAccrualCutoff: '2026-01-01',
      );
      // 3 cycles close: Jan->Feb, Feb->Mar, Mar->Apr
      accrueCardCredit(credit, DateTime(2026, 4, 5));

      final feeMovements = credit.movements.where((m) => m.type == 'fee');
      expect(feeMovements, hasLength(3));
      expect(credit.currentBalance, closeTo(45, 1e-9));
      expect(credit.cycleCount, 3);
    });

    test('annual management fee is only charged every 12th cycle', () {
      final credit = CardCredit(
        id: 'c1',
        name: 'Test',
        lender: 'Bank',
        currentBalance: 0,
        interestRate: 0,
        managementFee: 100,
        managementFeeFrequency: ManagementFeeFrequency.annual,
        cutoffDay: 1,
        lastAccrualCutoff: '2025-01-01',
      );
      // 15 cycles close between 2025-01-01 and 2026-04-05: fee should charge
      // at cycle 12 only (once).
      accrueCardCredit(credit, DateTime(2026, 4, 5));

      final feeMovements = credit.movements.where((m) => m.type == 'fee');
      expect(credit.cycleCount, 15);
      expect(feeMovements, hasLength(1));
      expect(credit.currentBalance, closeTo(100, 1e-9));
    });

    test('safety cap stops after 36 cycles in a single call', () {
      final credit = CardCredit(
        id: 'c1',
        name: 'Test',
        lender: 'Bank',
        currentBalance: 0,
        interestRate: 0,
        cutoffDay: 1,
        lastAccrualCutoff: '2000-01-01',
      );
      accrueCardCredit(credit, DateTime(2026, 1, 1));
      expect(credit.cycleCount, 36);
    });
  });

  group('applyRateChangeAt', () {
    test('closes pending cycles with the OLD rate before a rate edit, instead of back-charging the new rate', () {
      // Card unopened for 3 full cycles (Jan01, Feb01, Mar01) at the old
      // rate of 36.5% E.A. The user edits the rate to 60% E.A. today
      // (2026-04-05), which is itself mid-cycle (next cutoff 2026-05-01).
      final creditOldRateReference = CardCredit(
        id: 'ref',
        name: 'Test',
        lender: 'Bank',
        currentBalance: 1000,
        interestRate: 36.5,
        cutoffDay: 1,
        lastAccrualCutoff: '2026-01-01',
      );
      // What SHOULD happen: the 3 elapsed cycles accrue at the OLD rate.
      accrueCardCredit(creditOldRateReference, DateTime(2026, 4, 5));
      final expectedBalanceAtOldRate = creditOldRateReference.currentBalance;

      // What the bug would produce: same starting state, but accrual runs
      // AFTER the rate field was already overwritten to 60%.
      final creditBuggy = CardCredit(
        id: 'buggy',
        name: 'Test',
        lender: 'Bank',
        currentBalance: 1000,
        interestRate: 36.5,
        cutoffDay: 1,
        lastAccrualCutoff: '2026-01-01',
      );
      creditBuggy.interestRate = 60; // simulate overwriting the rate first
      accrueCardCredit(creditBuggy, DateTime(2026, 4, 5));
      final buggyBalance = creditBuggy.currentBalance;

      // The fix: call applyRateChangeAt with the OLD rate still in place,
      // THEN overwrite the rate field.
      final creditFixed = CardCredit(
        id: 'fixed',
        name: 'Test',
        lender: 'Bank',
        currentBalance: 1000,
        interestRate: 36.5,
        cutoffDay: 1,
        lastAccrualCutoff: '2026-01-01',
      );
      applyRateChangeAt(creditFixed, DateTime(2026, 4, 5));
      creditFixed.interestRate = 60;

      // The 3 already-elapsed cycles must match the OLD-rate reference
      // exactly, not the buggy new-rate result.
      expect(creditFixed.currentBalance, closeTo(expectedBalanceAtOldRate, 1e-9));
      expect(creditFixed.currentBalance, isNot(closeTo(buggyBalance, 1e-9)));
      expect(creditFixed.lastAccrualCutoff, '2026-04-01');

      // Now the pending (still-open) cycle from 2026-04-01 onward correctly
      // uses the NEW rate once it closes.
      accrueCardCredit(creditFixed, DateTime(2026, 5, 5));
      expect(creditFixed.lastAccrualCutoff, '2026-05-01');
      final lastInterestMovement =
          creditFixed.movements.where((m) => m.type == CardMovementType.interest).last;
      // dailyRate at 60% E.A. = (1.6)^(1/365)-1 ~= 0.0012872; 30 days in
      // April; balance going into April is expectedBalanceAtOldRate.
      final expectedNewCycleInterest =
          (expectedBalanceAtOldRate * (math.pow(1.6, 1 / 365) - 1) * 30 * 100).round() / 100;
      expect(lastInterestMovement.amount, closeTo(expectedNewCycleInterest, 1e-2));
    });

    test('on a brand-new card (no prior accrual) it is a no-op and does not break the first accrual', () {
      final credit = CardCredit(
        id: 'new1',
        name: 'Test',
        lender: 'Bank',
        currentBalance: 500,
        interestRate: 36.5,
        cutoffDay: 1,
      );
      expect(credit.lastAccrualCutoff, isNull);

      applyRateChangeAt(credit, DateTime(2026, 3, 10));
      // No anchor existed yet, so nothing should have been charged and the
      // anchor should still be unset (accrueCardCredit itself sets it on
      // its normal first run).
      expect(credit.lastAccrualCutoff, isNull);
      expect(credit.currentBalance, 500);
      expect(credit.movements, isEmpty);

      credit.interestRate = 60;
      // Normal first accrual afterwards still just anchors, no back-charge.
      accrueCardCredit(credit, DateTime(2026, 3, 10));
      expect(credit.lastAccrualCutoff, isNotNull);
      expect(credit.currentBalance, 500);
      expect(credit.movements, isEmpty);
    });
  });

  group('registerCardMovement', () {
    test('a charge increases the balance', () {
      final credit = CardCredit(id: 'c1', name: 'T', lender: 'B', currentBalance: 100);
      registerCardMovement(credit, 'charge', 50, note: 'compra');
      expect(credit.currentBalance, 150);
      expect(credit.movements.last.type, 'charge');
      expect(credit.movements.last.amount, 50);
    });

    test('a payment decreases the balance and never goes below zero', () {
      final credit = CardCredit(id: 'c1', name: 'T', lender: 'B', currentBalance: 30);
      registerCardMovement(credit, 'payment', 50);
      expect(credit.currentBalance, 0);
    });
  });

  test('toDateStr/parseDateStr round-trip', () {
    final d = DateTime(2026, 3, 1);
    expect(parseDateStr(toDateStr(d)), d);
  });
}
