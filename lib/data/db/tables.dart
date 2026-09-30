import 'package:drift/drift.dart';

/// Common credit fields (both loan/cupo and card) plus every type-specific
/// field, stored nullable, discriminated by [type]. Mirrors the flat shape
/// of a single entry in app.js's `state.credits` array (see
/// legacy_pwa/js/app.js — saveCredit ~L420-492).
@DataClassName('CreditRow')
class Credits extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()(); // 'loan' | 'card'
  TextColumn get name => text()();
  TextColumn get lender => text()();
  TextColumn get color => text().nullable()();
  TextColumn get notes => text().nullable()();

  // --- loan/cupo-only fields ---
  TextColumn get location => text().nullable()();
  TextColumn get card => text().nullable()();
  RealColumn get totalAmount => real().nullable()();
  RealColumn get quotaAmount => real().nullable()();
  IntColumn get totalInstallments => integer().nullable()();
  TextColumn get frequency => text().nullable()(); // weekly|biweekly|monthly
  TextColumn get startDate => text().nullable()(); // YYYY-MM-DD

  // shared by both (loan's tasa vs card's tasa E.A.)
  RealColumn get interestRate => real().nullable()();

  // --- loan-only: schedule-integrity flag ---
  /// True once this loan's installment schedule has diverged from the pure
  /// French amortization derived from its base fields (totalAmount,
  /// quotaAmount, totalInstallments, interestRate/Type) — e.g. via
  /// applyLoanAbono's reamortization or registerInstallmentActualPayment's
  /// principal adjustment. `recomputeLoanInstallments` must NEVER be run
  /// again on a loan with this flag set: it would silently discard the
  /// manual adjustment and rebuild the original pre-adjustment schedule.
  /// See CreditsNotifier.build() in lib/providers/credits_provider.dart.
  BoolColumn get scheduleManuallyAdjusted =>
      boolean().withDefault(const Constant(false))();
  // card-only: how interestRate is expressed (effectiveAnnual|
  // effectiveMonthly|nominalMonthly). Null on rows created before this
  // column existed; treated as effectiveAnnual (legacy behavior).
  TextColumn get interestRateType => text().nullable()();

  // --- card-only fields ---
  RealColumn get creditLimit => real().nullable()();
  RealColumn get currentBalance => real().nullable()();
  IntColumn get cutoffDay => integer().nullable()();
  IntColumn get paymentDueOffsetDays => integer().nullable()();
  RealColumn get managementFee => real().nullable()();
  TextColumn get managementFeeFrequency => text().nullable()(); // monthly|annual
  IntColumn get cycleCount => integer().nullable()();
  TextColumn get lastAccrualCutoff => text().nullable()(); // YYYY-MM-DD

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

  /// Card background design identifier — one of the 8 CardDesign enum values
  /// serialized as String (e.g. 'gradiente', 'swissGrid', 'liquido', etc.).
  /// Null means 'gradiente' (default gradient look).
  TextColumn get cardDesign => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A commercial credit line with a brand (Totto, Lili Pink, Éxito...).
/// Purchases inside it are Credits rows with quotaId pointing here — see
/// Credits.quotaId above.
///
/// Also used for bank entities (Bancolombia, Davivienda…) and app-based
/// lenders (Addi, Rapicredit…) since v8 via [entityType].
@DataClassName('CommercialQuotaRow')
class CommercialQuotas extends Table {
  TextColumn get id => text()();
  TextColumn get brand => text()();
  RealColumn get limit => real()();
  TextColumn get notes => text().nullable()();

  /// [VoucherPattern.name] chosen for every purchase under this quota —
  /// per-quota, never a single app-wide setting: two different cupos
  /// (e.g. "Joy" and "Totto") can each show a different abstract pattern
  /// on their vouchers. Null means "not chosen yet", falls back to the
  /// first pattern in code (see VoucherPattern.fromName).
  TextColumn get voucherPattern => text().nullable()();

  /// 'store' | 'bank' | 'app' — distinguishes credit stores (Totto),
  /// bank cards (Bancolombia), and app lenders (Addi). Default 'store'
  /// so all rows created before v8 are correctly classified.
  TextColumn get entityType =>
      text().withDefault(const Constant('store'))();

  // --- bank / card entity fields (null for stores) ---
  IntColumn get cutoffDay => integer().nullable()();
  IntColumn get paymentOffsetDays => integer().nullable()();
  RealColumn get managementFee => real().nullable()();
  TextColumn get managementFeeFrequency => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One row per loan/cupo installment. Mirrors app.js's `installments[]`
/// (buildLoanInstallments ~L388-418, applyInstallmentPayment ~L627-648).
@DataClassName('InstallmentRow')
class Installments extends Table {
  IntColumn get rowId => integer().autoIncrement()();
  TextColumn get creditId =>
      text().references(Credits, #id, onDelete: KeyAction.cascade)();
  IntColumn get number => integer()();
  TextColumn get dueDate => text()(); // YYYY-MM-DD
  RealColumn get amount => real()();
  RealColumn get principal => real()();
  RealColumn get interest => real()();
  BoolColumn get paid => boolean().withDefault(const Constant(false))();
  TextColumn get paymentDate => text().nullable()(); // ISO datetime
  BoolColumn get interestWaived =>
      boolean().withDefault(const Constant(false))();
}

/// One row per card movement. Mirrors app.js's `movements[]`
/// (registerCardMovement ~L763-773, accrueCardCredit ~L703-756).
@DataClassName('CardMovementRow')
class CardMovements extends Table {
  IntColumn get rowId => integer().autoIncrement()();
  TextColumn get creditId =>
      text().references(Credits, #id, onDelete: KeyAction.cascade)();
  TextColumn get date => text()(); // YYYY-MM-DD
  TextColumn get type => text()(); // charge|payment|interest|fee
  RealColumn get amount => real()();
  TextColumn get note => text().withDefault(const Constant(''))();
}

/// One row per loan "abono extra" (extra manual payment). Mirrors
/// lib/data/models/loan_abono.dart; see applyLoanAbono in
/// lib/domain/loan_calculator.dart for how the amount/installmentsSkipped
/// are derived.
@DataClassName('LoanAbonoRow')
class LoanAbonos extends Table {
  IntColumn get rowId => integer().autoIncrement()();
  TextColumn get creditId =>
      text().references(Credits, #id, onDelete: KeyAction.cascade)();
  TextColumn get date => text()(); // YYYY-MM-DD
  RealColumn get amount => real()();
  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get installmentsSkipped =>
      integer().withDefault(const Constant(0))();

  /// `loan.quotaAmount` immediately before this abono reamortized the
  /// schedule — null for abonos predating this column, or for the
  /// settle-the-whole-loan case. See LoanAbono.previousQuotaAmount.
  RealColumn get previousQuotaAmount => real().nullable()();

  /// JSON-encoded list of the unpaid installments' pre-abono state — null
  /// for abonos predating this column, or for the settle-the-whole-loan
  /// case. See LoanAbono.previousInstallmentsSnapshot.
  TextColumn get previousInstallmentsSnapshot => text().nullable()();
}
