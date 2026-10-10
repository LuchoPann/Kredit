# Krezium — Módulo Finanzas v2 Rediseño — Design Spec

**Fecha:** 2026-10-09  
**Versión objetivo:** 2.1.0+20  
**schemaVersion:** 13 → 14

---

## Objetivo

Rediseñar completamente las 3 pantallas del módulo Finanzas para ofrecer una experiencia de registro de gastos e ingresos comparable a apps especializadas, incorporando: sistema de libros de registro, categorías jerárquicas editables por el usuario, plantillas de transacciones, formulario de registro en 2 pasos con campos enriquecidos, y filtros de visualización en la lista de transacciones.

---

## Arquitectura general

### Navegación Finanzas (3 tabs)

| Tab | Ícono | Pantalla | Descripción |
|-----|-------|----------|-------------|
| 0 | `wallet` | **Cuentas** | Lista de libros con balance; tap → detalle de transacciones |
| 1 | `description` | **Plantillas** | Plantillas de transacciones reutilizables |
| 2 | `bar_chart` | **Estadísticas** | Gráficas, tendencias, presupuesto |

El tab "Cuenta" (posición 4, compartido con Créditos) no cambia.

---

## DB — schemaVersion 14

### Tablas modificadas

#### `FinanceCategories` — agregar `parentId`
```dart
TextColumn get parentId => text().nullable()
    .references(FinanceCategories, #id, onDelete: KeyAction.setNull)();
```
- `parentId == null` → categoría padre (nivel 1)
- `parentId != null` → subcategoría (nivel 2)
- El catálogo inicial de 30 categorías se reorganiza: cada categoría existente se convierte en subcategoría bajo un padre nuevo (ej: "salario" queda bajo "Sueldo").

#### `FinanceTransactions` — agregar 3 columnas
```dart
TextColumn get personaSitio => text().nullable()();
TextColumn get hora => text().nullable()();          // "HH:mm"
TextColumn get transferToAccountId => text().nullable()
    .references(FinanceAccounts, #id, onDelete: KeyAction.setNull)();
```

### Tablas nuevas

#### `FinancePlaces`
```dart
@DataClassName('FinancePlaceRow')
class FinancePlaces extends Table {
  TextColumn get id => text()();
  TextColumn get nombre => text()();
  IntColumn get usados => integer().withDefault(const Constant(0))();
  @override Set<Column> get primaryKey => {id};
}
```

#### `FinanceTemplates`
```dart
@DataClassName('FinanceTemplateRow')
class FinanceTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get nombre => text()();
  TextColumn get libroId => text().nullable()
      .references(FinanceAccounts, #id, onDelete: KeyAction.setNull)();
  TextColumn get categoryId => text()();
  TextColumn get tipo => text()();           // 'ingreso'|'gasto'
  RealColumn get monto => real().nullable()();
  TextColumn get personaSitio => text().nullable()();
  TextColumn get nota => text().nullable()();
  @override Set<Column> get primaryKey => {id};
}
```

### Migración
```dart
if (from < 14) {
  await m.addColumn(financeCategories, financeCategories.parentId);
  await m.addColumn(financeTransactions, financeTransactions.personaSitio);
  await m.addColumn(financeTransactions, financeTransactions.hora);
  await m.addColumn(financeTransactions, financeTransactions.transferToAccountId);
  await m.createTable(financePlaces);
  await m.createTable(financeTemplates);
}
```

### Seed de categorías jerárquicas (inserción en migración)
Categorías padre (nuevas en v14): Sueldo, Negocio, Inversiones, Otros ingresos, Hogar, Alimentación, Transporte, Salud, Educación, Entretenimiento, Ropa, Tecnología, Viajes, Finanzas personales, Otros gastos.  
Subcategorías: las 30 categorías existentes se mueven bajo sus padres correspondientes. La migración solo agrega las categorías padre como nuevas filas; las existentes quedan como subcategorías enlazadas por `parentId` vía una `customStatement` de UPDATE.

---

## Pantallas

### 1. `FinanzasCuentasScreen` (Tab 0 — reemplaza FinanzasTransaccionesScreen)

**Estructura:**
- `AppBar`: título "Cuentas", acciones: [ícono ajustes de categorías], [ícono agregar libro]
- `ListView` de libros (`FinanceAccountRow`), cada ítem muestra:
  - Ícono del libro (color configurable) + nombre
  - Ingresos del mes / Gastos del mes / Balance actual (saldo inicial + ingresos acumulados - gastos acumulados)
  - Flecha derecha
  - Favorito marcado con estrella (libro predeterminado)
