import 'package:flutter_test/flutter_test.dart';
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

    test('accrues simple daily E.A./365 interest for a single closed cycle', () {
      final credit = CardCredit(
        id: 'c1',
        name: 'Test',
        lender: 'Bank',
        currentBalance: 1000,
        interestRate: 36.5, // dailyRate = 36.5/100/365 = 0.001 exactly
        cutoffDay: 1,
        lastAccrualCutoff: '2026-02-01',
      );
      // Next cutoff after 2026-02-01 is 2026-03-01 -> 28 days in cycle (2026 not leap).
      accrueCardCredit(credit, DateTime(2026, 3, 5));

      // interest = 1000 * 0.001 * 28 = 28.00
      expect(credit.currentBalance, closeTo(1028.0, 1e-9));
      expect(credit.movements, hasLength(1));
      expect(credit.movements[0].type, 'interest');
      expect(credit.movements[0].amount, closeTo(28.0, 1e-9));
      expect(credit.lastAccrualCutoff, '2026-03-01');
    });

    test('accrues compounding-free simple interest across multiple cycles', () {
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
      // cycle 1: 1000 * .001 * 31 = 31.00 -> balance 1031.00
      // cycle 2: 1031.00 * .001 * 28 = 28.868 -> rounds to 28.87 -> balance 1059.87
      // cycle 3: 1059.87 * .001 * 31 = 32.856 -> rounds to 32.86 -> balance 1092.73
      expect(credit.currentBalance, closeTo(1092.73, 1e-2));
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

  group('registerCardMovement', () {
    test('a charge increases the balance', () {
      final credit = CardCredit(id: 'c1', name: 'T', lender: 'B', currentBalance: 100);
      registerCardMovement(credit, 'charge', 50, 'compra');
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
