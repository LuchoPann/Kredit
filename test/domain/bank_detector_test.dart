import 'package:flutter_test/flutter_test.dart';
import 'package:kredit/domain/bank_detector.dart';

void main() {
  group('detectBank - Falabella sub-entities', () {
    test('plain "Falabella" resolves to Banco Falabella', () {
      final info = detectBank(lender: 'Falabella');
      expect(info.cssClass, 'bank-falabella');
      expect(info.fullLabel, 'Banco Falabella');
      expect(info.shortLabel, 'Falabella');
    });

    test('"CMR Falabella" resolves to the CMR sub-brand, not the generic bank', () {
      final info = detectBank(lender: 'CMR Falabella');
      expect(info.cssClass, 'bank-falabella');
      expect(info.fullLabel, 'CMR Falabella');
      expect(info.shortLabel, 'CMR Falabella');
    });

    test('"CMR" alone (e.g. typed in the card field) is also detected', () {
      final info = detectBank(lender: 'Falabella', card: 'CMR');
      expect(info.fullLabel, 'CMR Falabella');
    });
  });

  group('subEntitiesForLender', () {
    test('Falabella exposes CMR Falabella and Banco Falabella as sub-entities', () {
      final options = subEntitiesForLender('Falabella');
      expect(options.map((o) => o.lenderText), containsAll(['CMR Falabella', 'Banco Falabella']));
    });

    test('a bank without known sub-brands returns an empty list', () {
      expect(subEntitiesForLender('Bancolombia'), isEmpty);
      expect(subEntitiesForLender('Nu'), isEmpty);
    });
  });
}
