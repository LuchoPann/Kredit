import 'package:flutter_test/flutter_test.dart';
import 'package:kredit/domain/interest_rate.dart';

void main() {
  group('dailyRateFrom', () {
    test('returns 0 when rate is 0, regardless of type', () {
      expect(dailyRateFrom(0, InterestRateType.effectiveAnnual), 0.0);
      expect(dailyRateFrom(0, InterestRateType.effectiveMonthly), 0.0);
      expect(dailyRateFrom(0, InterestRateType.nominalMonthly), 0.0);
      expect(dailyRateFrom(0, null), 0.0);
    });

    test('effectiveAnnual: (1+r)^(1/365)-1', () {
      final daily = dailyRateFrom(36.0, InterestRateType.effectiveAnnual);
      // r = 0.36 -> daily = (1.36)^(1/365) - 1 ~= 0.00084278
      expect(daily, closeTo(0.00084278, 1e-6));
    });

    test('effectiveMonthly: (1+r)^(1/30)-1', () {
      final daily = dailyRateFrom(3.0, InterestRateType.effectiveMonthly);
      // r = 0.03 -> daily = (1.03)^(1/30) - 1
      expect(daily, closeTo(0.0009853, 1e-6));
    });

    test('nominalMonthly: r/30 (no compounding)', () {
      final daily = dailyRateFrom(3.0, InterestRateType.nominalMonthly);
      expect(daily, closeTo(0.03 / 30, 1e-9));
    });

    test('unknown/null rateType falls back to effectiveAnnual', () {
      final fallback = dailyRateFrom(36.0, null);
      final explicit = dailyRateFrom(36.0, InterestRateType.effectiveAnnual);
      expect(fallback, explicit);

      final unknown = dailyRateFrom(36.0, 'someBankSpecificThing');
      expect(unknown, explicit);
    });
  });

  group('rateInconsistencyWarning', () {
    test('null/zero/negative rate never warns', () {
      expect(rateInconsistencyWarning(0, InterestRateType.effectiveAnnual), isNull);
      expect(rateInconsistencyWarning(-5, InterestRateType.effectiveMonthly), isNull);
    });

    test('normal monthly rate (1.5%-4%) does not warn', () {
      expect(rateInconsistencyWarning(2.5, InterestRateType.effectiveMonthly), isNull);
      expect(rateInconsistencyWarning(3.0, InterestRateType.nominalMonthly), isNull);
    });

    test('suspiciously high monthly rate warns (e.g. 24% typed as monthly)', () {
      final warning = rateInconsistencyWarning(24, InterestRateType.effectiveMonthly);
      expect(warning, isNotNull);
      expect(warning, contains('efectiva mensual del 24%'));
      expect(warning, contains('¿Seguro que la tasa está expresada mensualmente?'));
    });

    test('suspiciously high nominal monthly rate warns', () {
      expect(rateInconsistencyWarning(24, InterestRateType.nominalMonthly), isNotNull);
    });

    test('monthly boundary: exactly 5% does not warn, just above does', () {
      expect(rateInconsistencyWarning(5, InterestRateType.effectiveMonthly), isNull);
      expect(rateInconsistencyWarning(5.01, InterestRateType.effectiveMonthly), isNotNull);
    });

    test('normal annual rate (15%-30%) does not warn', () {
      expect(rateInconsistencyWarning(24, InterestRateType.effectiveAnnual), isNull);
      expect(rateInconsistencyWarning(29, null), isNull);
    });

    test('suspiciously low annual rate warns', () {
      expect(rateInconsistencyWarning(3, InterestRateType.effectiveAnnual), isNotNull);
    });

    test('annual boundary: exactly 5% does not warn, just below does', () {
      expect(rateInconsistencyWarning(5, InterestRateType.effectiveAnnual), isNull);
      expect(rateInconsistencyWarning(4.99, InterestRateType.effectiveAnnual), isNotNull);
    });

    test('extremely high annual rate warns', () {
      expect(rateInconsistencyWarning(150, InterestRateType.effectiveAnnual), isNotNull);
    });

    test('annual boundary: exactly 35% does not warn, just above does', () {
      expect(rateInconsistencyWarning(35, InterestRateType.effectiveAnnual), isNull);
      expect(rateInconsistencyWarning(35.01, InterestRateType.effectiveAnnual), isNotNull);
    });
  });

  group('InterestRateType', () {
    test('isValid recognizes the three known types', () {
      expect(InterestRateType.isValid(InterestRateType.effectiveAnnual), isTrue);
      expect(InterestRateType.isValid(InterestRateType.effectiveMonthly), isTrue);
      expect(InterestRateType.isValid(InterestRateType.nominalMonthly), isTrue);
      expect(InterestRateType.isValid('nope'), isFalse);
      expect(InterestRateType.isValid(null), isFalse);
    });
  });
}
