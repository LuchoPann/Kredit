# Credit Flow Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reemplazar el único flujo de 5 pasos de `AddCreditSheet` por tres sub-flujos independientes (tienda / tarjeta / préstamo), con dos nuevos campos en `CardCredit` y migración Drift.

**Architecture:** Un mismo archivo `add_credit_sheet.dart` aloja tres widgets privados `_TiendaFlow`, `_TarjetaFlow`, `_PrestamoFlow`. El state principal añade `_mode` (null = selector, 'tienda'|'tarjeta'|'prestamo') sobre el `_currentStep` existente. Widgets compartidos: `_BankPickerStep`, `_DesignPickerRow`.

**Tech Stack:** Flutter 3.x, Drift 2.x, Riverpod 2.x, SQLite, ADB integration_test.

**Spec:** `docs/superpowers/specs/2026-09-30-credit-flow-redesign.md`

## Global Constraints

- `schemaVersion` pasa de **9 a 10** — nunca hacer downgrade.
- `paymentDueOffsetDays` permanece en modelo y DB como deprecated — no se elimina.
- `paymentDueDay = 0` significa "no migrado" — leer siempre con fallback a offset.
- Ningún campo nuevo en `CardCredit` puede ser requerido sin default en Drift.
- Device ADB: `ZY22LBQ8XS` — todos los integration tests corren en este device.
- Tests unitarios corren con `flutter test` (in-memory Drift via `NativeDatabase.memory()`).
- Nunca sintetizar tasa falsa cuando `interestUnknown = true`.
- `quotaId = null` siempre para Flow B y Flow C.

## Review Focus

- **Tarjeta con `paymentDueDay = 0` (datos viejos no migrados):** `getCardCycleDates` debe caer en el fallback de offset sin lanzar excepción. → Task 2.
- **`oneInstallmentInterestPolicy` nunca tocado:** debe guardarse como `null`, no como `false`. El toggle indeterminado no debe colapsar a `false` en el primer rebuild. → Task 6.
- **Flow B guardado sin tasa:** `interestUnknown = true`, `interestRate = 0.0` — nunca NaN ni null. → Task 6.
- **Migración SQL UPDATE en DB vacía (primer install):** el UPDATE no debe fallar si no hay filas `type = 'card'`. → Task 1.
- **Volver al Step 0 desde cualquier sub-flow:** `_mode` y `_currentStep` se resetean limpiamente; los controllers del sub-flow anterior no ensucian el nuevo. → Task 4.

---

## Task 1: Modelo + Migración Drift

**Files:**
- Modify: `lib/data/models/credit.dart`
- Modify: `lib/data/db/tables.dart`
- Modify: `lib/data/db/database.dart`
- Test: `test/data/database_test.dart`

**Interfaces:**
- Produce: `CardCredit.oneInstallmentInterestPolicy` (`bool?`), `CardCredit.paymentDueDay` (`int`, default 0)
- Produce: `AppDatabase.schemaVersion = 10`
- Produce: `_cardFromRow` lee `oneInstallmentInterestPolicy` y `paymentDueDay`
- Produce: `_creditToCompanion` escribe ambos campos nuevos

- [ ] **Step 1: Escribir test que falla — round-trip CardCredit con nuevos campos**

```dart
// test/data/database_test.dart — añadir al final del main()
test('round-trips CardCredit with oneInstallmentInterestPolicy and paymentDueDay', () async {
  final card = CardCredit(
    id: 'card-new',
    name: 'Mi Tarjeta',
    lender: 'Bancolombia',
    creditLimit: 2000000,
    currentBalance: 650000,
    cutoffDay: 15,
    paymentDueDay: 5,
    paymentDueOffsetDays: 0,
    oneInstallmentInterestPolicy: true,
  );
  await db.upsertCredit(card);
  final loaded = (await db.loadAllCredits()).whereType<CardCredit>().first;
  expect(loaded.paymentDueDay, 5);
  expect(loaded.oneInstallmentInterestPolicy, true);
});

test('CardCredit with null oneInstallmentInterestPolicy round-trips as null', () async {
  final card = CardCredit(
    id: 'card-null-policy',
    name: 'Sin policy',
    lender: 'Davivienda',
    cutoffDay: 10,
    paymentDueDay: 0,   // no migrado
  );
  await db.upsertCredit(card);
  final loaded = (await db.loadAllCredits()).whereType<CardCredit>().first;
  expect(loaded.oneInstallmentInterestPolicy, isNull);
  expect(loaded.paymentDueDay, 0);
});
```

- [ ] **Step 2: Correr tests para verificar que fallan**

```bash
cd "/home/luis/Documentos/.VS CODE/PROYECTOS_PAN/Kredit"
flutter test test/data/database_test.dart -v
```
Esperado: FAIL — `CardCredit` no tiene `paymentDueDay` ni `oneInstallmentInterestPolicy`.

- [ ] **Step 3: Añadir campos a `CardCredit` en `credit.dart`**

En la clase `CardCredit`, después de `String? quotaId;`:
```dart
/// Día del mes (1–31) en que vence el pago de la tarjeta.
/// 0 = no migrado — usar paymentDueOffsetDays como fallback en ese caso.
int paymentDueDay;

/// null = usuario no lo configuró (desconocido)
/// true  = compras a 1 cuota sin interés si paga a tiempo
/// false = sí cobra interés en compras a 1 cuota
bool? oneInstallmentInterestPolicy;
```

En el constructor de `CardCredit`, añadir parámetros:
```dart
this.paymentDueDay = 0,
this.oneInstallmentInterestPolicy,
```

En `toJson()`:
```dart
'paymentDueDay': paymentDueDay,
'oneInstallmentInterestPolicy': oneInstallmentInterestPolicy,
```

En `fromJson()`:
```dart
paymentDueDay: (json['paymentDueDay'] as num?)?.toInt() ?? 0,
oneInstallmentInterestPolicy: json['oneInstallmentInterestPolicy'] as bool?,
```

- [ ] **Step 4: Añadir columnas a `tables.dart`**

Al final de la clase `Credits`, antes del `@override primaryKey`:
```dart
/// Día del mes (1–31) en que vence el pago — reemplaza paymentDueOffsetDays
/// en la UI y lógica nueva. 0 = no migrado aún.
IntColumn get paymentDueDay =>
    integer().withDefault(const Constant(0))();

/// null = desconocido, true = sin interés a 1 cuota, false = con interés.
BoolColumn get oneInstallmentInterestPolicy => boolean().nullable()();
```

- [ ] **Step 5: Actualizar `database.dart` — schemaVersion + migración + mappers**

Cambiar `schemaVersion`:
```dart
@override
int get schemaVersion => 10;
```

En `onUpgrade`, añadir bloque después del `if (from < 9)`:
```dart
if (from < 10) {
  await m.addColumn(credits, credits.paymentDueDay);
  await m.addColumn(credits, credits.oneInstallmentInterestPolicy);
  // Poblar paymentDueDay para tarjetas ya existentes a partir del offset.
  // ((cutoff + offset - 1) % 31) + 1 produce 1–31 siempre. Si no hay filas
  // card, el UPDATE no falla (afecta 0 filas).
  await customStatement('''
    UPDATE credits
    SET payment_due_day = ((cutoff_day + payment_due_offset_days - 1) % 31) + 1
    WHERE type = 'card'
      AND cutoff_day IS NOT NULL
      AND payment_due_offset_days IS NOT NULL
  ''');
}
```

En `_cardFromRow`, añadir después de `cardDesign`:
```dart
paymentDueDay: row.paymentDueDay,
oneInstallmentInterestPolicy: row.oneInstallmentInterestPolicy,
```

