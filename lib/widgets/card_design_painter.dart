import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// ─── Enum ───────────────────────────────────────────────────────────────────

enum CardDesign {
  y2k,
  swissGrid,
  liquido,
  neoGeo,
  organicModernism,
  cyberpunkMinimal,
  typographic,
  risografia;

  String get label => switch (this) {
        y2k => 'Y2K / Frutiger Aero',
        swissGrid => 'Minimalismo Suizo',
        liquido => 'Líquido',
        neoGeo => 'Neo-Geo',
        organicModernism => 'Organic Modernism',
        cyberpunkMinimal => 'Cyberpunk Minimal',
        typographic => 'Maximalismo Tipográfico',
        risografia => 'Risografía',
      };

  static CardDesign? fromKey(String? k) =>
      k == null ? null : values.where((v) => v.name == k).firstOrNull;

  // Whether this design has a light (cream/white) background
  bool get isLightBackground =>
      this == organicModernism;
}

// ─── Color helpers ───────────────────────────────────────────────────────────

// Approximates CSS color-mix(in srgb, a X%, b): t = fraction of 'a'
Color _mix(Color a, Color b, double t) => Color.lerp(b, a, t.clamp(0, 1))!;

// ─── SVG-space transform helper ──────────────────────────────────────────────
// Maps SVG viewBox 0 0 320 202 onto flutter Size using xMidYMid slice behavior

void _withSvgCanvas(Canvas canvas, Size size, void Function(Canvas c) draw) {
  final scale = size.width / 320.0;
  final svgRenderH = 202.0 * scale;
  final yOffset = (svgRenderH - size.height) / 2.0;
  canvas.save();
  canvas.clipRect(Offset.zero & size);
  canvas.scale(scale, scale);
  canvas.translate(0, -yOffset / scale);
  draw(canvas);
  canvas.restore();
}

// ─── Picture cache ───────────────────────────────────────────────────────────
// Keyed by design+colors+size+isPreview — recorded once, replayed every frame.
// drawPicture skips all Dart computation on subsequent renders.
final _pictureCache = <String, ui.Picture>{};

/// Pre-warms the Picture cache for a list of (design, c1, c2, c3) combos.
/// Call from splash after credits load so the list screen's first frame is free.
void prewarmDesignCache(
  List<({CardDesign design, Color c1, Color c2, Color c3})> entries,
  Size size,
) {
  for (final e in entries) {
    for (final preview in [false, true]) {
      final key =
          '${e.design.name}|${e.c1.toARGB32()}|${e.c2.toARGB32()}|${e.c3.toARGB32()}'
          '|${size.width.round()}x${size.height.round()}|$preview';
      if (_pictureCache.containsKey(key)) continue;
      final recorder = ui.PictureRecorder();
      CardDesignPainter(
        design: e.design,
        c1: e.c1,
        c2: e.c2,
        c3: e.c3,
        isPreview: preview,
      )._doPaint(Canvas(recorder), size);
      _pictureCache[key] = recorder.endRecording();
    }
  }
}

// ─── Master painter dispatcher ───────────────────────────────────────────────

class CardDesignPainter extends CustomPainter {
  final CardDesign design;
  final Color c1;
  final Color c2;
  final Color c3;
  // En modo preview (miniaturas del picker) se omiten los MaskFilter.blur
  // más costosos para que los 9 items del grid no bloqueen el UI thread.
  final bool isPreview;

