import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/models/commercial_quota.dart';
import '../data/models/credit.dart';
import '../domain/bank_detector.dart';
import '../domain/card_calculator.dart';
import '../domain/commercial_quota_calculator.dart';
import '../domain/credit_calculator.dart';
import '../domain/date_utils.dart';
import '../providers/commercial_quotas_provider.dart';
import '../providers/credits_provider.dart' show isDemoCredit;
import '../theme/app_theme.dart';
import '../utils/credit_display_utils.dart';
import 'card_design_painter.dart';
import 'demo_badge.dart';
import 'kredit_wordmark.dart';
import 'voucher_pattern.dart';

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

/// Caché para gradientes expandidos — keyed por `cssClass|colorHex`.
/// Evita 4 Color.lerp + computeLuminance por cada build de WalletCard/EntityCardFace.
final _gradientExpandedCache = <String, List<Color>>{};

List<Color> expandedGradientFor(String cssClass, String? fallbackColorHex) {
  final key = '$cssClass|${fallbackColorHex ?? ''}';
  return _gradientExpandedCache.putIfAbsent(
    key,
    () => _expandGradient(_gradientFor(cssClass, fallbackColorHex)),
  );
}

/// Caché para luminancia promedio — evita el fold+computeLuminance por rebuild.
final _luminanceCache = <String, double>{};

double _avgLuminanceFor(String cssClass, String? fallbackColorHex) {
  final key = '$cssClass|${fallbackColorHex ?? ''}';
  return _luminanceCache.putIfAbsent(key, () {
    final g = expandedGradientFor(cssClass, fallbackColorHex);
    return g.fold<double>(0, (s, c) => s + c.computeLuminance()) / g.length;
  });
}

/// Pre-calienta los cachés de gradiente y luminancia para todos los créditos.
/// Llamar desde el splash después de que carguen los datos, antes de mostrar
/// la pantalla de créditos, para evitar caídas de FPS en la primera entrada.
void prewarmCardCaches(List<Credit> credits) {
  for (final credit in credits) {
    final bank = detectBank(
      lender: credit.lender,
      card: credit is LoanCredit ? (credit as LoanCredit).card : null, // ignore: unnecessary_cast
      fallbackColor: credit.color,
    );
    expandedGradientFor(bank.cssClass, credit.color);
    _avgLuminanceFor(bank.cssClass, credit.color);
  }
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
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CardPatternPainter oldDelegate) => false;
}

// Instancia estática — shouldRepaint devuelve false, por lo que Flutter
// Shared — never redraws.
final _emvChipPainter = _EmvChipPainter();

/// EMV chip fiel al prototipo HTML: fondo oscuro 1a1a1a, 6 contactos en
/// gradiente radial plata, borde gris oscuro. viewBox SVG origen: 36×28.
class _EmvChip extends StatelessWidget {
  const _EmvChip();

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: const Size(40, 30),
        painter: _emvChipPainter,
      );
}

