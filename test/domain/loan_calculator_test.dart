import 'package:flutter_test/flutter_test.dart';
import 'package:kredit/data/models/credit.dart';
import 'package:kredit/domain/date_utils.dart';
import 'package:kredit/domain/loan_calculator.dart';

void main() {
  group('buildLoanInstallments', () {
    test('splits principal/interest evenly and computes correct due dates', () {
      final installments = buildLoanInstallments(
        totalAmount: 1000,
        totalInstallments: 4,
        quotaAmount: 300, // total paid = 1200, so total interest = 200
        frequency: CreditFrequency.monthly,
        startDate: '2026-01-15',
      );

      expect(installments, hasLength(4));
      // totalInterest = 1200 - 1000 = 200; per installment = 50
      for (final inst in installments) {
        expect(inst.interest, closeTo(50, 1e-9));
        expect(inst.principal, closeTo(250, 1e-9));
        expect(inst.amount, 300);
        expect(inst.paid, isFalse);
        expect(inst.interestWaived, isFalse);
      }
      expect(installments[0].dueDate, '2026-01-15');
      expect(installments[1].dueDate, '2026-02-15');
      expect(installments[2].dueDate, '2026-03-15');
      expect(installments[3].dueDate, '2026-04-15');
    });

    test('no interest when quota*installments <= totalAmount', () {
      final installments = buildLoanInstallments(
        totalAmount: 1200,
        totalInstallments: 4,
        quotaAmount: 300,
        frequency: CreditFrequency.weekly,
        startDate: '2026-01-01',
      );
      for (final inst in installments) {
        expect(inst.interest, 0);
        expect(inst.principal, 300);
      }
    });

    test('weekly frequency steps by 7 days', () {
      final installments = buildLoanInstallments(
        totalAmount: 400,
        totalInstallments: 3,
        quotaAmount: 150,
        frequency: CreditFrequency.weekly,
        startDate: '2026-01-01',
      );
      expect(installments[0].dueDate, '2026-01-01');
      expect(installments[1].dueDate, '2026-01-08');
      expect(installments[2].dueDate, '2026-01-15');
    });

    test('biweekly frequency steps by 14 days', () {
      final installments = buildLoanInstallments(
        totalAmount: 400,
        totalInstallments: 3,
        quotaAmount: 150,
        frequency: CreditFrequency.biweekly,
        startDate: '2026-01-01',
      );
      expect(installments[0].dueDate, '2026-01-01');
      expect(installments[1].dueDate, '2026-01-15');
      expect(installments[2].dueDate, '2026-01-29');
    });

    test('monthly frequency starting on the 31st rolls over short months (JS Date.setMonth parity)', () {
      final installments = buildLoanInstallments(
        totalAmount: 300,
        totalInstallments: 3,
        quotaAmount: 100,
        frequency: CreditFrequency.monthly,
        startDate: '2026-01-31',
      );
      expect(installments[0].dueDate, '2026-01-31');
      // Feb has 28 days in 2026 (not a leap year) -> day 31 overflows to Mar 3
      expect(installments[1].dueDate, '2026-03-03');
      expect(installments[2].dueDate, '2026-03-31');
    });
  });

  group('applyInstallmentPayment', () {
    test('paying early waives the interest portion', () {
      final inst = buildLoanInstallments(
        totalAmount: 1000,
        totalInstallments: 4,
        quotaAmount: 300,
        frequency: CreditFrequency.monthly,
        startDate: toDateStr(DateTime.now().add(const Duration(days: 30))),
      )[0];

      applyInstallmentPayment(inst, true);

      expect(inst.paid, isTrue);
      expect(inst.interestWaived, isTrue);
      expect(inst.amount, closeTo(inst.principal, 1e-9));
      expect(inst.paymentDate, isNotNull);
    });

    test('paying on/after the due date does NOT waive interest', () {
      final inst = buildLoanInstallments(
        totalAmount: 1000,
        totalInstallments: 4,
        quotaAmount: 300,
        frequency: CreditFrequency.monthly,
        startDate: toDateStr(DateTime.now().subtract(const Duration(days: 5))),
      )[0];
      final originalAmount = inst.amount;

      applyInstallmentPayment(inst, true);

      expect(inst.paid, isTrue);
      expect(inst.interestWaived, isFalse);
      expect(inst.amount, originalAmount);
    });

    test('unmarking a waived installment restores principal+interest', () {
      final inst = buildLoanInstallments(
        totalAmount: 1000,
        totalInstallments: 4,
        quotaAmount: 300,
        frequency: CreditFrequency.monthly,
        startDate: toDateStr(DateTime.now().add(const Duration(days: 30))),
      )[0];

      applyInstallmentPayment(inst, true);
      expect(inst.interestWaived, isTrue);

      applyInstallmentPayment(inst, false);
      expect(inst.paid, isFalse);
      expect(inst.interestWaived, isFalse);
      expect(inst.amount, closeTo(inst.principal + inst.interest, 1e-9));
      expect(inst.paymentDate, isNull);
    });

    test('zero-interest installment paid early is not marked as waived', () {
      final inst = buildLoanInstallments(
        totalAmount: 1200,
        totalInstallments: 4,
        quotaAmount: 300,
        frequency: CreditFrequency.monthly,
        startDate: toDateStr(DateTime.now().add(const Duration(days: 30))),
      )[0];

      applyInstallmentPayment(inst, true);
      expect(inst.interestWaived, isFalse);
      expect(inst.amount, 300);
    });
  });

  group('getLoanRemainingBalance', () {
    test('sums only unpaid installment amounts', () {
      final credit = LoanCredit(
        id: 'c1',
        name: 'Test',
        lender: 'Lender',
        totalAmount: 1000,
        quotaAmount: 300,
        totalInstallments: 4,
        frequency: CreditFrequency.monthly,
        startDate: '2026-01-01',
        installments: buildLoanInstallments(
          totalAmount: 1000,
          totalInstallments: 4,
          quotaAmount: 300,
          frequency: CreditFrequency.monthly,
          startDate: '2026-01-01',
        ),
      );
      applyInstallmentPayment(credit.installments[0], true);
      applyInstallmentPayment(credit.installments[1], true);

      final remaining = getLoanRemainingBalance(credit);
      expect(remaining, closeTo(600, 1e-9));
    });
  });
}
