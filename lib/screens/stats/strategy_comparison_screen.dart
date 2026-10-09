import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/credit.dart';
import '../../domain/debt_attack_simulator.dart';
import '../../providers/credits_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/credit_display_utils.dart';

class StrategyComparisonScreen extends ConsumerStatefulWidget {
  const StrategyComparisonScreen({super.key});

  @override
  ConsumerState<StrategyComparisonScreen> createState() =>
      _StrategyComparisonScreenState();
}

class _StrategyComparisonScreenState
    extends ConsumerState<StrategyComparisonScreen> {
  double _extra = 0;
  final _extraCtrl = TextEditingController(text: '0');
  Map<AttackStrategy, AttackPlanResult>? _results;

  @override
  void dispose() {
    _extraCtrl.dispose();
    super.dispose();
  }

  void _recalculate(List<Credit> credits) {
    final r = simulateAllStrategies(credits, extraMonthlyPayment: _extra);
    setState(() => _results = r);
  }

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    final credits = ref.watch(creditsProvider).value ?? <Credit>[];

    if (_results == null && credits.isNotEmpty) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _recalculate(credits));
    }

    final minimumsResult = _results?[AttackStrategy.minimums];
    final snowballResult = _results?[AttackStrategy.snowball];
    final avalancheResult = _results?[AttackStrategy.avalanche];

    return Scaffold(
      appBar: AppBar(title: const Text('Comparar estrategias')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.card),
        children: [
          Text(
            'Compara cuánto pagas y cuándo terminas con cada estrategia aplicando el mismo monto extra mensual.',
            style: TextStyle(
                fontSize: AppTextSize.body, color: kredit.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _extraCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: false),
            decoration: InputDecoration(
              prefixText: '\$ ',
              hintText: '0',
              labelText: 'Pago extra mensual',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.tile),
              ),
            ),
            onChanged: (v) {
              final parsed = double.tryParse(
                      v.replaceAll('.', '').replaceAll(',', '')) ??
                  0;
              if (parsed != _extra) {
                _extra = parsed;
                _recalculate(credits);
              }
            },
          ),
          const SizedBox(height: 24),

          if (_results == null || minimumsResult == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Sin deudas activas para comparar.',
                  style: TextStyle(
                      fontSize: AppTextSize.body,
                      color: kredit.textTertiary),
                ),
              ),
            )
          else ...[
            // Chart
            _ComparisonChart(
              minimums: minimumsResult,
              snowball: snowballResult!,
              avalanche: avalancheResult!,
              kredit: kredit,
              accent: accent,
            ),
            const SizedBox(height: 20),

            // Legend
            _Legend(
              kredit: kredit,
              accent: accent,
              credits: credits,
              extra: _extra,
            ),
            const SizedBox(height: 20),

            // Comparison table
            _ComparisonTable(
              minimums: minimumsResult,
              snowball: snowballResult,
              avalanche: avalancheResult,
              kredit: kredit,
              accent: accent,
            ),
          ],
        ],
      ),
    );
  }
}

class _ComparisonChart extends StatelessWidget {
  final AttackPlanResult minimums;
  final AttackPlanResult snowball;
  final AttackPlanResult avalanche;
  final AppThemeColors kredit;
  final Color accent;

  const _ComparisonChart({
    required this.minimums,
    required this.snowball,
    required this.avalanche,
    required this.kredit,
    required this.accent,
  });

  List<FlSpot> _spots(List<MonthlySnapshot> months) {
    return List.generate(months.length, (i) {
      return FlSpot(i.toDouble(), months[i].totalDebt / 1e6);
    });
  }

