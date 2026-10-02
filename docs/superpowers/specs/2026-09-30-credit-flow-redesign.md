# Rediseño del flujo de registro de créditos

**Fecha:** 2026-09-30  
**Estado:** Aprobado — listo para implementar

---

## Contexto

El flujo actual de `AddCreditSheet` mezcla tres tipos de crédito en un único recorrido lineal (entidad → tipo → datos → fechas → confirmación), lo que resulta confuso para el usuario, especialmente en tarjetas bancarias. El nuevo diseño separa tres caminos completamente independientes desde el primer tap.

---

## Objetivo

Reemplazar el flujo único de 5 pasos por tres sub-flujos independientes dentro del mismo `add_credit_sheet.dart`, cada uno con 4 pasos de entrada + 1 confirmación. El archivo permanece uno solo; los sub-flujos se extraen en widgets privados `_TiendaFlow`, `_TarjetaFlow`, `_PrestamoFlow`.

---

## Arquitectura general

```
+ Registrar crédito  (Step 0: selector de modo)
│
├── 🛍️ Cupo de tienda    → _TiendaFlow  (4 pasos + confirmación)
├── 💳 Tarjeta bancaria  → _TarjetaFlow (4 pasos + confirmación)
└── 🏦 Préstamo bancario → _PrestamoFlow (4 pasos + confirmación)
```

Estado central en `_AddCreditSheetState`:
- `_mode`: `null` (selector) | `'tienda'` | `'tarjeta'` | `'prestamo'`
- `_currentStep`: int 0–4
- `_stepDirection`: int +1 | -1 (para animación SlideTransition existente)
- `_lastStep`: constante = 4

`DraggableScrollableSheet`, `AnimatedSwitcher`, `SlideTransition` y `_StepProgress` permanecen sin cambios estructurales. `_StepProgress` muestra 5 burbujas siempre (0 = modo, 1–4 = pasos del sub-flow).

---

## Cambios al modelo de datos (`credit.dart`)

### CardCredit — campos nuevos

```dart
/// null = desconocido (usuario no lo configuró)
/// true = compras a 1 cuota sin interés si paga a tiempo
/// false = sí cobra interés en compras a 1 cuota
bool? oneInstallmentInterestPolicy;

/// Día del mes (1–31) en que vence el pago de la tarjeta.
/// Reemplaza paymentDueOffsetDays en la UI y lógica nueva.
/// 0 = no migrado aún (usa paymentDueOffsetDays como fallback).
int paymentDueDay;
```

`paymentDueOffsetDays` queda **deprecated**: se mantiene en el modelo y JSON para compatibilidad con datos existentes. No se muestra en UI. `getCardCycleDates()` en `card_calculator.dart` usa `paymentDueDay` si > 0, sino deriva de `cutoffDay + paymentDueOffsetDays`.

### Migración Drift

- `schemaVersion` sube en 1.
- `addColumn` para `oneInstallmentInterestPolicy` (nullable bool).
- `addColumn` para `paymentDueDay` (int, default 0).
- SQL UPDATE para rellenar `paymentDueDay` en tarjetas existentes:
  ```sql
  UPDATE credits SET payment_due_day = ((cutoff_day + payment_due_offset_days - 1) % 31) + 1 WHERE type = 'card'
  ```

### Sin cambios

`LoanCredit`, `CommercialQuota`, `Installment`, `CardMovement`, `LoanAbono` — sin modificaciones.

---

## Step 0 — Selector de modo

Tres tarjetas de selección que llenan el sheet. Al elegir una:
- `_mode = 'tienda' | 'tarjeta' | 'prestamo'`
- `_currentStep = 1`
- Animación SlideTransition existente

---

## Flow A — Cupo de tienda (`_TiendaFlow`)

### Step 1 — Entidad comercial
- `_EntityPickerCard` filtrado: solo entidades tipo `store`.
- Opciones: entidades existentes + "＋ Otro comercio" (modal nueva entidad) + "Sin entidad".
- `_selectedEntityId` → `quotaId` al guardar.

### Step 2 — Datos de la compra
- Nombre (opcional)
- Monto * (CurrencyInputFormatter)
- Cuotas * (int > 0)
- Tasa (vacío → `interestUnknown = true`)
- Tipo de tasa (visible solo si tasa > 0)
- `_QuotaPreviewCard` live
- Toggle `earlyPaymentWaivesInterest` con texto explicativo

### Step 3 — Fechas y estado
- Frecuencia: chips Mensual / Quincenal / Semanal
- Primera cuota * (DatePicker)
- Toggle "¿Ya empezaste?" → campo cuotas pagadas

