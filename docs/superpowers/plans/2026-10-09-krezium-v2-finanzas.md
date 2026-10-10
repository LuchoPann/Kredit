# Krezium v2.0.0 — Módulo Finanzas + Nav Dual — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Agregar módulo independiente de gastos/ingresos (Finanzas) con navegación dual de 5 botones y switch central entre entornos Créditos y Finanzas.

**Architecture:** Dos entornos independientes (Créditos / Finanzas) gestionados por `entornoProvider`. El `RootScaffold` pasa de 4 tabs a 5 posiciones con botón central elevado. Cuatro nuevas tablas Drift + migración schemaVersion 12→13.

**Tech Stack:** Flutter, Riverpod (StateProvider, AsyncNotifier), Drift ORM, shared_preferences, fl_chart (ya instalado).

**Spec:** docs/superpowers/specs/2026-10-09-krezium-v2-finanzas-design.md

## Global Constraints

- App 100% offline. Sin internet, sin cuentas.
- Solo COP. Sin multidivisa.
- `schemaVersion` pasa de 12 a 13 — migración `addTable` para las 4 tablas nuevas.
- Ninguna tabla existente de créditos se modifica.
- Todo campo nuevo en `fromJson` debe ser nullable — backups viejos deben importar sin error.
- Versión final: `2.0.0+19`.
- Usuarios existentes (onboardingShown=true) arrancan en entorno créditos sin pantalla extra.

## Review Focus

1. **Migración en instalaciones existentes** — schemaVersion 12→13 debe agregar 4 tablas sin tocar filas existentes. Test: abrir DB v12, ejecutar migración, verificar que tablas créditos intactas.
2. **Backup v1 importado en v2** — campo `finanzas` ausente → listas vacías, sin excepción. Test: importar JSON sin bloque `finanzas`.
3. **Switch de entorno mid-session** — usuario en StatsScreen Finanzas, cambia a Créditos: `TickerMode` de Finanzas queda desactivado sin crash. Test: widget test del `_TabFadeLayer` con entorno switch.
4. **Borrar cuenta con transacciones** — `KeyAction.restrict` lanza error Drift; UI debe capturar y mostrar mensaje amigable, no crash. Test: intentar delete con transacciones asociadas.
5. **Primera instalación onboarding** — `EntornoSelectionScreen` solo si `onboardingShown=false`; usuarios existentes saltan directo. Test: provider test con ambas condiciones.

---

## File Structure

**Nuevos archivos:**
- `lib/data/db/tables_finance.dart` — 4 tablas Drift (FinanceAccounts, FinanceCategories, FinanceTransactions, FinanceBudgets)
- `lib/data/finance_categories_catalog.dart` — 30 categorías constantes
- `lib/data/models/finance_models.dart` — modelos de dominio (FinanceAccount, FinanceCategory, FinanceTransaction, FinanceBudget)
- `lib/providers/entorno_provider.dart` — entornoProvider + helpers SharedPreferences
- `lib/providers/finance_provider.dart` — AsyncNotifier para transacciones/cuentas/presupuestos
- `lib/screens/onboarding/entorno_selection_screen.dart` — pantalla de selección en primer arranque
- `lib/screens/finanzas/finanzas_transacciones_screen.dart`
- `lib/screens/finanzas/registrar_transaccion_sheet.dart`
- `lib/screens/finanzas/finanzas_presupuesto_screen.dart`
- `lib/screens/finanzas/finanzas_estadisticas_screen.dart`

**Archivos modificados:**
- `lib/data/db/tables.dart` — agregar import de tables_finance.dart
- `lib/data/db/database.dart` — schemaVersion 12→13, addTable x4, incluir tablas en @DriftDatabase
- `lib/domain/export_import.dart` — bloque `finanzas` en JSON
- `lib/providers/navigation_provider.dart` — creditosTabProvider + finanzasTabProvider
- `lib/main.dart` (RootScaffold) — redesign nav 5 posiciones con botón central
- `lib/screens/onboarding/welcome_screen.dart` — agrega `EntornoSelectionScreen` al flujo
- `lib/screens/account/account_screen.dart` — opción "Vista principal" en sección General
- `lib/data/changelog.dart` — entrada 2.0.0
- `pubspec.yaml` — versión 2.0.0+19

---

### Task 1: DB Schema — 4 tablas Drift + migración schemaVersion 12→13

**Files:**
- Create: `lib/data/db/tables_finance.dart`
- Modify: `lib/data/db/database.dart`
- Test: `test/db/finance_tables_migration_test.dart`

**Interfaces:**
- Produces: `FinanceAccounts`, `FinanceCategories`, `FinanceTransactions`, `FinanceBudgets` — clases Drift con sus DataClass (`FinanceAccountRow`, etc.)

- [ ] **Step 1: Escribir test de migración**

```dart
// test/db/finance_tables_migration_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krezium/data/db/database.dart';

void main() {
  test('migración 12→13 crea las 4 tablas de finanzas sin tocar créditos', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    // Tablas nuevas existen
    await db.customSelect('SELECT * FROM finance_accounts LIMIT 1').get();
    await db.customSelect('SELECT * FROM finance_categories LIMIT 1').get();
    await db.customSelect('SELECT * FROM finance_transactions LIMIT 1').get();
    await db.customSelect('SELECT * FROM finance_budgets LIMIT 1').get();
    // Tablas existentes intactas
    await db.customSelect('SELECT * FROM credits LIMIT 1').get();
    await db.close();
  });
}
```

- [ ] **Step 2: Ejecutar test — debe fallar**

```bash
cd "/home/luis/Documentos/.VS CODE/PROYECTOS_PAN/Kredit"
dart test test/db/finance_tables_migration_test.dart
```
Expected: FAIL — tablas no existen

