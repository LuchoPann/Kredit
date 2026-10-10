import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:krezium/data/finance_categories_catalog.dart';
import 'package:krezium/providers/finance_provider.dart';

class FinanzasEstadisticasScreen extends ConsumerWidget {
  const FinanzasEstadisticasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final mes = DateFormat('yyyy-MM').format(now);
    final txAsync = ref.watch(financeTransactionsProvider(mes));
    final accountsAsync = ref.watch(financeAccountsProvider);
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: r'$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas Finanzas')),
      body: txAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (txs) {
          final gastos = txs.where((t) => t.tipo == 'gasto');
          final Map<String, double> porCat = {};
          for (final tx in gastos) {
            porCat[tx.categoryId] = (porCat[tx.categoryId] ?? 0) + tx.monto;
          }
          final sorted = porCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          final top5 = sorted.take(5).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (top5.isNotEmpty) ...[
                Text('Gastos por categoría', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: PieChart(PieChartData(
                    sections: top5.map((e) {
                      final cat = catalogoFinanzas.firstWhere(
                        (c) => c.id == e.key,
                        orElse: () => CatalogoCategoria(id: '', nombre: e.key, icono: Icons.label, color: Colors.grey, tipo: 'gasto'),
                      );
                      return PieChartSectionData(
                        value: e.value,
                        color: cat.color,
                        title: cat.nombre,
                        titleStyle: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                        radius: 80,
                      );
                    }).toList(),
                    centerSpaceRadius: 0,
                  )),
                ),
                const SizedBox(height: 24),
              ] else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text('Sin gastos este mes.', textAlign: TextAlign.center),
                  ),
                ),
              accountsAsync.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (accounts) {
                  if (accounts.isEmpty) return const SizedBox();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Saldo por cuenta', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ...accounts.map((a) {
                        final ing = txs
                            .where((t) => t.accountId == a.id && t.tipo == 'ingreso')
                            .fold(0.0, (s, t) => s + t.monto);
                        final gas = txs
                            .where((t) => t.accountId == a.id && t.tipo == 'gasto')
                            .fold(0.0, (s, t) => s + t.monto);
                        final saldo = a.saldoInicial + ing - gas;
                        return ListTile(
                          title: Text(a.nombre),
                          trailing: Text(
                            fmt.format(saldo),
                            style: TextStyle(
                              color: saldo >= 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