  const CardDesignPainter({
    required this.design,
    required this.c1,
    required this.c2,
    required this.c3,
    this.isPreview = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final key =
        '${design.name}|${c1.toARGB32()}|${c2.toARGB32()}|${c3.toARGB32()}'
        '|${size.width.round()}x${size.height.round()}|$isPreview';
    var picture = _pictureCache[key];
    if (picture == null) {
      final recorder = ui.PictureRecorder();
      _doPaint(Canvas(recorder), size);
      picture = recorder.endRecording();
      _pictureCache[key] = picture;
    }
    canvas.drawPicture(picture);
  }

  void _doPaint(Canvas canvas, Size size) {
    switch (design) {
      case CardDesign.y2k:
        _paintY2k(canvas, size, c1, c2, c3, isPreview: isPreview);
      case CardDesign.swissGrid:
        _paintSwissGrid(canvas, size, c1, c2, c3);
      case CardDesign.liquido:
        _paintLiquido(canvas, size, c1, c2, c3);
      case CardDesign.neoGeo:
        _paintNeoGeo(canvas, size, c1, c2, c3);
      case CardDesign.organicModernism:
        _paintOrganic(canvas, size, c1, c2, c3);
      case CardDesign.cyberpunkMinimal:
        _paintCyberpunk(canvas, size, c1, c2, c3, isPreview: isPreview);
      case CardDesign.typographic:
        _paintTypographic(canvas, size, c1, c2, c3);
      case CardDesign.risografia:
        _paintRisografia(canvas, size, c1, c2, c3);
    }
  }

  @override
  bool shouldRepaint(CardDesignPainter old) =>
      design != old.design ||
      c1 != old.c1 ||
      c2 != old.c2 ||
      c3 != old.c3 ||
      isPreview != old.isPreview;
}

// ═══ D1 · Y2K / Frutiger Aero ════════════════════════════════════════════════
// Radial auroral gradient · glassy orbs · grid lines · sparkles

void _paintY2k(Canvas canvas, Size size, Color c1, Color c2, Color c3, {bool isPreview = false}) {
  // Base radial gradient (ellipse at 18% 38%)
  final baseGrad = RadialGradient(
    center: Alignment(-0.64, -0.24), // 18% → -0.64, 38% → -0.24 in alignment space
    radius: 1.2,
    colors: [
      _mix(c1, const Color(0xFF4488FF), 0.60),
      _mix(c1, Colors.black, 0.80),
      _mix(c3, const Color(0xFF000088), 0.90),
    ],
    stops: const [0.0, 0.42, 1.0],
  );
  canvas.drawRect(
    Offset.zero & size,
    Paint()..shader = baseGrad.createShader(Offset.zero & size),
  );

  _withSvgCanvas(canvas, size, (c) {
    // Soft aura overlay
    c.drawOval(
      const Rect.fromLTWH(50, 27, 220, 136),
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );

    // Glassy orb large (92,76,r=58)
    final orbPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.38, -0.62),
        radius: 1.0,
        colors: [
          Color(0xE0FFFFFF),
          Color(0x84FFFFFF),
          Color(0x1AFFFFFF),
          Color(0x05FFFFFF),
        ],
        stops: [0.0, 0.22, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: const Offset(92, 76), radius: 58));
    c.drawCircle(const Offset(92, 76), 58, orbPaint..style = PaintingStyle.fill);

    // Specular highlight on large orb
    c.drawOval(Rect.fromCenter(center: const Offset(76, 56), width: 44, height: 28),
        Paint()..color = Colors.white.withValues(alpha: 0.40));
    c.drawOval(Rect.fromCenter(center: const Offset(72, 52), width: 16, height: 10),
        Paint()..color = Colors.white.withValues(alpha: 0.85));

    // Medium orb (238,62,r=38)
    final orb2Paint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.38, -0.62),
        radius: 1.0,
        colors: [Color(0xD0FFFFFF), Color(0x45FFFFFF), Color(0x08FFFFFF)],
        stops: [0.0, 0.22, 1.0],
      ).createShader(Rect.fromCircle(center: const Offset(238, 62), radius: 38));
    c.drawCircle(const Offset(238, 62), 38, orb2Paint..style = PaintingStyle.fill);
    // Medium orb specular
    c.drawOval(Rect.fromCenter(center: const Offset(226, 48), width: 28, height: 18),
        Paint()..color = Colors.white.withValues(alpha: 0.38));
    c.drawOval(Rect.fromCenter(center: const Offset(224, 45), width: 10, height: 7),
        Paint()..color = Colors.white.withValues(alpha: 0.72));

    // Small orb (284,108,r=22)
    c.drawCircle(const Offset(284, 108), 22,
        Paint()..color = Colors.white.withValues(alpha: 0.28));

    // Mini orb (168,38,r=12)
    c.drawCircle(const Offset(168, 38), 12,
        Paint()..color = Colors.white.withValues(alpha: 0.20));

    // Horizontal grid lines (Y2K cue)
    final linePaint = Paint()
      ..color = _mix(c1, Colors.white, 0.48).withValues(alpha: 0.22)
      ..strokeWidth = 0.4;
    for (final y in [22.0, 40.0, 58.0, 76.0, 94.0, 112.0]) {
      c.drawLine(Offset(0, y), Offset(320, y), linePaint);
    }

    // 4-point star sparkles
    final starPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;
    void star(double x, double y, double r) {
      c.drawLine(Offset(x - r, y), Offset(x + r, y), starPaint);
      c.drawLine(Offset(x, y - r), Offset(x, y + r), starPaint);
    }

    star(296, 34, 6);
    star(36, 116, 4);
    star(306, 94, 4);
    // Cross decoration
    star(52, 30, 6);

    // Light dots
    c.drawCircle(const Offset(198, 20), 2, Paint()..color = Colors.white.withValues(alpha: 0.70));
    c.drawCircle(const Offset(148, 112), 1.5, Paint()..color = Colors.white.withValues(alpha: 0.35));
    c.drawCircle(const Offset(316, 58), 1.5, Paint()..color = Colors.white.withValues(alpha: 0.70));
  });
}