- [ ] **Step 3: Crear `lib/data/db/tables_finance.dart`**

```dart
import 'package:drift/drift.dart';
import 'tables.dart';

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
  IntColumn get rowId => integer().autoIncrement()();
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
```

- [ ] **Step 4: Modificar `lib/data/db/database.dart`**

Agregar import, tablas al decorator `@DriftDatabase`, y migración:

```dart
// Al inicio del archivo, agregar import:
import 'tables_finance.dart';

// En @DriftDatabase(tables: [...]), agregar:
// FinanceAccounts, FinanceCategories, FinanceTransactions, FinanceBudgets

// schemaVersion: 12 → 13

// En onUpgrade, agregar:
if (from < 13) {
  await m.createTable(financeAccounts);
  await m.createTable(financeCategories);
  await m.createTable(financeTransactions);
  await m.createTable(financeBudgets);
}
```

- [ ] **Step 5: Ejecutar build_runner para regenerar código Drift**

```bash
cd "/home/luis/Documentos/.VS CODE/PROYECTOS_PAN/Kredit"
dart run build_runner build --delete-conflicting-outputs 2>&1 | tail -30
```
Expected: sin errores

- [ ] **Step 6: Ejecutar test — debe pasar**

```bash
dart test test/db/finance_tables_migration_test.dart
```
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add lib/data/db/tables_finance.dart lib/data/db/database.dart test/db/finance_tables_migration_test.dart
git commit -m "feat(db): tablas Finanzas + migración schemaVersion 12→13

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Task 2: Catálogo de categorías + modelos de dominio

**Files:**
- Create: `lib/data/finance_categories_catalog.dart`
- Create: `lib/data/models/finance_models.dart`
- Test: `test/data/finance_catalog_test.dart`

**Interfaces:**
- Produces: `CatalogoCategoria` (id, nombre, icono, color, tipo), `catalogoFinanzas` List<CatalogoCategoria>, `FinanceAccount`, `FinanceCategory`, `FinanceTransaction`, `FinanceBudget`

- [ ] **Step 1: Test catálogo**

```dart
// test/data/finance_catalog_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:krezium/data/finance_categories_catalog.dart';

void main() {
  test('catálogo tiene exactamente 30 categorías', () {
    expect(catalogoFinanzas.length, 30);
  });

  test('ids únicos en catálogo', () {
    final ids = catalogoFinanzas.map((c) => c.id).toSet();
    expect(ids.length, 30);
  });

  test('tipos válidos en catálogo', () {
    final tiposValidos = {'ingreso', 'gasto', 'ambos'};
    for (final c in catalogoFinanzas) {
      expect(tiposValidos.contains(c.tipo), true, reason: '${c.id} tiene tipo inválido: ${c.tipo}');
    }
  });

  test('8 ingresos y 22 gastos', () {
    final ingresos = catalogoFinanzas.where((c) => c.tipo == 'ingreso').length;
    final gastos = catalogoFinanzas.where((c) => c.tipo == 'gasto').length;
    expect(ingresos, 8);
    expect(gastos, 22);
  });
}
```

- [ ] **Step 2: Run test — FAIL**

```bash
dart test test/data/finance_catalog_test.dart
```

- [ ] **Step 3: Crear `lib/data/finance_categories_catalog.dart`**