- `FloatingActionButton`: nuevo libro
- Estado vacío: empty state card con ícono + "Crea tu primer libro de registro"
- Tap en libro → push `FinanzasLibroTransaccionesScreen`

**Libro predeterminado:** `SharedPreferences` key `'finanzas_libro_default'`. Al entrar al tab, si existe un predeterminado y hay libros, se abre directamente. El usuario puede retroceder (AppBar back) para ver la lista de libros.

### 2. `FinanzasLibroTransaccionesScreen` (nueva — push desde Cuentas)

**AppBar:**
- Título: nombre del libro + dropdown (▾) para cambiar de libro sin ir atrás
- Acciones: [búsqueda], [filtros ⚙]

**Header resumen** (expandible, colapsa al hacer scroll):
```
Período activo: < oct 2026 >   (flechas de mes)
Ingresos: $X   Gastos: $X   Balance: $X
```

**Panel de filtros** (sheet o expansión in-line):
- Período: Diario | Semanal | Mensual | Todo
- Orden: Más reciente primero | Más antiguo primero
- Densidad: Cómodo | Compacto
- Tipo: Todos | Solo ingresos | Solo gastos

**Lista de transacciones** agrupada por día:
- Header del día: fecha legible ("Hoy · 9 oct") + subtotal del día
- Fila (modo cómodo): ícono categoría (círculo) + `Categoría > Subcategoría` (bold) / `Nota · Ordenante` (subtitle) + monto ±color + hora
- Fila (modo compacto): sin subtitle, menor altura
- Swipe izquierda → eliminar (con confirmación)
- Tap → `EditarTransaccionSheet`

**FAB dual:**
- Botón principal `+` → `NuevaTransaccionSheet` (pre-selecciona el libro actual)
- Botón secundario (plantilla) → `SeleccionarPlantillaSheet` → pre-rellena NuevaTransaccionSheet

### 3. `NuevaTransaccionSheet` / `EditarTransaccionSheet`

**Flujo 2 pasos** (solo para nueva; editar va directo al paso 2):

*Paso 1 — Contexto:*
- Toggle: `[Ingreso]  [Gasto]  [Transferencia]`
- Selector de libro: DropdownButton (pre-seleccionado: libro actual o predeterminado)
- Si Transferencia: selector libro destino adicional
- Botón "Continuar →"

*Paso 2 — Detalle (BottomSheet expansible o página):*
- **Importe**: campo grande numérico (locale `es_CO`)
- **Fecha**: chip con flechas `← 9/10/26 →` (DatePicker al tap central)
- **Hora**: chip con flechas `← 23:12 →` (TimePicker al tap central), default `DateTime.now()`
- **Ordenante**: TextField con autocompletado desde `FinancePlaces` (ordenado por `usados` DESC); al guardar, si el nombre no existe → insert; si existe → `usados++`
- **Categoría**: botón pill "Seleccionar" → `CategoriaSelectorSheet` (árbol jerárquico)
- **Notas**: TextField opcional
- Botón "Guardar"

### 4. `CategoriaSelectorSheet`

- Toggle superior: `[Gasto]  [Ingreso]`
- Lista con dos niveles:
  - Fila de categoría padre: ícono + nombre + flecha expandir/contraer
  - Filas de subcategorías: indentadas, ícono + nombre, tap para seleccionar
- Búsqueda (opcional fase 2)
- Botón "+" para agregar categoría/subcategoría nueva → `EditarCategoriaSheet`

### 5. `FinanzasPlantillasScreen` (Tab 1)

- Toggle: `[Gastos]  [Ingresos]`
- Lista de plantillas filtradas por tipo:
  - Fila: ícono categoría + nombre plantilla + `Categoría > Subcategoría` + monto (si tiene)
  - Swipe izquierda → eliminar
  - Tap → abre NuevaTransaccionSheet pre-rellenada con datos de la plantilla
- FAB: crear nueva plantilla → `EditarPlantillaSheet`
- Estado vacío con CTA

### 6. `EditarPlantillaSheet`

Campos:
- Nombre de la plantilla (requerido)
- Tipo: ingreso / gasto
- Libro (opcional, puede ser "cualquiera")
- Categoría (selector jerárquico)
- Monto (opcional — si se deja vacío, el usuario lo llena al usarla)
- Ordenante (opcional)
- Nota (opcional)

### 7. `FinanzasEstadisticasScreen` (Tab 2 — rediseño)

