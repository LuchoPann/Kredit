import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/credit.dart';
import '../../domain/bank_detector.dart';
import '../../domain/card_calculator.dart';
import '../../domain/credit_calculator.dart';
import '../../domain/date_utils.dart';
import '../../providers/credits_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/credit_display_utils.dart';
import '../../widgets/account/stats_grid.dart';
import '../../widgets/kredit_section_card.dart';
import '../../widgets/progress_ring.dart';
import 'simulator_sheet.dart';

const _monthsEs = [
  'Ene',
  'Feb',
  'Mar',
  'Abr',
  'May',
  'Jun',
  'Jul',
  'Ago',
  'Sep',
  'Oct',
  'Nov',
  'Dic',
];

/// "Estadísticas avanzadas" screen: month-by-month debt projection, debt
/// distribution by lender, and payoff-date forecasts. Purely derived from
/// [creditsProvider] — no new persisted state.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditsAsync = ref.watch(creditsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas avanzadas')),
      body: creditsAsync.when(
        data: (credits) {
          if (credits.isEmpty) {
            return const _EmptyState();
          }
          return ListView(
            padding: const EdgeInsets.all(KreditSpacing.card),
            children: [
              _DebtOverviewPanel(credits: credits),
              const SizedBox(height: 22),
              StatsGrid(credits: credits),
              const SizedBox(height: 22),
              KreditSectionCard(
                children: [
                  _statsSectionHeader(
                    context,
                    Icons.savings_outlined,
                    'Abonos extra realizados',
                    subtitle:
                        'Impacto real de lo que ya has abonado a tus préstamos',
                  ),
                  const SizedBox(height: 12),
                  _AbonosHistorySummary(credits: credits),
                ],
              ),
              const SizedBox(height: 22),
              KreditSectionCard(
                children: [
                  _statsSectionHeader(
                    context,
                    Icons.show_chart_outlined,
                    'Deuda proyectada por mes',
                    subtitle: 'Próximos 6 meses, según cuotas y saldos vigentes',
                  ),
                  const SizedBox(height: 12),
                  _MonthlyDebtChart(credits: credits),
                ],
              ),
              const SizedBox(height: 22),
              KreditSectionCard(
                children: [
                  _statsSectionHeader(
                    context,
                    Icons.donut_small_outlined,
                    'Distribución por entidad',
                    subtitle:
                        'Proporción de tu deuda pendiente por banco o entidad',
                  ),
                  const SizedBox(height: 12),
                  _LenderDistributionChart(credits: credits),
                ],
              ),
              const SizedBox(height: 22),
              KreditSectionCard(
                children: [
                  _statsSectionHeader(
                    context,
                    Icons.event_available_outlined,
                    'Proyección de fin de pago',
                    subtitle: 'Cuándo terminarías de pagar cada préstamo activo',
                  ),
                  const SizedBox(height: 12),
                  _PayoffProjectionList(credits: credits),
                ],
              ),
              const SizedBox(height: 22),
              KreditSectionCard(
                children: [
                  _statsSectionHeader(
                    context,
                    Icons.calculate_outlined,
                    'Simulador financiero',
                    subtitle: '¿Qué pasaría si hago una compra o abono extra?',
                  ),
                  const SizedBox(height: 12),
                  _SimulatorEntryCard(credits: credits),
                ],
              ),
              const SizedBox(height: 24),
            ],
          );
        },
        loading: () => const _LoadingState(),
        error: (e, _) => _ErrorState(
          message: 'No se pudieron cargar las estadísticas.',
          onRetry: () => ref.invalidate(creditsProvider),
        ),
      ),
    );
  }
}

/// Editorial header panel: "Deuda activa total" leads as the protagonist
/// figure with a `ProgressRing` as its organic accent (same pattern as
/// dashboard_screen.dart's "DEUDA TOTAL"), and cupo disponible follows as a
/// secondary typographic stat — no surrounding boxes.
class _DebtOverviewPanel extends StatelessWidget {
  final List<Credit> credits;
  const _DebtOverviewPanel({required this.credits});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    double totalOwed = 0;
    double totalLimit = 0;
    int activeCount = 0;