```dart
import 'package:flutter/material.dart';

class CatalogoCategoria {
  final String id;
  final String nombre;
  final IconData icono;
  final Color color;
  final String tipo; // 'ingreso'|'gasto'|'ambos'

  const CatalogoCategoria({
    required this.id,
    required this.nombre,
    required this.icono,
    required this.color,
    required this.tipo,
  });
}

const List<CatalogoCategoria> catalogoFinanzas = [
  // --- Ingresos (8) ---
  CatalogoCategoria(id: 'salario', nombre: 'Salario', icono: Icons.work, color: Color(0xFF22C55E), tipo: 'ingreso'),
  CatalogoCategoria(id: 'freelance', nombre: 'Freelance', icono: Icons.laptop, color: Color(0xFF10B981), tipo: 'ingreso'),
  CatalogoCategoria(id: 'negocio', nombre: 'Negocio', icono: Icons.store, color: Color(0xFF059669), tipo: 'ingreso'),
  CatalogoCategoria(id: 'arriendo_recibido', nombre: 'Arriendo recibido', icono: Icons.home, color: Color(0xFF16A34A), tipo: 'ingreso'),
  CatalogoCategoria(id: 'intereses', nombre: 'Intereses', icono: Icons.trending_up, color: Color(0xFF15803D), tipo: 'ingreso'),
  CatalogoCategoria(id: 'regalo_ingreso', nombre: 'Regalo', icono: Icons.card_giftcard, color: Color(0xFF4ADE80), tipo: 'ingreso'),
  CatalogoCategoria(id: 'devolucion', nombre: 'Devolución', icono: Icons.undo, color: Color(0xFF86EFAC), tipo: 'ingreso'),
  CatalogoCategoria(id: 'otro_ingreso', nombre: 'Otro ingreso', icono: Icons.add_circle_outline, color: Color(0xFF6EE7B7), tipo: 'ingreso'),
  // --- Gastos (22) ---
  CatalogoCategoria(id: 'alimentacion', nombre: 'Alimentación', icono: Icons.restaurant, color: Color(0xFFF97316), tipo: 'gasto'),
  CatalogoCategoria(id: 'restaurantes', nombre: 'Restaurantes', icono: Icons.dining, color: Color(0xFFEA580C), tipo: 'gasto'),
  CatalogoCategoria(id: 'supermercado', nombre: 'Supermercado', icono: Icons.shopping_cart, color: Color(0xFFFB923C), tipo: 'gasto'),
  CatalogoCategoria(id: 'transporte', nombre: 'Transporte', icono: Icons.directions_bus, color: Color(0xFF3B82F6), tipo: 'gasto'),
  CatalogoCategoria(id: 'salud', nombre: 'Salud', icono: Icons.local_hospital, color: Color(0xFFEF4444), tipo: 'gasto'),
  CatalogoCategoria(id: 'vivienda', nombre: 'Vivienda', icono: Icons.house, color: Color(0xFF8B5CF6), tipo: 'gasto'),
  CatalogoCategoria(id: 'servicios_publicos', nombre: 'Servicios', icono: Icons.bolt, color: Color(0xFFF59E0B), tipo: 'gasto'),
  CatalogoCategoria(id: 'ropa', nombre: 'Ropa', icono: Icons.checkroom, color: Color(0xFFEC4899), tipo: 'gasto'),
  CatalogoCategoria(id: 'entretenimiento', nombre: 'Entretenimiento', icono: Icons.movie, color: Color(0xFFA855F7), tipo: 'gasto'),
  CatalogoCategoria(id: 'educacion', nombre: 'Educación', icono: Icons.school, color: Color(0xFF06B6D4), tipo: 'gasto'),
  CatalogoCategoria(id: 'viajes', nombre: 'Viajes', icono: Icons.flight, color: Color(0xFF0EA5E9), tipo: 'gasto'),
  CatalogoCategoria(id: 'mascotas', nombre: 'Mascotas', icono: Icons.pets, color: Color(0xFFD97706), tipo: 'gasto'),
  CatalogoCategoria(id: 'deporte', nombre: 'Deporte', icono: Icons.fitness_center, color: Color(0xFF10B981), tipo: 'gasto'),
  CatalogoCategoria(id: 'tecnologia', nombre: 'Tecnología', icono: Icons.devices, color: Color(0xFF6366F1), tipo: 'gasto'),
  CatalogoCategoria(id: 'belleza', nombre: 'Belleza', icono: Icons.face, color: Color(0xFFF43F5E), tipo: 'gasto'),
  CatalogoCategoria(id: 'regalos_gasto', nombre: 'Regalos', icono: Icons.redeem, color: Color(0xFFE879F9), tipo: 'gasto'),
  CatalogoCategoria(id: 'ahorros', nombre: 'Ahorros', icono: Icons.savings, color: Color(0xFF14B8A6), tipo: 'gasto'),
  CatalogoCategoria(id: 'inversion', nombre: 'Inversión', icono: Icons.show_chart, color: Color(0xFF0D9488), tipo: 'gasto'),
  CatalogoCategoria(id: 'suscripciones', nombre: 'Suscripciones', icono: Icons.subscriptions, color: Color(0xFF7C3AED), tipo: 'gasto'),
  CatalogoCategoria(id: 'cuidado_personal', nombre: 'Cuidado personal', icono: Icons.spa, color: Color(0xFFDB2777), tipo: 'gasto'),
  CatalogoCategoria(id: 'hogar', nombre: 'Hogar', icono: Icons.weekend, color: Color(0xFF92400E), tipo: 'gasto'),
  CatalogoCategoria(id: 'otro_gasto', nombre: 'Otro gasto', icono: Icons.more_horiz, color: Color(0xFF6B7280), tipo: 'gasto'),
];
```

- [ ] **Step 4: Crear `lib/data/models/finance_models.dart`**

```dart
import 'package:flutter/material.dart';

class FinanceAccount {
  final String id;
  final String nombre;
  final String tipo;
  final String icono;
  final String color;
  final double saldoInicial;
  final bool activa;
  final String orden;

  const FinanceAccount({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.icono,
    required this.color,
    required this.saldoInicial,
    required this.activa,
    required this.orden,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'nombre': nombre, 'tipo': tipo, 'icono': icono,
    'color': color, 'saldoInicial': saldoInicial, 'activa': activa, 'orden': orden,
  };

  factory FinanceAccount.fromJson(Map<String, dynamic> json) => FinanceAccount(
    id: json['id'] as String,
    nombre: json['nombre'] as String,
    tipo: json['tipo'] as String? ?? 'efectivo',
    icono: json['icono'] as String? ?? 'account_balance_wallet',
    color: json['color'] as String? ?? '#6B7280',
    saldoInicial: (json['saldoInicial'] as num?)?.toDouble() ?? 0.0,
    activa: json['activa'] as bool? ?? true,
    orden: json['orden'] as String? ?? '0',
  );
}

class FinanceCategory {
  final String id;
  final String nombre;
  final String icono;
  final String color;
  final String tipo;
  final bool archivada;

  const FinanceCategory({
    required this.id, required this.nombre, required this.icono,
    required this.color, required this.tipo, required this.archivada,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'nombre': nombre, 'icono': icono,
    'color': color, 'tipo': tipo, 'archivada': archivada,
  };

  factory FinanceCategory.fromJson(Map<String, dynamic> json) => FinanceCategory(
    id: json['id'] as String,
    nombre: json['nombre'] as String,
    icono: json['icono'] as String? ?? 'label',
    color: json['color'] as String? ?? '#6B7280',
    tipo: json['tipo'] as String? ?? 'gasto',
    archivada: json['archivada'] as bool? ?? false,
  );
}

class FinanceTransaction {
  final String id;
  final String accountId;
  final String categoryId;
  final String tipo; // 'ingreso'|'gasto'
  final double monto;
  final String fecha;
  final String nota;
  final bool esRecurrente;
  final String? recurrenciaConfig;

  const FinanceTransaction({
    required this.id, required this.accountId, required this.categoryId,
    required this.tipo, required this.monto, required this.fecha,
    required this.nota, required this.esRecurrente, this.recurrenciaConfig,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'accountId': accountId, 'categoryId': categoryId,
    'tipo': tipo, 'monto': monto, 'fecha': fecha, 'nota': nota,
    'esRecurrente': esRecurrente, 'recurrenciaConfig': recurrenciaConfig,
  };

  factory FinanceTransaction.fromJson(Map<String, dynamic> json) => FinanceTransaction(
    id: json['id'] as String,
    accountId: json['accountId'] as String,
    categoryId: json['categoryId'] as String,
    tipo: json['tipo'] as String? ?? 'gasto',
    monto: (json['monto'] as num?)?.toDouble() ?? 0.0,
    fecha: json['fecha'] as String? ?? '',
    nota: json['nota'] as String? ?? '',
    esRecurrente: json['esRecurrente'] as bool? ?? false,
    recurrenciaConfig: json['recurrenciaConfig'] as String?,
  );
}

class FinanceBudget {
  final String categoryId;
  final int anio;
  final int mes;
  final double montoLimite;

  const FinanceBudget({
    required this.categoryId, required this.anio,
    required this.mes, required this.montoLimite,
  });

  Map<String, dynamic> toJson() => {
    'categoryId': categoryId, 'anio': anio, 'mes': mes, 'montoLimite': montoLimite,
  };

  factory FinanceBudget.fromJson(Map<String, dynamic> json) => FinanceBudget(
    categoryId: json['categoryId'] as String,
    anio: json['anio'] as int? ?? 0,
    mes: json['mes'] as int? ?? 1,
    montoLimite: (json['montoLimite'] as num?)?.toDouble() ?? 0.0,
  );
}
```