class _EmvChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 36.0;
    final sy = size.height / 28.0;

    double px(double v) => v * sx;
    double py(double v) => v * sy;

    // Fondo negro
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(3.5 * sx),
      ),
      Paint()..color = const Color(0xFF1a1a1a),
    );

    // Gradiente radial plata: cx=12,cy=9,r=24 (userSpaceOnUse en SVG → canvas)
    final shader = ui.Gradient.radial(
      Offset(px(12), py(9)),
      px(24),
      const [Color(0xFFececec), Color(0xFFd8d8d8), Color(0xFFbebebe), Color(0xFFa0a0a0)],
      [0.0, 0.30, 0.62, 1.0],
    );
    final padPaint = Paint()..shader = shader;

    Path pad(List<List<double>> cmds) {
      final p = Path();
      for (final c in cmds) {
        switch (c[0].toInt()) {
          case 0: p.moveTo(px(c[1]), py(c[2]));
          case 1: p.lineTo(px(c[1]), py(c[2]));
          case 2: p.quadraticBezierTo(px(c[1]), py(c[2]), px(c[3]), py(c[4]));
          case 3: p.close();
        }
      }
      return p;
    }

    // 6 contactos (3 izq, 3 der) exactos del SVG — comando: 0=M,1=L,2=Q,3=Z
    final pads = [
      // C1 — top-left
      pad([[0,3.5,1.5],[1,14.5,1.5],[1,14.5,6.2],[2,14.5,9.2,11.5,9.2],[1,1.5,9.2],[1,1.5,3.5],[2,1.5,1.5,3.5,1.5],[3,0,0]]),
      // C2 — mid-left
      pad([[0,1.5,10.2],[1,11.5,10.2],[2,14.5,10.2,14.5,13.2],[1,14.5,14.9],[2,14.5,17.9,11.5,17.9],[1,1.5,17.9],[3,0,0]]),
      // C3 — bot-left
      pad([[0,1.5,18.9],[1,11.5,18.9],[2,14.5,18.9,14.5,21.9],[1,14.5,26.5],[1,3.5,26.5],[2,1.5,26.5,1.5,24.5],[1,1.5,18.9],[3,0,0]]),
      // C5 — top-right
      pad([[0,20.5,1.5],[1,32.5,1.5],[2,34.5,1.5,34.5,3.5],[1,34.5,9.2],[1,23.5,9.2],[2,20.5,9.2,20.5,6.2],[1,20.5,1.5],[3,0,0]]),
      // C6 — mid-right
      pad([[0,23.5,10.2],[2,20.5,10.2,20.5,13.2],[1,20.5,14.9],[2,20.5,17.9,23.5,17.9],[1,34.5,17.9],[1,34.5,10.2],[3,0,0]]),
      // C7 — bot-right
      pad([[0,23.5,18.9],[2,20.5,18.9,20.5,21.9],[1,20.5,26.5],[1,32.5,26.5],[2,34.5,26.5,34.5,24.5],[1,34.5,18.9],[3,0,0]]),
    ];

    for (final path in pads) {
      canvas.drawPath(path, padPaint);
    }

    // Borde exterior
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(px(0.5), py(0.5), px(35), py(27)),
        Radius.circular(3.5 * sx),
      ),
      Paint()
        ..color = const Color(0xFF5a5a5a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8 * sx,
    );
  }

  @override
  bool shouldRepaint(covariant _EmvChipPainter old) => false;
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

/// Logo NFC fiel al prototipo HTML: viewBox 22×22, centro (11,11),
/// 2 arcos concéntricos (r=9.2 stroke 1.8, r=7 stroke 0.9) abriendo a la
/// derecha (260° sweep CW) + texto "NFC" centrado en (12.5,11.5).
class _NfcIcon extends StatelessWidget {
  final Color color;
  final double size;
  const _NfcIcon({required this.color, this.size = 22});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size), painter: _NfcPainter(color: color));
}

class _NfcPainter extends CustomPainter {
  final Color color;
  const _NfcPainter({required this.color});

  static final Map<int, TextPainter> _tpCache = {};

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 22.0;
    // Centro en (11,11) del viewBox 22×22
    final cx = 11.0 * s;
    final cy = 11.0 * s;

