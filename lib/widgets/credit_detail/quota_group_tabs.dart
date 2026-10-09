import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/commercial_quota.dart';
import '../../data/models/credit.dart';
import '../../domain/commercial_quota_calculator.dart';
import '../../domain/credit_calculator.dart';
import '../../providers/credits_provider.dart';
import '../../screens/credit_detail/edit_credit_sheet.dart';
import '../../theme/app_theme.dart';
import '../../utils/credit_display_utils.dart';
import '../kredit_bottom_dialogs.dart';
import 'schedule_tab.dart';
import 'stat_box.dart';
import 'summary_tab.dart';

const _kAccordionAnim = Duration(milliseconds: 260);

/// Header row for one purchase's collapsible card — name + saldo restante +
/// chevron, always visible whether the card is open or closed. Tapping
/// anywhere on the row toggles it. Square bottom corners while expanded so
/// it visually welds onto the boxed body directly below it instead of
/// reading as two unrelated cards stacked apart.
class _PurchaseCardHeader extends StatelessWidget {
  final String name;
  final String trailingValue;
  final bool expanded;
  final VoidCallback onTap;

  const _PurchaseCardHeader({
    required this.name,
    required this.trailingValue,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    final radius = BorderRadius.vertical(
      top: const Radius.circular(AppRadius.card),
      bottom: Radius.circular(expanded ? 0 : AppRadius.card),
    );
    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: kredit.bgCard,
          borderRadius: radius,
          border: Border.all(color: kredit.borderCard.withValues(alpha: 0.78)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: kredit.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              trailingValue,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: kredit.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 6),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: _kAccordionAnim,
              curve: Curves.easeInOut,
              child: Icon(
                Icons.expand_more,
                size: AppIconSize.small,
                color: kredit.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The expanded body itself: a bordered box (same border/background as the
/// header, welded to its squared-off bottom corners) so the open content
/// visually reads as "inside a container" instead of loose text floating
/// under the header — the info being inspected never looks like it could
/// scroll away untethered.
class _PurchaseCardBody extends StatelessWidget {
  final Widget child;

  const _PurchaseCardBody({required this.child});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: kredit.bgCard,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.card)),
        border: Border(
          left: BorderSide(color: kredit.borderCard.withValues(alpha: 0.78)),
          right: BorderSide(color: kredit.borderCard.withValues(alpha: 0.78)),
          bottom: BorderSide(color: kredit.borderCard.withValues(alpha: 0.78)),
        ),
      ),
      child: child,
    );
  }
}

/// Wraps a collapsible card's boxed body so opening/closing it animates
/// height and opacity symmetrically in both directions. [AnimatedCrossFade]
/// (rather than swapping [child] for a plain placeholder under
/// [AnimatedOpacity]) keeps the real content mounted throughout the
/// transition, so collapsing fades and shrinks it exactly like expanding
/// does instead of yanking it out mid-animation.
class _ExpandableSection extends StatelessWidget {
  final bool expanded;
  final Widget child;

  const _ExpandableSection({required this.expanded, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: _kAccordionAnim,
      sizeCurve: Curves.easeInOut,
      firstCurve: Curves.easeIn,
      secondCurve: Curves.easeOut,
      crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: const SizedBox(width: double.infinity, height: 0),
      secondChild: _PurchaseCardBody(child: child),
    );
  }
}

/// Resumen tab for a credit that belongs to a CommercialQuota: instead of
/// stacking every purchase's full [SummaryTab] one after another, or forcing
/// a swipe/tab switch between them, each purchase is a collapsible card —
/// closed by default (just name + saldo), tap to expand it in place (inside
/// a bordered box) and see its full Resumen (same [SummaryTab] a single
/// credit would show, unmodified), tap again to collapse. The cupo-level
/// disponible/límite sits above the list, always visible. Which purchase is
/// open is owned by the parent screen ([expandedId]/[onToggle]) so Resumen
/// and Cronograma always show the same one.
class QuotaGroupSummaryTab extends ConsumerWidget {
  final CommercialQuota? quota;
  final List<LoanCredit> purchases;
  final String? expandedId;
  final ValueChanged<String> onToggle;

  const QuotaGroupSummaryTab({
    super.key,
    required this.quota,
    required this.purchases,
    required this.expandedId,
    required this.onToggle,
  });

  Future<void> _confirmDeletePurchase(
      BuildContext context, WidgetRef ref, LoanCredit purchase) async {
    final confirmed = await showAppConfirmSheet(
      context,
      title: 'Eliminar compra',
      message: '¿Eliminar "${purchase.name}" y todo su historial? Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      isDanger: true,
      icon: Icons.delete_outline,
    );
    if (confirmed != true) return;
    try {
      await ref.read(creditsProvider.notifier).deleteCredit(purchase.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar la compra. Intenta de nuevo.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    final q = quota;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.card, AppSpacing.card, AppSpacing.card, 16),
      itemCount: purchases.length + (q != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (q != null && index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Expanded(
                  child: StatBox(
                    label: 'Disponible',
                    value: formatCOP(quotaAvailable(q, purchases)),
                    icon: Icons.account_balance_wallet_outlined,
                    emphasized: true,
                  ),
                ),
                Container(
                  width: 1,
                  height: 34,
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  color: kredit.borderCard,
                ),
                Expanded(
                  child: StatBox(
                    label: 'Límite',
                    value: formatCOP(q.limit),
                    icon: Icons.credit_score_outlined,
                  ),
                ),
              ],
            ),
          );
        }
        final purchase = purchases[index - (q != null ? 1 : 0)];
        final isExpanded = expandedId == purchase.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PurchaseCardHeader(
                name: purchase.name,
                trailingValue: formatCOP(getCreditRemainingBalance(purchase)),
                expanded: isExpanded,
                onTap: () => onToggle(purchase.id),
              ),
              _ExpandableSection(
                expanded: isExpanded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SummaryTab(
                      credit: purchase,
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => EditCreditSheet.show(context, purchase),
                            icon: const Icon(Icons.edit_outlined, size: AppIconSize.small),
                            label: const Text('Editar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger),
                            ),
                            onPressed: () => _confirmDeletePurchase(context, ref, purchase),
                            icon: const Icon(Icons.delete_outline, size: AppIconSize.small),
                            label: const Text('Eliminar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Cronograma tab for a quota-grouped credit: same collapsible-card pattern
/// as [QuotaGroupSummaryTab] — each purchase's full [ScheduleTab] is tucked
/// behind a closed card (name + saldo), expand one at a time instead of
/// swiping between tabs or scrolling past every purchase's whole schedule.
/// Shares the same [expandedId]/[onToggle] the parent screen feeds Resumen,
/// so switching tabs never loses track of which purchase was open.
class QuotaGroupScheduleTab extends StatelessWidget {
  final List<LoanCredit> purchases;
  final String? expandedId;
  final ValueChanged<String> onToggle;

  const QuotaGroupScheduleTab({
    super.key,
    required this.purchases,
    required this.expandedId,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: purchases.length,
      itemBuilder: (context, index) {
        final purchase = purchases[index];
        final isExpanded = expandedId == purchase.id;
        final unpaidCount = purchase.installments.where((i) => !i.paid).length;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PurchaseCardHeader(
                name: purchase.name,
                trailingValue: '$unpaidCount pendiente${unpaidCount == 1 ? '' : 's'}',
                expanded: isExpanded,
                onTap: () => onToggle(purchase.id),
              ),
              _ExpandableSection(
                expanded: isExpanded,
                child: ScheduleTab(credit: purchase, shrinkWrap: true),
              ),
            ],
          ),
        );
      },
    );
  }
}