- [ ] **Step 5: Run test — PASS**

```bash
dart test test/data/finance_catalog_test.dart
```

- [ ] **Step 6: Commit**

```bash
git add lib/data/finance_categories_catalog.dart lib/data/models/finance_models.dart test/data/finance_catalog_test.dart
git commit -m "feat(finanzas): catálogo 30 categorías + modelos de dominio

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Task 3: Providers — entornoProvider + financeProvider + métodos DB

**Files:**
- Create: `lib/providers/entorno_provider.dart`
- Create: `lib/providers/finance_provider.dart`
- Modify: `lib/data/db/database.dart` — métodos CRUD finanzas
- Test: `test/providers/entorno_provider_test.dart`

**Interfaces:**
- Consumes: `FinanceAccountRow`, `FinanceCategoryRow`, `FinanceTransactionRow`, `FinanceBudgetRow` de Task 1; `FinanceAccount`, `FinanceTransaction`, `FinanceBudget` de Task 2
- Produces: `entornoProvider` (StateProvider<Entorno>), `financeAccountsProvider`, `financeTransactionsProvider`, `financeBudgetsProvider`

- [ ] **Step 1: Test entornoProvider**

```dart
// test/providers/entorno_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krezium/providers/entorno_provider.dart';

void main() {
  test('entornoProvider inicia en creditos', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(entornoProvider), Entorno.creditos);
  });

  test('toggle cambia de creditos a finanzas', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(entornoProvider.notifier).state = Entorno.finanzas;
    expect(container.read(entornoProvider), Entorno.finanzas);
  });
}
```

- [ ] **Step 2: Run test — FAIL**

```bash
dart test test/providers/entorno_provider_test.dart
```

- [ ] **Step 3: Crear `lib/providers/entorno_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Entorno { creditos, finanzas }

const _kPreferredEntorno = 'preferred_entorno';

final entornoProvider = StateProvider<Entorno>((ref) => Entorno.creditos);

Future<Entorno> loadPreferredEntorno() async {
  final prefs = await SharedPreferences.getInstance();
  final val = prefs.getString(_kPreferredEntorno);
  return val == 'finanzas' ? Entorno.finanzas : Entorno.creditos;
}

Future<void> savePreferredEntorno(Entorno entorno) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kPreferredEntorno, entorno.name);
}
```

- [ ] **Step 4: Agregar métodos CRUD a `lib/data/db/database.dart`**

Agregar dentro de la clase `AppDatabase`:

```dart
// --- Finance Accounts ---
Future<List<FinanceAccountRow>> getFinanceAccounts() =>
    select(financeAccounts).get();

Future<void> upsertFinanceAccount(FinanceAccountsCompanion row) =>
    into(financeAccounts).insertOnConflictUpdate(row);

Future<void> deleteFinanceAccount(String id) =>
    (delete(financeAccounts)..where((t) => t.id.equals(id))).go();

// --- Finance Categories ---
Future<List<FinanceCategoryRow>> getFinanceCategories() =>
    select(financeCategories).get();

Future<void> upsertFinanceCategory(FinanceCategoriesCompanion row) =>
    into(financeCategories).insertOnConflictUpdate(row);

// --- Finance Transactions ---
Future<List<FinanceTransactionRow>> getFinanceTransactions({
  String? accountId, String? mes, // 'YYYY-MM'
}) async {
  final query = select(financeTransactions);
  query.where((t) {
    Expression<bool> cond = const Constant(true);
    if (accountId != null) cond = cond & t.accountId.equals(accountId);
    if (mes != null) cond = cond & t.fecha.like('$mes%');
    return cond;
  });
  query.orderBy([(t) => OrderingTerm.desc(t.fecha)]);
  return query.get();
}

Future<void> upsertFinanceTransaction(FinanceTransactionsCompanion row) =>
    into(financeTransactions).insertOnConflictUpdate(row);

