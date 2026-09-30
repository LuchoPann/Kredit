import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../voucher_pattern.dart';

/// Lets the user pick which of the 8 [VoucherPattern] art styles a voucher
/// uses, showing a real miniature of each one (the exact voucher shape,
/// this specific [accent] color, and the style's own self-colored artwork)
/// rather than a plain swatch or text list — tapping a preview calls
/// [onSelect] immediately. Parameterized (no provider reads) so it can back
/// either the global default (Ajustes) or one specific cupo's own pattern.
class VoucherPatternPicker extends StatelessWidget {
  final VoucherPattern selected;
  final ValueChanged<VoucherPattern> onSelect;
  final String title;

  const VoucherPatternPicker({
    super.key,
    required this.selected,
    required this.onSelect,
    this.title = 'Diseño de voucher',
    @Deprecated('No longer used — each pattern has its own fixed palette')
    Color accent = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        SizedBox(
          height: 380,
          child: GridView.builder(
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 10,
              childAspectRatio: 1.35,
            ),
            itemCount: VoucherPattern.values.length,
            itemBuilder: (context, index) {
              final pattern = VoucherPattern.values[index];
              final isSelected = pattern == selected;
              return RepaintBoundary(
                child: GestureDetector(
                  onTap: () => onSelect(pattern),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: 1.9,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ClipPath(
                                clipper: const VoucherClipper(),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: DecoratedBox(
                                        decoration: pattern.backgroundDecoration,
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: VoucherPatternPainter(pattern: pattern),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isSelected)
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _VoucherSelectionBorderPainter(
                                    color: scheme.primary,
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
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pattern.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: KreditTextSize.caption,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
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
    );
  }
}

class _VoucherSelectionBorderPainter extends CustomPainter {
  final Color color;
  const _VoucherSelectionBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = voucherOutline(Offset.zero & size);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_VoucherSelectionBorderPainter old) => color != old.color;
}
