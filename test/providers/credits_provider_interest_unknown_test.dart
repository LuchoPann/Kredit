import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kredit/data/db/database.dart';
import 'package:kredit/data/models/credit.dart';
import 'package:kredit/providers/credits_provider.dart';
import 'package:kredit/providers/database_provider.dart';

void main() {
  test('saving a purchase with interestRate > 0 clears interestUnknown',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);
    addTearDown(db.close);

    final loan = LoanCredit(
      id: 'l1',
      name: 'Compra tenis',
      lender: 'Totto',
      totalAmount: 250000,
      quotaAmount: 46500,
      totalInstallments: 6,
      frequency: CreditFrequency.monthly,
      startDate: '2026-09-01',
      interestUnknown: true,
      interestRate: 2.5,
    );

    await container.read(creditsProvider.notifier).addCredit(loan);

    final saved = (await container.read(creditsProvider.future))
        .whereType<LoanCredit>()
        .firstWhere((c) => c.id == 'l1');

    expect(saved.interestUnknown, isFalse);
  });
}
