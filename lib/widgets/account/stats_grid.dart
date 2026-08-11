import 'package:flutter/material.dart';

import '../../data/models/credit.dart';
import '../../domain/credit_calculator.dart';
import '../../theme/app_theme.dart';
import 'shadowed_card.dart';

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

class StatsGrid extends StatelessWidget {
  final List<Credit> credits;
  const StatsGrid({super.key, required this.credits});

  static final _currency = NumberFormatLike();

  @override
  Widget build(BuildContext context) {
    final activeCount = credits.where(creditHasUnpaid).length;
    final totalBorrowed = getTotalBorrowed(credits);
    final totalPaid = _totalPaidHistorico(credits);

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.bolt_outlined,
            label: 'Créditos activos',
            value: '$activeCount',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.check_circle_outline,
            label: 'Total pagado',
            value: _currency.format(totalPaid),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.account_balance_outlined,
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
        sum += c.installments.where((i) => i.paid).fold(0.0, (s, i) => s + i.amount);
      } else if (c is CardCredit) {
        sum += c.movements
            .where((m) => m.type == 'payment')
            .fold(0.0, (s, m) => s + m.amount);
      }
    }
    return sum;
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return ShadowedCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: KreditSpacing.card, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 16, color: kredit.textTertiary),
            const SizedBox(height: 6),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: kredit.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: kredit.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
