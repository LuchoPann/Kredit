# Kredit — Plan de mejoras v2.0

**Objetivo:** Refactorizar la base de código para hacerla mantenible y escalable, luego implementar las funcionalidades de mayor impacto para el usuario.

**Principio:** Primero la fundación, luego las features. Una feature sobre código frágil se vuelve deuda técnica doble.

---

## Fase 1 — Fundación técnica (refactor crítico)

> Sin esto, cada feature nueva es más costosa de implementar y más propensa a bugs.

### 1.1 Eliminar rebuilds innecesarios en Dashboard

**Problema:** `ref.watch(creditsProvider)` reconstruye toda la pantalla ante cualquier cambio.

**Solución:** Reemplazar con selectores granulares.

```dart
// Antes
final credits = ref.watch(creditsProvider);

// Después
final totalDebt = ref.watch(creditsProvider.select((s) => s.totalDebt));
final nextDue = ref.watch(creditsProvider.select((s) => s.nextDueDate));
```

**Archivos:** `lib/screens/dashboard/dashboard_screen.dart`
**Impacto:** Rendimiento directo — pantalla principal deja de reconstruirse completa.

---

### 1.2 Cachear cálculos en StatsProvider

**Problema:** `stats_provider.dart` recalcula cronogramas completos en cada acceso.

**Solución:** Convertir a `AsyncNotifier` con memoización por ID.

```dart
class StatsNotifier extends AsyncNotifier<StatsState> {
  final Map<String, ScheduleResult> _cache = {};

  ScheduleResult getSchedule(String creditId) {
    return _cache.putIfAbsent(creditId, () => _calculate(creditId));
  }

  void invalidate(String creditId) => _cache.remove(creditId);
}
```

**Archivos:** `lib/providers/stats_provider.dart`

---

### 1.3 Unificar lógica financiera en CardCalculator

**Problema:** Cálculos de intereses duplicados entre `card_calculator.dart` y `simulator_sheet.dart`.

**Solución:** Todo cálculo financiero vive en `card_calculator.dart`. El simulador solo llama al calculador.

**Archivos:** `lib/domain/card_calculator.dart`, `lib/screens/stats/simulator_sheet.dart`

---

### 1.4 Dividir add_credit_sheet.dart (2631 líneas)

**Problema:** Archivo monolítico — lógica, estado y UI mezclados.

**Estructura propuesta:**

```
lib/screens/credits/
├── add_credit_sheet.dart          ← orquestador (estado, navegación entre steps)
├── steps/
│   ├── step_tipo.dart             ← selección de tipo de crédito
│   ├── step_entidad.dart          ← selección de entidad
│   ├── step_tarjeta_datos.dart    ← formulario tarjeta
│   ├── step_tienda_datos.dart     ← formulario tienda/cupo
│   └── step_confirmacion.dart     ← resumen antes de guardar
└── widgets/
    └── credit_form_field.dart     ← campo reutilizable con validación
```

---

### 1.5 Dividir simulator_sheet.dart (3374 líneas)

**Estructura propuesta:**

```
lib/screens/stats/
├── simulator_sheet.dart           ← orquestador
├── simulator/
│   ├── simulator_state.dart       ← estado y lógica
│   ├── panel_antes.dart           ← panel situación actual
│   ├── panel_despues.dart         ← panel con simulación
│   ├── estrategia_selector.dart   ← Avalanche / Snowball
│   └── simulator_result_card.dart ← tarjeta de resultado
```

---

### 1.6 Limpiezas rápidas

- Remover todos los `print()` de debug en providers
- Agregar `const` a widgets estáticos en `account_screen.dart`
- Verificar si `path_drawing` y `path_parsing` se usan realmente; eliminar si no
- Dividir `account_screen.dart` en subscreens: Apariencia, Seguridad, Datos, Acerca de

**Versión al completar Fase 1:** `1.1.0` — mejora interna, sin cambios visibles al usuario.

---

