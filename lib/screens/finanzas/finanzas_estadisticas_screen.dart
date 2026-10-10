import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krezium/data/finance_categories_catalog.dart';
import 'package:krezium/data/models/finance_models.dart';
import 'package:krezium/providers/database_provider.dart';
import 'package:krezium/providers/finance_provider.dart';
import 'package:krezium/theme/app_theme.dart';

// ─── Color helpers ─────────────────────────────────────────────────────────────

Color _colorFromHex(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

const _kIngresos = Color(0xFF22C55E);
const _kGastos = Color(0xFFEF4444);
const _kPieColors = [
  Color(0xFFEF4444),
  Color(0xFFF97316),
  Color(0xFFEAB308),
  Color(0xFF22C55E),
  Color(0xFF3B82F6),
  Color(0xFF8B5CF6),
  Color(0xFF6B7280),
];

const _kMesesCortos = [
  '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
];

// ─── Período ───────────────────────────────────────────────────────────────────

enum _Periodo { esteMes, tresMeses, seisMeses, esteAnio }

extension _PeriodoLabel on _Periodo {
  String get label {
    switch (this) {
      case _Periodo.esteMes:     return 'Este mes';
      case _Periodo.tresMeses:   return '3 meses';
      case _Periodo.seisMeses:   return '6 meses';
      case _Periodo.esteAnio:    return 'Este año';
    }
  }

  bool isInRange(String fecha) {
    final now = DateTime.now();
    final parts = fecha.split('-');
    if (parts.length < 2) return false;
    final year  = int.tryParse(parts[0]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 0;
    switch (this) {
      case _Periodo.esteMes:
        return year == now.year && month == now.month;
      case _Periodo.tresMeses:
        final from = DateTime(now.year, now.month - 2);
        return DateTime(year, month).isAfter(from.subtract(const Duration(days: 1)));
      case _Periodo.seisMeses:
        final from = DateTime(now.year, now.month - 5);
        return DateTime(year, month).isAfter(from.subtract(const Duration(days: 1)));
      case _Periodo.esteAnio:
        return year == now.year;
    }
  }
}

// ─── Screen ────────────────────────────────────────────────────────────────────

class FinanzasEstadisticasScreen extends ConsumerStatefulWidget {
  final FinanceAccount? libroInicial;

  const FinanzasEstadisticasScreen({super.key, this.libroInicial});

  @override
  ConsumerState<FinanzasEstadisticasScreen> createState() =>
      _FinanzasEstadisticasScreenState();
}

class _FinanzasEstadisticasScreenState
    extends ConsumerState<FinanzasEstadisticasScreen> {
  FinanceAccount? _libroActual;
  _Periodo _periodo = _Periodo.esteMes;
  int? _touchedPieIndex;

  // All transactions for the active libro (no period filter)
  Future<List<FinanceTransaction>>? _allTxFuture;

  @override
  void initState() {
    super.initState();
    _libroActual = widget.libroInicial;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_libroActual == null) {
      final accounts = ref.read(financeAccountsProvider);
      final rows = accounts.valueOrNull;
      if (rows != null && rows.isNotEmpty) {
        _libroActual = FinanceAccount.fromRow(rows.first);
      }
    }
    _reloadTx();
  }

  void _reloadTx() {
    if (_libroActual == null) return;
    final db = ref.read(databaseProvider);
    _allTxFuture = db
        .getFinanceTransactionsByLibro(
          libroId: _libroActual!.id,
          mes: null,
          tipo: null,
        )
        .then((rows) => rows.map(FinanceTransaction.fromRow).toList());
  }

  void _changeLibro(FinanceAccount libro) {
    setState(() {
      _libroActual = libro;
      _touchedPieIndex = null;
    });
    _reloadTx();
  }

  // ─── Totales ────────────────────────────────────────────────────────────────

  ({double ingresos, double gastos, double balance}) _totales(
      List<FinanceTransaction> txs) {
    double ing = 0, gas = 0;
    for (final t in txs) {
      if (!_periodo.isInRange(t.fecha)) continue;
      if (t.tipo == 'ingreso') ing += t.monto;
      if (t.tipo == 'gasto')   gas += t.monto;
    }
    return (
      ingresos: ing,
      gastos: gas,
      balance: (_libroActual?.saldoInicial ?? 0) + ing - gas,
    );
  }

  // ─── Pie data (gastos por categoría) ────────────────────────────────────────

  List<({String catId, double monto})> _gastosPorCategoria(
      List<FinanceTransaction> txs) {
    final mapa = <String, double>{};
    for (final t in txs) {
      if (t.tipo != 'gasto') continue;
      if (!_periodo.isInRange(t.fecha)) continue;
      mapa[t.categoryId] = (mapa[t.categoryId] ?? 0) + t.monto;
    }
    final lista = mapa.entries
        .map((e) => (catId: e.key, monto: e.value))
        .toList()
      ..sort((a, b) => b.monto.compareTo(a.monto));

    if (lista.length <= 6) return lista;

    final top5 = lista.sublist(0, 6);
    final otros = lista.sublist(6).fold<double>(0, (s, e) => s + e.monto);
    return [...top5, (catId: '__otros__', monto: otros)];
  }

  // ─── Bar chart: últimos 6 meses ─────────────────────────────────────────────

  List<({int year, int month, double ingresos, double gastos})> _tendencia(
      List<FinanceTransaction> txs) {
    final now = DateTime.now();
    final result = <({int year, int month, double ingresos, double gastos})>[];

    for (int i = 5; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i);
      final prefix =
          '${d.year}-${d.month.toString().padLeft(2, '0')}';
      double ing = 0, gas = 0;
      for (final t in txs) {
        if (!t.fecha.startsWith(prefix)) continue;
        if (t.tipo == 'ingreso') ing += t.monto;
        if (t.tipo == 'gasto')   gas += t.monto;
      }
      result.add((year: d.year, month: d.month, ingresos: ing, gastos: gas));
    }
    return result;
  }

  // ─── Formato compacto ────────────────────────────────────────────────────────

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final asyncLibros = ref.watch(financeAccountsProvider);
    final asyncCats   = ref.watch(allFinanceCategoriesProvider);
    final colors      = Theme.of(context).extension<AppThemeColors>()!;

    // Auto-set libro from provider if still null (first frame after accounts load)
    if (_libroActual == null) {
      final rows = asyncLibros.valueOrNull;
      if (rows != null && rows.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _libroActual = FinanceAccount.fromRow(rows.first);
              _reloadTx();
            });
          }
        });
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final libroColor  = _colorFromHex(_libroActual!.color);

    return Scaffold(
      appBar: AppBar(
        title: asyncLibros.maybeWhen(
          data: (rows) {
            final libros = rows.map(FinanceAccount.fromRow).toList();
            return DropdownButton<String>(
              value: _libroActual!.id,
              underline: const SizedBox(),
              dropdownColor: colors.bgCard,
              icon: const Icon(Icons.arrow_drop_down),
              style: TextStyle(
                color: Theme.of(context).appBarTheme.foregroundColor ??
                    Colors.white,
                fontSize: AppTextSize.body,
                fontWeight: FontWeight.bold,
              ),
              items: libros
                  .map((l) => DropdownMenuItem(
                        value: l.id,
                        child: Text(l.nombre),
                      ))
                  .toList(),
              onChanged: (id) {
                if (id == null) return;
                final nuevo = libros.firstWhere((l) => l.id == id);
                _changeLibro(nuevo);
              },
            );
          },
          orElse: () => const Text('Estadísticas'),
        ),
        actions: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: libroColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<FinanceTransaction>>(
        future: _allTxFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final allTxs = snap.data ?? [];

          // Map categorías
          final catMap = asyncCats.valueOrNull != null
              ? {
                  for (final c in asyncCats.valueOrNull!)
                    if (c is CatalogoCategoria) c.id: c
                }
              : <String, CatalogoCategoria>{};

          final tot = _totales(allTxs);
          final pieData = _gastosPorCategoria(allTxs);
          final tendencia = _tendencia(allTxs);
          final hayDatos = pieData.isNotEmpty || tot.ingresos > 0 || tot.gastos > 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Selector período ──────────────────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _Periodo.values
                        .map((p) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(p.label),
                                selected: _periodo == p,
                                onSelected: (_) =>
                                    setState(() {
                                      _periodo = p;
                                      _touchedPieIndex = null;
                                    }),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Sección 1: Resumen cards ──────────────────────────────────
                Text(
                  'Resumen',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _ResumenCard(
                      label: 'Ingresos',
                      monto: tot.ingresos,
                      color: _kIngresos,
                      colors: colors,
                    ),
                    const SizedBox(width: 8),
                    _ResumenCard(
                      label: 'Gastos',
                      monto: tot.gastos,
                      color: _kGastos,
                      colors: colors,
                    ),
                    const SizedBox(width: 8),
                    _ResumenCard(
                      label: 'Balance',
                      monto: tot.balance,
                      color: tot.balance >= 0 ? _kIngresos : _kGastos,
                      colors: colors,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (!hayDatos) ...[
                  // ── Estado vacío ──────────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        Icon(Icons.bar_chart,
                            size: 64,
                            color: colors.textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'Sin datos para este período',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // ── Sección 2: PieChart donut ─────────────────────────────
                  if (pieData.isNotEmpty) ...[
                    Text(
                      'Gastos por categoría',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _PieDonutSection(
                      data: pieData,
                      catMap: catMap,
                      touchedIndex: _touchedPieIndex,
                      onTouch: (idx) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _touchedPieIndex =
                              _touchedPieIndex == idx ? null : idx;
                        });
                      },
                      totalGastos: pieData.fold(0, (s, e) => s + e.monto),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Sección 3: BarChart tendencia mensual ─────────────────
                  Text(
                    'Tendencia mensual',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _BarTendencia(tendencia: tendencia, fmt: _fmt),
                  const SizedBox(height: 24),
                ],

                // ── Sección 4: Balance por libros ─────────────────────────
                asyncLibros.maybeWhen(
                  data: (rows) {
                    final libros = rows.map(FinanceAccount.fromRow).toList();
                    if (libros.length <= 1) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Balance por libro',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: libros.length,
                            separatorBuilder: (ctx2, i2) =>
                                const SizedBox(width: 12),
                            itemBuilder: (ctx, i) {
                              final l = libros[i];
                              final lColor = _colorFromHex(l.color);
                              return _LibroBalanceCard(
                                libro: l,
                                libroColor: lColor,
                                colors: colors,
                                txsFuture: ref
                                    .read(databaseProvider)
                                    .getFinanceTransactionsByLibro(
                                      libroId: l.id,
                                      mes: null,
                                      tipo: null,
                                    )
                                    .then((rows) => rows
                                        .map(FinanceTransaction.fromRow)
                                        .toList()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Resumen card ─────────────────────────────────────────────────────────────

class _ResumenCard extends StatelessWidget {
  final String label;
  final double monto;
  final Color color;
  final AppThemeColors colors;

  const _ResumenCard({
    required this.label,
    required this.monto,
    required this.color,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: AppTextSize.caption,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '\$${monto.toStringAsFixed(0)}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pie donut section ────────────────────────────────────────────────────────

class _PieDonutSection extends StatelessWidget {
  final List<({String catId, double monto})> data;
  final Map<String, CatalogoCategoria> catMap;
  final int? touchedIndex;
  final ValueChanged<int> onTouch;
  final double totalGastos;

  const _PieDonutSection({
    required this.data,
    required this.catMap,
    required this.touchedIndex,
    required this.onTouch,
    required this.totalGastos,
  });

  @override
  Widget build(BuildContext context) {
    final sections = <PieChartSectionData>[];
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final isOtros = item.catId == '__otros__';
      final cat = isOtros ? null : catMap[item.catId];
      final color = _kPieColors[i % _kPieColors.length];
      final isTouched = touchedIndex == i;
      final pct = totalGastos > 0 ? item.monto / totalGastos * 100 : 0.0;
      final label = isOtros
          ? 'Otros'
          : (cat?.nombre ?? item.catId);

      sections.add(PieChartSectionData(
        value: item.monto,
        color: color,
        radius: isTouched ? 70 : 60,
        title: isTouched ? '${pct.toStringAsFixed(1)}%' : '',
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: isTouched
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$label\n\$${item.monto.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : null,
        badgePositionPercentageOffset: 1.4,
      ));
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 50,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  if (!event.isInterestedForInteractions) return;
                  final idx = response?.touchedSection?.touchedSectionIndex;
                  if (idx != null && idx >= 0) onTouch(idx);
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Leyenda
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            for (int i = 0; i < data.length; i++)
              _PieLegendItem(
                item: data[i],
                cat: data[i].catId == '__otros__'
                    ? null
                    : catMap[data[i].catId],
                color: _kPieColors[i % _kPieColors.length],
                totalGastos: totalGastos,
                isOtros: data[i].catId == '__otros__',
              ),
          ],
        ),
      ],
    );
  }
}

class _PieLegendItem extends StatelessWidget {
  final ({String catId, double monto}) item;
  final CatalogoCategoria? cat;
  final Color color;
  final double totalGastos;
  final bool isOtros;

  const _PieLegendItem({
    required this.item,
    required this.cat,
    required this.color,
    required this.totalGastos,
    required this.isOtros,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = isOtros ? 'Otros' : (cat?.nombre ?? item.catId);
    final pct = totalGastos > 0 ? item.monto / totalGastos * 100 : 0.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(
          '$nombre  \$${item.monto.toStringAsFixed(0)} (${pct.toStringAsFixed(1)}%)',
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}

// ─── Bar chart tendencia ──────────────────────────────────────────────────────

class _BarTendencia extends StatelessWidget {
  final List<({int year, int month, double ingresos, double gastos})> tendencia;
  final String Function(double) fmt;

  const _BarTendencia({required this.tendencia, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final maxVal = tendencia.fold<double>(
      0,
      (m, e) => math.max(m, math.max(e.ingresos, e.gastos)),
    );
    final maxY = maxVal == 0 ? 100.0 : (maxVal * 1.2);

    final groups = <BarChartGroupData>[];
    for (int i = 0; i < tendencia.length; i++) {
      final t = tendencia[i];
      groups.add(BarChartGroupData(
        x: i,
        groupVertically: false,
        barRods: [
          BarChartRodData(
            toY: t.ingresos,
            color: _kIngresos,
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: t.gastos,
            color: _kGastos,
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
        barsSpace: 4,
      ));
    }

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barGroups: groups,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, meta) => Text(
                  fmt(v),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= tendencia.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    _kMesesCortos[tendencia[idx].month],
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final t = tendencia[groupIndex];
                final isIng = rodIndex == 0;
                return BarTooltipItem(
                  '${_kMesesCortos[t.month]}\n'
                  '${isIng ? "Ingresos" : "Gastos"}: \$${rod.toY.toStringAsFixed(0)}',
                  TextStyle(
                    color: isIng ? _kIngresos : _kGastos,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Libro balance card ───────────────────────────────────────────────────────

class _LibroBalanceCard extends StatelessWidget {
  final FinanceAccount libro;
  final Color libroColor;
  final AppThemeColors colors;
  final Future<List<FinanceTransaction>> txsFuture;

  const _LibroBalanceCard({
    required this.libro,
    required this.libroColor,
    required this.colors,
    required this.txsFuture,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FinanceTransaction>>(
      future: txsFuture,
      builder: (ctx, snap) {
        double balance = libro.saldoInicial;
        if (snap.hasData) {
          for (final t in snap.data!) {
            if (t.tipo == 'ingreso') balance += t.monto;
            if (t.tipo == 'gasto')   balance -= t.monto;
          }
        }
        final balanceColor = balance >= 0 ? _kIngresos : _kGastos;
        return Container(
          width: 140,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: libroColor.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: libroColor.withValues(alpha: 0.2),
                    child: Text(
                      libro.nombre.isNotEmpty
                          ? libro.nombre[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                          color: libroColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      libro.nombre,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '\$${balance.toStringAsFixed(2)}',
                style: TextStyle(
                  color: balanceColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
