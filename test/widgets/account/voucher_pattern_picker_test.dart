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

    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pump(VoucherPattern.diagonalLines);
    await tester.pumpAndSettle();

    for (final pattern in VoucherPattern.values) {
      await tester.scrollUntilVisible(
        find.text(pattern.label),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(pattern.label), findsOneWidget);
    }

    await tester.ensureVisible(find.text(VoucherPattern.circuit.label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(VoucherPattern.circuit.label));
    await tester.pumpAndSettle();

    expect(selected, VoucherPattern.circuit);
  });
}
