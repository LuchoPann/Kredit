import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/card_movement.dart';
import '../../data/models/credit.dart';
import '../../data/models/installment.dart';
import '../../domain/card_calculator.dart';
import '../../domain/credit_calculator.dart';
import '../../domain/date_utils.dart';
import '../../domain/loan_calculator.dart';
import '../../providers/credits_provider.dart';
import '../../theme/app_theme.dart';
import '../card_movement_sheet.dart';
import '../wallet_card.dart';
import 'notes_tab.dart';
import 'stat_box.dart';

/// Resumen tab: the one screen someone opens to answer "where do I stand on
/// this debt, and what should I do next" without hunting through the other
/// tabs. Beyond the raw totals it surfaces the single most actionable fact
/// for each credit kind — "your next installment is due in N days, pay it
/// now" for loans, "you've used X% of your limit" for cards — with a
/// one-tap action right where that fact lives. Notes (location/payment
/// card/comments) are folded in here as a supporting section instead of
/// living in their own tab, since the app only has Resumen + Cronograma now.
class SummaryTab extends ConsumerWidget {
  final Credit credit;

  const SummaryTab({super.key, required this.credit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining = getCreditRemainingBalance(credit);

    late final String totalLabel;
    late final String totalValue;
    late final double interestRate;

    if (credit is LoanCredit) {
      final loan = credit as LoanCredit;
      totalLabel = 'Monto Financiado';
      totalValue = formatCurrency(loan.totalAmount);
      interestRate = loan.interestRate;
    } else {
      final card = credit as CardCredit;
      totalLabel = 'Límite Total';
      totalValue = formatCurrency(card.creditLimit);
      interestRate = card.interestRate;
    }

    return ListView(
      padding: const EdgeInsets.all(KreditSpacing.card),
      children: [
        WalletCard(credit: credit),
        const SizedBox(height: 16),
        // "Pendiente" gets a full-width hero tile — it's the one number a
        // user actually needs at a glance.
        StatBox(
          label: 'Pendiente',
          value: formatCurrency(remaining),
          caption: 'Lo que falta por pagar',
          icon: Icons.account_balance_wallet_outlined,
          emphasized: true,
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: StatBox(
                label: totalLabel,
                value: totalValue,
                icon: Icons.paid_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatBox(
                label: 'Interés E.A.',
                value: '${interestRate.toStringAsFixed(1)}%',
                icon: Icons.percent,
              ),
            ),
          ],
        ),
        if (credit is LoanCredit) ...[
          const SizedBox(height: 20),
          _LoanProgress(credit: credit as LoanCredit),
          const SizedBox(height: 14),
          _NextInstallmentCard(credit: credit as LoanCredit),
        ] else ...[
          const SizedBox(height: 20),
          _CardUtilization(credit: credit as CardCredit),
          const SizedBox(height: 14),
          _CardCycleInfo(credit: credit as CardCredit),
          const SizedBox(height: 14),
          _CardQuickActions(credit: credit as CardCredit),
        ],
        const SizedBox(height: 20),
        NotesTab(credit: credit, embedded: true),
      ],
    );
  }
}

class _LoanProgress extends StatelessWidget {
  final LoanCredit credit;

