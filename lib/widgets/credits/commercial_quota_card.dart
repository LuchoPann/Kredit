import 'package:flutter/material.dart';

import '../../data/models/commercial_quota.dart';
import '../../data/models/credit.dart';
import '../../domain/commercial_quota_calculator.dart';
import '../../domain/credit_calculator.dart';
import '../../utils/credit_display_utils.dart';

/// Groups every purchase (LoanCredit) tagged with a CommercialQuota under
/// one card showing the brand and available/limit — the user sees "Totto",
/// never the real financial provider behind it.
class CommercialQuotaCard extends StatelessWidget {
  final CommercialQuota quota;
  final List<LoanCredit> purchases;

  const CommercialQuotaCard({
    super.key,
    required this.quota,
    required this.purchases,
  });

  @override
  Widget build(BuildContext context) {
    final available = quotaAvailable(quota, purchases);
    final ratio = quota.limit <= 0
        ? 0.0
        : (available / quota.limit).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(quota.brand, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: ratio),
            const SizedBox(height: 4),
            Text(
                '${formatCOP(available)} disponible de ${formatCOP(quota.limit)}'),
            const SizedBox(height: 12),
            for (final purchase in purchases)
              Material(
                color: Colors.transparent,
                child: ListTile(
                  title: Text(purchase.name),
                  trailing:
                      Text(formatCOP(getCreditRemainingBalance(purchase))),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