## Fase 2 — Mejoras a funcionalidad existente

### 2.1 Ordenar y filtrar lista de créditos

**Qué:** Barra de filtros en `credits_list_screen.dart`.

**Opciones de orden:**
- Próximo vencimiento (default)
- Mayor deuda
- Tipo (tarjeta / tienda)
- Nombre A-Z

**Implementación:** `SortBar` widget + campo `sortMode` en `CreditsFilter` state local.

**Complejidad:** Baja — datos ya disponibles, solo UI + sort.

---

### 2.2 Notificaciones configurables por crédito

**Qué:** Cada crédito puede tener su propio número de días de anticipación (actualmente global).

**Campos nuevos en modelo:**
```dart
int? diasAnticipacionPersonalizado; // null = usa el global
```

**UI:** Toggle en detalle de crédito → "Usar recordatorio personalizado" → slider de días.

**Complejidad:** Media — requiere migración de base de datos Drift.

---

### 2.3 Guardar escenarios del simulador

**Qué:** Botón "Guardar escenario" en el simulador. Lista de escenarios guardados para comparar.

**Modelo nuevo:**
```dart
class SimulatorScenario {
  final String id;
  final String nombre;
  final DateTime fecha;
  final SimulatorInput input;
  final SimulatorResult resultado;
}
```

**UI:** Drawer lateral en el simulador con historial de escenarios.

**Complejidad:** Media.

---

### 2.4 Historial de pagos reales vs proyectados

**Qué:** Al llegar la fecha de pago, el usuario registra lo que realmente pagó. El detalle muestra proyectado vs real.

**Modelo nuevo:**
```dart
class PagoRealizado {
  final String creditId;
  final DateTime fecha;
  final double montoPagado;
  final double montoProyectado;
  final String? nota;
}
```

**UI:** Botón "Registrar pago" en detalle de crédito, visible cuando hay cuota próxima. Tab "Historial" en detalle.

**Complejidad:** Media — desbloquea Fase 3 completa.

**Versión al completar Fase 2:** `1.2.0`

---

## Fase 3 — Nuevas funcionalidades de alto impacto

### 3.1 Widget de pantalla de inicio Android ⚡

**Prioridad máxima** — dependencia `home_widget` ya instalada, solo falta implementación.

**Contenido del widget:**
- Deuda total
- Próximo vencimiento (crédito + fecha + monto)
- Indicador visual de urgencia

**Tamaños:** 2×2 (compacto) y 4×2 (expandido).

**Archivos a crear:**
```
android/app/src/main/res/layout/
├── kredit_widget_compact.xml
└── kredit_widget_expanded.xml

lib/widgets/home_widget/
├── home_widget_service.dart      ← actualización de datos
└── home_widget_updater.dart      ← cuándo actualizar (al abrir app, al guardar crédito)
```

**Complejidad:** Media — el SDK ya está, falta la implementación Android + Dart.

---

### 3.2 Calculadora de cuota preventiva

**Qué:** Herramienta standalone: "¿Cuánto me cuesta esto a cuotas?". Sin necesidad de crear un crédito.

**Inputs:**
- Valor del artículo
- Número de cuotas
- Tasa de interés mensual (o seleccionar entidad conocida)

**Output:**
- Cuota mensual
- Total a pagar
- Total de intereses
- Recomendación: "Con tu deuda actual, este pago representaría X% de tu ingreso si lo tienes configurado"

**Ubicación:** Botón flotante en `stats_screen.dart` o ítem en el menú del simulador.

**Complejidad:** Baja — lógica ya existe en `card_calculator.dart`.

---

### 3.3 Gráfica de deuda histórica en Dashboard

**Qué:** Línea temporal mostrando cómo ha evolucionado la deuda total.

**Datos:** Con `PagoRealizado` (Fase 2.4) se puede construir el historial. Sin él, se puede aproximar desde las fechas de creación de créditos y los cronogramas proyectados.

**Librería:** `fl_chart` ya instalada.

