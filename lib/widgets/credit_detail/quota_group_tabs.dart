import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/commercial_quota.dart';
import '../../data/models/credit.dart';
import '../../domain/commercial_quota_calculator.dart';
import '../../providers/credits_provider.dart';
import '../../screens/credit_detail/edit_credit_sheet.dart';
import '../../theme/app_theme.dart';
import '../../utils/credit_display_utils.dart';
import 'schedule_tab.dart';
import 'stat_box.dart';
import 'summary_tab.dart';

/// Resumen tab for a credit that belongs to a CommercialQuota: the exact
/// same [SummaryTab] the app already uses for a single credit — same
/// WalletCard, same stats, same progreso de amortización, same "próxima
/// cuota" card — stacked once per purchase in the cupo (entering purchase
/// first, the rest ordered most-recent-first), never a custom layout. A
/// compact cupo-level header (disponible/límite, same [StatBox] used
/// everywhere else) sits above the list, and each purchase gets its own
/// Editar/Eliminar row — the single-credit bottom bar doesn't apply once
/// there's more than one credit on screen.
class QuotaGroupSummaryTab extends ConsumerWidget {
  final CommercialQuota? quota;
  final List<LoanCredit> purchases;

  const QuotaGroupSummaryTab({
    super.key,
    required this.quota,
    required this.purchases,
  });

  Future<void> _confirmDeletePurchase(
      BuildContext context, WidgetRef ref, LoanCredit purchase) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Compra'),
        content: Text(
          '¿Eliminar "${purchase.name}" y todo su historial? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
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
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final q = quota;

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: purchases.length + (q != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (q != null && index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
                KreditSpacing.card, KreditSpacing.card, KreditSpacing.card, 4),
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
        final isFirstPurchase = purchase == purchases.first;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isFirstPurchase || q != null) ...[
              Divider(height: 1, color: kredit.borderCard),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Text(
                  purchase.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: KreditTextSize.caption,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: kredit.textTertiary,
                  ),
                ),
              ),
            ],
            SummaryTab(
              credit: purchase,
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(
                  KreditSpacing.card, 8, KreditSpacing.card, 0),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => EditCreditSheet.show(context, purchase),
                      icon: const Icon(Icons.edit_outlined, size: KreditIconSize.small),
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
                      icon: const Icon(Icons.delete_outline, size: KreditIconSize.small),
                      label: const Text('Eliminar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Cronograma tab for a quota-grouped credit: the exact same [ScheduleTab]
/// used for a single credit, one full instance per purchase (most recent
/// first) instead of a custom combined list — each purchase keeps its own
/// Vencidas/Próximas/Futuras/Pagadas grouping and its own Abono Extra/Pago
/// total actions, unchanged.
class QuotaGroupScheduleTab extends StatelessWidget {
  final List<LoanCredit> purchases;

  const QuotaGroupScheduleTab({super.key, required this.purchases});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: purchases.length,
      itemBuilder: (context, index) {
        final purchase = purchases[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) Divider(height: 1, color: kredit.borderCard),
            ScheduleTab(credit: purchase, shrinkWrap: true),
          ],
        );
      },
    );
  }
}
