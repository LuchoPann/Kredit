import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/commercial_quota.dart';
import '../../data/models/credit.dart';
import '../../domain/commercial_quota_calculator.dart';
import '../../domain/credit_calculator.dart';
import '../../domain/date_utils.dart';
import '../../providers/credits_provider.dart';
import '../../screens/credit_detail/edit_credit_sheet.dart';
import '../../theme/app_theme.dart';
import '../../utils/credit_display_utils.dart';
import '../wallet_card.dart';
import 'stat_box.dart';

/// Resumen tab for a credit that belongs to a CommercialQuota: instead of
/// showing just the one purchase the user tapped into, it shows every
/// purchase ("voucher") registered under that same cupo — the entering
/// purchase first, the rest ordered most-recent-first — so the user
/// understands the whole cupo from one screen instead of hunting through
/// the credits list purchase by purchase.
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

    return ListView(
      padding: const EdgeInsets.all(KreditSpacing.card),
      children: [
        if (q != null) ...[
          Row(
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
          const SizedBox(height: 18),
          Divider(height: 1, color: kredit.borderCard),
          const SizedBox(height: 20),
        ],
        Text(
          '${purchases.length} COMPRA${purchases.length == 1 ? '' : 'S'}',
          style: TextStyle(
            fontSize: KreditTextSize.caption,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: kredit.textTertiary,
          ),
        ),
        const SizedBox(height: 8),
        for (final purchase in purchases) ...[
          WalletCard(credit: purchase),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: StatBox(
                  label: 'Deuda restante',
                  value: formatCOP(getCreditRemainingBalance(purchase)),
                ),
              ),
              IconButton(
                onPressed: () => EditCreditSheet.show(context, purchase),
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar compra',
              ),
              IconButton(
                onPressed: () => _confirmDeletePurchase(context, ref, purchase),
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                tooltip: 'Eliminar compra',
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

/// Cronograma tab for a quota-grouped credit: one collapsible section per
/// purchase (most recent expanded by default) instead of a single flat
/// schedule — each purchase keeps its own cuotas legible instead of being
/// merged into one confusing combined list.
class QuotaGroupScheduleTab extends ConsumerWidget {
  final List<LoanCredit> purchases;

  const QuotaGroupScheduleTab({super.key, required this.purchases});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kredit = Theme.of(context).extension<KreditColors>()!;

    return ListView.builder(
      padding: const EdgeInsets.all(KreditSpacing.card),
      itemCount: purchases.length,
      itemBuilder: (context, index) {
        final purchase = purchases[index];
        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: index == 0,
            title: Text(
              purchase.name,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: KreditTextSize.body),
            ),
            subtitle: Text(
              '${formatCOP(getCreditRemainingBalance(purchase))} pendiente',
              style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textSecondary),
            ),
            children: [
              for (final inst in purchase.installments)
                ListTile(
                  dense: true,
                  leading: Icon(
                    inst.paid ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: inst.paid ? kredit.textSecondary : Theme.of(context).colorScheme.primary,
                    size: KreditIconSize.small,
                  ),
                  title: Text('Cuota #${inst.number}'),
                  subtitle: Text(formatDate(inst.dueDate)),
                  trailing: Text(
                    formatCOP(inst.amount),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onTap: () => ref
                      .read(creditsProvider.notifier)
                      .toggleInstallmentPaid(purchase.id, inst.number),
                ),
            ],
          ),
        );
      },
    );
  }
}