**UI:** Card deslizable debajo del resumen en dashboard. Período: 3m / 6m / 1a.

**Complejidad:** Media — depende de Fase 2.4 para datos reales.

---

### 3.4 Resumen mensual "Estado de cuenta Kredit"

**Qué:** Vista de lo que venció este mes, lo que se pagó y el balance.

**Secciones:**
- Cuotas del mes (pagadas ✓ / pendientes ○ / vencidas ✗)
- Total pagado vs total proyectado
- Intereses pagados en el mes
- Comparación vs mes anterior

**UI:** Pantalla nueva accesible desde Dashboard. Navegación por meses (← →).

**Complejidad:** Media — requiere Fase 2.4.

---

### 3.5 Alertas de mora proyectada

**Qué:** Si una cuota vence en X días y no hay registro de pago, notificación local con mora estimada.

**Lógica:**
```dart
// 1 día después del vencimiento sin pago registrado
if (fechaHoy > fechaVencimiento && !tienePagoRegistrado) {
  final mora = calculadora.calcularMora(cuota, diasAtraso);
  notificationService.mostrarAlertaMora(credito, mora);
}
```

**Complejidad:** Media — requiere Fase 2.4.

**Versión al completar Fase 3:** `1.3.0`

---

## Fase 4 — Funcionalidades avanzadas

### 4.1 Modo "Plan de ataque"

**Qué:** Cronograma mes a mes hasta quedar libre de deudas, aplicando la estrategia elegida.

**Output:**
- Tabla: mes | créditos activos | pago total | deuda restante
- Fecha estimada de libertad financiera
- Total de intereses que se pagarán
- Exportable como imagen (Share)

**Complejidad:** Alta — requiere simulación multi-período sobre múltiples créditos simultáneos.

---

### 4.2 Comparador de estrategias visual

**Qué:** Gráfica lado a lado: Solo mínimos vs Snowball vs Avalanche.

**Ejes:** Tiempo (meses) vs Deuda total restante.
**Datos clave por estrategia:** Meses hasta $0, total de intereses pagados.

**Librería:** `fl_chart` (ya instalada).

**Complejidad:** Alta.

---

### 4.3 Etiquetas de gastos en movimientos

**Qué:** Categorizar cada movimiento de tarjeta (Ropa, Tecnología, Alimentación, Salud, Entretenimiento, Otro).

**UI:** Chip selector al registrar movimiento. Gráfica de torta en Stats mostrando distribución de gastos por categoría.

**Complejidad:** Media — requiere migración de modelo `CardMovement`.

**Versión al completar Fase 4:** `2.0.0`

---

## Resumen de versiones

| Fase | Versión | Descripción |
|------|---------|-------------|
| 1 | `1.1.0` | Refactor técnico — sin cambios visibles |
| 2 | `1.2.0` | Filtros, notificaciones config., escenarios, pagos reales |
| 3 | `1.3.0` | Widget Android, calculadora, gráficas, resumen mensual, alertas mora |
| 4 | `2.0.0` | Plan de ataque, comparador visual, etiquetas de gastos |

---

## Orden de implementación recomendado

```
1.1 Selectors en dashboard          ← 1 día
1.6 Limpiezas rápidas               ← 1 día
1.3 Unificar CardCalculator         ← 1 día
1.2 Cache en StatsProvider          ← 1-2 días
1.4 Dividir add_credit_sheet        ← 2-3 días
1.5 Dividir simulator_sheet         ← 2-3 días
──── RELEASE 1.1.0 ────────────────
2.1 Ordenar/filtrar créditos        ← 1 día
3.2 Calculadora preventiva          ← 1 día    ← quick win
3.1 Widget Android                  ← 2-3 días ← quick win
2.4 Registro de pagos reales        ← 2-3 días ← desbloquea todo
2.2 Notificaciones configurables    ← 1-2 días
2.3 Guardar escenarios              ← 1-2 días
──── RELEASE 1.2.0 ────────────────
3.3 Gráfica deuda histórica         ← 2 días
3.4 Resumen mensual                 ← 2-3 días
3.5 Alertas mora proyectada         ← 1-2 días
──── RELEASE 1.3.0 ────────────────
4.1 Plan de ataque                  ← 3-4 días
4.2 Comparador de estrategias       ← 2-3 días
4.3 Etiquetas de gastos             ← 2-3 días
──── RELEASE 2.0.0 ────────────────
```

