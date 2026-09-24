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
import '../../screens/stats/simulator_sheet.dart';
import '../card_movement_sheet.dart';
import '../../utils/credit_display_utils.dart';
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
      totalValue = formatCOP(loan.totalAmount);
      interestRate = loan.interestRate;
    } else {
      final card = credit as CardCredit;
      totalLabel = 'Límite Total';
      totalValue = card.creditLimit > 0
          ? formatCOP(card.creditLimit)
          : 'No definido';
      interestRate = card.interestRate;
    }

    final kredit = Theme.of(context).extension<KreditColors>()!;

    return ListView(
      padding: const EdgeInsets.all(KreditSpacing.card),
      children: [
        WalletCard(credit: credit),
        // El monto pendiente ya se muestra como "DEUDA RESTANTE" dentro del
        // WalletCard de arriba para préstamos, así que aquí no se repite —
        // solo las tarjetas de crédito conservan este bloque, porque su
        // WalletCard no incluye esa cifra.
        if (credit is! LoanCredit) ...[
          const SizedBox(height: 24),
          // "Pendiente" leads as the protagonist figure — full jerarquía
          // tipográfica sin caja, como en el dashboard.
          StatBox(
            label: 'Pendiente',
            value: formatCOP(remaining),
            caption: 'Lo que falta por pagar',
            icon: Icons.account_balance_wallet_outlined,
            emphasized: true,
          ),
          const SizedBox(height: 18),
          Divider(height: 1, color: kredit.borderCard),
          const SizedBox(height: 16),
        ] else
          const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StatBox(
                label: totalLabel,
                value: totalValue,
                icon: Icons.paid_outlined,
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
                label: 'Interés E.A.',
                value: '${interestRate.toStringAsFixed(1)}%',
                icon: Icons.percent,
              ),
            ),
          ],
        ),
        if (credit is LoanCredit) ...[
          const SizedBox(height: 18),
          Divider(height: 1, color: kredit.borderCard),
          const SizedBox(height: 20),
          _LoanProgress(credit: credit as LoanCredit),
          const SizedBox(height: 20),
          Divider(height: 1, color: kredit.borderCard),
          const SizedBox(height: 20),
          _NextInstallmentCard(credit: credit as LoanCredit),
        ] else ...[
          const SizedBox(height: 18),
          Divider(height: 1, color: kredit.borderCard),
          const SizedBox(height: 20),
          _CardUtilization(credit: credit as CardCredit),
          const SizedBox(height: 20),
          Divider(height: 1, color: kredit.borderCard),
          const SizedBox(height: 20),
          _CardCycleInfo(credit: credit as CardCredit),
          const SizedBox(height: 18),
          _CardQuickActions(credit: credit as CardCredit),
        ],
        const SizedBox(height: 20),
        Divider(height: 1, color: kredit.borderCard),
        const SizedBox(height: 4),
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
    final totalAmount = credit.installments.fold(0.0, (s, i) => s + i.amount);
    final pct = total > 0 ? paid / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PROGRESO DE AMORTIZACIÓN',
              style: TextStyle(
                fontSize: KreditTextSize.caption,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: kredit.textTertiary,
              ),
            ),
            Text(
              '$paid de $total cuotas · ${(pct * 100).round()}%',
              style: TextStyle(
                fontSize: KreditTextSize.caption,
                fontWeight: FontWeight.w600,
                color: kredit.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: kredit.borderCard,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${formatCOP(paidAmount)} pagado de ${formatCOP(totalAmount)}',
          style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
        ),
      ],
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
      return Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
            size: KreditIconSize.small,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Crédito totalmente pagado. ¡Sin cuotas pendientes!',
              style: TextStyle(
                fontSize: KreditTextSize.caption,
                fontWeight: FontWeight.w600,
                color: kredit.textPrimary,
              ),
            ),
          ),
        ],
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

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PRÓXIMA CUOTA · #${next.number}',
                style: TextStyle(
                  fontSize: KreditTextSize.caption,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: kredit.textTertiary,
                ),
              ),
              const SizedBox(height: 5),
              // El monto ya protagoniza el WalletCard de arriba ("PRÓXIMA
              // CUOTA"); aquí solo aporta contexto nuevo (el número de cuota
              // arriba y cuánto falta/si está vencida abajo), así que va en
              // un tamaño secundario en vez de repetirse como cifra grande.
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: KreditTextSize.body,
                  fontWeight: isOverdue ? FontWeight.w700 : FontWeight.w600,
                  color: isOverdue ? accent : kredit.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Tooltip(
          message: 'Simular abono extra sobre este crédito',
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 0),
            ),
            onPressed: () =>
                openSimulatorSheet(context, initialCreditId: credit.id),
            child: const Icon(Icons.calculate_outlined, size: KreditIconSize.small),
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
                SnackBar(
                  content: Text('Cuota ${next.number} registrada como pagada'),
                ),
              );
            } catch (e) {
              messenger.showSnackBar(
                SnackBar(content: Text('No se pudo registrar el pago: $e')),
              );
            }
          },
          icon: const Icon(Icons.check, size: KreditIconSize.small),
          label: const Text('Pagar'),
        ),
      ],
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
    final limit = credit.creditLimit;
    final used = credit.currentBalance;

    // No limit was set at creation (left optional/empty) — a 0% bar or a
    // "$0 disponible" line would misleadingly read as "no credit left"
    // instead of "we don't know the limit", so just say so instead of
    // rendering the usual progress bar.
    if (limit <= 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CUPO UTILIZADO',
            style: TextStyle(
              fontSize: KreditTextSize.caption,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: kredit.textTertiary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            used > 0
                ? '${formatCOP(used)} en saldo · límite no definido'
                : 'Límite no definido para esta tarjeta.',
            style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
          ),
        ],
      );
    }

    final accent = Theme.of(context).colorScheme.primary;
    final pct = (used / limit).clamp(0.0, 1.0);
    final available = getCardAvailableLimit(credit);
    // High utilization is a signal worth flagging visually, not just a
    // decorative color choice.
    final isHigh = pct >= 0.8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CUPO UTILIZADO',
              style: TextStyle(
                fontSize: KreditTextSize.caption,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: kredit.textTertiary,
              ),
            ),
            Text(
              '${(pct * 100).round()}%',
              style: TextStyle(
                fontSize: KreditTextSize.caption,
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
            minHeight: 6,
            backgroundColor: kredit.borderCard,
            color: accent,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${formatCOP(used)} usado de ${formatCOP(limit)} · ${formatCOP(available)} disponible',
          style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
        ),
      ],
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
    // `.start`, not `.stretch` — this Row lives inside SummaryTab's
    // ListView, which gives it an unbounded height; `.stretch` tries to
    // force children to fill that height, which Flutter can't resolve
    // against an infinite constraint and throws
    // "BoxConstraints forces an infinite height".
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            icon: const Icon(Icons.arrow_upward, size: KreditIconSize.small),
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
            icon: const Icon(Icons.arrow_downward, size: KreditIconSize.small),
            label: const Text('Registrar Pago'),
          ),
        ),
      ],
    );
  }
}
