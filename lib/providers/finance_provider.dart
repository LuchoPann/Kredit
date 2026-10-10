import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krezium/data/db/database.dart';
import 'package:krezium/data/finance_categories_catalog.dart';
import 'package:krezium/data/finanzas_filtros.dart';
import 'package:krezium/data/models/finance_models.dart';
import 'database_provider.dart';

final financeAccountsProvider = FutureProvider<List<FinanceAccountRow>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.getFinanceAccounts();
});

final financeTransactionsProvider =
    FutureProvider.family<List<FinanceTransactionRow>, String?>((ref, mes) {
  final db = ref.watch(databaseProvider);
  return db.getFinanceTransactions(mes: mes);
});

final financeBudgetsProvider =
    FutureProvider.family<List<FinanceBudgetRow>, (int, int)>((ref, anioMes) {
  final db = ref.watch(databaseProvider);
  return db.getFinanceBudgets(anioMes.$1, anioMes.$2);
});

final allFinanceCategoriesProvider =
    FutureProvider<List<dynamic>>((ref) async {
  final db = ref.watch(databaseProvider);
  final custom = await db.getFinanceCategories();
  return [...todoCatalogo, ...custom];
});

// Lugares (autocomplete de lugar en transacción)
final financePlacesProvider = FutureProvider<List<FinancePlace>>((ref) async {
  final db = ref.watch(databaseProvider);
  final rows = await db.getFinancePlaces();
  return rows.map(FinancePlace.fromRow).toList();
});

// Plantillas filtradas por tipo ('ingreso'|'gasto'|null = todas)
final financeTemplatesByTipoProvider =
    FutureProvider.family<List<FinanceTemplate>, String?>((ref, tipo) async {
  final db = ref.watch(databaseProvider);
  final rows = await db.getFinanceTemplates(tipo: tipo);
  return rows.map(FinanceTemplate.fromRow).toList();
});

// Filtros activos de la pantalla de transacciones
final finanzasFiltrosProvider = StateProvider<FinanzasFiltros>(
  (_) => const FinanzasFiltros(),
);

// Libro activo (ID del libro seleccionado en Tab 0)
final finanzasLibroActivoProvider = StateProvider<String?>((_) => null);

// Totales globales (sin filtros) de un libro — para el lobby
final financeAccountSummaryProvider =
    FutureProvider.family<({double ingresos, double gastos}), String>(
        (ref, libroId) async {
  final db = ref.watch(databaseProvider);
  final rows = await db.getFinanceTransactionsByLibro(
    libroId: libroId,
    mes: null,
    tipo: null,
    ascending: true,
  );
  final txs = rows.map(FinanceTransaction.fromRow).toList();
  final ingresos = txs
      .where((t) => t.tipo == 'ingreso')
      .fold(0.0, (sum, t) => sum + t.monto);
  final gastos = txs
      .where((t) => t.tipo == 'gasto')
      .fold(0.0, (sum, t) => sum + t.monto);
  return (ingresos: ingresos, gastos: gastos);
});

// Transacciones del libro activo aplicando filtros
final finanzasLibroTxProvider =
    FutureProvider.family<List<FinanceTransaction>, String>(
        (ref, libroId) async {
  final db = ref.watch(databaseProvider);
  final filtros = ref.watch(finanzasFiltrosProvider);
  final now = DateTime.now();
  final mes = filtros.periodo == 'mensual'
      ? '${now.year}-${now.month.toString().padLeft(2, '0')}'
      : null;
  final tipo = filtros.tipoFiltro == 'todos' ? null : filtros.tipoFiltro;
  final rows = await db.getFinanceTransactionsByLibro(
    libroId: libroId,
    mes: mes,
    tipo: tipo,
    ascending: filtros.ascending,
  );
  return rows.map(FinanceTransaction.fromRow).toList();
});
