import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/models/credit.dart';
import '../domain/bank_detector.dart';
import '../domain/credit_calculator.dart';
import '../providers/credits_provider.dart' show isDemoCredit;
import '../theme/app_theme.dart' show KreditRadius;
import 'demo_badge.dart';

/// Real bank/issuer logo assets, keyed by [BankInfo.cssClass]. Only entities
/// with a clean official logo we could source (mostly Wikimedia Commons) are
/// listed here — anything missing (e.g. DaviPlata, Lulo Bank) keeps the
/// existing text-only fallback.
const Map<String, String> bankLogoAssets = {
  'bank-nequi': 'assets/logos/bank-nequi.svg',
  'bank-bancolombia': 'assets/logos/bank-bancolombia.svg',
  'bank-nu': 'assets/logos/bank-nu.svg',
  'bank-davivienda': 'assets/logos/bank-davivienda.png',
  'bank-daviplata': 'assets/logos/bank-daviplata.png',
  'bank-bbva': 'assets/logos/bank-bbva.svg',
  'bank-rappi': 'assets/logos/bank-rappi.svg',
  'bank-lulo': 'assets/logos/bank-lulo.png',
  'bank-bogota': 'assets/logos/bank-bogota.svg',
  'bank-falabella': 'assets/logos/bank-falabella.svg',
  'bank-colpatria': 'assets/logos/bank-colpatria.svg',
  'bank-popular': 'assets/logos/bank-popular.png',
  'bank-avvillas': 'assets/logos/bank-avvillas.png',
  'bank-occidente': 'assets/logos/bank-occidente.png',
  'bank-itau': 'assets/logos/bank-itau.png',
  'bank-tuya': 'assets/logos/bank-tuya.png',
  'bank-generic': 'assets/logos/bank-generic.svg',
};

/// A small white "chip" holding the bank's real logo, used both on the big
/// [WalletCard] and the compact [CreditCardTile] so the wordmark reads
/// cleanly regardless of the logo's own colors or the card's gradient.
class BankLogoChip extends StatelessWidget {
  final String assetPath;
  final double height;
  final EdgeInsets padding;

  const BankLogoChip({
    super.key,
    required this.assetPath,
    this.height = 18,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
  });

  @override
  Widget build(BuildContext context) {
    final isSvg = assetPath.endsWith('.svg');
    return isSvg
        ? SvgPicture.asset(assetPath, height: height, fit: BoxFit.contain)
        : Image.asset(assetPath, height: height, fit: BoxFit.contain);
  }
}

/// Format a numeric amount like the legacy `formatCurrency` (Intl COP,
/// no decimals) — good enough visual parity without pulling `intl` in.
String formatCurrency(double amount) {
  final rounded = amount.round();
  final s = rounded.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '${rounded < 0 ? '-' : ''}\$${buf.toString()}';
}

/// Gradient look-alike of the legacy .wallet-card.bank-* CSS classes
/// (legacy_pwa/css/style.css ~L1483-1616). Keyed by [BankInfo.cssClass].
List<Color> _gradientFor(String cssClass, String? fallbackColorHex) {
  switch (cssClass) {
    case 'bank-nequi':
      return const [Color(0xFF131A3A), Color(0xFF0A0E26), Color(0xFF05070F)];
    case 'bank-bancolombia':
      return const [Color(0xFF2A2018), Color(0xFF14100B), Color(0xFF080705)];
    case 'bank-davivienda':
      return const [Color(0xFFE4032E), Color(0xFF7A0212), Color(0xFF150202)];
    case 'bank-daviplata':
      return const [Color(0xFFEE3124), Color(0xFF8A150C), Color(0xFF1F0402)];
    case 'bank-nu':
      return const [Color(0xFF820AD1), Color(0xFF4A007E), Color(0xFF19002E)];
    case 'bank-rappi':
      return const [Color(0xFFFE3F23), Color(0xFF8F1A0C), Color(0xFF170301)];
    case 'bank-lulo':
      return const [Color(0xFF00E28A), Color(0xFF046B46), Color(0xFF01180F)];
    case 'bank-bbva':
      return const [Color(0xFF0A2F6B), Color(0xFF041638), Color(0xFF01050F)];
    case 'bank-bogota':
      return const [Color(0xFF002147), Color(0xFF001026), Color(0xFF00050D)];
    case 'bank-falabella':
      return const [Color(0xFFC3D500), Color(0xFF6B7600), Color(0xFF0F1200)];
    case 'bank-colpatria':
      return const [Color(0xFFEC0712), Color(0xFF6E0006), Color(0xFF120000)];
    case 'bank-popular':
      return const [Color(0xFF00875A), Color(0xFF00452E), Color(0xFF00170F)];
    case 'bank-avvillas':
      return const [Color(0xFF0055A5), Color(0xFF002C57), Color(0xFF000E1F)];
    case 'bank-occidente':
      return const [Color(0xFF00205B), Color(0xFF001030), Color(0xFF000512)];
    case 'bank-itau':
      return const [Color(0xFFEC7000), Color(0xFF7A3900), Color(0xFF241100)];
    case 'bank-tuya':
      return const [Color(0xFFD4AF00), Color(0xFF6B5800), Color(0xFF1C1700)];
    default:
      if (fallbackColorHex != null && fallbackColorHex.isNotEmpty) {
        final c = _colorFromHex(fallbackColorHex);
        if (c != null) {
          return [
            Color.lerp(c, Colors.black, 0.15)!,
            Color.lerp(c, Colors.black, 0.65)!,
            Colors.black,
          ];
        }
      }
      return const [Color(0xFF121212), Colors.black];
  }
}

