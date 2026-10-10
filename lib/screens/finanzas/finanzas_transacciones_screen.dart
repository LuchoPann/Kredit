import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:krezium/data/db/database.dart';
import 'package:krezium/data/finance_categories_catalog.dart';
import 'package:krezium/providers/finance_provider.dart';
import 'registrar_transaccion_sheet.dart';

final mesActivoFinanzasProvider = StateProvider<String>((ref) {
  return DateFormat('yyyy-MM').format(DateTime.now());
});

class FinanzasTransaccionesScreen extends ConsumerWidget {
  const FinanzasTransaccionesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mes = ref.watch(mesActivoFinanzasProvider);
    final txAsync = ref.watch(financeTransactionsProvider(mes));
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: r'$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finanzas'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: txAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (txs) {
          final ingresos = txs.where((t) => t.tipo == 'ingreso').fold(0.0, (s, t) => s + t.monto);
          final gastos = txs.where((t) => t.tipo == 'gasto').fold(0.0, (s, t) => s + t.monto);
          final balance = ingresos - gastos;

          final Map<String, List<FinanceTransactionRow>> grouped = {};
          for (final tx in txs) {
            grouped.putIfAbsent(tx.fecha, () => []).add(tx);
          }
          final fechas = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _HeaderResumen(ingresos: ingresos, gastos: gastos, balance: balance, fmt: fmt),
              ),
              if (txs.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('Sin transacciones este mes.\nToca + para registrar una.', textAlign: TextAlign.center)),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final fecha = fechas[i];
                      final items = grouped[fecha]!;
                      return _FechaGroup(fecha: fecha, items: items, fmt: fmt);
                    },
                    childCount: fechas.length,
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const RegistrarTransaccionSheet(),
        ).then((_) {
          ref.invalidate(financeTransactionsProvider);
          ref.invalidate(financeAccountsProvider);
        }),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _HeaderResumen extends StatelessWidget {
  final double ingresos, gastos, balance;
  final NumberFormat fmt;
  const _HeaderResumen({required this.ingresos, required this.gastos, required this.balance, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _NumTile('Ingresos', fmt.format(ingresos), Colors.green)),
          const SizedBox(width: 8),
          Expanded(child: _NumTile('Gastos', fmt.format(gastos), Colors.red)),
          const SizedBox(width: 8),
          Expanded(child: _NumTile('Balance', fmt.format(balance), balance >= 0 ? Colors.green : Colors.red)),
        ],
      ),
    );
  }
}

class _NumTile extends StatelessWidget {
  final String label, value;
  final Color color;
  const _NumTile(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _FechaGroup extends StatelessWidget {
  final String fecha;
  final List<FinanceTransactionRow> items;
  final NumberFormat fmt;
  const _FechaGroup({required this.fecha, required this.items, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(fecha, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        ...items.map((tx) => _TxItem(tx: tx, fmt: fmt)),
      ],
    );
  }
}

class _TxItem extends StatelessWidget {
  final FinanceTransactionRow tx;
  final NumberFormat fmt;
  const _TxItem({required this.tx, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final cat = catalogoFinanzas.firstWhere(
      (c) => c.id == tx.categoryId,
      orElse: () => CatalogoCategoria(id: '', nombre: tx.categoryId, icono: Icons.label, color: Colors.grey, tipo: 'gasto', iconoKey: 'more_horiz'),
    );
    final isIngreso = tx.tipo == 'ingreso';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cat.color.withValues(alpha: 0.15),
        child: Icon(cat.icono, color: cat.color, size: 20),
      ),
      title: Text(cat.nombre),
      subtitle: tx.nota.isNotEmpty ? Text(tx.nota, style: const TextStyle(fontSize: 12)) : null,
      trailing: Text(
        '${isIngreso ? '+' : '-'}${fmt.format(tx.monto)}',
        style: TextStyle(color: isIngreso ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
      ),
    );
  }
}
