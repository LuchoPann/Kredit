import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// A single stat block (label + value + optional caption), expressed purely
/// through typography — no surrounding Container/border/BoxDecoration. Mirrors
/// the `_SecondaryStat` pattern from dashboard_screen.dart: small caps label,
/// then a value whose size/weight carries the hierarchy.
///
/// [emphasized] renders the tile as the "hero" figure of a group — larger
/// value text, accent-tinted value color — used to give the most important
/// number (e.g. remaining balance) visual priority over its siblings instead
/// of all four stats competing equally for attention.
class StatBox extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;
  final IconData? icon;
  final bool emphasized;

  const StatBox({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.icon,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: kredit.textTertiary),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: KreditTextSize.caption,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: kredit.textTertiary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: emphasized ? 6 : 4),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasized ? KreditTextSize.emphasis : KreditTextSize.heading,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: emphasized ? accent : kredit.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (caption != null) ...[
          const SizedBox(height: 2),
          Text(
            caption!,
            style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
