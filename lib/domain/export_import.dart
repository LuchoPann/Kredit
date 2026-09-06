import 'dart:convert';

import '../data/models/credit.dart';

/// Port of exportData/importData's JSON shape (app.js ~L1615-1658).
///
/// The legacy app persists (and exports) `state = { credits: [...] }`
/// verbatim. We keep that exact top-level shape (`{"credits": [...] }`) for
/// forward/backward compatibility with existing PWA backups, even though the
/// Flutter app's source of truth is now the Drift database rather than a
/// single in-memory `state` object.
///
/// Starting at version 2, exports are wrapped in a small versioned envelope
/// (`format`/`version`/`exportedAt` alongside `credits`) so future schema
/// changes can be detected and migrated instead of silently misread. Legacy
/// exports (this app's own v1 output, and the PWA's) have neither field and
/// are treated as implicit version 1 — they must keep importing exactly as
/// before.

/// Current backup schema version this app writes and fully understands.
///
/// Bump this whenever the backup shape changes, and extend [_migrateBackup]
/// with a case that upgrades the *previous* version into the new one.
const int kBackupFormatVersion = 2;

/// The `format` marker identifying versioned (v2+) backups. Legacy (v1)
/// backups predate this field entirely — they are just `{"credits": [...]}`
/// with no `format`/`version` key at all.
const String kBackupFormatMarker = 'kredit-backup';

/// Serializes [credits] into the current versioned backup JSON string
/// (pretty-printed with 2-space indent):
/// `{"format": "kredit-backup", "version": 2, "exportedAt": ISO8601 UTC,
/// "credits": [...] }`.
String exportStateToJson(List<Credit> credits) {
  final map = {
    'format': kBackupFormatMarker,
    'version': kBackupFormatVersion,
    'exportedAt': DateTime.now().toUtc().toIso8601String(),
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

/// Normalizes a decoded backup payload of any known version into the shape
/// [kBackupFormatVersion] expects (currently just a `Map` with a `credits`
/// list), so the rest of [importStateFromJson] never has to special-case
/// versions.
///
/// Migration pattern for future schema changes: this function walks the
/// payload forward one version at a time via the `while` loop below. To add
/// support for a new version N+1: bump [kBackupFormatVersion] to N+1, then
/// add a branch `if (version == N) { ...transform decoded in place...;
/// version = N + 1; continue; }` inside the loop, above the final
/// `break`/return. Each branch should only know how to upgrade *from* its
/// own version to the next — the loop chains them together so a very old
/// backup is migrated step by step up to the latest version.
Map<String, dynamic> _migrateBackup(Map<String, dynamic> decoded) {
  // Legacy (pre-versioning) backups: plain `{"credits": [...]}` with no
  // `format`/`version` field. Treat as implicit version 1.
  int version = (decoded['version'] as num?)?.toInt() ?? 1;

  if (version > kBackupFormatVersion) {
    // Forward-compat: a newer app produced this backup, using a schema we
    // don't know about. Don't fail hard — best-effort read whatever
    // `credits` it still carries, since that key has been stable since v1.
    return decoded;
  }

  while (version < kBackupFormatVersion) {
    if (version == 1) {
      // v1 -> v2 only added the envelope (`format`/`version`/`exportedAt`);
      // the meaning and shape of `credits` itself is unchanged, so there is
      // nothing to transform.
      version = 2;
      continue;
    }
    // Should be unreachable given the version check above, but avoid an
    // infinite loop if a future version is added to kBackupFormatVersion
    // without a matching branch here.
    break;
  }

  return decoded;
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

  final migrated = _migrateBackup(decoded);
  if (migrated['credits'] is! List) {
    throw const InvalidBackupFormatException();
  }

  final creditsJson = migrated['credits'] as List;
  return creditsJson
      .map((e) => creditFromJson(e as Map<String, dynamic>))
      .toList();
}
