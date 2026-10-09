import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/date_utils.dart';
import '../../domain/recommendations.dart';
import '../../providers/credits_provider.dart';
import '../../providers/stats_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/credit_display_utils.dart';
import '../../widgets/kredit_section_card.dart';
import '../../widgets/progress_ring.dart';
import 'attack_plan_screen.dart';
import 'calculator_sheet.dart';
import 'strategy_comparison_screen.dart';

/// "Estadísticas avanzadas" screen: month-by-month debt projection, debt
/// distribution by lender, and payoff-date forecasts. Purely derived from
/// [creditsProvider] — no new persisted state.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditsAsync = ref.watch(creditsProvider);
    final statsData = ref.watch(statsDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas avanzadas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const CalculatorSheet(),
        ),
        icon: const Icon(Icons.calculate_outlined),
        label: const Text('Calcular cuota'),
      ),
      body: creditsAsync.when(
        data: (credits) {
          if (credits.isEmpty) return const _EmptyState();
          if (statsData == null) return const _LoadingState();
          return ListView(
            padding: const EdgeInsets.all(KreditSpacing.card),
            children: [
              _ResumenPanel(
                totalOwed: statsData.totalOwed,
                totalLimit: statsData.totalLimit,
                totalPaidHistorico: statsData.totalPaidHistorico,
                progressPct: statsData.progressPct,
                activeCount: statsData.activeCount,
                installmentsAdvanced: statsData.installmentsAdvanced,
                risks: statsData.risks,
              ),
              const SizedBox(height: 28),

              _GroupLabel(text: 'PROYECCIÓN'),
              const SizedBox(height: 12),
              if (statsData.payoffProjections.isNotEmpty)
                _FreedomCallout(entries: statsData.payoffProjections),
              if (statsData.payoffProjections.isNotEmpty)
                const SizedBox(height: 10),
              KreditSectionCard(
                children: [
                  _statsSectionHeader(
                    context,
                    Icons.show_chart_outlined,
                    'Cuota mensual proyectada',
                    subtitle: 'Próximos 6 meses, según cuotas y saldos vigentes',
                  ),
                  const SizedBox(height: 12),
                  _MonthlyDebtChart(
                    data: statsData.monthlyProjection,
                    breakdown: statsData.monthlyBreakdown,
                  ),
                  _InsightLine(text: statsData.monthlyDebtInsight),
                ],
              ),
              const SizedBox(height: 10),
              KreditSectionCard(
                children: [
                  _statsSectionHeader(
                    context,
                    Icons.event_available_outlined,
                    'Cuándo termina cada crédito',
                  ),
                  const SizedBox(height: 12),
                  _PayoffTimeline(entries: statsData.payoffProjections),
                ],
              ),
              const SizedBox(height: 28),

              _GroupLabel(text: 'POR ENTIDAD'),
              const SizedBox(height: 12),
              KreditSectionCard(
                children: [
                  _statsSectionHeader(
                    context,
                    Icons.donut_small_outlined,
                    'Distribución de deuda',
                    subtitle: 'Proporción pendiente por banco o entidad',
                  ),
                  const SizedBox(height: 12),
                  _LenderDistributionChart(slices: statsData.distribution, compact: true),
                  _InsightLine(text: statsData.lenderDistributionInsight),
                ],
              ),
              const SizedBox(height: 28),

              _GroupLabel(text: 'HERRAMIENTAS DE ATAQUE'),
              const SizedBox(height: 12),
              KreditSectionCard(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.bolt_rounded,
                          size: KreditIconSize.small,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    title: const Text('Plan de ataque',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Snowball o Avalanche con pago extra'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AttackPlanScreen()),
                    ),
                  ),
                  Divider(
                      height: 1,
                      color: Theme.of(context)
                          .extension<KreditColors>()!
                          .borderCard),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .extension<KreditColors>()!
                            .success
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.show_chart_rounded,
                          size: KreditIconSize.small,
                          color: Theme.of(context)
                              .extension<KreditColors>()!
                              .success),
                    ),
                    title: const Text('Comparar estrategias',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Mínimos vs Snowball vs Avalanche en una gráfica'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const StrategyComparisonScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              if (statsData.risks.isNotEmpty) ...[
                _GroupLabel(text: 'ALERTAS'),
                const SizedBox(height: 12),
                KreditSectionCard(
                  children: [
                    for (final risk in statsData.risks) _RiskRow(risk: risk),
                  ],
                ),
                const SizedBox(height: 28),
              ],
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

class _ResumenPanel extends StatelessWidget {
  final double totalOwed;
  final double totalLimit;
  final double totalPaidHistorico;
  final double progressPct;
  final int activeCount;
  final int installmentsAdvanced;
  final List<FinancialRecommendation> risks;

  const _ResumenPanel({
    required this.totalOwed,
    required this.totalLimit,
    required this.totalPaidHistorico,
    required this.progressPct,
    required this.activeCount,
    required this.installmentsAdvanced,
    required this.risks,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ProgressRing(percent: progressPct, size: 72),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL PAGADO',
                    style: TextStyle(
                      fontSize: KreditTextSize.body,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: kredit.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatCOP(totalPaidHistorico),
                    style: const TextStyle(
                      fontSize: KreditTextSize.hero,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                      height: 1.0,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Por pagar: ',
                        style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textSecondary),
                      ),
                      Text(
                        formatCOP(totalOwed),
                        style: TextStyle(
                          fontSize: KreditTextSize.body,
                          fontWeight: FontWeight.w700,
                          color: kredit.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  _RiskCountPill(risks: risks),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatChip(
                value: '$activeCount',
                label: 'Créditos\nactivos',
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatChip(
                value: '$installmentsAdvanced',
                label: 'Cuotas\nadelant.',
                color: kredit.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatChip({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: kredit.bgCard,
        borderRadius: BorderRadius.circular(KreditRadius.tile),
        border: Border.all(color: kredit.borderCard),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: KreditTextSize.emphasis,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.0,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: KreditTextSize.body,
              fontWeight: FontWeight.w500,
              color: kredit.textTertiary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Secondary metric expressed purely through typography — a mid-weight
/// value over a small-caps label, no surrounding box. Misma jerarquía que
/// `_SecondaryStat` (dashboard_screen.dart) y `_StatTile`

/// Pill discreto que adelanta cuántos riesgos hay detectados, junto al
/// anillo de progreso — se oculta por completo cuando no hay ninguno, para
/// no agregar ruido visual al caso feliz.
class _RiskCountPill extends StatelessWidget {
  final List<FinancialRecommendation> risks;
  const _RiskCountPill({required this.risks});

  @override
  Widget build(BuildContext context) {
    if (risks.isEmpty) return const SizedBox.shrink();
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final hasDanger = risks.any((r) => r.severity == RecommendationSeverity.danger);
    final color = hasDanger ? kredit.danger : kredit.warning;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(KreditRadius.chip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: KreditIconSize.micro, color: color),
            const SizedBox(width: 4),
            Text(
              '${risks.length} ${risks.length == 1 ? 'riesgo' : 'riesgos'}',
              style: TextStyle(
                fontSize: KreditTextSize.body,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Encabezado de grupo tipográfico puro — sin caja, mismo lenguaje que la
/// etiqueta "DEUDA ACTIVA TOTAL" de [_DebtOverviewPanel] — usado para separar
/// temáticamente las tarjetas de abajo y suavizar el salto de estilo entre
/// la zona superior sin caja y la zona de tarjetas.
class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Text(
      text,
      style: TextStyle(
        fontSize: KreditTextSize.body,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: kredit.textTertiary,
      ),
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
            style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
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
              style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textSecondary),
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
              style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

class _FreedomCallout extends StatelessWidget {
  final List<PayoffEntry> entries;
  const _FreedomCallout({required this.entries});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    if (entries.isEmpty) return const SizedBox.shrink();

    final latest = entries.reduce((a, b) => a.monthsFromNow > b.monthsFromNow ? a : b);
    final months = latest.monthsFromNow;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kredit.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(KreditRadius.card),
        border: Border.all(color: kredit.success.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kredit.success.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.shield_outlined, size: KreditIconSize.small, color: kredit.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LIBRE DE DEUDAS EN',
                  style: TextStyle(
                    fontSize: KreditTextSize.body,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: kredit.success,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatDate(toDateStr(latest.endDate)),
                  style: TextStyle(
                    fontSize: KreditTextSize.heading,
                    fontWeight: FontWeight.w800,
                    color: kredit.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  '· $months ${months == 1 ? 'mes' : 'meses'} desde hoy',
                  style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PayoffTimeline extends StatelessWidget {
  final List<PayoffEntry> entries;
  const _PayoffTimeline({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const _InlineEmptyCard(text: 'No hay créditos con cuotas pendientes.');
    }

    return Column(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          _TimelineRow(entry: entries[i]),
        ],
        const SizedBox(height: 14),
        _TimelineLegend(),
      ],
    );
  }
}

class _TimelineLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Row(
      children: [
        _LegendItem(color: kredit.success.withValues(alpha: 0.5), label: 'Pagado'),
        const SizedBox(width: 16),
        _LegendItem(color: kredit.textTertiary.withValues(alpha: 0.4), label: 'Pendiente'),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final PayoffEntry entry;
  const _TimelineRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final color = _payoffUrgencyColor(kredit, entry.monthsFromNow);
    final paidFraction = entry.paidFraction.clamp(0.0, 1.0);
    final remainFraction = 1.0 - paidFraction;
    final paidLabel = '${entry.paidInstallments}/${entry.totalInstallments}';
    final pct = (paidFraction * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                entry.name,
                style: const TextStyle(fontSize: KreditTextSize.body, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$paidLabel cuotas · $pct%',
              style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                if (paidFraction > 0)
                  Flexible(
                    flex: (paidFraction * 100).round().clamp(1, 99),
                    child: Container(color: kredit.success.withValues(alpha: 0.55)),
                  ),
                if (remainFraction > 0)
                  Flexible(
                    flex: (remainFraction * 100).round().clamp(1, 99),
                    child: Container(color: kredit.textTertiary.withValues(alpha: 0.25)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              'Termina ${formatDate(toDateStr(entry.endDate))}',
              style: TextStyle(fontSize: KreditTextSize.caption, color: color, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              'Resta ${formatCOP(entry.remainingAmount)}',
              style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
        ),
      ],
    );
  }
}

/// Gráfica de barras con proyección mensual. Recibe datos ya calculados
/// desde [statsDataProvider] — no llama ninguna función de cómputo en build().
/// [RepaintBoundary] aísla el CustomPainter de fl_chart del árbol de widgets
/// padre para que sus redraws (animación, tooltip) no invaliden la pantalla.
class _MonthlyDebtChart extends StatelessWidget {
  final Map<MonthKey, double> data;
  final Map<MonthKey, Map<String, double>> breakdown;
  // maxY pre-computado fuera de build() — evita fold por cada rebuild del tema/layout.
  final double maxY;

  _MonthlyDebtChart({required this.data, required this.breakdown})
      : maxY = data.values.fold(0, (m, v) => v > m ? v : m);

  String _fmtY(double v) {
    if (v >= 1e9) return '\$${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '\$${(v / 1e3).toStringAsFixed(0)}K';
    return '\$${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final entries = data.entries.toList();

    if (maxY <= 0) {
      return const _InlineEmptyCard(
        text: 'No hay cuotas ni saldos próximos por proyectar.',
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 8, 0),
      child: RepaintBoundary(
        child: SizedBox(
          height: 220,
          child: BarChart(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            BarChartData(
              maxY: maxY * 1.2,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: false,
                horizontalInterval: maxY * 1.2 / 4,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: kredit.borderCard,
                  strokeWidth: 1,
                  dashArray: [3, 5],
                ),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  maxContentWidth: 220,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final idx = group.x.toInt();
                    final monthKey = idx >= 0 && idx < entries.length
                        ? entries[idx].key
                        : null;
                    final byCredit =
                        monthKey != null ? (breakdown[monthKey] ?? {}) : {};
                    // Sort by amount descending for readability
                    final sorted = byCredit.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));
                    final lines = sorted
                        .map((e) =>
                            '${e.key.length > 14 ? '${e.key.substring(0, 12)}…' : e.key.padRight(14)}  ${formatCOP(e.value)}')
                        .join('\n');
                    final header = 'Total  ${formatCOP(rod.toY)}';
                    final body = sorted.length > 1 ? '\n$lines' : '';
                    return BarTooltipItem(
                      '$header$body',
                      TextStyle(
                        color: kredit.textPrimary,
                        fontSize: KreditTextSize.body,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SpaceGrotesk',
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 38,
                    interval: maxY * 1.2 / 4,
                    getTitlesWidget: (value, meta) {
                      if (value <= 0 || value >= maxY * 1.2 - 1) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          _fmtY(value),
                          style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
                          textAlign: TextAlign.right,
                        ),
                      );
                    },
                  ),
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
                    reservedSize: 42,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= entries.length) {
                        return const SizedBox.shrink();
                      }
                      final key = entries[idx].key;
                      final prevKey = idx > 0 ? entries[idx - 1].key : null;
                      final showYear = prevKey == null || prevKey.year != key.year;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              key.label.split('\n').first,
                              style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
                            ),
                            if (showYear)
                              Text(
                                key.label.split('\n').last,
                                style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary.withValues(alpha: 0.55)),
                              ),
                          ],
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
      ),
    );
  }
}

class _RiskRow extends StatelessWidget {
  final FinancialRecommendation risk;
  const _RiskRow({required this.risk});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final isDanger = risk.severity == RecommendationSeverity.danger;
    final isWarning = risk.severity == RecommendationSeverity.warning;
    final color = isDanger ? kredit.danger : isWarning ? kredit.warning : kredit.info;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(KreditRadius.tile),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isDanger
                  ? Icons.warning_amber_rounded
                  : isWarning
                      ? Icons.info_outline
                      : Icons.lightbulb_outline,
              size: KreditIconSize.small,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  risk.title,
                  style: TextStyle(
                    fontSize: KreditTextSize.body,
                    fontWeight: FontWeight.w700,
                    color: kredit.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  risk.description,
                  style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _payoffUrgencyColor(KreditColors kredit, int monthsFromNow) {
  if (monthsFromNow <= 6) return kredit.success;
  if (monthsFromNow <= 18) return kredit.warning;
  return kredit.textSecondary;
}

class _InsightLine extends StatelessWidget {
  final String? text;
  const _InsightLine({required this.text});

  @override
  Widget build(BuildContext context) {
    if (text == null) return const SizedBox.shrink();
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.only(left: 10, top: 4, bottom: 4),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.45),
              width: 2,
            ),
          ),
        ),
        child: Text(
          text!,
          style: TextStyle(
            fontSize: KreditTextSize.body,
            color: kredit.textSecondary,
            height: 1.4,
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
        style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
      ),
    );
  }
}

/// Distribución por entidad como barras horizontales. Recibe slices
/// pre-computadas desde [statsDataProvider].
class _LenderDistributionChart extends StatelessWidget {
  final List<LenderSlice> slices;
  final bool compact;
  final double total;

  _LenderDistributionChart({required this.slices, this.compact = false})
      : total = slices.fold(0, (s, e) => s + e.amount);

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty || total <= 0) {
      return const _InlineEmptyCard(
        text: 'No hay deuda pendiente para distribuir.',
      );
    }
    return Column(
      children: [
        for (var i = 0; i < slices.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          _LenderBar(slice: slices[i], total: total),
        ],
      ],
    );
  }
}

class _LenderBar extends StatelessWidget {
  final LenderSlice slice;
  final double total;
  const _LenderBar({required this.slice, required this.total});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final pct = (slice.amount / total * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: slice.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                slice.label,
                style: const TextStyle(
                  fontSize: KreditTextSize.body,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$pct%',
              style: TextStyle(
                fontSize: KreditTextSize.body,
                fontWeight: FontWeight.w700,
                color: slice.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: slice.amount / total,
            backgroundColor: kredit.borderCard,
            valueColor: AlwaysStoppedAnimation<Color>(slice.color),
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          formatCOP(slice.amount),
          style: TextStyle(
            fontSize: KreditTextSize.body,
            color: kredit.textTertiary,
          ),
        ),
      ],
    );
  }
}

