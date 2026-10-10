# Krezium v2.0.0 — Módulo Finanzas + Navegación Dual

## Goal

Agregar un módulo de registro de gastos e ingresos completamente independiente del módulo de créditos, con una arquitectura de navegación de dos entornos (Créditos / Finanzas) que el usuario puede alternar desde un botón central en el nav inferior.

## Architecture

Dos entornos independientes con sus propias pantallas y datos. El nav inferior tiene 5 posiciones fijas: las dos de la izquierda y las dos de la derecha cambian según el entorno activo; la posición central es siempre el botón de cambio de entorno. Cuenta es compartida y ocupa la posición 4 (derecha) en ambos entornos.

## Tech Stack

- Flutter + Riverpod (igual que el resto de la app)
- Drift ORM — nuevas tablas en migración `schemaVersion` existente + 1
- `shared_preferences` — persiste entorno preferido del usuario
- Entorno activo en un nuevo `entornoProvider` (StateProvider)

## Spec

---

### Global Constraints

- App 100% offline. Sin conexión a internet, sin cuentas, sin analytics.
- Solo pesos colombianos (COP). Sin soporte multidivisa.
- Backups existentes siguen siendo importables; las nuevas tablas de finanzas se incluyen en el JSON de export/import.
- No se modifica ninguna tabla existente de créditos.
- Nullable en `fromJson` para todo campo nuevo — importar backups anteriores nunca falla.
- La versión nueva es `2.0.0+19`.

---

### 1. Navegación dual — RootScaffold

El `RootScaffold` actual (4 tabs) se reemplaza por uno nuevo con 5 posiciones:

```
Posición:  0          1          2 (centro)     3              4
Créditos: [Inicio]  [Créditos]  [◉ Finanzas]  [Estadísticas] [Cuenta]
Finanzas: [Transacc] [Presup.]  [◉ Créditos]  [Estadísticas] [Cuenta]
```

**Posición central (2):** no es un tab normal. Es un `FloatingActionButton`-style elevado que hace:
- Muestra el ícono y nombre del entorno al que cambia (destino, no origen).
- Al tocarlo, actualiza `entornoProvider` (toggle `creditos` ↔ `finanzas`).
- Persiste el entorno activo en `SharedPreferences`.
- Anima el cambio con `AnimatedSwitcher` sobre el contenido, igual que el `_TabFadeLayer` existente.

**Diseño del nav:** usar `NavigationBar` (Material 3) en lugar del `BottomNavigationBar` actual para poder insertar el botón central elevado. El botón central va sobre el nav bar (Stack), desplazado hacia arriba ~8 px, con `FloatingActionButton.small` o un `Container` con `BoxDecoration` circular, color de acento, elevación 4.

**Tab activo** por entorno se guarda por separado — si el usuario estaba en "Presupuesto" en Finanzas, cambia a Créditos, vuelve a Finanzas → regresa a "Presupuesto", no a "Transacciones".

**Providers:**
```dart
// lib/providers/entorno_provider.dart
enum Entorno { creditos, finanzas }
final entornoProvider = StateProvider<Entorno>((ref) => Entorno.creditos);

// lib/providers/navigation_provider.dart (existente — extender)
final creditosTabProvider = StateProvider<int>((ref) => 0); // 0=Dashboard,1=Créditos,2=Stats
final finanzasTabProvider = StateProvider<int>((ref) => 0); // 0=Transacc,1=Presup,2=Stats
```

**Pantallas por entorno:**

Créditos (índices 0,1,2):
- `DashboardScreen` (existente)
- `CreditsListScreen` (existente)
- `StatsScreen` (existente — stats de créditos)

Finanzas (índices 0,1,2):
- `FinanzasTransaccionesScreen` (nueva)
- `FinanzasPresupuestoScreen` (nueva)
- `FinanzasEstadisticasScreen` (nueva)

Compartido (índice 3 en ambos):
- `AccountScreen` (existente, sin cambios)

---

### 2. Entorno preferido — Onboarding y Cuenta

**Primera apertura (onboarding):**
El `WelcomeScreen` existente ya maneja la bienvenida. Se le agrega una pantalla adicional al final del onboarding: `EntornoSelectionScreen` — dos tarjetas grandes, una para Créditos y una para Finanzas, con descripción de una línea. El usuario toca la que prefiere. El resultado se guarda como `preferred_entorno` en `SharedPreferences` y se refleja en `entornoProvider` en el arranque.

