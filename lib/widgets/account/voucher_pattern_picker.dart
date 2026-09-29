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
    final kredit = Theme.of(context).extension<KreditColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: kredit.textSecondary)),
        const SizedBox(height: KreditSpacing.tile),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: VoucherPattern.values.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (context, index) {
            final pattern = VoucherPattern.values[index];
            final isSelected = pattern == selected;
            return GestureDetector(
              onTap: () => onSelect(pattern),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(KreditRadius.card),
                  border: Border.all(
                    color: isSelected ? kredit.textPrimary : kredit.borderCard,
                    width: isSelected ? 2.5 : 1,
                  ),
                ),
                padding: const EdgeInsets.all(6),
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Center(
                            child: AspectRatio(
                              aspectRatio: 1.9,
                              child: ClipPath(
                                clipper: const VoucherClipper(),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: DecoratedBox(decoration: pattern.backgroundDecoration),
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
                          ),
                          if (isSelected)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: kredit.textPrimary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  size: 12,
                                  color: kredit.bgCard,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pattern.label,
                      style: TextStyle(
                        fontSize: KreditTextSize.caption,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                        color: isSelected ? kredit.textPrimary : kredit.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
