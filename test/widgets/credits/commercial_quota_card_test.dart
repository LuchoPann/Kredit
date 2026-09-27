import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kredit/data/models/commercial_quota.dart';
import 'package:kredit/data/models/credit.dart';
import 'package:kredit/data/models/installment.dart';
import 'package:kredit/theme/app_theme.dart';
import 'package:kredit/utils/credit_display_utils.dart';
import 'package:kredit/widgets/credits/commercial_quota_card.dart';

LoanCredit _purchase({
  required String id,
  required String name,
  required String quotaId,
  required double amount,
}) =>
    LoanCredit(
      id: id,
      name: name,
      lender: 'Totto',
      totalAmount: amount,
      quotaAmount: amount,
      totalInstallments: 1,
      frequency: CreditFrequency.monthly,
      startDate: '2026-09-01',
      quotaId: quotaId,
      installments: [
        Installment(
          number: 1,
          dueDate: '2026-09-01',
          amount: amount,
          principal: amount,
          interest: 0,
          paid: false,
        ),
      ],
    );

void main() {
  testWidgets('shows the brand and quota-level stats as a single voucher',
      (tester) async {
    final quota = CommercialQuota(id: 'q1', brand: 'Totto', limit: 700000);
    final purchase = _purchase(
        id: 'l1', name: 'Compra tenis', quotaId: 'q1', amount: 250000);

    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(body: CommercialQuotaCard(quota: quota, purchases: [purchase])),
    ));

    expect(find.text('Totto'), findsOneWidget);
    expect(find.text(formatCOP(450000)), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    // Collapsed by default: no per-purchase rows yet.
    expect(find.text('Compra tenis'), findsNothing);
  });

  testWidgets('tapping the voucher calls onTap', (tester) async {
    final quota = CommercialQuota(id: 'q1', brand: 'Totto', limit: 700000);
    var tapped = false;

    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: CommercialQuotaCard(
          quota: quota,
          purchases: const [],
          onTap: () => tapped = true,
        ),
      ),
    ));

    await tester.tap(find.text('Totto'));
    expect(tapped, isTrue);
  });

  testWidgets('expanding shows each compra and collapsing hides them again',
      (tester) async {
    final quota = CommercialQuota(id: 'q1', brand: 'Totto', limit: 700000);
    final purchase = _purchase(
        id: 'l1', name: 'Compra tenis', quotaId: 'q1', amount: 250000);

    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(body: CommercialQuotaCard(quota: quota, purchases: [purchase])),
    ));

    await tester.tap(find.text('Ver 1 compra'));
    await tester.pump();
    expect(find.text('Compra tenis'), findsOneWidget);

    await tester.tap(find.text('Ocultar compras'));
    await tester.pump();
    expect(find.text('Compra tenis'), findsNothing);
  });

  testWidgets(
      'available is computed from allPurchases, not the (possibly filtered) '
      'displayed purchases list', (tester) async {
    final quota = CommercialQuota(id: 'q1', brand: 'Totto', limit: 700000);
    final hiddenByFilter = _purchase(
        id: 'l1', name: 'Oculta por el filtro', quotaId: 'q1', amount: 300000);

    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: CommercialQuotaCard(
          quota: quota,
          purchases: const [],
          allPurchases: [hiddenByFilter],
        ),
      ),
    ));

    expect(find.text(formatCOP(400000)), findsOneWidget);
    // La compra no se muestra (fuera de este tab/filtro), solo su saldo
    // cuenta contra el disponible.
    expect(find.text('Oculta por el filtro'), findsNothing);
  });

  testWidgets('renders with zero purchases without crashing', (tester) async {
    final quota = CommercialQuota(id: 'q1', brand: 'Totto', limit: 700000);

    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(body: CommercialQuotaCard(quota: quota, purchases: const [])),
    ));

    expect(find.text('Totto'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });
}
