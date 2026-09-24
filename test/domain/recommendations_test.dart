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
