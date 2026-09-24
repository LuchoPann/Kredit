import 'package:flutter_test/flutter_test.dart';
import 'package:kredit/data/models/credit.dart';
import 'package:kredit/domain/loan_calculator.dart';
import 'package:kredit/domain/recommendations.dart';

void main() {
  group('buildPendingPayments', () {
    test('orders payments by urgency with overdue items first', () {
      final ref = DateTime(2026, 1, 10);
      final overdue = _loan(
        id: 'overdue',
        name: 'Cupo vencido',
        dueDate: '2026-01-08',
        amount: 100000,
      );
      final upcomingLarge = _loan(
        id: 'large',
        name: 'Pago grande',
        dueDate: '2026-01-12',
        amount: 900000,
      );

      final payments = buildPendingPayments(
        [upcomingLarge, overdue],
        now: ref,
      );

      expect(payments.first.credit.id, 'overdue');
      expect(payments.last.credit.id, 'large');
    });
  });

  group('buildPaymentWeekSummary', () {
    test('counts overdue, today and next 7 days totals', () {
      final ref = DateTime(2026, 1, 10);
      final payments = buildPendingPayments(
        [
          _loan(id: 'a', dueDate: '2026-01-09', amount: 100000),
          _loan(id: 'b', dueDate: '2026-01-10', amount: 200000),
          _loan(id: 'c', dueDate: '2026-01-14', amount: 300000),
        ],
        now: ref,
      );

      final summary = buildPaymentWeekSummary(payments, now: ref);

      expect(summary.overdueCount, 1);
      expect(summary.dueTodayCount, 1);
      expect(summary.dueSoonCount, 1);
      expect(summary.dueWithin7Days, 600000);
      expect(summary.nextPayment?.credit.id, 'a');
    });
  });

  group('buildPrimaryRecommendation', () {
    test('returns calm state when there are no pending payments', () {
      final loan = _loan(id: 'paid', dueDate: '2026-01-10', amount: 100000);
      loan.installments.first.paid = true;

      final recommendation = buildPrimaryRecommendation([loan]);

      expect(recommendation.severity, RecommendationSeverity.calm);
      expect(recommendation.payment, isNull);
    });

    test('prioritizes overdue payments as danger', () {
      final recommendation = buildPrimaryRecommendation(
        [
          _loan(id: 'loan', name: 'Cupo personal', dueDate: '2026-01-08'),
        ],
        now: DateTime(2026, 1, 10),
      );

      expect(recommendation.severity, RecommendationSeverity.danger);
      expect(recommendation.payment?.credit.name, 'Cupo personal');
    });
  });

  group('buildRiskRecommendations', () {
    test('flags debt concentration when one lender dominates', () {
      final big = _loan(id: 'big', name: 'Prestamo grande', amount: 900000);
      final small = _loan(id: 'small', name: 'Prestamo chico', amount: 100000);

      final risks = buildRiskRecommendations([big, small]);

      expect(risks.any((r) => r.title == 'Deuda concentrada'), isTrue);
    });

    test('does not flag concentration when debt is balanced', () {
      final a = _loan(id: 'a', amount: 500000);
      final b = _loan(id: 'b', amount: 500000);

      final risks = buildRiskRecommendations([a, b]);

      expect(risks.any((r) => r.title == 'Deuda concentrada'), isFalse);
    });

    test('flags a card near its limit', () {
      final card = CardCredit(
        id: 'card',
        name: 'Tarjeta',
        lender: 'Banco',
        creditLimit: 1000000,
        currentBalance: 900000,
      );

      final risks = buildRiskRecommendations([card]);

      expect(risks.any((r) => r.title == 'Cupo casi agotado'), isTrue);
    });

    test('returns no risks for a single healthy loan', () {
      final loan = _loan(id: 'only', amount: 100000);

      expect(buildRiskRecommendations([loan]), isEmpty);
    });

    test('flags the costliest loan when its rate dwarfs the others', () {
      final expensive = _loan(id: 'exp', name: 'Gota a gota', interestRate: 90);
      final cheap1 = _loan(id: 'c1', name: 'Banco A', interestRate: 15);
      final cheap2 = _loan(id: 'c2', name: 'Banco B', interestRate: 18);

      final risks = buildRiskRecommendations([expensive, cheap1, cheap2]);

      expect(risks.any((r) => r.title == 'Deuda mas costosa'), isTrue);
    });

    test('does not flag costliest when rates are similar', () {
      final a = _loan(id: 'a', interestRate: 20);
      final b = _loan(id: 'b', interestRate: 22);

      expect(
        buildRiskRecommendations([a, b]).any((r) => r.title == 'Deuda mas costosa'),
        isFalse,
      );
    });
  });

  group('effectiveAnnualRate', () {
    test('returns 0 for a credit without an interest rate', () {
      expect(effectiveAnnualRate(_loan(id: 'a', interestRate: 0)), 0);
    });

    test('returns a positive annualized rate for a loan with E.A. rate', () {
      final rate = effectiveAnnualRate(_loan(id: 'a', interestRate: 24));
      expect(rate, closeTo(24, 0.5));
    });
  });

  group('buildBestPrepaymentRecommendation', () {
    test('returns null with fewer than two active loans', () {
      expect(buildBestPrepaymentRecommendation([_loan(id: 'a', interestRate: 20)]), isNull);
    });

    test('picks the loan with the highest effective annual rate', () {
      final expensive = _loan(id: 'exp', name: 'Gota a gota', interestRate: 90);
      final cheap = _loan(id: 'cheap', name: 'Banco A', interestRate: 15);

      final rec = buildBestPrepaymentRecommendation([expensive, cheap]);

      expect(rec, isNotNull);
      expect(rec!.description, contains('Gota a gota'));
    });

    test('ignores fully paid loans', () {
      final expensive = _loan(id: 'exp', name: 'Gota a gota', interestRate: 90);
      expensive.installments.first.paid = true;
      final cheap = _loan(id: 'cheap', name: 'Banco A', interestRate: 15);

      final rec = buildBestPrepaymentRecommendation([expensive, cheap]);

      expect(rec, isNull);
    });
  });
}

LoanCredit _loan({
  required String id,
  String name = 'Credito',
  String dueDate = '2026-01-10',
  double amount = 100000,
  double interestRate = 0,
}) {
  return LoanCredit(
    id: id,
    name: name,
    lender: 'Banco',
    totalAmount: amount,
    quotaAmount: amount,
    totalInstallments: 1,
    frequency: CreditFrequency.monthly,
    startDate: dueDate,
    interestRate: interestRate,
    installments: buildLoanInstallments(
      totalAmount: amount,
      totalInstallments: 1,
      quotaAmount: amount,
      frequency: CreditFrequency.monthly,
      startDate: dueDate,
    ),
  );
}