    // Ángulo inicial: atan2 del vector centro→punto inicio (16.91,18.05)
    // dy=7.05, dx=5.91 → ≈50° = 0.8727 rad
    const startAngle = 0.8727; // atan2(7.05, 5.91)
    // Arco grande: 260° CW (la apertura de 100° queda al este, derecha del ícono)
    const sweepAngle = 4.5379; // 260° en rad

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Arco exterior: r=9.2, strokeWidth=1.8
    paint.strokeWidth = 1.8 * s;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy), width: 9.2 * 2 * s, height: 9.2 * 2 * s),
      startAngle, sweepAngle, false, paint,
    );

    // Arco interior: r=7, strokeWidth=0.9
    paint.strokeWidth = 0.9 * s;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy), width: 7.0 * 2 * s, height: 7.0 * 2 * s),
      startAngle, sweepAngle, false, paint,
    );

    // Texto "NFC" centrado en (12.5, 11.5) del viewBox, font-size=6.5
    final fontSize = 6.5 * s;
    final tp = _tpCache.putIfAbsent(color.toARGB32(), () {
      final p = TextPainter(
        text: TextSpan(
          text: 'NFC',
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      return p;
    });
    tp.paint(
      canvas,
      Offset(12.5 * s - tp.width / 2, 11.5 * s - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(_NfcPainter old) => color != old.color;
}

/// Decorative zigzag cut in the voucher's top-left corner, styled after
/// Nequi's own app (the dark-purple "Disponible" panel cut by straight,
/// semi-rounded diagonal edges, with a magenta sliver peeking through at
/// the valleys) — gives the Nequi cash-advance voucher a bit of that app's
/// actual visual identity instead of a generic flat rectangle. Confined to
/// the top-left area behind the bank logo chip; the rest of the voucher
/// stays plain white paper.
class VoucherWaveCornerPainter extends CustomPainter {
  final Color purple;
  final Color pink;
  const VoucherWaveCornerPainter({required this.purple, required this.pink});

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
    canvas.drawPath(
      _roundedPolygon(pinkPoints, cornerRadii),
      Paint()..color = pink,
    );

    final purplePoints = [
      const Offset(0, 0),
      Offset(w, 0),
      Offset(w, h * 0.3),
      Offset(w * 0.6, h * 0.66),
      Offset(w * 0.38, h * 0.34),
      Offset(0, h * 0.48),
    ];
    canvas.drawPath(
      _roundedPolygon(purplePoints, cornerRadii),
      Paint()..color = purple,
    );
  }

  @override
  bool shouldRepaint(covariant VoucherWaveCornerPainter oldDelegate) =>
      purple != oldDelegate.purple || pink != oldDelegate.pink;
}

/// Big visual wallet-card mockup shown atop the credit detail "Resumen" tab,
/// mirroring #detail-wallet-card in legacy_pwa/index.html (~L358-379).
class WalletCard extends ConsumerWidget {
  final Credit credit;

  const WalletCard({super.key, required this.credit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = credit is LoanCredit ? (credit as LoanCredit).card : null;
    final bank = detectBank(
      lender: credit.lender,
      card: card,
      fallbackColor: credit.color,
    );
    final gradient = expandedGradientFor(bank.cssClass, credit.color);
    final remaining = getCreditRemainingBalance(credit);
    final isBankVoucher = credit is LoanCredit && !bank.hasPhysicalCard;
    final isQuotaVoucher =
        credit is LoanCredit && (credit as LoanCredit).quotaId != null;
    final isVoucher = isBankVoucher || isQuotaVoucher;

    // Card design (null = predeterminado / legacy gradient)
    final cardDesign = isVoucher
        ? null
        : CardDesign.fromKey(credit.cardDesign);

    // Luminancia promedio cacheada — evita fold+computeLuminance por build.
    final avgLuminance = _avgLuminanceFor(bank.cssClass, credit.color);
    // Patrón del voucher: select() para no reconstruir si cambia otra quota.
    final quotaPattern = isQuotaVoucher
        ? VoucherPattern.fromName(
            ref.watch(commercialQuotasProvider.select(
              (quotas) => quotas.valueOrNull
                  ?.where((q) => q.id == (credit as LoanCredit).quotaId)
                  .firstOrNull
                  ?.voucherPattern,
            )),
          )
        : VoucherPattern.diagonalLines;
    final isLightFace = isBankVoucher ||
        (cardDesign?.isLightBackground ?? false) ||
        (!isVoucher && cardDesign == null && avgLuminance > 0.5);
    // Neo-Geo has a cream base visible in the bottom corners — white text
    // there is illegible. Use dark ink only for the bottom block.
    final isNeoGeoBottom = cardDesign == CardDesign.neoGeo;
    final ink = isQuotaVoucher
        ? quotaPattern.foregroundColor
        : (isLightFace ? Colors.black : Colors.white);
    final inkStrong = ink;
    final inkMid = ink.withValues(alpha: isLightFace ? 0.72 : 0.78);
    final inkFaint = ink.withValues(alpha: isLightFace ? 0.55 : 0.6);
    // Bottom-block ink (dark for Neo-Geo cream zone, same as global otherwise).
    final bottomInkStrong = isNeoGeoBottom ? Colors.black : inkStrong;
    final bottomInkMid = isNeoGeoBottom ? Colors.black.withValues(alpha: 0.72) : inkMid;
    final bottomInkFaint = isNeoGeoBottom ? Colors.black.withValues(alpha: 0.55) : inkFaint;
    final chipChromeBorder = Colors.white.withValues(
      alpha: isLightFace ? 0.55 : 0.08,
    );

    final stats = _statsFor(credit);

    // RepaintBoundary: this card's face (gradient/pattern painters, dashed
    // border) is expensive to composite and never changes for reasons
    // unrelated to its own data — without this, every keystroke in a
    // parent form (e.g. EditCreditSheet's live preview, which rebuilds on
    // every character typed) forces the whole surrounding subtree onto the
    // same compositor layer, repainting this card's face too even though
    // nothing in it changed.
    final cardWidget = RepaintBoundary(
      child: AspectRatio(
        // Noticeably shorter than the previous 1.65 — same footprint width,
        // less vertical real-estate, while the stats block below absorbs the
        // data that used to live in a separate CreditStatsRow underneath.
        aspectRatio: 1.9,
        child: ClipPath(
          // Voucher variant clips to the notched voucherOutline (a "torn
          // ticket stub" shape); a real card keeps a plain, more-rounded rect
          // — CustomClipper defaults to a full-rect path when not overridden,
          // so a plain ClipRect-equivalent isn't needed here.
          clipper: isVoucher
              ? const VoucherClipper()
              : ShapeBorderClipper(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
          child: Stack(
            children: [
              // Base surface: a real card gets the bank's brand gradient; the
              // voucher variant is plain white paper instead (Nequi-styled —
              // its own color shows only in the wave corner painted below).
              // The voucher also skips the solid chrome border (a
              // straight-edged Border.all would poke past the notched clip)
              // — its edge comes entirely from the dashed outline instead.
              Positioned.fill(
                child: isQuotaVoucher
                    ? DecoratedBox(
                        decoration: quotaPattern.backgroundDecoration,
                      )
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          color: isBankVoucher ? Colors.white : null,
                          gradient: (isVoucher || cardDesign != null)
                              ? null
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: gradient,
                                ),
                          border: isVoucher
                              ? null
                              : Border.all(color: chipChromeBorder),
                        ),
                      ),
              ),
              // Custom card design background (when not voucher and design selected)
              if (!isVoucher && cardDesign != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: CardDesignPainter(
                        design: cardDesign,
                        c1: gradient.first,
                        c2: gradient[gradient.length ~/ 2],
                        c3: gradient.last,
                      ),
                    ),
                  ),
                ),
              // Real bank cash-advance voucher only (Nequi/DaviPlata): the
              // brand's own wave-corner cut, echoing that bank's own app —
              // never used for a cupo comercial purchase, which is a flat
              // accent-colored fill instead (see the DecoratedBox above).
              if (isBankVoucher)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: VoucherWaveCornerPainter(
                        purple: Color(0xFF2A0944),
                        pink: Color(0xFFDA0081),
                      ),
                    ),
                  ),
                ),
              // Radial highlights: only for legacy gradient
              if (!isVoucher && cardDesign == null)
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
              if (!isVoucher && cardDesign == null)
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
              // Cupo comercial voucher only: the user-selected abstract
              // texture (Ajustes → Personalización → "Diseño de voucher"),
              // spanning the whole face but faded out before the bottom
              // disponible/compras figures. Real bank cash-advance vouchers
              // keep their own Nequi-style wave corner instead.
              if (isQuotaVoucher)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: VoucherPatternPainter(pattern: quotaPattern),
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
                      painter: VoucherBorderPainter(
                        color: ink.withValues(alpha: 0.35),
                      ),
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
                              // Cupo comercial voucher: Kredit's own
                              // wordmark, painted straight in `ink` (no
                              // white chip box) — this IS the brand's
                              // voucher, not a third-party bank's.
                              if (isQuotaVoucher) {
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: KreditWordmark(color: ink, height: 18),
                                );
                              }
                              final asset = bankLogoAssets[bank.cssClass];
                              if (asset != null) {
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        KreditRadius.chip,
                                      ),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.contain,
                                      alignment: Alignment.center,
                                      child: BankLogoChip(
                                        assetPath: asset,
                                        height: 17,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return Text(
                                bank.fullLabel,
                                style: TextStyle(
                                  color: inkStrong,
                                  fontWeight: FontWeight.w700,
                                  fontSize: KreditTextSize.body,
                                  letterSpacing: 0.5,
                                ),
                              );
                            },
                          ),
                        ),
                        // Nombre que el usuario le dio a este crédito/tarjeta
                        // al crearlo (ej. "Mi RappiCard" vs. "RappiCard de
                        // Ana") — antes `credit.name` no se pintaba en
                        // ningún lado de la tarjeta visual, así que dos
                        // tarjetas del mismo banco eran indistinguibles a
                        // simple vista. Chip de alto contraste (no un texto
                        // discreto) para que salte a la vista, no una nota
                        // al pie.
                        if (credit.name.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 130),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isLightFace
                                    ? Colors.black
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(
                                  KreditRadius.chip,
                                ),
                              ),
                              child: Text(
                                credit.name.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isLightFace
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.w800,
                                  fontSize: KreditTextSize.body,
                                  letterSpacing: 0.2,
                                ),
                              ),
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
                          _NfcIcon(color: inkMid, size: KreditIconSize.small),
                        ],
                      ),
                    const Spacer(),
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
                                  color: bottomInkFaint,
                                  fontSize: KreditTextSize.body,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                formatCOP(remaining),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: bottomInkStrong,
                                  fontWeight: FontWeight.w800,
                                  fontSize: KreditTextSize.emphasis,
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
                            captionColor: bottomInkFaint,
                            valueColor: bottomInkStrong,
                            secondaryColor: bottomInkMid,
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
      ),
    );

    return cardWidget;
  }
}

