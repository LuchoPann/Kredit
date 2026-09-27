import 'package:flutter/material.dart';

import '../../data/models/commercial_quota.dart';
import '../../data/models/credit.dart';
import '../../domain/commercial_quota_calculator.dart';
import '../../utils/credit_display_utils.dart';
import '../wallet_card.dart';

/// Groups every purchase (LoanCredit) tagged with a CommercialQuota under
/// one card showing the brand and available/limit — the user sees "Totto",
/// never the real financial provider behind it.
class CommercialQuotaCard extends StatelessWidget {
  final CommercialQuota quota;
  final List<LoanCredit> purchases;
  // Purchases to compute disponible/límite from — always the quota's FULL
  // purchase list, regardless of any tab/search/quick-filter narrowing
  // `purchases` (the rows actually displayed) may have applied. Defaults to
  // `purchases` for callers with nothing to filter.
  final List<LoanCredit>? allPurchases;
  final ValueChanged<LoanCredit>? onPurchaseTap;
  final VoidCallback? onDeleteQuota;

  const CommercialQuotaCard({
    super.key,
    required this.quota,
    required this.purchases,
    this.allPurchases,
    this.onPurchaseTap,
    this.onDeleteQuota,
  });

  @override
  Widget build(BuildContext context) {
    final available = quotaAvailable(quota, allPurchases ?? purchases);
    final ratio = quota.limit <= 0
        ? 0.0
        : (available / quota.limit).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(quota.brand,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                if (onDeleteQuota != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Eliminar cupo',
                    onPressed: onDeleteQuota,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: ratio),
            const SizedBox(height: 4),
            Text(
                '${formatCOP(available)} disponible de ${formatCOP(quota.limit)}'),
            const SizedBox(height: 12),
            // Cada compra es su propio voucher (misma forma recortada que
            // el detalle) — nunca una fila de lista plana: son préstamos
            // sin tarjeta física, igual que el cupo que los agrupa.
            for (final purchase in purchases) ...[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onPurchaseTap == null
                    ? null
                    : () => onPurchaseTap!(purchase),
                child: WalletCard(credit: purchase),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
