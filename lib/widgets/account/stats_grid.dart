import 'package:flutter/material.dart';

import '../../data/models/credit.dart';
import '../../domain/credit_calculator.dart';
import '../../theme/app_theme.dart';

/// Minimal COP-style currency formatter (avoids pulling in intl formatting
/// conventions not already established elsewhere in this file's scope).
class NumberFormatLike {
  String format(double value) {
    final rounded = value.round();
    final str = rounded.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return '${rounded < 0 ? '-' : ''}\$$buf';
  }
}

/// Top summary row on stats_screen.dart: three metrics expressed purely
/// through typography — no surrounding boxes — separated by hairline
/// dividers, matching the language established in dashboard_screen.dart.
class StatsGrid extends StatelessWidget {
  final List<Credit> credits;
  const StatsGrid({super.key, required this.credits});

  static final _currency = NumberFormatLike();

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final totalBorrowed = getTotalBorrowed(credits);
    final totalPaid = _totalPaidHistorico(credits);
    final finishedCount = credits.where((c) => !creditHasUnpaid(c)).length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _StatTile(
            label: 'Finalizados',
            value: '$finishedCount',
          ),
        ),
        Container(
          width: 1,
          height: 34,
          margin: const EdgeInsets.symmetric(horizontal: 14),
          color: kredit.borderCard,
        ),
        Expanded(
          child: _StatTile(
            label: 'Total pagado',
            value: _currency.format(totalPaid),
          ),
        ),
        Container(
          width: 1,
          height: 34,
          margin: const EdgeInsets.symmetric(horizontal: 14),
          color: kredit.borderCard,
        ),
        Expanded(
          child: _StatTile(
            label: 'Total prestado',
            value: _currency.format(totalBorrowed),
          ),
        ),
      ],
    );
  }

  /// Total actually paid so far, across all credits: for loans, the sum of
  /// paid installment amounts; for cards, the sum of `payment` movements.
  /// Not ported 1:1 from a single app.js function — legacy renderSettings
  /// only shows totalBorrowed — but derived analogously from data already
  /// present on the models, to satisfy the "total pagado histórico" stat.
  double _totalPaidHistorico(List<Credit> credits) {
    var sum = 0.0;
    for (final c in credits) {
      if (c is LoanCredit) {
        sum += c.installments
            .where((i) => i.paid)
            .fold(0.0, (s, i) => s + i.amount);
      } else if (c is CardCredit) {
        sum += c.movements
            .where((m) => m.type == 'payment')
            .fold(0.0, (s, m) => s + m.amount);
      }
    }
    return sum;
  }
}

/// Misma jerarquía tipográfica que `_SecondaryStat` (dashboard_screen.dart) y
/// `_StatColumn` (stats_screen.dart) — las tres son la misma "fila de
/// métricas separadas por una línea fina" y antes tenían tamaños/pesos de
/// label y valor ligeramente distintos sin ninguna razón de diseño; ahora
/// comparten un único valor 19px/w700 y label 11.5px/w600/letterSpacing 0.6.
class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: KreditTextSize.value,
            letterSpacing: -0.3,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
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
      ],
    );
  }
}