// ═══ D2 · Minimalismo Suizo ══════════════════════════════════════════════════
// 4-quadrant composition · large ring at intersection · brand-adaptive

void _paintSwissGrid(Canvas canvas, Size size, Color c1, Color c2, Color c3) {
  final dark = _mix(c3, Colors.black, 0.96);
  final accent = _mix(c1, Colors.black, 0.92);
  const white = Color(0xF7FFFFFF);

  _withSvgCanvas(canvas, size, (c) {
    // Clip to upper 128px (design zone)
    c.save();
    c.clipRect(const Rect.fromLTWH(0, 0, 320, 128));

    // 4 quadrant backgrounds
    c.drawRect(const Rect.fromLTWH(0, 0, 175, 68), Paint()..color = dark);         // TL dark
    c.drawRect(const Rect.fromLTWH(175, 0, 145, 68), Paint()..color = white);      // TR white
    c.drawRect(const Rect.fromLTWH(0, 68, 175, 60), Paint()..color = accent);      // BL c1
    c.drawRect(const Rect.fromLTWH(175, 68, 145, 60), Paint()..color = dark);      // BR dark

    // Large ring (r=60 outer, r=32 inner) centered at (175, 68)
    const cx = 175.0;
    const cy = 68.0;
    const rOuter = 60.0;
    const rInner = 32.0;

    // Each quadrant sees a different color face
    void drawCircleClipped(double x, double y, double r, Color fill, Rect clip) {
      c.save();
      c.clipRect(clip);
      c.drawCircle(Offset(x, y), r, Paint()..color = fill);
      c.restore();
    }

    // Outer ring per quadrant: TL=white, TR=dark, BL=white, BR=white
    drawCircleClipped(cx, cy, rOuter, white, const Rect.fromLTWH(0, 0, 175, 68));
    drawCircleClipped(cx, cy, rOuter, dark, const Rect.fromLTWH(175, 0, 145, 68));
    drawCircleClipped(cx, cy, rOuter, white, const Rect.fromLTWH(0, 68, 175, 60));
    drawCircleClipped(cx, cy, rOuter, white, const Rect.fromLTWH(175, 68, 145, 60));

    // Inner counter (hole): TL=dark, TR=white, BL=c1, BR=dark
    drawCircleClipped(cx, cy, rInner, dark, const Rect.fromLTWH(0, 0, 175, 68));
    drawCircleClipped(cx, cy, rInner, white, const Rect.fromLTWH(175, 0, 145, 68));
    drawCircleClipped(cx, cy, rInner, accent, const Rect.fromLTWH(0, 68, 175, 60));
    drawCircleClipped(cx, cy, rInner, dark, const Rect.fromLTWH(175, 68, 145, 60));

    c.restore();

    // Fill below design zone (text area)
    c.drawRect(const Rect.fromLTWH(0, 128, 320, 74), Paint()..color = dark);
  });
}

// ═══ D3 · Líquido ════════════════════════════════════════════════════════════
// Dark base · 4 flowing wave bands with vivid brand mixes · volumetric

