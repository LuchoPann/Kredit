import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/models/credit.dart';
import '../domain/bank_detector.dart';
import '../domain/card_calculator.dart';
import '../domain/credit_calculator.dart';
import '../domain/date_utils.dart';
import '../providers/credits_provider.dart' show isDemoCredit;
import '../theme/app_theme.dart';
import '../utils/credit_display_utils.dart';
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

/// Outline of the "cash-advance voucher" variant of [WalletCard]: a SQUARE-
/// cornered rect (no corner rounding at all — a comprobante/talonario is cut
/// paper, not a plastic card) with a tall OVAL notch (noticeably taller than
/// wide — curved top-to-bottom, not side-to-side) cut into the middle of the
/// left and right edges. Takes an explicit [rect] rather than always the
/// full bounds so [_VoucherBorderPainter] can trace an INSET copy (border
/// drawn slightly inside the true edge) while [_VoucherClipper] clips the
/// card face to the full-size version — both built by this one function so
/// their curvature/notch shape never drifts apart.
Path _voucherOutline(
  Rect rect, {
  double radius = 0,
  double notchWidth = 14,
  double notchHeight = 26,
}) {
  final base = Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
  final notchCenterY = rect.top + rect.height / 2;
  final notches = Path()
    ..addOval(Rect.fromCenter(
      center: Offset(rect.left, notchCenterY),
      width: notchWidth,
      height: notchHeight,
    ))
    ..addOval(Rect.fromCenter(
      center: Offset(rect.right, notchCenterY),
      width: notchWidth,
      height: notchHeight,
    ));
  return Path.combine(PathOperation.difference, base, notches);
}

/// Clips [WalletCard]'s voucher variant to [_voucherOutline] (full bounds) —
/// the side notches only read as "cut into the shape" if the card face
/// itself (its gradient, glints, etc.) is actually clipped there, not just
/// outlined.
class _VoucherClipper extends CustomClipper<Path> {
  const _VoucherClipper();

  @override
  Path getClip(Size size) => _voucherOutline(Offset.zero & size);

  // Always true: the outline is cheap to recompute, and returning false
  // let a stale cached clip shape survive a hot reload that changed
  // _voucherOutline's geometry (radius/notch size) — the card face would
  // keep the OLD silhouette while the dashed border painter (repainted
  // unconditionally on reassemble) already showed the new one.
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

/// Dashed stroke traced along [_voucherOutline], INSET a few pixels from the
/// true edge (rather than sitting exactly on it) — reads as a stitched
/// comprobante line just inside the paper's edge rather than the edge
/// itself. Walks the path via [Path.computeMetrics] so the dash pattern
/// follows the oval notches correctly instead of just the bounding rect.
class _VoucherBorderPainter extends CustomPainter {
  final Color color;
  const _VoucherBorderPainter({required this.color});

  static const _inset = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _voucherOutline((Offset.zero & size).deflate(_inset));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    const dashWidth = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _VoucherBorderPainter oldDelegate) =>
      color != oldDelegate.color;
}

/// Builds a closed polygon path, rounding each vertex by the matching entry
/// in [radii] (same length as [points]; pass 0 for a vertex that must stay
/// perfectly sharp — e.g. the card's true outer corners — and a positive
/// value for the interior zigzag peaks/valleys that should read as
/// "straight edges, small rounded corners"). Replaces each rounded corner
/// with a short quadratic bezier between points pulled back along its two
/// adjacent edges, the standard "rounded polygon" technique.
Path _roundedPolygon(List<Offset> points, List<double> radii) {
  final path = Path();
  final n = points.length;
  for (var i = 0; i < n; i++) {
    final curr = points[i];
    final prev = points[(i - 1 + n) % n];
    final next = points[(i + 1) % n];
    final toPrev = prev - curr;
    final toNext = next - curr;
    final radius = radii[i];
    final rBack = radius.clamp(0.0, toPrev.distance / 2);
    final rFwd = radius.clamp(0.0, toNext.distance / 2);
    final start = curr + toPrev / toPrev.distance * rBack;
    final end = curr + toNext / toNext.distance * rFwd;
    if (i == 0) {
      path.moveTo(start.dx, start.dy);
    } else {
      path.lineTo(start.dx, start.dy);
    }
    path.quadraticBezierTo(curr.dx, curr.dy, end.dx, end.dy);
  }
  path.close();
  return path;
}