  const _LoanProgress({required this.credit});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final total = credit.installments.length;
    final paid = credit.installments.where((i) => i.paid).length;
    final paidAmount = credit.installments
        .where((i) => i.paid)
        .fold(0.0, (s, i) => s + i.amount);
    final totalAmount =
        credit.installments.fold(0.0, (s, i) => s + i.amount);
    final pct = total > 0 ? paid / total : 0.0;
    return Container(
      padding: const EdgeInsets.all(KreditSpacing.tile),
      decoration: BoxDecoration(
        color: kredit.bgCard,
        border: Border.all(color: kredit.borderCard),
        borderRadius: BorderRadius.circular(KreditRadius.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progreso de Amortización',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kredit.textPrimary),
              ),
              Text(
                '$paid de $total cuotas · ${(pct * 100).round()}%',
                style: TextStyle(fontSize: 12, color: kredit.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: kredit.borderCard,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${formatCurrency(paidAmount)} pagado de ${formatCurrency(totalAmount)}',
            style: TextStyle(fontSize: 11, color: kredit.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// Surfaces the next unpaid installment with an inline "pay now" action so
/// the most common task on this screen — settling the upcoming cuota —
/// doesn't require switching to the Cronograma tab.
class _NextInstallmentCard extends ConsumerWidget {
  final LoanCredit credit;

  const _NextInstallmentCard({required this.credit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final unpaid = credit.installments.where((i) => !i.paid).toList()
      ..sort((a, b) => a.number.compareTo(b.number));

    if (unpaid.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(KreditSpacing.tile),
        decoration: BoxDecoration(
          color: kredit.bgCard,
          border: Border.all(color: kredit.borderCard),
          borderRadius: BorderRadius.circular(KreditRadius.tile),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Crédito totalmente pagado. ¡Sin cuotas pendientes!',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kredit.textPrimary),
              ),
            ),
          ],
        ),
      );
    }

    final Installment next = unpaid.first;
    final days = getDaysDifference(next.dueDate);
    final status = getInstallmentStatus(next);
    final isOverdue = status.state == InstallmentState.overdue;
    final accent = Theme.of(context).colorScheme.primary;

    String subtitle;
    if (isOverdue) {
      subtitle = 'Vencida hace ${days.abs()} día(s)';
    } else if (days == 0) {
      subtitle = 'Vence hoy';
    } else {
      subtitle = 'Vence en $days día(s) · ${formatDate(next.dueDate)}';
    }

    return Container(
      padding: const EdgeInsets.all(KreditSpacing.tile),
      decoration: BoxDecoration(
        color: kredit.bgCard,
        border: Border.all(color: isOverdue ? accent.withValues(alpha: 0.5) : kredit.borderCard),
        borderRadius: BorderRadius.circular(KreditRadius.tile),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Próxima Cuota · #${next.number}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kredit.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  formatCurrency(next.amount),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kredit.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                    color: isOverdue ? accent : kredit.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref
                    .read(creditsProvider.notifier)
                    .toggleInstallmentPaid(credit.id, next.number);
                messenger.showSnackBar(
                  SnackBar(content: Text('Cuota ${next.number} registrada como pagada')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('No se pudo registrar el pago: $e')),
                );
              }
            },
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Pagar'),
          ),
        ],
      ),
    );
  }
}

/// Utilization bar for cards — "you've used 80% of your limit" is far more
/// actionable than two bare numbers side by side.
class _CardUtilization extends StatelessWidget {
  final CardCredit credit;

  const _CardUtilization({required this.credit});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    final limit = credit.creditLimit;
    final used = credit.currentBalance;
    final pct = limit > 0 ? (used / limit).clamp(0.0, 1.0) : 0.0;
    final available = getCardAvailableLimit(credit);
    // High utilization is a signal worth flagging visually, not just a
    // decorative color choice.
    final isHigh = pct >= 0.8;

    return Container(
      padding: const EdgeInsets.all(KreditSpacing.tile),
      decoration: BoxDecoration(
        color: kredit.bgCard,
        border: Border.all(color: isHigh ? accent.withValues(alpha: 0.5) : kredit.borderCard),
        borderRadius: BorderRadius.circular(KreditRadius.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cupo Utilizado',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kredit.textPrimary),
              ),
              Text(
                '${(pct * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isHigh ? accent : kredit.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: kredit.borderCard,
              color: accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${formatCurrency(used)} usado de ${formatCurrency(limit)} · ${formatCurrency(available)} disponible',
            style: TextStyle(fontSize: 11, color: kredit.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// Cutoff/due-date at-a-glance so a cardholder doesn't need to open the
/// movements list just to know when the next bill closes.
class _CardCycleInfo extends StatelessWidget {
  final CardCredit credit;

  const _CardCycleInfo({required this.credit});

  @override
  Widget build(BuildContext context) {
    final dates = getCardCycleDates(credit);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: StatBox(
            label: 'Próxima Fecha de Corte',
            value: toDateStr(dates.nextCutoff),
            icon: Icons.event_repeat,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatBox(
            label: 'Fecha Límite de Pago',
            value: toDateStr(dates.dueDate),
            icon: Icons.event_available,
          ),
        ),
      ],
    );
  }
}

/// Direct access to the two actions someone reaches for constantly on a
/// card — registering a charge or a payment — without leaving Resumen.
class _CardQuickActions extends StatelessWidget {
  final CardCredit credit;

  const _CardQuickActions({required this.credit});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => CardMovementSheet.show(
              context,
              creditId: credit.id,
              movementType: CardMovementType.charge,
            ),
            icon: const Icon(Icons.arrow_upward, size: 16),
            label: const Text('Cargo/Compra'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => CardMovementSheet.show(
              context,
              creditId: credit.id,
              movementType: CardMovementType.payment,
            ),
            icon: const Icon(Icons.arrow_downward, size: 16),
            label: const Text('Registrar Pago'),
          ),
        ),
      ],
    );
  }
}
