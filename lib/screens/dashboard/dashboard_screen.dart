import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/credit.dart';
import '../../data/models/installment.dart';
import '../../domain/credit_calculator.dart';
import '../../domain/urgency_score.dart';
import '../../providers/credits_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/credit_display_utils.dart';
import '../../widgets/credit_card_tile.dart';
import '../../widgets/kredit_logo.dart';
import '../../widgets/progress_ring.dart';
import '../stats/stats_screen.dart';

/// Dashboard ("Inicio") screen — answers "¿Qué tengo que pagar pronto?":
/// a greeting header, 3 compact metrics (por pagar / créditos activos /
/// deuda total), up to 3 upcoming-payment cards sorted by urgency, and the
/// list of active credits below.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditsAsync = ref.watch(creditsProvider);
    final credits = creditsAsync.valueOrNull;
    final isEmpty = credits != null && credits.isEmpty;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const SizedBox.shrink(),
        toolbarHeight: 0,
      ),
      body: SafeArea(
        child: creditsAsync.when(
          loading: () => const _DashboardLoadingState(),
          error: (err, st) => _DashboardErrorState(
            onRetry: () => ref.invalidate(creditsProvider),
          ),
          data: (credits) => _DashboardBody(credits: credits),
        ),
      ),
      // Oculto cuando la lista está vacía: en ese estado `_EmptyDashboard`
      // ya muestra su propio botón "Nuevo Crédito" y tener ambos era una
      // acción duplicada en pantalla.
      floatingActionButton: isEmpty
          ? null
          : Builder(
              builder: (context) {
                // Bug 2: luminance-based foreground so icon is readable on any accent
                final accentColor = Theme.of(context).colorScheme.primary;
                final fgColor = accentColor.computeLuminance() > 0.3 ? Colors.black : Colors.white;
                return FloatingActionButton(
                  backgroundColor: accentColor,
                  foregroundColor: fgColor,
                  onPressed: () => Navigator.of(context).pushNamed('/add-credit'),
                  tooltip: 'Agregar Crédito',
                  child: const Icon(Icons.add),
                );
              },
            ),
    );
  }
}

/// Branded loading spinner shown while credits are first fetched — matches
/// the treatment used in credits_list_screen.dart / stats_screen.dart.
class _DashboardLoadingState extends StatelessWidget {
  const _DashboardLoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// Error placeholder with icon + message + retry action, so a load failure
/// doesn't surface as raw debug text on the dashboard.
class _DashboardErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _DashboardErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: kredit.textTertiary),
            const SizedBox(height: 16),
            Text(
              'No se pudieron cargar tus créditos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: kredit.textSecondary),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Greeting shown up top, keyed off the hour of day — the dashboard's main
/// textual element now that the AppBar has been collapsed to zero height.
String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Buenos días';
  if (hour < 19) return 'Buenas tardes';
  return 'Buenas noches';
}

class _DashboardBody extends ConsumerWidget {
  final List<Credit> credits;

  const _DashboardBody({required this.credits});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (credits.isEmpty) {
      return const _EmptyDashboard();
    }
    final kredit = Theme.of(context).extension<KreditColors>()!;

    final totalDebt = ref.watch(totalUnpaidProvider);
    final activeCredits = credits.where(creditHasUnpaid).toList();
    final progressPct = getLoansProgressPercent(credits);
    final dueSoon = getDueSoonTotal(credits);
    final upcoming = _buildUpcomingItems(credits);

