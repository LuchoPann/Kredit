# Krezium — Finanzas v2.1.0 Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rediseñar completamente el módulo Finanzas: sistema de libros de registro, categorías jerárquicas, plantillas, formulario de registro en 2 pasos con campos enriquecidos, y filtros de visualización.

**Architecture:** Finanzas pasa de 3 pantallas básicas a un sistema completo con `FinanzasCuentasScreen` (Tab 0), `FinanzasPlantillasScreen` (Tab 1), `FinanzasEstadisticasScreen` (Tab 2). Nueva pantalla `FinanzasLibroTransaccionesScreen` empujada desde Tab 0. schemaVersion 13→14.

**Tech Stack:** Flutter, Riverpod (StateProvider, FutureProvider, FutureProvider.family), Drift ORM, shared_preferences, fl_chart (ya instalado).

**Spec:** `docs/superpowers/specs/2026-10-09-krezium-finanzas-v2-redesign.md`

## Global Constraints

- App 100% offline. Sin internet, sin cuentas.
- Solo COP. Sin multidivisa.
- `schemaVersion` pasa 13→14. Migración `addColumn` + `createTable`.
- Ninguna tabla de créditos se modifica.
- Todo campo nuevo en `fromJson` debe ser nullable con default — backups v2.0.0 deben importar sin error: `json['field'] as Type? ?? default`.
- Versión final: `2.1.0+20`.
- **UI/UX priority:** Cada pantalla debe sentirse intuitiva y pulida. Usar animaciones suaves (`AnimatedSwitcher`, `Hero`), empty states claros con CTAs accionables, haptic feedback en acciones clave, y jerarquía visual consistente. Preferir interacciones por gestos (swipe para borrar) sobre menús enterrados. Color-code consistente: ingresos = verde (`Color(0xFF22C55E)`), gastos = rojo (`Color(0xFFEF4444)`), transferencias = azul. Cada sheet debe tener título claro y escape (botón X o gesto back). El objetivo es una app que deleite al usuario, no solo que funcione.

## Review Focus

1. **Migración en instalaciones existentes** — schemaVersion 13→14, nuevas columnas nullable, nuevas tablas. Tablas existentes intactas.
2. **Backup v2.0.0 importado en v2.1.0** — campos nuevos ausentes → valores por defecto, sin excepción.
3. **Libro predeterminado auto-push** — si existe `finanzas_libro_default`, Tab 0 empuja `FinanzasLibroTransaccionesScreen` automáticamente con `addPostFrameCallback`.
4. **Árbol jerárquico de categorías** — `parentId == null` → categoría padre; `parentId != null` → subcategoría. La UI del selector debe mostrar ambos niveles.
5. **Filtros de transacciones** — `FinanzasFiltros` (periodo, ascending, densidad, tipoFiltro) deben filtrar correctamente la lista sin crashes.

---

## File Structure

**Nuevos archivos:**
- `lib/data/finance_icon_map.dart` — Map<String, IconData> + iconFromKey()
- `lib/data/finanzas_filtros.dart` — FinanzasFiltros class
- `lib/screens/finanzas/finanzas_cuentas_screen.dart`
- `lib/screens/finanzas/finanzas_libro_transacciones_screen.dart`
- `lib/screens/finanzas/nueva_transaccion_sheet.dart`
- `lib/screens/finanzas/categoria_selector_sheet.dart`
- `lib/screens/finanzas/finanzas_plantillas_screen.dart`
- `lib/screens/finanzas/editar_plantilla_sheet.dart`

**Archivos modificados:**
- `lib/data/db/tables_finance.dart` — agregar columnas + nuevas tablas
- `lib/data/db/database.dart` — schemaVersion 13→14, migración, CRUD nuevos
- `lib/data/models/finance_models.dart` — campos nuevos + FinancePlace + FinanceTemplate
- `lib/data/finance_categories_catalog.dart` — agregar iconoKey + parentId
- `lib/providers/finance_provider.dart` — nuevos providers + filtros
- `lib/screens/finanzas/finanzas_estadisticas_screen.dart` — rediseño completo
- `lib/main.dart` — tabs finanzas (Cuentas/Plantillas/Estadísticas)
- `pubspec.yaml` — versión 2.1.0+20
- `lib/data/changelog.dart` — entrada v2.1.0

