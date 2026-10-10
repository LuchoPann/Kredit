import 'package:drift/drift.dart';

@DataClassName('FinanceAccountRow')
class FinanceAccounts extends Table {
  TextColumn get id => text()();
  TextColumn get nombre => text()();
  TextColumn get tipo => text()(); // 'efectivo'|'digital'|'bancaria'
  TextColumn get icono => text()();
  TextColumn get color => text()();
  RealColumn get saldoInicial => real().withDefault(const Constant(0.0))();
  BoolColumn get activa => boolean().withDefault(const Constant(true))();
  TextColumn get orden => text().withDefault(const Constant('0'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('FinanceCategoryRow')
class FinanceCategories extends Table {
  TextColumn get id => text()();
  TextColumn get nombre => text()();
  TextColumn get icono => text()();
  TextColumn get color => text()();
  TextColumn get tipo => text()(); // 'ingreso'|'gasto'|'ambos'
  BoolColumn get archivada => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('FinanceTransactionRow')
class FinanceTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get accountId =>
      text().references(FinanceAccounts, #id, onDelete: KeyAction.restrict)();
  TextColumn get categoryId => text()();
  TextColumn get tipo => text()(); // 'ingreso'|'gasto'
  RealColumn get monto => real()();
  TextColumn get fecha => text()(); // YYYY-MM-DD
  TextColumn get nota => text().withDefault(const Constant(''))();
  BoolColumn get esRecurrente => boolean().withDefault(const Constant(false))();
  TextColumn get recurrenciaConfig => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('FinanceBudgetRow')
class FinanceBudgets extends Table {
  IntColumn get rowId => integer().autoIncrement()();
  TextColumn get categoryId => text()();
  IntColumn get anio => integer()();
  IntColumn get mes => integer()(); // 1-12
  RealColumn get montoLimite => real()();
}
