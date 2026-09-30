import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

enum VoucherPattern {
  diagonalLines('Bauhaus'),
  arcs('Memphis'),
  constellation('Swiss Grid'),
  circles('Brutalista'),
  asymmetricGrid('Art Decó'),
  waves('Risografía'),
  circuit('Vaporwave'),
  halftone('Ukiyo-e');

  final String label;
  const VoucherPattern(this.label);

  /// Fixed background decoration — each style owns its palette; no accent color.
  Decoration get backgroundDecoration => switch (this) {
    VoucherPattern.diagonalLines => const BoxDecoration(color: Color(0xFFFAFAF7)),
    VoucherPattern.arcs          => const BoxDecoration(color: Color(0xFF1B1712)),
    VoucherPattern.constellation => const BoxDecoration(color: Color(0xFFFAFAFA)),
    VoucherPattern.circles       => const BoxDecoration(color: Color(0xFF2B2B2B)),
    VoucherPattern.asymmetricGrid => const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment(-0.45, -0.90),
        end:   Alignment( 0.45,  0.90),
        colors: [Color(0xFF0E2038), Color(0xFF0B1A2E)],
      ),
    ),
    VoucherPattern.waves => const BoxDecoration(color: Color(0xFFFDF6EC)),
    VoucherPattern.circuit => const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end:   Alignment.bottomCenter,
        stops: [0.0, 0.45, 1.0],
        colors: [Color(0xFF1A0B2E), Color(0xFF5B1A6B), Color(0xFF0C0616)],
      ),
    ),
    VoucherPattern.halftone => const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end:   Alignment.bottomCenter,
        colors: [Color(0xFF1B2A4A), Color(0xFF101B33)],
      ),
    ),
  };

  /// Fixed foreground color for text, logo, and border elements.
  Color get foregroundColor => switch (this) {
    VoucherPattern.diagonalLines  => const Color(0xFF111111),
    VoucherPattern.arcs           => const Color(0xFFEFE3C7),
    VoucherPattern.constellation  => const Color(0xFF111111),
    VoucherPattern.circles        => const Color(0xFFF5F5F5),
    VoucherPattern.asymmetricGrid => const Color(0xFFF3E9CB),
    VoucherPattern.waves          => const Color(0xFF1B1B3A),
    VoucherPattern.circuit        => const Color(0xFFF3E7FF),
    VoucherPattern.halftone       => const Color(0xFFEAF3FA),
  };

  static VoucherPattern fromName(String? name) {
    return VoucherPattern.values.firstWhere(
      (p) => p.name == name,
      orElse: () => VoucherPattern.diagonalLines,
    );
  }
}

/// Draws the decorative art-style pattern for a voucher.
/// The background is owned by [VoucherPattern.backgroundDecoration] — this
/// painter only draws the pattern layer on top of that background.
/// All coordinates are in the SVG viewBox (340 × 180) and scaled to the
/// actual widget size internally.
class VoucherPatternPainter extends CustomPainter {
  final VoucherPattern pattern;
  const VoucherPatternPainter({required this.pattern});

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 340.0;
    final sy = size.height / 180.0;
    canvas.save();
    canvas.scale(sx, sy);