  @override
  Widget build(BuildContext context) {
    final minimumsSpots = _spots(minimums.months);
    final snowballSpots = _spots(snowball.months);
    final avalancheSpots = _spots(avalanche.months);

    final maxX = [
      minimums.months.length,
      snowball.months.length,
      avalanche.months.length,
    ].fold(0, (a, b) => a > b ? a : b).toDouble();

    final maxY = minimums.months.isNotEmpty
        ? minimums.months.first.totalDebt / 1e6 * 1.1
        : 1.0;

    final snowballColor = accent;
    final avalancheColor = kredit.success;
    final minimumsColor = kredit.textTertiary;

    return RepaintBoundary(
      child: SizedBox(
        height: 240,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: maxX,
            minY: 0,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: kredit.borderCard,
                strokeWidth: 1,
                dashArray: [3, 5],
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  getTitlesWidget: (v, _) => v == 0
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            '\$${v.toStringAsFixed(1)}M',
                            style: TextStyle(
                                fontSize: AppTextSize.caption,
                                color: kredit.textTertiary),
                          ),
                        ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: (maxX / 4).ceilToDouble().clamp(1, 999),
                  getTitlesWidget: (v, _) => Text(
                    '${v.toInt()}m',
                    style: TextStyle(
                        fontSize: AppTextSize.caption,
                        color: kredit.textTertiary),
                  ),
                ),
              ),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [
              // Minimums (grey dashed)
              LineChartBarData(
                spots: minimumsSpots,
                color: minimumsColor,
                barWidth: 2,
                dotData: const FlDotData(show: false),
                dashArray: [4, 4],
              ),
              // Snowball (accent solid)
              LineChartBarData(
                spots: snowballSpots,
                color: snowballColor,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
              ),
              // Avalanche (success/green solid)
              LineChartBarData(
                spots: avalancheSpots,
                color: avalancheColor,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final AppThemeColors kredit;
  final Color accent;
  final List<Credit> credits;
  final double extra;

  const _Legend({
    required this.kredit,
    required this.accent,
    required this.credits,
    required this.extra,
  });

  @override
  Widget build(BuildContext context) {
    AttackStrategy? recommended;
    if (credits.length >= 2) {
      try {
        paidOffTracker.clear();
        final rec = recommendStrategy(credits, extraMonthlyPayment: extra);
        paidOffTracker.clear();
        recommended = rec.recommended;
      } catch (_) {}
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(color: kredit.textTertiary, label: 'Solo mínimos', dashed: true),
        const SizedBox(width: 16),
        _LegendDot(
          color: accent,
          label: 'Snowball',
          isRecommended: recommended == AttackStrategy.snowball,
        ),
        const SizedBox(width: 16),
        _LegendDot(
          color: kredit.success,
          label: 'Avalanche',
          isRecommended: recommended == AttackStrategy.avalanche,
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;
  final bool isRecommended;

  const _LegendDot({
    required this.color,
    required this.label,
    this.dashed = false,
    this.isRecommended = false,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: dashed ? Colors.transparent : color,
            border: dashed ? Border.all(color: color, width: 1) : null,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
              fontSize: AppTextSize.body, color: kredit.textSecondary),
        ),
        if (isRecommended) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Text(
              '★ Rec.',
              style: TextStyle(
                fontSize: AppTextSize.caption,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  final AttackPlanResult minimums;
  final AttackPlanResult snowball;
  final AttackPlanResult avalanche;
  final AppThemeColors kredit;
  final Color accent;

  const _ComparisonTable({
    required this.minimums,
    required this.snowball,
    required this.avalanche,
    required this.kredit,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final monthFmt = DateFormat('MMM yyyy', 'es_CO');
    final strategies = [
      _StrategyData(
          name: 'Solo\nmínimos',
          result: minimums,
          color: kredit.textTertiary),
      _StrategyData(
          name: 'Snowball', result: snowball, color: accent),
      _StrategyData(
          name: 'Avalanche', result: avalanche, color: kredit.success),
    ];

    return Container(
      decoration: BoxDecoration(
        color: kredit.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: kredit.borderCard),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const SizedBox(width: 80),
                for (final s in strategies)
                  Expanded(
                    child: Text(
                      s.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppTextSize.body,
                        fontWeight: FontWeight.w700,
                        color: s.color,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: kredit.borderCard),
          _TableRow(
            label: 'Libre en',
            values: strategies
                .map((s) => monthFmt.format(s.result.freedomDate))
                .toList(),
            kredit: kredit,
            colors: strategies.map((s) => s.color).toList(),
          ),
          Divider(height: 1, color: kredit.borderCard),
          _TableRow(
            label: 'Meses',
            values: strategies
                .map((s) => '${s.result.months.length}')
                .toList(),
            kredit: kredit,
            colors: strategies.map((s) => s.color).toList(),
          ),
          Divider(height: 1, color: kredit.borderCard),
          _TableRow(
            label: 'Intereses',
            values: strategies
                .map((s) => formatCOP(s.result.totalInterest))
                .toList(),
            kredit: kredit,
            colors: strategies.map((s) => s.color).toList(),
          ),
          Divider(height: 1, color: kredit.borderCard),
          _TableRow(
            label: 'Total\npagado',
            values: strategies
                .map((s) => formatCOP(s.result.totalPaid))
                .toList(),
            kredit: kredit,
            colors: strategies.map((s) => s.color).toList(),
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _StrategyData {
  final String name;
  final AttackPlanResult result;
  final Color color;
  const _StrategyData(
      {required this.name, required this.result, required this.color});
}

class _TableRow extends StatelessWidget {
  final String label;
  final List<String> values;
  final AppThemeColors kredit;
  final List<Color> colors;
  final bool isLast;

  const _TableRow({
    required this.label,
    required this.values,
    required this.kredit,
    required this.colors,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 10, 12, isLast ? 12 : 10),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                  fontSize: AppTextSize.body, color: kredit.textTertiary),
            ),
          ),
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Text(
                values[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTextSize.body,
                  fontWeight: FontWeight.w700,
                  color: colors[i],
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