/// Decorative zigzag cut in the voucher's top-left corner, styled after
/// Nequi's own app (the dark-purple "Disponible" panel cut by straight,
/// semi-rounded diagonal edges, with a magenta sliver peeking through at
/// the valleys) — gives the Nequi cash-advance voucher a bit of that app's
/// actual visual identity instead of a generic flat rectangle. Confined to
/// the top-left area behind the bank logo chip; the rest of the voucher
/// stays plain white paper.
class _NequiWaveCornerPainter extends CustomPainter {
  final Color purple;
  final Color pink;
  const _NequiWaveCornerPainter({required this.purple, required this.pink});

  @override
  void paint(Canvas canvas, Size size) {
    // Spans the FULL card width — no white should show at the top corners,
    // only below the shape's straight diagonal edges. One peak + one
    // valley (not a repeating zigzag), small rounded corners at every
    // vertex. Pink drawn first, its points pulled further down than
    // purple's at each matching x so it peeks through underneath.
    final w = size.width;
    final h = size.height * 0.62;

    // The first two points of each list are the card's TRUE top-left/
    // top-right outer corners — radius 0, perfectly sharp, matching a real
    // card/voucher edge. Every other point is an interior zigzag
    // peak/valley (or where the diagonal exits the card's side edge),
    // which gets the small rounding.
    const cornerRadii = [0.0, 0.0, 12.0, 12.0, 12.0, 12.0];

    final pinkPoints = [
      const Offset(0, 0),
      Offset(w, 0),
      Offset(w, h * 0.42),
      Offset(w * 0.58, h * 0.86),
      Offset(w * 0.34, h * 0.5),
      Offset(0, h * 0.66),
    ];
    canvas.drawPath(_roundedPolygon(pinkPoints, cornerRadii), Paint()..color = pink);

    final purplePoints = [
      const Offset(0, 0),
      Offset(w, 0),
      Offset(w, h * 0.3),
      Offset(w * 0.6, h * 0.66),
      Offset(w * 0.38, h * 0.34),
      Offset(0, h * 0.48),
    ];
    canvas.drawPath(_roundedPolygon(purplePoints, cornerRadii), Paint()..color = purple);
  }

  @override
  bool shouldRepaint(covariant _NequiWaveCornerPainter oldDelegate) =>
      purple != oldDelegate.purple || pink != oldDelegate.pink;
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
    // A LoanCredit whose lender has no real physical card product (e.g.
    // Nequi cash advances) gets the "cash-advance voucher" chrome instead of
    // the physical-card mockup — no EMV chip, no contactless icon. A
    // CardCredit is, by definition, always a real card, so it NEVER uses
    // this variant even if its lender were ever flagged hasPhysicalCard:
    // false — the `is LoanCredit` check always comes first.
    final isVoucher = credit is LoanCredit && !bank.hasPhysicalCard;

    // The card face can be any accent color the user picks (light or dark),
    // so text color is derived from the actual gradient rather than assumed
    // white — the same luminance-based approach used for the dashboard FAB
    // (dashboard_screen.dart) applied per-stop and averaged, since the face
    // is a gradient, not a single flat color.
    final avgLuminance =
        gradient.fold<double>(0, (sum, c) => sum + c.computeLuminance()) / gradient.length;
    // Voucher variant is white paper with black ink unconditionally (styled
    // after Nequi's own app), regardless of the bank's brand gradient
    // luminance — only a real plastic card derives ink color from its face.
    final isLightFace = isVoucher || avgLuminance > 0.5;
    final ink = isLightFace ? Colors.black : Colors.white;
    final inkStrong = ink;
    final inkMid = ink.withValues(alpha: isLightFace ? 0.72 : 0.78);
    final inkFaint = ink.withValues(alpha: isLightFace ? 0.55 : 0.6);
    final chipChromeBorder = Colors.white.withValues(alpha: isLightFace ? 0.55 : 0.08);

