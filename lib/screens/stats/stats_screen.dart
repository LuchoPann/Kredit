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
      body: creditsAsync.when(
        data: (credits) {
          if (credits.isEmpty) return const _EmptyState();
          if (statsData == null) return const _LoadingState();
          return ListView(
            padding: const EdgeInsets.all(KreditSpacing.card),
            children: [
              _DebtOverviewPanel(
                totalOwed: statsData.totalOwed,
                totalLimit: statsData.totalLimit,
                activeCount: statsData.activeCount,
                totalPaidHistorico: statsData.totalPaidHistorico,
                progressPct: statsData.progressPct,
                risks: statsData.risks,
              ),
              const SizedBox(height: 30),

              // Grupo 1 · Proyecciones: los dos visuales que responden
              // "¿cómo evoluciona mi deuda?" — el de barras va primero y más
              // grande por ser el más accionable (próximos 6 meses), el de
              // torta lo acompaña más compacto como su complemento.
              _GroupLabel(text: 'PROYECCIONES'),
              const SizedBox(height: 12),
              KreditSectionCard(
                children: [
                  _statsSectionHeader(
                    context,
                    Icons.show_chart_outlined,
                    'Deuda proyectada por mes',
                    subtitle: 'Próximos 6 meses, según cuotas y saldos vigentes',
                  ),
                  const SizedBox(height: 12),
                  _MonthlyDebtChart(data: statsData.monthlyProjection),
                  _InsightLine(text: statsData.monthlyDebtInsight),
                ],
              ),
              const SizedBox(height: 16),
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
                  _LenderDistributionChart(slices: statsData.distribution, compact: true),
                  _InsightLine(text: statsData.lenderDistributionInsight),
                ],
              ),
              const SizedBox(height: 30),

              // Grupo 2 · Historial y herramientas: lo que ya pasó (abonos),
              // lo que se viene (fechas de fin de pago) y un acceso rápido al
              // simulador — este último no es un panel de datos, es una
              // acción de navegación, así que va como fila simple con
              // chevron en vez de otra tarjeta idéntica a las anteriores.
              if (statsData.risks.isNotEmpty) ...[
                _GroupLabel(text: 'RIESGOS DETECTADOS'),
                const SizedBox(height: 12),
                KreditSectionCard(
                  children: [
                    for (final risk in statsData.risks) _RiskRow(risk: risk),
                  ],
                ),
                const SizedBox(height: 30),
              ],
              _GroupLabel(text: 'HISTORIAL Y HERRAMIENTAS'),
              const SizedBox(height: 12),
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
                  _AbonosHistorySummary(
                    abonoCount: statsData.abonoCount,
                    abonoTotal: statsData.abonoTotal,
                    installmentsAdvanced: statsData.installmentsAdvanced,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              KreditSectionCard(
                children: [
                  _statsSectionHeader(
                    context,
                    Icons.event_available_outlined,
                    'Proyección de fin de pago',
                    subtitle: 'Cuándo terminarías de pagar cada préstamo activo',
                  ),
                  const SizedBox(height: 12),
                  _PayoffProjectionList(entries: statsData.payoffProjections),
                  _InsightLine(text: statsData.bestPrepayment),
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
  final double totalOwed;
  final double totalLimit;
  final int activeCount;
  final double totalPaidHistorico;
  final double progressPct;
  final List<FinancialRecommendation> risks;

  const _DebtOverviewPanel({
    required this.totalOwed,
    required this.totalLimit,
    required this.activeCount,
    required this.totalPaidHistorico,
    required this.progressPct,
    required this.risks,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final availableCredit = totalLimit > totalOwed ? totalLimit - totalOwed : 0.0;

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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ProgressRing(percent: progressPct, size: 68),
                // Indicador aditivo: si hay riesgos detectados (misma
                // función que ya alimenta la sección "RIESGOS DETECTADOS"
                // más abajo), un pill discreto lo adelanta aquí arriba —
                // no reemplaza esa sección, solo la anticipa visualmente.
                _RiskCountPill(risks: risks),
              ],
            ),
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
                label: 'Total pagado',
                value: formatCOP(totalPaidHistorico),
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
            Icon(Icons.warning_amber_rounded, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              '${risks.length} ${risks.length == 1 ? 'riesgo' : 'riesgos'}',
              style: TextStyle(
                fontSize: 10.5,
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
        fontSize: KreditTextSize.caption,
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

/// Gráfica de barras con proyección mensual. Recibe datos ya calculados
/// desde [statsDataProvider] — no llama ninguna función de cómputo en build().
/// [RepaintBoundary] aísla el CustomPainter de fl_chart del árbol de widgets
/// padre para que sus redraws (animación, tooltip) no invaliden la pantalla.
class _MonthlyDebtChart extends StatelessWidget {
  final Map<MonthKey, double> data;
  // maxY pre-computado fuera de build() — evita fold por cada rebuild del tema/layout.
  final double maxY;

  _MonthlyDebtChart({required this.data})
      : maxY = data.values.fold(0, (m, v) => v > m ? v : m);

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
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      formatCOP(rod.toY),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: KreditIconSize.small, color: kredit.warning),
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
                  style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
      child: Text(
        text!,
        style: TextStyle(
          fontSize: KreditTextSize.caption,
          color: kredit.textSecondary,
          height: 1.4,
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

/// Gráfica de torta con distribución por entidad. Recibe slices pre-computadas
/// desde [statsDataProvider]. [RepaintBoundary] aísla el CustomPainter de
/// fl_chart del árbol padre para que sus redraws no invaliden la pantalla.
class _LenderDistributionChart extends StatelessWidget {
  final List<LenderSlice> slices;
  final bool compact;
  // total pre-computado fuera de build().
  final double total;

  _LenderDistributionChart({required this.slices, this.compact = false})
      : total = slices.fold(0, (s, e) => s + e.amount);

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;

    if (slices.isEmpty || total <= 0) {
      return const _InlineEmptyCard(
        text: 'No hay deuda pendiente para distribuir.',
      );
    }

    return Column(
      children: [
        RepaintBoundary(
          child: SizedBox(
            height: compact ? 160 : 180,
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
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
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
                    '${formatCOP(s.amount)}',
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

/// Lista de proyecciones de fin de pago. Recibe entradas pre-computadas
/// desde [statsDataProvider] — solo convierte [DateTime] a texto con
/// [toDateStr] + [formatDate], que son operaciones O(1).
class _PayoffProjectionList extends StatelessWidget {
  final List<PayoffEntry> entries;
  const _PayoffProjectionList({required this.entries});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;

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
// Historial real de abonos extra
// ─────────────────────────────────────────────────────────────────────────────

/// Resumen de abonos extra. Recibe valores pre-computados desde
/// [statsDataProvider] — no itera créditos en build().
class _AbonosHistorySummary extends StatelessWidget {
  final int abonoCount;
  final double abonoTotal;
  final int installmentsAdvanced;

  const _AbonosHistorySummary({
    required this.abonoCount,
    required this.abonoTotal,
    required this.installmentsAdvanced,
  });

  @override
  Widget build(BuildContext context) {
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
            value: formatCOP(abonoTotal),
          ),
        ),
      ],
    );
  }
}
