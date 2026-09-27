# Cupo Comercial Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the user group commercial "cupos" (Totto, Lili Pink, Éxito CrediCompras, etc.) as a
light wrapper over existing `LoanCredit` purchases, showing brand + available/limit, without adding
a new `Credit` subtype or touching bank/card credits.

**Architecture:** New standalone `CommercialQuotas` table (brand + limit) referenced by a nullable
`quotaId` FK on the existing `Credits` table. Each "purchase" inside a cupo stays a normal
`LoanCredit` row — zero changes to `loan_calculator.dart`, `Installments`, or any existing
amortization/balance logic. A new pure function `quotaAvailable()` sums remaining balance of a
quota's purchases using the existing `getCreditRemainingBalance`/`creditHasUnpaid` helpers. UI adds
a grouping card on the Créditos screen and one conditional step in the wizard.

**Tech Stack:** Flutter, Riverpod (`AsyncNotifier`), Drift (SQLite), existing `credit_calculator.dart`/`loan_calculator.dart` domain layer.

**Spec:** `docs/superpowers/specs/2026-09-27-cupo-comercial-design.md`

## Global Constraints

- Bank/card credits (`CardCredit`, and `LoanCredit` rows without `quotaId`) must behave exactly as
  today — every new column is nullable or has a safe default, no backfill.
- Never calculate or assume an interest rate the user didn't provide; `interestUnknown` must
  suppress rate display, not synthesize a fake 0% rate as if it were real data.
- Never generalize the Lili Pink pronto-pago behavior automatically — `earlyPaymentWaivesInterest`
  is always a manual per-purchase flag, default `false`.
- Deleting a `CommercialQuota` with active (unpaid) purchases must fail loudly, never cascade-delete
  real `LoanCredit` data.
- `ROADMAP_KREDIT.md` must be updated with what was built once this plan finishes (per the user's
  standing instruction to log everything there — see the "Como funciona Kredit hoy" section, which
  must also be updated to describe cupo comercial once it exists).

## Review Focus

- A `LoanCredit` purchase whose `quotaId` points to a `CommercialQuota` that was later deleted (data
  corruption / manual DB edit) — `quotaAvailable`/grouping code must not crash the Créditos screen.
- A cupo with zero purchases yet — `quotaAvailable` must return the full limit, and the grouping
  card must render without a divide-by-zero or empty-list crash on the progress bar.
- Old JSON payloads / DB rows created before this change (no `quotaId`/`interestUnknown`/
  `earlyPaymentWaivesInterest` columns/keys) — must load with `quotaId: null`,
  `interestUnknown: false`, `earlyPaymentWaivesInterest: false`, never throw during
  `fromJson`/row-mapping.
- User sets a real `interestRate > 0` on a purchase that already had `interestUnknown: true` — the
  save path must clear the flag, never leave both "no rate known" and a nonzero rate visible at once.
- Attempting to delete a `CommercialQuota` that still has unpaid purchases referencing it — must
  surface a clear, translated error to the user, not a raw Drift/SQLite exception.

---

## Task 1: `CommercialQuota` domain model + `CommercialQuotas` Drift table

**Files:**
- Create: `lib/data/models/commercial_quota.dart`
- Modify: `lib/data/db/tables.dart` (add `CommercialQuotas` table, add 3 columns to `Credits`)
- Modify: `lib/data/db/database.dart` (register table in `@DriftDatabase`, bump `schemaVersion` to 6, add migration step)
- Test: `test/data/models/commercial_quota_test.dart`

**Interfaces:**
- Produces: `class CommercialQuota { String id; String brand; double limit; String? notes; CommercialQuota({required this.id, required this.brand, required this.limit, this.notes}); Map<String, dynamic> toJson(); factory CommercialQuota.fromJson(Map<String, dynamic> json); }`
- Produces: Drift table `CommercialQuotas` with columns `id (text, pk)`, `brand (text)`, `limit (real)`, `notes (text, nullable)`.
- Produces: `Credits` table gains `quotaId (text, nullable, FK -> CommercialQuotas.id, onDelete: KeyAction.restrict)`, `interestUnknown (bool, default false)`, `earlyPaymentWaivesInterest (bool, default false)`.

- [ ] **Step 1: Write the failing model test**

```dart
// test/data/models/commercial_quota_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kredit/data/models/commercial_quota.dart';

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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/models/commercial_quota_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:kredit/data/models/commercial_quota.dart'`

- [ ] **Step 3: Create the model**

