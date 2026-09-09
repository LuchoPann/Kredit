import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/credit.dart';
import '../../data/models/installment.dart';
import '../../domain/credit_calculator.dart';
import '../../domain/urgency_score.dart';
import '../../providers/credits_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/credit_display_utils.dart';
import '../../widgets/credit_card_tile.dart';
import '../../widgets/kredit_logo.dart';
import '../../widgets/kredit_section_card.dart';
import '../../widgets/progress_ring.dart';

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
                final fgColor = legibleForegroundOn(accentColor);
                return FloatingActionButton(
                  // Explicit, distinct hero tag: with all 4 tabs kept alive by
                  // the root IndexedStack (see main.dart), this FAB and
                  // credits_list_screen.dart's FAB both exist in the tree at
                  // once — without distinct tags they'd collide on Flutter's
                  // default hero tag and throw "multiple heroes share the
                  // same tag".
                  heroTag: 'fab-dashboard',
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
            Icon(Icons.error_outline, size: KreditIconSize.large, color: kredit.textTertiary),
            const SizedBox(height: 16),
            Text(
              'No se pudieron cargar tus créditos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textSecondary),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: KreditIconSize.small),
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
/// Ranges: mañana 5:00–11:59, tarde 12:00–17:59, noche 18:00–4:59 (cubre
/// toda la franja nocturna/madrugada).
String _greeting() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 12) return 'Buenos días';
  if (hour >= 12 && hour < 18) return 'Buenas tardes';
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

    final profileName = ref.watch(themePreferencesProvider).profileName;
    final totalDebt = ref.watch(totalUnpaidProvider);
    final activeCredits = credits.where(creditHasUnpaid).toList();
    final progressPct = getLoansProgressPercent(credits);
    final dueSoon = getDueSoonTotal(credits);
    final upcoming = _buildUpcomingItems(credits);

    return ListView(
      // Extra bottom clearance so the last row of content can scroll clear
      // of the floating "+" button instead of sitting hidden behind it.
      padding: const EdgeInsets.fromLTRB(
        KreditSpacing.card,
        KreditSpacing.card,
        KreditSpacing.card,
        88,
      ),
      children: [
        // 1. Greeting header — the main textual element now that the AppBar
        // is collapsed, plus a small logo mark for brand continuity.
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_greeting()}, $profileName',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tu situación crediticia',
                    style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Discreto — un acento de marca junto al saludo, no un segundo
            // punto focal compitiendo con el título.
            const KreditLogo(height: 30),
          ],
        ),
        const SizedBox(height: 28),

        // 2. Panel editorial de métricas: "Deuda total" lidera como cifra
        // protagonista (con el anillo de progreso como acento orgánico que
        // rompe la grilla), y las otras dos métricas quedan como datos
        // secundarios separados por una única línea fina — sin cajas.
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DEUDA TOTAL',
                    style: TextStyle(
                      fontSize: KreditTextSize.caption,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: kredit.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatCOP(totalDebt),
                    style: const TextStyle(
                      fontSize: KreditTextSize.hero,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                      height: 1.0,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ProgressRing(percent: progressPct, size: 68),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _SecondaryStat(
                label: 'Por pagar · 7 días',
                value: formatCOP(dueSoon),
              ),
            ),
            Container(
              width: 1,
              height: 34,
              margin: const EdgeInsets.symmetric(horizontal: 18),
              color: kredit.borderCard,
            ),
            Expanded(
              child: _SecondaryStat(
                label: 'Créditos activos',
                value: '${activeCredits.length} de ${credits.length}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // 3. Próximos pagos — ahora en su propia tarjeta discreta: fondo
        // ligeramente elevado (kredit.bgCard), radio moderado, sin sombra
        // dura ni borde marcado. El color de urgencia sigue viviendo en el
        // texto y en el acento circular pequeño de cada fila, no en el
        // contenedor — la tarjeta solo agrupa, no compite visualmente.
        KreditSectionCard(
          children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    'Próximos pagos',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: KreditTextSize.heading),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${upcoming.length}',
                    style: TextStyle(
                      fontSize: KreditTextSize.body,
                      fontWeight: FontWeight.w600,
                      color: kredit.textTertiary,
                    ),
                  ),
                  const Spacer(),
                  if (upcoming.length > 3)
                    TextButton(
                      onPressed: () => _showAllUpcomingSheet(context, upcoming),
                      child: const Text('Ver todos', style: TextStyle(fontSize: KreditTextSize.caption)),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              if (upcoming.isEmpty)
                const _InlineEmpty(text: 'No tienes pagos pendientes próximos.')
              else
                _UpcomingList(items: upcoming.take(3).toList()),
              if (upcoming.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: TextButton(
                    onPressed: () => _showAllUpcomingSheet(context, upcoming),
                    child: const Text('Ver todos'),
                  ),
                ),
          ],
        ),

        // 4. Lista de créditos activos — misma tarjeta discreta.
        if (activeCredits.isNotEmpty) ...[
          const SizedBox(height: 16),
          KreditSectionCard(
            children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      'Tus créditos',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: KreditTextSize.heading),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${activeCredits.length}',
                      style: TextStyle(
                        fontSize: KreditTextSize.body,
                        fontWeight: FontWeight.w600,
                        color: kredit.textTertiary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () =>
                          ref.read(navigationIndexProvider.notifier).state = AppNavTab.credits,
                      child: const Text('Ver todos', style: TextStyle(fontSize: KreditTextSize.caption)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                CreditCardTileList(
                  credits: activeCredits,
                  onTap: (c) => Navigator.of(context).pushNamed(
                    '/credit-detail',
                    arguments: c.id,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Secondary metric expressed purely through typography — a small caps
/// label over a mid-weight value, no surrounding box. Jerarquía viene del
/// contraste de tamaño/peso frente a la cifra protagonista de arriba, no de
/// un contenedor propio.
class _SecondaryStat extends StatelessWidget {
  final String label;
  final String value;

  const _SecondaryStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: KreditTextSize.heading,
            letterSpacing: -0.3,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: KreditTextSize.caption,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: kredit.textTertiary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
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

/// The "Próximos pagos" list: rows separated by a hairline divider instead
/// of stacked bordered cards — urgency lives in the text color and a small
/// circular accent dot, not in a boxed container.
class _UpcomingList extends StatelessWidget {
  final List<_UpcomingItem> items;
  const _UpcomingList({required this.items});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _UpcomingRow(item: items[i]),
          if (i != items.length - 1) Divider(height: 1, color: kredit.borderCard),
        ],
      ],
    );
  }
}

/// A single "Próximos pagos" entry: entity name, amount, due date, and an
/// urgency dot (overdue = red, due soon = amber, otherwise neutral) — no
/// surrounding card.
class _UpcomingRow extends ConsumerWidget {
  final _UpcomingItem item;
  const _UpcomingRow({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final isLoan = item.installment != null;
    final daysLeft = item.daysUntilDue;

    final Color urgencyColor;
    final String urgencyLabel;

    if (daysLeft < 0) {
      urgencyColor = AppColors.danger;
      urgencyLabel = 'Vencido hace ${daysLeft.abs()}d';
    } else if (daysLeft == 0) {
      urgencyColor = Colors.orange;
      urgencyLabel = '¡Vence hoy!';
    } else if (daysLeft <= 3) {
      urgencyColor = Colors.amber;
      urgencyLabel = 'En $daysLeft días';
    } else {
      urgencyColor = kredit.textTertiary;
      urgencyLabel = 'En $daysLeft días';
    }

    final amountStr = isLoan
        ? formatCOP(item.installment!.amount)
        : (item.credit is CardCredit ? formatCOP((item.credit as CardCredit).currentBalance) : '');

    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(
        '/credit-detail',
        arguments: item.credit.id,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: urgencyColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.credit.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: KreditTextSize.body),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.credit.lender} · $urgencyLabel',
                    style: TextStyle(fontSize: KreditTextSize.caption, color: urgencyColor, fontWeight: FontWeight.w600),
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
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: KreditTextSize.body),
                ),
                const SizedBox(height: 4),
                if (isLoan)
                  Builder(
                    builder: (context) {
                      // Luminance-based foreground so the button stays
                      // legible on any accent color — same pattern used
                      // for the FABs.
                      final accentColor = Theme.of(context).colorScheme.primary;
                      final fgColor =
                          legibleForegroundOn(accentColor);
                      return InkWell(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          ref
                              .read(creditsProvider.notifier)
                              .toggleInstallmentPaid(item.credit.id, item.installment!.number);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.installment!.paid
                                ? kredit.success.withValues(alpha: 0.16)
                                : accentColor,
                            borderRadius: BorderRadius.circular(KreditRadius.chip),
                          ),
                          child: Text(
                            item.installment!.paid ? 'Pagado' : 'Marcar pago',
                            style: TextStyle(
                              fontSize: KreditTextSize.caption,
                              fontWeight: FontWeight.w700,
                              color: item.installment!.paid ? kredit.success : fgColor,
                            ),
                          ),
                        ),
                      );
                    },
                  )
                else
                  Icon(Icons.chevron_right, size: KreditIconSize.small, color: kredit.textTertiary),
              ],
            ),
          ],
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
                size: KreditIconSize.large, color: kredit.textTertiary),
            const SizedBox(height: 16),
            const Text(
              'Aún no tienes créditos registrados',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: KreditTextSize.body),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Agrega tu primera tarjeta o préstamo para empezar a llevar el control.',
              style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textSecondary),
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
        style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
      ),
    );
  }
}

