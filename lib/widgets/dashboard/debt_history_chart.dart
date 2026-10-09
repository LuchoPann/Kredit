import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/debt_history_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/kredit_section_card.dart';

const _monthLabels = [
  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
];

class DebtHistoryChart extends ConsumerStatefulWidget {
  const DebtHistoryChart({super.key});

  @override
  ConsumerState<DebtHistoryChart> createState() => _DebtHistoryChartState();
}

class _DebtHistoryChartState extends ConsumerState<DebtHistoryChart> {
  int _months = 6;

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    final histAsync = ref.watch(debtHistoryProvider(_months));

    return AppSectionCard(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Evolución de deuda',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: AppTextSize.body,
                  color: kredit.textPrimary,
                ),
              ),
            ),
            for (final m in [3, 6, 12])
              _PeriodChip(
                label: '${m}m',
                selected: _months == m,
                onTap: () => setState(() => _months = m),
              ),
          ],
        ),
        const SizedBox(height: 16),
        histAsync.when(
          loading: () => const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, __) => SizedBox(
            height: 80,
            child: Center(
              child: Text(
                'No se pudo cargar el historial',
                style: TextStyle(color: kredit.textTertiary, fontSize: AppTextSize.body),
              ),
            ),
          ),
          data: (points) {
            if (points.length < 2) {
              return SizedBox(
                height: 80,
                child: Center(
                  child: Text(
                    'Agrega más créditos para ver la evolución',
                    style: TextStyle(color: kredit.textTertiary, fontSize: AppTextSize.body),
                  ),
                ),
              );
            }

            final maxY = points.fold<double>(
              0,
              (m, p) => m < p.projected ? p.projected : m,
            );
            final topY = maxY <= 0 ? 1.0 : maxY * 1.15;

            final projSpots = <FlSpot>[];
            final realSpots = <FlSpot>[];

            for (var i = 0; i < points.length; i++) {
              final p = points[i];
              projSpots.add(FlSpot(i.toDouble(), p.projected));
              if (p.real != null) {
                realSpots.add(FlSpot(i.toDouble(), p.real!));
              }
            }

            return SizedBox(
              height: 150,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: topY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: topY / 3,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: kredit.borderCard,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        getTitlesWidget: (v, _) {
                          if (v == 0) return const SizedBox.shrink();
                          final label = v >= 1000000
                              ? '${(v / 1000000).toStringAsFixed(1)}M'
                              : v >= 1000
                                  ? '${(v / 1000).toStringAsFixed(0)}K'
                                  : v.toStringAsFixed(0);
                          return Text(
                            label,
                            style: TextStyle(
                              fontSize: 9,
                              color: kredit.textTertiary,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        getTitlesWidget: (v, _) {
                          final idx = v.toInt();
                          if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                          final month = points[idx].date.month - 1;
                          return Text(
                            _monthLabels[month],
                            style: TextStyle(fontSize: 9, color: kredit.textTertiary),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    // Projected line (dashed)
                    LineChartBarData(
                      spots: projSpots,
                      isCurved: true,
                      color: accent.withValues(alpha: 0.45),
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      dashArray: [5, 4],
                      belowBarData: BarAreaData(
                        show: true,
                        color: accent.withValues(alpha: 0.06),
                      ),
                    ),
                    // Real line (solid) — only if there is data
                    if (realSpots.isNotEmpty)
                      LineChartBarData(
                        spots: realSpots,
                        isCurved: true,
                        color: kredit.success,
                        barWidth: 2.5,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                            radius: 3,
                            color: kredit.success,
                            strokeWidth: 0,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _Legend(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.45), label: 'Proyectado', dashed: true),
            const SizedBox(width: 16),
            _Legend(color: Theme.of(context).extension<AppThemeColors>()!.success, label: 'Real registrado'),
          ],
        ),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(
            color: selected ? accent : kredit.borderCard,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppTextSize.body,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? accent : kredit.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;

  const _Legend({required this.color, required this.label, this.dashed = false});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20,
          height: 2,
          child: CustomPaint(
            painter: _LinePainter(color: color, dashed: dashed),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: AppTextSize.body, color: kredit.textTertiary),
        ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  final Color color;
  final bool dashed;

  const _LinePainter({required this.color, required this.dashed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    if (!dashed) {
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
      return;
    }
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, size.height / 2), Offset((x + 4).clamp(0, size.width), size.height / 2), paint);
      x += 7;
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.color != color || old.dashed != dashed;
}