### Step 4 — Confirmación + diseño
- Resumen de datos ingresados
- `WalletCard` preview con diseño seleccionado en tiempo real
- Picker de diseño de tarjeta (8 opciones, horizontal)
- Notas (opcional)
- Botón "Registrar compra"

**Guardado:** `LoanCredit` con `quotaId = _selectedEntityId`. Lógica `buildLoanInstallments()` y `_markAdvancedInstallments()` sin cambios.

---

## Flow B — Tarjeta bancaria (`_TarjetaFlow`)

### Step 1 — Banco e identidad
- Picker de bancos (lista `_presetLenders` existente, chips/cards)
- Nombre personalizado (opcional, `_nameCtrl`)
- `quotaId = null` siempre
- Autofill de fechas desde `entity_templates.dart` al elegir banco

### Step 2 — Cupo y deuda
- Cupo (`_limitCtrl`, opcional)
- Deuda actual (`_balanceCtrl`, default 0)
- Disponible calculado live (visible solo si limit > 0)
- Barra de utilización (visible solo si limit > 0)

### Step 3 — Condiciones financieras
- Banner informativo: "Los datos de interés son opcionales."
- Tasa (`_interestCtrl`, vacío → `interestUnknown = true`)
- Tipo de tasa (visible solo si tasa > 0)
- Toggle `oneInstallmentInterestPolicy`:
  - Arranca en `null` (indeterminado, sin marca)
  - Activar → `true`; desactivar explícitamente → `false`; nunca tocado → `null`
  - Texto explicativo bajo el toggle
- Cuota de manejo (`_managementFeeCtrl`, vacío = 0 = no aplica)
- Frecuencia cuota de manejo (visible solo si fee > 0)

### Step 4 — Fechas del ciclo
- Día de corte: `DropdownButton<int>` items 1–28
- Día límite de pago: `DropdownButton<int>` items 1–31
- Autofill desde `entity_templates.dart` si no tocados
- Notas (opcional)

### Step 5 — Confirmación + diseño
- `WalletCard` preview
- Resumen: banco, cupo, deuda, disponible, corte, pago, tasa, política 1 cuota, cuota de manejo
- Picker de diseño (8 opciones)
- Botón "Registrar tarjeta"

**Guardado:** `CardCredit` con `paymentDueDay`, `oneInstallmentInterestPolicy`, `paymentDueOffsetDays = 0`.

---

## Flow C — Préstamo bancario (`_PrestamoFlow`)

### Step 1 — Banco
- Mismo picker de bancos que Flow B (widget compartido `_BankPickerStep`)
- Nombre del crédito (opcional)
- `quotaId = null`

### Step 2 — Datos del préstamo
- Monto * (CurrencyInputFormatter)
- Cuotas * (int > 0)
- `_QuotaPreviewCard` live

### Step 3 — Condiciones
- Tasa (vacío → `interestUnknown = true`)
- Tipo de tasa (visible solo si tasa > 0)
- Frecuencia: chips Mensual / Quincenal / Semanal
- Toggle `earlyPaymentWaivesInterest` con texto explicativo

### Step 4 — Fechas y estado
- Primera cuota * (DatePicker)
- Toggle "¿Ya empezaste?" → campo cuotas pagadas

### Step 5 — Confirmación + diseño
- `WalletCard` preview
- Resumen: banco, monto, cuotas, cuota estimada, tasa, frecuencia, primera cuota, cuotas pagadas
- Notas (opcional)
- Picker de diseño (8 opciones)
- Botón "Registrar préstamo"

**Guardado:** `LoanCredit` con `quotaId = null`. Misma lógica que hoy.

---

## Widgets compartidos entre sub-flows

| Widget | Usado en |
|---|---|
| `_BankPickerStep` | Flow B + Flow C (mismo widget, misma lista) |
| `_QuotaPreviewCard` | Flow A + Flow C (cuota estimada live) |
| `_DesignPickerRow` | Confirmación de los tres flujos |
| `_StepProgress` | Los tres flujos (sin cambios) |

---

## Archivos tocados

| Archivo | Cambio |
|---|---|
| `lib/data/models/credit.dart` | Nuevos campos `CardCredit` |
| `lib/data/db/tables.dart` | Nuevas columnas + `schemaVersion` |
| `lib/data/db/database.dart` | `MigrationStrategy` con addColumn + SQL UPDATE |
| `lib/domain/card_calculator.dart` | `getCardCycleDates()` usa `paymentDueDay` |
| `lib/screens/credits/add_credit_sheet.dart` | Refactor completo — tres sub-flows |

---

## Fuera de scope (próxima iteración)

- Registrar avances/adelantos de tarjeta
- Migrar `lender` string → entidad normalizada `FinancialEntity`
- Tests de integración ADB (se agregan al final del sprint)