    switch (pattern) {
      case VoucherPattern.diagonalLines:
        _paintBauhaus(canvas);
      case VoucherPattern.arcs:
        _paintMemphis(canvas);
      case VoucherPattern.constellation:
        _paintSwissGrid(canvas);
      case VoucherPattern.circles:
        _paintBrutalist(canvas);
      case VoucherPattern.asymmetricGrid:
        _paintArtDeco(canvas);
      case VoucherPattern.waves:
        _paintRisograph(canvas);
      case VoucherPattern.circuit:
        _paintVaporwave(canvas);
      case VoucherPattern.halftone:
        _paintUkiyoE(canvas);
    }

    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // 1. Bauhaus — vertical stripe field clipped to a notched band, concentric
  //    sun rings rising from the centre, top-band cover + separator line.
  // ---------------------------------------------------------------------------
  void _paintBauhaus(Canvas canvas) {
    // Stripe clip: M0,46 H340 V112 H180 L160,126 H0 Z
    final clip = Path()
      ..moveTo(0, 46)
      ..lineTo(340, 46)
      ..lineTo(340, 112)
      ..lineTo(180, 112)
      ..lineTo(160, 126)
      ..lineTo(0, 126)
      ..close();
    canvas.save();
    canvas.clipPath(clip);
    final linePaint = Paint()
      ..color = const Color(0xFF111111).withValues(alpha: 0.9)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    for (double x = 6; x <= 330; x += 9) {
      canvas.drawLine(Offset(x, 46), Offset(x, 128), linePaint);
    }
    canvas.restore();

    // Filled concentric sun rings, outermost first
    const ringColors = [
      0xFF4A2C13, 0xFFB5471E, 0xFFD9591F,
      0xFFEB7A2B, 0xFFF4993C, 0xFFFAC15A,
    ];
    const radii = [26.0, 22.0, 18.0, 14.0, 10.0, 5.0];
    for (var i = 0; i < radii.length; i++) {
      canvas.drawCircle(
        const Offset(170, 82),
        radii[i],
        Paint()..color = Color(ringColors[i]),
      );
    }

    // Top band cover (white) then narrow black cap line
    canvas.drawRect(
      const Rect.fromLTWH(0, 40, 340, 10),
      Paint()..color = const Color(0xFFFAFAF7),
    );
    canvas.drawRect(
      const Rect.fromLTWH(0, 45, 340, 2.5),
      Paint()..color = const Color(0xFF111111),
    );

    // Stepped lower separator
    final sep = Path()
      ..moveTo(0, 126)
      ..lineTo(160, 126)
      ..lineTo(180, 112)
      ..lineTo(340, 112);
    canvas.drawPath(
      sep,
      Paint()
        ..color = const Color(0xFF111111)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Memphis — multicolor geometric field: squiggles, shapes, patterns
  //    Clip zone: y=42–118. Card-edge bleeding (x=0, x=340) looks intentional.
  // ---------------------------------------------------------------------------
  void _paintMemphis(Canvas canvas) {
    const coral  = Color(0xFFFF6B6B);
    const yellow = Color(0xFFFBBF24);
    const purple = Color(0xFF8B5CF6);
    const teal   = Color(0xFF34D399);
    const pink   = Color(0xFFF472B6);
    const cream  = Color(0xFFEFE3C7);

    canvas.save();
    canvas.clipRect(const Rect.fromLTWH(0, 42, 340, 76)); // y=42..118

    // ── Left edge: coral semicircle bleeding off x=0 (intentional) ──
    canvas.drawCircle(const Offset(0, 80), 36,
        Paint()..color = coral.withValues(alpha: 0.20));
    canvas.drawCircle(const Offset(0, 80), 36,
        Paint()
          ..color = coral.withValues(alpha: 0.80)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8);

    // ── Yellow triangle ──
    canvas.drawPath(
      Path()..moveTo(105, 50)..lineTo(126, 82)..lineTo(84, 82)..close(),
      Paint()..color = yellow.withValues(alpha: 0.82),
    );

    // ── Striped yellow rect (140,50 36×22) — 45° diagonal stripes ──
    canvas.save();
    canvas.clipRect(const Rect.fromLTWH(140, 50, 36, 22));
    final stripeY = Paint()
      ..color = yellow.withValues(alpha: 0.65)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    for (double i = -22; i <= 58; i += 5) {
      canvas.drawLine(Offset(140 + i, 72), Offset(140 + i + 22, 50), stripeY);
    }
    canvas.restore();
    canvas.drawRect(
      const Rect.fromLTWH(140, 50, 36, 22),
      Paint()
        ..color = yellow.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // ── Purple tilted square (center 206,63) rotated 15° ──
    canvas.save();
    canvas.translate(206, 63);
    canvas.rotate(15 * math.pi / 180);
    canvas.drawRect(
      const Rect.fromLTWH(-13, -13, 26, 26),
      Paint()..color = purple.withValues(alpha: 0.78),
    );
    canvas.restore();

    // ── Dot grid patch (238,46 50×32) — pink dots ──
    final dotPink = Paint()..color = pink.withValues(alpha: 0.55);
    for (double dy = 4.5; dy < 32; dy += 9) {
      for (double dx = 4.5; dx < 50; dx += 9) {
        canvas.drawCircle(Offset(238 + dx, 46 + dy), 1.8, dotPink);
      }
    }

    // ── Teal double ring (cx=302,cy=68) ──
    canvas.drawCircle(const Offset(302, 68), 20,
        Paint()
          ..color = teal.withValues(alpha: 0.90)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8);
    canvas.drawCircle(const Offset(302, 68), 11,
        Paint()..color = teal.withValues(alpha: 0.28));

    // ── Right edge: teal stripe rect (318,90 40×22) bleeding off x=340 ──
    canvas.save();
    canvas.clipRect(const Rect.fromLTWH(318, 90, 40, 22));
    final stripeT = Paint()
      ..color = teal.withValues(alpha: 0.65)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    for (double i = -22; i <= 62; i += 5) {
      canvas.drawLine(Offset(318 + i, 112), Offset(318 + i + 22, 90), stripeT);
    }
    canvas.restore();
    canvas.drawRect(
      const Rect.fromLTWH(318, 90, 40, 22),
      Paint()
        ..color = teal.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // ── Main squiggle (purple) — period=36, amplitude=14, baseline y=84 ──
    // M0,84 Q18,70 36,84 Q54,98 72,84 ... (peaks up then down alternating)
    final sq1 = Path()..moveTo(0, 84);
    double x1 = 0;
    bool up1 = true;
    while (x1 < 340) {
      final nx = math.min(x1 + 36.0, 340.0);
      sq1.quadraticBezierTo((x1 + nx) / 2, up1 ? 70.0 : 98.0, nx, 84);
      x1 = nx; up1 = !up1;
    }
    canvas.drawPath(sq1, Paint()
      ..color = purple.withValues(alpha: 0.90)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);

    // ── Second squiggle (teal) — period=40, amplitude=12, baseline y=102 ──
    final sq2 = Path()..moveTo(0, 102);
    double x2 = 0;
    bool up2 = true;
    while (x2 < 340) {
      final nx = math.min(x2 + 40.0, 340.0);
      sq2.quadraticBezierTo((x2 + nx) / 2, up2 ? 90.0 : 114.0, nx, 102);
      x2 = nx; up2 = !up2;
    }
    canvas.drawPath(sq2, Paint()
      ..color = teal.withValues(alpha: 0.60)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);

    // ── Zigzag bottom-left (y=103..112) ──
    final zz = Path()..moveTo(20, 112);
    final zzPts = [[36.0,103.0],[52.0,112.0],[68.0,103.0],[84.0,112.0],[100.0,103.0],[116.0,112.0]];
    for (final p in zzPts) { zz.lineTo(p[0], p[1]); }
    canvas.drawPath(zz, Paint()
      ..color = cream.withValues(alpha: 0.45)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke);

    // ── Asterisk yellow at (52,108) ──
    final ast = Paint()
      ..color = yellow.withValues(alpha: 0.90)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(52, 101), const Offset(52, 115), ast);
    canvas.drawLine(const Offset(45, 108), const Offset(59, 108), ast);
    canvas.drawLine(const Offset(47, 103), const Offset(57, 113), ast);
    canvas.drawLine(const Offset(57, 103), const Offset(47, 113), ast);

    // ── Pink dot cluster (center) ──
    canvas.drawCircle(const Offset(152, 108), 5.0,
        Paint()..color = pink.withValues(alpha: 0.85));
    canvas.drawCircle(const Offset(165, 103), 3.5,
        Paint()..color = pink.withValues(alpha: 0.65));
    canvas.drawCircle(const Offset(178, 110), 4.5,
        Paint()..color = pink.withValues(alpha: 0.75));

    // ── Teal stripe rect (210,100 32×18) ──
    canvas.save();
    canvas.clipRect(const Rect.fromLTWH(210, 100, 32, 18));
    for (double i = -18; i <= 50; i += 5) {
      canvas.drawLine(Offset(210 + i, 118), Offset(210 + i + 18, 100), stripeT);
    }
    canvas.restore();
    canvas.drawRect(
      const Rect.fromLTWH(210, 100, 32, 18),
      Paint()
        ..color = teal.withValues(alpha: 0.70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // ── Coral triangle bottom-center ──
    canvas.drawPath(
      Path()..moveTo(210, 116)..lineTo(228, 96)..lineTo(246, 116)..close(),
      Paint()..color = coral.withValues(alpha: 0.70),
    );

    // ── Confetti accents ──
    canvas.drawCircle(const Offset(58, 52), 3.5,
        Paint()..color = coral.withValues(alpha: 0.90));
    canvas.drawCircle(const Offset(70, 47), 2.5,
        Paint()..color = yellow.withValues(alpha: 0.90));
    canvas.drawCircle(const Offset(64, 62), 2.0,
        Paint()..color = teal.withValues(alpha: 0.90));
    canvas.save();
    canvas.translate(169, 54);
    canvas.rotate(22 * math.pi / 180);
    canvas.drawRect(const Rect.fromLTWH(-4.5, -4.5, 9, 9),
        Paint()..color = cream.withValues(alpha: 0.60));
    canvas.restore();
    canvas.drawCircle(const Offset(332, 50), 4.0,
        Paint()..color = purple.withValues(alpha: 0.80));

    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // 3. Swiss Grid — grid lines, two red squares, two red vertical bars with caps.
  //    Matches 3-Barra.dc.html from the design artifact exactly.
  // ---------------------------------------------------------------------------
  void _paintSwissGrid(Canvas canvas) {
    const red  = Color(0xFFC0392B);
    const grid = Color(0xFFD8D5CE);

    final hLine = Paint()
      ..color = grid.withValues(alpha: 0.80)
      ..strokeWidth = 0.75
      ..style = PaintingStyle.stroke;
    final vLine = Paint()
      ..color = grid.withValues(alpha: 0.50)
      ..strokeWidth = 0.75
      ..style = PaintingStyle.stroke;

    // Horizontal lines y=52,68,84,100 span full width; y=116 stops at x=195
    for (final y in [52.0, 68.0, 84.0, 100.0]) {
      canvas.drawLine(Offset(0, y), Offset(340, y), hLine);
    }
    canvas.drawLine(const Offset(0, 116), const Offset(195, 116), hLine);

    // Vertical lines
    canvas.drawLine(const Offset(60, 46), const Offset(60, 128), vLine);
    canvas.drawLine(const Offset(280, 46), const Offset(280, 96), vLine);

    // Red squares
    canvas.drawRect(const Rect.fromLTWH(94, 58, 20, 20), Paint()..color = red);
    canvas.drawRect(const Rect.fromLTWH(236, 58, 20, 20), Paint()..color = red);

    // Red vertical bars (y=52..116, height=64)
    canvas.drawRect(const Rect.fromLTWH(145, 52, 4, 64), Paint()..color = red);
    canvas.drawRect(const Rect.fromLTWH(191, 52, 4, 64), Paint()..color = red);

    // Cap lines at bar tops and bottoms
    final cap = Paint()
      ..color = red
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(141, 52),  const Offset(153, 52),  cap);
    canvas.drawLine(const Offset(141, 116), const Offset(153, 116), cap);
    canvas.drawLine(const Offset(187, 52),  const Offset(199, 52),  cap);
    canvas.drawLine(const Offset(187, 116), const Offset(199, 116), cap);

    // Tick marks
    final tick = Paint()
      ..color = const Color(0xFF111111).withValues(alpha: 0.60)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(40, 60),  const Offset(40, 70),  tick);
    canvas.drawLine(const Offset(40, 104), const Offset(40, 114), tick);
    canvas.drawLine(const Offset(300, 60), const Offset(300, 70), tick);
  }

  // ---------------------------------------------------------------------------
  // 4. Brutalist — stepped polygon, speed lines, diagonal bars, right-panel bars
  // ---------------------------------------------------------------------------
  void _paintBrutalist(Canvas canvas) {
    const bg    = Color(0xFF151515);
    const white = Color(0xFFF5F5F5);
    const red   = Color(0xFFD6432F);

    // Outer safe zone: stepped polygon 0,46→340,46→340,112→180,112→160,126→0,126
    final outerClip = Path()
      ..moveTo(0, 46)..lineTo(340, 46)..lineTo(340, 112)
      ..lineTo(180, 112)..lineTo(160, 126)..lineTo(0, 126)..close();
    canvas.save();
    canvas.clipPath(outerClip);

    // Dark texture fill (slightly smaller, same shape)
    canvas.drawPath(
      Path()
        ..moveTo(20, 46)..lineTo(320, 46)..lineTo(320, 112)
        ..lineTo(180, 112)..lineTo(160, 126)..lineTo(20, 126)..close(),
      Paint()..color = bg.withValues(alpha: 0.70),
    );

    // Inner outline: M26,52 H314 V106 H177 L157,121 H26 Z
    final innerPath = Path()
      ..moveTo(26, 52)..lineTo(314, 52)..lineTo(314, 106)
      ..lineTo(177, 106)..lineTo(157, 121)..lineTo(26, 121)..close();
    canvas.drawPath(
      innerPath,
      Paint()
        ..color = white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // Speed lines clipped to inner outline
    canvas.save();
    canvas.clipPath(innerPath);
    final speedPaint = Paint()
      ..color = white.withValues(alpha: 0.30)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    for (final pts in [
      [40.0, 46.0, -38.0, 126.0],
      [56.0, 46.0, -22.0, 126.0],
      [72.0, 46.0, -6.0,  126.0],
      [88.0, 46.0, 10.0,  126.0],
      [104.0, 46.0, 26.0, 126.0],
      [120.0, 46.0, 42.0, 126.0],
    ]) {
      canvas.drawLine(Offset(pts[0], pts[1]), Offset(pts[2], pts[3]), speedPaint);
    }
    canvas.restore();

    // Red corner mark top-left: M26,60 V52 H44
    canvas.drawPath(
      Path()..moveTo(26, 60)..lineTo(26, 52)..lineTo(44, 52),
      Paint()
        ..color = red.withValues(alpha: 0.85)
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.square,
    );

    // Diagonal bars extended y=46..y=126
    // Red: 152,46  188,46  110,126  74,126
    canvas.drawPath(
      Path()..moveTo(152, 46)..lineTo(188, 46)..lineTo(110, 126)..lineTo(74, 126)..close(),
      Paint()..color = red,
    );
    // White: 182,46  202,46  124,126  104,126
    canvas.drawPath(
      Path()..moveTo(182, 46)..lineTo(202, 46)..lineTo(124, 126)..lineTo(104, 126)..close(),
      Paint()..color = white.withValues(alpha: 0.95),
    );
    // Black separator: (185,46)→(107,126)
    canvas.drawLine(
      const Offset(185, 46), const Offset(107, 126),
      Paint()
        ..color = bg.withValues(alpha: 0.75)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );

    // ── RIGHT PANEL ──

    // Corner bracket top-right: M298,52 H314 V68
    canvas.drawPath(
      Path()..moveTo(298, 52)..lineTo(314, 52)..lineTo(314, 68),
      Paint()
        ..color = white.withValues(alpha: 0.50)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.square,
    );

    // Bar 1: solid white w=70, y=59..66
    canvas.drawRect(
      const Rect.fromLTWH(214, 59, 70, 7),
      Paint()..color = white.withValues(alpha: 0.78),
    );
    // Tick marks inside bar 1
    final tickDark = Paint()
      ..color = bg.withValues(alpha: 0.35)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (final x in [232.0, 250.0, 268.0]) {
      canvas.drawLine(Offset(x, 59), Offset(x, 66), tickDark);
    }

    // Bar 2: diagonal stripes w=48, y=71..77
    canvas.save();
    canvas.clipRect(const Rect.fromLTWH(214, 71, 48, 6));
    final stripePaint = Paint()
      ..color = white.withValues(alpha: 0.65)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    for (double i = -6; i <= 54; i += 5) {
      canvas.drawLine(Offset(214 + i, 77), Offset(214 + i + 6, 71), stripePaint);
    }
    canvas.restore();
    canvas.drawRect(
      const Rect.fromLTWH(214, 71, 48, 6),
      Paint()
        ..color = white.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Bar 3: red w=78, y=82..89
    canvas.drawRect(
      const Rect.fromLTWH(214, 82, 78, 7),
      Paint()..color = red.withValues(alpha: 0.92),
    );
    // Triangle ◀ pointing left from bar 3: (307,80 307,91 297,85)
    canvas.drawPath(
      Path()..moveTo(307, 80)..lineTo(307, 91)..lineTo(297, 85)..close(),
      Paint()..color = red,
    );

    // Bar 4: dot pattern w=56, y=94..99
    canvas.save();
    canvas.clipRect(const Rect.fromLTWH(214, 94, 56, 5));
    final dotPaint = Paint()..color = white.withValues(alpha: 0.60);
    for (double dx = 3; dx < 56; dx += 6) {
      canvas.drawCircle(Offset(214 + dx, 96.5), 1.3, dotPaint);
    }
    canvas.restore();
    canvas.drawRect(
      const Rect.fromLTWH(214, 94, 56, 5),
      Paint()
        ..color = white.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    // Vertical scale ruler at x=308, y=55..102
    canvas.drawLine(
      const Offset(308, 55), const Offset(308, 102),
      Paint()
        ..color = white.withValues(alpha: 0.28)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );
    final tickW = Paint()
      ..color = white.withValues(alpha: 0.45)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (final y in [62.0, 74.0, 96.0]) {
      canvas.drawLine(Offset(304, y), Offset(308, y), tickW);
    }
    canvas.drawLine(
      const Offset(300, 85), const Offset(308, 85),
      Paint()
        ..color = red.withValues(alpha: 0.85)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );

    // Grain dots
    final grain = Paint()..color = white.withValues(alpha: 0.20);
    canvas.drawCircle(const Offset(34, 88), 1.4, grain);
    canvas.drawCircle(const Offset(46, 118), 1.2, grain);
    canvas.drawCircle(const Offset(200, 106), 1.4, grain);

    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // 5. Art Deco — Matches 5-Split.dc.html reference design:
  //    Zones A/G (semicircle fans), B/F (column clusters), C/E (horizontal
  //    fill lines), D (nested concentric arches top+bottom), center accents,
  //    corner L-ticks, frame rects, and diamond lozenge border strips.
  // ---------------------------------------------------------------------------
  void _paintArtDeco(Canvas canvas) {
    const gold = Color(0xFFE8C547);

    Paint stroke(double w, double a) => Paint()
      ..color = gold.withValues(alpha: a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w;

    // ── Outer frame rect ──
    canvas.drawRect(
      const Rect.fromLTWH(14, 52, 312, 58),
      stroke(0.75, 0.50),
    );
    // ── Inner rect ──
    canvas.drawRect(
      const Rect.fromLTWH(20, 58, 300, 46),
      stroke(0.75, 0.35),
    );

    // ── Corner L-ticks (outside frame corners) ──
    final tick = stroke(1.5, 0.85);
    // top-left
    canvas.drawLine(const Offset(14, 52), const Offset(14, 64), tick);
    canvas.drawLine(const Offset(14, 52), const Offset(26, 52), tick);
    // top-right
    canvas.drawLine(const Offset(326, 52), const Offset(326, 64), tick);
    canvas.drawLine(const Offset(326, 52), const Offset(314, 52), tick);
    // bottom-left
    canvas.drawLine(const Offset(14, 110), const Offset(14, 98), tick);
    canvas.drawLine(const Offset(14, 110), const Offset(26, 110), tick);
    // bottom-right
    canvas.drawLine(const Offset(326, 110), const Offset(326, 98), tick);
    canvas.drawLine(const Offset(326, 110), const Offset(314, 110), tick);

    // ── Zone A (left): semicircle fan at (20,81), r=8..48 step 8, opens right ──
    for (double r = 8; r <= 48; r += 8) {
      canvas.drawArc(
        Rect.fromCenter(center: const Offset(20, 81), width: r * 2, height: r * 2),
        -math.pi / 2, math.pi, false, // right half-circle
        stroke(0.8, 0.75),
      );
    }
    // ── Zone G (right): mirror at (320,81), opens left ──
    for (double r = 8; r <= 48; r += 8) {
      canvas.drawArc(
        Rect.fromCenter(center: const Offset(320, 81), width: r * 2, height: r * 2),
        math.pi / 2, math.pi, false, // left half-circle
        stroke(0.8, 0.75),
      );
    }

    // ── Zone B (left cluster): 5 vertical lines x=74..82, y=61..101 ──
    for (double x = 74; x <= 82; x += 2) {
      canvas.drawLine(Offset(x, 61), Offset(x, 101), stroke(0.85, 0.80));
    }
    // ── Zone F (right cluster): 5 lines x=258..266 ──
    for (double x = 258; x <= 266; x += 2) {
      canvas.drawLine(Offset(x, 61), Offset(x, 101), stroke(0.85, 0.80));
    }

    // ── Zone C/E: dense horizontal fill lines y=61..101, x=91..249 ──
    for (double y = 61; y <= 101; y += 2.5) {
      canvas.drawLine(Offset(91, y), Offset(249, y), stroke(0.6, 0.22));
    }

    // ── Zone D: 5 nested concentric arches ──
    // Top arches bow DOWN from y=58; bottom arches bow UP from y=104.
    // Both sets share the same chord widths (centered at x=170).
    const archWidths  = [158.0, 122.0, 90.0, 60.0, 32.0];
    const archHeights = [32.0,  24.0,  17.0, 11.0, 6.0];
    for (int i = 0; i < 5; i++) {
      final w = archWidths[i];
      final h = archHeights[i];
      // top arch: bows down from y=58
      canvas.drawArc(
        Rect.fromCenter(center: const Offset(170, 58), width: w, height: h),
        0, math.pi, false,
        stroke(0.85, 0.70),
      );
      // bottom arch: bows up from y=104
      canvas.drawArc(
        Rect.fromCenter(center: const Offset(170, 104), width: w, height: h),
        math.pi, math.pi, false,
        stroke(0.85, 0.70),
      );
    }

    // ── Center vertical accents ──
    final thick = stroke(2.0, 0.90);
    final thin  = stroke(0.9, 0.70);
    for (final x in [162.0, 165.0, 175.0, 178.0]) {
      canvas.drawLine(Offset(x, 61), Offset(x, 101), thick);
    }
    for (final x in [158.0, 182.0]) {
      canvas.drawLine(Offset(x, 61), Offset(x, 101), thin);
    }

    // ── Diamond lozenge border strips (filled) ──
    final loz = Paint()..color = gold.withValues(alpha: 0.85);
    const period = 5.0;
    const dr = 2.2; // half-diagonal of each diamond

    void diamonds(double x0, double x1, double cy) {
      for (double x = x0; x < x1; x += period) {
        final cx = x + period / 2;
        canvas.drawPath(
          Path()
            ..moveTo(cx, cy - dr)
            ..lineTo(cx + dr, cy)
            ..lineTo(cx, cy + dr)
            ..lineTo(cx - dr, cy)
            ..close(),
          loz,
        );
      }
    }
    void diamondsV(double y0, double y1, double cx) {
      for (double y = y0; y < y1; y += period) {
        final cy = y + period / 2;
        canvas.drawPath(
          Path()
            ..moveTo(cx, cy - dr)
            ..lineTo(cx + dr, cy)
            ..lineTo(cx, cy + dr)
            ..lineTo(cx - dr, cy)
            ..close(),
          loz,
        );
      }
    }
    diamonds(14, 326, 55.0);  // top strip, center y=55
    diamonds(14, 326, 107.0); // bottom strip, center y=107
    diamondsV(58, 104, 17.0); // left strip, center x=17
    diamondsV(58, 104, 323.0);// right strip, center x=323
  }

  // ---------------------------------------------------------------------------
  // 6. Risograph — two radial-gradient blobs (no blur, no saveLayer)
  // ---------------------------------------------------------------------------
  void _paintRisograph(Canvas canvas) {
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 340, 180),
      Paint()..color = const Color(0xFFFDF6EC),
    );

    // Pink blob (top-left) — expanded to fill corner aggressively
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(30, 20), width: 500, height: 360),
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xAAFF6F91), Color(0x55FF6F91), Color(0x00FF6F91)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCenter(center: const Offset(30, 20), width: 500, height: 360)),
    );

    // Teal blob (bottom-right) — expanded to fill corner aggressively
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(320, 165), width: 500, height: 360),
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xAA00A896), Color(0x5500A896), Color(0x0000A896)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCenter(center: const Offset(320, 165), width: 500, height: 360)),
    );

