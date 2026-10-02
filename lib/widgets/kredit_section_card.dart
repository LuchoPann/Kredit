import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tarjeta sutil compartida: un `Container` con fondo `bgCard`, borde suave
/// `borderCard` y radio `KreditRadius.card`, usada para agrupar bloques de
/// información relacionada en toda la app.
///
/// Si [label] no es nulo, se dibuja un header interno (ícono opcional +
/// texto en mayúsculas, `KreditTextSize.body`/`textTertiary`) antes del
/// contenido — el patrón de `_EditSectionCard`. Si [label] es nulo, la
/// tarjeta solo envuelve [children] sin header — el patrón de
/// `_DashboardSectionCard`.
class KreditSectionCard extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final List<Widget> children;

  const KreditSectionCard({
    super.key,
    this.label,
    this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KreditSpacing.card),
      decoration: BoxDecoration(
        color: kredit.bgCard,
        borderRadius: BorderRadius.circular(KreditRadius.card),
        border: Border.all(color: kredit.borderCard.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: KreditIconSize.small, color: kredit.textTertiary),
                  const SizedBox(width: 6),
                ],
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: KreditTextSize.body,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: kredit.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          ...children,
        ],
      ),
    );
  }
}