Si el usuario ya tiene `onboardingShown = true` (instalación existente), NO se muestra `EntornoSelectionScreen` — el entorno predeterminado es `creditos` (sin cambio de comportamiento para usuarios actuales).

**En Cuenta:**
Nueva opción en la sección "General" (o la que exista): "Vista principal" con opciones Créditos / Finanzas. Escribe en `SharedPreferences('preferred_entorno')`.

---

### 3. Modelo de datos — Tablas Finanzas

Cuatro tablas nuevas en `lib/data/db/tables.dart`. Migración Drift: `schemaVersion` actual + 1.

#### `FinanceAccounts` — cuentas/bolsillos

```dart
@DataClassName('FinanceAccountRow')
class FinanceAccounts extends Table {
  TextColumn get id => text()();
  TextColumn get nombre => text()();
  TextColumn get tipo => text()(); // 'efectivo'|'digital'|'bancaria'
  TextColumn get icono => text()(); // nombre del IconData serializado
  TextColumn get color => text()(); // hex string
  RealColumn get saldoInicial => real().withDefault(const Constant(0.0))();
  BoolColumn get activa => boolean().withDefault(const Constant(true))();
  TextColumn get orden => text().withDefault(const Constant('0'))();

  @override
  Set<Column> get primaryKey => {id};
}
```

#### `FinanceCategories` — categorías personalizadas

Solo las categorías creadas por el usuario van aquí. Las ~30 del catálogo base son constantes en Dart (`lib/data/finance_categories_catalog.dart`), nunca en DB.

```dart
@DataClassName('FinanceCategoryRow')
class FinanceCategories extends Table {
  TextColumn get id => text()();
  TextColumn get nombre => text()();
  TextColumn get icono => text()(); // IconData key
  TextColumn get color => text()(); // hex
  TextColumn get tipo => text()(); // 'ingreso'|'gasto'|'ambos'
  BoolColumn get archivada => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
```

#### `FinanceTransactions` — movimientos

```dart
@DataClassName('FinanceTransactionRow')
class FinanceTransactions extends Table {
  IntColumn get rowId => integer().autoIncrement()();
  TextColumn get id => text()();
  TextColumn get accountId =>
      text().references(FinanceAccounts, #id, onDelete: KeyAction.restrict)();
  TextColumn get categoryId => text()(); // catálogo id o DB id
  TextColumn get tipo => text()(); // 'ingreso'|'gasto'
  RealColumn get monto => real()();
  TextColumn get fecha => text()(); // YYYY-MM-DD
  TextColumn get nota => text().withDefault(const Constant(''))();
  BoolColumn get esRecurrente => boolean().withDefault(const Constant(false))();
  TextColumn get recurrenciaConfig => text().nullable()(); // JSON: {freq, fin?}

  @override
  Set<Column> get primaryKey => {id};
}
```

**`accountId` con `KeyAction.restrict`:** no se puede borrar una cuenta que tenga transacciones. El usuario debe reasignarlas o archivar la cuenta.

#### `FinanceBudgets` — presupuesto mensual por categoría

```dart
@DataClassName('FinanceBudgetRow')
class FinanceBudgets extends Table {
  IntColumn get rowId => integer().autoIncrement()();
  TextColumn get categoryId => text()();
  IntColumn get anio => integer()();
  IntColumn get mes => integer()(); // 1-12
  RealColumn get montoLimite => real()();
}
```

---

### 4. Catálogo base de categorías

`lib/data/finance_categories_catalog.dart` — constantes Dart, nunca escritas en DB.

```dart
class CatalogoCategoria {
  final String id;       // slug único: 'salario', 'mercado', etc.
  final String nombre;
  final IconData icono;
  final Color color;
  final String tipo;     // 'ingreso'|'gasto'|'ambos'
}
```

**Ingresos (8):**
`salario`, `freelance`, `negocio`, `arriendo_recibido`, `intereses`, `regalo_ingreso`, `devolucion`, `otro_ingreso`

**Gastos (22):**
`alimentacion`, `restaurantes`, `supermercado`, `transporte`, `salud`, `vivienda`, `servicios_publicos`, `ropa`, `entretenimiento`, `educacion`, `viajes`, `mascotas`, `deporte`, `tecnologia`, `belleza`, `regalos_gasto`, `ahorros`, `inversion`, `suscripciones`, `cuidado_personal`, `hogar`, `otro_gasto`

Total: **30 categorías de sistema**.

---

### 5. Pantallas del módulo Finanzas

#### `FinanzasTransaccionesScreen`

