import 'package:flutter/services.dart';

/// Formats a plain-integer money field using the Colombian convention:
/// '.' as thousands separator, no decimals (COP amounts are virtually
/// always whole pesos).
///
/// Use [CurrencyInputFormatter.unformat] to strip the thousands dots
/// before calling `double.tryParse` / `double.parse` on the saved value.
class CurrencyInputFormatter extends TextInputFormatter {
  const CurrencyInputFormatter();

  /// Removes the thousands separators added by this formatter so the
  /// resulting string can be parsed with `double.tryParse`.
  static String unformat(String value) => value.replaceAll('.', '');

  /// Formats a numeric value (e.g. one computed programmatically) into the
  /// '1.500.000' display form, so it can be assigned directly to a
  /// controller's `text` without waiting for a user keystroke.
  static String format(num value) => _addThousandsSeparators(value.round().toString());

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Keep only digits.
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final newText = _addThousandsSeparators(digitsOnly);

    // Preserve the cursor's relative position by counting how many digits
    // are to the left of the cursor in the raw input, then placing the
    // cursor after the same count of digits in the formatted output.
    final digitsBeforeCursor = newValue.text
        .substring(0, newValue.selection.end.clamp(0, newValue.text.length))
        .replaceAll(RegExp(r'[^0-9]'), '')
        .length;

    var cursorPos = 0;
    var digitsSeen = 0;
    for (var i = 0; i < newText.length; i++) {
      if (digitsSeen >= digitsBeforeCursor) break;
      if (newText[i] != '.') digitsSeen++;
      cursorPos = i + 1;
    }
    if (digitsBeforeCursor == 0) cursorPos = 0;

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursorPos),
    );
  }

  static String _addThousandsSeparators(String digits) {
    final buffer = StringBuffer();
    final length = digits.length;
    for (var i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
