import 'package:flutter/material.dart';

import '../data/models/credit.dart';
import '../domain/bank_detector.dart';
import '../providers/credits_provider.dart' show isDemoCredit;
import '../theme/app_theme.dart';
import '../utils/credit_display_utils.dart';
import 'demo_badge.dart';
import 'wallet_card.dart' show bankLogoAssets, BankLogoChip;

/// Compact credit row used by the dashboard's "Créditos activos" list.
///
/// Follows the typographic language introduced at the top of
/// `dashboard_screen.dart` ("Próximos pagos" / `_UpcomingRow`): no bordered
/// box wrapping the row — hierarchy comes from type size/weight, and a small
/// circular accent (the bank's color, standing in for the urgency dot used
/// above) replaces the old bank-logo avatar's boxed-circle-with-border
/// treatment. Consecutive rows are separated by the caller with a hairline
/// `Divider`, exactly as `_UpcomingList` does — see `CreditCardTileList`
/// below, used by `dashboard_screen.dart`.
///
/// The richer, full-card presentation (visual [WalletCard] + stats row)
/// lives in `wallet_card.dart` as `CreditStatsRow`/`WalletCard`, used by
/// credits_list_screen.dart instead of this tile.
class CreditCardTile extends StatefulWidget {
  final Credit credit;
  final VoidCallback onTap;

  const CreditCardTile({
    super.key,
    required this.credit,
    required this.onTap,
  });

  @override
  State<CreditCardTile> createState() => _CreditCardTileState();
}

class _CreditCardTileState extends State<CreditCardTile> {
  double _opacity = 1;

  void _setPressed(bool pressed) {
    setState(() => _opacity = pressed ? 0.6 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final credit = widget.credit;
    final bank = detectBank(
      lender: credit.lender,
      card: credit is LoanCredit ? credit.card : null,
      fallbackColor: credit.color,
    );
    final accent = parseHexColor(bank.accentColor);
    final logoAsset = bankLogoAssets[bank.cssClass];
    final kredit = Theme.of(context).extension<AppThemeColors>()!;

    return InkWell(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
          child: Row(
            children: [
              // Small circular accent standing in for the bank identity —
              // logo when we have one, otherwise a plain dot of the bank's
              // color — the same footprint as the urgency dot in
              // "Próximos pagos", not a boxed avatar.
              SizedBox(
                width: 22,
                height: 22,
                child: logoAsset != null
                    ? ClipOval(
                        child: ColoredBox(
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: BankLogoChip(assetPath: logoAsset, height: 16),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            credit.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: AppTextSize.body),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isDemoCredit(credit.id)) const DemoBadge(),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${bank.shortLabel} · ${creditTypeLabel(credit)} · ${creditSublabel(credit)}',
                      style: TextStyle(
                        fontSize: AppTextSize.body,
                        fontWeight: FontWeight.w600,
                        color: kredit.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Amount gets more visual weight than the rest of the row
              // (larger, bolder) since it's the primary decision-driving
              // fact in a credit list — "how much do I still owe here".
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    credit.isCard ? 'SALDO' : 'PENDIENTE',
                    style: TextStyle(
                      fontSize: AppTextSize.body,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: kredit.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    creditRemainingLabel(credit),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: AppTextSize.body,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, size: AppIconSize.small, color: kredit.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wraps a run of [CreditCardTile]s with hairline dividers between
/// consecutive rows — same pattern as `_UpcomingList` in
/// `dashboard_screen.dart` — instead of each tile drawing its own bordered
/// box. Used by the dashboard's "Tus créditos" section.
class CreditCardTileList extends StatelessWidget {
  final List<Credit> credits;
  final void Function(Credit credit) onTap;

  const CreditCardTileList({
    super.key,
    required this.credits,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    return Column(
      children: [
        for (var i = 0; i < credits.length; i++) ...[
          CreditCardTile(
            credit: credits[i],
            onTap: () => onTap(credits[i]),
          ),
          if (i != credits.length - 1) Divider(height: 1, color: kredit.borderCard),
        ],
      ],
    );
  }
}
