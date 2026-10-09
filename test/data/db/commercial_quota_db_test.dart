import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:krezium/data/db/database.dart';
import 'package:krezium/data/models/commercial_quota.dart';
import 'package:krezium/data/models/credit.dart';
import 'package:krezium/data/models/installment.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('upsert and load a CommercialQuota', () async {
    await db.upsertCommercialQuota(
      CommercialQuota(id: 'q1', brand: 'Totto', limit: 700000),
    );

    final quotas = await db.loadAllCommercialQuotas();

    expect(quotas, hasLength(1));
    expect(quotas.first.brand, 'Totto');
    expect(quotas.first.limit, 700000);
  });

  test('LoanCredit with quotaId round-trips through the DB', () async {
    await db.upsertCommercialQuota(
      CommercialQuota(id: 'q1', brand: 'Totto', limit: 700000),
    );
    await db.upsertCredit(LoanCredit(
      id: 'l1',
      name: 'Compra tenis',
      lender: 'Totto',
      totalAmount: 250000,
      quotaAmount: 46500,
      totalInstallments: 6,
      frequency: CreditFrequency.monthly,
      startDate: '2026-09-01',
      quotaId: 'q1',
      interestUnknown: true,
    ));

    final credits = await db.loadAllCredits();
    final loan = credits.single as LoanCredit;

    expect(loan.quotaId, 'q1');
    expect(loan.interestUnknown, isTrue);
    expect(loan.earlyPaymentWaivesInterest, isFalse);
  });

  test('deleting a quota with an unpaid purchase referencing it throws', () async {
    await db.upsertCommercialQuota(
      CommercialQuota(id: 'q1', brand: 'Totto', limit: 700000),
    );
    await db.upsertCredit(LoanCredit(
      id: 'l1',
      name: 'Compra tenis',
      lender: 'Totto',
      totalAmount: 250000,
      quotaAmount: 46500,
      totalInstallments: 6,
      frequency: CreditFrequency.monthly,
      startDate: '2026-09-01',
      quotaId: 'q1',
    ));

    expect(() => db.deleteCommercialQuota('q1'),
        throwsA(isA<QuotaHasActivePurchasesException>()));
  });

  test(
      'deleting a quota whose only purchase is fully paid succeeds and '
      'unlinks that purchase instead of losing its history', () async {
    await db.upsertCommercialQuota(
      CommercialQuota(id: 'q1', brand: 'Totto', limit: 700000),
    );
    await db.upsertCredit(LoanCredit(
      id: 'l1',
      name: 'Compra pagada',
      lender: 'Totto',
      totalAmount: 100000,
      quotaAmount: 100000,
      totalInstallments: 1,
      frequency: CreditFrequency.monthly,
      startDate: '2026-09-01',
      quotaId: 'q1',
      installments: [
        Installment(
          number: 1,
          dueDate: '2026-09-01',
          amount: 100000,
          principal: 100000,
          interest: 0,
          paid: true,
        ),
      ],
    ));

    await db.deleteCommercialQuota('q1');

    expect(await db.loadAllCommercialQuotas(), isEmpty);
    final credits = await db.loadAllCredits();
    expect((credits.single as LoanCredit).quotaId, isNull);
  });

  test('deleting a quota with no purchases at all succeeds', () async {
    await db.upsertCommercialQuota(
      CommercialQuota(id: 'q1', brand: 'Totto', limit: 700000),
    );

    await db.deleteCommercialQuota('q1');

    expect(await db.loadAllCommercialQuotas(), isEmpty);
  });
}
