import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../data/models/commercial_quota.dart';
import 'database_provider.dart';

class CommercialQuotasNotifier extends AsyncNotifier<List<CommercialQuota>> {
  AppDatabase get _db => ref.read(databaseProvider);

  @override
  Future<List<CommercialQuota>> build() => _db.loadAllCommercialQuotas();

  Future<void> upsert(CommercialQuota quota) async {
    await _db.upsertCommercialQuota(quota);
    state = AsyncData(await _db.loadAllCommercialQuotas());
  }

  Future<void> delete(String id) async {
    await _db.deleteCommercialQuota(id);
    state = AsyncData(await _db.loadAllCommercialQuotas());
  }
}

final commercialQuotasProvider =
    AsyncNotifierProvider<CommercialQuotasNotifier, List<CommercialQuota>>(
  CommercialQuotasNotifier.new,
);