    // Overlap zone: mix effect where blobs naturally cross in the center
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(175, 95), width: 240, height: 180),
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x4455CCAA), Color(0x1E66BBBB), Color(0x0000A896)],
          stops: [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCenter(center: const Offset(175, 95), width: 240, height: 180)),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. Vaporwave — Matches 7-Troquel.dc.html: stars, sun glow+disc, road
  //    with neon rails, perspective lane markers, fade mask y=80→148.
  // ---------------------------------------------------------------------------
  void _paintVaporwave(Canvas canvas) {
    void poly(List<Offset> pts, Paint p) {
      final path = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (final pt in pts.skip(1)) { path.lineTo(pt.dx, pt.dy); }
      path.close();
      canvas.drawPath(path, p);
    }

    // Stars
    final starPaint = Paint()..color = const Color(0xFFF3E7FF);
    for (final (cx, cy, r) in [
      (34.0, 52.0, 1.0), (66.0, 60.0, 1.0), (24.0, 72.0, 0.8),
      (278.0, 54.0, 1.0), (306.0, 64.0, 0.8), (292.0, 76.0, 1.0),
      (120.0, 50.0, 0.8), (216.0, 50.0, 0.8),
    ]) {
      canvas.drawCircle(Offset(cx, cy), r, starPaint);
    }

    // Sun glow
    canvas.drawCircle(
      const Offset(170, 80), 40,
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(170, 80), 40,
          [const Color(0x59FFB24C), const Color(0x00FFB24C)],
          [0.55, 1.0],
        ),
    );
    // Sun disc
    canvas.drawCircle(
      const Offset(170, 80), 27,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(170, 53), const Offset(170, 107),
          [
            const Color(0xFFFFE99B), const Color(0xFFFFB24C),
            const Color(0xFFFF6FB5), const Color(0xFFC13584),
          ],
          [0.0, 0.45, 0.75, 1.0],
        ),
    );

    // Road layer with fade mask (opaque y=80, transparent y=148)
    // saveLayer + dstIn gradient mask replicates the SVG roadMask.
    canvas.saveLayer(
      const Rect.fromLTWH(60, 80, 220, 100),
      Paint(),
    );

    // Road surface: (158,80 182,80 240,180 100,180)
    poly(
      [
        const Offset(158, 80), const Offset(182, 80),
        const Offset(240, 180), const Offset(100, 180),
      ],
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(170, 80), const Offset(170, 180),
          [const Color(0xFF7A1E8F), const Color(0xFF170A26)],
        ),
    );

    // Left neon glow: (148,80 158,80 100,180 88,180) opacity .15
    poly(
      [const Offset(148, 80), const Offset(158, 80), const Offset(100, 180), const Offset(88, 180)],
      Paint()..color = const Color(0x26FF3EA5), // 0.15 * 255 ≈ 38 = 0x26
    );
    // Left solid edge: (155,80 158,80 100,180 97,180) opacity .9
    poly(
      [const Offset(155, 80), const Offset(158, 80), const Offset(100, 180), const Offset(97, 180)],
      Paint()..color = const Color(0xE6FF3EA5), // 0.9 * 255 ≈ 230 = 0xE6
    );
    // Right neon glow: (182,80 192,80 252,180 240,180) opacity .15
    poly(
      [const Offset(182, 80), const Offset(192, 80), const Offset(252, 180), const Offset(240, 180)],
      Paint()..color = const Color(0x26FF3EA5),
    );
    // Right solid edge: (182,80 185,80 243,180 240,180) opacity .9
    poly(
      [const Offset(182, 80), const Offset(185, 80), const Offset(243, 180), const Offset(240, 180)],
      Paint()..color = const Color(0xE6FF3EA5),
    );

    // Centre lane markers — perspective-corrected dashes
    for (final (x, y, w, h, a) in [
      (168.75, 133.0, 2.5, 4.0, 0.75),
      (169.10, 121.0, 1.8, 3.2, 0.65),
      (169.40, 110.0, 1.2, 2.5, 0.55),
      (169.55, 100.0, 0.9, 2.0, 0.45),
      (169.65,  91.0, 0.7, 1.8, 0.35),
      (169.75,  83.0, 0.5, 1.5, 0.25),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(0.3)),
        Paint()..color = const Color(0xFFDDD8FF).withValues(alpha: a),
      );
    }

    // Apply fade mask: opaque at y=80, fully transparent at y=148
    canvas.drawRect(
      const Rect.fromLTWH(60, 80, 220, 100),
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = ui.Gradient.linear(
          const Offset(0, 80), const Offset(0, 148),
          [Colors.white, Colors.transparent],
        ),
    );
    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // 8. Ukiyo-e — orange sun, dark sea fill, wave horizon stroke
  // ---------------------------------------------------------------------------
  void _paintUkiyoE(Canvas canvas) {
    // Sun glow — concentric circles instead of blur
    for (final (r, a) in [(38.0, 0.12), (32.0, 0.22), (27.0, 0.40)]) {
      canvas.drawCircle(const Offset(272, 82), r,
          Paint()..color = const Color(0xFFE8742C).withValues(alpha: a));
    }
    // Sun disc
    canvas.drawCircle(
      const Offset(272, 82), 20,
      Paint()..color = const Color(0xFFF08A3C),
    );

    // Wave horizon path (mountain silhouette fill)
    final wave = Path()
      ..moveTo(0, 96)..lineTo(28, 90)..lineTo(52, 98)..lineTo(80, 86)
      ..lineTo(104, 94)..lineTo(132, 82)..lineTo(158, 92)..lineTo(188, 80)
      ..lineTo(214, 90)..lineTo(242, 78)..lineTo(268, 88)..lineTo(296, 80)
      ..lineTo(340, 90);
    final sea = Path.from(wave)
      ..lineTo(340, 180)
      ..lineTo(0, 180)
      ..close();
    canvas.drawPath(sea, Paint()..color = const Color(0xFF101B33));

    // Horizon stroke
    canvas.drawPath(
      wave,
      Paint()
        ..color = const Color(0xFFEAF3FA).withValues(alpha: 0.9)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant VoucherPatternPainter oldDelegate) =>
      pattern != oldDelegate.pattern;
}