**Archivos a eliminar:**
- `lib/screens/finanzas/registrar_transaccion_sheet.dart`
- `lib/screens/finanzas/finanzas_transacciones_screen.dart`
- `lib/screens/finanzas/finanzas_presupuesto_screen.dart`

---

### Task 1: DB Schema v14 — columnas + tablas nuevas + migración

**Files:**
- Modify: `lib/data/db/tables_finance.dart`
- Modify: `lib/data/db/database.dart`

**Interfaces:**
- Produces: `FinanceAccountRow` (con `esFavorito`), `FinanceCategoryRow` (con `parentId`), `FinanceTransactionRow` (con `personaSitio`, `hora`, `transferToAccountId`), `FinancePlaceRow`, `FinanceTemplateRow`

- [ ] **Step 1: Agregar columnas a tablas existentes en `tables_finance.dart`**

```dart
// En FinanceAccounts — agregar al final de la clase:
BoolColumn get esFavorito => boolean().withDefault(const Constant(false))();

// En FinanceCategories — agregar al final de la clase:
TextColumn get parentId => text().nullable()
    .references(FinanceCategories, #id, onDelete: KeyAction.setNull)();

// En FinanceTransactions — agregar al final de la clase:
TextColumn get personaSitio => text().nullable()();
TextColumn get hora => text().nullable()(); // "HH:mm"
TextColumn get transferToAccountId => text().nullable()
    .references(FinanceAccounts, #id, onDelete: KeyAction.setNull)();
```

- [ ] **Step 2: Agregar nuevas tablas `FinancePlaces` y `FinanceTemplates` en `tables_finance.dart`**

```dart
@DataClassName('FinancePlaceRow')
class FinancePlaces extends Table {
  TextColumn get id => text()();
  TextColumn get nombre => text()();
  IntColumn get usados => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('FinanceTemplateRow')
class FinanceTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get nombre => text()();
  TextColumn get libroId => text().nullable()
      .references(FinanceAccounts, #id, onDelete: KeyAction.setNull)();
  TextColumn get categoryId => text()();
  TextColumn get tipo => text()(); // 'ingreso'|'gasto'
  RealColumn get monto => real().nullable()();
  TextColumn get personaSitio => text().nullable()();
  TextColumn get nota => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

- [ ] **Step 3: Actualizar `database.dart`**

Registrar las nuevas tablas en `@DriftDatabase(tables: [...])`:
```dart
FinancePlaces, FinanceTemplates
```

Subir schemaVersion a 14:
```dart
@override
int get schemaVersion => 14;
```

Agregar bloque de migración:
```dart
if (from < 14) {
  await m.addColumn(financeAccounts, financeAccounts.esFavorito);
  await m.addColumn(financeCategories, financeCategories.parentId);
  await m.addColumn(financeTransactions, financeTransactions.personaSitio);
  await m.addColumn(financeTransactions, financeTransactions.hora);
  await m.addColumn(financeTransactions, financeTransactions.transferToAccountId);
  await m.createTable(financePlaces);
  await m.createTable(financeTemplates);
}
```

- [ ] **Step 4: Agregar métodos CRUD en `database.dart`**

```dart
// FinancePlaces
Future<List<FinancePlaceRow>> getFinancePlaces() =>
    (select(financePlaces)..orderBy([(t) => OrderingTerm.desc(t.usados)])).get();

Future<void> upsertFinancePlace(FinancePlacesCompanion place) =>
    into(financePlaces).insertOnConflictUpdate(place);

// FinanceTemplates
Future<List<FinanceTemplateRow>> getFinanceTemplates({String? tipo}) {
  final q = select(financeTemplates);
  if (tipo != null) q.where((t) => t.tipo.equals(tipo));
  return q.get();
}

Future<void> upsertFinanceTemplate(FinanceTemplatesCompanion template) =>
    into(financeTemplates).insertOnConflictUpdate(template);

Future<void> deleteFinanceTemplate(String id) =>
    (delete(financeTemplates)..where((t) => t.id.equals(id))).go();

