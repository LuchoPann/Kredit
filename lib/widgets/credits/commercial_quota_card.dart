import 'package:flutter/material.dart';

import '../../data/models/commercial_quota.dart';
import '../../data/models/credit.dart';
import '../../domain/commercial_quota_calculator.dart';
import '../../domain/credit_calculator.dart';
import '../../theme/app_theme.dart';
import '../../utils/credit_display_utils.dart';
import '../wallet_card.dart';

/// A single voucher representing a whole CommercialQuota (Totto, Lili Pink,
/// Éxito CrediCompras...) — never a box wrapping several separate vouchers.
/// The bottom strip shows quota-level info (how many compras, disponible)
/// instead of a normal credit's "progreso pagado", and can be expanded in
/// place to show each compra's own balance without leaving the list. Tap
/// anywhere on the voucher itself to open the full detail (all compras of
/// this cupo, grouped) — deleting the quota lives there, not here.
class CommercialQuotaCard extends StatefulWidget {
  final CommercialQuota quota;
  final List<LoanCredit> purchases;
  // Purchases to compute disponible from — always the quota's FULL purchase
  // list, regardless of any tab/search/quick-filter narrowing `purchases`
  // (the ones actually listed when expanded) may have applied. Defaults to
  // `purchases` for callers with nothing to filter.
  final List<LoanCredit>? allPurchases;
  final VoidCallback? onTap;

  const CommercialQuotaCard({
    super.key,
    required this.quota,
    required this.purchases,
    this.allPurchases,
    this.onTap,
  });

  @override
  State<CommercialQuotaCard> createState() => _CommercialQuotaCardState();
}

class _CommercialQuotaCardState extends State<CommercialQuotaCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final available =
        quotaAvailable(widget.quota, widget.allPurchases ?? widget.purchases);
    final count = widget.purchases.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: _QuotaVoucherFace(
            brand: widget.quota.brand,
            available: available,
            limit: widget.quota.limit,
            count: count,
          ),
        ),
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _expanded ? 'Ocultar compras' : 'Ver $count compra${count == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: KreditTextSize.caption,
                    fontWeight: FontWeight.w700,
                    color: kredit.textSecondary,
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: KreditIconSize.small,
                  color: kredit.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          for (final purchase in widget.purchases)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      purchase.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: KreditTextSize.body,
                        color: kredit.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    formatCOP(getCreditRemainingBalance(purchase)),
                    style: TextStyle(
                      fontSize: KreditTextSize.body,
                      fontWeight: FontWeight.w700,
                      color: kredit.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

/// The voucher face itself — same notched-paper shape/chrome as an
/// individual purchase's [WalletCard] voucher variant, but representing the
/// cupo as a whole: brand where a bank logo would go, and a bottom stat row
/// showing disponible/límite + número de compras instead of a single
/// credit's progreso pagado.
class _QuotaVoucherFace extends StatelessWidget {
  final String brand;
  final double available;
  final double limit;
  final int count;

  const _QuotaVoucherFace({
    required this.brand,
    required this.available,
    required this.limit,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    // Voucher minimalista: relleno plano con el color de acento que el
    // usuario eligió en Ajustes, nunca el motivo de olas de Nequi
    // reciclado en otro color.
    final accent = Theme.of(context).colorScheme.primary;
    final ink = legibleForegroundOn(accent);
    return AspectRatio(
      aspectRatio: 1.9,
      child: ClipPath(
        clipper: const VoucherClipper(),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(decoration: BoxDecoration(color: accent)),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: VoucherBorderPainter(color: ink.withValues(alpha: 0.35)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(KreditRadius.chip),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.contain,
                          child: BankLogoChip(
                            assetPath: 'assets/logos/bank-generic.svg',
                            height: 17,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          brand,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: ink,
                            fontWeight: FontWeight.w700,
                            fontSize: KreditTextSize.body,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DISPONIBLE',
                              style: TextStyle(
                                color: ink.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w700,
                                fontSize: KreditTextSize.caption,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              formatCOP(available),
                              style: TextStyle(
                                color: ink,
                                fontWeight: FontWeight.w800,
                                fontSize: KreditTextSize.emphasis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'COMPRAS',
                            style: TextStyle(
                              color: ink.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w700,
                              fontSize: KreditTextSize.caption,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '$count',
                            style: TextStyle(
                              color: ink,
                              fontWeight: FontWeight.w800,
                              fontSize: KreditTextSize.emphasis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
