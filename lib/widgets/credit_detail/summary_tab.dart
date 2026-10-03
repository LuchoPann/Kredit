import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/card_movement.dart';
import '../../data/models/credit.dart';
import '../../data/models/installment.dart';
import '../../domain/card_calculator.dart';
import '../../domain/date_utils.dart';
import '../../domain/loan_calculator.dart';
import '../../providers/credits_provider.dart';
import '../../theme/app_theme.dart';
import '../../screens/stats/simulator_sheet.dart';
import '../card_advance_sheet.dart';
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
  // Cuando un credito de cupo comercial agrupa varias compras, el detalle
  // muestra un SummaryTab completo por compra dentro de una tarjeta
  // colapsable de un ListView externo — este debe encogerse a su
  // contenido (nunca competir por el scroll) en vez de asumir que es el
  // unico widget de la pantalla.
  final bool shrinkWrap;
  final EdgeInsets? padding;

  const SummaryTab({
    super.key,
    required this.credit,
    this.shrinkWrap = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kredit = Theme.of(context).extension<KreditColors>()!;

    return ListView(
      padding: padding ?? const EdgeInsets.all(KreditSpacing.card),
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      children: [
        WalletCard(credit: credit),
        if (credit is CardCredit) ...[
          const SizedBox(height: 16),
          Divider(height: 1, color: kredit.borderCard),
          const SizedBox(height: 16),
          _CardCycleSummaryRow(credit: credit as CardCredit),
          const SizedBox(height: 16),
          Divider(height: 1, color: kredit.borderCard),
          const SizedBox(height: 16),
        ] else
          const SizedBox(height: 12),
        if (credit is LoanCredit) ...[
          const SizedBox(height: 12),
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
                fontSize: KreditTextSize.body,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: kredit.textTertiary,
              ),
            ),
            Text(
              '$paid de $total cuotas · ${(pct * 100).round()}%',
              style: TextStyle(
                fontSize: KreditTextSize.body,
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
          style: TextStyle(
            fontSize: KreditTextSize.body,
            color: kredit.textTertiary,
          ),
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
                fontSize: KreditTextSize.body,
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

    String daysLabel;
    if (isOverdue) {
      daysLabel = 'Venció hace ${days.abs()} día(s)';
    } else if (days == 0) {
      daysLabel = 'Vence hoy';
    } else {
      daysLabel = 'Vence en $days día(s)';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PRÓXIMA CUOTA · #${next.number}',
                style: TextStyle(
                  fontSize: KreditTextSize.body,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: kredit.textTertiary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                daysLabel,
                style: TextStyle(
                  fontSize: KreditTextSize.body,
                  fontWeight: isOverdue ? FontWeight.w700 : FontWeight.w600,
                  color: isOverdue ? accent : kredit.textPrimary,
                ),
              ),
              if (!isOverdue && days != 0) ...[
                const SizedBox(height: 1),
                Text(
                  formatDate(next.dueDate),
                  style: TextStyle(
                    fontSize: KreditTextSize.body,
                    color: kredit.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: kredit.textPrimary,
          ),
          onPressed: () => openSimulatorSheet(context, initialCreditId: credit.id),
          icon: const Icon(Icons.calculate_outlined, size: KreditIconSize.small),
          label: const Text('Simular'),
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            foregroundColor: legibleForegroundOn(accent),
          ),
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
              fontSize: KreditTextSize.body,
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
            style: TextStyle(
              fontSize: KreditTextSize.body,
              color: kredit.textTertiary,
            ),
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
                fontSize: KreditTextSize.body,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: kredit.textTertiary,
              ),
            ),
            Text(
              '${(pct * 100).round()}%',
              style: TextStyle(
                fontSize: KreditTextSize.body,
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
          style: TextStyle(
            fontSize: KreditTextSize.body,
            color: kredit.textTertiary,
          ),
        ),
      ],
    );
  }
}

/// Consumo del ciclo actual + días para fecha límite de pago — datos que
/// no aparecen en la tarjeta visual y que el usuario necesita de un vistazo.
const _monthsEs = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

String _humanDate(DateTime d) =>
    '${d.day} de ${_monthsEs[d.month - 1]} de ${d.year}';

/// Próximo vencimiento + mini timeline del ciclo en un Row.
/// El StatBox ocupa la mitad izquierda; la mitad derecha muestra
/// una línea de tiempo [corte ──●── límite] con el día actual marcado.
class _CardCycleSummaryRow extends StatelessWidget {
  final CardCredit credit;

  const _CardCycleSummaryRow({required this.credit});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final dates = getCardCycleDates(credit);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final due = dates.dueDate;
    final cutoff = dates.nextCutoff;
    final daysUntilDue = due.difference(todayDate).inDays;

    String dueLabel;
    Color dueColor = kredit.textPrimary;
    if (daysUntilDue < 0) {
      dueLabel = 'Vencido';
      dueColor = Colors.red.shade400;
    } else if (daysUntilDue == 0) {
      dueLabel = 'Hoy';
      dueColor = Colors.orange.shade400;
    } else if (daysUntilDue == 1) {
      dueLabel = 'Mañana';
      dueColor = Colors.orange.shade300;
    } else {
      dueLabel = 'En $daysUntilDue días';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: StatBox(
            label: 'Próximo vencimiento',
            value: dueLabel,
            caption: _humanDate(due),
            icon: Icons.timer_outlined,
            valueColor: dueColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CycleTimeline(
            cutoff: cutoff,
            due: due,
            today: todayDate,
            kredit: kredit,
            cutoffDay: credit.cutoffDay,
          ),
        ),
      ],
    );
  }
}

