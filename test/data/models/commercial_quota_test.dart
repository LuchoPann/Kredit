import 'package:flutter_test/flutter_test.dart';
import 'package:krezium/data/models/commercial_quota.dart';

void main() {
  test('toJson/fromJson round-trip', () {
    final quota = CommercialQuota(
      id: 'q1',
      brand: 'Totto',
      limit: 700000,
      notes: 'Cupo de compras',
    );

    final json = quota.toJson();
    final restored = CommercialQuota.fromJson(json);

    expect(restored.id, 'q1');
    expect(restored.brand, 'Totto');
    expect(restored.limit, 700000);
    expect(restored.notes, 'Cupo de compras');
  });

  test('fromJson with missing notes defaults to null', () {
    final restored = CommercialQuota.fromJson({
      'id': 'q2',
      'brand': 'Lili Pink',
      'limit': 500000.0,
    });

    expect(restored.notes, isNull);
  });
}
