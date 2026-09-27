import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/interest_rate.dart';
import '../models/card_movement.dart';
import '../models/commercial_quota.dart';
import '../models/credit.dart';
import '../models/installment.dart';
import '../models/loan_abono.dart';
import 'connection.dart';
import 'tables.dart';

part 'database.g.dart';

/// App-wide Drift database. Replaces app.js's single Dexie `kv` table (which
/// just stashed the whole `state` object as one JSON blob) with a proper
/// relational schema — see lib/data/db/tables.dart for the mapping notes.
@DriftDatabase(
    tables: [Credits, Installments, CardMovements, LoanAbonos, CommercialQuotas])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  /// For tests: pass an in-memory executor directly.
  AppDatabase.forTesting(super.executor);

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
        // SQLite ignores FK constraints (like Credits.quotaId's
        // onDelete: restrict) unless this pragma is set per-connection —
        // it does not persist in the schema itself.
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  // --- Domain <-> row mapping -------------------------------------------

  LoanCredit _loanFromRow(
      CreditRow row, List<Installment> installments, List<LoanAbono> abonos) {
    return LoanCredit(
      id: row.id,
      name: row.name,
      lender: row.lender,
      color: row.color,
      notes: row.notes,
      location: row.location,
      card: row.card,
      totalAmount: row.totalAmount ?? 0,
      quotaAmount: row.quotaAmount ?? 0,
      totalInstallments: row.totalInstallments ?? 0,
      frequency: row.frequency ?? CreditFrequency.monthly,
      startDate: row.startDate ?? '',
      interestRate: row.interestRate ?? 0,
      interestRateType:
          row.interestRateType ?? InterestRateType.effectiveAnnual,
      installments: installments,
      abonos: abonos,
      scheduleManuallyAdjusted: row.scheduleManuallyAdjusted,
      quotaId: row.quotaId,
      interestUnknown: row.interestUnknown,
      earlyPaymentWaivesInterest: row.earlyPaymentWaivesInterest,
    );
  }

  CardCredit _cardFromRow(
      CreditRow row, List<CardMovement> movements) {
    return CardCredit(
      id: row.id,
      name: row.name,
      lender: row.lender,
      color: row.color,
      notes: row.notes,
      creditLimit: row.creditLimit ?? 0,
      currentBalance: row.currentBalance ?? 0,
      cutoffDay: row.cutoffDay ?? 1,
      paymentDueOffsetDays: row.paymentDueOffsetDays ?? 20,
      interestRate: row.interestRate ?? 0,
      interestRateType:
          row.interestRateType ?? InterestRateType.effectiveAnnual,
      managementFee: row.managementFee ?? 0,
      managementFeeFrequency:
          row.managementFeeFrequency ?? ManagementFeeFrequency.monthly,
      cycleCount: row.cycleCount ?? 0,
      lastAccrualCutoff: row.lastAccrualCutoff,
      movements: movements,
    );
  }

  CreditsCompanion _creditToCompanion(Credit credit) {
    if (credit is LoanCredit) {
      return CreditsCompanion.insert(
        id: credit.id,
        type: CreditType.loan,
        name: credit.name,
        lender: credit.lender,
        color: Value(credit.color),
        notes: Value(credit.notes),
        location: Value(credit.location),
        card: Value(credit.card),
        totalAmount: Value(credit.totalAmount),
        quotaAmount: Value(credit.quotaAmount),
        totalInstallments: Value(credit.totalInstallments),
        frequency: Value(credit.frequency),
        startDate: Value(credit.startDate),
        interestRate: Value(credit.interestRate),
        interestRateType: Value(credit.interestRateType),
        scheduleManuallyAdjusted: Value(credit.scheduleManuallyAdjusted),
        quotaId: Value(credit.quotaId),
        interestUnknown: Value(credit.interestUnknown),
        earlyPaymentWaivesInterest: Value(credit.earlyPaymentWaivesInterest),
      );
    } else if (credit is CardCredit) {
      return CreditsCompanion.insert(
        id: credit.id,
        type: CreditType.card,
        name: credit.name,
        lender: credit.lender,
        color: Value(credit.color),
        notes: Value(credit.notes),
        interestRate: Value(credit.interestRate),
        interestRateType: Value(credit.interestRateType),
        creditLimit: Value(credit.creditLimit),
        currentBalance: Value(credit.currentBalance),
        cutoffDay: Value(credit.cutoffDay),
        paymentDueOffsetDays: Value(credit.paymentDueOffsetDays),
        managementFee: Value(credit.managementFee),
        managementFeeFrequency: Value(credit.managementFeeFrequency),
        cycleCount: Value(credit.cycleCount),
        lastAccrualCutoff: Value(credit.lastAccrualCutoff),
      );
    }
    throw ArgumentError('Unknown credit subtype: ${credit.runtimeType}');
  }

  // --- Public API ----------------------------------------------------------

  /// Loads the full list of credits (with their installments/movements),
  /// equivalent to app.js's `state.credits` after loadState().
  Future<List<Credit>> loadAllCredits() async {
    final rows = await select(credits).get();
    final result = <Credit>[];
    for (final row in rows) {
      if (row.type == CreditType.card) {
        final movementRows = await (select(cardMovements)
              ..where((m) => m.creditId.equals(row.id))
              ..orderBy([(m) => OrderingTerm.asc(m.rowId)]))
            .get();
        result.add(_cardFromRow(
          row,
          movementRows
              .map((m) => CardMovement(
                    date: m.date,
                    type: m.type,
                    amount: m.amount,
                    note: m.note,
                  ))
              .toList(),
        ));
      } else {
        final instRows = await (select(installments)
              ..where((i) => i.creditId.equals(row.id))
              ..orderBy([(i) => OrderingTerm.asc(i.number)]))
            .get();
        final abonoRows = await (select(loanAbonos)
              ..where((a) => a.creditId.equals(row.id))
              ..orderBy([(a) => OrderingTerm.asc(a.rowId)]))
            .get();
        result.add(_loanFromRow(
          row,
          instRows
              .map((i) => Installment(
                    number: i.number,
                    dueDate: i.dueDate,
                    amount: i.amount,
                    principal: i.principal,
                    interest: i.interest,
                    paid: i.paid,
                    paymentDate: i.paymentDate,
                    interestWaived: i.interestWaived,
                  ))
              .toList(),
          abonoRows
              .map((a) => LoanAbono(
                    date: a.date,
                    amount: a.amount,
                    note: a.note,
                    installmentsSkipped: a.installmentsSkipped,
                    previousQuotaAmount: a.previousQuotaAmount,
                    previousInstallmentsSnapshot:
                        a.previousInstallmentsSnapshot == null
                            ? null
                            : (jsonDecode(a.previousInstallmentsSnapshot!)
                                    as List<dynamic>)
                                .map((e) => Installment.fromJson(
                                    e as Map<String, dynamic>))
                                .toList(),
                  ))
              .toList(),
        ));
      }
    }
    return result;
  }

  /// Inserts or fully replaces [credit] and its children (installments or
  /// movements), matching app.js's pattern of always writing the whole
  /// credit object back on save.
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

  Future<void> upsertCredit(Credit credit) async {
    await transaction(() async {
      await into(credits).insertOnConflictUpdate(_creditToCompanion(credit));

      if (credit is LoanCredit) {
        await (delete(installments)..where((i) => i.creditId.equals(credit.id)))
            .go();
        for (final inst in credit.installments) {
          await into(installments).insert(InstallmentsCompanion.insert(
            creditId: credit.id,
            number: inst.number,
            dueDate: inst.dueDate,
            amount: inst.amount,
            principal: inst.principal,
            interest: inst.interest,
            paid: Value(inst.paid),
            paymentDate: Value(inst.paymentDate),
            interestWaived: Value(inst.interestWaived),
          ));
        }
        await (delete(loanAbonos)..where((a) => a.creditId.equals(credit.id)))
            .go();
        for (final abono in credit.abonos) {
          await into(loanAbonos).insert(LoanAbonosCompanion.insert(
            creditId: credit.id,
            date: abono.date,
            amount: abono.amount,
            note: Value(abono.note),
            installmentsSkipped: Value(abono.installmentsSkipped),
            previousQuotaAmount: Value(abono.previousQuotaAmount),
            previousInstallmentsSnapshot: Value(
              abono.previousInstallmentsSnapshot == null
                  ? null
                  : jsonEncode(abono.previousInstallmentsSnapshot!
                      .map((i) => i.toJson())
                      .toList()),
            ),
          ));
        }
      } else if (credit is CardCredit) {
        await (delete(cardMovements)
              ..where((m) => m.creditId.equals(credit.id)))
            .go();
        for (final mv in credit.movements) {
          await into(cardMovements).insert(CardMovementsCompanion.insert(
            creditId: credit.id,
            date: mv.date,
            type: mv.type,
            amount: mv.amount,
            note: Value(mv.note),
          ));
        }
      }
    });
  }

  /// Deletes [creditId] and (via FK cascade) all its installments/movements.
  Future<void> deleteCredit(String creditId) =>
      (delete(credits)..where((c) => c.id.equals(creditId))).go();

  /// Deletes everything (clearAllData, app.js ~L1660-1669), including
  /// commercial quotas — a wipe must not leave orphaned cupo cards behind.
  Future<void> clearAllData() async {
    await transaction(() async {
      await delete(installments).go();
      await delete(cardMovements).go();
      await delete(loanAbonos).go();
      await delete(credits).go();
      await delete(commercialQuotas).go();
    });
  }

  /// Replaces both the credits and commercial-quotas tables with
  /// [newCredits]/[newQuotas] in a single transaction — a backup restore
  /// must never leave the database with some rows cleared and others not
  /// inserted (e.g. on a mid-restore FK failure). A credit whose `quotaId`
  /// doesn't match any of [newQuotas] has it nulled out instead of failing
  /// the whole restore (defends against a backup file edited by hand, or a
  /// future backup format that dropped a quota some credit still points
  /// to).
  Future<void> replaceAllData(
      List<Credit> newCredits, List<CommercialQuota> newQuotas) async {
    final quotaIds = newQuotas.map((q) => q.id).toSet();
    await transaction(() async {
      await delete(installments).go();
      await delete(cardMovements).go();
      await delete(loanAbonos).go();
      await delete(credits).go();
      await delete(commercialQuotas).go();
      for (final q in newQuotas) {
        await upsertCommercialQuota(q);
      }
      for (final c in newCredits) {
        if (c is LoanCredit && c.quotaId != null && !quotaIds.contains(c.quotaId)) {
          c.quotaId = null;
        }
        await upsertCredit(c);
      }
    });
  }
}
