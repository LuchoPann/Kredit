import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/card_movement.dart';
import '../../data/models/credit.dart';
import '../../providers/notification_settings_provider.dart';
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
import 'rate_history_tile.dart';
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
    final kredit = Theme.of(context).extension<AppThemeColors>()!;

    return ListView(
      padding: padding ?? const EdgeInsets.all(AppSpacing.card),
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      children: [
        WalletCard(credit: credit),
        if (credit is CardCredit) ...[
          const SizedBox(height: 12),
          _CardUtilization(credit: credit as CardCredit),
          const SizedBox(height: 16),
          Divider(height: 1, color: kredit.borderCard),
          const SizedBox(height: 16),
          _CardCycleSummaryRow(credit: credit as CardCredit),
          const SizedBox(height: 16),
          Divider(height: 1, color: kredit.borderCard),
          const SizedBox(height: 16),
          RateHistoryTile(credit: credit as CardCredit),
          const SizedBox(height: 16),
          Divider(height: 1, color: kredit.borderCard),
          const SizedBox(height: 16),
          _CardQuickActions(credit: credit as CardCredit),
        ] else ...[
          const SizedBox(height: 12),
          Divider(height: 1, color: kredit.borderCard),
          const SizedBox(height: 20),
          _LoanProgress(credit: credit as LoanCredit),
          const SizedBox(height: 20),
          Divider(height: 1, color: kredit.borderCard),
          const SizedBox(height: 20),
          _NextInstallmentCard(credit: credit as LoanCredit),
        ],
        const SizedBox(height: 20),
        Divider(height: 1, color: kredit.borderCard),
        const SizedBox(height: 8),
        _NotificationOverrideTile(credit: credit),
        const SizedBox(height: 8),
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
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
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
                fontSize: AppTextSize.body,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: kredit.textTertiary,
              ),
            ),
            Text(
              '$paid de $total cuotas · ${(pct * 100).round()}%',
              style: TextStyle(
                fontSize: AppTextSize.body,
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
            fontSize: AppTextSize.body,
            color: kredit.textTertiary,
          ),
        ),
        const SizedBox(height: 6),
        if (credit.interestUnknown)
          Text(
            'Cuenta sin intereses registrados',
            style: TextStyle(
              fontSize: AppTextSize.body,
              color: kredit.textTertiary,
            ),
          )
        else
          Text(
            '${(credit.interestRate * 100).toStringAsFixed(1)}% ${credit.interestRateType ?? ''}',
            style: TextStyle(
              fontSize: AppTextSize.body,
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
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    final unpaid = credit.installments.where((i) => !i.paid).toList()
      ..sort((a, b) => a.number.compareTo(b.number));

    if (unpaid.isEmpty) {
      return Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
            size: AppIconSize.small,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Crédito totalmente pagado. ¡Sin cuotas pendientes!',
              style: TextStyle(
                fontSize: AppTextSize.body,
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
                  fontSize: AppTextSize.body,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: kredit.textTertiary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                daysLabel,
                style: TextStyle(
                  fontSize: AppTextSize.body,
                  fontWeight: isOverdue ? FontWeight.w700 : FontWeight.w600,
                  color: isOverdue ? accent : kredit.textPrimary,
                ),
              ),
              if (!isOverdue && days != 0) ...[
                const SizedBox(height: 1),
                Text(
                  formatDate(next.dueDate),
                  style: TextStyle(
                    fontSize: AppTextSize.body,
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
          icon: const Icon(Icons.calculate_outlined, size: AppIconSize.small),
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
          icon: const Icon(Icons.check, size: AppIconSize.small),
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
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
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
              fontSize: AppTextSize.body,
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
              fontSize: AppTextSize.body,
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
                fontSize: AppTextSize.body,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: kredit.textTertiary,
              ),
            ),
            Text(
              '${(pct * 100).round()}%',
              style: TextStyle(
                fontSize: AppTextSize.body,
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
            fontSize: AppTextSize.body,
            color: kredit.textTertiary,
          ),
        ),
      ],
    );
  }
}