    for (final c in credits) {
      if (c is LoanCredit) {
        final unpaid = c.installments
            .where((i) => !i.paid)
            .fold(0.0, (sum, i) => sum + i.amount);
        totalOwed += unpaid;
        if (unpaid > 0) activeCount++;
      } else if (c is CardCredit) {
        totalOwed += c.currentBalance;
        totalLimit += c.creditLimit;
        if (c.currentBalance > 0) activeCount++;
      }
    }

    final availableCredit = totalLimit > totalOwed
        ? totalLimit - totalOwed
        : 0.0;
    final progressPct = getLoansProgressPercent(credits);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DEUDA ACTIVA TOTAL',
                    style: TextStyle(
                      fontSize: KreditTextSize.caption,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: kredit.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatCOP(totalOwed),
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
              child: _StatColumn(
                label: 'Créditos activos',
                value: '$activeCount',
              ),
            ),
            Container(
              width: 1,
              height: 34,
              margin: const EdgeInsets.symmetric(horizontal: 18),
              color: kredit.borderCard,
            ),
            Expanded(
              child: _StatColumn(
                label: 'Cupo disponible',
                value: formatCOP(availableCredit),
              ),
            ),
            Container(
              width: 1,
              height: 34,
              margin: const EdgeInsets.symmetric(horizontal: 18),
              color: kredit.borderCard,
            ),
            Expanded(
              child: _StatColumn(
                label: 'Límite total',
                value: formatCOP(totalLimit),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Secondary metric expressed purely through typography — a mid-weight
/// value over a small-caps label, no surrounding box. Misma jerarquía que
/// `_SecondaryStat` (dashboard_screen.dart) y `_StatTile`
/// (widgets/account/stats_grid.dart) — las tres son el mismo patrón de "fila
/// de métricas separadas por una línea fina".
class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  const _StatColumn({required this.label, required this.value});

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

Widget _statsSectionHeader(
  BuildContext context,
  IconData icon,
  String title, {
  String? subtitle,
}) {
  final kredit = Theme.of(context).extension<KreditColors>()!;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: KreditIconSize.small, color: kredit.textSecondary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: KreditTextSize.heading,
              fontWeight: FontWeight.bold,
              color: kredit.textPrimary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: Text(
            subtitle,
            style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
          ),
        ),
      ],
    ],
  );
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

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
              message,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: KreditIconSize.large,
              color: kredit.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin datos para graficar',
              style: TextStyle(
                fontSize: KreditTextSize.heading,
                fontWeight: FontWeight.bold,
                color: kredit.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega créditos para ver tus estadísticas de deuda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bucket key for a calendar month.
class _MonthKey implements Comparable<_MonthKey> {
  final int year;
  final int month;
  const _MonthKey(this.year, this.month);

  @override
  bool operator ==(Object other) =>
      other is _MonthKey && other.year == year && other.month == month;

  @override
  int get hashCode => year * 12 + month;

  @override
  int compareTo(_MonthKey other) => hashCode.compareTo(other.hashCode);

  String get label => '${_monthsEs[month - 1]}\n$year';
}

/// Sums projected debt per month for the next [monthsAhead] months: loan
/// installments (unpaid, grouped by dueDate month) plus each card's current
/// balance placed in the month of its next due date.
Map<_MonthKey, double> _projectMonthlyDebt(
  List<Credit> credits, {
  int monthsAhead = 6,
}) {
  final now = DateTime.now();
  final start = _MonthKey(now.year, now.month);
  final months = <_MonthKey>[];
  for (var i = 0; i < monthsAhead; i++) {
    final totalMonth0 = (start.month - 1) + i;
    final y = start.year + totalMonth0 ~/ 12;
    final m = totalMonth0 % 12 + 1;
    months.add(_MonthKey(y, m));
  }
  final buckets = {for (final m in months) m: 0.0};

  for (final credit in credits) {
    if (credit is LoanCredit) {
      for (final inst in credit.installments) {
        if (inst.paid) continue;
        final due = parseDateStr(inst.dueDate);
        final key = _MonthKey(due.year, due.month);
        if (buckets.containsKey(key)) {
          buckets[key] = buckets[key]! + inst.amount;
        }
      }
    } else if (credit is CardCredit) {
      if (credit.currentBalance <= 0) continue;
      final dates = getCardCycleDates(credit);
      final key = _MonthKey(dates.dueDate.year, dates.dueDate.month);
      if (buckets.containsKey(key)) {
        buckets[key] = buckets[key]! + credit.currentBalance;
      }
    }
  }

  return {for (final m in months) m: buckets[m] ?? 0.0};
}

class _MonthlyDebtChart extends StatelessWidget {
  final List<Credit> credits;
  const _MonthlyDebtChart({required this.credits});

  static final _currency = NumberFormatLike();

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final data = _projectMonthlyDebt(credits);
    final entries = data.entries.toList();
    final maxY = entries.fold<double>(0, (m, e) => e.value > m ? e.value : m);

    if (maxY <= 0) {
      return const _InlineEmptyCard(
        text: 'No hay cuotas ni saldos próximos por proyectar.',
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 8, 0),
      child: SizedBox(
        height: 220,
        child: BarChart(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          BarChartData(
            maxY: maxY * 1.2,
            alignment: BarChartAlignment.spaceAround,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    _currency.format(rod.toY),
                    TextStyle(
                      color: kredit.textPrimary,
                      fontSize: KreditTextSize.caption,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= entries.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        entries[idx].key.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: KreditTextSize.caption,
                          color: kredit.textTertiary,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < entries.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: entries[i].value,
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          accent.withValues(alpha: 0.45),
                          accent,
                        ],
                      ),
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineEmptyCard extends StatelessWidget {
  final String text;
  const _InlineEmptyCard({required this.text});

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

class _LenderSlice {
  final String label;
  final double amount;
  final Color color;
  const _LenderSlice({
    required this.label,
    required this.amount,
    required this.color,
  });
}

List<_LenderSlice> _distributionByLender(List<Credit> credits) {
  final byLender = <String, double>{};
  final colorByLender = <String, Color>{};

  for (final credit in credits) {
    final balance = getCreditRemainingBalance(credit);
    if (balance <= 0) continue;
    final bank = detectBank(
      lender: credit.lender,
      card: credit is LoanCredit ? credit.card : null,
    );
    final key = bank.shortLabel.isEmpty ? credit.lender : bank.shortLabel;
    byLender[key] = (byLender[key] ?? 0) + balance;
    colorByLender.putIfAbsent(key, () {
      final hex = bank.accentColor.replaceFirst('#', '');
      final full = hex.length == 6 ? 'FF$hex' : hex;
      return Color(int.parse(full, radix: 16));
    });
  }

  final entries = byLender.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return [
    for (final e in entries)
      _LenderSlice(label: e.key, amount: e.value, color: colorByLender[e.key]!),
  ];
}

class _LenderDistributionChart extends StatelessWidget {
  final List<Credit> credits;
  const _LenderDistributionChart({required this.credits});

  static final _currency = NumberFormatLike();

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final slices = _distributionByLender(credits);
    final total = slices.fold<double>(0, (s, e) => s + e.amount);

    if (slices.isEmpty || total <= 0) {
      return const _InlineEmptyCard(
        text: 'No hay deuda pendiente para distribuir.',
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 44,
              sections: [
                for (final s in slices)
                  PieChartSectionData(
                    value: s.amount,
                    color: s.color,
                    title: '${(s.amount / total * 100).round()}%',
                    radius: 46,
                    titleStyle: const TextStyle(
                      fontSize: KreditTextSize.caption,
                      fontWeight: FontWeight.bold,
                      color: Colors
                          .white, // Bug 1: always legible on vivid slice colors
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final s in slices)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: s.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${s.label} · ${(s.amount / total * 100).round()}% · '
                    '${_currency.format(s.amount)}',
                    style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textSecondary),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _PayoffEntry {
  final String name;
  final DateTime endDate;
  final int monthsFromNow;
  const _PayoffEntry({
    required this.name,
    required this.endDate,
    required this.monthsFromNow,
  });
}

List<_PayoffEntry> _payoffProjections(List<Credit> credits) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final entries = <_PayoffEntry>[];

  for (final credit in credits) {
    if (credit is! LoanCredit) continue;
    final unpaid = credit.installments.where((i) => !i.paid).toList();
    if (unpaid.isEmpty) continue;
    final lastDue = unpaid
        .map((i) => parseDateStr(i.dueDate))
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final months = ((lastDue.difference(today).inDays) / 30).ceil();
    entries.add(
      _PayoffEntry(
        name: credit.name,
        endDate: lastDue,
        monthsFromNow: months < 0 ? 0 : months,
      ),
    );
  }

  entries.sort((a, b) => a.endDate.compareTo(b.endDate));
  return entries;
}

class _PayoffProjectionList extends StatelessWidget {
  final List<Credit> credits;
  const _PayoffProjectionList({required this.credits});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final entries = _payoffProjections(credits);

    if (entries.isEmpty) {
      return const _InlineEmptyCard(
        text: 'No hay créditos con cuotas pendientes.',
      );
    }

    return Column(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) Divider(height: 1, color: kredit.borderCard),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.event_available_outlined,
                  size: KreditIconSize.small,
                  color: kredit.textSecondary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entries[i].name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: KreditTextSize.body,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entries[i].monthsFromNow <= 0
                            ? 'Termina este mes'
                            : 'Termina en ${entries[i].monthsFromNow} mes${entries[i].monthsFromNow == 1 ? '' : 'es'}',
                        style: TextStyle(
                          fontSize: KreditTextSize.caption,
                          color: kredit.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  formatDate(toDateStr(entries[i].endDate)),
                  style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Historial real de abonos extra (Hallazgo B)
// ─────────────────────────────────────────────────────────────────────────────

class _AbonosHistorySummary extends StatelessWidget {
  final List<Credit> credits;
  const _AbonosHistorySummary({required this.credits});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormatLike();

    int abonoCount = 0;
    double abonoTotal = 0;
    int installmentsAdvanced = 0;

    for (final c in credits) {
      if (c is! LoanCredit) continue;
      for (final abono in c.abonos) {
        abonoCount++;
        abonoTotal += abono.amount;
        installmentsAdvanced += abono.installmentsSkipped;
      }
    }

    if (abonoCount == 0) {
      return const _InlineEmptyCard(
        text:
            'Aún no has registrado abonos extra. Cuando abones desde el '
            'simulador o desde el detalle de un préstamo, aquí verás el '
            'impacto real de esos abonos.',
      );
    }

    final kredit = Theme.of(context).extension<KreditColors>()!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _StatColumn(
            label: 'Abonos realizados',
            value: '$abonoCount',
          ),
        ),
        Container(
          width: 1,
          height: 34,
          margin: const EdgeInsets.symmetric(horizontal: 18),
          color: kredit.borderCard,
        ),
        Expanded(
          child: _StatColumn(
            label: 'Adelantos',
            value: '$installmentsAdvanced',
          ),
        ),
        Container(
          width: 1,
          height: 34,
          margin: const EdgeInsets.symmetric(horizontal: 18),
          color: kredit.borderCard,
        ),
        Expanded(
          child: _StatColumn(
            label: 'Suma abonada',
            value: fmt.format(abonoTotal),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Simulator entry card
// ─────────────────────────────────────────────────────────────────────────────

class _SimulatorEntryCard extends StatelessWidget {
  final List<Credit> credits;
  const _SimulatorEntryCard({required this.credits});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () => openSimulatorSheet(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.calculate_outlined, color: accent, size: KreditIconSize.small),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿Qué pasa si…?',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: KreditTextSize.body,
                      color: kredit.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Simula una compra en cuotas o un abono extra a capital',
                    style: TextStyle(
                      fontSize: KreditTextSize.caption,
                      color: kredit.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: kredit.textTertiary, size: KreditIconSize.small),
          ],
        ),
      ),
    );
  }
}