/// Utility: returns white or black, whichever contrasts better against [bg].
Color legibleForegroundOn(Color bg) =>
    bg.computeLuminance() > 0.35 ? Colors.black : Colors.white;

/// Dashed stroke traced along [voucherOutline], inset from the true edge —
/// reads as a stitched comprobante line rather than a solid border.
class VoucherBorderPainter extends CustomPainter {
  final Color color;
  const VoucherBorderPainter({required this.color});

  static const _inset = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final path = voucherOutline((Offset.zero & size).deflate(_inset));
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
  bool shouldRepaint(covariant VoucherBorderPainter oldDelegate) =>
      color != oldDelegate.color;
}

/// Outline of the notched voucher shape. Used by [VoucherClipper] and
/// [VoucherBorderPainter] so their curvature/notch shape never drifts apart.
Path voucherOutline(
  Rect rect, {
  double radius = 0,
  double notchWidth = 14,
  double notchHeight = 38,
}) {
  final base = Path()
    ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
  final notchCenterY = rect.top + rect.height / 2;
  final notches = Path()
    ..addOval(
      Rect.fromCenter(
        center: Offset(rect.left, notchCenterY),
        width: notchWidth,
        height: notchHeight,
      ),
    )
    ..addOval(
      Rect.fromCenter(
        center: Offset(rect.right, notchCenterY),
        width: notchWidth,
        height: notchHeight,
      ),
    );
  return Path.combine(PathOperation.difference, base, notches);
}

/// Clips a widget to the notched voucher outline.
class VoucherClipper extends CustomClipper<Path> {
  const VoucherClipper();

  @override
  Path getClip(Size size) => voucherOutline(Offset.zero & size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}