    return ListView(
      padding: const EdgeInsets.all(KreditSpacing.card),
      children: [
        // 1. Greeting header — the main textual element now that the AppBar
        // is collapsed, plus a small logo mark for brand continuity.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tu situación crediticia',
                    style: TextStyle(fontSize: 13, color: kredit.textSecondary),
                  ),
                ],
              ),
            ),
            const KreditLogo(height: 24),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.bar_chart_rounded),
              tooltip: 'Ver estadísticas',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: KreditSpacing.section),

        // 2. Compact 3-metric row.
        IntrinsicHeight(
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Por pagar',
                value: formatCOP(dueSoon),
                sublabel: 'Próximos 7 días',
                icon: Icons.schedule,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                label: 'Créditos activos',
                value: '${activeCredits.length}',
                sublabel: '${credits.length} en total',
                icon: Icons.credit_card,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                label: 'Deuda total',
                value: formatCOP(totalDebt),
                sublabel: null,
                icon: null,
                ring: progressPct,
              ),
            ),
          ],
          ),
        ),
        const SizedBox(height: KreditSpacing.section),

        // 3. Próximos pagos — up to 3 rich cards.
        Row(
          children: [
            Icon(Icons.event_repeat_outlined, size: 20, color: kredit.textSecondary),
            const SizedBox(width: 8),
            const Text(
              'Próximos pagos',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(width: 8),
            _CountPill(count: upcoming.length),
          ],
        ),
        const SizedBox(height: 12),
        if (upcoming.isEmpty)
          const _InlineEmpty(text: 'No tienes pagos pendientes próximos.')
        else
          ...upcoming.take(3).map((u) => _UpcomingCard(item: u)),
        if (upcoming.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextButton(
              onPressed: () => Navigator.of(context).pushNamed('/credits'),
              child: const Text('Ver todos'),
            ),
          ),

        // 4. Lista de créditos activos.
        if (activeCredits.isNotEmpty) ...[
          const SizedBox(height: KreditSpacing.section),
          Row(
            children: [
              const Text(
                'Tus créditos',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(width: 8),
              _CountPill(count: activeCredits.length),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/credits'),
                child: const Text('Ver todos', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...activeCredits.map((c) => CreditCardTile(
                credit: c,
                onTap: () => Navigator.of(context).pushNamed(
                  '/credit-detail',
                  arguments: c.id,
                ),
              )),
        ],
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? sublabel;
  final IconData? icon;
  final double? ring;

  const _MetricTile({
    required this.label,
    required this.value,
    this.sublabel,
    this.icon,
    this.ring,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Container(
      padding: const EdgeInsets.all(KreditSpacing.tile),
      decoration: BoxDecoration(
        color: kredit.bgCard,
        borderRadius: BorderRadius.circular(KreditRadius.tile),
        border: Border.all(color: kredit.borderCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: kredit.textTertiary),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: kredit.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (ring != null)
            Center(child: ProgressRing(percent: ring!, size: 56))
          else ...[
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (sublabel != null) ...[
              const SizedBox(height: 2),
              Text(
                sublabel!,
                style: TextStyle(fontSize: 9.5, color: kredit.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final int count;
  const _CountPill({required this.count});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: kredit.bgCard,
        borderRadius: BorderRadius.circular(KreditRadius.chip),
        border: Border.all(color: kredit.borderCard),
      ),
      child: Text(
        '$count',
        style: TextStyle(fontSize: 11, color: kredit.textSecondary),
      ),
    );
  }
}

class _UpcomingItem {
  final Credit credit;
  final DateTime dueDate;
  final Installment? installment; // null for card due dates

  _UpcomingItem({required this.credit, required this.dueDate, this.installment});

  /// Amount associated with this pending payment: the installment's own
  /// amount for loans, or the card's current balance for card due dates.
  double get amount {
    if (installment != null) return installment!.amount;
    final c = credit;
    return c is CardCredit ? c.currentBalance : 0;
  }

  /// Days from "today" (midnight) until [dueDate]; negative when overdue.
  int get daysUntilDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.difference(today).inDays;
  }

  /// Urgency score used to order "Próximos pagos": overdue items always
  /// outrank not-yet-due ones, and among items with similar timing, a
  /// larger amount is considered more urgent. See
  /// `lib/domain/urgency_score.dart`.
  double get urgency => urgencyScore(daysUntilDue: daysUntilDue, amount: amount);
}

List<_UpcomingItem> _buildUpcomingItems(List<Credit> credits) {
  final items = <_UpcomingItem>[];
  for (final c in credits) {
    if (c is LoanCredit) {
      final unpaid = c.installments.where((i) => !i.paid).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      if (unpaid.isNotEmpty) {
        items.add(_UpcomingItem(
          credit: c,
          dueDate: DateTime.parse(unpaid.first.dueDate),
          installment: unpaid.first,
        ));
      }
    } else if (c is CardCredit && c.currentBalance > 0) {
      final due = getNextDueDate(c);
      if (due != null) {
        items.add(_UpcomingItem(credit: c, dueDate: due));
      }
    }
  }
  // Descending urgency score: overdue first, then soonest-due, with larger
  // amounts breaking ties between similarly-urgent items.
  items.sort((a, b) => b.urgency.compareTo(a.urgency));
  return items;
}

/// A single "Próximos pagos" entry — bigger and more visual than the old
/// simple row: bank/entity name, amount, due date, and an urgency icon
/// (overdue = red error icon, due soon = amber clock, otherwise neutral).
class _UpcomingCard extends ConsumerWidget {
  final _UpcomingItem item;
  const _UpcomingCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final isLoan = item.installment != null;
    final daysLeft = item.daysUntilDue;

    final Color urgencyColor;
    final IconData urgencyIcon;
    final String urgencyLabel;
    final bool isCritical;

    if (daysLeft < 0) {
      urgencyColor = AppColors.danger;
      urgencyIcon = Icons.error;
      urgencyLabel = 'Vencido hace ${daysLeft.abs()}d';
      isCritical = true;
    } else if (daysLeft == 0) {
      urgencyColor = Colors.orange;
      urgencyIcon = Icons.schedule;
      urgencyLabel = '¡Vence hoy!';
      isCritical = true;
    } else if (daysLeft <= 3) {
      urgencyColor = Colors.amber;
      urgencyIcon = Icons.schedule;
      urgencyLabel = 'En $daysLeft días';
      isCritical = false;
    } else {
      urgencyColor = kredit.textTertiary;
      urgencyIcon = Icons.event_available;
      urgencyLabel = 'En $daysLeft días';
      isCritical = false;
    }

    final amountStr = isLoan
        ? formatCOP(item.installment!.amount)
        : (item.credit is CardCredit ? formatCOP((item.credit as CardCredit).currentBalance) : '');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isCritical ? Color.lerp(kredit.bgCard, urgencyColor, 0.06) : kredit.bgCard,
        borderRadius: BorderRadius.circular(KreditRadius.card),
        border: Border.all(color: kredit.borderCard),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(
          '/credit-detail',
          arguments: item.credit.id,
        ),
        child: Padding(
          padding: const EdgeInsets.all(KreditSpacing.card),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: urgencyColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(urgencyIcon, color: urgencyColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.credit.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.credit.lender} · $urgencyLabel',
                      style: TextStyle(fontSize: 11, color: urgencyColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amountStr,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  if (isLoan)
                    InkWell(
                      onTap: () => ref
                          .read(creditsProvider.notifier)
                          .toggleInstallmentPaid(item.credit.id, item.installment!.number),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.installment!.paid
                              ? Colors.green.withValues(alpha: 0.18)
                              : Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(KreditRadius.chip),
                        ),
                        child: Text(
                          item.installment!.paid ? 'Pagado' : 'Marcar pago',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: item.installment!.paid ? Colors.green : Colors.black,
                          ),
                        ),
                      ),
                    )
                  else
                    Icon(Icons.chevron_right, size: 18, color: kredit.textTertiary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard();

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 56, color: kredit.textTertiary),
            const SizedBox(height: 16),
            const Text(
              'Aún no tienes créditos registrados',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Agrega tu primera tarjeta o préstamo para empezar a llevar el control.',
              style: TextStyle(fontSize: 12, color: kredit.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/add-credit'),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Crédito'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  final String text;
  const _InlineEmpty({required this.text});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: kredit.textTertiary),
      ),
    );
  }
}
