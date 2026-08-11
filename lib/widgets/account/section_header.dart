import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

const sectionTitleStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.bold,
  letterSpacing: 0.2,
);

/// Section header with a leading icon for quick visual scanning, and
/// consistent weight/spacing across all "Cuenta" sections. [subtitle], when
/// given, adds a one-line plain-language explainer under the title so each
/// section's purpose is clear before the user reads its controls.
Widget sectionHeader(IconData icon, String title, {Color? color, String? subtitle}) {
  return Builder(
    builder: (context) {
      final kredit = Theme.of(context).extension<KreditColors>()!;
      final resolvedColor = color ?? kredit.textPrimary;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color ?? kredit.textSecondary),
              const SizedBox(width: 8),
              Text(title, style: sectionTitleStyle.copyWith(color: resolvedColor)),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(subtitle, style: TextStyle(fontSize: 12, color: kredit.textTertiary)),
            ),
          ],
        ],
      );
    },
  );
}
