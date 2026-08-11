/// Bank/issuer recognition ported from app.js (renderDashboard ~L916-931,
/// renderCreditsList ~L1105-1120, updateWalletCardDesign ~L1221-1286, and
/// getBankColor ~L1313-1327).
///
/// The legacy code repeats this if/else chain in three different places with
/// slightly different label sets (short "bankLabel" for list rows vs the
/// fuller name used on the wallet card). We consolidate into one reusable
/// [BankInfo] lookup keyed the same way (`"$lender $card"` lowercased,
/// `.contains(...)` checks, first match wins, in the same order as app.js).
library;

class BankInfo {
  final String cssClass; // e.g. "bank-nequi" (kept for parity/CSS reuse)
  final String shortLabel; // label used in list/dashboard rows
  final String fullLabel; // label used on the wallet card detail view
  final String accentColor; // getBankColor()

  const BankInfo({
    required this.cssClass,
    required this.shortLabel,
    required this.fullLabel,
    required this.accentColor,
  });
}

/// Detects the bank/issuer for a credit from its `lender` and `card` free
/// text fields. Falls back to a generic entry using [fallbackLender] and
/// [fallbackColor] when nothing matches, exactly like app.js's bank-generic
/// branch.
BankInfo detectBank({
  required String lender,
  String? card,
  String? fallbackColor,
}) {
  final textToSearch = '$lender ${card ?? ''}'.toLowerCase();

  bool has(String needle) => textToSearch.contains(needle);

  if (has('daviplata')) {
    return const BankInfo(
      cssClass: 'bank-daviplata',
      shortLabel: 'DaviPlata',
      fullLabel: 'DaviPlata',
      accentColor: '#f0521c',
    );
  }
  if (has('davivienda')) {
    return const BankInfo(
      cssClass: 'bank-davivienda',
      shortLabel: 'Davivienda',
      fullLabel: 'Davivienda',
      accentColor: '#e4032e',
    );
  }
  if (has('nequi')) {
    return const BankInfo(
      cssClass: 'bank-nequi',
      shortLabel: 'Nequi',
      fullLabel: 'Nequi',
      accentColor: '#9333ea',
    );
  }
  if (has('bancolombia')) {
    return const BankInfo(
      cssClass: 'bank-bancolombia',
      shortLabel: 'Bancolombia',
      fullLabel: 'Bancolombia',
      accentColor: '#ffdd00',
    );
  }
  if (has('nubank') ||
      has('nu (') ||
      has('nu colombia') ||
      textToSearch.startsWith('nu ') ||
      textToSearch == 'nu') {
    return const BankInfo(
      cssClass: 'bank-nu',
      shortLabel: 'Nu',
      fullLabel: 'nu',
      accentColor: '#820ad1',
    );
  }
  if (has('bbva')) {
    return const BankInfo(
      cssClass: 'bank-bbva',
      shortLabel: 'BBVA',
      fullLabel: 'BBVA Colombia',
      accentColor: '#85c8ff',
    );
  }
  if (has('rappi')) {
    return const BankInfo(
      cssClass: 'bank-rappi',
      shortLabel: 'RappiCard',
      fullLabel: 'RappiCard',
      accentColor: '#fe3f23',
    );
  }
  if (has('lulo')) {
    return const BankInfo(
      cssClass: 'bank-lulo',
      shortLabel: 'Lulo',
      fullLabel: 'Lulo Bank',
      accentColor: '#00e28a',
    );
  }
  if (has('bogota') || has('bogotá')) {
    return const BankInfo(
      cssClass: 'bank-bogota',
      shortLabel: 'B. Bogotá',
      fullLabel: 'Banco de Bogotá',
      accentColor: '#d4af37',
    );
  }
  if (has('falabella')) {
    return const BankInfo(
      cssClass: 'bank-falabella',
      shortLabel: 'Falabella',
      fullLabel: 'Banco Falabella',
      accentColor: '#c3d500',
    );
  }
  if (has('colpatria') || has('scotiabank')) {
    return const BankInfo(
      cssClass: 'bank-colpatria',
      shortLabel: 'Colpatria',
      fullLabel: 'Scotiabank Colpatria',
      accentColor: '#ec0712',
    );
  }
  if (has('popular')) {
    return const BankInfo(
      cssClass: 'bank-popular',
      shortLabel: 'Popular',
      fullLabel: 'Banco Popular',
      accentColor: '#00875a',
    );
  }
  if (has('villas') || has('av villas')) {
    return const BankInfo(
      cssClass: 'bank-avvillas',
      shortLabel: 'AV Villas',
      fullLabel: 'Banco AV Villas',
      accentColor: '#0055a5',
    );
  }
  if (has('occidente')) {
    return const BankInfo(
      cssClass: 'bank-occidente',
      shortLabel: 'Occidente',
      fullLabel: 'Banco de Occidente',
      accentColor: '#00205b',
    );
  }
  if (has('itau') || has('itaú')) {
    return const BankInfo(
      cssClass: 'bank-itau',
      shortLabel: 'Itaú',
      fullLabel: 'Itaú',
      accentColor: '#ec7000',
    );
  }
  if (has('tuya') || has('exito') || has('éxito')) {
    return const BankInfo(
      cssClass: 'bank-tuya',
      shortLabel: 'Tuya',
      fullLabel: 'Tarjeta Tuya / Éxito',
      accentColor: '#ffd100',
    );
  }

  return BankInfo(
    cssClass: 'bank-generic',
    shortLabel: lender,
    fullLabel: lender.isEmpty ? 'Crédito Personal' : lender,
    accentColor: fallbackColor ?? '#ffffff',
  );
}
