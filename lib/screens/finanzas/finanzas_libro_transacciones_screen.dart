import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krezium/data/finance_categories_catalog.dart';
import 'package:krezium/data/finanzas_filtros.dart';
import 'package:krezium/data/models/finance_models.dart';
import 'package:krezium/providers/database_provider.dart';
import 'package:krezium/providers/finance_provider.dart';
import 'package:krezium/screens/finanzas/nueva_transaccion_sheet.dart';
import 'package:krezium/theme/app_theme.dart';

// ─── Color helper ─────────────────────────────────────────────────────────────
Color _colorFromHex(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

// ─── Public screen ────────────────────────────────────────────────────────────
class FinanzasLibroTransaccionesScreen extends ConsumerStatefulWidget {
  final FinanceAccount libro;
  const FinanzasLibroTransaccionesScreen({
    super.key,
    required this.libro,
  });

  @override
  ConsumerState<FinanzasLibroTransaccionesScreen> createState() =>
      _FinanzasLibroTransaccionesScreenState();
}

class _FinanzasLibroTransaccionesScreenState
    extends ConsumerState<FinanzasLibroTransaccionesScreen> {
  late FinanceAccount _libroActual;
  // Offset de mes para navegación de período mensual (0 = mes actual)
  int _mesOffset = 0;

  @override
  void initState() {
    super.initState();
    _libroActual = widget.libro;
  }

  // ─── Período activo ────────────────────────────────────────────────────────

  DateTime get _mesActivo {
    final now = DateTime.now();
    return DateTime(now.year, now.month + _mesOffset);
  }

  String get _mesActivoLabel {
    const meses = [
      '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    final d = _mesActivo;
    return '${meses[d.month]} ${d.year}';
  }

  // ─── Agrupar por fecha ─────────────────────────────────────────────────────

  Map<String, List<FinanceTransaction>> _agrupar(
      List<FinanceTransaction> txs, bool ascending) {
    // Filtrar por mes si el período es mensual
    final filtros = ref.read(finanzasFiltrosProvider);
    List<FinanceTransaction> filtradas = txs;
    if (filtros.periodo == 'mensual') {
      final prefix =
          '${_mesActivo.year}-${_mesActivo.month.toString().padLeft(2, '0')}';
      filtradas = txs.where((t) => t.fecha.startsWith(prefix)).toList();
    }

    final mapa = <String, List<FinanceTransaction>>{};
    for (final tx in filtradas) {
      mapa.putIfAbsent(tx.fecha, () => []).add(tx);
    }
    // Ordenar claves
    final keys = mapa.keys.toList()
      ..sort((a, b) => ascending ? a.compareTo(b) : b.compareTo(a));
    return {for (final k in keys) k: mapa[k]!};
  }

  String _fechaLabel(String fecha) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final parts = fecha.split('-');
    if (parts.length != 3) return fecha;
    final d = DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    if (d == today) return 'Hoy';
    if (d == today.subtract(const Duration(days: 1))) return 'Ayer';
    const dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    const meses = [
      '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${dias[d.weekday - 1]} ${d.day} ${meses[d.month]}';
  }

  // ─── Totales ───────────────────────────────────────────────────────────────

  ({double ingresos, double gastos, double balance}) _totales(
      List<FinanceTransaction> txs) {
    double ing = 0, gas = 0;
    for (final t in txs) {
      if (t.tipo == 'ingreso') ing += t.monto;
      if (t.tipo == 'gasto') gas += t.monto;
    }
    return (ingresos: ing, gastos: gas, balance: ing - gas);
  }

  // ─── Filtros sheet ─────────────────────────────────────────────────────────

  void _mostrarFiltrosSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _FiltrosSheet(
        filtros: ref.read(finanzasFiltrosProvider),
        onChanged: (f) => ref.read(finanzasFiltrosProvider.notifier).state = f,
      ),
    );
  }

  // ─── Delete ────────────────────────────────────────────────────────────────

  Future<bool> _confirmarEliminar(BuildContext ctx, FinanceTransaction tx) async {
    final result = await showDialog<bool>(
      context: ctx,
      builder: (d) => AlertDialog(
        title: const Text('Eliminar transacción'),
        content: const Text('¿Seguro que deseas eliminar esta transacción?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Eliminar', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _eliminar(FinanceTransaction tx) async {
    final db = ref.read(databaseProvider);
    await db.deleteFinanceTransaction(tx.id);
    ref.invalidate(finanzasLibroTxProvider(_libroActual.id));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transacción eliminada')),
      );
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filtros = ref.watch(finanzasFiltrosProvider);
    final asyncTx = ref.watch(finanzasLibroTxProvider(_libroActual.id));
    final asyncLibros = ref.watch(financeAccountsProvider);
    final asyncCats = ref.watch(allFinanceCategoriesProvider);
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final libroColor = _colorFromHex(_libroActual.color);

    return Scaffold(
      body: asyncTx.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (txs) {
          final grupos = _agrupar(txs, filtros.ascending);
          final tot = _totales(txs.where((t) {
            if (filtros.periodo == 'mensual') {
              final prefix =
                  '${_mesActivo.year}-${_mesActivo.month.toString().padLeft(2, '0')}';
              return t.fecha.startsWith(prefix);
            }
            return true;
          }).toList());

          final catMap = asyncCats.valueOrNull != null
              ? {
                  for (final c in asyncCats.valueOrNull!)
                    if (c is CatalogoCategoria) c.id: c
                }
              : <String, CatalogoCategoria>{};

          // Build list of slivers
          final slivers = <Widget>[];

          // AppBar sliver
          slivers.add(
            SliverAppBar(
              pinned: true,
              floating: false,
              expandedHeight: 140,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              title: asyncLibros.maybeWhen(
                data: (rows) {
                  final libros = rows.map(FinanceAccount.fromRow).toList();
                  return DropdownButton<String>(
                    value: _libroActual.id,
                    underline: const SizedBox(),
                    dropdownColor: colors.bgCard,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                    style: const TextStyle(
                      color: Colors.white,
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
                      setState(() => _libroActual = nuevo);
                    },
                  );
                },
                orElse: () => Text(
                  _libroActual.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_outlined),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Búsqueda — Próximamente')),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.tune_outlined),
                  onPressed: _mostrarFiltrosSheet,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 80, 16, 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Navegación mensual
                      if (filtros.periodo == 'mensual')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left, size: 20),
                              onPressed: () =>
                                  setState(() => _mesOffset--),
                            ),
                            Text(
                              'Período: $_mesActivoLabel',
                              style: const TextStyle(
                                fontSize: AppTextSize.caption,
                                color: Colors.white70,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right, size: 20),
                              onPressed: () =>
                                  setState(() => _mesOffset++),
                            ),
                          ],
                        ),
                      // Resumen
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ResumenChip(
                              label: 'Ingresos',
                              monto: tot.ingresos,
                              color: const Color(0xFF22C55E)),
                          _ResumenChip(
                              label: 'Gastos',
                              monto: tot.gastos,
                              color: const Color(0xFFEF4444)),
                          _ResumenChip(
                              label: 'Balance',
                              monto: tot.balance,
                              color: tot.balance >= 0
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFFEF4444)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );

          if (grupos.isEmpty) {
            slivers.add(
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Hero(
                        tag: 'libro_icon_${_libroActual.id}',
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: libroColor.withValues(alpha: 0.2),
                          child: Text(
                            _libroActual.icono.isNotEmpty
                                ? _libroActual.icono[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: libroColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sin transacciones',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: AppTextSize.body,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            for (final entry in grupos.entries) {
              final fecha = entry.key;
              final dayTxs = entry.value;
              final dayTot = dayTxs.fold<double>(
                0,
                (sum, t) =>
                    sum + (t.tipo == 'ingreso' ? t.monto : -t.monto),
              );

              // Day header
              slivers.add(
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _fechaLabel(fecha),
                          style: TextStyle(
                            fontSize: AppTextSize.caption,
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${dayTot >= 0 ? '+' : ''}\$${dayTot.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: AppTextSize.caption,
                            color: dayTot >= 0
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFEF4444),
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              // Transactions
              slivers.add(
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final tx = dayTxs[i];
                      final cat = catMap[tx.categoryId];
                      return _TxRow(
                        tx: tx,
                        cat: cat,
                        compacto: filtros.densidad == 'compacto',
                        onDismiss: () async {
                          final ok =
                              await _confirmarEliminar(context, tx);
                          if (ok) await _eliminar(tx);
                        },
                        colors: colors,
                      );
                    },
                    childCount: dayTxs.length,
                  ),
                ),
              );
            }
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(finanzasLibroTxProvider(_libroActual.id)),
            child: CustomScrollView(slivers: slivers),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // FAB secundario — plantillas
          FloatingActionButton.small(
            heroTag: 'fab_plantillas',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Plantillas — Próximamente')),
            ),
            child: const Icon(Icons.description_outlined),
          ),
          const SizedBox(height: 8),
          // FAB principal — nueva transacción
          FloatingActionButton(
            heroTag: 'fab_nueva_tx',
            onPressed: () => showNuevaTransaccionSheet(
              context,
              libroId: _libroActual.id,
            ),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

// ─── Resumen chip ─────────────────────────────────────────────────────────────
class _ResumenChip extends StatelessWidget {
  final String label;
  final double monto;
  final Color color;

  const _ResumenChip({
    required this.label,
    required this.monto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppTextSize.caption,
            color: Colors.white70,
          ),
        ),
        Text(
          '\$${monto.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: AppTextSize.caption,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

// ─── Fila de transacción ──────────────────────────────────────────────────────
class _TxRow extends StatelessWidget {
  final FinanceTransaction tx;
  final CatalogoCategoria? cat;
  final bool compacto;
  final VoidCallback onDismiss;
  final AppThemeColors colors;

  const _TxRow({
    required this.tx,
    required this.cat,
    required this.compacto,
    required this.onDismiss,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isIngreso = tx.tipo == 'ingreso';
    final montoColor =
        isIngreso ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final montoStr =
        '${isIngreso ? '+' : '-'}\$${tx.monto.toStringAsFixed(2)}';

    final catColor = cat != null ? cat!.color : colors.textSecondary;
    final catNombre = cat?.nombre ?? tx.categoryId;
    // Parent name si es subcategoría
    final catLabel = catNombre;

    final subtitle = [
      if (tx.nota.isNotEmpty) tx.nota,
      if (tx.personaSitio != null && tx.personaSitio!.isNotEmpty)
        tx.personaSitio!,
    ].join(' · ');

    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: const Color(0xFFEF4444).withValues(alpha: 0.2),
        child: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
      ),
      confirmDismiss: (_) async {
        onDismiss();
        return false; // Manejamos nosotros la eliminación
      },
      child: ListTile(
        dense: compacto,
        minVerticalPadding: compacto ? 4 : 8,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: catColor.withValues(alpha: 0.2),
          child: cat != null
              ? Icon(cat!.icono, color: catColor, size: 16)
              : Text(
                  catNombre.isNotEmpty ? catNombre[0].toUpperCase() : '?',
                  style: TextStyle(color: catColor, fontSize: 12),
                ),
        ),
        title: Text(
          catLabel,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: (!compacto && subtitle.isNotEmpty)
            ? Text(
                subtitle,
                style: TextStyle(
                  fontSize: AppTextSize.caption,
                  color: colors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              montoStr,
              style: TextStyle(
                color: montoColor,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (tx.hora != null && tx.hora!.isNotEmpty)
              Text(
                tx.hora!,
                style: TextStyle(
                  fontSize: AppTextSize.caption,
                  color: colors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Filtros sheet ────────────────────────────────────────────────────────────
class _FiltrosSheet extends StatefulWidget {
  final FinanzasFiltros filtros;
  final ValueChanged<FinanzasFiltros> onChanged;

  const _FiltrosSheet({required this.filtros, required this.onChanged});

  @override
  State<_FiltrosSheet> createState() => _FiltrosSheetState();
}

class _FiltrosSheetState extends State<_FiltrosSheet> {
  late FinanzasFiltros _f;

  @override
  void initState() {
    super.initState();
    _f = widget.filtros;
  }

  void _update(FinanzasFiltros f) {
    setState(() => _f = f);
    widget.onChanged(f);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Filtros',
              style: TextStyle(
                  fontSize: AppTextSize.heading,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Período
            const Text('Período',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'mensual', label: Text('Mensual')),
                ButtonSegment(value: 'semanal', label: Text('Semanal')),
                ButtonSegment(value: 'diario', label: Text('Diario')),
                ButtonSegment(value: 'todo', label: Text('Todo')),
              ],
              selected: {_f.periodo},
              onSelectionChanged: (s) =>
                  _update(_f.copyWith(periodo: s.first)),
            ),
            const SizedBox(height: 16),

            // Orden
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_f.ascending ? 'Más antiguo primero' : 'Más reciente primero'),
              value: _f.ascending,
              onChanged: (v) => _update(_f.copyWith(ascending: v)),
            ),

            // Densidad
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_f.densidad == 'compacto' ? 'Compacto' : 'Cómodo'),
              value: _f.densidad == 'compacto',
              onChanged: (v) =>
                  _update(_f.copyWith(densidad: v ? 'compacto' : 'comodo')),
            ),

            // Tipo
            const Text('Tipo', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'todos', label: Text('Todos')),
                ButtonSegment(value: 'ingreso', label: Text('Ingresos')),
                ButtonSegment(value: 'gasto', label: Text('Gastos')),
              ],
              selected: {_f.tipoFiltro},
              onSelectionChanged: (s) =>
                  _update(_f.copyWith(tipoFiltro: s.first)),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