```dart
// lib/data/models/commercial_quota.dart

/// A commercial credit line the user has with a brand/merchant (e.g. Totto,
/// Lili Pink, Éxito CrediCompras). Deliberately does not model the real
/// financial provider behind the brand (Keypago, Tuya, Credifactory) — the
/// user only ever sees the brand. Purchases inside this quota are normal
/// `LoanCredit` rows tagged with this quota's id via `LoanCredit.quotaId`.
class CommercialQuota {
  final String id;
  String brand;
  double limit;
  String? notes;

  CommercialQuota({
    required this.id,
    required this.brand,
    required this.limit,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand,
        'limit': limit,
        'notes': notes,
      };

  factory CommercialQuota.fromJson(Map<String, dynamic> json) =>
      CommercialQuota(
        id: json['id'] as String,
        brand: json['brand'] as String,
        limit: (json['limit'] as num).toDouble(),
        notes: json['notes'] as String?,
      );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/models/commercial_quota_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 5: Add the Drift table and new `Credits` columns**

In `lib/data/db/tables.dart`, add after the `Credits` class's existing card-only fields block
(right before `Set<Column> get primaryKey => {id};`):

```dart
  // --- commercial quota fields ---
  /// Links this loan/cupo purchase to its parent CommercialQuota, or null
  /// for a normal bank loan/card unrelated to any commercial quota.
  /// onDelete: restrict — deleting a quota with active purchases must fail
  /// loudly rather than silently orphan or cascade-delete real credit data.
  TextColumn get quotaId => text()
      .nullable()
      .references(CommercialQuotas, #id, onDelete: KeyAction.restrict)();

  /// True when the user chose not to provide/know the interest rate for
  /// this purchase — suppresses rate display, never synthesizes a fake 0%.
  BoolColumn get interestUnknown =>
      boolean().withDefault(const Constant(false))();

  /// True when this purchase's brand waives interest if paid before the
  /// due date (e.g. Lili Pink's CrediPink) — always a manual per-purchase
  /// flag, never assumed by default.
  BoolColumn get earlyPaymentWaivesInterest =>
      boolean().withDefault(const Constant(false))();
```

Then add a new table class in the same file (after the `Credits` class):

```dart
/// A commercial credit line with a brand (Totto, Lili Pink, Éxito...).
/// Purchases inside it are Credits rows with quotaId pointing here — see
/// Credits.quotaId above.
@DataClassName('CommercialQuotaRow')
class CommercialQuotas extends Table {
  TextColumn get id => text()();
  TextColumn get brand => text()();
  RealColumn get limit => real()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

- [ ] **Step 6: Register the table and add the migration in `database.dart`**

Change the `@DriftDatabase` annotation:

```dart
@DriftDatabase(
    tables: [Credits, Installments, CardMovements, LoanAbonos, CommercialQuotas])
```

Bump the schema version and add the migration step:

```dart
  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(credits, credits.interestRateType);
          }
          if (from < 3) {
            await m.createTable(loanAbonos);
          }
          if (from < 4) {
            await m.addColumn(credits, credits.scheduleManuallyAdjusted);
          }
          if (from < 5) {
            await m.addColumn(loanAbonos, loanAbonos.previousQuotaAmount);
            await m.addColumn(
                loanAbonos, loanAbonos.previousInstallmentsSnapshot);
          }
          if (from < 6) {
            await m.createTable(commercialQuotas);
            await m.addColumn(credits, credits.quotaId);
            await m.addColumn(credits, credits.interestUnknown);
            await m.addColumn(credits, credits.earlyPaymentWaivesInterest);
          }
        },
      );
```

- [ ] **Step 7: Regenerate Drift code**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: completes with no errors, `lib/data/db/database.g.dart` updated with `CommercialQuotaRow`/`CommercialQuotasCompanion` and the 3 new `Credits` columns.

- [ ] **Step 8: Run the full test suite to confirm nothing existing broke**

Run: `flutter test`
Expected: PASS (all existing tests + the 2 new ones)

- [ ] **Step 9: Commit**

```bash
git add lib/data/models/commercial_quota.dart lib/data/db/tables.dart lib/data/db/database.dart lib/data/db/database.g.dart test/data/models/commercial_quota_test.dart
git commit -m "feat: agrega modelo y tabla CommercialQuota + columnas de cupo en Credits"
```

---

## Task 2: `LoanCredit` gains `quotaId`/`interestUnknown`/`earlyPaymentWaivesInterest`

**Files:**
- Modify: `lib/data/models/credit.dart` (`LoanCredit` class only)
- Test: `test/data/models/credit_test.dart` (create if it doesn't exist)

**Interfaces:**
- Consumes: nothing new.
- Produces: `LoanCredit.quotaId (String?)`, `LoanCredit.interestUnknown (bool)`, `LoanCredit.earlyPaymentWaivesInterest (bool)`, all present in `toJson()`/`fromJson()`.

- [ ] **Step 1: Write the failing test for old-JSON backward compatibility**

```dart
// test/data/models/credit_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kredit/data/models/credit.dart';

void main() {
  group('LoanCredit cupo comercial fields', () {
    test('fromJson without new fields defaults safely', () {
      final loan = LoanCredit.fromJson({
        'id': 'l1',
        'name': 'Compra Totto',
        'lender': 'Totto',
        'totalAmount': 250000.0,
        'quotaAmount': 46500.0,
        'totalInstallments': 6,
        'frequency': 'monthly',
        'startDate': '2026-09-01',
      });

      expect(loan.quotaId, isNull);
      expect(loan.interestUnknown, isFalse);
      expect(loan.earlyPaymentWaivesInterest, isFalse);
    });

    test('toJson/fromJson round-trips the new fields', () {
      final loan = LoanCredit(
        id: 'l2',
        name: 'Compra Lili Pink',
        lender: 'Lili Pink',
        totalAmount: 100000,
        quotaAmount: 34000,
        totalInstallments: 3,
        frequency: CreditFrequency.monthly,
        startDate: '2026-09-01',
        quotaId: 'q1',
        interestUnknown: true,
        earlyPaymentWaivesInterest: true,
      );

      final restored = LoanCredit.fromJson(loan.toJson());

      expect(restored.quotaId, 'q1');
      expect(restored.interestUnknown, isTrue);
      expect(restored.earlyPaymentWaivesInterest, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/models/credit_test.dart`
Expected: FAIL — no named parameter `quotaId`/`interestUnknown`/`earlyPaymentWaivesInterest` on `LoanCredit`

- [ ] **Step 3: Add the fields to `LoanCredit`**

In `lib/data/models/credit.dart`, inside `class LoanCredit extends Credit`, add fields after
`bool scheduleManuallyAdjusted;`:

```dart
  /// Links this purchase to its parent CommercialQuota, or null if this is
  /// a normal bank loan unrelated to any commercial quota (Totto, Lili
  /// Pink, Éxito CrediCompras, etc.).
  String? quotaId;

  /// True when the user chose not to provide/know this purchase's interest
  /// rate — Kredit must only show a "sin intereses registrados" notice,
  /// never synthesize or display a fake rate.
  bool interestUnknown;

  /// True when this purchase's brand waives interest if paid before the
  /// due date (e.g. Lili Pink's CrediPink pronto-pago benefit). Always a
  /// manual per-purchase flag, never assumed by default.
  bool earlyPaymentWaivesInterest;
```

Update the constructor:

```dart
  LoanCredit({
    required super.id,
    required super.name,
    required super.lender,
    super.color,
    super.notes,
    this.location,
    this.card,
    required this.totalAmount,
    required this.quotaAmount,
    required this.totalInstallments,
    required this.frequency,
    required this.startDate,
    this.interestRate = 0,
    this.interestRateType = InterestRateType.effectiveAnnual,
    List<Installment>? installments,
    List<LoanAbono>? abonos,
    this.scheduleManuallyAdjusted = false,
    this.quotaId,
    this.interestUnknown = false,
    this.earlyPaymentWaivesInterest = false,
  })  : installments = installments ?? [],
        abonos = abonos ?? [],
        super(type: CreditType.loan);
```

Update `toJson()` (add before the closing `};`):

```dart
        'scheduleManuallyAdjusted': scheduleManuallyAdjusted,
        'quotaId': quotaId,
        'interestUnknown': interestUnknown,
        'earlyPaymentWaivesInterest': earlyPaymentWaivesInterest,
      };
```

Update `fromJson()` factory (add before the closing `);`):

```dart
        scheduleManuallyAdjusted:
            json['scheduleManuallyAdjusted'] as bool? ?? false,
        quotaId: json['quotaId'] as String?,
        interestUnknown: json['interestUnknown'] as bool? ?? false,
        earlyPaymentWaivesInterest:
            json['earlyPaymentWaivesInterest'] as bool? ?? false,
      );
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/models/credit_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 5: Run the full test suite**

Run: `flutter test`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/data/models/credit.dart test/data/models/credit_test.dart
git commit -m "feat: LoanCredit soporta quotaId/interestUnknown/earlyPaymentWaivesInterest"
```

---

## Task 3: Wire `AppDatabase` row-mapping and CRUD for `CommercialQuota` + updated `LoanCredit` mapping

**Files:**
- Modify: `lib/data/db/database.dart` (`_loanFromRow`, `upsertCredit`'s loan branch, add quota CRUD methods)
- Test: `test/data/db/commercial_quota_db_test.dart`

**Interfaces:**
- Consumes: `CommercialQuota` (Task 1), `LoanCredit.quotaId/interestUnknown/earlyPaymentWaivesInterest` (Task 2), generated `CommercialQuotaRow`/`CommercialQuotasCompanion` (Task 1, Step 7).
- Produces: `Future<List<CommercialQuota>> AppDatabase.loadAllCommercialQuotas()`, `Future<void> AppDatabase.upsertCommercialQuota(CommercialQuota quota)`, `Future<void> AppDatabase.deleteCommercialQuota(String id)` (throws if referenced by an unpaid purchase — see Step 3 for exact exception handling), and `_loanFromRow`/`upsertCredit` correctly round-trip the 3 new `LoanCredit` fields through the DB.

- [ ] **Step 1: Write the failing DB round-trip test**

```dart
// test/data/db/commercial_quota_db_test.dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/db/commercial_quota_db_test.dart`
Expected: FAIL — `loadAllCommercialQuotas`/`upsertCommercialQuota`/`deleteCommercialQuota` not defined on `AppDatabase`, and `LoanCredit`'s DB round-trip drops the 3 new fields.

- [ ] **Step 3: Add quota CRUD and fix loan row-mapping in `database.dart`**

Find `_loanFromRow` (near the top of the "Domain <-> row mapping" section) and add the 3 new
fields to its `LoanCredit(...)` construction:

```dart
  LoanCredit _loanFromRow(
      CreditRow row, List<Installment> installments, List<LoanAbono> abonos) {
    return LoanCredit(
      id: row.id,
      name: row.name,
      lender: row.lender,
      color: row.color,
      notes: row.notes,
      // ...keep every existing field assignment exactly as-is...
      quotaId: row.quotaId,
      interestUnknown: row.interestUnknown,
      earlyPaymentWaivesInterest: row.earlyPaymentWaivesInterest,
    );
  }
```

Find `upsertCredit`'s branch that builds a `CreditsCompanion` for a `LoanCredit` and add the 3
fields to that companion (mirror however `scheduleManuallyAdjusted` is already being written
there — same companion, same pattern, just 3 more named fields):

```dart
        quotaId: Value(credit.quotaId),
        interestUnknown: Value(credit.interestUnknown),
        earlyPaymentWaivesInterest: Value(credit.earlyPaymentWaivesInterest),
```

Add new CRUD methods anywhere in `AppDatabase` alongside `loadAllCredits`/`upsertCredit`:

```dart
  Future<List<CommercialQuota>> loadAllCommercialQuotas() async {
    final rows = await select(commercialQuotas).get();
    return rows
        .map((r) => CommercialQuota(
              id: r.id,
              brand: r.brand,
              limit: r.limit,
              notes: r.notes,
            ))
        .toList();
  }

  Future<void> upsertCommercialQuota(CommercialQuota quota) async {
    await into(commercialQuotas).insertOnConflictUpdate(
      CommercialQuotasCompanion.insert(
        id: quota.id,
        brand: quota.brand,
        limit: quota.limit,
        notes: Value(quota.notes),
      ),
    );
  }

  /// Throws a Drift/SQLite foreign-key-violation exception if any Credits
  /// row still references this quota (onDelete: restrict on Credits.quotaId
  /// — see tables.dart). Callers must catch and show a clear message
  /// instead of letting the raw exception reach the user.
  Future<void> deleteCommercialQuota(String id) async {
    await (delete(commercialQuotas)..where((q) => q.id.equals(id))).go();
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/db/commercial_quota_db_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 5: Run the full test suite**

Run: `flutter test`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/data/db/database.dart test/data/db/commercial_quota_db_test.dart
git commit -m "feat: CRUD de CommercialQuota + mapeo de campos de cupo en LoanCredit"
```

---

## Task 4: `quotaAvailable()` domain function

**Files:**
- Create: `lib/domain/commercial_quota_calculator.dart`
- Test: `test/domain/commercial_quota_calculator_test.dart`

**Interfaces:**
- Consumes: `CommercialQuota` (Task 1), `LoanCredit.quotaId` (Task 2), `getCreditRemainingBalance(Credit)` and `creditHasUnpaid(Credit)` from `lib/domain/credit_calculator.dart` (existing, unmodified).
- Produces: `double quotaAvailable(CommercialQuota quota, List<LoanCredit> allLoans)`.

- [ ] **Step 1: Write the failing tests**

```dart
// test/domain/commercial_quota_calculator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kredit/data/models/commercial_quota.dart';
import 'package:kredit/data/models/credit.dart';
import 'package:kredit/data/models/installment.dart';
import 'package:kredit/domain/commercial_quota_calculator.dart';

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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/commercial_quota_calculator_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:kredit/domain/commercial_quota_calculator.dart'`

- [ ] **Step 3: Implement the function**

```dart
// lib/domain/commercial_quota_calculator.dart
import '../data/models/commercial_quota.dart';
import '../data/models/credit.dart';
import 'credit_calculator.dart';

/// How much of [quota]'s limit is still free, given every purchase
/// (LoanCredit) tagged with this quota's id. Fully reuses the existing
/// balance/unpaid logic from credit_calculator.dart — a cupo comercial is
/// never a new kind of financial math, just a grouping over LoanCredits.
///
/// Deliberately not clamped to zero: a negative result is real information
/// (the user is over their registered limit) and the UI decides how to
/// warn about it, not this function.
double quotaAvailable(CommercialQuota quota, List<LoanCredit> allLoans) {
  final usedByUnpaid = allLoans
      .where((l) => l.quotaId == quota.id)
      .where(creditHasUnpaid)
      .fold(0.0, (sum, p) => sum + getCreditRemainingBalance(p));
  return quota.limit - usedByUnpaid;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/domain/commercial_quota_calculator_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 5: Run the full test suite**

Run: `flutter test`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/domain/commercial_quota_calculator.dart test/domain/commercial_quota_calculator_test.dart
git commit -m "feat: agrega quotaAvailable() para calcular disponible de un cupo comercial"
```

---

## Task 5: `commercialQuotasProvider` + clear-`interestUnknown`-on-save rule

**Files:**
- Create: `lib/providers/commercial_quotas_provider.dart`
- Modify: `lib/providers/credits_provider.dart` (add the interestUnknown-clearing rule to the existing save/upsert path)
- Test: `test/providers/commercial_quotas_provider_test.dart`
- Test: `test/providers/credits_provider_interest_unknown_test.dart`

**Interfaces:**
- Consumes: `AppDatabase.loadAllCommercialQuotas/upsertCommercialQuota/deleteCommercialQuota` (Task 3), `databaseProvider` (existing).
- Produces: `commercialQuotasProvider` (`AsyncNotifierProvider<CommercialQuotasNotifier, List<CommercialQuota>>`) with methods `Future<void> upsert(CommercialQuota quota)` and `Future<void> delete(String id)`.

- [ ] **Step 1: Inspect the existing `CreditsNotifier` upsert entrypoint before writing anything**

Run: `grep -n "Future<void> upsert\|Future<void> saveCredit\|Future<void> addCredit" lib/providers/credits_provider.dart`

Use whichever method name that returns actually saves/updates a credit — the plan below assumes
it's a method that receives a `Credit` and calls `_db.upsertCredit(credit)` before refreshing
`state`; adapt the exact clearing snippet in Step 5 to wherever that call site actually is if the
name differs.

- [ ] **Step 2: Write the failing provider test**

```dart
// test/providers/commercial_quotas_provider_test.dart
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kredit/data/db/database.dart';
import 'package:kredit/data/models/commercial_quota.dart';
import 'package:kredit/providers/commercial_quotas_provider.dart';
import 'package:kredit/providers/database_provider.dart';

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
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/providers/commercial_quotas_provider_test.dart`
Expected: FAIL — `commercial_quotas_provider.dart` doesn't exist

- [ ] **Step 4: Implement the provider**

```dart
// lib/providers/commercial_quotas_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../data/models/commercial_quota.dart';
import 'database_provider.dart';

part 'commercial_quotas_provider.g.dart';

@riverpod
class CommercialQuotasNotifier extends _$CommercialQuotasNotifier {
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
```

If `credits_provider.dart` uses a hand-written `AsyncNotifierProvider` instead of the
`@riverpod`-annotated code-gen style (check the top of that file for `part '...provider.g.dart'`
vs. a manual `final creditsProvider = AsyncNotifierProvider<...>(...)` declaration) — mirror
whichever style is actually used there instead of the `@riverpod` annotation above, so the new
provider matches the codebase's real pattern.

- [ ] **Step 5: Add the interestUnknown-clearing rule to the credits save path**

At the save/upsert method identified in Step 1, right before the call to `_db.upsertCredit(credit)`,
add:

```dart
    if (credit is LoanCredit && credit.interestRate > 0) {
      credit.interestUnknown = false;
    }
```

- [ ] **Step 6: Write the failing test for the clearing rule**

```dart
// test/providers/credits_provider_interest_unknown_test.dart
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kredit/data/db/database.dart';
import 'package:kredit/data/models/credit.dart';
import 'package:kredit/providers/credits_provider.dart';
import 'package:kredit/providers/database_provider.dart';

void main() {
  test('saving a purchase with interestRate > 0 clears interestUnknown', () async {
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

    // Adjust this call to whatever save/upsert method Step 1 identified.
    await container.read(creditsProvider.notifier).upsert(loan);

    final saved = (await container.read(creditsProvider.future))
        .whereType<LoanCredit>()
        .single;

    expect(saved.interestUnknown, isFalse);
  });
}
```

- [ ] **Step 7: Run test to verify it fails, then passes**

Run: `flutter test test/providers/credits_provider_interest_unknown_test.dart`
Expected: FAIL before Step 5's edit is picked up by codegen (if `@riverpod` codegen is in play,
run `dart run build_runner build --delete-conflicting-outputs` first), then PASS after.

- [ ] **Step 8: Run the full test suite**

Run: `flutter test`
Expected: PASS

- [ ] **Step 9: Commit**

```bash
git add lib/providers/commercial_quotas_provider.dart lib/providers/credits_provider.dart test/providers/commercial_quotas_provider_test.dart test/providers/credits_provider_interest_unknown_test.dart
git commit -m "feat: agrega commercialQuotasProvider y limpia interestUnknown al guardar tasa real"
```

(If codegen produced `lib/providers/commercial_quotas_provider.g.dart`, add it to the same commit.)

---

## Task 6: Créditos screen groups purchases under a quota card

**Files:**
- Create: `lib/widgets/credits/commercial_quota_card.dart`
- Modify: `lib/screens/credits/credits_screen.dart` (or wherever the Créditos list is rendered — confirm exact filename first)
- Test: `test/widgets/credits/commercial_quota_card_test.dart`

**Interfaces:**
- Consumes: `CommercialQuota` (Task 1), `LoanCredit` (Task 2), `quotaAvailable()` (Task 4), `commercialQuotasProvider` (Task 5), `creditsProvider` (existing).
- Produces: `class CommercialQuotaCard extends StatelessWidget { final CommercialQuota quota; final List<LoanCredit> purchases; const CommercialQuotaCard({super.key, required this.quota, required this.purchases}); }` — renders brand, an available/limit progress bar, and one row per purchase (name + remaining balance), tappable to open that purchase's detail like any other credit today.

- [ ] **Step 1: Locate the exact Créditos list file and its credit-list-building code**

Run: `grep -rln "creditsProvider" lib/screens/credits/`

Read that file's build method to find where it currently maps `List<Credit>` to a flat list of
cards, so Step 4 below inserts the grouping in the right place without guessing at surrounding
widget names.

- [ ] **Step 2: Write the failing widget test for the new card**

```dart
// test/widgets/credits/commercial_quota_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kredit/data/models/commercial_quota.dart';
import 'package:kredit/data/models/credit.dart';
import 'package:kredit/widgets/credits/commercial_quota_card.dart';

void main() {
  testWidgets('shows brand and per-purchase rows', (tester) async {
    final quota = CommercialQuota(id: 'q1', brand: 'Totto', limit: 700000);
    final purchase = LoanCredit(
      id: 'l1',
      name: 'Compra tenis',
      lender: 'Totto',
      totalAmount: 250000,
      quotaAmount: 46500,
      totalInstallments: 6,
      frequency: CreditFrequency.monthly,
      startDate: '2026-09-01',
      quotaId: 'q1',
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CommercialQuotaCard(quota: quota, purchases: [purchase]),
      ),
    ));

    expect(find.text('Totto'), findsOneWidget);
    expect(find.text('Compra tenis'), findsOneWidget);
  });

  testWidgets('renders with zero purchases without crashing', (tester) async {
    final quota = CommercialQuota(id: 'q1', brand: 'Totto', limit: 700000);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CommercialQuotaCard(quota: quota, purchases: const []),
      ),
    ));

    expect(find.text('Totto'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/widgets/credits/commercial_quota_card_test.dart`
Expected: FAIL — file doesn't exist

- [ ] **Step 4: Implement `CommercialQuotaCard`**

```dart
// lib/widgets/credits/commercial_quota_card.dart
import 'package:flutter/material.dart';

import '../../data/models/commercial_quota.dart';
import '../../data/models/credit.dart';
import '../../domain/commercial_quota_calculator.dart';
import '../../domain/credit_calculator.dart';
import '../../domain/format_money.dart'; // formatCOP — confirm exact import path in Step 1's file

class CommercialQuotaCard extends StatelessWidget {
  final CommercialQuota quota;
  final List<LoanCredit> purchases;

  const CommercialQuotaCard({
    super.key,
    required this.quota,
    required this.purchases,
  });

  @override
  Widget build(BuildContext context) {
    final available = quotaAvailable(quota, purchases);
    final ratio = quota.limit <= 0
        ? 0.0
        : (available / quota.limit).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(quota.brand, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: ratio),
            const SizedBox(height: 4),
            Text('${formatCOP(available)} disponible de ${formatCOP(quota.limit)}'),
            const SizedBox(height: 12),
            for (final purchase in purchases)
              ListTile(
                title: Text(purchase.name),
                trailing: Text(formatCOP(getCreditRemainingBalance(purchase))),
              ),
          ],
        ),
      ),
    );
  }
}
```

Note: confirm the real money-formatting helper's import path/name in Step 1's file (the codebase
already has a shared `formatCOP()` per prior session work) and adjust the import if it differs
from the placeholder path above.

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/widgets/credits/commercial_quota_card_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 6: Wire the card into the Créditos screen**

In the file found in Step 1, watch `commercialQuotasProvider` alongside the existing
`creditsProvider` watch, partition the loaded `List<Credit>` into loans with a non-null `quotaId`
vs. everything else, and render one `CommercialQuotaCard` per quota (passing that quota's matching
purchases) above/alongside the existing flat list of ungrouped credits. Keep every credit without a
`quotaId` rendering exactly as it does today — this task only adds grouping for the new case, it
does not change the existing rendering path for bank loans/cards.

- [ ] **Step 7: Run the full test suite**

Run: `flutter test`
Expected: PASS

- [ ] **Step 8: Manual device check**

Run: `flutter run -d ZY22LBQ8XS`, using ADB/uiautomator as established in this project: create a
`PRUEBA_BORRAR_` cupo comercial with a couple of `PRUEBA_BORRAR_` purchases through whatever
temporary means Task 7's wizard step will later provide (for this task, it's fine to insert test
rows directly via a temporary debug button or by running the Task 3 DB test manually against the
live app's DB path) to visually confirm the card renders brand + progress bar + purchase rows
correctly, then delete the `PRUEBA_BORRAR_*` rows immediately. Do not leave test data in place.

- [ ] **Step 9: Commit**

```bash
git add lib/widgets/credits/commercial_quota_card.dart lib/screens/credits/<archivo_real>.dart test/widgets/credits/commercial_quota_card_test.dart
git commit -m "feat: agrupa compras de un cupo comercial bajo una tarjeta con disponible/limite"
```

---

## Task 7: Wizard step to attach a purchase to a quota (or create one)

**Files:**
- Modify: `lib/screens/credits/add_credit_sheet.dart`
- Test: manual device test only (this widget's existing test coverage in the codebase is manual/ADB-based per prior sessions, not automated widget tests — follow that established pattern rather than introducing a new automated harness for this one screen)

**Interfaces:**
- Consumes: `commercialQuotasProvider` (Task 5), `CommercialQuota` (Task 1), the existing wizard's step-state machine in `add_credit_sheet.dart` (read it first — do not guess field/method names).

- [ ] **Step 1: Read the existing wizard step machinery before changing anything**

Run: `grep -n "_step1BasicData\|_currentStep\|PageRouteBuilder\|AnimatedSwitcher\|class _AddCreditSheetState" lib/screens/credits/add_credit_sheet.dart`

Confirm exactly how steps are added/ordered and how `_type` (loan vs card) gates which steps show,
since this task's new step must only appear for the loan (cupo) flow, never for cards.

- [ ] **Step 2: Add the quota-selection UI**

Only for `_type == CreditType.loan`, add a step (following whatever step-numbering/transition
pattern Step 1 revealed) containing:
- A toggle/checkbox: "Es una compra de un cupo comercial" (default off — unrelated bank loans must
  be entirely unaffected, this stays opt-in).
- If enabled: a dropdown built from `ref.watch(commercialQuotasProvider).valueOrNull ?? []`,
  listing each quota's `brand`, plus a final "Crear cupo nuevo" entry.
- If "Crear cupo nuevo" is chosen: two inline fields (marca, límite) that, on continuing, call
  `ref.read(commercialQuotasProvider.notifier).upsert(CommercialQuota(id: <new uuid, matching
  however existing credit ids are generated in this file>, brand: <input>, limit: <input>))` and
  set the newly created quota's id as the selected one.
- Store the selected quota's id in whatever local field this widget uses to accumulate the credit
  being built (mirror how `_lenderCtrl`/existing fields are already staged before final save), so
  it becomes `LoanCredit.quotaId` when the credit is actually saved at the end of the wizard.

- [ ] **Step 3: Add the interestUnknown / earlyPaymentWaivesInterest controls to the rate step**

Wherever `interestRate`/`interestRateType` are currently collected in this same file, add:
- A choice control ("Conozco la tasa" / "No la conozco") that sets `interestUnknown` and, when "no
  la conozco" is picked, hides the rate input entirely and shows "Cuenta sin intereses registrados"
  static text instead — never a computed/synthesized rate.
- A checkbox "Si pago antes de la fecha de pago, no cobran interés" bound to
  `earlyPaymentWaivesInterest`, unchecked by default, shown only when a quota is attached (Step 2).

- [ ] **Step 4: Run the full test suite**

Run: `flutter test`
Expected: PASS (no automated tests changed in this task, this just confirms nothing else broke)

- [ ] **Step 5: Manual device test — full flow, using only `PRUEBA_BORRAR_*` data**

Run: `flutter run -d ZY22LBQ8XS`. Via ADB/uiautomator:
1. Open "Nuevo Crédito", type = préstamo/cupo.
2. Enable "Es una compra de un cupo comercial", choose "Crear cupo nuevo", enter brand
   `PRUEBA_BORRAR_Totto`, limit `700000`.
3. Finish the purchase with amount `250000`, 6 installments, "No la conozco" for the rate.
4. Confirm on the Créditos screen: a `CommercialQuotaCard` for `PRUEBA_BORRAR_Totto` shows
   available `450000` de `700000`, with the purchase listed inside it showing "Cuenta sin
   intereses registrados" in its detail.
5. Create a second `PRUEBA_BORRAR_` purchase under the same quota, confirm available updates
   correctly (`450000 - <segunda compra>`).
6. Delete both `PRUEBA_BORRAR_` purchases, then delete the `PRUEBA_BORRAR_Totto` quota, confirming
   the quota card disappears and no orphaned data remains.

Report back to the user what was visually observed at each of these 6 points before considering
this task done — this is the step that answers "cómo se ve visualmente y cómo aplica las
funcionalidades".

- [ ] **Step 6: Commit**

```bash
git add lib/screens/credits/add_credit_sheet.dart
git commit -m "feat: wizard permite asociar una compra a un cupo comercial o crear uno nuevo"
```

---

## Task 8: Update `ROADMAP_KREDIT.md`

**Files:**
- Modify: `ROADMAP_KREDIT.md`

**Interfaces:**
- Consumes: nothing code-level — this is documentation only.

- [ ] **Step 1: Add a dated section describing what was built**

Append a new `## Cupo comercial — 2026-09-27` (or the actual completion date) section
summarizing: the `CommercialQuota` model/table, the `LoanCredit` field additions, `quotaAvailable()`,
the Créditos screen grouping, and the wizard step — in the same narrative style as the existing
"Una entidad, un registro" section, including the Totto/Lili Pink/Éxito research findings on
per-purchase installments and Lili Pink's pronto-pago benefit (with the caveat that it's not
confirmed for Totto/Éxito).

- [ ] **Step 2: Update the "Como funciona Kredit hoy" functional guide section**

In the same file's screen-by-screen guide (added in an earlier session), update the Créditos
screen's description and the wizard's step list to mention the new cupo comercial grouping and
step, per that section's own self-maintenance rule.

- [ ] **Step 3: Commit**

```bash
git add ROADMAP_KREDIT.md
git commit -m "docs: registra cupo comercial en ROADMAP_KREDIT.md"
```

---

## Self-Review Notes

**Spec coverage:** every spec section has a task — data model → Tasks 1-2, domain logic → Task 4,
providers/error clearing → Task 5, UI (screen grouping, wizard, sin-intereses notice) → Tasks 6-7,
error handling (restrict-delete, negative available, migration safety) → Tasks 1/3/4 tests,
testing section → each task's own tests, roadmap logging → Task 8.

**Type consistency check:** `CommercialQuota(id, brand, limit, notes)` used identically in Tasks
1/3/4/5/6/7. `quotaAvailable(CommercialQuota, List<LoanCredit>)` signature identical everywhere
it's called (Tasks 4, 6). `getCreditRemainingBalance`/`creditHasUnpaid` used with their real,
verified names (not the placeholder names from the initial spec draft, corrected before this plan
was written).

**Placeholder scan:** the two spots that say "confirm exact filename/import path in Step 1" (Tasks
6 and 7) are intentional — this codebase's exact screen filename and money-formatter import weren't
re-verified line-by-line for this plan, and each of those tasks opens by grep-ing for the true name
before writing code, rather than the plan guessing wrong. Every other step has concrete code.

**Review Focus coverage:** dangling `quotaId` after quota deletion → prevented at the DB layer by
`onDelete: KeyAction.restrict` (Task 1) plus Task 3's explicit test that deletion throws; zero-
purchase quota → Task 4's first test + Task 6's second widget test; old-JSON/DB rows → Task 2's
backward-compat test + Task 1's nullable/default columns; interestUnknown-clearing → Task 5 Step
6's test; delete-with-active-purchases error surfacing → Task 3's test at the DB layer (UI-level
friendly-message wrapping is called out in Task 7 Step 5's manual test but is not a separate
automated test, since the existing codebase's error-surfacing pattern for this kind of DB exception
should be confirmed against whatever try/catch convention `add_credit_sheet.dart` already uses
elsewhere, per Task 7 Step 1's read-first instruction).