void showCardDesignPicker(
  BuildContext context, {
  required CardDesign? current,
  required Color c1,
  required Color c2,
  required Color c3,
  required void Function(CardDesign?) onSelected,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DesignPickerSheet(
      current: current,
      c1: c1,
      c2: c2,
      c3: c3,
      onSelected: (d) {
        Navigator.of(context).pop();
        onSelected(d);
      },
    ),
  );
}

class _DesignPickerSheet extends StatelessWidget {
  final CardDesign? current;
  final Color c1, c2, c3;
  final void Function(CardDesign?) onSelected;

  const _DesignPickerSheet({
    required this.current,
    required this.c1,
    required this.c2,
    required this.c3,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final allOptions = <(CardDesign?, String)>[
      (null, 'Predeterminado'),
      ...CardDesign.values.map((d) => (d, d.label)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'DISEÑO DE TARJETA',
              style: TextStyle(
                fontSize: KreditTextSize.body,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.35,
                ),
                itemCount: allOptions.length,
                itemBuilder: (_, i) {
                  final (design, label) = allOptions[i];
                  final isSelected = design == current;
                  return RepaintBoundary(
                    child: GestureDetector(
                      onTap: () => onSelected(design),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox.expand(
                                    child: design == null
                                        ? DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [c1, c2, c3],
                                              ),
                                            ),
                                          )
                                        : CustomPaint(
                                            painter: CardDesignPainter(
                                              design: design,
                                              c1: c1,
                                              c2: c2,
                                              c3: c3,
                                              isPreview: true,
                                            ),
                                          ),
                                  ),
                                ),
                                if (isSelected)
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: scheme.primary,
                                          width: 2.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (isSelected)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: scheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        size: KreditIconSize.micro,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: KreditTextSize.body,
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
      items.add(
        _StatItem(
          icon: Icons.credit_card_outlined,
          label: 'Cupo disponible',
          value: formatCOP(available),
        ),
      );
    }
    if (credit.currentBalance > 0) {
      final due = getCardCycleDates(credit).dueDate;
      items.add(
        _StatItem(
          icon: Icons.event_outlined,
          label: 'Próximo pago',
          value: formatDate(toDateStr(due)),
        ),
      );
    }
  } else if (credit is LoanCredit) {
    final unpaid = credit.installments.where((i) => !i.paid).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    if (unpaid.isNotEmpty) {
      final next = unpaid.first;
      items.add(
        _StatItem(
          icon: Icons.payments_outlined,
          label: 'Próxima cuota',
          value: formatCOP(next.amount),
        ),
      );
      items.add(
        _StatItem(
          icon: Icons.event_outlined,
          label: 'Vence',
          value: formatDate(next.dueDate),
        ),
      );
    }
  }

  return items;
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });
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
            fontSize: KreditTextSize.body,
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
            fontSize: KreditTextSize.emphasis,
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
              fontSize: KreditTextSize.body,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ],
    );
  }
}

