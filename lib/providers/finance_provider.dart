import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krezium/data/db/database.dart';
import 'package:krezium/data/finance_categories_catalog.dart';
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
  return [...catalogoFinanzas, ...custom];
});
