import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krezium/theme/app_theme.dart';
import 'package:krezium/widgets/account/voucher_pattern_picker.dart';
import 'package:krezium/widgets/voucher_pattern.dart';

void main() {
  testWidgets('shows all 8 patterns and tapping one calls onSelect', (tester) async {
    VoucherPattern? selected;

    Future<void> pump(VoucherPattern current) => tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: VoucherPatternPicker(
                  selected: current,
                  accent: Colors.blue,
                  onSelect: (p) => selected = p,
                ),
              ),
            ),
          ),
        );

    await pump(VoucherPattern.diagonalLines);
    await tester.pumpAndSettle();

    for (final pattern in VoucherPattern.values) {
      expect(find.text(pattern.label), findsOneWidget);
    }

    await tester.ensureVisible(find.text(VoucherPattern.circuit.label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(VoucherPattern.circuit.label));
    await tester.pumpAndSettle();

    expect(selected, VoucherPattern.circuit);
  });
}
