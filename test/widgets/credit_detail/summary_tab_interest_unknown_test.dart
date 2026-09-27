import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kredit/data/models/credit.dart';
import 'package:kredit/theme/app_theme.dart';
import 'package:kredit/widgets/credit_detail/summary_tab.dart';

void main() {
  testWidgets(
      'shows "Cuenta sin intereses registrados" instead of a rate when interestUnknown',
      (tester) async {
    final loan = LoanCredit(
      id: 'l1',
      name: 'Compra Totto',
      lender: 'Totto',
      totalAmount: 250000,
      quotaAmount: 41667,
      totalInstallments: 6,
      frequency: CreditFrequency.monthly,
      startDate: '2026-09-01',
      interestUnknown: true,
    );

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(body: SummaryTab(credit: loan)),
      ),
    ));

    expect(find.text('Cuenta sin intereses registrados'), findsOneWidget);
    expect(find.text('0.0%'), findsNothing);
  });
}