void _paintLiquido(Canvas canvas, Size size, Color c1, Color c2, Color c3) {
  // Base
  canvas.drawRect(
      Offset.zero & size,
      Paint()..color = _mix(c3, const Color(0xFF04000E), 0.85));

  _withSvgCanvas(canvas, size, (c) {
    final wa = _mix(c1, const Color(0xFFCC00FF), 0.72); // onda front
    final wb = _mix(c2, const Color(0xFF6600FF), 0.68); // onda mid
    final wc = _mix(c1, const Color(0xFFFF0088), 0.50); // onda accent
    final wd = _mix(c2, const Color(0xFF0022FF), 0.55); // onda back

    // Ambient glow — layered alpha simulates blur without offscreen pass
    for (final (alpha, inflate) in [(0.08, 12.0), (0.18, 6.0), (0.30, 0.0)]) {
      c.drawOval(
        Rect.fromCenter(center: const Offset(60, 120), width: 260, height: 200).inflate(inflate),
        Paint()..color = wd.withValues(alpha: alpha),
      );
    }
    for (final (alpha, inflate) in [(0.06, 10.0), (0.14, 5.0), (0.22, 0.0)]) {
      c.drawOval(
        Rect.fromCenter(center: const Offset(240, 60), width: 240, height: 180).inflate(inflate),
        Paint()..color = wa.withValues(alpha: alpha),
      );
    }

    // Wave 1 — back (wd)
    final w1 = Path()
      ..moveTo(-30, 202)
      ..cubicTo(10, 165, 50, 148, 90, 130)
      ..cubicTo(130, 112, 148, 88, 140, 60)
      ..cubicTo(132, 32, 100, 18, 110, -10)
      ..lineTo(160, -10)
      ..cubicTo(148, 18, 178, 42, 186, 70)
      ..cubicTo(194, 98, 178, 122, 138, 142)
      ..cubicTo(98, 162, 60, 178, 30, 202)
      ..close();
    c.drawPath(w1, Paint()..color = wd);

    // Wave 2 — mid (wb)
    final w2 = Path()
      ..moveTo(-30, 90)
      ..cubicTo(20, 68, 80, 62, 140, 78)
      ..cubicTo(185, 90, 220, 75, 265, 50)
      ..cubicTo(295, 32, 318, 16, 340, 8)
      ..lineTo(340, 50)
      ..cubicTo(318, 58, 292, 76, 258, 98)
      ..cubicTo(215, 124, 178, 140, 132, 126)
      ..cubicTo(86, 112, 32, 118, -30, 138)
      ..close();
    c.drawPath(w2, Paint()..color = wb);

    // Wave 3 — front (wa)
    final w3 = Path()
      ..moveTo(-30, 50)
      ..cubicTo(30, 28, 90, 20, 148, 36)
      ..cubicTo(198, 50, 232, 42, 270, 22)
      ..cubicTo(296, 8, 318, -2, 340, -6)
      ..lineTo(340, 28)
      ..cubicTo(316, 32, 292, 44, 264, 60)
      ..cubicTo(224, 80, 188, 90, 142, 78)
      ..cubicTo(96, 66, 40, 72, -30, 90)
      ..close();
    c.drawPath(w3, Paint()..color = wa);

    // Wave 4 — accent ribbon top-right (wc)
    final w4 = Path()
      ..moveTo(140, -10)
      ..cubicTo(185, 2, 230, -4, 278, -14)
      ..cubicTo(305, -20, 326, -14, 340, -10)
      ..lineTo(340, 18)
      ..cubicTo(324, 14, 302, 8, 274, 14)
      ..cubicTo(226, 24, 180, 32, 135, 20)
      ..close();
    c.drawPath(w4, Paint()..color = wc.withValues(alpha: 0.82));

    // Edge highlights (thin bright paths along top of waves)
    final hPaint = Paint()
      ..color = _mix(c1, Colors.white, 0.40).withValues(alpha: 0.55)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final h1 = Path()
      ..moveTo(-30, 50)
      ..cubicTo(30, 28, 90, 20, 148, 36)
      ..cubicTo(200, 50, 250, 32, 300, 12);
    c.drawPath(h1, hPaint);

    final hPaint2 = Paint()
      ..color = _mix(c1, Colors.white, 0.28).withValues(alpha: 0.45)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final h2 = Path()
      ..moveTo(-30, 90)
      ..cubicTo(20, 68, 80, 62, 140, 78)
      ..cubicTo(200, 94, 250, 68, 300, 40);
    c.drawPath(h2, hPaint2);
  });
}

// ═══ D4 · Neo-Geo ════════════════════════════════════════════════════════════
// Light cream · overlapping triangles · hatch texture · diagonal accents