- AppBar: título "Finanzas" + ícono de filtro.
- Header numérico: ingresos del mes / gastos del mes / balance.
- Lista de transacciones del mes activo, agrupadas por fecha.
- FAB: registrar nueva transacción → `RegistrarTransaccionSheet` (bottom sheet).
- Filtros: mes, cuenta, tipo (ingreso/gasto), categoría.
- Vista compacta / cómoda — toggle en AppBar, persistido en prefs.
- Cada ítem muestra: ícono+color categoría, nombre categoría, nota (si hay), cuenta, monto (verde ingreso / rojo gasto).

#### `RegistrarTransaccionSheet`

- Tipo: Ingreso / Gasto (segmented button).
- Monto (campo principal, grande).
- Cuenta (selector de `FinanceAccounts` del usuario).
- Categoría (grid de chips con ícono — catálogo + personalizadas).
- Fecha (por defecto hoy).
- Nota (opcional).
- Recurrente (switch) → si activo: frecuencia (diaria/semanal/mensual) + fecha fin opcional.

#### `FinanzasPresupuestoScreen`

- Mes activo (chevrons para navegar).
- Tarjeta resumen: total presupuestado / total gastado / % usado.
- Lista de categorías con presupuesto asignado: barra de progreso + monto gastado vs límite. Rojo cuando supera el 90%.
- Categorías sin presupuesto definido pero con gastos del mes: listadas al final con opción de asignar límite.
- FAB o botón: "Configurar presupuesto" → sheet para establecer límites por categoría.

#### `FinanzasEstadisticasScreen`

- Selector de rango: mes, trimestre, año.
- Tarjeta torta: gastos por categoría (top 5 + "Otros").
- Barras: ingresos vs gastos por mes (últimos 6 meses).
- Tarjeta tendencia: categoría donde más creció el gasto vs mes anterior.
- Resumen por cuenta: saldo actual de cada bolsillo.

---

### 6. Gestión de cuentas y categorías

#### Cuentas (`FinanceAccountsScreen` — sub-pantalla desde Cuenta o header de Transacciones)

- Lista de cuentas activas con saldo calculado (saldo_inicial + sum(ingresos) − sum(gastos)).
- Crear / editar / archivar (nunca borrar si tiene transacciones).
- Cuentas predeterminadas sugeridas en el primer uso: "Efectivo", "Nequi" — el usuario las puede eliminar.

#### Categorías personalizadas (desde `RegistrarTransaccionSheet` o Cuenta)

- El usuario puede agregar una categoría con nombre, ícono (selector de Material icons subset) y color.
- Las categorías del catálogo base no son editables, pero sí pueden archivarse para que no aparezcan en la selección.

---

### 7. Export / Import

El JSON de respaldo existente se extiende con un bloque `finanzas`:

```json
{
  "credits": [...],
  "quotas": [...],
  "finanzas": {
    "accounts": [...],
    "categories": [...],
    "transactions": [...],
    "budgets": [...]
  }
}
```

Si el campo `finanzas` no existe en un backup (versiones anteriores), la importación lo ignora silenciosamente — compatibilidad total hacia atrás.

---

### 8. Versionado

- Versión: `1.1.0+18` → `2.0.0+19`
- Tipo: MAJOR — nuevo subsistema, cambio de arquitectura de navegación.
- DB `schemaVersion`: actual + 1 (agregar las 4 tablas nuevas como `addTable` en la migración).

---

## Review Focus

Los cinco puntos más propensos a romperse que los tests de tarea no cubren:

1. **Migración DB en instalaciones existentes** — usuario con datos de créditos actualiza a v2.0.0; la migración debe agregar las 4 tablas sin tocar las filas existentes y sin perder datos.
2. **Backup de versión anterior importado en v2.0.0** — campo `finanzas` ausente → `fromJson` debe devolver listas vacías, no lanzar excepción.
3. **Entorno switch mid-session** — usuario en StatsScreen de Finanzas, cambia a Créditos, el `_TabFadeLayer` de Finanzas debe quedar invisible pero montado (no disponer animaciones colgadas o excepciones de ticker).
4. **Borrar cuenta con transacciones** — `KeyAction.restrict` en FK debe lanzar un error Drift que la UI captura y muestra como mensaje amigable, nunca crash silencioso.
5. **Primera instalación (onboarding)** — `EntornoSelectionScreen` solo aparece si `onboardingShown` es false; usuarios existentes con `onboardingShown = true` arrancan directamente en entorno `creditos` sin ver ninguna pantalla adicional.
