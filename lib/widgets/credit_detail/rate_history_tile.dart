import 'package:flutter/material.dart';

import '../../data/models/credit.dart';
import '../../domain/interest_rate.dart';
import '../../theme/app_theme.dart';

/// Shows the current interest rate of a [CardCredit] with its type label,
/// and a note explaining that historical rate changes are not yet stored.
class RateHistoryTile extends StatelessWidget {
  final CardCredit credit;

  const RateHistoryTile({super.key, required this.credit});

  String _rateLabel(String type) {
    switch (type) {
      case InterestRateType.effectiveMonthly:
        return 'E.M.';
      case InterestRateType.nominalMonthly:
        return 'N.M.V.';
      case InterestRateType.effectiveAnnual:
      default:
        return 'E.A.';
    }
  }

  String _ratePeriod(String type) {
    switch (type) {
      case InterestRateType.effectiveMonthly:
      case InterestRateType.nominalMonthly:
        return 'mensual';
      case InterestRateType.effectiveAnnual:
      default:
        return 'anual';
    }
  }

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    final rate = credit.interestRate;
    final type = credit.interestRateType;
    final hasRate = rate > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.percent_rounded,
                size: AppIconSize.small, color: kredit.textTertiary),
            const SizedBox(width: 8),
            Text(
              'Tasa de interés',
              style: TextStyle(
                fontSize: AppTextSize.body,
                fontWeight: FontWeight.w600,
                color: kredit.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (hasRate)
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  border: Border.all(
                      color: accent.withValues(alpha: 0.25)),
                ),
                child: Text(
                  '${rate.toStringAsFixed(rate % 1 == 0 ? 0 : 2)}% ${_rateLabel(type)} ${_ratePeriod(type)}',
                  style: TextStyle(
                    fontSize: AppTextSize.body,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'tasa actual',
                style: TextStyle(
                    fontSize: AppTextSize.caption,
                    color: kredit.textTertiary),
              ),
            ],
          )
        else
          Text(
            'Sin tasa registrada',
            style: TextStyle(
                fontSize: AppTextSize.body, color: kredit.textTertiary),
          ),
        const SizedBox(height: 6),
        Text(
          'Los cambios de tasa quedan registrados a partir de la próxima actualización en la app.',
          style: TextStyle(
              fontSize: AppTextSize.caption,
              color: kredit.textTertiary,
              fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}