Future<void> deleteFinanceTransaction(String id) =>
    (delete(financeTransactions)..where((t) => t.id.equals(id))).go();

// --- Finance Budgets ---
Future<List<FinanceBudgetRow>> getFinanceBudgets(int anio, int mes) =>
    (select(financeBudgets)
      ..where((t) => t.anio.equals(anio) & t.mes.equals(mes)))
        .get();

Future<void> upsertFinanceBudget(FinanceBudgetsCompanion row) =>
    into(financeBudgets).insertOnConflictUpdate(row);
```

- [ ] **Step 5: Crear `lib/providers/finance_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krezium/data/db/database.dart';
import 'package:krezium/data/models/finance_models.dart';
import 'package:krezium/data/finance_categories_catalog.dart';

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

// Combina catálogo base + categorías personalizadas de DB
final allFinanceCategoriesProvider =
    FutureProvider<List<dynamic>>((ref) async {
  final db = ref.watch(databaseProvider);
  final custom = await db.getFinanceCategories();
  return [...catalogoFinanzas, ...custom];
});
```

- [ ] **Step 6: Run build_runner + tests**

```bash
dart run build_runner build --delete-conflicting-outputs 2>&1 | tail -20
dart test test/providers/entorno_provider_test.dart
```
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add lib/providers/entorno_provider.dart lib/providers/finance_provider.dart lib/data/db/database.dart test/providers/entorno_provider_test.dart
git commit -m "feat(providers): entornoProvider + financeProvider + CRUD métodos DB

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Task 4: RootScaffold — nav 5 posiciones con botón central elevado

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/providers/navigation_provider.dart`

**Interfaces:**
- Consumes: `entornoProvider` (Entorno) de Task 3
- Produces: nav funcional con 5 posiciones, switch de entorno, `creditosTabProvider`, `finanzasTabProvider`

- [ ] **Step 1: Leer archivos actuales**

Leer `lib/main.dart` y `lib/providers/navigation_provider.dart` completos antes de modificar.

- [ ] **Step 2: Modificar `lib/providers/navigation_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Índices visuales de nav (0-3 excluyendo botón central)
enum AppNavTab { dashboard, credits, stats, account }

// Mantener para compatibilidad con código existente
final navigationIndexProvider = StateProvider<int>((ref) => 0);

// Tab activo por entorno (0,1,2 = los 3 tabs del entorno, excluyendo Cuenta)
final creditosTabProvider = StateProvider<int>((ref) => 0); // 0=Dashboard,1=Créditos,2=Stats
final finanzasTabProvider = StateProvider<int>((ref) => 0); // 0=Transacc,1=Presup,2=Stats
```

- [ ] **Step 3: Modificar `lib/main.dart` — RootScaffold**

Reemplazar el `BottomNavigationBar` actual con un `Stack` que contiene:
1. `NavigationBar` (Material 3) con 4 destinos (sin posición central)
2. `FloatingActionButton` centrado y elevado como switch

```dart
// Estructura del nuevo RootScaffold:
// - body: Stack con AnimatedOpacity por tab (igual que antes pero 3+1 tabs por entorno)
// - bottomNavigationBar: _DualEntornoNav widget

// _DualEntornoNav:
// Stack [
//   NavigationBar(destinations: _destinationsFor(entorno)),  // 4 items: left2 + right2
//   Positioned(bottom: 8, child: _SwitchButton()),           // botón central elevado
// ]
```

El widget `_DualEntornoNav` completo:

```dart
class _DualEntornoNav extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entorno = ref.watch(entornoProvider);
    final creditosTab = ref.watch(creditosTabProvider);
    final finanzasTab = ref.watch(finanzasTabProvider);
    final theme = Theme.of(context);
    final kredit = theme.extension<AppThemeColors>()!;

    final currentTab = entorno == Entorno.creditos ? creditosTab : finanzasTab;

    return SizedBox(
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          NavigationBar(
            selectedIndex: currentTab >= 2 ? currentTab + 1 : currentTab,
            // índice 2 es el hueco del botón central
            destinations: entorno == Entorno.creditos
                ? const [
                    NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Inicio'),
                    NavigationDestination(icon: Icon(Icons.credit_card_outlined), selectedIcon: Icon(Icons.credit_card), label: 'Créditos'),
                    NavigationDestination(icon: SizedBox.shrink(), label: ''),  // hueco central
                    NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Estadísticas'),
                    NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Cuenta'),
                  ]
                : const [
                    NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Transac.'),
                    NavigationDestination(icon: Icon(Icons.pie_chart_outline), selectedIcon: Icon(Icons.pie_chart), label: 'Presupuesto'),
                    NavigationDestination(icon: SizedBox.shrink(), label: ''),
                    NavigationDestination(icon: Icon(Icons.area_chart_outlined), selectedIcon: Icon(Icons.area_chart), label: 'Estadísticas'),
                    NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Cuenta'),
                  ],
            onDestinationSelected: (i) {
              if (i == 2) return; // hueco del botón central
              final tab = i > 2 ? i - 1 : i; // ajustar índice real (0,1,2,3)
              if (entorno == Entorno.creditos) {
                ref.read(creditosTabProvider.notifier).state = tab < 3 ? tab : 3;
              } else {
                ref.read(finanzasTabProvider.notifier).state = tab < 3 ? tab : 3;
              }
            },
          ),
          Positioned(
            top: -16,
            left: 0,
            right: 0,
            child: Center(
              child: _SwitchEntornoButton(entorno: entorno, ref: ref),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchEntornoButton extends StatelessWidget {
  final Entorno entorno;
  final WidgetRef ref;
  const _SwitchEntornoButton({required this.entorno, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isCreditos = entorno == Entorno.creditos;
    return FloatingActionButton.small(
      heroTag: 'switch_entorno',
      tooltip: isCreditos ? 'Cambiar a Finanzas' : 'Cambiar a Créditos',
      onPressed: () {
        final next = isCreditos ? Entorno.finanzas : Entorno.creditos;
        ref.read(entornoProvider.notifier).state = next;
        savePreferredEntorno(next);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isCreditos ? Icons.account_balance_wallet_outlined : Icons.credit_card_outlined, size: 16),
          Text(isCreditos ? 'Fin.' : 'Cré.', style: const TextStyle(fontSize: 8)),
        ],
      ),
    );
  }
}
```