void _showAllUpcomingSheet(BuildContext context, List<_UpcomingItem> items) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AllUpcomingPaymentsSheet(items: items),
  );
}

class _AllUpcomingPaymentsSheet extends ConsumerWidget {
  final List<_UpcomingItem> items;
  const _AllUpcomingPaymentsSheet({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: kredit.bgPrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: kredit.borderCard),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kredit.borderCard,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_outlined, color: accent, size: KreditIconSize.small),
                  const SizedBox(width: 10),
                  Text(
                    'Todos los próximos pagos',
                    style: TextStyle(
                      fontSize: KreditTextSize.heading,
                      fontWeight: FontWeight.w700,
                      color: kredit.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${items.length})',
                    style: TextStyle(
                      fontSize: KreditTextSize.body,
                      fontWeight: FontWeight.w600,
                      color: kredit.textTertiary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: KreditIconSize.small),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: kredit.borderCard),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: kredit.borderCard),
                itemBuilder: (context, i) => _UpcomingRow(item: items[i]),
              ),
            ),
            Divider(height: 1, color: kredit.borderCard),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref.read(navigationIndexProvider.notifier).state =
                      AppNavTab.credits;
                },
                icon: const Icon(Icons.credit_card_outlined, size: KreditIconSize.small),
                label: const Text('Ver en lista de créditos'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