void _paintNeoGeo(Canvas canvas, Size size, Color c1, Color c2, Color c3) {
  // Light cream base
  canvas.drawRect(
      Offset.zero & size,
      Paint()..color = _mix(c1, const Color(0xFFEEE8E0), 0.07));

  _withSvgCanvas(canvas, size, (c) {
    final gd = _mix(c2, c3, 0.80);
    final gm = _mix(c2, c3, 0.50).withValues(alpha: 0.88);
    final ga = c1;
    final ghColor = _mix(c2, c3, 0.65);
    final goColor = _mix(c2, c3, 0.75);
    final gxColor = _mix(c1, c2, 0.55);

    // Large dark triangle (bottom-left)
    final tri1 = Path()..addPolygon(const [Offset(0, 0), Offset(210, 0), Offset(90, 135)], true);
    c.drawPath(tri1, Paint()..color = gd);

    // Mid triangle overlapping
    final tri2 = Path()
      ..addPolygon(const [Offset(0, 38), Offset(155, 0), Offset(77, 132), Offset(39, 132)], true);
    c.drawPath(tri2, Paint()..color = gm);

    // Hatch pattern triangle (simulated with thin diagonal lines)
    final hatchTri = Path()
      ..addPolygon(const [Offset(110, 30), Offset(285, 0), Offset(220, 132)], true);
    c.save();
    c.clipPath(hatchTri);
    final hatchLinePaint = Paint()
      ..color = ghColor.withValues(alpha: 0.45)
      ..strokeWidth = 0.9;
    for (double x = -200; x < 500; x += 5.5) {
      c.drawLine(Offset(x, 0), Offset(x + 200, 280), hatchLinePaint);
    }
    c.restore();
    c.drawPath(hatchTri, Paint()..color = goColor..style = PaintingStyle.stroke..strokeWidth = 1.1);

    // Accent triangle top-right (c1)
    final tri3 = Path()
      ..addPolygon(const [Offset(188, 68), Offset(320, 0), Offset(320, 128)], true);
    c.drawPath(tri3, Paint()..color = ga);

    // Small hatch triangle bottom-left
    final smallHatch = Path()
      ..addPolygon(const [Offset(45, 98), Offset(84, 132), Offset(22, 132)], true);
    c.save();
    c.clipPath(smallHatch);
    final smallHatchPaint = Paint()
      ..color = ghColor.withValues(alpha: 0.50)
      ..strokeWidth = 0.65;
    for (double x = -100; x < 200; x += 4) {
      c.drawLine(Offset(x, 0), Offset(x + 200, 280), smallHatchPaint);
    }
    c.restore();
    c.drawPath(smallHatch, Paint()..color = goColor..style = PaintingStyle.stroke..strokeWidth = 1.1);

    // Small dark corner triangle
    final tri4 = Path()
      ..addPolygon(const [Offset(262, 88), Offset(320, 26), Offset(320, 98)], true);
    c.drawPath(tri4, Paint()..color = gd);

    // Outline triangle
    final triOut = Path()
      ..addPolygon(const [Offset(148, 0), Offset(265, 72), Offset(68, 88)], false);
    c.drawPath(triOut, Paint()..color = goColor..style = PaintingStyle.stroke..strokeWidth = 1.1);

    // Diagonal accent lines
    c.drawLine(const Offset(113, 132), const Offset(320, 0),
        Paint()..color = gxColor..strokeWidth = 0.9);
    c.drawLine(const Offset(0, 0), const Offset(207, 132),
        Paint()..color = gxColor.withValues(alpha: 0.35)..strokeWidth = 0.7);
  });
}

// ═══ D5 · Organic Modernism ══════════════════════════════════════════════════
// Cream base · overlapping organic blobs · earthy brand-adaptive palette

