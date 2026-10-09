import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/card_movement.dart';
import '../../data/models/credit.dart';
import '../../providers/credits_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/credit_display_utils.dart';

// ─── Categoría helpers ────────────────────────────────────────────────────────

const _knownCategories = [
  'alimentación',
  'transporte',
  'salud',
  'ropa',
  'entretenimiento',
  'servicios',
  'viajes',
  'otro',
];

const _categoryColors = <String, Color>{
  'alimentación':    Color(0xFFF97316), // naranja
  'transporte':      Color(0xFF38B6FF), // azul
  'salud':           Color(0xFF10B981), // verde
  'ropa':            Color(0xFFEC4899), // rosa
  'entretenimiento': Color(0xFFA855F7), // púrpura
  'servicios':       Color(0xFF06B6D4), // cian
  'viajes':          Color(0xFFEAB308), // dorado
  'otro':            Color(0xFF6B7280), // gris
  'sin categoría':   Color(0xFF374151), // gris oscuro
};

const _categoryIcons = <String, IconData>{
  'alimentación':    Icons.restaurant_outlined,
  'transporte':      Icons.directions_bus_outlined,
  'salud':           Icons.health_and_safety_outlined,
  'ropa':            Icons.checkroom_outlined,
  'entretenimiento': Icons.movie_outlined,
  'servicios':       Icons.receipt_outlined,
  'viajes':          Icons.flight_outlined,
  'otro':            Icons.category_outlined,
  'sin categoría':   Icons.category_outlined,
};

Color _colorFor(String cat) =>
    _categoryColors[cat] ?? const Color(0xFF6B7280);

IconData _iconFor(String cat) =>
    _categoryIcons[cat] ?? Icons.category_outlined;

String _normalize(String? raw) {
  if (raw == null || raw.trim().isEmpty) return 'sin categoría';
  final v = raw.trim().toLowerCase();
  return _knownCategories.contains(v) ? v : 'otro';
}

// ─── Período ─────────────────────────────────────────────────────────────────

enum _Period { lastMonth, last3Months, all }

extension _PeriodLabel on _Period {
  String get label {
    switch (this) {
      case _Period.lastMonth:    return 'Último mes';
      case _Period.last3Months:  return 'Últimos 3 meses';
      case _Period.all:          return 'Todo';
    }
  }
}

// ─── Modelo de slice ──────────────────────────────────────────────────────────

class _CategorySlice {
  final String category;
  final double total;
  final List<_MovEntry> movements;

  const _CategorySlice({
    required this.category,
    required this.total,
    required this.movements,
  });
}

class _MovEntry {
  final String creditName;
  final double amount;
  final String date;

  const _MovEntry({
    required this.creditName,
    required this.amount,
    required this.date,
  });
}

// ─── Pantalla ─────────────────────────────────────────────────────────────────

class SpendingBreakdownScreen extends ConsumerStatefulWidget {
  const SpendingBreakdownScreen({super.key});

  @override
  ConsumerState<SpendingBreakdownScreen> createState() =>
      _SpendingBreakdownScreenState();
}