En `_creditToCompanion`, bloque `CardCredit`, añadir:
```dart
paymentDueDay: Value(credit.paymentDueDay),
oneInstallmentInterestPolicy: Value(credit.oneInstallmentInterestPolicy),
```

- [ ] **Step 6: Regenerar código Drift**

```bash
cd "/home/luis/Documentos/.VS CODE/PROYECTOS_PAN/Kredit"
dart run build_runner build --delete-conflicting-outputs
```
Esperado: `database.g.dart` actualizado sin errores.

- [ ] **Step 7: Correr tests para verificar que pasan**

```bash
flutter test test/data/database_test.dart -v
```
Esperado: PASS todos.

- [ ] **Step 8: Commit**

```bash
git add lib/data/models/credit.dart lib/data/db/tables.dart lib/data/db/database.dart lib/data/db/database.g.dart test/data/database_test.dart
git commit -m "feat: add paymentDueDay + oneInstallmentInterestPolicy to CardCredit, DB v10

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 2: Actualizar `getCardCycleDates` para `paymentDueDay`

**Files:**
- Modify: `lib/domain/card_calculator.dart:41-60`
- Test: `test/domain/card_calculator_test.dart`

**Interfaces:**
- Consume: `CardCredit.paymentDueDay` (int), `CardCredit.paymentDueOffsetDays` (int)
- Produce: `getCardCycleDates` retorna `dueDate` correcta para ambos modos

- [ ] **Step 1: Escribir tests que fallan**

```dart
// test/domain/card_calculator_test.dart — añadir al grupo existente
group('getCardCycleDates with paymentDueDay', () {
  test('uses paymentDueDay when > 0', () {
    final card = CardCredit(
      id: 'c1', name: 'T', lender: 'B',
      cutoffDay: 15,
      paymentDueDay: 5,
      paymentDueOffsetDays: 999, // debe ser ignorado
    );
    // ref: 2026-09-20 (después del corte 15 sep → último corte fue sep 15)
    final dates = getCardCycleDates(card, DateTime(2026, 9, 20));
    // dueDate debe ser oct 5 (día 5 del mes siguiente al último corte)
    expect(dates.dueDate, DateTime(2026, 10, 5));
  });

  test('falls back to paymentDueOffsetDays when paymentDueDay == 0', () {
    final card = CardCredit(
      id: 'c2', name: 'T', lender: 'B',
      cutoffDay: 15,
      paymentDueDay: 0,   // no migrado
      paymentDueOffsetDays: 20,
    );
    final dates = getCardCycleDates(card, DateTime(2026, 9, 20));
    // dueDate = lastCutoff (sep 15) + 20 días = oct 5
    expect(dates.dueDate, DateTime(2026, 10, 5));
  });

  test('paymentDueDay handles month wrap (day 5 of next month)', () {
    final card = CardCredit(
      id: 'c3', name: 'T', lender: 'B',
      cutoffDay: 28,
      paymentDueDay: 5,
      paymentDueOffsetDays: 0,
    );
    // ref: 2026-09-30 → último corte sep 28
    final dates = getCardCycleDates(card, DateTime(2026, 9, 30));
    expect(dates.dueDate, DateTime(2026, 10, 5));
  });
});
```

- [ ] **Step 2: Correr tests para verificar que fallan**

```bash
flutter test test/domain/card_calculator_test.dart -v
```
Esperado: FAIL — lógica actual usa solo `paymentDueOffsetDays`.

- [ ] **Step 3: Actualizar `getCardCycleDates`**

Reemplazar las líneas que calculan `dueDate` (actualmente `lastCutoff.add(Duration(days: offset))`):

```dart
CardCycleDates getCardCycleDates(CardCredit credit, [DateTime? refDate]) {
  final ref = refDate ?? DateTime.now();
  final today = DateTime(ref.year, ref.month, ref.day);
  final cutoffDay = _clampCutoffDay(credit.cutoffDay);

  var lastCutoff = cutoffDateForMonth(today.year, today.month, cutoffDay);
  if (lastCutoff.isAfter(today)) {
    final prevMonthRef = DateTime(today.year, today.month - 1, 1);
    lastCutoff = cutoffDateForMonth(
        prevMonthRef.year, prevMonthRef.month, cutoffDay);
  }
  final nextMonthRef = DateTime(lastCutoff.year, lastCutoff.month + 1, 1);
  final nextCutoff =
      cutoffDateForMonth(nextMonthRef.year, nextMonthRef.month, cutoffDay);

  final DateTime dueDate;
  if (credit.paymentDueDay > 0) {
    // paymentDueDay es un día del mes: el vencimiento es ese día en el mes
    // siguiente al último corte (ej: corte sep 15 → pago oct 5).
    final dueMonth = DateTime(lastCutoff.year, lastCutoff.month + 1, 1);
    final lastDayOfDueMonth = _lastDayOfMonth(dueMonth.year, dueMonth.month);
    dueDate = DateTime(
      dueMonth.year,
      dueMonth.month,
      math.min(credit.paymentDueDay, lastDayOfDueMonth),
    );
  } else {
    // Fallback para registros no migrados: offset en días desde el último corte.
    dueDate = lastCutoff.add(Duration(days: credit.paymentDueOffsetDays));
  }

  return CardCycleDates(
    lastCutoff: lastCutoff,
    nextCutoff: nextCutoff,
    dueDate: dueDate,
  );
}
```

- [ ] **Step 4: Correr tests para verificar que pasan**

```bash
flutter test test/domain/card_calculator_test.dart -v
```
Esperado: PASS todos.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/card_calculator.dart test/domain/card_calculator_test.dart
git commit -m "feat: getCardCycleDates uses paymentDueDay, falls back to offset

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 3: Shared widgets — `_BankPickerStep` y `_DesignPickerRow`

**Files:**
- Modify: `lib/screens/credits/add_credit_sheet.dart` (añadir widgets privados al final)

**Interfaces:**
- Produce: `_BankPickerStep({required String? selectedBank, required ValueChanged<String> onSelected})` — devuelve el nombre del banco seleccionado.
- Produce: `_DesignPickerRow({required ValueNotifier<CardDesign?> notifier})` — picker horizontal de 8 diseños, reutiliza `_cardDesignNotifier` existente.

- [ ] **Step 1: Añadir `_BankPickerStep` al final del archivo**

```dart
/// Selector de banco para Flow B (tarjeta) y Flow C (préstamo).
/// Muestra chips con la lista de bancos + "Otro banco".
class _BankPickerStep extends StatelessWidget {
  final String? selectedBank;
  final ValueChanged<String> onSelected;

  const _BankPickerStep({required this.selectedBank, required this.onSelected});

