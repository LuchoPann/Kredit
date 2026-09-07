import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Section header for "Cuenta": bold title — optionally tinted (e.g. the
/// danger accent for "Zona de riesgo") — plus an optional one-line tertiary
/// subtitle underneath. Pure typographic hierarchy, no leading icon, no
/// icon-in-circle, no boxed container — matches the voice used by
/// dashboard_screen.dart's "Próximos pagos" / "Tus créditos" section titles.
Widget sectionHeader(String title, {Color? color, String? subtitle}) {
  return Builder(
    builder: (context) {
      final kredit = Theme.of(context).extension<KreditColors>()!;
      final resolvedColor = color ?? kredit.textPrimary;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: KreditTextSize.heading, color: resolvedColor),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(subtitle, style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary)),
          ],
        ],
      );
    },
  );
}
