import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krezium/widgets/kredit_wordmark.dart';

void main() {
  testWidgets('AppWordmark renders without crashing', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: AppWordmark(color: Colors.black, height: 18),
      ),
    ));

    expect(find.byType(AppWordmark), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppWordmarkReveal calls onCompleted once the reveal finishes',
      (tester) async {
    var completed = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AppWordmarkReveal(
          color: Colors.white,
          duration: const Duration(milliseconds: 300),
          onCompleted: () => completed = true,
        ),
      ),
    ));

    // Partway through: not yet done.
    await tester.pump(const Duration(milliseconds: 150));
    expect(completed, isFalse);
    expect(tester.takeException(), isNull);

    // Past the full duration: onCompleted fires exactly once.
    await tester.pump(const Duration(milliseconds: 200));
    expect(completed, isTrue);
  });
}
