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
}