---

## Hallazgos adicionales (primer agente — auditoría técnica profunda)

### Críticos confirmados y ampliados
- **`add_credit_sheet.dart` tiene 55 llamadas a `setState`** — cada toque en el formulario reconstruye ~300 widgets. Confirmado como el problema de rendimiento más grave.
- **`_reload()` en cada mutación** — 14 operaciones distintas (agregar, editar, borrar crédito, etc.) hacen una lectura completa de la DB. Solución: mutar en memoria + persistir; solo releer cuando se necesita sincronización real.
- **`profile_header.dart` no está en git** — el archivo fue eliminado de git pero puede seguir existiendo localmente. En otro equipo el clone rompe el build. Verificar y resolver.

### Moderados adicionales
- **`animations` package: 0 importaciones** — eliminar de `pubspec.yaml`. Reducción de tamaño del APK sin costo.
- **`edit_credit_sheet.dart` duplica lógica con `add_credit_sheet.dart`** — dos archivos enormes con lógica casi idéntica. Unificar en un widget con modo `create`/`edit`.

---

## Hallazgos adicionales (segundo agente de auditoría)

### Crítico adicional
- **`add_credit_sheet.dart` tiene en realidad ~4484 líneas** (no 2631 — el primer conteo fue parcial). La división es aún más urgente.
- **`accrueCardCredit()` itera hasta 36 ciclos sin guard de cache** — si el provider se reconstruye frecuentemente es O(36) por crédito por rebuild. Agregar `if (lastAccrualCutoff == nextCutoff) return;` antes del loop.

### Moderado adicional
- **`formatCOP` potencialmente duplicado** en dashboard, add_credit, credit_detail, simulator. Verificar si está en un util compartido o duplicado. Si duplicado → mover a `lib/utils/formatters.dart`.
- **`accrueCardCredit()` sin tests** — lógica de negocio crítica (intereses, ciclos de corte) sin cobertura de tests. Alto riesgo de regresión silenciosa.
- **`entity_templates.dart` hardcodea datos de entidades** — días de corte/pago de Bancolombia, Nu, Davivienda. Cuando cambian, usuarios con templates tienen datos erróneos.

### Funcionalidades adicionales identificadas
- **Historial de tasas de interés** — `applyRateChangeAt()` ya existe en `card_calculator.dart` pero no hay UI. Cuando el banco cambia la tasa, sin historial el usuario pierde el registro. Complejidad: Baja-Media.
- **Recordatorio de cierre de ciclo** — las tarjetas tienen fecha de corte además de fecha de pago. Compras después del corte caen al siguiente ciclo — notificación de "hoy cierra tu ciclo". `cutoffDay` ya está en el modelo. Complejidad: Baja.
- **Exportar a calendario del sistema** — fechas de pago/corte exportadas al Calendar de Android. `getCardCycleDates()` ya calcula las fechas. Complejidad: Media.
- **Modo comparar créditos** — side-by-side de dos créditos para decidir cuál pagar primero. Datos ya disponibles en stats. Complejidad: Baja.
- **Breakdown por crédito en gráfica mensual** — al tocar una barra del gráfico de proyección a 6 meses, mostrar qué crédito contribuye cuánto. Complejidad: Baja (datos ya en el provider).
- **Metas de pago** — usuario se pone meta "pagar X en 3 meses" y ve progreso. Nueva entidad `PaymentGoal` en Drift. Complejidad: Media.

---

*Generado: 2026-10-08 · Kredit v1.0.0 → v2.0.0*