Secciones:
1. **Selector de período** (mes activo con flechas)
2. **PieChart gastos** top 5 categorías + leyenda lateral (no labels dentro del pie)
3. **BarChart tendencia** — 6 meses, barras ingresos (verde) vs gastos (rojo) lado a lado
4. **Presupuesto del mes** — `LinearProgressIndicator` por categoría (anillo total arriba)
5. **Balance por libro** — lista compacta de todos los libros con su saldo actual

FAB: agregar/editar límite de presupuesto para el mes activo → `EditarPresupuestoSheet`

---

## Componentes reutilizados de Créditos

- `KreditSectionCard` — cards de secciones en Estadísticas
- `ProgressRing` — anillo de presupuesto total
- `_SectionDivider` / patrón de tema — colores, tipografía, AppThemeColors

---

## Providers nuevos/modificados

```dart
// Existentes a actualizar:
financeAccountsProvider        // sin cambio de nombre; "libros"
financeTransactionsProvider    // agregar filtros: mes, libroId, tipo, orden
allFinanceCategoriesProvider   // devuelve árbol jerárquico

// Nuevos:
financePlacesProvider          // FutureProvider<List<FinancePlaceRow>>
financeTemplatesProvider       // FutureProvider<List<FinanceTemplateRow>>
financeTemplatesByTipoProvider // .family(String tipo)
financeLibroActivoProvider     // StateProvider<String?> (libroId)
finanzasFiltrosProvider        // StateProvider<FinanzasFiltros>
```

```dart
class FinanzasFiltros {
  final String periodo;      // 'diario'|'semanal'|'mensual'|'todo'
  final String orden;        // 'desc'|'asc'
  final String densidad;     // 'comodo'|'compacto'
  final String tipoFiltro;   // 'todos'|'ingreso'|'gasto'
}
```

---

## Modelos

```dart
// finance_models.dart — agregar campos a FinanceTransaction:
class FinanceTransaction {
  // ... existentes ...
  final String? personaSitio;
  final String? hora;
  final String? transferToAccountId;
}

class FinancePlace {
  final String id;
  final String nombre;
  final int usados;
}

class FinanceTemplate {
  final String id;
  final String nombre;
  final String? libroId;
  final String categoryId;
  final String tipo;
  final double? monto;
  final String? personaSitio;
  final String? nota;
}
```

---

## Compatibilidad con backups

Todos los campos nuevos en `fromJson` usan cast nullable con default:
```dart
personaSitio: json['personaSitio'] as String?,
hora: json['hora'] as String?,
transferToAccountId: json['transferToAccountId'] as String?,
```
Backups de v2.0.0 (sin estos campos) importan sin error.

---

## Versión

- `pubspec.yaml`: `2.0.0+19` → `2.1.0+20`
- `changelog.dart`: nueva entrada v2.1.0

---

## Archivos a crear/modificar

### Crear
- `lib/screens/finanzas/finanzas_cuentas_screen.dart`
- `lib/screens/finanzas/finanzas_libro_transacciones_screen.dart`
- `lib/screens/finanzas/nueva_transaccion_sheet.dart` (reemplaza registrar_transaccion_sheet.dart)
- `lib/screens/finanzas/editar_plantilla_sheet.dart`
- `lib/screens/finanzas/categoria_selector_sheet.dart`
- `lib/screens/finanzas/finanzas_plantillas_screen.dart`

### Modificar
- `lib/data/db/tables_finance.dart` — nuevas tablas + columnas
- `lib/data/db/database.dart` — migración v14, CRUD nuevas tablas
- `lib/data/models/finance_models.dart` — campos nuevos + Place + Template
- `lib/providers/finance_provider.dart` — nuevos providers + filtros
- `lib/screens/finanzas/finanzas_estadisticas_screen.dart` — rediseño completo
- `lib/screens/finanzas/finanzas_presupuesto_screen.dart` — mover a sección dentro de estadísticas (o eliminar como pantalla independiente)
- `lib/main.dart` — renombrar tabs finanzas (Cuentas, Plantillas, Estadísticas), actualizar íconos
- `lib/pubspec.yaml` — bump versión
- `lib/data/changelog.dart` — entrada v2.1.0

### Eliminar
- `lib/screens/finanzas/registrar_transaccion_sheet.dart` (reemplazada)
- `lib/screens/finanzas/finanzas_transacciones_screen.dart` (reemplazada)
- `lib/screens/finanzas/finanzas_presupuesto_screen.dart` (integrada en estadísticas)