void _paintOrganic(Canvas canvas, Size size, Color c1, Color c2, Color c3) {
  // Cream base
  canvas.drawRect(
      Offset.zero & size,
      Paint()..color = _mix(c1, const Color(0xFFECE6DC), 0.05));

  _withSvgCanvas(canvas, size, (c) {
    final ba = _mix(c1, const Color(0xFFBEB5A5), 0.40).withValues(alpha: 0.82);
    final bb = _mix(c2, const Color(0xFF9A9085), 0.48).withValues(alpha: 0.75);
    final bc = _mix(c1, const Color(0xFFB06858), 0.30).withValues(alpha: 0.70);
    final bd = _mix(c2, const Color(0xFFA8B098), 0.25).withValues(alpha: 0.58);
    final be = _mix(c1, const Color(0xFFC0B8A8), 0.18).withValues(alpha: 0.50);
    final bf = _mix(c2, c3, 0.55).withValues(alpha: 0.38);

    // Circle blob bd
    c.drawCircle(const Offset(70, 74), 64, Paint()..color = bd);

    // Blob ba
    final bla = Path()
      ..moveTo(178, -22)
      ..cubicTo(248, -12, 368, 28, 345, 105)
      ..cubicTo(322, 172, 238, 192, 196, 160)
      ..cubicTo(158, 130, 164, 78, 178, -22)
      ..close();
    c.drawPath(bla, Paint()..color = ba);

    // Blob bb
    final blb = Path()
      ..moveTo(-22, 112)
      ..cubicTo(18, 90, 82, 100, 114, 148)
      ..cubicTo(138, 184, 112, 218, 58, 214)
      ..cubicTo(8, 208, -28, 168, -22, 112)
      ..close();
    c.drawPath(blb, Paint()..color = bb);

    // Blob bc
    final blc = Path()
      ..moveTo(142, 158)
      ..cubicTo(168, 142, 214, 150, 224, 178)
      ..cubicTo(232, 200, 202, 218, 168, 214)
      ..cubicTo(138, 208, 128, 172, 142, 158)
      ..close();
    c.drawPath(blc, Paint()..color = bc);

    // Blob be
    final ble = Path()
      ..moveTo(256, 88)
      ..cubicTo(278, 78, 312, 86, 316, 108)
      ..cubicTo(320, 128, 302, 145, 280, 142)
      ..cubicTo(258, 139, 244, 100, 256, 88)
      ..close();
    c.drawPath(ble, Paint()..color = be);

    // Blob bf
    final blf = Path()
      ..moveTo(238, 30)
      ..cubicTo(256, 16, 304, 22, 310, 46)
      ..cubicTo(316, 66, 292, 82, 268, 76)
      ..cubicTo(246, 70, 224, 42, 238, 30)
      ..close();
    c.drawPath(blf, Paint()..color = bf);

    // Flow lines
    final flPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fl1 = Path()
      ..moveTo(102, 38)
      ..cubicTo(165, 58, 182, 122, 152, 184);
    c.drawPath(fl1, flPaint..color = Colors.white.withValues(alpha: 0.35));

    final fl2 = Path()
      ..moveTo(28, 98)
      ..cubicTo(72, 82, 134, 94, 168, 138);
    c.drawPath(fl2, flPaint..color = Colors.white.withValues(alpha: 0.25));
  });
}

// ═══ D6 · Cyberpunk Minimal ══════════════════════════════════════════════════
// Dark angular panels · neon diagonal lines with brand gradient glow

