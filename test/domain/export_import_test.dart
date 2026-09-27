import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kredit/data/models/commercial_quota.dart';
import 'package:kredit/data/models/credit.dart';
import 'package:kredit/domain/export_import.dart';

void main() {
  LoanCredit buildLoan() => LoanCredit(
        id: 'l1',
        name: 'Préstamo test',
        lender: 'Banco X',
        totalAmount: 1000000,
        quotaAmount: 100000,
        totalInstallments: 10,
        frequency: CreditFrequency.monthly,
        startDate: '2026-01-01',
      );

  group('exportStateToJson', () {
    test('produces the versioned envelope with format/version/exportedAt', () {
      final json = exportStateToJson([buildLoan()]);
      final decoded = jsonDecode(json) as Map<String, dynamic>;

      expect(decoded['format'], 'kredit-backup');
      expect(decoded['version'], kBackupFormatVersion);
      expect(decoded['exportedAt'], isA<String>());
      expect(() => DateTime.parse(decoded['exportedAt'] as String), returnsNormally);
      expect(decoded['credits'], isA<List>());
      expect((decoded['credits'] as List).length, 1);
    });
  });

  group('importStateFromJson', () {
    test('imports the current versioned format', () {
      final json = exportStateToJson([buildLoan()]);
      final imported = importStateFromJson(json);

      expect(imported.credits, hasLength(1));
      expect(imported.credits.single, isA<LoanCredit>());
      expect(imported.credits.single.id, 'l1');
    });

    test('imports legacy (unversioned) backups exactly as before', () {
      final legacyJson = jsonEncode({
        'credits': [buildLoan().toJson()],
      });

      final imported = importStateFromJson(legacyJson);

      expect(imported.credits, hasLength(1));
      expect(imported.credits.single, isA<LoanCredit>());
      expect(imported.credits.single.id, 'l1');
    });

    test('imports a backup from a newer, unknown version best-effort', () {
      final futureJson = jsonEncode({
        'format': 'kredit-backup',
        'version': kBackupFormatVersion + 1,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'credits': [buildLoan().toJson()],
      });

      final imported = importStateFromJson(futureJson);

      expect(imported.credits, hasLength(1));
      expect(imported.credits.single.id, 'l1');
    });

    test('throws InvalidBackupFormatException on malformed JSON shape', () {
      expect(
        () => importStateFromJson(jsonEncode({'nope': true})),
        throwsA(isA<InvalidBackupFormatException>()),
      );
    });

    test('throws InvalidBackupFormatException when credits is not a list', () {
      expect(
        () => importStateFromJson(jsonEncode({'credits': 'not-a-list'})),
        throwsA(isA<InvalidBackupFormatException>()),
      );
    });

    test('round-trips commercial quotas through export/import', () {
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

      final json = exportStateToJson([purchase], [quota]);
      final imported = importStateFromJson(json);

      expect(imported.quotas, hasLength(1));
      expect(imported.quotas.single.brand, 'Totto');
      expect(imported.credits.single.id, 'l1');
    });

    test('a v2 backup (no commercialQuotas key) migrates to an empty quota list', () {
      final v2Json = jsonEncode({
        'format': 'kredit-backup',
        'version': 2,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'credits': [buildLoan().toJson()],
      });

      final imported = importStateFromJson(v2Json);

      expect(imported.quotas, isEmpty);
      expect(imported.credits, hasLength(1));
    });
  });
}