const _monthsEs = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

String _humanDate(DateTime d) =>
    '${d.day} de ${_monthsEs[d.month - 1]} de ${d.year}';

/// StatBox de próximo vencimiento + rich billing cycle timeline, en columna.
class _CardCycleSummaryRow extends StatelessWidget {
  final CardCredit credit;

  const _CardCycleSummaryRow({required this.credit});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    final dates = getCardCycleDates(credit);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final due = dates.dueDate;
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

    final cutoff = dates.nextCutoff;
    final daysUntilCutoff = cutoff.difference(todayDate).inDays;
    final cutoffLabel = daysUntilCutoff == 0
        ? 'Hoy'
        : daysUntilCutoff == 1
            ? 'Mañana'
            : daysUntilCutoff < 0
                ? 'Pasado'
                : 'En $daysUntilCutoff días';
    final cutoffColor = daysUntilCutoff <= 1
        ? Colors.orange.shade300
        : kredit.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Container(width: 1, height: 52, color: kredit.borderCard, margin: const EdgeInsets.symmetric(horizontal: 16)),
            Expanded(
              child: StatBox(
                label: 'Próximo corte',
                value: cutoffLabel,
                caption: _humanDate(cutoff),
                icon: Icons.content_cut_rounded,
                valueColor: cutoffColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Divider(color: kredit.borderCard, height: 1),
        const SizedBox(height: 14),
        Text(
          'CICLO DE FACTURACIÓN',
          style: TextStyle(
            fontSize: AppTextSize.body,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: kredit.textTertiary,
          ),
        ),
        const SizedBox(height: 8),
        _BillingCycleTimeline(
          cutoffDay: credit.cutoffDay,
          paymentDueDay: credit.paymentDueDay > 0
              ? credit.paymentDueDay
              : (credit.cutoffDay + credit.paymentDueOffsetDays - 1) % 31 + 1,
          todayDay: today.day,
          accent: accent,
          kredit: kredit,
          isOverdue: daysUntilDue < 0,
        ),
      ],
    );
  }
}

/// Rich billing cycle timeline, identical in spirit to the one shown at card
/// creation — spending period (teal) + payment window (accent) across a
/// 1-31 day axis, with a dynamic TODAY marker.
class _BillingCycleTimeline extends StatelessWidget {
  final int cutoffDay;
  final int paymentDueDay;
  final int todayDay;
  final Color accent;
  final AppThemeColors kredit;
  final bool isOverdue;

  const _BillingCycleTimeline({
    required this.cutoffDay,
    required this.paymentDueDay,
    required this.todayDay,
    required this.accent,
    required this.kredit,
    this.isOverdue = false,
  });