void _paintCyberpunk(Canvas canvas, Size size, Color c1, Color c2, Color c3, {bool isPreview = false}) {
  // Dark base gradient
  final baseGrad = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [
      _mix(c2, const Color(0xFF242424), 0.14),
      _mix(c2, const Color(0xFF141414), 0.07),
      const Color(0xFF080808),
    ],
    stops: const [0.0, 0.48, 1.0],
  );
  canvas.drawRect(
      Offset.zero & size, Paint()..shader = baseGrad.createShader(Offset.zero & size));

  _withSvgCanvas(canvas, size, (c) {
    final p1 = _mix(c2, const Color(0xFF202020), 0.18);
    final p2 = _mix(c2, const Color(0xFF1A1A1A), 0.11);
    final p3 = _mix(c2, const Color(0xFF161616), 0.07);

    c.save();
    c.clipRect(const Rect.fromLTWH(0, 0, 320, 128));

    // Angular dark panels (between diagonal lines at ~40°)
    // L1: (48,128)→(200,0)  L2: (108,128)→(260,0)  L3: (164,128)→(316,0)
    final band1 = Path()
      ..addPolygon(const [Offset(48, 128), Offset(108, 128), Offset(260, 0), Offset(200, 0)], true);
    c.drawPath(band1, Paint()..color = p1);

    final band2 = Path()
      ..addPolygon(const [Offset(108, 128), Offset(164, 128), Offset(316, 0), Offset(260, 0)], true);
    c.drawPath(band2, Paint()..color = p2);

    final band3 = Path()
      ..addPolygon(const [Offset(164, 128), Offset(320, 128), Offset(320, 0), Offset(316, 0)], true);
    c.drawPath(band3, Paint()..color = p3);

    final bandLeft = Path()
      ..addPolygon(const [Offset(-10, 128), Offset(48, 128), Offset(200, 0), Offset(-10, 0)], true);
    c.drawPath(bandLeft, Paint()..color = p3.withValues(alpha: 0.6 * p3.a));

    // Neon lines: L1, L2, L3 with glow simulation
    // Neon gradient (shared direction)
    final neonGrad = LinearGradient(
      begin: const Alignment(-1.0, 1.0),
      end: const Alignment(1.0, -1.0),
      colors: [
        c1.withValues(alpha: 0.02),
        c1.withValues(alpha: 0.82),
        c1,
        _mix(c1, Colors.white, 0.55).withValues(alpha: 0.95),
        c2.withValues(alpha: 0.78),
        c2.withValues(alpha: 0.04),
      ],
      stops: const [0.0, 0.18, 0.42, 0.62, 0.82, 1.0],
    );
    final glowGrad = LinearGradient(
      begin: const Alignment(-1.0, 1.0),
      end: const Alignment(1.0, -1.0),
      colors: [
        c1.withValues(alpha: 0.0),
        c1.withValues(alpha: 0.48),
        c1.withValues(alpha: 0.62),
        c2.withValues(alpha: 0.45),
        c2.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.22, 0.50, 0.78, 1.0],
    );

    const neonRect = Rect.fromLTWH(0, 0, 320, 128);

    void neonLine(Offset p1o, Offset p2o,
        {double glowW1 = 18, double glowW2 = 8, double coreW = 1.5, double alpha = 1.0}) {
      // Neon glow: 3 concentric strokes (wide faint → narrow bright), no blur
      c.drawLine(p1o, p2o,
          Paint()
            ..shader = glowGrad.createShader(neonRect)
            ..strokeWidth = glowW1
            ..style = PaintingStyle.stroke
            ..color = Colors.white.withValues(alpha: 0.15 * alpha));
      c.drawLine(p1o, p2o,
          Paint()
            ..shader = glowGrad.createShader(neonRect)
            ..strokeWidth = glowW2
            ..style = PaintingStyle.stroke
            ..color = Colors.white.withValues(alpha: 0.30 * alpha));
      c.drawLine(p1o, p2o,
          Paint()
            ..shader = neonGrad.createShader(neonRect)
            ..strokeWidth = isPreview ? coreW * 2 : coreW
            ..style = PaintingStyle.stroke);
    }

    neonLine(const Offset(48, 128), const Offset(200, 0));
    neonLine(const Offset(108, 128), const Offset(260, 0),
        glowW1: 14, glowW2: 6, coreW: 1.3, alpha: 0.45);
    neonLine(const Offset(164, 128), const Offset(316, 0),
        glowW1: 10, glowW2: 5, coreW: 1.0, alpha: 0.35);

    c.restore();
  });
}

// ═══ D7 · Maximalismo Tipográfico ════════════════════════════════════════════
// Dense color blocks · giant letters as texture · urban aesthetic

void _paintTypographic(Canvas canvas, Size size, Color c1, Color c2, Color c3) {
  _withSvgCanvas(canvas, size, (c) {
    final ba7 = c1;
    final bb7 = _mix(c2, Colors.black, 0.88);
    final bc7 = _mix(c1, Colors.white, 0.38);
    final bd7 = _mix(c1, c3, 0.18);
    const bs7 = Color(0x12FFFFFF);

    // Solid base (c3)
    c.drawRect(const Rect.fromLTWH(0, 0, 320, 202), Paint()..color = c3);

    // Upper color blocks (y=0–118)
    c.drawRect(const Rect.fromLTWH(0, 0, 168, 118), Paint()..color = ba7);    // TL c1
    c.drawRect(const Rect.fromLTWH(168, 0, 152, 118), Paint()..color = bb7);  // TR c2 dark

    // Lower solid (y=118–202)
    c.drawRect(const Rect.fromLTWH(0, 118, 320, 84), Paint()..color = bd7);

    // Accent stripe at divider
    c.drawRect(const Rect.fromLTWH(0, 114, 320, 4), Paint()..color = ba7.withValues(alpha: 0.55));

    // Stripe block top-right
    c.drawRect(const Rect.fromLTWH(195, 56, 125, 62), Paint()..color = bs7);

    // Divider line between upper blocks
    c.drawLine(const Offset(168, 0), const Offset(168, 118),
        Paint()..color = Colors.black.withValues(alpha: 0.18)..strokeWidth = 2);

    // Giant letters clipped to upper zone (y≤118)
    c.save();
    c.clipRect(const Rect.fromLTWH(0, 0, 320, 118));

    final darkFill = _mix(c3, Colors.black, 0.95);

    // K — large rotated left
    _drawBigLetter(c, 'K', const Offset(-18, 118), 200,
        fill: darkFill, rotation: -6 * math.pi / 180, rotCenter: const Offset(80, 60));

    // R — white right side
    _drawBigLetter(c, 'R', const Offset(118, 92), 132,
        fill: Colors.white.withValues(alpha: 0.85), rotation: 5 * math.pi / 180, rotCenter: const Offset(200, 36));

    // $ — accent smaller
    _drawBigLetter(c, r'$', const Offset(48, 116), 90,
        fill: bc7.withValues(alpha: 0.42), rotation: -4 * math.pi / 180);

    c.restore();
  });
}

