import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:kredit/data/db/database.dart';
import 'package:kredit/data/models/commercial_quota.dart';
import 'package:kredit/data/models/credit.dart';

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

    expect(() => db.deleteCommercialQuota('q1'), throwsA(anything));
  });
}
