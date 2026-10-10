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

const _kMeses = [
  '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];
const _kMesesCorto = [
  '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];
const _kDiasCorto = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

DateTime _parseFecha(String fecha) {
  final parts = fecha.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

class _FinanzasLibroTransaccionesScreenState
    extends ConsumerState<FinanzasLibroTransaccionesScreen> {
  late FinanceAccount _libroActual;

  @override
  void initState() {
    super.initState();
    _libroActual = widget.libro;
  }

  // ─── Agrupar — listado único, agrupación puramente visual ───────────────────
  // Ya no filtra por mes: siempre se agrupa el histórico completo recibido.
  // La clave de grupo cambia según filtros.periodo (diario/semanal/mensual),
  // pero los datos mostrados son siempre los mismos.

  String _claveGrupo(FinanceTransaction tx, String periodo) {
    final d = _parseFecha(tx.fecha);
    switch (periodo) {
      case 'semanal':
        final inicioSemana = d.subtract(Duration(days: d.weekday - 1));
        return '${inicioSemana.year}-${inicioSemana.month.toString().padLeft(2, '0')}-${inicioSemana.day.toString().padLeft(2, '0')}';
      case 'mensual':
        return '${d.year}-${d.month.toString().padLeft(2, '0')}';
      case 'diario':
      default:
        return tx.fecha;
    }
  }

  Map<String, List<FinanceTransaction>> _agrupar(
      List<FinanceTransaction> txs, String periodo, bool ascending) {
    final mapa = <String, List<FinanceTransaction>>{};
    for (final tx in txs) {
      mapa.putIfAbsent(_claveGrupo(tx, periodo), () => []).add(tx);
    }
    final keys = mapa.keys.toList()
      ..sort((a, b) => ascending ? a.compareTo(b) : b.compareTo(a));
    return {for (final k in keys) k: mapa[k]!};
  }

  String _grupoLabel(String clave, String periodo) {
    switch (periodo) {
      case 'semanal':
        final inicio = _parseFecha(clave);
        final fin = inicio.add(const Duration(days: 6));
        if (inicio.month == fin.month) {
          return 'Semana del ${inicio.day} al ${fin.day} de ${_kMesesCorto[fin.month]}';
        }
        return 'Semana del ${inicio.day} ${_kMesesCorto[inicio.month]} al ${fin.day} ${_kMesesCorto[fin.month]}';
      case 'mensual':
        final parts = clave.split('-');
        final mes = int.parse(parts[1]);
        return '${_kMeses[mes][0].toUpperCase()}${_kMeses[mes].substring(1)} ${parts[0]}';
      case 'diario':
      default:
        return _fechaLabel(clave);
    }
  }

  String _fechaLabel(String fecha) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = _parseFecha(fecha);
    if (d == today) return 'Hoy';
    if (d == today.subtract(const Duration(days: 1))) return 'Ayer';
    return '${_kDiasCorto[d.weekday - 1]} ${d.day} ${_kMesesCorto[d.month]}';
  }

  // Fecha corta para mostrar dentro de cada fila — mantiene el registro
  // autocontenido aunque el usuario pierda de vista el encabezado de grupo.
  String _fechaCorta(String fecha) {
    final d = _parseFecha(fecha);
    return '${d.day} ${_kMesesCorto[d.month]}';
  }

  // ─── Totales ───────────────────────────────────────────────────────────────

  ({double ingresos, double gastos, double balance}) _totales(
      List<FinanceTransaction> txs) {
    double ing = 0, gas = 0;
    for (final t in txs) {
      if (t.tipo == 'ingreso') ing += t.monto;
      if (t.tipo == 'gasto') gas += t.monto;
    }
    return (ingresos: ing, gastos: gas, balance: _libroActual.saldoInicial + ing - gas);
  }

  // ─── Filtros sheet ─────────────────────────────────────────────────────────

  void _mostrarBusqueda(BuildContext context, List<FinanceTransaction> txs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _BusquedaSheet(
        txs: txs,
        onTap: (tx) {
          Navigator.pop(ctx);
          showNuevaTransaccionSheet(context, libroId: _libroActual.id);
        },
      ),
    );
  }

  void _mostrarPlantillasSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _PlantillasSheet(
        libroId: _libroActual.id,
        onPlantillaSeleccionada: (template) {
          Navigator.pop(ctx);
          showNuevaTransaccionSheet(context, libroId: _libroActual.id, template: template);
        },
      ),
    );
  }

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
          final grupos = _agrupar(txs, filtros.periodo, filtros.ascending);
          final tot = _totales(txs);

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
              leading: Hero(
                tag: 'libro_icon_${_libroActual.id}',
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: libroColor.withValues(alpha: 0.3),
                      child: Text(
                        _libroActual.icono.isNotEmpty
                            ? _libroActual.icono[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
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
                  onPressed: () => _mostrarBusqueda(context, txs),
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
                      // Resumen (histórico completo — ya no recortado por mes)
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
              final clave = entry.key;
              final grupoTxs = entry.value;
              final grupoTot = grupoTxs.fold<double>(
                0,
                (sum, t) =>
                    sum + (t.tipo == 'ingreso' ? t.monto : -t.monto),
              );

              // Encabezado de grupo (diario / semanal / mensual según filtro)
              slivers.add(
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _grupoLabel(clave, filtros.periodo),
                          style: TextStyle(
                            fontSize: AppTextSize.caption,
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${grupoTot >= 0 ? '+' : ''}\$${grupoTot.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: AppTextSize.caption,
                            color: grupoTot >= 0
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

              // Transacciones del grupo — cada fila lleva su propia fecha
              // corta para que el registro sea legible por sí solo.
              slivers.add(
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final tx = grupoTxs[i];
                      final cat = catMap[tx.categoryId];
                      return _TxRow(
                        tx: tx,
                        cat: cat,
                        fechaCorta: _fechaCorta(tx.fecha),
                        compacto: filtros.densidad == 'compacto',
                        onConfirmDismiss: () =>
                            _confirmarEliminar(context, tx),
                        onDismissed: () => _eliminar(tx),
                        colors: colors,
                      );
                    },
                    childCount: grupoTxs.length,
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
            onPressed: _mostrarPlantillasSheet,
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
  final String fechaCorta;
  final bool compacto;
  final Future<bool> Function() onConfirmDismiss;
  final VoidCallback onDismissed;
  final AppThemeColors colors;

  const _TxRow({
    required this.tx,
    required this.cat,
    required this.fechaCorta,
    required this.compacto,
    required this.onConfirmDismiss,
    required this.onDismissed,
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
      confirmDismiss: (_) => onConfirmDismiss(),
      onDismissed: (_) => onDismissed(),
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
            // Siempre visible — el registro se entiende sin depender del
            // encabezado de grupo, aunque el usuario esté lejos de él al hacer scroll.
            Text(
              tx.hora != null && tx.hora!.isNotEmpty
                  ? '$fechaCorta · ${tx.hora}'
                  : fechaCorta,
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

            // Agrupación visual — todo el historial se muestra siempre;
            // esto solo decide cómo se agrupan los encabezados de sección.
            const Text('Agrupar por',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'diario', label: Text('Día')),
                ButtonSegment(value: 'semanal', label: Text('Semana')),
                ButtonSegment(value: 'mensual', label: Text('Mes')),
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

// ─── Búsqueda sheet ───────────────────────────────────────────────────────────
class _BusquedaSheet extends StatefulWidget {
  final List<FinanceTransaction> txs;
  final void Function(FinanceTransaction) onTap;

  const _BusquedaSheet({required this.txs, required this.onTap});

  @override
  State<_BusquedaSheet> createState() => _BusquedaSheetState();
}

class _BusquedaSheetState extends State<_BusquedaSheet> {
  final _ctrl = TextEditingController();
  List<FinanceTransaction> _results = [];

  @override
  void initState() {
    super.initState();
    _results = widget.txs;
    _ctrl.addListener(_filtrar);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_filtrar);
    _ctrl.dispose();
    super.dispose();
  }

  void _filtrar() {
    final q = _ctrl.text.toLowerCase();
    setState(() {
      _results = widget.txs.where((t) {
        return t.nota.toLowerCase().contains(q) ||
            (t.personaSitio?.toLowerCase().contains(q) ?? false) ||
            t.monto.toString().contains(q) ||
            t.fecha.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tc = Theme.of(context).extension<AppThemeColors>()!;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => Container(
        decoration: BoxDecoration(
          color: tc.bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: tc.borderCard, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ctrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Buscar transacciones…',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: tc.bgSecondary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.tile),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _results.isEmpty
                  ? Center(child: Text('Sin resultados', style: TextStyle(color: tc.textSecondary)))
                  : ListView.builder(
                      controller: scroll,
                      itemCount: _results.length,
                      itemBuilder: (_, i) {
                        final tx = _results[i];
                        final isIngreso = tx.tipo == 'ingreso';
                        final titulo = tx.personaSitio?.isNotEmpty == true
                            ? tx.personaSitio!
                            : tx.nota.isNotEmpty
                                ? tx.nota
                                : tx.tipo;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isIngreso
                                ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                                : const Color(0xFFEF4444).withValues(alpha: 0.15),
                            child: Icon(
                              isIngreso ? Icons.arrow_downward : Icons.arrow_upward,
                              size: 16,
                              color: isIngreso ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                            ),
                          ),
                          title: Text(titulo, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(tx.fecha, style: TextStyle(fontSize: AppTextSize.caption, color: tc.textSecondary)),
                          trailing: Text(
                            '\$${tx.monto.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isIngreso ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                            ),
                          ),
                          onTap: () => widget.onTap(tx),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Plantillas sheet (selección rápida) ──────────────────────────────────────
class _PlantillasSheet extends ConsumerWidget {
  final String libroId;
  final void Function(FinanceTemplate) onPlantillaSeleccionada;

  const _PlantillasSheet({
    required this.libroId,
    required this.onPlantillaSeleccionada,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = Theme.of(context).extension<AppThemeColors>()!;
    final asyncTemplates = ref.watch(financeTemplatesByTipoProvider(null));

    return Container(
      decoration: BoxDecoration(
        color: tc.bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: tc.borderCard, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Usar plantilla', style: TextStyle(fontSize: AppTextSize.heading, fontWeight: FontWeight.bold, color: tc.textPrimary)),
          const SizedBox(height: 12),
          asyncTemplates.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (templates) {
              if (templates.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.description_outlined, size: AppIconSize.large, color: tc.textSecondary),
                        const SizedBox(height: 8),
                        Text('Sin plantillas creadas', style: TextStyle(color: tc.textSecondary)),
                      ],
                    ),
                  ),
                );
              }
              return SizedBox(
                height: 280,
                child: ListView.builder(
                  itemCount: templates.length,
                  itemBuilder: (_, i) {
                    final t = templates[i];
                    final isIngreso = t.tipo == 'ingreso';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isIngreso
                            ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                            : const Color(0xFFEF4444).withValues(alpha: 0.15),
                        child: Icon(
                          isIngreso ? Icons.arrow_downward : Icons.arrow_upward,
                          size: 18,
                          color: isIngreso ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                        ),
                      ),
                      title: Text(t.nombre),
                      subtitle: t.monto != null
                          ? Text('\$${t.monto!.toStringAsFixed(2)}', style: TextStyle(color: tc.textSecondary, fontSize: AppTextSize.caption))
                          : null,
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () => onPlantillaSeleccionada(t),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
