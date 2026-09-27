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