class _SpendingBreakdownScreenState
    extends ConsumerState<SpendingBreakdownScreen> {
  _Period _period = _Period.lastMonth;
  int? _touchedIndex;

  List<_CategorySlice> _buildSlices(List<Credit> credits) {
    final cutoff = _cutoffDate();
    final Map<String, double> totals = {};
    final Map<String, List<_MovEntry>> entries = {};

    for (final c in credits) {
      if (c is! CardCredit) continue;
      for (final m in c.movements) {
        if (m.type != CardMovementType.charge) continue;
        if (cutoff != null && m.date.compareTo(cutoff) < 0) continue;
        final cat = _normalize(m.categoria);
        totals[cat] = (totals[cat] ?? 0) + m.amount;
        (entries[cat] ??= []).add(_MovEntry(
          creditName: c.name,
          amount: m.amount,
          date: m.date,
        ));
      }
    }

    final slices = totals.entries
        .map((e) => _CategorySlice(
              category: e.key,
              total: e.value,
              movements: (entries[e.key] ?? [])
                ..sort((a, b) => b.date.compareTo(a.date)),
            ))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    return slices;
  }

  String? _cutoffDate() {
    final now = DateTime.now();
    switch (_period) {
      case _Period.lastMonth:
        final d = DateTime(now.year, now.month - 1, now.day);
        return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      case _Period.last3Months:
        final d = DateTime(now.year, now.month - 3, now.day);
        return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      case _Period.all:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final creditsAsync = ref.watch(creditsProvider);
    final kredit = Theme.of(context).extension<KreditColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Gastos por categoría')),
      body: creditsAsync.when(
        data: (credits) {
          final slices = _buildSlices(credits);
          final grandTotal = slices.fold<double>(0, (s, e) => s + e.total);

          return ListView(
            padding: const EdgeInsets.all(KreditSpacing.card),
            children: [
              // Selector de período
              _PeriodChips(
                current: _period,
                onChanged: (p) => setState(() {
                  _period = p;
                  _touchedIndex = null;
                }),
              ),
              const SizedBox(height: 20),

              if (slices.isEmpty)
                _EmptyState()
              else ...[
                // PieChart
                _PieSection(
                  slices: slices,
                  grandTotal: grandTotal,
                  touchedIndex: _touchedIndex,
                  onTouch: (i) => setState(() =>
                      _touchedIndex = _touchedIndex == i ? null : i),
                ),
                const SizedBox(height: 24),

                // Leyenda + detalle
                ...slices.asMap().entries.map((e) {
                  final idx = e.key;
                  final slice = e.value;
                  final pct = grandTotal > 0
                      ? (slice.total / grandTotal * 100).round()
                      : 0;
                  final isSelected = _touchedIndex == idx;
                  return _CategoryTile(
                    slice: slice,
                    pct: pct,
                    isSelected: isSelected,
                    onTap: () => setState(() =>
                        _touchedIndex = isSelected ? null : idx),
                    kredit: kredit,
                  );
                }),
                const SizedBox(height: 16),

                // Detalle de la categoría seleccionada
                if (_touchedIndex != null &&
                    _touchedIndex! < slices.length)
                  _DetailCard(
                    slice: slices[_touchedIndex!],
                    kredit: kredit,
                  ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error al cargar gastos.',
            style: TextStyle(color: Theme.of(context).extension<KreditColors>()!.textSecondary),
          ),
        ),
      ),
    );
  }
}

// ─── Chips de período ─────────────────────────────────────────────────────────

class _PeriodChips extends StatelessWidget {
  final _Period current;
  final ValueChanged<_Period> onChanged;

  const _PeriodChips({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: _Period.values.map((p) {
        final selected = p == current;
        return ChoiceChip(
          label: Text(p.label),
          selected: selected,
          onSelected: (_) => onChanged(p),
        );
      }).toList(),
    );
  }
}

// ─── PieChart ────────────────────────────────────────────────────────────────

class _PieSection extends StatelessWidget {
  final List<_CategorySlice> slices;
  final double grandTotal;
  final int? touchedIndex;
  final ValueChanged<int> onTouch;

  const _PieSection({
    required this.slices,
    required this.grandTotal,
    required this.touchedIndex,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final sections = slices.asMap().entries.map((e) {
      final idx = e.key;
      final slice = e.value;
      final isTouched = touchedIndex == idx;
      final pct = grandTotal > 0 ? slice.total / grandTotal * 100 : 0.0;
      final color = _colorFor(slice.category);
      return PieChartSectionData(
        value: slice.total,
        color: color,
        radius: isTouched ? 80 : 65,
        title: pct >= 8 ? '${pct.round()}%' : '',
        titleStyle: const TextStyle(
          fontSize: KreditTextSize.body,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
        badgeWidget: null,
      );
    }).toList();

    return RepaintBoundary(
      child: SizedBox(
        height: 260,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                sections: sections,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    if (!event.isInterestedForInteractions) return;
                    final i = response?.touchedSection?.touchedSectionIndex;
                    if (i != null && i >= 0) onTouch(i);
                  },
                ),
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                borderData: FlBorderData(show: false),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TOTAL',
                  style: TextStyle(
                    fontSize: KreditTextSize.body,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: kredit.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatCOP(grandTotal),
                  style: TextStyle(
                    fontSize: KreditTextSize.heading,
                    fontWeight: FontWeight.w800,
                    color: kredit.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tile de categoría ────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  final _CategorySlice slice;
  final int pct;
  final bool isSelected;
  final VoidCallback onTap;
  final KreditColors kredit;

  const _CategoryTile({
    required this.slice,
    required this.pct,
    required this.isSelected,
    required this.onTap,
    required this.kredit,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(slice.category);
    final icon = _iconFor(slice.category);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KreditRadius.tile),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.10)
              : kredit.bgCard,
          borderRadius: BorderRadius.circular(KreditRadius.tile),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.40) : kredit.borderCard,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: KreditIconSize.small, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _capitalize(slice.category),
                style: TextStyle(
                  fontSize: KreditTextSize.body,
                  fontWeight: FontWeight.w600,
                  color: kredit.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatCOP(slice.total),
              style: TextStyle(
                fontSize: KreditTextSize.body,
                fontWeight: FontWeight.w700,
                color: kredit.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 36,
              child: Text(
                '$pct%',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: KreditTextSize.body,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Detalle expandido ────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final _CategorySlice slice;
  final KreditColors kredit;

  const _DetailCard({required this.slice, required this.kredit});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(slice.category);
    final movs = slice.movements.take(20).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kredit.bgCard,
        borderRadius: BorderRadius.circular(KreditRadius.card),
        border: Border.all(color: kredit.borderCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Text(
              'Movimientos — ${_capitalize(slice.category)}',
              style: TextStyle(
                fontSize: KreditTextSize.body,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const Divider(height: 1),
          ...movs.asMap().entries.map((e) {
            final idx = e.key;
            final m = e.value;
            return Column(
              children: [
                if (idx > 0)
                  Divider(height: 1, color: kredit.borderCard),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.creditName,
                              style: TextStyle(
                                fontSize: KreditTextSize.body,
                                fontWeight: FontWeight.w600,
                                color: kredit.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _fmtDate(m.date),
                              style: TextStyle(
                                fontSize: KreditTextSize.caption,
                                color: kredit.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatCOP(m.amount),
                        style: TextStyle(
                          fontSize: KreditTextSize.body,
                          fontWeight: FontWeight.w700,
                          color: kredit.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
          if (slice.movements.length > 20)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                '+${slice.movements.length - 20} más',
                style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
              ),
            ),
        ],
      ),
    );
  }

  String _fmtDate(String d) {
    // "YYYY-MM-DD" → "DD/MM/YYYY"
    final parts = d.split('-');
    if (parts.length != 3) return d;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pie_chart_outline, size: KreditIconSize.large, color: kredit.textTertiary),
          const SizedBox(height: 16),
          Text(
            'Sin gastos categorizados',
            style: TextStyle(
              fontSize: KreditTextSize.heading,
              fontWeight: FontWeight.bold,
              color: kredit.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Registra categorías al añadir movimientos de tarjeta.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