/// Mini línea de tiempo visual [corte ──●hoy──▶ límite].
class _CycleTimeline extends StatelessWidget {
  final DateTime cutoff;
  final DateTime due;
  final DateTime today;
  final KreditColors kredit;
  final int cutoffDay;

  const _CycleTimeline({
    required this.cutoff,
    required this.due,
    required this.today,
    required this.kredit,
    required this.cutoffDay,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    // Ventana: desde el corte anterior (cutoff - 30d aprox) hasta el límite.
    // Usamos cutoff como inicio del ciclo de facturación y due como fin.
    final cycleStart = cutoff.subtract(const Duration(days: 30));
    final totalDays = due.difference(cycleStart).inDays.clamp(1, 999);
    final elapsed = today.difference(cycleStart).inDays.clamp(0, totalDays);
    final progress = elapsed / totalDays;

    final isOverdue = today.isAfter(due);
    final markerColor = isOverdue
        ? Colors.red.shade400
        : today.isAtSameMomentAs(due)
            ? Colors.orange.shade400
            : accent;

    final dueDay = due.day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Ciclo de facturación',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: kredit.textTertiary,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (ctx, constraints) {
            final w = constraints.maxWidth;
            final markerX = (progress * w).clamp(4.0, w - 4.0);
            return SizedBox(
              height: 32,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Track fondo
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 14,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: kredit.borderCard,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Track progreso
                  Positioned(
                    left: 0,
                    width: markerX,
                    top: 14,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: markerColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Marcador día actual
                  Positioned(
                    left: markerX - 5,
                    top: 9,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: markerColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(ctx).colorScheme.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  // Label corte (izquierda)
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: Text(
                      'Corte $cutoffDay',
                      style: TextStyle(fontSize: 9, color: kredit.textTertiary),
                    ),
                  ),
                  // Label límite (derecha)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Text(
                      'Pago $dueDay',
                      style: TextStyle(
                        fontSize: 9,
                        color: isOverdue ? Colors.red.shade400 : kredit.textTertiary,
                        fontWeight: isOverdue ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
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
    final accent = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => CardMovementSheet.show(
                  context,
                  creditId: credit.id,
                  movementType: CardMovementType.charge,
                ),
                icon: const Icon(Icons.shopping_bag_outlined, size: KreditIconSize.small),
                label: const Text('Nueva compra'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  foregroundColor: legibleForegroundOn(accent),
                ),
                onPressed: () => CardMovementSheet.show(
                  context,
                  creditId: credit.id,
                  movementType: CardMovementType.payment,
                ),
                icon: const Icon(Icons.payments_outlined, size: KreditIconSize.small),
                label: const Text('Pagar tarjeta'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => CardAdvanceSheet.show(context, credit: credit),
            icon: const Icon(Icons.attach_money_outlined, size: KreditIconSize.small),
            label: const Text('Registrar avance'),
          ),
        ),
      ],
    );
  }
}
