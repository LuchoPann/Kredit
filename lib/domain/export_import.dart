import 'dart:convert';

import '../data/models/credit.dart';

/// Port of exportData/importData's JSON shape (app.js ~L1615-1658).
///
/// The legacy app persists (and exports) `state = { credits: [...] }`
/// verbatim. We keep that exact top-level shape (`{"credits": [...] }`) for
/// forward/backward compatibility with existing PWA backups, even though the
/// Flutter app's source of truth is now the Drift database rather than a
/// single in-memory `state` object.

/// Serializes [credits] into the legacy-compatible backup JSON string
/// (pretty-printed with 2-space indent, matching `JSON.stringify(state,
/// null, 2)`).
String exportStateToJson(List<Credit> credits) {
  final map = {
    'credits': credits.map((c) {
      if (c is CardCredit) return c.toJson();
      if (c is LoanCredit) return c.toJson();
      throw ArgumentError('Unknown credit subtype: ${c.runtimeType}');
    }).toList(),
  };
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(map);
}

/// Thrown when [importStateFromJson] receives a payload that fails the same
/// basic validation app.js performs before overwriting state
/// (`importedState && Array.isArray(importedState.credits)`).
class InvalidBackupFormatException implements Exception {
  final String message;
  const InvalidBackupFormatException([this.message = 'Archivo inválido: no es un respaldo de Kredit']);
  @override
  String toString() => message;
}

/// Parses a backup JSON string into a list of [Credit]. Throws
/// [InvalidBackupFormatException] on malformed input, or a [FormatException]
/// if the JSON itself doesn't parse — same failure split as importData's
/// try/catch + validation (app.js ~L1630-1658).
List<Credit> importStateFromJson(String jsonStr) {
  final decoded = jsonDecode(jsonStr);
  if (decoded is! Map<String, dynamic> || decoded['credits'] is! List) {
    throw const InvalidBackupFormatException();
  }
  final creditsJson = decoded['credits'] as List;
  return creditsJson
      .map((e) => creditFromJson(e as Map<String, dynamic>))
      .toList();
}