/// Cara de tarjeta/voucher para el picker de entidades — mismo visual que
/// [WalletCard] pero sin deuda restante. Muestra disponible/límite abajo.
/// Se define aquí para acceder a las clases privadas del fichero.
class EntityCardFace extends StatelessWidget {
  final CommercialQuota quota;
  final List<LoanCredit> allLoans;

  const EntityCardFace({
    super.key,
    required this.quota,
    required this.allLoans,
  });

  @override
  Widget build(BuildContext context) {
    final isStore = quota.entityType == EntityType.store;
    final bank = detectBank(lender: quota.brand);
    final gradient = expandedGradientFor(bank.cssClass, null);

    final isQuotaVoucher = isStore;
    final isBankVoucher = !isStore && !bank.hasPhysicalCard;
    final isVoucher = isQuotaVoucher || isBankVoucher;

    final quotaPattern = isQuotaVoucher
        ? VoucherPattern.fromName(quota.voucherPattern)
        : VoucherPattern.diagonalLines;

    final avgLuminance = _avgLuminanceFor(bank.cssClass, null);
    final isLightFace = isBankVoucher || (!isVoucher && avgLuminance > 0.5);
    final ink = isQuotaVoucher
        ? quotaPattern.foregroundColor
        : (isLightFace ? Colors.black : Colors.white);
    final inkFaint = ink.withValues(alpha: isLightFace ? 0.55 : 0.6);
    final chipChromeBorder =
        Colors.white.withValues(alpha: isLightFace ? 0.55 : 0.08);

    final double? available = quota.limit > 0
        ? (isStore ? quotaAvailable(quota, allLoans) : quota.limit)
        : null;
    final bottomLabel = isStore ? 'DISPONIBLE' : 'LÍMITE';
    final bottomValue = available != null ? formatCOP(available) : '—';

    return AspectRatio(
      aspectRatio: 1.9,
      child: ClipPath(
        clipper: isVoucher
            ? const VoucherClipper()
            : ShapeBorderClipper(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
        child: Stack(
          children: [
            Positioned.fill(
              child: isQuotaVoucher
                  ? DecoratedBox(decoration: quotaPattern.backgroundDecoration)
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        color: isBankVoucher ? Colors.white : null,
                        gradient: isVoucher
                            ? null
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: gradient,
                              ),
                        border:
                            isVoucher ? null : Border.all(color: chipChromeBorder),
                      ),
                    ),
            ),
            if (isBankVoucher)
              const Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: VoucherWaveCornerPainter(
                      purple: Color(0xFF2A0944),
                      pink: Color(0xFFDA0081),
                    ),
                  ),
                ),
              ),
            if (!isVoucher)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: const _CardPatternPainter()),
                ),
              ),
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
            if (isQuotaVoucher)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: VoucherPatternPainter(pattern: quotaPattern),
                  ),
                ),
              ),
            if (isVoucher)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter:
                        VoucherBorderPainter(color: ink.withValues(alpha: 0.35)),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Builder(
                          builder: (ctx) {
                            if (isQuotaVoucher) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: KreditWordmark(color: ink, height: 18),
                              );
                            }
                            final asset = bankLogoAssets[bank.cssClass];
                            if (asset != null) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(KreditRadius.chip),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child:
                                        BankLogoChip(assetPath: asset, height: 17),
                                  ),
                                ),
                              );
                            }
                            return Text(
                              bank.fullLabel,
                              style: TextStyle(
                                color: ink,
                                fontWeight: FontWeight.w700,
                                fontSize: KreditTextSize.body,
                                letterSpacing: 0.5,
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 130),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: isLightFace ? Colors.black : Colors.white,
                          borderRadius: BorderRadius.circular(KreditRadius.chip),
                        ),
                        child: Text(
                          quota.brand,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isLightFace ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w800,
                            fontSize: KreditTextSize.body,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!isVoucher) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const _EmvChip(),
                        const Spacer(),
                        _NfcIcon(color: inkFaint, size: KreditIconSize.small),
                      ],
                    ),
                  ],
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        bottomLabel,
                        style: TextStyle(
                          color: inkFaint,
                          fontSize: KreditTextSize.body,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        bottomValue,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w800,
                          fontSize: KreditTextSize.emphasis,
                          letterSpacing: -0.5,
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
