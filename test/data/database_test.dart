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
      installments: buildLoanInstallments(
        totalAmount: 1000,
        totalInstallments: 4,
        quotaAmount: 300,
        frequency: CreditFrequency.monthly,
        startDate: '2026-01-01',
      ),
    );

    await db.upsertCredit(loan);
    final all = await db.loadAllCredits();

    expect(all, hasLength(1));
    final loaded = all.first as LoanCredit;
    expect(loaded.name, 'Laptop');
    expect(loaded.installments, hasLength(4));
    expect(loaded.installments[0].interest, closeTo(50, 1e-9));
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
