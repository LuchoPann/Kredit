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
import '../../widgets/account/stats_grid.dart';
import 'simulator_sheet.dart';

const _monthsEs = [
  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
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
              StatsGrid(credits: credits),
              const SizedBox(height: 24),
              _ActionableMetricsSummary(credits: credits),
              const SizedBox(height: 24),
              _statsSectionHeader(
                context,
                Icons.show_chart_outlined,
                'Deuda proyectada por mes',
                subtitle: 'Próximos 6 meses, según cuotas y saldos vigentes',
              ),
              const SizedBox(height: 12),
              _MonthlyDebtChart(credits: credits),
              const SizedBox(height: 28),
              _statsSectionHeader(
                context,
                Icons.donut_small_outlined,
                'Distribución por entidad',
                subtitle: 'Proporción de tu deuda pendiente por banco o entidad',
              ),
              const SizedBox(height: 12),
              _LenderDistributionChart(credits: credits),
              const SizedBox(height: 28),
              _statsSectionHeader(
                context,
                Icons.event_available_outlined,
                'Proyección de fin de pago',
                subtitle: 'Cuándo terminarías de pagar cada préstamo activo',
              ),
              const SizedBox(height: 12),
              _PayoffProjectionList(credits: credits),
              const SizedBox(height: 28),
              _statsSectionHeader(
                context,
                Icons.calculate_outlined,
                'Simulador Financiero',
                subtitle: '¿Qué pasaría si hago una compra o abono extra?',
              ),
              const SizedBox(height: 12),
              _SimulatorEntryCard(credits: credits),
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

class _ActionableMetricsSummary extends StatelessWidget {
  final List<Credit> credits;
  const _ActionableMetricsSummary({required this.credits});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    double totalOwed = 0;
    double totalLimit = 0;
    int activeCount = 0;

    for (final c in credits) {
      if (c is LoanCredit) {
        final unpaid = c.installments.where((i) => !i.paid).fold(0.0, (sum, i) => sum + i.amount);
        totalOwed += unpaid;
        if (unpaid > 0) activeCount++;
      } else if (c is CardCredit) {
        totalOwed += c.currentBalance;
        totalLimit += c.creditLimit;
        if (c.currentBalance > 0) activeCount++;
      }
    }

    final availableCredit = totalLimit > totalOwed ? totalLimit - totalOwed : 0.0;
    final fmt = NumberFormatLike(); // Bug 4: thousands-separator formatter

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Deuda Activa Total',
                value: fmt.format(totalOwed),
                subtext: '$activeCount créditos vigentes',
                color: colorScheme.error,
                icon: Icons.account_balance_wallet_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'Cupo Disponible (Tarjetas)',
                value: fmt.format(availableCredit),
                subtext: 'Límite total ${fmt.format(totalLimit)}',
                color: colorScheme.primary,
                icon: Icons.credit_card_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtext;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.subtext,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Container(
      padding: const EdgeInsets.all(KreditSpacing.tile),
      decoration: BoxDecoration(
        color: kredit.bgCard,
        borderRadius: BorderRadius.circular(KreditRadius.card),
        border: Border.all(color: kredit.borderCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(fontSize: 11, color: kredit.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kredit.textPrimary)),
          const SizedBox(height: 2),
          Text(subtext, style: TextStyle(fontSize: 10, color: kredit.textTertiary)),
        ],
      ),
    );
  }
}

Widget _statsSectionHeader(BuildContext context, IconData icon, String title, {String? subtitle}) {
  final kredit = Theme.of(context).extension<KreditColors>()!;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 18, color: kredit.textSecondary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
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
          child: Text(subtitle, style: TextStyle(fontSize: 12, color: kredit.textTertiary)),
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
            Icon(Icons.error_outline, size: 48, color: kredit.textTertiary),
            const SizedBox(height: 16),
            Text(
              message,
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
            Icon(Icons.bar_chart_outlined, size: 56, color: kredit.textTertiary),
            const SizedBox(height: 16),
            Text(
              'Sin datos para graficar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kredit.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega créditos para ver tus estadísticas de deuda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: kredit.textTertiary),
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
Map<_MonthKey, double> _projectMonthlyDebt(List<Credit> credits, {int monthsAhead = 6}) {
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
      return const _InlineEmptyCard(text: 'No hay cuotas ni saldos próximos por proyectar.');
    }

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 20, 16),
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
                      TextStyle(color: kredit.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= entries.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          entries[idx].key.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10, color: kredit.textTertiary),
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
                        color: accent,
                        width: 18,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  ),
              ],
            ),
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
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(KreditSpacing.card),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: kredit.textTertiary, fontSize: 13),
        ),
      ),
    );
  }
}

class _LenderSlice {
  final String label;
  final double amount;
  final Color color;
  const _LenderSlice({required this.label, required this.amount, required this.color});
}

List<_LenderSlice> _distributionByLender(List<Credit> credits) {
  final byLender = <String, double>{};
  final colorByLender = <String, Color>{};

  for (final credit in credits) {
    final balance = getCreditRemainingBalance(credit);
    if (balance <= 0) continue;
    final bank = detectBank(lender: credit.lender, card: credit is LoanCredit ? credit.card : null);
    final key = bank.shortLabel.isEmpty ? credit.lender : bank.shortLabel;
    byLender[key] = (byLender[key] ?? 0) + balance;
    colorByLender.putIfAbsent(key, () {
      final hex = bank.accentColor.replaceFirst('#', '');
      final full = hex.length == 6 ? 'FF$hex' : hex;
      return Color(int.parse(full, radix: 16));
    });
  }

  final entries = byLender.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
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
      return const _InlineEmptyCard(text: 'No hay deuda pendiente para distribuir.');
    }

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(KreditSpacing.card),
        child: Column(
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
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Bug 1: always legible on vivid slice colors
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
                        decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${s.label} · ${_currency.format(s.amount)}',
                        style: TextStyle(fontSize: 12, color: kredit.textSecondary),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PayoffEntry {
  final String name;
  final DateTime endDate;
  final int monthsFromNow;
  const _PayoffEntry({required this.name, required this.endDate, required this.monthsFromNow});
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
    entries.add(_PayoffEntry(
      name: credit.name,
      endDate: lastDue,
      monthsFromNow: months < 0 ? 0 : months,
    ));
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
      return const _InlineEmptyCard(text: 'No hay créditos con cuotas pendientes.');
    }

    return Card(
      elevation: 0,
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            ListTile(
              // Bug 3: explicit KreditColors tokens for consistent theming
              leading: Icon(Icons.event_available_outlined, color: kredit.textSecondary),
              title: Text(entries[i].name, style: TextStyle(color: kredit.textPrimary, fontWeight: FontWeight.w600)),
              subtitle: Text(
                entries[i].monthsFromNow <= 0
                    ? 'Termina este mes'
                    : 'Termina en ${entries[i].monthsFromNow} mes${entries[i].monthsFromNow == 1 ? '' : 'es'}',
                style: TextStyle(color: kredit.textSecondary, fontSize: 12),
              ),
              trailing: Text(
                formatDate(toDateStr(entries[i].endDate)),
                style: TextStyle(fontSize: 12, color: kredit.textTertiary),
              ),
            ),
          ],
        ],
      ),
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

    return Card(
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => openSimulatorSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(KreditSpacing.tile),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.calculate_outlined, color: accent, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Qué pasa si…?',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: kredit.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Simula una compra en cuotas o un abono extra a capital',
                      style: TextStyle(
                        fontSize: 12,
                        color: kredit.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: kredit.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