// Cache de TextPainters — evita layout() en cada paint() call del D7.
final _bigLetterCache = <String, TextPainter>{};

void _drawBigLetter(Canvas canvas, String letter, Offset pos, double fontSize,
    {required Color fill,
    double rotation = 0,
    Offset rotCenter = Offset.zero}) {
  canvas.save();
  if (rotation != 0) {
    canvas.translate(rotCenter.dx, rotCenter.dy);
    canvas.rotate(rotation);
    canvas.translate(-rotCenter.dx, -rotCenter.dy);
  }
  final key = '$letter|$fontSize|${fill.toARGB32()}';
  final tp = _bigLetterCache.putIfAbsent(key, () => TextPainter(
    text: TextSpan(
      text: letter,
      style: TextStyle(
        color: fill,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: -fontSize * 0.04,
        height: 1.0,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout());
  // SVG text y is baseline; TextPainter paints from top-left
  tp.paint(canvas, Offset(pos.dx, pos.dy - fontSize * 0.85));
  canvas.restore();
}

// ═══ D8 · Risografía ════════════════════════════════════════════════════════
// Editorial blocks · registration marks · halftone dots · brand-adaptive

void _paintRisografia(Canvas canvas, Size size, Color c1, Color c2, Color c3) {
  canvas.drawRect(
      Offset.zero & size,
      Paint()..color = _mix(c3, const Color(0xFF0E0A04), 0.80));

  _withSvgCanvas(canvas, size, (c) {
    final gbk = _mix(c1, const Color(0x2EFFFFFF), 0.55).withValues(alpha: 0.62);
    final gba = _mix(c1, Colors.white, 0.85).withValues(alpha: 0.48);
    final ht = _mix(c1, Colors.white, 0.50).withValues(alpha: 0.52);

    // Ink blocks
    c.drawRect(const Rect.fromLTWH(0, 0, 320, 32), Paint()..color = gbk);    // top strip
    c.drawRect(const Rect.fromLTWH(0, 0, 32, 116), Paint()..color = gbk);    // left column
    c.drawRect(const Rect.fromLTWH(240, 0, 80, 32), Paint()..color = gba);   // accent block top-right
    c.drawRect(const Rect.fromLTWH(240, 32, 80, 52), Paint()..color = gbk);  // right block mid

    // Editorial separator line
    c.drawRect(const Rect.fromLTWH(32, 84, 208, 3), Paint()..color = gbk);

    // Registration marks (cross marks)
    final regPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.42)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    void regMark(double x, double y) {
      c.drawLine(Offset(x - 12, y), Offset(x + 12, y), regPaint);
      c.drawLine(Offset(x, y - 12), Offset(x, y + 12), regPaint);
    }

    regMark(300, 18);
    regMark(300, 102);

    // Halftone dots (graduated sizes, bottom of design zone)
    final htPaint = Paint()..color = ht;
    final halftoneData = [
      // (cx, cy, r)
      (188.0, 116.0, 4.0), (200.0, 116.0, 3.8), (212.0, 116.0, 3.5),
      (182.0, 104.0, 3.5), (194.0, 104.0, 3.2), (206.0, 104.0, 2.8), (218.0, 104.0, 2.5),
      (176.0, 93.0, 2.8),  (188.0, 93.0, 2.5),  (200.0, 93.0, 2.2),  (212.0, 93.0, 1.8),
      (176.0, 82.0, 2.2),  (188.0, 82.0, 2.0),  (200.0, 82.0, 1.5),
      (176.0, 72.0, 1.5),  (188.0, 72.0, 1.2),
    ];
    for (final (cx, cy, r) in halftoneData) {
      c.drawCircle(Offset(cx, cy), r, htPaint);
    }

    // Editorial dotted line
    const dash = 4.0;
    const gap = 4.0;
    double x = 32;
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.30)
      ..strokeWidth = 1.0;
    while (x < 240) {
      c.drawLine(Offset(x, 116), Offset(math.min(x + dash, 240), 116), dashPaint);
      x += dash + gap;
    }
  });
}