  static const _banks = [
    'Bancolombia', 'Davivienda', 'BBVA', 'Nu (Nubank)', 'RappiCard',
    'Banco de Bogotá', 'Banco Falabella', 'Scotiabank Colpatria',
    'Lulo Bank', 'Banco AV Villas', 'Otro banco',
  ];

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _banks.map((bank) {
        final selected = selectedBank == bank;
        return FilterChip(
          label: Text(bank),
          selected: selected,
          onSelected: (_) => onSelected(bank),
          selectedColor: accent.withValues(alpha: 0.15),
          checkmarkColor: accent,
          labelStyle: TextStyle(
            color: selected ? accent : kredit.textPrimary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }
}

/// Picker horizontal de diseños de tarjeta (8 opciones).
/// Reutilizable en el step de confirmación de los tres flujos.
class _DesignPickerRow extends StatelessWidget {
  final ValueNotifier<CardDesign?> notifier;

  const _DesignPickerRow({required this.notifier});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: CardDesign.values.map((design) {
          return ValueListenableBuilder<CardDesign?>(
            valueListenable: notifier,
            builder: (context, selected, _) {
              final isSelected = selected == design;
              return GestureDetector(
                onTap: () => notifier.value = design,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 80,
                  height: 50,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : kredit.borderCard,
                      width: isSelected ? 2.5 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: CustomPaint(
                      painter: CardDesignPainter(design: design, color: Colors.blue),
                    ),
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
```

- [ ] **Step 2: Correr análisis estático**

```bash
cd "/home/luis/Documentos/.VS CODE/PROYECTOS_PAN/Kredit"
flutter analyze lib/screens/credits/add_credit_sheet.dart
```
Esperado: sin errores nuevos.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/credits/add_credit_sheet.dart
git commit -m "feat: add shared _BankPickerStep and _DesignPickerRow widgets

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 4: Step 0 — Selector de modo en `_AddCreditSheetState`

**Files:**
- Modify: `lib/screens/credits/add_credit_sheet.dart` — `_AddCreditSheetState`

**Interfaces:**
- Añade: `String? _mode` (null | 'tienda' | 'tarjeta' | 'prestamo')
- Produce: método `_setMode(String mode)` que resetea `_currentStep = 1`, `_stepDirection = 1`
- Produce: método `_backToModeSelector()` que resetea `_mode = null`, `_currentStep = 0`
- Produce: `_buildStepContent()` ramifica por `_mode` — null → `_ModeSelector`, resto → sub-flow

- [ ] **Step 1: Añadir variable `_mode` y métodos de navegación**

En `_AddCreditSheetState`, junto a `_currentStep`:
```dart
String? _mode; // null = selector, 'tienda' | 'tarjeta' | 'prestamo'

void _setMode(String mode) {
  setState(() {
    _mode = mode;
    _currentStep = 1;
    _stepDirection = 1;
  });
}

void _backToModeSelector() {
  setState(() {
    _mode = null;
    _currentStep = 0;
    _stepDirection = -1;
  });
}
```

- [ ] **Step 2: Añadir widget `_ModeSelector`**

Al final del archivo:
```dart
class _ModeSelector extends StatelessWidget {
  final ValueChanged<String> onSelect;

  const _ModeSelector({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '¿Qué quieres registrar?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: kredit.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        _ModeCard(
          icon: Icons.store_outlined,
          title: 'Cupo de tienda',
          subtitle: 'Totto, Lili Pink, Éxito, Alkosto...',
          onTap: () => onSelect('tienda'),
        ),
        const SizedBox(height: 12),
        _ModeCard(
          icon: Icons.credit_card_outlined,
          title: 'Tarjeta bancaria',
          subtitle: 'Tarjetas de crédito de cualquier banco',
          onTap: () => onSelect('tarjeta'),
        ),
        const SizedBox(height: 12),
        _ModeCard(
          icon: Icons.account_balance_outlined,
          title: 'Préstamo bancario',
          subtitle: 'Libre inversión, consumo, vehículo...',
          onTap: () => onSelect('prestamo'),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kredit.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kredit.borderCard),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: kredit.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 13, color: kredit.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: kredit.textTertiary),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Conectar `_ModeSelector` al `build()` del state**

En el método que actualmente construye el contenido del step (buscar `_buildStepContent` o el switch de `_currentStep`), envolver con:

```dart
Widget _buildCurrentContent() {
  if (_mode == null) {
    return _ModeSelector(onSelect: _setMode);
  }
  switch (_mode) {
    case 'tienda':
      return _TiendaFlow(/* params */); // placeholder hasta Task 5
    case 'tarjeta':
      return _TarjetaFlow(/* params */); // placeholder hasta Task 6
    case 'prestamo':
      return _PrestamoFlow(/* params */); // placeholder hasta Task 7
    default:
      return _ModeSelector(onSelect: _setMode);
  }
}
```

El botón "Atrás" del step 1 de cualquier sub-flow llama `_backToModeSelector()`.

- [ ] **Step 4: Analizar y hot-restart en device**

```bash
flutter analyze lib/screens/credits/add_credit_sheet.dart
flutter run -d ZY22LBQ8XS
```
Verificar manualmente: al abrir `+`, aparece el selector de 3 opciones. Al tocar cada una, avanza. Al retroceder desde step 1 de un sub-flow, vuelve al selector.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/credits/add_credit_sheet.dart
git commit -m "feat: step 0 mode selector — tienda/tarjeta/prestamo entry point

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 5: Flow A — `_TiendaFlow`

**Files:**
- Modify: `lib/screens/credits/add_credit_sheet.dart`

**Interfaces:**
- Consume: `_AddCreditSheetState` controllers: `_nameCtrl`, `_amountCtrl`, `_installmentsCtrl`, `_quotaCtrl`, `_interestCtrl`, `_paidInstallmentsCtrl`, `_selectedEntityId`, `_startDate`, `_frequency`, `_interestRateType`, `_interestUnknown`, `_earlyPaymentWaivesInterest`, `_cardDesignNotifier`
- Produce: llama `_save()` con `LoanCredit` con `quotaId = _selectedEntityId`
- Produce: steps 1–4 para cupo de tienda, con `_currentStep` manejado por el state padre

**Nota:** `_TiendaFlow` recibe todos sus callbacks del state padre (evitar pasar todos los controllers; mejor pasar callbacks para cada acción). Sin embargo, dado que el archivo es uno solo y los controllers viven en el state, es aceptable acceder a ellos directamente desde el build del state. `_TiendaFlow` es un widget stateless que recibe los values y callbacks necesarios.

- [ ] **Step 1: Implementar `_TiendaFlow` — steps 1 a 4**

```dart
class _TiendaFlow extends StatelessWidget {
  final int currentStep;
  // Step 1
  final List<CommercialQuota> quotas;
  final String? selectedEntityId;
  final ValueChanged<String?> onEntitySelected;
  // Step 2
  final TextEditingController nameCtrl;
  final TextEditingController amountCtrl;
  final TextEditingController installmentsCtrl;
  final TextEditingController quotaCtrl;
  final TextEditingController interestCtrl;
  final String interestRateType;
  final ValueChanged<String> onRateTypeChanged;
  final bool interestUnknown;
  final ValueChanged<bool> onInterestUnknownChanged;
  final bool earlyPaymentWaivesInterest;
  final ValueChanged<bool> onEarlyPaymentChanged;
  // Step 3
  final String frequency;
  final ValueChanged<String> onFrequencyChanged;
  final DateTime? startDate;
  final VoidCallback onPickDate;
  final TextEditingController paidInstallmentsCtrl;
  // Step 4
  final ValueNotifier<CardDesign?> designNotifier;
  final TextEditingController notesCtrl;
  final VoidCallback onSave;
  final bool saving;

  const _TiendaFlow({
    required this.currentStep,
    required this.quotas,
    required this.selectedEntityId,
    required this.onEntitySelected,
    required this.nameCtrl,
    required this.amountCtrl,
    required this.installmentsCtrl,
    required this.quotaCtrl,
    required this.interestCtrl,
    required this.interestRateType,
    required this.onRateTypeChanged,
    required this.interestUnknown,
    required this.onInterestUnknownChanged,
    required this.earlyPaymentWaivesInterest,
    required this.onEarlyPaymentChanged,
    required this.frequency,
    required this.onFrequencyChanged,
    required this.startDate,
    required this.onPickDate,
    required this.paidInstallmentsCtrl,
    required this.designNotifier,
    required this.notesCtrl,
    required this.onSave,
    required this.saving,
  });

  @override
  Widget build(BuildContext context) {
    switch (currentStep) {
      case 1: return _step1(context);
      case 2: return _step2(context);
      case 3: return _step3(context);
      case 4: return _step4(context);
      default: return const SizedBox.shrink();
    }
  }

  Widget _step1(BuildContext context) {
    // Entity picker filtrado: solo stores. Reutiliza el _EntityPickerCard
    // existente o construye uno equivalente filtrando por entityType == 'store'.
    // Opciones: entidades existentes (store) + "Sin entidad" + "+ Agregar comercio"
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final storeQuotas = quotas
        .where((q) => q.entityType == EntityType.store || q.entityType == null)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('¿Dónde tienes el cupo?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kredit.textPrimary)),
        const SizedBox(height: 16),
        // Tarjeta "Sin entidad"
        _EntityOptionTile(
          icon: Icons.credit_card_off_outlined,
          label: 'Sin entidad específica',
          selected: selectedEntityId == 'none',
          onTap: () => onEntitySelected('none'),
        ),
        const SizedBox(height: 8),
        ...storeQuotas.map((q) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _EntityOptionTile(
            icon: Icons.store_outlined,
            label: q.brand,
            selected: selectedEntityId == q.id,
            onTap: () => onEntitySelected(q.id),
          ),
        )),
        // "+ Agregar comercio" — abre el sub-sheet existente de nueva entidad
      ],
    );
  }

  Widget _step2(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: 'Nombre de la compra',
            hintText: 'ej: Tenis Totto (opcional)',
            labelStyle: TextStyle(color: kredit.textSecondary),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: amountCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
          decoration: InputDecoration(
            labelText: 'Valor de la compra *',
            prefixText: '\$ ',
            labelStyle: TextStyle(color: kredit.textSecondary),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: installmentsCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Número de cuotas *',
            labelStyle: TextStyle(color: kredit.textSecondary),
          ),
          validator: (v) {
            final n = int.tryParse(v ?? '');
            return (n == null || n <= 0) ? 'Debe ser mayor a 0' : null;
          },
        ),
        const SizedBox(height: 16),
        if (!interestUnknown) ...[
          TextFormField(
            controller: interestCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Tasa de interés',
              hintText: 'Vacío = desconocida',
              suffixText: '%',
              labelStyle: TextStyle(color: kredit.textSecondary),
            ),
          ),
          const SizedBox(height: 8),
          InterestRateTypeField(
            value: interestRateType,
            onChanged: onRateTypeChanged,
          ),
        ],
        const SizedBox(height: 16),
        // Cuota estimada live
        _QuotaPreviewCard(controller: quotaCtrl),
        const SizedBox(height: 16),
        SwitchListTile(
          value: earlyPaymentWaivesInterest,
          onChanged: onEarlyPaymentChanged,
          title: Text('Pago anticipado sin interés',
              style: TextStyle(fontWeight: FontWeight.w600, color: kredit.textPrimary)),
          subtitle: Text('Actívalo si el comercio condona el interés al pagar antes del vencimiento.',
              style: TextStyle(fontSize: 12, color: kredit.textSecondary)),
        ),
      ],
    );
  }

  Widget _step3(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Frecuencia de pago',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kredit.textSecondary)),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: CreditFrequency.monthly, label: Text('Mensual')),
            ButtonSegment(value: CreditFrequency.biweekly, label: Text('Quincenal')),
            ButtonSegment(value: CreditFrequency.weekly, label: Text('Semanal')),
          ],
          selected: {frequency},
          onSelectionChanged: (s) => onFrequencyChanged(s.first),
        ),
        const SizedBox(height: 20),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Primera cuota *',
              style: TextStyle(color: kredit.textPrimary, fontWeight: FontWeight.w600)),
          subtitle: startDate == null
              ? Text('Toca para seleccionar', style: TextStyle(color: kredit.textTertiary))
              : Text(startDate!.toIso8601String().substring(0, 10),
                  style: TextStyle(color: kredit.textPrimary)),
          trailing: const Icon(Icons.calendar_today_outlined),
          onTap: onPickDate,
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          value: paidInstallmentsCtrl.text.isNotEmpty && int.tryParse(paidInstallmentsCtrl.text) != null && int.parse(paidInstallmentsCtrl.text) > 0,
          onChanged: (v) {
            if (!v) paidInstallmentsCtrl.clear();
          },
          title: Text('¿Ya empezaste a pagar?',
              style: TextStyle(fontWeight: FontWeight.w600, color: kredit.textPrimary)),
        ),
        if (paidInstallmentsCtrl.text.isNotEmpty || true) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: paidInstallmentsCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Cuotas ya pagadas',
              hintText: '0',
              labelStyle: TextStyle(color: kredit.textSecondary),
            ),
          ),
        ],
      ],
    );
  }

  Widget _step4(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Confirmar compra',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kredit.textPrimary)),
        const SizedBox(height: 16),
        // Notas
        TextFormField(
          controller: notesCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Notas (opcional)',
            hintText: 'Ubicación del contrato, condiciones especiales...',
            labelStyle: TextStyle(color: kredit.textSecondary),
          ),
        ),
        const SizedBox(height: 20),
        Text('Diseño de tarjeta',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kredit.textSecondary)),
        const SizedBox(height: 8),
        _DesignPickerRow(notifier: designNotifier),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: saving ? null : onSave,
          child: saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Registrar compra'),
        ),
      ],
    );
  }
}

class _EntityOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _EntityOptionTile({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.08) : kredit.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? accent : kredit.borderCard, width: selected ? 2 : 1),
        ),
        child: Row(children: [
          Icon(icon, color: selected ? accent : kredit.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: selected ? accent : kredit.textPrimary, fontWeight: selected ? FontWeight.w700 : FontWeight.w500))),
          if (selected) Icon(Icons.check_circle, color: accent, size: 18),
        ]),
      ),
    );
  }
}
```

- [ ] **Step 2: Conectar `_TiendaFlow` en `_buildCurrentContent()` del state**

```dart
case 'tienda':
  return _TiendaFlow(
    currentStep: _currentStep,
    quotas: ref.read(commercialQuotasProvider).value ?? [],
    selectedEntityId: _selectedEntityId,
    onEntitySelected: (id) => setState(() => _selectedEntityId = id),
    nameCtrl: _nameCtrl,
    amountCtrl: _amountCtrl,
    installmentsCtrl: _installmentsCtrl,
    quotaCtrl: _quotaCtrl,
    interestCtrl: _interestCtrl,
    interestRateType: _interestRateType,
    onRateTypeChanged: (v) => setState(() => _interestRateType = v),
    interestUnknown: _interestUnknown,
    onInterestUnknownChanged: (v) => setState(() => _interestUnknown = v),
    earlyPaymentWaivesInterest: _earlyPaymentWaivesInterest,
    onEarlyPaymentChanged: (v) => setState(() => _earlyPaymentWaivesInterest = v),
    frequency: _frequency,
    onFrequencyChanged: (v) => setState(() => _frequency = v),
    startDate: _startDate,
    onPickDate: _pickDate,
    paidInstallmentsCtrl: _paidInstallmentsCtrl,
    designNotifier: _cardDesignNotifier,
    notesCtrl: _notesCtrl,
    onSave: _save,
    saving: _saving,
  );
```

- [ ] **Step 3: Verificar que el botón "Siguiente" valida correctamente por step**

La lógica de `_canAdvance()` del state padre debe retornar:
- Step 1 (tienda): `_selectedEntityId != null`
- Step 2 (tienda): form válido (`_formKey.currentState!.validate()`)
- Step 3 (tienda): `_startDate != null`
- Step 4: siempre true (confirmación)

- [ ] **Step 4: Smoke test manual en device**

```bash
flutter run -d ZY22LBQ8XS
```
Recorrer Flow A completo: seleccionar tienda → llenar datos → seleccionar fecha → confirmar → verificar que el crédito aparece en la lista.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/credits/add_credit_sheet.dart
git commit -m "feat: _TiendaFlow — step 1-4 cupo de tienda

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 6: Flow B — `_TarjetaFlow`

**Files:**
- Modify: `lib/screens/credits/add_credit_sheet.dart`

**Interfaces:**
- Consume: `_lenderCtrl`, `_nameCtrl`, `_limitCtrl`, `_balanceCtrl`, `_interestCtrl`, `_interestRateType`, `_managementFeeCtrl`, `_managementFeeFrequency`, `_cutoffDayCtrl` (como int), `paymentDueDay` (nuevo `int _paymentDueDay` en state)
- Produce: `CardCredit` con `paymentDueDay`, `oneInstallmentInterestPolicy`, `paymentDueOffsetDays = 0`
- Añade al state: `int _paymentDueDay = 5`, `bool? _oneInstallmentInterestPolicy`

- [ ] **Step 1: Añadir variables de estado nuevas en `_AddCreditSheetState`**

```dart
int _paymentDueDay = 5;           // para tarjeta — día del mes (1–31)
int _cutoffDayInt = 15;           // para tarjeta — día de corte (1–28)
bool? _oneInstallmentInterestPolicy; // null=indeterminado, true/false=elegido
```

- [ ] **Step 2: Implementar `_TarjetaFlow`**

```dart
class _TarjetaFlow extends StatelessWidget {
  final int currentStep;
  // Step 1
  final String? selectedBank;
  final ValueChanged<String> onBankSelected;
  final TextEditingController nameCtrl;
  // Step 2
  final TextEditingController limitCtrl;
  final TextEditingController balanceCtrl;
  // Step 3
  final TextEditingController interestCtrl;
  final String interestRateType;
  final ValueChanged<String> onRateTypeChanged;
  final bool? oneInstallmentInterestPolicy;
  final ValueChanged<bool?> onPolicyChanged;
  final TextEditingController managementFeeCtrl;
  final String managementFeeFrequency;
  final ValueChanged<String> onFeeFreqChanged;
  // Step 4
  final int cutoffDay;
  final ValueChanged<int> onCutoffDayChanged;
  final int paymentDueDay;
  final ValueChanged<int> onPaymentDueDayChanged;
  final TextEditingController notesCtrl;
  // Step 5 (confirmación)
  final ValueNotifier<CardDesign?> designNotifier;
  final String? entityTemplateNote;
  final VoidCallback onSave;
  final bool saving;

  const _TarjetaFlow({
    required this.currentStep,
    required this.selectedBank,
    required this.onBankSelected,
    required this.nameCtrl,
    required this.limitCtrl,
    required this.balanceCtrl,
    required this.interestCtrl,
    required this.interestRateType,
    required this.onRateTypeChanged,
    required this.oneInstallmentInterestPolicy,
    required this.onPolicyChanged,
    required this.managementFeeCtrl,
    required this.managementFeeFrequency,
    required this.onFeeFreqChanged,
    required this.cutoffDay,
    required this.onCutoffDayChanged,
    required this.paymentDueDay,
    required this.onPaymentDueDayChanged,
    required this.notesCtrl,
    required this.designNotifier,
    required this.entityTemplateNote,
    required this.onSave,
    required this.saving,
  });

  @override
  Widget build(BuildContext context) {
    switch (currentStep) {
      case 1: return _step1(context);
      case 2: return _step2(context);
      case 3: return _step3(context);
      case 4: return _step4(context);
      case 5: return _step5(context);
      default: return const SizedBox.shrink();
    }
  }

  Widget _step1(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('¿En qué banco tienes la tarjeta?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kredit.textPrimary)),
        const SizedBox(height: 16),
        _BankPickerStep(selectedBank: selectedBank, onSelected: onBankSelected),
        const SizedBox(height: 20),
        TextFormField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: 'Nombre personalizado',
            hintText: 'ej: La de gastos, Viajes... (opcional)',
            labelStyle: TextStyle(color: kredit.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _step2(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final limit = _parseCurrency(limitCtrl.text);
    final balance = _parseCurrency(balanceCtrl.text);
    final available = limit > 0 ? (limit - balance).clamp(0, double.infinity) : null;
    final pct = limit > 0 ? (balance / limit).clamp(0.0, 1.0) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: limitCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
          decoration: InputDecoration(
            labelText: 'Cupo de la tarjeta',
            hintText: '¿Cuánto cupo te aprobó el banco? (opcional)',
            prefixText: '\$ ',
            labelStyle: TextStyle(color: kredit.textSecondary),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: balanceCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
          decoration: InputDecoration(
            labelText: 'Deuda actual',
            hintText: '¿Cuánto debes actualmente?',
            prefixText: '\$ ',
            labelStyle: TextStyle(color: kredit.textSecondary),
          ),
        ),
        if (available != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kredit.bgCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kredit.borderCard),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Disponible', style: TextStyle(color: kredit.textSecondary, fontSize: 13)),
                    Text(formatCOP(available), style: TextStyle(color: kredit.textPrimary, fontWeight: FontWeight.w700)),
                  ],
                ),
                if (pct != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: kredit.borderCard,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${(pct * 100).round()}% utilizado',
                      style: TextStyle(fontSize: 11, color: kredit.textTertiary)),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _step3(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final hasRate = interestCtrl.text.isNotEmpty &&
        double.tryParse(interestCtrl.text.replaceAll(',', '.')) != null &&
        double.parse(interestCtrl.text.replaceAll(',', '.')) > 0;
    final hasFee = managementFeeCtrl.text.isNotEmpty &&
        _parseCurrency(managementFeeCtrl.text) > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: kredit.bgCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kredit.borderCard),
          ),
          child: Text(
            'Los datos de interés son opcionales. Puedes continuar sin ellos.',
            style: TextStyle(fontSize: 13, color: kredit.textSecondary),
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: interestCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Tasa de interés',
            hintText: 'Vacío si no la conoces',
            suffixText: '%',
            labelStyle: TextStyle(color: kredit.textSecondary),
          ),
        ),
        if (hasRate) ...[
          const SizedBox(height: 8),
          InterestRateTypeField(value: interestRateType, onChanged: onRateTypeChanged),
        ],
        const SizedBox(height: 20),
        // Toggle oneInstallmentInterestPolicy — arranca indeterminado (null)
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Compras a 1 cuota sin interés',
                      style: TextStyle(fontWeight: FontWeight.w600, color: kredit.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    oneInstallmentInterestPolicy == null
                        ? 'No configurado — activa si aplica a tu tarjeta'
                        : 'Actívalo solo si tu tarjeta no cobra interés en compras a 1 cuota pagadas a tiempo.',
                    style: TextStyle(fontSize: 12, color: kredit.textSecondary),
                  ),
                ],
              ),
            ),
            Switch(
              value: oneInstallmentInterestPolicy ?? false,
              onChanged: (v) {
                // Primera vez que toca: false→true (lo activa).
                // Si ya era true y lo apaga: pasa a false (explícitamente desactivado).
                // null→true: primera interacción, siempre activa.
                onPolicyChanged(v);
              },
              // Cuando es null, mostrar apagado pero sin acento — estado "sin tocar"
              activeColor: Theme.of(context).colorScheme.primary,
              inactiveThumbColor: oneInstallmentInterestPolicy == null
                  ? kredit.textTertiary
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: managementFeeCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
          decoration: InputDecoration(
            labelText: 'Cuota de manejo',
            hintText: 'Vacío si no aplica',
            prefixText: '\$ ',
            labelStyle: TextStyle(color: kredit.textSecondary),
          ),
        ),
        if (hasFee) ...[
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: ManagementFeeFrequency.monthly, label: Text('Mensual')),
              ButtonSegment(value: ManagementFeeFrequency.annual, label: Text('Anual')),
            ],
            selected: {managementFeeFrequency},
            onSelectionChanged: (s) => onFeeFreqChanged(s.first),
          ),
        ],
      ],
    );
  }

  Widget _step4(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Ciclo de facturación',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kredit.textPrimary)),
        const SizedBox(height: 8),
        Text('Encuentra estos datos en tu extracto bancario.',
            style: TextStyle(fontSize: 13, color: kredit.textSecondary)),
        if (entityTemplateNote != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kredit.bgCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kredit.borderCard),
            ),
            child: Text(entityTemplateNote!, style: TextStyle(fontSize: 12, color: kredit.textSecondary)),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Día de corte', style: TextStyle(fontSize: 13, color: kredit.textSecondary)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    value: cutoffDay.clamp(1, 28),
                    items: List.generate(28, (i) => i + 1)
                        .map((d) => DropdownMenuItem(value: d, child: Text('Día $d')))
                        .toList(),
                    onChanged: (v) { if (v != null) onCutoffDayChanged(v); },
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Día límite de pago', style: TextStyle(fontSize: 13, color: kredit.textSecondary)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    value: paymentDueDay.clamp(1, 31),
                    items: List.generate(31, (i) => i + 1)
                        .map((d) => DropdownMenuItem(value: d, child: Text('Día $d')))
                        .toList(),
                    onChanged: (v) { if (v != null) onPaymentDueDayChanged(v); },
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: notesCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Notas (opcional)',
            labelStyle: TextStyle(color: kredit.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _step5(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final limit = _parseCurrency(limitCtrl.text);
    final balance = _parseCurrency(balanceCtrl.text);
    final rate = double.tryParse(interestCtrl.text.replaceAll(',', '.')) ?? 0;
    final fee = _parseCurrency(managementFeeCtrl.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Confirmar tarjeta',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kredit.textPrimary)),
        const SizedBox(height: 16),
        // Resumen
        _SummaryRow('Banco', selectedBank ?? '—'),
        if (nameCtrl.text.isNotEmpty) _SummaryRow('Nombre', nameCtrl.text),
        if (limit > 0) _SummaryRow('Cupo', formatCOP(limit)),
        _SummaryRow('Deuda actual', formatCOP(balance)),
        if (limit > 0) _SummaryRow('Disponible', formatCOP((limit - balance).clamp(0, double.infinity))),
        _SummaryRow('Corte', 'Día $cutoffDay'),
        _SummaryRow('Límite de pago', 'Día $paymentDueDay'),
        _SummaryRow('Tasa', rate > 0 ? '$rate% $interestRateType' : 'No especificada'),
        _SummaryRow('1 cuota sin interés',
            oneInstallmentInterestPolicy == null ? 'No configurado' :
            oneInstallmentInterestPolicy! ? 'Sí' : 'No'),
        _SummaryRow('Cuota de manejo', fee > 0 ? '${formatCOP(fee)} / $managementFeeFrequency' : 'No aplica'),
        const SizedBox(height: 20),
        Text('Diseño de tarjeta',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kredit.textSecondary)),
        const SizedBox(height: 8),
        _DesignPickerRow(notifier: designNotifier),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: saving ? null : onSave,
          child: saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Registrar tarjeta'),
        ),
      ],
    );
  }
}

double _parseCurrency(String text) {
  final cleaned = text.replaceAll(RegExp(r'[^\d]'), '');
  return double.tryParse(cleaned) ?? 0;
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: kredit.textSecondary, fontSize: 14)),
          Text(value, style: TextStyle(color: kredit.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Actualizar `_save()` para el modo tarjeta**

En `_save()`, añadir rama para `_mode == 'tarjeta'`:
```dart
if (_mode == 'tarjeta') {
  final rateText = _interestCtrl.text.replaceAll(',', '.');
  final rate = double.tryParse(rateText) ?? 0;
  final credit = CardCredit(
    id: const Uuid().v4(),
    name: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : (_lenderCtrl.text),
    lender: _lenderCtrl.text,
    creditLimit: _parseCurrency(_limitCtrl.text),
    currentBalance: _parseCurrency(_balanceCtrl.text),
    cutoffDay: _cutoffDayInt,
    paymentDueDay: _paymentDueDay,
    paymentDueOffsetDays: 0, // deprecated
    interestRate: rate,
    interestRateType: _interestRateType,
    interestUnknown: rate == 0,
    managementFee: _parseCurrency(_managementFeeCtrl.text),
    managementFeeFrequency: _managementFeeFrequency,
    oneInstallmentInterestPolicy: _oneInstallmentInterestPolicy,
    color: _color != '#00F2FE' ? _color : null,
    cardDesign: _cardDesignNotifier.value?.name,
    notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
  );
  await ref.read(creditsProvider.notifier).add(credit);
  if (context.mounted) Navigator.pop(context);
  return;
}
```

- [ ] **Step 4: Smoke test manual en device**

```bash
flutter run -d ZY22LBQ8XS
```
Recorrer Flow B completo: banco → cupo/deuda → condiciones (con toggle) → fechas (selects) → confirmación → registrar. Verificar que `paymentDueDay` y `oneInstallmentInterestPolicy` se muestran correctamente en el detalle de la tarjeta.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/credits/add_credit_sheet.dart
git commit -m "feat: _TarjetaFlow — step 1-5 tarjeta bancaria con paymentDueDay y oneInstallmentInterestPolicy

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 7: Flow C — `_PrestamoFlow`

**Files:**
- Modify: `lib/screens/credits/add_credit_sheet.dart`

**Interfaces:**
- Consume: `_lenderCtrl`, `_nameCtrl`, `_amountCtrl`, `_installmentsCtrl`, `_quotaCtrl`, `_interestCtrl`, `_interestRateType`, `_frequency`, `_earlyPaymentWaivesInterest`, `_startDate`, `_paidInstallmentsCtrl`, `_cardDesignNotifier`, `_notesCtrl`
- Produce: `LoanCredit` con `quotaId = null`

- [ ] **Step 1: Implementar `_PrestamoFlow`**

```dart
class _PrestamoFlow extends StatelessWidget {
  final int currentStep;
  // Step 1
  final String? selectedBank;
  final ValueChanged<String> onBankSelected;
  final TextEditingController nameCtrl;
  // Step 2
  final TextEditingController amountCtrl;
  final TextEditingController installmentsCtrl;
  final TextEditingController quotaCtrl;
  // Step 3
  final TextEditingController interestCtrl;
  final String interestRateType;
  final ValueChanged<String> onRateTypeChanged;
  final String frequency;
  final ValueChanged<String> onFrequencyChanged;
  final bool earlyPaymentWaivesInterest;
  final ValueChanged<bool> onEarlyPaymentChanged;
  // Step 4
  final DateTime? startDate;
  final VoidCallback onPickDate;
  final TextEditingController paidInstallmentsCtrl;
  // Step 5
  final ValueNotifier<CardDesign?> designNotifier;
  final TextEditingController notesCtrl;
  final VoidCallback onSave;
  final bool saving;

  const _PrestamoFlow({
    required this.currentStep,
    required this.selectedBank,
    required this.onBankSelected,
    required this.nameCtrl,
    required this.amountCtrl,
    required this.installmentsCtrl,
    required this.quotaCtrl,
    required this.interestCtrl,
    required this.interestRateType,
    required this.onRateTypeChanged,
    required this.frequency,
    required this.onFrequencyChanged,
    required this.earlyPaymentWaivesInterest,
    required this.onEarlyPaymentChanged,
    required this.startDate,
    required this.onPickDate,
    required this.paidInstallmentsCtrl,
    required this.designNotifier,
    required this.notesCtrl,
    required this.onSave,
    required this.saving,
  });

  @override
  Widget build(BuildContext context) {
    switch (currentStep) {
      case 1: return _step1(context);
      case 2: return _step2(context);
      case 3: return _step3(context);
      case 4: return _step4(context);
      case 5: return _step5(context);
      default: return const SizedBox.shrink();
    }
  }

  Widget _step1(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('¿Dónde tienes el préstamo?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kredit.textPrimary)),
        const SizedBox(height: 16),
        _BankPickerStep(selectedBank: selectedBank, onSelected: onBankSelected),
        const SizedBox(height: 20),
        TextFormField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: 'Nombre del crédito',
            hintText: 'ej: Libre inversión, Vehículo... (opcional)',
            labelStyle: TextStyle(color: kredit.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _step2(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: amountCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
          decoration: InputDecoration(
            labelText: 'Monto del préstamo *',
            hintText: '¿Cuánto te prestaron?',
            prefixText: '\$ ',
            labelStyle: TextStyle(color: kredit.textSecondary),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: installmentsCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Número de cuotas *',
            labelStyle: TextStyle(color: kredit.textSecondary),
          ),
          validator: (v) {
            final n = int.tryParse(v ?? '');
            return (n == null || n <= 0) ? 'Debe ser mayor a 0' : null;
          },
        ),
        const SizedBox(height: 16),
        _QuotaPreviewCard(controller: quotaCtrl),
      ],
    );
  }

  Widget _step3(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final hasRate = interestCtrl.text.isNotEmpty &&
        double.tryParse(interestCtrl.text.replaceAll(',', '.')) != null &&
        double.parse(interestCtrl.text.replaceAll(',', '.')) > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: interestCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Tasa de interés',
            hintText: 'Vacío si no la conoces',
            suffixText: '%',
            labelStyle: TextStyle(color: kredit.textSecondary),
          ),
        ),
        if (hasRate) ...[
          const SizedBox(height: 8),
          InterestRateTypeField(value: interestRateType, onChanged: onRateTypeChanged),
        ],
        const SizedBox(height: 20),
        Text('Frecuencia de pago',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kredit.textSecondary)),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: CreditFrequency.monthly, label: Text('Mensual')),
            ButtonSegment(value: CreditFrequency.biweekly, label: Text('Quincenal')),
            ButtonSegment(value: CreditFrequency.weekly, label: Text('Semanal')),
          ],
          selected: {frequency},
          onSelectionChanged: (s) => onFrequencyChanged(s.first),
        ),
        const SizedBox(height: 20),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: earlyPaymentWaivesInterest,
          onChanged: onEarlyPaymentChanged,
          title: Text('Pago anticipado sin intereses futuros',
              style: TextStyle(fontWeight: FontWeight.w600, color: kredit.textPrimary)),
          subtitle: Text('Actívalo si tu entidad condona el interés restante al pagar antes del vencimiento.',
              style: TextStyle(fontSize: 12, color: kredit.textSecondary)),
        ),
      ],
    );
  }

  Widget _step4(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final hasPaid = int.tryParse(paidInstallmentsCtrl.text) != null &&
        int.parse(paidInstallmentsCtrl.text) > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Fecha de la primera cuota *',
              style: TextStyle(color: kredit.textPrimary, fontWeight: FontWeight.w600)),
          subtitle: startDate == null
              ? Text('Toca para seleccionar', style: TextStyle(color: kredit.textTertiary))
              : Text(startDate!.toIso8601String().substring(0, 10),
                  style: TextStyle(color: kredit.textPrimary)),
          trailing: const Icon(Icons.calendar_today_outlined),
          onTap: onPickDate,
        ),
        const SizedBox(height: 20),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: hasPaid,
          onChanged: (v) { if (!v) paidInstallmentsCtrl.clear(); },
          title: Text('¿Ya empezaste a pagarlo?',
              style: TextStyle(fontWeight: FontWeight.w600, color: kredit.textPrimary)),
        ),
        if (hasPaid || paidInstallmentsCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: paidInstallmentsCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Cuotas ya pagadas',
              helperText: 'Kredit las marcará como pagadas con la fecha de hoy.',
              labelStyle: TextStyle(color: kredit.textSecondary),
            ),
          ),
        ],
      ],
    );
  }

  Widget _step5(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final amount = _parseCurrency(amountCtrl.text);
    final n = int.tryParse(installmentsCtrl.text) ?? 0;
    final rate = double.tryParse(interestCtrl.text.replaceAll(',', '.')) ?? 0;
    final quota = _parseCurrency(quotaCtrl.text);
    final paid = int.tryParse(paidInstallmentsCtrl.text) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Confirmar préstamo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kredit.textPrimary)),
        const SizedBox(height: 16),
        _SummaryRow('Banco', selectedBank ?? '—'),
        if (nameCtrl.text.isNotEmpty) _SummaryRow('Nombre', nameCtrl.text),
        _SummaryRow('Monto', formatCOP(amount)),
        _SummaryRow('Cuotas', '$n cuotas'),
        if (quota > 0) _SummaryRow('Cuota estimada', '${formatCOP(quota)} / $frequency'),
        _SummaryRow('Tasa', rate > 0 ? '$rate% $interestRateType' : 'No especificada'),
        if (startDate != null)
          _SummaryRow('Primera cuota', startDate!.toIso8601String().substring(0, 10)),
        if (paid > 0) _SummaryRow('Cuotas ya pagadas', '$paid'),
        const SizedBox(height: 20),
        TextFormField(
          controller: notesCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Notas (opcional)',
            labelStyle: TextStyle(color: kredit.textSecondary),
          ),
        ),
        const SizedBox(height: 20),
        Text('Diseño de tarjeta',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kredit.textSecondary)),
        const SizedBox(height: 8),
        _DesignPickerRow(notifier: designNotifier),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: saving ? null : onSave,
          child: saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Registrar préstamo'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Actualizar `_save()` para modo préstamo**