    final stats = _statsFor(credit);

    return AspectRatio(
      // Noticeably shorter than the previous 1.65 — same footprint width,
      // less vertical real-estate, while the stats block below absorbs the
      // data that used to live in a separate CreditStatsRow underneath.
      aspectRatio: 1.9,
      child: ClipPath(
        // Voucher variant clips to the notched _voucherOutline (a "torn
        // ticket stub" shape); a real card keeps a plain, more-rounded rect
        // — CustomClipper defaults to a full-rect path when not overridden,
        // so a plain ClipRect-equivalent isn't needed here.
        clipper: isVoucher
            ? const _VoucherClipper()
            : ShapeBorderClipper(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        child: Stack(
          children: [
            // Base surface: a real card gets the bank's brand gradient; the
            // voucher variant is plain white paper instead (Nequi-styled —
            // its own color shows only in the wave corner painted below).
            // The voucher also skips the solid chrome border (a
            // straight-edged Border.all would poke past the notched clip)
            // — its edge comes entirely from the dashed outline instead.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isVoucher ? Colors.white : null,
                  gradient: isVoucher
                      ? null
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradient,
                        ),
                  border: isVoucher ? null : Border.all(color: chipChromeBorder),
                ),
              ),
            ),
            // Voucher variant: Nequi-styled wave cut in the top-left corner
            // (dark purple + magenta sliver, echoing Nequi's own app) behind
            // where the bank logo chip sits — the rest of the voucher stays
            // white paper.
            if (isVoucher)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: const _NequiWaveCornerPainter(
                      // Real Nequi brand tones, not the generic dark-navy
                      // gradient this bank uses elsewhere as a card face —
                      // deep violet + Nequi's actual magenta (#DA0081,
                      // already used as its auto-picked accent color
                      // elsewhere in the app).
                      purple: Color(0xFF2A0944),
                      pink: Color(0xFFDA0081),
                    ),
                  ),
                ),
              ),
            // Very tenuous diagonal-line texture, characteristic of
            // physical card mockups — pure decoration, no shadow. Skipped
            // for the voucher variant, which should read as flatter paper
            // rather than textured plastic.
            if (!isVoucher)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: const _CardPatternPainter()),
                ),
              ),
            // Subtle radial highlight/reflection in the top-right corner, to
            // sell the "physical card" feel — skipped for the voucher
            // variant, which is meant to read as flat/minimalist paper, not
            // glossy plastic.
            if (!isVoucher)
              Positioned(
                top: -40,
                right: -40,
                child: IgnorePointer(
                  child: Container(
                    width: 150,
                    height: 150,
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
            // light instead of a single flat highlight — also card-only.
            if (!isVoucher)
              Positioned(
                bottom: -50,
                left: -30,
                child: IgnorePointer(
                  child: Container(
                    width: 130,
                    height: 130,
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
            // Voucher variant: the dashed border traces the full notched
            // outline (corners + side notches) instead of a solid edge —
            // this is the "comprobante/talonario" cue, replacing the old
            // internal-only tear line.
            if (isVoucher)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _VoucherBorderPainter(color: ink.withValues(alpha: 0.35)),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(KreditRadius.chip),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    alignment: Alignment.center,
                                    child: BankLogoChip(assetPath: asset, height: 17),
                                  ),
                                ),
                              );
                            }
                            return Text(
                              bank.fullLabel,
                              style: TextStyle(
                                color: inkStrong,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            );
                          },
                        ),
                      ),
                      if (isDemoCredit(credit.id)) const DemoBadge(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // EMV chip + contactless icon, standard physical-card row
                  // — skipped entirely for the cash-advance voucher variant,
                  // which has no real plastic to simulate.
                  if (!isVoucher)
                    Row(
                      children: [
                        const _EmvChip(),
                        const Spacer(),
                        Icon(Icons.wifi, color: inkMid, size: 18),
                      ],
                    ),
                  const Spacer(),
                  Text(
                    credit.isCard
                        ? 'Tarjeta de Crédito'
                        : (isVoucher ? 'Adelanto (${bank.shortLabel})' : 'Préstamo (${bank.shortLabel})'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: inkMid,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Bottom block: deuda restante (left) and the next-payment
                  // fact (right) as two matched columns, same caption/value
                  // type scale on both sides so neither reads as an
                  // afterthought — bottom-aligned so a taller side pushes the
                  // shorter one's baseline down with it instead of the two
                  // blocks drifting apart.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'DEUDA RESTANTE',
                              style: TextStyle(
                                color: inkFaint,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              formatCOP(remaining),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: inkStrong,
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (stats.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        _CardStatColumn(
                          primary: stats[0],
                          secondary: stats.length > 1 ? stats[1] : null,
                          captionColor: inkFaint,
                          valueColor: inkStrong,
                          secondaryColor: inkMid,
                        ),
                      ],
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

/// Builds the key-facts list shown at the bottom of [WalletCard]: available
/// limit + next payment date for cards, next installment amount + due date
/// for loans. Previously a separate `CreditStatsRow` rendered underneath the
/// card; now the single source of truth lives here, inside the card face.
List<_StatItem> _statsFor(Credit credit) {
  final items = <_StatItem>[];

  if (credit is CardCredit) {
    // Skip the "cupo disponible" fact entirely when no limit was set (the
    // user left it empty at creation) — showing "$0 disponible" would read
    // as "you have no credit left" instead of "we don't know your limit".
    if (credit.creditLimit > 0) {
      final available = getCardAvailableLimit(credit);
      items.add(_StatItem(
        icon: Icons.credit_card_outlined,
        label: 'Cupo disponible',
        value: formatCOP(available),
      ));
    }
    if (credit.currentBalance > 0) {
      final due = getCardCycleDates(credit).dueDate;
      items.add(_StatItem(
        icon: Icons.event_outlined,
        label: 'Próximo pago',
        value: formatDate(toDateStr(due)),
      ));
    }
  } else if (credit is LoanCredit) {
    final unpaid = credit.installments.where((i) => !i.paid).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    if (unpaid.isNotEmpty) {
      final next = unpaid.first;
      items.add(_StatItem(
        icon: Icons.payments_outlined,
        label: 'Próxima cuota',
        value: formatCOP(next.amount),
      ));
      items.add(_StatItem(
        icon: Icons.event_outlined,
        label: 'Vence',
        value: formatDate(next.dueDate),
      ));
    }
  }

  return items;
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  const _StatItem({required this.icon, required this.label, required this.value});
}

/// Right-side key-fact column rendered inside the [WalletCard] face,
/// mirroring the left "DEUDA RESTANTE" block's type scale so the next
/// payment fact reads with the same weight instead of a small afterthought:
/// a caption the same size as "DEUDA RESTANTE" (10px) topping a value the
/// same size as the debt amount (22px) — [secondary] (e.g. the due date)
/// trails below at the smaller type-label scale (12px), same spot it held
/// before this block was widened to match the left column.
class _CardStatColumn extends StatelessWidget {
  final _StatItem primary;
  final _StatItem? secondary;
  final Color captionColor;
  final Color valueColor;
  final Color secondaryColor;

  const _CardStatColumn({
    required this.primary,
    required this.secondary,
    required this.captionColor,
    required this.valueColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          primary.label.toUpperCase(),
          style: TextStyle(
            color: captionColor,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        Text(
          primary.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        if (secondary != null) ...[
          const SizedBox(height: 3),
          Text(
            '${secondary!.label}: ${secondary!.value}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: secondaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ],
    );
  }
}
