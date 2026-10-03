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
                        pattern.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: KreditTextSize.body,
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

/// Shows a bottom sheet for picking a [VoucherPattern], mirroring the look
/// and behaviour of [showCardDesignPicker] in wallet_card.dart.
void showVoucherPatternPickerSheet(
  BuildContext context, {
  required VoucherPattern current,
  required void Function(VoucherPattern) onSelected,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _VoucherPickerSheet(
      current: current,
      onSelected: (p) {
        Navigator.of(context).pop();
        onSelected(p);
      },
    ),
  );
}

class _VoucherPickerSheet extends StatelessWidget {
  final VoucherPattern current;
  final void Function(VoucherPattern) onSelected;

  const _VoucherPickerSheet({
    required this.current,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
              'DISEÑO DE VOUCHER',
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
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.35,
                ),
                itemCount: VoucherPattern.values.length,
                itemBuilder: (_, i) {
                  final pattern = VoucherPattern.values[i];
                  final isSelected = pattern == current;
                  return RepaintBoundary(
                    child: GestureDetector(
                      onTap: () => onSelected(pattern),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
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
                            pattern.label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: KreditTextSize.body,
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
        ),
      ),
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