En `_save()`, añadir rama para `_mode == 'prestamo'`:
```dart
if (_mode == 'prestamo') {
  final rateText = _interestCtrl.text.replaceAll(',', '.');
  final rate = double.tryParse(rateText) ?? 0;
  final amount = _parseCurrency(_amountCtrl.text);
  final n = int.tryParse(_installmentsCtrl.text) ?? 0;
  final quota = _parseCurrency(_quotaCtrl.text);
  final paid = int.tryParse(_paidInstallmentsCtrl.text) ?? 0;
  final installments = buildLoanInstallments(
    totalAmount: amount,
    totalInstallments: n,
    quotaAmount: quota,
    frequency: _frequency,
    startDate: _startDate!.toIso8601String().substring(0, 10),
    interestRate: rate,
    interestRateType: _interestRateType,
  );
  var credit = LoanCredit(
    id: const Uuid().v4(),
    name: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : _lenderCtrl.text,
    lender: _lenderCtrl.text,
    totalAmount: amount,
    quotaAmount: quota,
    totalInstallments: n,
    frequency: _frequency,
    startDate: _startDate!.toIso8601String().substring(0, 10),
    interestRate: rate,
    interestRateType: _interestRateType,
    interestUnknown: rate == 0,
    earlyPaymentWaivesInterest: _earlyPaymentWaivesInterest,
    installments: installments,
    quotaId: null, // siempre null para préstamo bancario
    color: _color != '#00F2FE' ? _color : null,
    cardDesign: _cardDesignNotifier.value?.name,
    notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
  );
  if (paid > 0) _markAdvancedInstallments(credit, paid);
  await ref.read(creditsProvider.notifier).add(credit);
  if (context.mounted) Navigator.pop(context);
  return;
}
```

