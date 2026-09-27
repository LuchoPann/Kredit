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

  test('restores quotas and quota-linked credits atomically', () async {
    final quota = CommercialQuota(id: 'q1', brand: 'Totto', limit: 700000);
    final purchase = LoanCredit(
      id: 'l1',
      name: 'Compra',
      lender: 'Totto',
      totalAmount: 250000,
      quotaAmount: 41667,
      totalInstallments: 6,
      frequency: CreditFrequency.monthly,
      startDate: '2026-09-01',
      quotaId: 'q1',
    );

    await db.replaceAllData([purchase], [quota]);

    final quotas = await db.loadAllCommercialQuotas();
    final credits = await db.loadAllCredits();

    expect(quotas, hasLength(1));
    expect(quotas.first.brand, 'Totto');
    expect((credits.single as LoanCredit).quotaId, 'q1');
  });

  test('a credit whose quotaId has no matching quota is imported with '
      'quotaId nulled out instead of failing the whole restore', () async {
    final orphan = LoanCredit(
      id: 'l1',
      name: 'Compra huerfana',
      lender: 'Totto',
      totalAmount: 250000,
      quotaAmount: 41667,
      totalInstallments: 6,
      frequency: CreditFrequency.monthly,
      startDate: '2026-09-01',
      quotaId: 'missing-quota',
    );

    await db.replaceAllData([orphan], []);

    final credits = await db.loadAllCredits();
    expect((credits.single as LoanCredit).quotaId, isNull);
  });

  test('replaces prior data instead of appending to it', () async {
    await db.upsertCommercialQuota(
      CommercialQuota(id: 'old', brand: 'Old', limit: 1),
    );
    await db.upsertCredit(LoanCredit(
      id: 'old-credit',
      name: 'Old',
      lender: 'Old',
      totalAmount: 1,
      quotaAmount: 1,
      totalInstallments: 1,
      frequency: CreditFrequency.monthly,
      startDate: '2026-09-01',
    ));

    await db.replaceAllData([], []);

    expect(await db.loadAllCommercialQuotas(), isEmpty);
    expect(await db.loadAllCredits(), isEmpty);
  });
}
