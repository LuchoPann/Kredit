import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// A single stat tile (label + value + optional caption).
///
/// [emphasized] renders the tile as the "hero" figure of a group — larger
/// value text, accent-tinted border — used to give the most important
/// number (e.g. remaining balance) visual priority over its siblings
/// instead of all four stats competing equally for attention.
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
    return Container(
      padding: const EdgeInsets.all(KreditSpacing.tile),
      decoration: BoxDecoration(
        color: kredit.bgCard,
        border: Border.all(color: emphasized ? accent.withValues(alpha: 0.5) : kredit.borderCard),
        borderRadius: BorderRadius.circular(KreditRadius.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: kredit.textTertiary),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, color: kredit.textSecondary),
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
              fontSize: emphasized ? 22 : 16,
              fontWeight: FontWeight.bold,
              color: kredit.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(
              caption!,
              style: TextStyle(fontSize: 10, color: kredit.textTertiary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