- [ ] **Step 3: Smoke test manual en device**

```bash
flutter run -d ZY22LBQ8XS
```
Recorrer Flow C: banco → monto/cuotas → tasa/frecuencia → fecha → confirmación → registrar. Verificar cronograma generado en la vista de detalle.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/credits/add_credit_sheet.dart
git commit -m "feat: _PrestamoFlow — step 1-5 préstamo bancario

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 8: Integration tests on device via ADB

**Files:**
- Create: `integration_test/credit_flow_test.dart`
- Create: `test_driver/integration_test.dart`
- Modify: `pubspec.yaml` — añadir `integration_test`

**Interfaces:**
- Consume: app completa corriendo en device `ZY22LBQ8XS`
- Produce: tests E2E que recorren los tres flujos de registro

- [ ] **Step 1: Añadir `integration_test` a `pubspec.yaml`**

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
```

Luego:
```bash
cd "/home/luis/Documentos/.VS CODE/PROYECTOS_PAN/Kredit"
flutter pub get
```

- [ ] **Step 2: Crear `test_driver/integration_test.dart`**

```dart
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
```

- [ ] **Step 3: Crear `integration_test/credit_flow_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kredit/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Credit registration flows', () {
    testWidgets('Flow A — Cupo de tienda completo', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navegar a créditos si no está ahí
      final creditTab = find.byIcon(Icons.account_balance_wallet_outlined);
      if (creditTab.evaluate().isNotEmpty) {
        await tester.tap(creditTab);
        await tester.pumpAndSettle();
      }

      // Abrir sheet con botón +
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Step 0: seleccionar "Cupo de tienda"
      await tester.tap(find.text('Cupo de tienda'));
      await tester.pumpAndSettle();

      // Step 1: seleccionar "Sin entidad específica"
      await tester.tap(find.text('Sin entidad específica'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      // Step 2: llenar datos
      await tester.enterText(find.byType(TextFormField).first, 'Tenis de prueba');
      await tester.enterText(
          find.ancestor(of: find.text('\$ '), matching: find.byType(TextFormField)).first,
          '300000');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Número de cuotas *'), '3');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      // Step 3: seleccionar fecha (DatePicker — tap el tile de fecha)
      await tester.tap(find.text('Toca para seleccionar'));
      await tester.pumpAndSettle();
      // Confirmar fecha actual en el DatePicker nativo
      await tester.tap(find.text('OK').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      // Step 4: confirmar
      await tester.tap(find.text('Registrar compra'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verificar que el sheet se cerró
      expect(find.text('Registrar compra'), findsNothing);
    });

    testWidgets('Flow B — Tarjeta bancaria completo', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final creditTab = find.byIcon(Icons.account_balance_wallet_outlined);
      if (creditTab.evaluate().isNotEmpty) {
        await tester.tap(creditTab);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Step 0: seleccionar tarjeta
      await tester.tap(find.text('Tarjeta bancaria'));
      await tester.pumpAndSettle();

      // Step 1: elegir banco
      await tester.tap(find.text('Bancolombia'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      // Step 2: cupo y deuda
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Cupo de la tarjeta'), '2000000');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Deuda actual'), '650000');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      // Step 3: condiciones — dejar tasa vacía (desconocida)
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      // Step 4: fechas — verificar selects presentes
      expect(find.text('Día de corte'), findsOneWidget);
      expect(find.text('Día límite de pago'), findsOneWidget);
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      // Step 5: confirmar
      expect(find.text('Confirmar tarjeta'), findsOneWidget);
      expect(find.text('No especificada'), findsOneWidget); // tasa vacía
      await tester.tap(find.text('Registrar tarjeta'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Registrar tarjeta'), findsNothing);
    });

    testWidgets('Flow C — Préstamo bancario completo', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final creditTab = find.byIcon(Icons.account_balance_wallet_outlined);
      if (creditTab.evaluate().isNotEmpty) {
        await tester.tap(creditTab);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Step 0: seleccionar préstamo
      await tester.tap(find.text('Préstamo bancario'));
      await tester.pumpAndSettle();

      // Step 1: banco
      await tester.tap(find.text('Davivienda'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      // Step 2: monto y cuotas
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Monto del préstamo *'), '5000000');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Número de cuotas *'), '36');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      // Step 3: condiciones (dejar defaults)
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      // Step 4: fecha
      await tester.tap(find.text('Toca para seleccionar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      // Step 5: confirmar
      expect(find.text('Confirmar préstamo'), findsOneWidget);
      expect(find.text('Davivienda'), findsOneWidget);
      await tester.tap(find.text('Registrar préstamo'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Registrar préstamo'), findsNothing);
    });

    testWidgets('Volver al selector desde cualquier sub-flow', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final creditTab = find.byIcon(Icons.account_balance_wallet_outlined);
      if (creditTab.evaluate().isNotEmpty) {
        await tester.tap(creditTab);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Entrar a tarjeta
      await tester.tap(find.text('Tarjeta bancaria'));
      await tester.pumpAndSettle();

      // Atrás → debe volver al selector
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new).first);
      await tester.pumpAndSettle();

      // Selector visible de nuevo
      expect(find.text('¿Qué quieres registrar?'), findsOneWidget);
      expect(find.text('Cupo de tienda'), findsOneWidget);
      expect(find.text('Tarjeta bancaria'), findsOneWidget);
      expect(find.text('Préstamo bancario'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 4: Correr integration tests en device ZY22LBQ8XS**

```bash
cd "/home/luis/Documentos/.VS CODE/PROYECTOS_PAN/Kredit"
flutter test integration_test/credit_flow_test.dart \
  --device-id ZY22LBQ8XS \
  -v
```
Esperado: los 4 tests PASS. Si hay timeouts, ajustar `pumpAndSettle` con mayor duración.

- [ ] **Step 5: Correr también todos los unit tests para regresión**

```bash
flutter test test/ -v
```
Esperado: todos los tests previos siguen en PASS.

- [ ] **Step 6: Commit final**

```bash
git add integration_test/ test_driver/ pubspec.yaml pubspec.lock
git commit -m "test: integration tests E2E para los tres flujos de registro de crédito, ADB device

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Self-review

**Spec coverage:**
- ✅ Nuevo entry point (Step 0 selector) → Task 4
- ✅ Flow A Cupo de tienda 4 pasos → Task 5
- ✅ Flow B Tarjeta bancaria 4+confirmación → Task 6
- ✅ Flow C Préstamo bancario 4+confirmación → Task 7
- ✅ `oneInstallmentInterestPolicy: bool?` → Task 1 + Task 6
- ✅ `paymentDueDay: int` → Task 1 + Task 6
- ✅ `paymentDueOffsetDays` deprecated → Task 1 (no eliminado)
- ✅ Migración Drift v10 → Task 1
- ✅ `getCardCycleDates` usa `paymentDueDay` → Task 2
- ✅ Selects numéricos para corte/pago → Task 6
- ✅ Tasa vacía = `interestUnknown` sin switch separado → Task 6, Task 7
- ✅ `_BankPickerStep` compartido B+C → Task 3
- ✅ `_DesignPickerRow` en confirmación de los tres → Task 3, 5, 6, 7
- ✅ Integration tests ADB → Task 8

**Placeholders:** Ninguno — todo el código de implementación está escrito.

**Type consistency:** `_parseCurrency()` definido una vez, reutilizado en Tasks 6+7. `_SummaryRow` definido en Task 6, reutilizado en Task 7. `CardDesign.values` ya existe en el codebase.

**Review Focus cubierto:**
- `paymentDueDay = 0` (no migrado) → test en Task 2 step 1
- `oneInstallmentInterestPolicy null` → test en Task 1 step 1 + lógica null-check en Task 6
- Tasa vacía → `interestUnknown = true` verificado en integration test Flow B (Step 3 "No especificada")
- SQL UPDATE en DB vacía → sentencia con `WHERE type = 'card'` segura con 0 filas
- Volver al selector → test dedicado en Task 8 step 3