El body del `RootScaffold` usa `IndexedStack` o `_TabFadeLayer` equivalente por entorno. Cuenta (índice 3) se comparte.

- [ ] **Step 4: `dart analyze` en archivos modificados**

```bash
dart analyze lib/main.dart lib/providers/navigation_provider.dart lib/providers/entorno_provider.dart 2>&1 | tail -20
```
Expected: sin errores (solo posibles infos)

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart lib/providers/navigation_provider.dart
git commit -m "feat(nav): RootScaffold 5 posiciones con switch central de entorno

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Task 5: EntornoSelectionScreen + integración onboarding

**Files:**
- Create: `lib/screens/onboarding/entorno_selection_screen.dart`
- Modify: `lib/screens/onboarding/welcome_screen.dart`
- Modify: `lib/main.dart` — leer entorno preferido al arrancar

**Interfaces:**
- Consumes: `entornoProvider`, `savePreferredEntorno`, `onboardingProvider` de código existente

- [ ] **Step 1: Crear `lib/screens/onboarding/entorno_selection_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krezium/providers/entorno_provider.dart';

class EntornoSelectionScreen extends ConsumerStatefulWidget {
  final VoidCallback onSelected;
  const EntornoSelectionScreen({super.key, required this.onSelected});

  @override
  ConsumerState<EntornoSelectionScreen> createState() => _EntornoSelectionScreenState();
}

class _EntornoSelectionScreenState extends ConsumerState<EntornoSelectionScreen> {
  Future<void> _select(Entorno entorno) async {
    ref.read(entornoProvider.notifier).state = entorno;
    await savePreferredEntorno(entorno);
    widget.onSelected();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text('¿Por dónde empezamos?', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Elige la vista que quieres ver al abrir Krezium. Puedes cambiarla cuando quieras.', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 40),
              _EntornoCard(
                icono: Icons.credit_card,
                titulo: 'Créditos',
                descripcion: 'Gestiona tus tarjetas, cupos y préstamos.',
                onTap: () => _select(Entorno.creditos),
              ),
              const SizedBox(height: 16),
              _EntornoCard(
                icono: Icons.account_balance_wallet,
                titulo: 'Finanzas',
                descripcion: 'Registra gastos e ingresos del día a día.',
                onTap: () => _select(Entorno.finanzas),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntornoCard extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final VoidCallback onTap;

  const _EntornoCard({required this.icono, required this.titulo, required this.descripcion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icono, size: 40, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(descripcion, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Modificar `welcome_screen.dart`**

En `_finish()`, antes de `Navigator.pushReplacement` hacia `RootScaffold`, navegar primero a `EntornoSelectionScreen`:

```dart
// En _finish() de WelcomeScreen:
await ref.read(onboardingProvider.notifier).markShown();
if (!mounted) return;
Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => EntornoSelectionScreen(
      onSelected: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RootScaffold()),
      ),
    ),
  ),
);
```

- [ ] **Step 3: Modificar `lib/main.dart` — cargar entorno al inicio**

En el init del app (antes de mostrar `RootScaffold`), leer `loadPreferredEntorno()` y setear `entornoProvider`:

```dart
// En MyApp o en el ConsumerStatefulWidget raíz:
@override
void initState() {
  super.initState();
  _loadEntorno();
}

Future<void> _loadEntorno() async {
  final entorno = await loadPreferredEntorno();
  if (mounted) {
    ref.read(entornoProvider.notifier).state = entorno;
  }
}
```

- [ ] **Step 4: `dart analyze`**

```bash
dart analyze lib/screens/onboarding/ lib/main.dart 2>&1 | tail -20
```

- [ ] **Step 5: Commit**

```bash
git add lib/screens/onboarding/entorno_selection_screen.dart lib/screens/onboarding/welcome_screen.dart lib/main.dart
git commit -m "feat(onboarding): EntornoSelectionScreen para primer arranque

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Task 6: FinanzasTransaccionesScreen + RegistrarTransaccionSheet

**Files:**
- Create: `lib/screens/finanzas/finanzas_transacciones_screen.dart`
- Create: `lib/screens/finanzas/registrar_transaccion_sheet.dart`

**Interfaces:**
- Consumes: `financeAccountsProvider`, `financeTransactionsProvider`, `allFinanceCategoriesProvider`, `AppDatabase` (upsertFinanceTransaction) de Task 3

