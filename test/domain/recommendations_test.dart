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
  });
}

LoanCredit _loan({
  required String id,
  String name = 'Credito',
  String dueDate = '2026-01-10',
  double amount = 100000,
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
    installments: buildLoanInstallments(
      totalAmount: amount,
      totalInstallments: 1,
      quotaAmount: amount,
      frequency: CreditFrequency.monthly,
      startDate: dueDate,
    ),
  );
}