  @override
  Widget build(BuildContext context) {
    const spendColor = Color(0xFF4CAF93);
    final payColor = accent;
    final wraps = paymentDueDay <= cutoffDay;

    double frac(int day) => (day - 1) / 30.0;
    final cutFrac = frac(cutoffDay.clamp(1, 31));
    final dueFrac = frac(paymentDueDay.clamp(1, 31));
    final todayFrac = frac(todayDay.clamp(1, 31));

    final todayColor = isOverdue ? Colors.red.shade400 : accent;

    return LayoutBuilder(builder: (ctx, box) {
      final w = box.maxWidth;
      final cutX = w * cutFrac;
      final dueX = w * dueFrac;
      final todayX = (w * todayFrac).clamp(0.0, w);

      const barH = 10.0;
      const labelH = 14.0;
      const labelGap = 4.0;
      const nextH = 5.0;
      const nextGap = 8.0;
      const tickH = labelH + labelGap + nextH + nextGap;
      const dotR = 5.5;
      const totalH = tickH + barH + 50.0;

      return SizedBox(
        height: totalH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── "Nuevo extracto →" label above cutoff ──────────────────────
            Positioned(
              top: 0,
              left: (cutX + 4).clamp(0, w - 130),
              child: Text(
                'Nuevo extracto →',
                style: TextStyle(
                  fontSize: AppTextSize.caption,
                  fontWeight: FontWeight.w600,
                  color: spendColor,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            // ── Dashed next-cycle bar ───────────────────────────────────────
            Positioned(
              top: labelH + labelGap,
              left: cutX,
              right: 0,
              child: Row(
                children: List.generate(
                  30,
                  (i) => Expanded(
                    child: Container(
                      height: nextH,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        color: spendColor.withValues(
                            alpha: i == 0 ? 0.85 : (0.6 - i * 0.015).clamp(0.1, 1.0)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // ── Full background bar ─────────────────────────────────────────
            Positioned(
              top: tickH,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(height: barH, color: kredit.borderCard),
              ),
            ),
            // ── Spending segment (1 → corte) ────────────────────────────────
            Positioned(
              top: tickH,
              left: 0,
              width: cutX.clamp(0, w),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6), bottomLeft: Radius.circular(6)),
                child: Container(height: barH, color: spendColor.withValues(alpha: 0.75)),
              ),
            ),
            // ── Payment segment (corte → límite, no-wrap) ───────────────────
            if (!wraps && dueX > cutX)
              Positioned(
                top: tickH,
                left: cutX,
                width: (dueX - cutX).clamp(0, w - cutX),
                child: Container(height: barH, color: payColor.withValues(alpha: 0.6)),
              ),
            // ── Payment wrap: right side (corte → 31) ──────────────────────
            if (wraps)
              Positioned(
                top: tickH,
                left: cutX,
                right: 0,
                child: Container(height: barH, color: payColor.withValues(alpha: 0.6)),
              ),
            // ── Payment wrap: left side (1 → límite) ───────────────────────
            if (wraps && dueX > 0)
              Positioned(
                top: tickH,
                left: 0,
                width: dueX.clamp(0, w),
                child: Container(height: barH, color: payColor.withValues(alpha: 0.35)),
              ),

            // ── Tick + dot: corte ───────────────────────────────────────────
            Positioned(
              top: 0,
              left: cutX - 1,
              child: Container(width: 2, height: tickH + barH + 4, color: spendColor),
            ),
            Positioned(
              top: tickH - dotR + barH / 2,
              left: cutX - dotR,
              child: Container(
                width: dotR * 2,
                height: dotR * 2,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: spendColor,
                    border: Border.all(color: kredit.bgCard, width: 2)),
              ),
            ),
            // ── Tick + dot: límite ──────────────────────────────────────────
            Positioned(
              top: 0,
              left: dueX - 1,
              child: Container(width: 2, height: tickH + barH + 4, color: payColor),
            ),
            Positioned(
              top: tickH - dotR + barH / 2,
              left: dueX - dotR,
              child: Container(
                width: dotR * 2,
                height: dotR * 2,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: payColor,
                    border: Border.all(color: kredit.bgCard, width: 2)),
              ),
            ),

            // ── TODAY marker ────────────────────────────────────────────────
            // Small vertical tick + "Hoy" label above
            Positioned(
              top: labelH + labelGap + nextH + nextGap - 2,
              left: todayX - 1,
              child: Container(
                width: 2,
                height: barH + 4,
                color: todayColor.withValues(alpha: 0.9),
              ),
            ),
            Positioned(
              top: tickH - dotR + barH / 2,
              left: todayX - dotR,
              child: Container(
                width: dotR * 2,
                height: dotR * 2,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: todayColor,
                    border: Border.all(color: kredit.bgCard, width: 2.5)),
              ),
            ),
            // "Hoy" label — positioned above the tick, nudged to stay in bounds
            Positioned(
              top: 0,
              left: (todayX - 12).clamp(0, w - 28),
              child: Text(
                'Hoy',
                style: TextStyle(
                  fontSize: AppTextSize.caption,
                  fontWeight: FontWeight.w700,
                  color: todayColor,
                ),
              ),
            ),

            // ── Labels below bar ────────────────────────────────────────────
            Positioned(
              top: tickH + barH + 8,
              left: 0,
              child: Text('1',
                  style: TextStyle(fontSize: AppTextSize.caption, color: kredit.textTertiary)),
            ),
            Positioned(
              top: tickH + barH + 8,
              left: (cutX - 26).clamp(0, w - 52),
              width: 52,
              child: Text(
                'Corte\nDía $cutoffDay',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: AppTextSize.caption,
                    fontWeight: FontWeight.w600,
                    color: spendColor,
                    height: 1.3),
              ),
            ),
            Positioned(
              top: tickH + barH + 8,
              left: (dueX - 26).clamp(0, w - 52),
              width: 52,
              child: Text(
                wraps ? 'Límite\n(mes sig.)' : 'Límite\nDía $paymentDueDay',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: AppTextSize.caption,
                    fontWeight: FontWeight.w600,
                    color: payColor,
                    height: 1.3),
              ),
            ),
            Positioned(
              top: tickH + barH + 8,
              right: 0,
              child: Text('31',
                  style: TextStyle(fontSize: AppTextSize.caption, color: kredit.textTertiary)),
            ),
          ],
        ),
      );
    });
  }
}