- [ ] **Step 1: Crear `lib/screens/finanzas/finanzas_transacciones_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:krezium/data/db/database.dart';
import 'package:krezium/data/finance_categories_catalog.dart';
import 'package:krezium/providers/finance_provider.dart';
import 'package:krezium/theme/app_theme.dart';
import 'registrar_transaccion_sheet.dart';

final _mesActivoProvider = StateProvider<String>((ref) {
  return DateFormat('yyyy-MM').format(DateTime.now());
});

class FinanzasTransaccionesScreen extends ConsumerWidget {
  const FinanzasTransaccionesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mes = ref.watch(_mesActivoProvider);
    final txAsync = ref.watch(financeTransactionsProvider(mes));
    final accountsAsync = ref.watch(financeAccountsProvider);
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

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

          // Agrupar por fecha
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
                  child: Center(child: Text('Sin transacciones este mes.\nToca + para registrar una.')),
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
        ).then((_) => ref.invalidate(financeTransactionsProvider)),
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
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
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
      orElse: () => CatalogoCategoria(id: '', nombre: tx.categoryId, icono: Icons.label, color: Colors.grey, tipo: 'gasto'),
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
```

- [ ] **Step 2: Crear `lib/screens/finanzas/registrar_transaccion_sheet.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:krezium/data/db/database.dart';
import 'package:krezium/data/finance_categories_catalog.dart';
import 'package:krezium/providers/finance_provider.dart';

class RegistrarTransaccionSheet extends ConsumerStatefulWidget {
  const RegistrarTransaccionSheet({super.key});

  @override
  ConsumerState<RegistrarTransaccionSheet> createState() => _RegistrarTransaccionSheetState();
}

class _RegistrarTransaccionSheetState extends ConsumerState<RegistrarTransaccionSheet> {
  String _tipo = 'gasto';
  String? _categoryId;
  String? _accountId;
  String _fecha = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final _montoCtrl = TextEditingController();
  final _notaCtrl = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    final monto = double.tryParse(_montoCtrl.text.replaceAll('.', '').replaceAll(',', '.'));
    if (monto == null || monto <= 0 || _categoryId == null || _accountId == null) return;
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    await db.upsertFinanceTransaction(FinanceTransactionsCompanion.insert(
      id: const Uuid().v4(),
      accountId: _accountId!,
      categoryId: _categoryId!,
      tipo: _tipo,
      monto: monto,
      fecha: _fecha,
      nota: Value(_notaCtrl.text),
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(financeAccountsProvider);
    final cats = catalogoFinanzas.where((c) => c.tipo == _tipo || c.tipo == 'ambos').toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nueva transacción', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'ingreso', label: Text('Ingreso'), icon: Icon(Icons.arrow_upward)),
                ButtonSegment(value: 'gasto', label: Text('Gasto'), icon: Icon(Icons.arrow_downward)),
              ],
              selected: {_tipo},
              onSelectionChanged: (s) => setState(() { _tipo = s.first; _categoryId = null; }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _montoCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monto', prefixText: '\$ '),
            ),
            const SizedBox(height: 16),
            Text('Categoría', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cats.map((c) {
                final sel = _categoryId == c.id;
                return FilterChip(
                  avatar: Icon(c.icono, size: 16, color: c.color),
                  label: Text(c.nombre),
                  selected: sel,
                  onSelected: (_) => setState(() => _categoryId = c.id),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            accountsAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error cuentas: $e'),
              data: (accounts) {
                if (accounts.isEmpty) {
                  return const Text('Crea una cuenta primero');
                }
                _accountId ??= accounts.first.id;
                return DropdownButtonFormField<String>(
                  value: _accountId,
                  decoration: const InputDecoration(labelText: 'Cuenta'),
                  items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.nombre))).toList(),
                  onChanged: (v) => setState(() => _accountId = v),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(controller: _notaCtrl, decoration: const InputDecoration(labelText: 'Nota (opcional)')),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: `dart analyze` en archivos nuevos**

```bash
dart analyze lib/screens/finanzas/ 2>&1 | tail -20
```

- [ ] **Step 4: Commit**

```bash
git add lib/screens/finanzas/finanzas_transacciones_screen.dart lib/screens/finanzas/registrar_transaccion_sheet.dart
git commit -m "feat(finanzas): FinanzasTransaccionesScreen + RegistrarTransaccionSheet

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Task 7: FinanzasPresupuestoScreen

**Files:**
- Create: `lib/screens/finanzas/finanzas_presupuesto_screen.dart`

**Interfaces:**
- Consumes: `financeBudgetsProvider`, `financeTransactionsProvider`, `allFinanceCategoriesProvider`

- [ ] **Step 1: Crear `lib/screens/finanzas/finanzas_presupuesto_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:krezium/data/db/database.dart';
import 'package:krezium/data/finance_categories_catalog.dart';
import 'package:krezium/providers/finance_provider.dart';

final _presupuestoMesProvider = StateProvider<DateTime>((ref) => DateTime.now());

class FinanzasPresupuestoScreen extends ConsumerWidget {
  const FinanzasPresupuestoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fecha = ref.watch(_presupuestoMesProvider);
    final budgetsAsync = ref.watch(financeBudgetsProvider((fecha.year, fecha.month)));
    final txMes = ref.watch(financeTransactionsProvider(DateFormat('yyyy-MM').format(fecha)));
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

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
        data: (budgets) => txMes.when(
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
                Text('${fmt.format(gasto)} / ${fmt.format(limite)}', style: TextStyle(color: overLimit ? Colors.red : null)),
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
```

- [ ] **Step 2: `dart analyze`**

```bash
dart analyze lib/screens/finanzas/finanzas_presupuesto_screen.dart 2>&1 | tail -10
```

- [ ] **Step 3: Commit**

