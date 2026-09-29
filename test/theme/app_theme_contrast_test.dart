import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kredit/theme/app_theme.dart';

void main() {
  group('legibleForegroundOn', () {
    test('picks black on the default white accent', () {
      expect(legibleForegroundOn(const Color(0xFFFFFFFF)), Colors.black);
    });

    test('picks white on a genuinely dark background', () {
      expect(legibleForegroundOn(const Color(0xFF0F0B1A)), Colors.white);
    });

    // Regression: the old fixed luminance-threshold implementation picked
    // white for these three accent-picker swatches even though black gives
    // dramatically higher WCAG contrast on all of them (their luminance
    // sits in the "medium" band just under the old 0.4 cutoff, not
    // genuinely dark).
    test('picks black on the pastel purple accent (regression)', () {
      expect(legibleForegroundOn(const Color(0xFFC084FC)), Colors.black);
    });

    test('picks black on the pastel blue accent (regression)', () {
      expect(legibleForegroundOn(const Color(0xFF4FACFE)), Colors.black);
    });

    test('picks black on the pastel pink accent (regression)', () {
      expect(legibleForegroundOn(const Color(0xFFFB7185)), Colors.black);
    });

    test('picks black on the bright cyan and yellow accents', () {
      expect(legibleForegroundOn(const Color(0xFF00F2FE)), Colors.black);
      expect(legibleForegroundOn(const Color(0xFFFACC15)), Colors.black);
    });

    test('picks black on the green accent', () {
      expect(legibleForegroundOn(const Color(0xFF34D399)), Colors.black);
    });
  });
}
