import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:krezium/data/finance_categories_catalog.dart';
import 'package:krezium/providers/finance_provider.dart';

final _presupuestoMesProvider = StateProvider<DateTime>((ref) => DateTime.now());

class FinanzasPresupuestoScreen extends ConsumerWidget {
  const FinanzasPresupuestoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fecha = ref.watch(_presupuestoMesProvider);
    final budgetsAsync = ref.watch(financeBudgetsProvider((fecha.year, fecha.month)));
    final txAsync = ref.watch(financeTransactionsProvider(DateFormat('yyyy-MM').format(fecha)));
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: r'$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presupuesto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => ref.read(_presupuestoMesProvider.notifier).state =
                DateTime(fecha.year, fecha.month - 1),
          ),
          Text(DateFormat('MMM yyyy', 'es').format(fecha)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => ref.read(_presupuestoMesProvider.notifier).state =
                DateTime(fecha.year, fecha.month + 1),
          ),
        ],
      ),
      body: budgetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (budgets) => txAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (txs) {
            final gastosPorCat = <String, double>{};
            for (final tx in txs.where((t) => t.tipo == 'gasto')) {
              gastosPorCat[tx.categoryId] = (gastosPorCat[tx.categoryId] ?? 0) + tx.monto;
            }
            final totalPresupuestado = budgets.fold(0.0, (s, b) => s + b.montoLimite);
            final totalGastado = gastosPorCat.values.fold(0.0, (s, v) => s + v);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ResumenPresupuesto(presupuestado: totalPresupuestado, gastado: totalGastado, fmt: fmt),
                const SizedBox(height: 16),
                if (budgets.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Sin presupuesto definido este mes.', textAlign: TextAlign.center),
                    ),
                  )
                else
                  ...budgets.map((b) {
                    final gasto = gastosPorCat[b.categoryId] ?? 0.0;
                    final progreso = b.montoLimite > 0 ? (gasto / b.montoLimite).clamp(0.0, 1.0) : 0.0;
                    final cat = catalogoFinanzas.firstWhere(
                      (c) => c.id == b.categoryId,
                      orElse: () => CatalogoCategoria(id: '', nombre: b.categoryId, icono: Icons.label, color: Colors.grey, tipo: 'gasto'),
                    );
                    return _BudgetItem(cat: cat, gasto: gasto, limite: b.montoLimite, progreso: progreso, fmt: fmt);
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ResumenPresupuesto extends StatelessWidget {
  final double presupuestado, gastado;
  final NumberFormat fmt;
  const _ResumenPresupuesto({required this.presupuestado, required this.gastado, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final pct = presupuestado > 0 ? ((gastado / presupuestado) * 100).round() : 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Presupuestado: ${fmt.format(presupuestado)}'),
                Text('Gastado: ${fmt.format(gastado)}'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: presupuestado > 0 ? (gastado / presupuestado).clamp(0.0, 1.0) : 0),
            const SizedBox(height: 4),
            Text('$pct% utilizado'),
          ],
        ),
      ),
    );
  }
}

class _BudgetItem extends StatelessWidget {
  final CatalogoCategoria cat;
  final double gasto, limite, progreso;
  final NumberFormat fmt;
  const _BudgetItem({required this.cat, required this.gasto, required this.limite, required this.progreso, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final overLimit = progreso >= 0.9;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(cat.icono, color: cat.color, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(cat.nombre)),
                Text(
                  '${fmt.format(gasto)} / ${fmt.format(limite)}',
                  style: TextStyle(color: overLimit ? Colors.red : null, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progreso,
              color: overLimit ? Colors.red : cat.color,
              backgroundColor: cat.color.withValues(alpha: 0.1),
            ),
          ],
        ),
      ),
    );
  }
}