```bash
git add lib/screens/finanzas/finanzas_presupuesto_screen.dart
git commit -m "feat(finanzas): FinanzasPresupuestoScreen con barras de progreso

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Task 8: FinanzasEstadisticasScreen

**Files:**
- Create: `lib/screens/finanzas/finanzas_estadisticas_screen.dart`

**Interfaces:**
- Consumes: `financeTransactionsProvider`, `financeAccountsProvider`, fl_chart (ya instalado como `fl_chart`)

- [ ] **Step 1: Crear `lib/screens/finanzas/finanzas_estadisticas_screen.dart`**

```dart
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
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

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
                    sections: top5.asMap().entries.map((e) {
                      final cat = catalogoFinanzas.firstWhere(
                        (c) => c.id == e.value.key,
                        orElse: () => CatalogoCategoria(id: '', nombre: e.value.key, icono: Icons.label, color: Colors.grey, tipo: 'gasto'),
                      );
                      return PieChartSectionData(
                        value: e.value.value,
                        color: cat.color,
                        title: cat.nombre,
                        titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
                        radius: 80,
                      );
                    }).toList(),
                    centerSpaceRadius: 0,
                  )),
                ),
                const SizedBox(height: 24),
              ],
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
                        final ing = txs.where((t) => t.accountId == a.id && t.tipo == 'ingreso').fold(0.0, (s, t) => s + t.monto);
                        final gas = txs.where((t) => t.accountId == a.id && t.tipo == 'gasto').fold(0.0, (s, t) => s + t.monto);
                        final saldo = a.saldoInicial + ing - gas;
                        return ListTile(
                          title: Text(a.nombre),
                          trailing: Text(fmt.format(saldo), style: TextStyle(color: saldo >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
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
```

- [ ] **Step 2: `dart analyze`**

```bash
dart analyze lib/screens/finanzas/finanzas_estadisticas_screen.dart 2>&1 | tail -10
```

- [ ] **Step 3: Commit**

```bash
git add lib/screens/finanzas/finanzas_estadisticas_screen.dart
git commit -m "feat(finanzas): FinanzasEstadisticasScreen con gráfica torta + saldo cuentas

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Task 9: Cuenta — opción vista principal + Export/Import + versión 2.0.0+19

**Files:**
- Modify: `lib/screens/account/account_screen.dart` — opción "Vista principal"
- Modify: `lib/domain/export_import.dart` — bloque finanzas
- Modify: `lib/data/changelog.dart` — entrada 2.0.0
- Modify: `pubspec.yaml` — versión 2.0.0+19

**Interfaces:**
- Consumes: `entornoProvider`, `savePreferredEntorno`, `AppDatabase` (getFinanceAccounts etc.), modelos de Task 2

- [ ] **Step 1: Leer account_screen.dart y export_import.dart**

Leer ambos archivos antes de modificar.

- [ ] **Step 2: Agregar "Vista principal" en AccountScreen**

Localizar la sección "General" (o similar) en `account_screen.dart` y agregar:

```dart
ListTile(
  leading: const Icon(Icons.swap_horiz),
  title: const Text('Vista principal'),
  subtitle: Text(ref.watch(entornoProvider) == Entorno.creditos ? 'Créditos' : 'Finanzas'),
  onTap: () async {
    final current = ref.read(entornoProvider);
    final next = current == Entorno.creditos ? Entorno.finanzas : Entorno.creditos;
    ref.read(entornoProvider.notifier).state = next;
    await savePreferredEntorno(next);
  },
),
```

- [ ] **Step 3: Modificar export_import.dart**

Agregar bloque `finanzas` al JSON de exportación e importación:

```dart
// En exportToJson():
'finanzas': {
  'accounts': accounts.map((a) => FinanceAccount.fromRow(a).toJson()).toList(),
  'categories': categories.map((c) => FinanceCategory.fromRow(c).toJson()).toList(),
  'transactions': transactions.map((t) => FinanceTransaction.fromRow(t).toJson()).toList(),
  'budgets': budgets.map((b) => FinanceBudget.fromRow(b).toJson()).toList(),
},

// En importFromJson():
final finanzasBlock = json['finanzas'] as Map<String, dynamic>?;
if (finanzasBlock != null) {
  // importar accounts, categories, transactions, budgets
}
// Si finanzasBlock == null: ignorar silenciosamente (backup anterior)
```

- [ ] **Step 4: Agregar entrada 2.0.0 en changelog.dart**

```dart
VersionEntry(
  version: '2.0.0',
  date: 'Octubre 2026',
  changes: [
    ChangeItem(ChangeType.nuevo, 'Módulo Finanzas: registra gastos e ingresos con categorías, cuentas y presupuesto mensual.'),
    ChangeItem(ChangeType.nuevo, 'Navegación dual: alterna entre el entorno de Créditos y Finanzas con el botón central del nav.'),
    ChangeItem(ChangeType.nuevo, 'Catálogo de 30 categorías predefinidas para clasificar gastos e ingresos, con soporte para categorías personalizadas.'),
    ChangeItem(ChangeType.nuevo, 'Estadísticas de Finanzas: gráfica de gastos por categoría y saldo actual de cada cuenta/bolsillo.'),
    ChangeItem(ChangeType.nuevo, 'Al instalar Krezium por primera vez, puedes elegir qué vista quieres ver al abrirla.'),
    ChangeItem(ChangeType.mejora, 'Los respaldos incluyen ahora los datos de Finanzas. Los respaldos anteriores se siguen importando sin cambios.'),
  ],
),
```

- [ ] **Step 5: Actualizar pubspec.yaml**

```
version: 1.1.0+18 → version: 2.0.0+19
```

- [ ] **Step 6: `dart analyze` general**

```bash
dart analyze lib/ 2>&1 | grep -E "error|warning" | head -30
```

- [ ] **Step 7: Commit final**

```bash
git add lib/screens/account/account_screen.dart lib/domain/export_import.dart lib/data/changelog.dart pubspec.yaml
git commit -m "release: v2.0.0+19 — módulo Finanzas + navegación dual

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```