// Transacciones por libro con filtros
Future<List<FinanceTransactionRow>> getFinanceTransactionsByLibro({
  required String libroId,
  String? mes, // 'YYYY-MM'
  String? tipo, // 'ingreso'|'gasto'|null
  bool ascending = false,
}) {
  final q = select(financeTransactions)
    ..where((t) => t.accountId.equals(libroId));
  if (mes != null) q.where((t) => t.fecha.like('$mes%'));
  if (tipo != null) q.where((t) => t.tipo.equals(tipo));
  q.orderBy([(t) => ascending
      ? OrderingTerm.asc(t.fecha)
      : OrderingTerm.desc(t.fecha)]);
  return q.get();
}
```

- [ ] **Step 5: Ejecutar `dart run build_runner build --delete-conflicting-outputs` y confirmar sin errores**

- [ ] **Step 6: `flutter analyze` — cero errores**

- [ ] **Commit:** `feat(db): schema v14 — libros favorito, categorías parentId, transacciones enriquecidas, lugares, plantillas`

---

### Task 2: Modelos + IconMap + Catálogo de categorías

**Files:**
- Modify: `lib/data/models/finance_models.dart`
- Modify: `lib/data/finance_categories_catalog.dart`
- Create: `lib/data/finance_icon_map.dart`

**Interfaces:**
- Consumes: Drift rows de Task 1 (`FinancePlaceRow`, `FinanceTemplateRow`, columnas nuevas)
- Produces: `FinanceTransaction` (con `personaSitio`, `hora`, `transferToAccountId`), `FinanceCategory` (con `parentId`), `FinanceAccount` (con `esFavorito`), `FinancePlace`, `FinanceTemplate`, `financeIconMap`, `iconFromKey()`

- [ ] **Step 1: Actualizar `finance_models.dart`**

```dart
class FinanceAccount {
  // ... campos existentes ...
  final bool esFavorito; // default false

  // fromRow: esFavorito: row.esFavorito
  // fromJson: esFavorito: json['esFavorito'] as bool? ?? false
}

class FinanceCategory {
  // ... campos existentes ...
  final String? parentId; // null = categoría padre

  // fromRow: parentId: row.parentId
  // fromJson: parentId: json['parentId'] as String?
}

class FinanceTransaction {
  // ... campos existentes ...
  final String? personaSitio;
  final String? hora; // "HH:mm"
  final String? transferToAccountId;

  // fromRow y fromJson con nullables
}

class FinancePlace {
  final String id;
  final String nombre;
  final int usados;

  const FinancePlace({required this.id, required this.nombre, required this.usados});

  factory FinancePlace.fromRow(FinancePlaceRow row) =>
      FinancePlace(id: row.id, nombre: row.nombre, usados: row.usados);
}

class FinanceTemplate {
  final String id;
  final String nombre;
  final String? libroId;
  final String categoryId;
  final String tipo; // 'ingreso'|'gasto'
  final double? monto;
  final String? personaSitio;
  final String? nota;

  const FinanceTemplate({
    required this.id, required this.nombre, this.libroId,
    required this.categoryId, required this.tipo,
    this.monto, this.personaSitio, this.nota,
  });

  factory FinanceTemplate.fromRow(FinanceTemplateRow row) => FinanceTemplate(
    id: row.id, nombre: row.nombre, libroId: row.libroId,
    categoryId: row.categoryId, tipo: row.tipo, monto: row.monto,
    personaSitio: row.personaSitio, nota: row.nota,
  );
}
```

- [ ] **Step 2: Crear `lib/data/finance_icon_map.dart`**

```dart
import 'package:flutter/material.dart';

const Map<String, IconData> financeIconMap = {
  // Ingresos
  'work': Icons.work_outline,
  'laptop': Icons.laptop_outlined,
  'store': Icons.store_outlined,
  'trending_up': Icons.trending_up,
  'account_balance': Icons.account_balance_outlined,
  'card_giftcard': Icons.card_giftcard_outlined,
  'attach_money': Icons.attach_money,
  // Gastos
  'restaurant': Icons.restaurant_outlined,
  'local_grocery_store': Icons.local_grocery_store_outlined,
  'directions_car': Icons.directions_car_outlined,
  'local_gas_station': Icons.local_gas_station_outlined,
  'home': Icons.home_outlined,
  'bolt': Icons.bolt_outlined,
  'water_drop': Icons.water_drop_outlined,
  'wifi': Icons.wifi_outlined,
  'phone': Icons.phone_outlined,
  'local_hospital': Icons.local_hospital_outlined,
  'medication': Icons.medication_outlined,
  'school': Icons.school_outlined,
  'menu_book': Icons.menu_book_outlined,
  'movie': Icons.movie_outlined,
  'sports_esports': Icons.sports_esports_outlined,
  'music_note': Icons.music_note_outlined,
  'checkroom': Icons.checkroom_outlined,
  'devices': Icons.devices_outlined,
  'flight': Icons.flight_outlined,
  'hotel': Icons.hotel_outlined,
  'pets': Icons.pets_outlined,
  'fitness_center': Icons.fitness_center_outlined,
  'savings': Icons.savings_outlined,
  'credit_card': Icons.credit_card_outlined,
  'swap_horiz': Icons.swap_horiz_outlined,
  'more_horiz': Icons.more_horiz,
};

