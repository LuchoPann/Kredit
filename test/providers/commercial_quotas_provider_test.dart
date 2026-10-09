import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krezium/data/db/database.dart';
import 'package:krezium/data/models/commercial_quota.dart';
import 'package:krezium/providers/commercial_quotas_provider.dart';
import 'package:krezium/providers/database_provider.dart';

void main() {
  test('upsert then read reflects the new quota', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);
    addTearDown(db.close);

    await container.read(commercialQuotasProvider.notifier).upsert(
          CommercialQuota(id: 'q1', brand: 'Totto', limit: 700000),
        );

    final quotas = await container.read(commercialQuotasProvider.future);

    expect(quotas, hasLength(1));
    expect(quotas.first.brand, 'Totto');
  });

  test('delete removes the quota', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);
    addTearDown(db.close);

    await container.read(commercialQuotasProvider.notifier).upsert(
          CommercialQuota(id: 'q1', brand: 'Totto', limit: 700000),
        );
    await container.read(commercialQuotasProvider.notifier).delete('q1');

    final quotas = await container.read(commercialQuotasProvider.future);

    expect(quotas, isEmpty);
  });
}
