import 'package:flutter/material.dart';

import '../../data/models/commercial_quota.dart';
import '../../data/models/credit.dart';
import '../../domain/commercial_quota_calculator.dart';
import '../../domain/credit_calculator.dart';
import '../../theme/app_theme.dart';
import '../../utils/credit_display_utils.dart';
import '../kredit_wordmark.dart';
import '../voucher_pattern.dart';
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

class _CommercialQuotaCardState extends State<CommercialQuotaCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  // Initialized in initState — AnimationController requires vsync (this),
  // which is only valid after the mixin is bound. Accessed only from build()
  // which runs after initState, so late is safe here.
  late final AnimationController _chevronCtrl;

  Animation<double> get _chevronTurn => _chevronCtrl.drive(
        Tween<double>(begin: 0.0, end: 0.5).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
      );

  @override
  void initState() {
    super.initState();
    _chevronCtrl = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _chevronCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _chevronCtrl.forward();
    } else {
      _chevronCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final available = quotaAvailable(
      widget.quota,
      widget.allPurchases ?? widget.purchases,
    );
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
            pattern: VoucherPattern.fromName(widget.quota.voucherPattern),
          ),
        ),
        // Misma caja gris de bordes inferiores curvos que "PROGRESO PAGADO"
        // bajo un WalletCard normal (_CreditComparisonStrip) — nunca un
        // chevron suelto flotando bajo el voucher.
        InkWell(
          onTap: _toggle,
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
            decoration: BoxDecoration(
              color: kredit.bgCard,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(KreditRadius.card),
              ),
              border: Border(
                left: BorderSide(
                  color: kredit.borderCard.withValues(alpha: 0.78),
                ),
                right: BorderSide(
                  color: kredit.borderCard.withValues(alpha: 0.78),
                ),
                bottom: BorderSide(
                  color: kredit.borderCard.withValues(alpha: 0.78),
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'COMPRAS DE ESTE CUPO',
                        style: TextStyle(
                          fontSize: KreditTextSize.caption,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: kredit.textTertiary,
                        ),
                      ),
                    ),
                    RotationTransition(
                      turns: _chevronTurn,
                      child: Icon(
                        Icons.expand_more,
                        size: KreditIconSize.small,
                        color: kredit.textSecondary,
                      ),
                    ),
                  ],
                ),
                // AnimatedSize anima el crecimiento/reducción del área
                AnimatedSize(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                    child: _expanded
                        ? Column(
                            key: const ValueKey('expanded'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              for (final purchase in widget.purchases)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          purchase.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: KreditTextSize.caption,
                                            color: kredit.textPrimary,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        formatCOP(getCreditRemainingBalance(purchase)),
                                        style: TextStyle(
                                          fontSize: KreditTextSize.caption,
                                          fontWeight: FontWeight.w800,
                                          color: kredit.textPrimary,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          )
                        : Align(
                            key: const ValueKey('collapsed'),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '$count compra${count == 1 ? '' : 's'}',
                              style: TextStyle(
                                fontSize: KreditTextSize.caption,
                                color: kredit.textSecondary,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
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
  final VoucherPattern pattern;

  const _QuotaVoucherFace({
    required this.brand,
    required this.available,
    required this.limit,
    required this.count,
    required this.pattern,
  });

  @override
  Widget build(BuildContext context) {
    final ink = pattern.foregroundColor;
    return RepaintBoundary(
      child: AspectRatio(
        aspectRatio: 1.9,
        child: ClipPath(
          clipper: const VoucherClipper(),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(decoration: pattern.backgroundDecoration),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: VoucherPatternPainter(pattern: pattern),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: VoucherBorderPainter(
                      color: ink.withValues(alpha: 0.35),
                    ),
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
                        // Kredit's own wordmark, painted straight in `ink`
                        // (no white chip box) — a cupo comercial voucher is
                        // Kredit's own product, not a third-party bank's.
                        KreditWordmark(color: ink, height: 18),
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
      ),
    );
  }
}
