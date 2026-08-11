/// Lightweight "entity template" catalog: NOT real/official bank data, just
/// reasonable starting-point suggestions (editable by the user) for the
/// typical structure of a card product from a known Colombian entity, so the
/// add-credit form has less friction to fill out. Kredit does not — and
/// should not — try to track the *actual* current cutoff/payment-due rules
/// of each bank (those change per user/contract and go stale fast); this is
/// only a sensible default the user can immediately overwrite.
///
/// Matching uses the same case-insensitive `.contains(...)` criterion as
/// `bank_detector.dart`'s `detectBank()`, applied to the lender free-text
/// field.
library;

class EntityTemplate {
  final String matchKeyword;
  final int? typicalCutoffDay;
  final int? typicalPaymentOffsetDays;
  final String note;

  const EntityTemplate({
    required this.matchKeyword,
    this.typicalCutoffDay,
    this.typicalPaymentOffsetDays,
    this.note = '',
  });
}

// Typical/industry-range values for Colombian card products (20-25 days
// between cutoff and payment due date is the normal range) — these are
// reasonable starting defaults, NOT official data scraped from any bank's
// current terms. The user should always verify against their real
// statement ("estado de cuenta"); the form only uses these to pre-fill
// empty fields, never to overwrite something the user already typed.
const entityTemplates = <EntityTemplate>[
  EntityTemplate(
    matchKeyword: 'bancolombia',
    typicalCutoffDay: 15,
    typicalPaymentOffsetDays: 21,
  ),
  EntityTemplate(
    matchKeyword: 'nu',
    typicalCutoffDay: 20,
    typicalPaymentOffsetDays: 25,
    note: 'Nu suele tener corte y pago configurables por el usuario en su app.',
  ),
  EntityTemplate(
    matchKeyword: 'davivienda',
    typicalCutoffDay: 15,
    typicalPaymentOffsetDays: 20,
  ),
  EntityTemplate(
    matchKeyword: 'bbva',
    typicalCutoffDay: 15,
    typicalPaymentOffsetDays: 20,
  ),
  EntityTemplate(
    matchKeyword: 'rappi',
    typicalCutoffDay: 20,
    typicalPaymentOffsetDays: 22,
  ),
  EntityTemplate(
    matchKeyword: 'lulo',
    typicalCutoffDay: 20,
    typicalPaymentOffsetDays: 25,
    note: 'Lulo Bank suele permitir configurar la fecha de corte desde la app.',
  ),
  EntityTemplate(
    matchKeyword: 'bogota',
    typicalCutoffDay: 15,
    typicalPaymentOffsetDays: 20,
  ),
  EntityTemplate(
    matchKeyword: 'falabella',
    typicalCutoffDay: 15,
    typicalPaymentOffsetDays: 20,
  ),
  EntityTemplate(
    matchKeyword: 'colpatria',
    typicalCutoffDay: 15,
    typicalPaymentOffsetDays: 20,
  ),
  EntityTemplate(
    matchKeyword: 'popular',
    typicalCutoffDay: 15,
    typicalPaymentOffsetDays: 20,
  ),
  EntityTemplate(
    matchKeyword: 'villas',
    typicalCutoffDay: 15,
    typicalPaymentOffsetDays: 20,
  ),
  EntityTemplate(
    matchKeyword: 'occidente',
    typicalCutoffDay: 15,
    typicalPaymentOffsetDays: 20,
  ),
  EntityTemplate(
    matchKeyword: 'itau',
    typicalCutoffDay: 15,
    typicalPaymentOffsetDays: 20,
  ),
  EntityTemplate(
    matchKeyword: 'tuya',
    typicalCutoffDay: 15,
    typicalPaymentOffsetDays: 20,
  ),
  // Nequi and DaviPlata are predominantly fixed-installment products
  // (Nequi doesn't offer a revolving card at all; DaviPlata's Nanocrédito
  // is fixed-installment too — see `_typeSuggestion` in add_credit_sheet.dart)
  // so no cutoff/payment-offset template applies to them.
];

/// Finds the first [EntityTemplate] whose `matchKeyword` is contained in
/// [lenderText] (case-insensitive), mirroring `detectBank()`'s matching
/// approach. Returns null if nothing matches.
EntityTemplate? matchEntityTemplate(String lenderText) {
  final text = lenderText.toLowerCase();
  for (final t in entityTemplates) {
    if (text.contains(t.matchKeyword)) return t;
  }
  return null;
}
