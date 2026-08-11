import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// "Ejemplo" pill shown next to demo credits (`credit.id == "demo-1" |
/// "demo-2"`), ported from `.badge-demo` in legacy_pwa/css/style.css
/// (~L480-491). Colors there are fixed neutral tones (`--text-tertiary`,
/// `--border-card`), not the user's accent — kept fixed here too.
class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: kredit.textPrimary.withValues(alpha: 0.06),
        border: Border.all(color: kredit.borderCard),
        borderRadius: BorderRadius.circular(KreditRadius.chip),
      ),
      child: Text(
        'EJEMPLO',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: kredit.textTertiary,
        ),
      ),
    );
  }
}
