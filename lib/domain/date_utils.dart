/// Date helpers ported 1:1 from legacy_pwa/js/app.js.
///
/// The legacy app stores dates as "YYYY-MM-DD" strings and does date math in
/// the browser's local timezone. Here we use plain local `DateTime` values
/// truncated to midnight (no time component) to mirror that behavior.
library;

/// Formats a [DateTime] as "YYYY-MM-DD" (mirrors `toDateStr` / the
/// `toISOString().split("T")[0]` pattern used throughout app.js).
String toDateStr(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

/// Parses a "YYYY-MM-DD" string into a local midnight DateTime.
/// Mirrors `new Date(dateStr + "T00:00:00")`.
DateTime parseDateStr(String dateStr) {
  final parts = dateStr.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

DateTime _atMidnight(DateTime d) => DateTime(d.year, d.month, d.day);

/// Number of days from "today" (local midnight) to [dateStr]'s date,
/// rounded the same way `Math.ceil` does in getDaysDifference().
int getDaysDifference(String dateStr) {
  final today = _atMidnight(DateTime.now());
  final target = parseDateStr(dateStr);
  final diffMs = target.difference(today).inMilliseconds;
  return (diffMs / (1000 * 60 * 60 * 24)).ceil();
}

const _monthsEs = [
  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
];

/// Formats "YYYY-MM-DD" into "D Mon, YYYY" Spanish short format.
String formatDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return 'N/A';
  final parts = dateStr.split('-').map(int.parse).toList();
  final year = parts[0];
  final month = parts[1];
  final day = parts[2];
  return '$day ${_monthsEs[month - 1]}, $year';
}
