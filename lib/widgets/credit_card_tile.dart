import 'package:flutter/material.dart';

import '../data/models/credit.dart';
import '../domain/bank_detector.dart';
import '../domain/card_calculator.dart';
import '../domain/date_utils.dart';
import '../providers/credits_provider.dart' show isDemoCredit;
import '../theme/app_theme.dart';
import '../utils/credit_display_utils.dart';
import 'demo_badge.dart';
import 'wallet_card.dart' show bankLogoAssets, BankLogoChip;

class CreditCardTile extends StatefulWidget {
  final Credit credit;
  final VoidCallback onTap;

  /// When true, renders extra rows below the header (cupo disponible /
  /// próximo pago for cards, próxima cuota for loans) — used by
  /// credits_list_screen.dart's richer cards. Dashboard rows stay compact
  /// (default false) since they already carry that info via _UpcomingRow.
  final bool expanded;

  const CreditCardTile({
    super.key,
    required this.credit,
    required this.onTap,
    this.expanded = false,
  });

  @override
  State<CreditCardTile> createState() => _CreditCardTileState();
}

class _CreditCardTileState extends State<CreditCardTile> {
  double _scale = 1;

  void _setPressed(bool pressed) {
    setState(() => _scale = pressed ? 0.97 : 1);
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
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: kredit.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KreditRadius.tile),
            side: BorderSide(color: kredit.borderCard, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            child: Container(
              padding: const EdgeInsets.all(KreditSpacing.tile),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                children: [
                  // Bank Logo Avatar — smaller than before (44 vs 52): the
                  // logo is an identifier, not the hero of this row, so it
                  // yields space to the remaining balance, which is the
                  // number a user scanning a credit list actually cares
                  // about first.
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: accent.withValues(alpha: 0.8), width: 2),
                    ),
                    padding: const EdgeInsets.all(7),
                    child: Center(
                      child: logoAsset != null
                          ? FittedBox(
                              fit: BoxFit.contain,
                              child: BankLogoChip(assetPath: logoAsset, height: 24),
                            )
                          : Icon(
                              credit.isCard ? Icons.credit_card : Icons.account_balance,
                              color: accent,
                              size: 20,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                credit.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isDemoCredit(credit.id)) const DemoBadge(),
                          ],
                        ),
                        const SizedBox(height: 3),
                        // Bank + type collapsed into one compact secondary
                        // line (was bank-chip + type on one row, sublabel on
                        // another) so the tile reads name → context → amount
                        // in two lines instead of three, tightening density
                        // for a scrollable list.
                        Text(
                          '${bank.shortLabel} · ${creditTypeLabel(credit)}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? accent : (accent == Colors.white ? Colors.black : accent),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          creditSublabel(credit),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF737373) : const Color(0xFF64748B),
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
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF737373) : const Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        creditRemainingLabel(credit),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: -0.2,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ],
                  ),
                  if (widget.expanded) ...[
                    const SizedBox(height: KreditSpacing.tile),
                    Container(height: 1, color: kredit.borderCard),
                    const SizedBox(height: 8),
                    _ExpandedInfoRow(credit: credit, kredit: kredit),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary info row shown when [CreditCardTile.expanded] is true: cupo
/// disponible + próximo pago for cards, próxima cuota for loans — the
/// "how is this credit doing" facts that don't fit the compact row.
class _ExpandedInfoRow extends StatelessWidget {
  final Credit credit;
  final KreditColors kredit;

  const _ExpandedInfoRow({required this.credit, required this.kredit});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];

    if (credit is CardCredit) {
      final card = credit as CardCredit;
      final available = getCardAvailableLimit(card);
      items.add(_InfoStat(
        label: 'CUPO DISPONIBLE',
        value: '${formatCOP(available)} / ${formatCOP(card.creditLimit)}',
        kredit: kredit,
      ));
      if (card.currentBalance > 0) {
        final due = getCardCycleDates(card).dueDate;
        items.add(_InfoStat(
          label: 'PRÓXIMO PAGO',
          value: formatDate(toDateStr(due)),
          kredit: kredit,
        ));
      }
    } else if (credit is LoanCredit) {
      final loan = credit as LoanCredit;
      final unpaid = loan.installments.where((i) => !i.paid).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      if (unpaid.isNotEmpty) {
        final next = unpaid.first;
        items.add(_InfoStat(
          label: 'PRÓXIMA CUOTA',
          value: '${formatCOP(next.amount)} · ${formatDate(next.dueDate)}',
          kredit: kredit,
        ));
      }
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: items,
    );
  }
}

class _InfoStat extends StatelessWidget {
  final String label;
  final String value;
  final KreditColors kredit;

  const _InfoStat({required this.label, required this.value, required this.kredit});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: kredit.textTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: kredit.textSecondary,
          ),
        ),
      ],
    );
  }
}
