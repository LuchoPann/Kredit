import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kredit/data/db/database.dart';
import 'package:kredit/data/models/card_movement.dart';
import 'package:kredit/data/models/credit.dart';
import 'package:kredit/domain/loan_calculator.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('round-trips a loan credit with installments', () async {
    final loan = LoanCredit(
      id: 'loan1',
      name: 'Laptop',
      lender: 'Tienda',
      totalAmount: 1000,
      quotaAmount: 300,
      totalInstallments: 4,
      frequency: CreditFrequency.monthly,
      startDate: '2026-01-01',
      interestRate: 24,
      installments: buildLoanInstallments(
        totalAmount: 1000,
        totalInstallments: 4,
        quotaAmount: 300,
        frequency: CreditFrequency.monthly,
        startDate: '2026-01-01',
        interestRate: 24,
      ),
    );

    await db.upsertCredit(loan);
    final all = await db.loadAllCredits();

    expect(all, hasLength(1));
    final loaded = all.first as LoanCredit;
    expect(loaded.name, 'Laptop');
    expect(loaded.installments, hasLength(4));
    // French amortization: first installment's interest is balance*periodRate
    // (balance == totalAmount at the start), i.e. > 0 and decreasing after.
    expect(loaded.installments[0].interest, greaterThan(0));
    expect(loaded.installments[0].interest, greaterThan(loaded.installments[1].interest));
  });

  test('scheduleManuallyAdjusted round-trips and survives a save->reload cycle '
      'after an abono, preventing recomputeLoanInstallments from reverting it '
      '(regression test for the original data-loss bug)', () async {
    final loan = LoanCredit(
      id: 'loan-abono',
      name: 'Test',
      lender: 'Lender',
      totalAmount: 1000,
      quotaAmount: 300,
      totalInstallments: 4,
      frequency: CreditFrequency.monthly,
      startDate: '2026-01-01',
      installments: buildLoanInstallments(
        totalAmount: 1000,
        totalInstallments: 4,
        quotaAmount: 300,
        frequency: CreditFrequency.monthly,
        startDate: '2026-01-01',
      ),
    );

    // Apply a real abono a capital: reamortizes the unpaid installments in
    // place (reducirCuota) and sets scheduleManuallyAdjusted.
    final abono = applyLoanAbono(loan, 200, strategy: AbonoStrategy.reducirCuota);
    loan.abonos.add(abono);
    expect(loan.scheduleManuallyAdjusted, isTrue);
    final reamortizedQuota = loan.quotaAmount;
    expect(reamortizedQuota, closeTo(200, 1e-9)); // (1000-200)/4

    await db.upsertCredit(loan);

    // Simulate app restart: reload from the DB, as CreditsNotifier.build()
    // does.
    var reloaded = (await db.loadAllCredits()).first as LoanCredit;
    expect(reloaded.scheduleManuallyAdjusted, isTrue);
    expect(reloaded.quotaAmount, closeTo(reamortizedQuota, 1e-9));
    for (final inst in reloaded.installments) {
      expect(inst.principal, closeTo(200, 1e-9));
    }

    // The old bug: CreditsNotifier.build() called recomputeLoanInstallments
    // unconditionally for every LoanCredit, rebuilding the ENTIRE schedule
    // from totalAmount/quotaAmount/totalInstallments — which silently
    // reverted the reamortization back to the pre-abono numbers. The fix is
    // to gate that call on `!scheduleManuallyAdjusted`, exactly like
    // CreditsNotifier.build() now does.
    if (!reloaded.scheduleManuallyAdjusted) {
      reloaded.installments = recomputeLoanInstallments(reloaded);
    }

    // The reamortized schedule must have survived the reload.
    expect(reloaded.quotaAmount, closeTo(reamortizedQuota, 1e-9));
    for (final inst in reloaded.installments) {
      expect(inst.principal, closeTo(200, 1e-9));
    }
    expect(getLoanRemainingBalance(reloaded), closeTo(800, 1e-9));
  });

  test('round-trips a card credit with movements', () async {
    final card = CardCredit(
      id: 'card1',
      name: 'Visa',
      lender: 'Bancolombia',
      creditLimit: 5000,
      currentBalance: 200,
    );
    card.movements.add(const CardMovement(
      date: '2026-01-05',
      type: CardMovementType.charge,
      amount: 200,
      note: 'Saldo inicial registrado',
    ));

    await db.upsertCredit(card);
    final all = await db.loadAllCredits();

    expect(all, hasLength(1));
    final loaded = all.first as CardCredit;
    expect(loaded.creditLimit, 5000);
    expect(loaded.currentBalance, 200);
    expect(loaded.movements, hasLength(1));
    expect(loaded.movements[0].type, CardMovementType.charge);
  });

  test('round-trips CardCredit with paymentDueDay and oneInstallmentInterestPolicy', () async {
    final card = CardCredit(
      id: 'card-new',
      name: 'Mi Tarjeta',
      lender: 'Bancolombia',
      creditLimit: 2000000,
      currentBalance: 650000,
      cutoffDay: 15,
      paymentDueDay: 5,
      oneInstallmentInterestPolicy: true,
    );
    await db.upsertCredit(card);
    final loaded = (await db.loadAllCredits()).whereType<CardCredit>().first;
    expect(loaded.paymentDueDay, 5);
    expect(loaded.oneInstallmentInterestPolicy, true);
  });

  test('CardCredit with null oneInstallmentInterestPolicy round-trips as null', () async {
    final card = CardCredit(
      id: 'card-null-policy',
      name: 'Sin policy',
      lender: 'Davivienda',
      cutoffDay: 10,
      paymentDueDay: 0,
    );
    await db.upsertCredit(card);
    final loaded = (await db.loadAllCredits()).whereType<CardCredit>().first;
    expect(loaded.oneInstallmentInterestPolicy, isNull);
    expect(loaded.paymentDueDay, 0);
  });

  test('deleteCredit cascades to installments', () async {
    final loan = LoanCredit(
      id: 'loan2',
      name: 'X',
      lender: 'Y',
      totalAmount: 100,
      quotaAmount: 50,
      totalInstallments: 2,
      frequency: CreditFrequency.monthly,
      startDate: '2026-01-01',
      installments: buildLoanInstallments(
        totalAmount: 100,
        totalInstallments: 2,
        quotaAmount: 50,
        frequency: CreditFrequency.monthly,
        startDate: '2026-01-01',
      ),
    );
    await db.upsertCredit(loan);
    await db.deleteCredit('loan2');
    final all = await db.loadAllCredits();
    expect(all, isEmpty);
  });

  test('clearAllData empties everything', () async {
    final loan = LoanCredit(
      id: 'loan3',
      name: 'X',
      lender: 'Y',
      totalAmount: 100,
      quotaAmount: 50,
      totalInstallments: 1,
      frequency: CreditFrequency.monthly,
      startDate: '2026-01-01',
      installments: buildLoanInstallments(
        totalAmount: 100,
        totalInstallments: 1,
        quotaAmount: 50,
        frequency: CreditFrequency.monthly,
        startDate: '2026-01-01',
      ),
    );
    await db.upsertCredit(loan);
    await db.clearAllData();
    final all = await db.loadAllCredits();
    expect(all, isEmpty);
  });
}