Color? _colorFromHex(String hex) {
  var h = hex.replaceFirst('#', '');
  if (h.length == 6) h = 'FF$h';
  final v = int.tryParse(h, radix: 16);
  return v == null ? null : Color(v);
}

/// Expands a 3-stop base gradient into a richer multi-stop one so the card
/// face reads as a textured surface rather than a flat 3-color blend —
/// purely a gradient definition, no shadows involved.
List<Color> _expandGradient(List<Color> base) {
  if (base.length < 3) return base;
  final a = base[0], b = base[1], c = base[2];
  return [
    Color.lerp(a, Colors.white, 0.06)!,
    a,
    Color.lerp(a, b, 0.55)!,
    b,
    Color.lerp(b, c, 0.6)!,
    c,
  ];
}

/// Faint diagonal-line texture characteristic of physical card mockups —
/// drawn with a very low alpha so it reads as texture, not decoration, and
/// never competes with the real information above it.
class _CardPatternPainter extends CustomPainter {
  const _CardPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    const gap = 14.0;
    final diag = size.width + size.height;
    for (double x = -size.height; x < diag; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CardPatternPainter oldDelegate) => false;
}

/// Simulated EMV chip — a small gold rectangle with the characteristic
/// grid of contact lines, purely decorative (no real chip data exists).
class _EmvChip extends StatelessWidget {
  const _EmvChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8D48A), Color(0xFFBFA054), Color(0xFFE8D48A)],
        ),
      ),
      child: CustomPaint(painter: _EmvChipLinesPainter()),
    );
  }
}

class _EmvChipLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF7A6528).withValues(alpha: 0.55)
      ..strokeWidth = 1;
    // Horizontal divider lines.
    canvas.drawLine(Offset(0, size.height * 0.35), Offset(size.width, size.height * 0.35), paint);
    canvas.drawLine(Offset(0, size.height * 0.65), Offset(size.width, size.height * 0.65), paint);
    // Vertical divider lines within the middle band.
    canvas.drawLine(
      Offset(size.width * 0.35, size.height * 0.35),
      Offset(size.width * 0.35, size.height * 0.65),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.65, size.height * 0.35),
      Offset(size.width * 0.65, size.height * 0.65),
      paint,
    );
    // Small rounded rect outline for the whole contact area.
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      const Radius.circular(5),
    );
    canvas.drawRRect(rect, paint..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant _EmvChipLinesPainter oldDelegate) => false;
}

/// Big visual wallet-card mockup shown atop the credit detail "Resumen" tab,
/// mirroring #detail-wallet-card in legacy_pwa/index.html (~L358-379).
class WalletCard extends StatelessWidget {
  final Credit credit;

  const WalletCard({super.key, required this.credit});

  @override
  Widget build(BuildContext context) {
    final card = credit is LoanCredit ? (credit as LoanCredit).card : null;
    final bank = detectBank(
      lender: credit.lender,
      card: card,
      fallbackColor: credit.color,
    );
    final gradient = _expandGradient(_gradientFor(bank.cssClass, credit.color));
    final remaining = getCreditRemainingBalance(credit);

    return AspectRatio(
      aspectRatio: 1.65,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Base gradient surface.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
            ),
            // Very tenuous diagonal-line texture, characteristic of
            // physical card mockups — pure decoration, no shadow.
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: const _CardPatternPainter()),
              ),
            ),
            // Subtle radial highlight/reflection in the top-right corner,
            // to sell the "physical card" feel without adding new colors.
            Positioned(
              top: -40,
              right: -40,
              child: IgnorePointer(
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // A second, dimmer glint low-left, for a bit of directional
            // light instead of a single flat highlight.
            Positioned(
              bottom: -50,
              left: -30,
              child: IgnorePointer(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.05),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bank identity row: real logo (or wordmark fallback) +
                  // demo badge if applicable.
                  Row(
                    children: [
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final asset = bankLogoAssets[bank.cssClass];
                            if (asset != null) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(KreditRadius.chip),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    alignment: Alignment.center,
                                    child: BankLogoChip(assetPath: asset, height: 20),
                                  ),
                                ),
                              );
                            }
                            return Text(
                              bank.fullLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            );
                          },
                        ),
                      ),
                      if (isDemoCredit(credit.id)) const DemoBadge(),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // EMV chip + contactless icon, standard physical-card row.
                  const Row(
                    children: [
                      _EmvChip(),
                      Spacer(),
                      Icon(Icons.wifi, color: Colors.white70, size: 20),
                    ],
                  ),
                  const Spacer(),
                  // Purely decorative masked "card number" — Kredit never
                  // stores real card numbers, this is aesthetic only, in a
                  // monospaced face for the classic embossed-digit feel.
                  Text(
                    '••••  ••••  ••••  ••••',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontFamily: 'monospace',
                      fontSize: 15,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    credit.isCard ? 'Tarjeta de Crédito' : 'Préstamo (${bank.shortLabel})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Remaining-balance block is the reason this card exists —
                  // unmistakably the largest text on the face of the card.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DEUDA RESTANTE',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              formatCurrency(remaining),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 26,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
