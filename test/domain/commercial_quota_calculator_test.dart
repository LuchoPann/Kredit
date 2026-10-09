import 'package:flutter_test/flutter_test.dart';
import 'package:krezium/data/models/commercial_quota.dart';
import 'package:krezium/data/models/credit.dart';
import 'package:krezium/data/models/installment.dart';
import 'package:krezium/domain/commercial_quota_calculator.dart';

LoanCredit _purchase({
  required String id,
  required String quotaId,
  required double amount,
  required List<bool> paidFlags,
}) {
  final perInstallment = amount / paidFlags.length;
  return LoanCredit(
    id: id,
    name: 'Compra',
    lender: 'Totto',
    totalAmount: amount,
    quotaAmount: perInstallment,
    totalInstallments: paidFlags.length,
    frequency: CreditFrequency.monthly,
    startDate: '2026-09-01',
    quotaId: quotaId,
    installments: [
      for (var i = 0; i < paidFlags.length; i++)
        Installment(
          number: i + 1,
          dueDate: '2026-0${9 + i}-01',
          amount: perInstallment,
          principal: perInstallment,
          interest: 0,
          paid: paidFlags[i],
        ),
    ],
  );
}

void main() {
  final quota = CommercialQuota(id: 'q1', brand: 'Totto', limit: 700000);

  test('quota with no purchases returns the full limit', () {
    expect(quotaAvailable(quota, []), 700000);
  });

  test('fully paid purchase does not reduce available', () {
    final paid = _purchase(
        id: 'l1', quotaId: 'q1', amount: 250000, paidFlags: [true, true]);

    expect(quotaAvailable(quota, [paid]), 700000);
  });

  test('unpaid purchase reduces available by its remaining balance', () {
    final pending = _purchase(
        id: 'l2', quotaId: 'q1', amount: 240000, paidFlags: [false, false]);

    expect(quotaAvailable(quota, [pending]), 700000 - 240000);
  });

  test('purchases from a different quota are ignored', () {
    final other = _purchase(
        id: 'l3', quotaId: 'other-quota', amount: 500000, paidFlags: [false]);

    expect(quotaAvailable(quota, [other]), 700000);
  });

  test('available can go negative and is not clamped to zero', () {
    final big = _purchase(
        id: 'l4', quotaId: 'q1', amount: 900000, paidFlags: [false]);

    expect(quotaAvailable(quota, [big]), 700000 - 900000);
  });
}
