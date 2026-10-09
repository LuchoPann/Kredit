import 'package:flutter_test/flutter_test.dart';
import 'package:krezium/domain/urgency_score.dart';

void main() {
  group('urgencyScore', () {
    test('overdue item outranks a not-yet-due item even with a smaller amount', () {
      final overdue = urgencyScore(daysUntilDue: -2, amount: 10000);
      final upcoming = urgencyScore(daysUntilDue: 5, amount: 5000000);
      expect(overdue, greaterThan(upcoming));
    });

    test('same due date: larger amount scores more urgent', () {
      final small = urgencyScore(daysUntilDue: 3, amount: 100000);
      final large = urgencyScore(daysUntilDue: 3, amount: 900000);
      expect(large, greaterThan(small));
    });

    test('produces a stable descending order across a mixed list', () {
      final items = [
        (daysUntilDue: 10, amount: 50000.0),
        (daysUntilDue: -1, amount: 20000.0),
        (daysUntilDue: 0, amount: 300000.0),
        (daysUntilDue: -1, amount: 800000.0),
      ];
      final sorted = [...items]..sort((a, b) => urgencyScore(daysUntilDue: b.daysUntilDue, amount: b.amount)
          .compareTo(urgencyScore(daysUntilDue: a.daysUntilDue, amount: a.amount)));

      expect(sorted[0], (daysUntilDue: -1, amount: 800000.0));
      expect(sorted[1], (daysUntilDue: -1, amount: 20000.0));
      expect(sorted[2], (daysUntilDue: 0, amount: 300000.0));
      expect(sorted[3], (daysUntilDue: 10, amount: 50000.0));
    });
  });
}
