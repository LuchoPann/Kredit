import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krezium/data/db/database.dart';

void main() {
  test('tablas finanzas existen en DB nueva', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.getFinanceAccounts();
    await db.getFinanceCategories();
    await db.getFinanceBudgets(2026, 10);
    await db.getFinanceTransactions();
    await db.customSelect('SELECT * FROM credits LIMIT 1').get();
    await db.close();
  });
}