IconData iconFromKey(String? key) =>
    key != null ? (financeIconMap[key] ?? Icons.label_outline) : Icons.label_outline;
```

- [ ] **Step 3: Actualizar `finance_categories_catalog.dart`** — agregar campo `iconoKey String` a `CatalogoCategoria` y `parentId String?`. Actualizar las 30 entradas con claves del `financeIconMap`. Ejemplo:

```dart
class CatalogoCategoria {
  final String id;
  final String nombre;
  final String icono; // string emoji o nombre legacy
  final String iconoKey; // clave para financeIconMap
  final String color;
  final String tipo; // 'ingreso'|'gasto'|'ambos'
  final String? parentId; // null = es padre
}
```

Agregar las categorías padre (nuevas IDs): `'cat_sueldo_padre'`, `'cat_negocio_padre'`, etc., con `parentId = null`. Las 30 existentes quedan con `parentId` apuntando al padre correspondiente.

- [ ] **Step 4: `flutter analyze` — cero errores**

- [ ] **Commit:** `feat(models): FinancePlace, FinanceTemplate, iconMap, categorías jerárquicas`

---

### Task 3: Providers — filtros + nuevos providers

**Files:**
- Create: `lib/data/finanzas_filtros.dart`
- Modify: `lib/providers/finance_provider.dart`

**Interfaces:**
- Consumes: `AppDatabase` methods de Task 1, modelos de Task 2
- Produces: `financePlacesProvider`, `financeTemplatesByTipoProvider`, `finanzasFiltrosProvider`, `finanzasLibroActivoProvider`, `finanzasLibroTxProvider`

- [ ] **Step 1: Crear `lib/data/finanzas_filtros.dart`**

```dart
class FinanzasFiltros {
  final String periodo;   // 'diario'|'semanal'|'mensual'|'todo'
  final bool ascending;
  final String densidad;  // 'comodo'|'compacto'
  final String tipoFiltro; // 'todos'|'ingreso'|'gasto'

  const FinanzasFiltros({
    this.periodo = 'mensual',
    this.ascending = false,
    this.densidad = 'comodo',
    this.tipoFiltro = 'todos',
  });

  FinanzasFiltros copyWith({
    String? periodo,
    bool? ascending,
    String? densidad,
    String? tipoFiltro,
  }) => FinanzasFiltros(
    periodo: periodo ?? this.periodo,
    ascending: ascending ?? this.ascending,
    densidad: densidad ?? this.densidad,
    tipoFiltro: tipoFiltro ?? this.tipoFiltro,
  );
}
```

- [ ] **Step 2: Agregar providers en `finance_provider.dart`**

```dart
// Lugares (ordenante autocomplete)
final financePlacesProvider = FutureProvider<List<FinancePlace>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final rows = await db.getFinancePlaces();
  return rows.map(FinancePlace.fromRow).toList();
});

// Plantillas por tipo
final financeTemplatesByTipoProvider = FutureProvider.family<List<FinanceTemplate>, String?>((ref, tipo) async {
  final db = ref.watch(appDatabaseProvider);
  final rows = await db.getFinanceTemplates(tipo: tipo);
  return rows.map(FinanceTemplate.fromRow).toList();
});

// Filtros activos
final finanzasFiltrosProvider = StateProvider<FinanzasFiltros>(
  (_) => const FinanzasFiltros(),
);

// Libro activo (ID del libro seleccionado en Tab 0)
final finanzasLibroActivoProvider = StateProvider<String?>((_) => null);

