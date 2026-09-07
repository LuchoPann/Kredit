import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Circular amortization-progress indicator, ported from the SVG
/// `.progress-ring` in legacy_pwa/index.html (~L108-123): a track circle plus
/// an arc circle that fills clockwise from the top as [percent] rises.
class ProgressRing extends StatelessWidget {
  final double percent; // 0-100
  final double size;

  const ProgressRing({super.key, required this.percent, this.size = 92});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    // Follows the theme's own text color instead of a hardcoded white, so
    // the percentage stays legible in light mode too (dark text on light
    // backgrounds), not just in the app's original dark-only design.
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF0F172A);
    final target = percent.clamp(0, 100).toDouble();
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: target),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, animated, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _ProgressRingPainter(percent: animated, accent: accent),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${animated.round()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      // Scales down gracefully at compact sizes (e.g. the
                      // dashboard hero uses size: 76) so the number never
                      // crowds the ring's inner radius.
                      fontSize: size >= 88 ? KreditTextSize.title : KreditTextSize.body,
                      color: textColor,
                    ),
                  ),
                  Text(
                    'PAGADO',
                    style: TextStyle(
                      fontSize: KreditTextSize.micro,
                      letterSpacing: 0.5,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double percent;
  final Color accent;

  _ProgressRingPainter({required this.percent, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - 6) / 2;

    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(center, radius, track);

    // Ring gradient follows the user's chosen accent color (legacy CSS
    // .prog-grad-stop-start / .prog-grad-stop-end, both var(--accent-primary)
    // with the end stop at 0.55 opacity — style.css ~L305-317).
    final arc = Paint()
      ..shader = LinearGradient(
        colors: [accent, accent.withValues(alpha: 0.55)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final glow = Paint()
      ..color = accent.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final sweep = 2 * math.pi * (percent / 100);
    if (percent > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweep,
        false,
        glow,
      );
    }
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.percent != percent || oldDelegate.accent != accent;
}
