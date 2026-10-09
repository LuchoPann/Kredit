import 'package:flutter_test/flutter_test.dart';
import 'package:krezium/data/models/credit.dart';

void main() {
  group('LoanCredit cupo comercial fields', () {
    test('fromJson without new fields defaults safely', () {
      final loan = LoanCredit.fromJson({
        'id': 'l1',
        'name': 'Compra Totto',
        'lender': 'Totto',
        'totalAmount': 250000.0,
        'quotaAmount': 46500.0,
        'totalInstallments': 6,
        'frequency': 'monthly',
        'startDate': '2026-09-01',
      });

      expect(loan.quotaId, isNull);
      expect(loan.interestUnknown, isFalse);
      expect(loan.earlyPaymentWaivesInterest, isFalse);
    });

    test('toJson/fromJson round-trips the new fields', () {
      final loan = LoanCredit(
        id: 'l2',
        name: 'Compra Lili Pink',
        lender: 'Lili Pink',
        totalAmount: 100000,
        quotaAmount: 34000,
        totalInstallments: 3,
        frequency: CreditFrequency.monthly,
        startDate: '2026-09-01',
        quotaId: 'q1',
        interestUnknown: true,
        earlyPaymentWaivesInterest: true,
      );

      final restored = LoanCredit.fromJson(loan.toJson());

      expect(restored.quotaId, 'q1');
      expect(restored.interestUnknown, isTrue);
      expect(restored.earlyPaymentWaivesInterest, isTrue);
    });
  });
}