/// Direct access to the actions someone reaches for constantly on a card.
class _CardQuickActions extends StatelessWidget {
  final CardCredit credit;

  const _CardQuickActions({required this.credit});

  void _showPaymentTypeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: _PaymentTypeSheet(credit: credit),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kredit.borderCard),
        color: kredit.bgCard,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
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
                  icon: const Icon(Icons.shopping_bag_outlined, size: AppIconSize.small),
                  label: const Text('Nueva compra'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    foregroundColor: legibleForegroundOn(accent),
                  ),
                  onPressed: () => _showPaymentTypeSheet(context),
                  icon: const Icon(Icons.payments_outlined, size: AppIconSize.small),
                  label: const Text('Pagar tarjeta'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => CardAdvanceSheet.show(context, credit: credit),
              icon: const Icon(Icons.attach_money_outlined, size: AppIconSize.small),
              label: const Text('Registrar avance'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentTypeSheet extends StatefulWidget {
  final CardCredit credit;

  const _PaymentTypeSheet({required this.credit});

  @override
  State<_PaymentTypeSheet> createState() => _PaymentTypeSheetState();
}

class _PaymentTypeSheetState extends State<_PaymentTypeSheet> {
  String _selected = 'extracto';

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    final accent = Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: kredit.borderCard,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '¿Cómo quieres pagar?',
                style: TextStyle(
                  fontSize: AppTextSize.heading,
                  fontWeight: FontWeight.w700,
                  color: kredit.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.receipt_long_outlined,
                  color: _selected == 'extracto' ? accent : kredit.textSecondary),
              title: Text(
                'Pagar extracto',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: kredit.textPrimary,
                ),
              ),
              subtitle: Text(
                'Aplica al extracto más antiguo sin pagar primero',
                style: TextStyle(fontSize: AppTextSize.body, color: kredit.textSecondary),
              ),
              trailing: _selected == 'extracto'
                  ? Icon(Icons.check_circle, color: accent)
                  : Icon(Icons.radio_button_unchecked, color: kredit.borderCard),
              onTap: () => setState(() => _selected = 'extracto'),
            ),
            ListTile(
              leading: Icon(Icons.account_balance_wallet_outlined,
                  color: _selected == 'deuda' ? accent : kredit.textSecondary),
              title: Text(
                'Abono a la deuda',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: kredit.textPrimary,
                ),
              ),
              subtitle: Text(
                'Reduce tu saldo total directamente',
                style: TextStyle(fontSize: AppTextSize.body, color: kredit.textSecondary),
              ),
              trailing: _selected == 'deuda'
                  ? Icon(Icons.check_circle, color: accent)
                  : Icon(Icons.radio_button_unchecked, color: kredit.borderCard),
              onTap: () => setState(() => _selected = 'deuda'),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    foregroundColor: legibleForegroundOn(accent),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    CardMovementSheet.show(
                      context,
                      creditId: widget.credit.id,
                      movementType: CardMovementType.payment,
                    );
                  },
                  child: const Text('Continuar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tile que permite sobrescribir los días de antelación de notificación
/// para este crédito en particular. Cuando está en "usar global" (null),
/// muestra cuántos días aplica el ajuste global.
class _NotificationOverrideTile extends ConsumerWidget {
  final Credit credit;
  const _NotificationOverrideTile({required this.credit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    final globalSettings = ref.watch(notificationSettingsProvider);
    final hasOverride = credit.notificationDaysBefore != null;
    final effectiveDays = credit.notificationDaysBefore ?? globalSettings.daysBefore;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Recordatorio personalizado',
            style: TextStyle(
              fontSize: AppTextSize.body,
              fontWeight: FontWeight.w600,
              color: kredit.textPrimary,
            ),
          ),
          subtitle: Text(
            hasOverride
                ? '$effectiveDays días antes (personalizado)'
                : '${globalSettings.daysBefore} días antes (global)',
            style: TextStyle(fontSize: AppTextSize.body, color: kredit.textSecondary),
          ),
          value: hasOverride,
          onChanged: (on) {
            final updated = _withNotificationDays(credit, on ? globalSettings.daysBefore : null);
            ref.read(creditsProvider.notifier).updateCredit(updated);
          },
        ),
        if (hasOverride) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
            child: Row(
              children: [
                Text('1', style: TextStyle(fontSize: AppTextSize.body, color: kredit.textTertiary)),
                Expanded(
                  child: Slider(
                    value: effectiveDays.toDouble().clamp(1, 14),
                    min: 1,
                    max: 14,
                    divisions: 13,
                    label: '$effectiveDays días',
                    onChanged: (v) {
                      final updated = _withNotificationDays(credit, v.round());
                      ref.read(creditsProvider.notifier).updateCredit(updated);
                    },
                  ),
                ),
                Text('14', style: TextStyle(fontSize: AppTextSize.body, color: kredit.textTertiary)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Credit _withNotificationDays(Credit credit, int? days) {
    if (credit is LoanCredit) {
      return LoanCredit(
        id: credit.id,
        name: credit.name,
        lender: credit.lender,
        color: credit.color,
        notes: credit.notes,
        cardDesign: credit.cardDesign,
        notificationDaysBefore: days,
        location: credit.location,
        card: credit.card,
        totalAmount: credit.totalAmount,
        quotaAmount: credit.quotaAmount,
        totalInstallments: credit.totalInstallments,
        frequency: credit.frequency,
        startDate: credit.startDate,
        interestRate: credit.interestRate,
        interestRateType: credit.interestRateType,
        installments: credit.installments,
        abonos: credit.abonos,
        scheduleManuallyAdjusted: credit.scheduleManuallyAdjusted,
        quotaId: credit.quotaId,
        interestUnknown: credit.interestUnknown,
        earlyPaymentWaivesInterest: credit.earlyPaymentWaivesInterest,
      );
    } else if (credit is CardCredit) {
      return CardCredit(
        id: credit.id,
        name: credit.name,
        lender: credit.lender,
        color: credit.color,
        notes: credit.notes,
        cardDesign: credit.cardDesign,
        notificationDaysBefore: days,
        creditLimit: credit.creditLimit,
        currentBalance: credit.currentBalance,
        cutoffDay: credit.cutoffDay,
        paymentDueOffsetDays: credit.paymentDueOffsetDays,
        paymentDueDay: credit.paymentDueDay,
        interestRate: credit.interestRate,
        interestRateType: credit.interestRateType,
        managementFee: credit.managementFee,
        managementFeeFrequency: credit.managementFeeFrequency,
        cycleCount: credit.cycleCount,
        lastAccrualCutoff: credit.lastAccrualCutoff,
        quotaId: credit.quotaId,
        oneInstallmentInterestPolicy: credit.oneInstallmentInterestPolicy,
        movements: credit.movements,
      );
    }
    return credit;
  }
}
