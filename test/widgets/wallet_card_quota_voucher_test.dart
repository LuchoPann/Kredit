import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kredit/data/models/credit.dart';
import 'package:kredit/widgets/wallet_card.dart';

void main() {
  LoanCredit buildLoan({String? quotaId}) => LoanCredit(
        id: 'l1',
        name: 'Compra tenis',
        lender: 'Totto',
        totalAmount: 250000,
        quotaAmount: 41667,
        totalInstallments: 6,
        frequency: CreditFrequency.monthly,
        startDate: '2026-09-01',
        quotaId: quotaId,
      );

  testWidgets('a cupo comercial purchase renders as a voucher, not a card',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: WalletCard(credit: buildLoan(quotaId: 'q1'))),
    ));

    expect(find.textContaining('Compra (Totto)'), findsOneWidget);
    expect(find.byIcon(Icons.wifi), findsNothing);
  });

  testWidgets('a normal bank loan (no quotaId) keeps the plastic-card look',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: WalletCard(credit: buildLoan())),
    ));

    expect(find.textContaining('Préstamo'), findsOneWidget);
    expect(find.byIcon(Icons.wifi), findsOneWidget);
  });
}