// Transacciones del libro activo
final finanzasLibroTxProvider = FutureProvider.family<List<FinanceTransaction>, String>((ref, libroId) async {
  final db = ref.watch(appDatabaseProvider);
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
```

También actualizar `allFinanceCategoriesProvider` existente para que devuelva lista completa (incluyendo `parentId`).

- [ ] **Step 3: `flutter analyze` — cero errores**

- [ ] **Commit:** `feat(providers): FinanzasFiltros, places, templates, libro activo`

---

### Task 4: CategoriaSelectorSheet

**Files:**
- Create: `lib/screens/finanzas/categoria_selector_sheet.dart`

**Interfaces:**
- Consumes: `allFinanceCategoriesProvider` (Task 3), `financeIconMap` (Task 2)
- Produces: `showCategoriaSelectorSheet(context, tipo, onSelected)` — retorna `FinanceCategory` seleccionada

**UX notes:**
- Toggle `[Gasto] [Ingreso]` arriba — usa `SegmentedButton` de Material 3
- Árbol de 2 niveles: categorías padre expandibles/contraíbles con `AnimatedSize`
- Subcategorías indentadas con `Padding(left: 32)`, ícono pequeño + nombre
- Tap en subcategoría → selección inmediata, haptic `HapticFeedback.lightImpact()`, cierra el sheet
- Cada fila de categoría muestra un círculo coloreado con el ícono
- Sin scroll horizontal — solo vertical

- [ ] **Step 1: Implementar el sheet**

```dart
Future<FinanceCategory?> showCategoriaSelectorSheet(
  BuildContext context,
  String tipo,
) async {
  return showModalBottomSheet<FinanceCategory>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CategoriaSelectorSheet(tipoInicial: tipo),
  );
}

class _CategoriaSelectorSheet extends ConsumerStatefulWidget {
  final String tipoInicial; // 'gasto'|'ingreso'
  ...
}
```

- El sheet tiene `DraggableScrollableSheet` que ocupa hasta 90% de pantalla.
- Estado interno: `_tipo` (toggle), `_expandidos` Set<String> (IDs de padres abiertos).
- `allFinanceCategoriesProvider` devuelve lista flat; el widget agrupa: padres = `parentId == null && tipo == _tipo`, hijos = `parentId == padreId`.
- Botón "+" en AppBar del sheet → abre `EditarCategoriaSheet` (simplificado: solo nombre + tipo + ícono; fuera del scope de esta tarea, mostrar un `SnackBar` "Próximamente" si se toca).

- [ ] **Step 2: `flutter analyze` — cero errores**

- [ ] **Commit:** `feat(finanzas): CategoriaSelectorSheet con árbol jerárquico`

---

### Task 5: NuevaTransaccionSheet — formulario 2 pasos

**Files:**
- Create: `lib/screens/finanzas/nueva_transaccion_sheet.dart`

**Interfaces:**
- Consumes: `financeAccountsProvider`, `financePlacesProvider` (Task 3), `showCategoriaSelectorSheet` (Task 4), `AppDatabase` (upsertFinancePlace, addFinanceTransaction)
- Produces: `showNuevaTransaccionSheet(context, {libroId?, template?})` — guarda en DB, retorna void

**UX notes:**
- **Paso 1** se siente como picker rápido, no formulario. Toggle grande tipo con 3 opciones (Ingreso/Gasto/Transferencia), selector de libro (Card prominente), botón "Continuar →". Animación `Hero` en el ícono del libro.
- **Transición Paso 1 → Paso 2** con `AnimatedSwitcher` (slideTransition de derecha a izquierda).
- **Paso 2**: campo Importe auto-focaliza al entrar. Campo grande, numérico, con texto de `es_CO`. Chip de Categoría muestra círculo coloreado + nombre una vez seleccionada. Fecha/hora con chips de flechas.
- Haptic `HapticFeedback.mediumImpact()` al guardar.
- Si se pasa `template`, auto-rellena todos los campos del Paso 2 y salta directo a él.

- [ ] **Step 1: Implementar flujo de 2 pasos**

```dart
Future<void> showNuevaTransaccionSheet(
  BuildContext context, {
  String? libroId,
  FinanceTemplate? template,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _NuevaTransaccionSheet(
      libroIdInicial: libroId,
      template: template,
    ),
  );
}
```

Estado interno: `_paso` (1 o 2), `_tipo` ('ingreso'|'gasto'|'transferencia'), `_libroId`, `_categoriaSeleccionada`, `_monto`, `_fecha`, `_hora` (auto `TimeOfDay.now()`), `_ordenante` (TextEditingController), `_nota` (TextEditingController).

Paso 1:
- `SegmentedButton` con 3 opciones: Ingreso / Gasto / Transferencia
- `DropdownButton` o `Card` lista de libros disponibles
- Si Transferencia: segundo selector de libro destino
- Botón "Continuar →"

Paso 2:
- Campo importe: `TextField` con `keyboardType: TextInputType.numberWithOptions(decimal: true)`, font grande (28sp)
- Fecha: `Row` con `IconButton` ←, `TextButton` (fecha legible, abre `DatePicker`), `IconButton` →
- Hora: igual que fecha, con `TimePicker`
- Ordenante: `Autocomplete<FinancePlaceRow>` mostrando los guardados ordenados por `usados`
- Categoría: `OutlinedButton` con ícono coloreado si hay selección
- Notas: `TextField` opcional
- Botón "Guardar" — al guardar: upsert en FinancePlaces si hay ordenante nuevo, guardar transacción, haptic, pop

- [ ] **Step 2: `flutter analyze` — cero errores**

- [ ] **Commit:** `feat(finanzas): NuevaTransaccionSheet flujo 2 pasos`

---

### Task 6: FinanzasCuentasScreen (Tab 0)

**Files:**
- Create: `lib/screens/finanzas/finanzas_cuentas_screen.dart`
- Delete: `lib/screens/finanzas/finanzas_transacciones_screen.dart` (reemplazada)

**Interfaces:**
- Consumes: `financeAccountsProvider`, SharedPreferences `finanzas_libro_default`, `showNuevaTransaccionSheet` (Task 5)
- Produces: `FinanzasCuentasScreen` — exportada para `main.dart`

**UX notes:**
- Cada card de libro tiene borde izquierdo sutil en el color del libro (`Container` con `decoration: BoxDecoration(border: Border(left: BorderSide(color: libroColor, width: 4)))`).
- Balance mostrado grande (18sp bold), ingresos/gastos en tamaño secundario.
- Swipe derecho en card → marcar como favorito (con haptic + SnackBar "Libro predeterminado").
- Push con `Hero` en el ícono del libro: `tag: 'libro_icon_${libro.id}'`.
- Empty state: `Column` centrado, ícono `Icons.book_outlined` grande, texto "Crea tu primer libro de registro", botón "Crear libro".
- `addPostFrameCallback` en `initState`: si hay `finanzas_libro_default` en SharedPreferences y la lista no está vacía, empujar `FinanzasLibroTransaccionesScreen` automáticamente.

- [ ] **Step 1: Implementar `FinanzasCuentasScreen`**

```dart
class FinanzasCuentasScreen extends ConsumerStatefulWidget {
  const FinanzasCuentasScreen({super.key});
  ...
}
```

- `initState` con `addPostFrameCallback` para auto-push libro predeterminado.
- `AppBar` con acciones: [IconButton ajustes categorías → SnackBar "Próximamente"], [IconButton `add` → `_mostrarNuevoLibroSheet()`].
- `ListView.builder` de `financeAccountsProvider`.
- FAB con `Icons.add` → `_mostrarNuevoLibroSheet()`.
- `_LibroCard` widget separado con `Dismissible` para swipe-derecho favorito.

- [ ] **Step 2: Eliminar archivo viejo `finanzas_transacciones_screen.dart`**

- [ ] **Step 3: `flutter analyze` — cero errores**

- [ ] **Commit:** `feat(finanzas): FinanzasCuentasScreen con libros, favorito, auto-push`

---

### Task 7: FinanzasLibroTransaccionesScreen

**Files:**
- Create: `lib/screens/finanzas/finanzas_libro_transacciones_screen.dart`

**Interfaces:**
- Consumes: `finanzasLibroTxProvider(libroId)` (Task 3), `finanzasFiltrosProvider` (Task 3), `financeAccountsProvider`, `showNuevaTransaccionSheet` (Task 5), `AppDatabase.deleteFinanceTransaction`
- Produces: `FinanzasLibroTransaccionesScreen({required FinanceAccount libro})`

**UX notes:**
- Day headers: "Hoy", "Ayer", o fecha legible para días anteriores. Header muestra subtotal del día.
- Swipe izquierda en transacción → eliminar con `Dismissible`, mostrar SnackBar con "Deshacer" (`ScaffoldMessenger.of(context).showSnackBar(...).closed.then(...)` para restaurar si toca deshacer).
- Monto con `fontFeatures: [FontFeature.tabularFigures()]` para alineación.
- Pull-to-refresh con `RefreshIndicator` que invalida `finanzasLibroTxProvider`.
- Panel de filtros: `BottomSheet` no modal con los 4 controles de `FinanzasFiltros`.
- FAB dual: botón principal `+`, botón secundario plantilla (FAB pequeño arriba del principal).
- Header colapsable con resumen del período: Ingresos / Gastos / Balance.
- Dropdown en AppBar title para cambiar de libro sin retroceder.

- [ ] **Step 1: Implementar la pantalla**

```dart
class FinanzasLibroTransaccionesScreen extends ConsumerStatefulWidget {
  final FinanceAccount libro;
  const FinanzasLibroTransaccionesScreen({super.key, required this.libro});
  ...
}
```

- `CustomScrollView` con `SliverAppBar` colapsable.
- Agrupación de transacciones por fecha (Map<String, List<FinanceTransaction>>).
- Cada grupo: `SliverStickyHeader` o `SliverList` con header de fecha.
- Fila cómoda: ícono categoría + nombre categoría/subcategoría (bold) / nota · ordenante (subtitle) + monto con color + hora.
- Fila compacta: sin subtitle, menor `ListTile.minVerticalPadding`.

- [ ] **Step 2: `flutter analyze` — cero errores**

- [ ] **Commit:** `feat(finanzas): FinanzasLibroTransaccionesScreen con filtros, swipe, undo`

---

### Task 8: FinanzasPlantillasScreen + EditarPlantillaSheet

**Files:**
- Create: `lib/screens/finanzas/finanzas_plantillas_screen.dart`
- Create: `lib/screens/finanzas/editar_plantilla_sheet.dart`
- Delete: `lib/screens/finanzas/finanzas_presupuesto_screen.dart` (reemplazada)

**Interfaces:**
- Consumes: `financeTemplatesByTipoProvider` (Task 3), `showCategoriaSelectorSheet` (Task 4), `showNuevaTransaccionSheet` (Task 5), `AppDatabase.upsertFinanceTemplate`, `AppDatabase.deleteFinanceTemplate`
- Produces: `FinanzasPlantillasScreen`

**UX notes:**
- Cards de plantillas muestran preview de cómo quedará la transacción: "Categoría > Subcategoría · $monto" con los colores correctos (verde/rojo).
- Tap en plantilla → `showNuevaTransaccionSheet(context, template: template)` con animación satisfactoria. Usar `HapticFeedback.selectionClick()`.
- Toggle `[Gastos] [Ingresos]` con `SegmentedButton`. Animación `AnimatedSwitcher` al cambiar.
- Swipe izquierda → eliminar con confirmación `showDialog`.
- FAB: crear nueva plantilla → `showEditarPlantillaSheet`.
- Empty state por tipo: "No hay plantillas de gastos. Crea una para agilizar tus registros."

- [ ] **Step 1: Implementar `FinanzasPlantillasScreen`**

```dart
class FinanzasPlantillasScreen extends ConsumerStatefulWidget {
  const FinanzasPlantillasScreen({super.key});
  ...
}
```

- [ ] **Step 2: Implementar `EditarPlantillaSheet`**

Campos: nombre (requerido), tipo (ingreso/gasto), libro (opcional), categoría (selector), monto (opcional), ordenante (opcional), nota (opcional).

```dart
Future<void> showEditarPlantillaSheet(
  BuildContext context, {
  FinanceTemplate? template, // null = nueva
}) async { ... }
```

- [ ] **Step 3: Eliminar `finanzas_presupuesto_screen.dart`**

- [ ] **Step 4: `flutter analyze` — cero errores**

- [ ] **Commit:** `feat(finanzas): FinanzasPlantillasScreen + EditarPlantillaSheet`

---

### Task 9: FinanzasEstadisticasScreen — rediseño completo

**Files:**
- Modify: `lib/screens/finanzas/finanzas_estadisticas_screen.dart`

**Interfaces:**
- Consumes: `financeAccountsProvider`, `allFinanceCategoriesProvider`, `finanzasFiltrosProvider` (Task 3), `fl_chart` (PieChart, BarChart)
- Produces: `FinanzasEstadisticasScreen` rediseñada

**UX notes:**
- PieChart (donut) con `touchCallback` — al tocar una sección, mostrar tooltip con nombre de categoría + monto + porcentaje.
- BarChart con animación `BarChartData(barTouchData: ...)` y `Duration(milliseconds: 600)` al cargar.
- Empty state POR SECCIÓN, no uno global. Si no hay gastos del mes, mostrar empty en la sección del pie; el bar chart puede mostrar barras vacías del historial de 6 meses.
- Selector de período con flechas `← oct 2026 →` en el header.
- Presupuesto: `LinearProgressIndicator` por categoría, con anillo `ProgressRing` total arriba.
- Balance por libro: lista compacta de todos los libros con su saldo.

- [ ] **Step 1: Rediseñar la pantalla**

Secciones en `CustomScrollView`:
1. Header: selector de período
2. `AppSectionCard` → PieChart top 5 gastos (donut, `PieChart` de fl_chart, `PieChartData(centerSpaceRadius: 40)`)
3. `AppSectionCard` → BarChart tendencia 6 meses (barras ingresos verde + gastos rojo lado a lado)
4. `AppSectionCard` → Presupuesto del mes (`LinearProgressIndicator` por categoría)
5. `AppSectionCard` → Balance por libro (lista compacta)

FAB: agregar/editar límite de presupuesto → `EditarPresupuestoSheet` (nuevo, simple: categoría + monto límite + mes).

- [ ] **Step 2: `flutter analyze` — cero errores**

- [ ] **Commit:** `feat(finanzas): FinanzasEstadisticasScreen rediseño con gráficas interactivas`

---

### Task 10: main.dart nav update + versión 2.1.0+20 + changelog + limpieza

**Files:**
- Modify: `lib/main.dart`
- Modify: `pubspec.yaml`
- Modify: `lib/data/changelog.dart`
- Delete: `lib/screens/finanzas/registrar_transaccion_sheet.dart`

**Interfaces:**
- Consumes: `FinanzasCuentasScreen` (Task 6), `FinanzasPlantillasScreen` (Task 8), `FinanzasEstadisticasScreen` (Task 9)

- [ ] **Step 1: Actualizar tabs de Finanzas en `main.dart`**

```dart
// Reemplazar finanzasScreens:
final finanzasScreens = const [
  FinanzasCuentasScreen(),
  FinanzasPlantillasScreen(),
  FinanzasEstadisticasScreen(),
];
```

Actualizar íconos del NavigationBar para Finanzas:
```dart
// Tab 0: wallet (Cuentas)
NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Cuentas'),
// Tab 1: description (Plantillas)
NavigationDestination(icon: Icon(Icons.description_outlined), label: 'Plantillas'),
// Tab 2 (switch): ya existente
// Tab 3: bar_chart (Estadísticas)
NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'Estadísticas'),
// Tab 4: person (Cuenta)
NavigationDestination(icon: Icon(Icons.person_outline), label: 'Cuenta'),
```

Actualizar imports: agregar las 3 nuevas pantallas, eliminar imports de las 3 eliminadas.

- [ ] **Step 2: Eliminar `registrar_transaccion_sheet.dart`**

- [ ] **Step 3: Bump versión en `pubspec.yaml`**
```yaml
version: 2.1.0+20
```

- [ ] **Step 4: Agregar entrada en `lib/data/changelog.dart`**

```dart
ChangelogEntry(
  version: '2.1.0',
  date: '2026-10-10',
  changes: [
    'Módulo Finanzas rediseñado: sistema de libros de registro',
    'Categorías jerárquicas con íconos personalizables',
    'Plantillas de transacciones reutilizables',
    'Formulario de registro en 2 pasos con campo de ordenante',
    'Filtros de visualización: período, orden, densidad, tipo',
    'Estadísticas con gráficas de pastel y barras interactivas',
  ],
),
```

- [ ] **Step 5: `flutter analyze` — cero errores**

- [ ] **Commit:** `release: v2.1.0+20 — Finanzas rediseño completo con libros, plantillas y categorías jerárquicas`
