import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../data/models/commercial_quota.dart';
import 'credits_provider.dart';
import 'database_provider.dart';

class CommercialQuotasNotifier extends AsyncNotifier<List<CommercialQuota>> {
  AppDatabase get _db => ref.read(databaseProvider);

  @override
  Future<List<CommercialQuota>> build() => _db.loadAllCommercialQuotas();

  Future<void> upsert(CommercialQuota quota) async {
    await _db.upsertCommercialQuota(quota);
    state = AsyncData(await _db.loadAllCommercialQuotas());
  }

  /// Throws [QuotaHasActivePurchasesException] if any referencing purchase
  /// is still active — fully paid ones get unlinked instead of blocking
  /// (see AppDatabase.deleteCommercialQuota). Since that unlinking changes
  /// those credits' `quotaId`, creditsProvider is invalidated too so the
  /// Créditos screen doesn't keep showing them as still grouped.
  Future<void> delete(String id) async {
    await _db.deleteCommercialQuota(id);
    state = AsyncData(await _db.loadAllCommercialQuotas());
    ref.invalidate(creditsProvider);
  }
}

final commercialQuotasProvider =
    AsyncNotifierProvider<CommercialQuotasNotifier, List<CommercialQuota>>(
  CommercialQuotasNotifier.new,
);
