# Cupo comercial — diseño (2026-09-27)

## Contexto y motivación

El usuario tuvo una conversación con ChatGPT (guardada en `UltimoChatConGPT.md`) sobre cómo funcionan
productos de crédito comercial colombianos: Totto (Keypago), Lili Pink/Yoi (CrediPink), Éxito
(Tarjeta Tuya / CrediCompras). Todos comparten un patrón: el usuario tiene un **cupo** con una
**marca** (nunca con el proveedor financiero real detrás — Keypago, Tuya, Credifactory quedan
invisibles), y dentro de ese cupo hace **compras independientes**, cada una a sus propias cuotas.

Investigación confirmó (ver conversación previa, con fuentes):
- Totto/Keypago, Lili Pink/Yoi y Éxito (Tuya/CrediCompras): cada compra se difiere por separado,
  con su propio número de cuotas; el cupo se libera a medida que se paga.
- Lili Pink (CrediPink) tiene beneficio de pronto-pago (paga antes de la fecha de pago → no cobra
  interés, el abono va a capital). **No confirmado** en Totto/Keypago ni en Éxito — no se puede
  generalizar como comportamiento automático.

Principio rector, palabras del usuario: Kredit debe seguir siendo simple para el usuario promedio
que solo quiere gestionar sus créditos, sin obligarlo a conocer jerga financiera (tasa efectiva,
E.A., etc.) ni a saber qué entidad procesa realmente su crédito.

Este documento cubre exclusivamente la funcionalidad de **cupo comercial**. No reabre ni modifica
el trabajo ya implementado de "Una entidad, un registro" (aviso de duplicado + chip de nombre en
`WalletCard`), que sigue vigente tal cual.

## Decisión de alcance (confirmada con el usuario)

- Los bancos/tarjetas ya existentes (`LoanCredit`/`CardCredit` tal como están hoy) **no se tocan**.
- "Cupo comercial" se modela como una **capa agrupadora ligera** sobre `LoanCredit` ya existente —
  no es un tipo de `Credit` nuevo. Cada compra dentro de un cupo sigue siendo un `LoanCredit`
  normal (reutiliza `loan_calculator.dart`, `Installments`, `creditRemainingBalance`,
  `creditHasUnpaid` tal cual).
- El usuario nunca ve ni configura la entidad financiera real (Keypago, Tuya, Credifactory); solo
  ve la **marca** (Totto, Lili Pink, Éxito, o el nombre que el usuario quiera darle).
- Tasa de interés es opcional por compra: si el usuario no la conoce, no se calcula interés, solo
  se hace seguimiento de cuotas pagadas/pendientes según el valor de cuota que el usuario ingrese.
- El beneficio de pronto-pago (no cobra interés si pagas antes de la fecha de pago) es un flag
  opcional por compra, nunca un comportamiento asumido por defecto.

## Modelo de datos

### Tabla nueva: `CommercialQuotas`

```dart
@DataClassName('CommercialQuotaRow')
class CommercialQuotas extends Table {
  TextColumn get id => text()();
  TextColumn get brand => text()();       // "Totto", "Lili Pink", "Éxito"...
  RealColumn get limit => real()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

### `Credits` (tabla existente) — 3 columnas nuevas, todas nullable/default seguro

```dart
TextColumn get quotaId =>
    text().nullable().references(CommercialQuotas, #id, onDelete: KeyAction.restrict)();
BoolColumn get interestUnknown =>
    boolean().withDefault(const Constant(false))();
BoolColumn get earlyPaymentWaivesInterest =>
    boolean().withDefault(const Constant(false))();
```

`onDelete: KeyAction.restrict` (no `cascade`): borrar un cupo con compras activas debe fallar
explícitamente, nunca perder un `LoanCredit` real por accidente.

Filas existentes: `quotaId` queda `null` (crédito bancario normal, sin cambios de comportamiento),
`interestUnknown`/`earlyPaymentWaivesInterest` quedan `false` — comportamiento actual intacto.

### `LoanCredit` (modelo domain) — 3 campos nuevos

```dart
String? quotaId;
bool interestUnknown;
bool earlyPaymentWaivesInterest;
```

Con defaults `null`/`false`/`false` en constructor y en `fromJson` (JSON viejo sin estos campos
sigue parseando igual que hoy — sin backfill necesario).

### Modelo nuevo: `CommercialQuota`

```dart
class CommercialQuota {
  final String id;
  String brand;
  double limit;
  String? notes;
}
```

Sin lógica financiera propia — es un contenedor de datos.

## Lógica de dominio

### `lib/domain/commercial_quota_calculator.dart` (nuevo)

```dart
double quotaAvailable(CommercialQuota quota, List<LoanCredit> allLoans) {
  final purchases = allLoans.where((l) => l.quotaId == quota.id);
  final usedByUnpaid = purchases
      .where(creditHasUnpaid)
      .fold(0.0, (sum, p) => sum + creditRemainingBalance(p));
  return quota.limit - usedByUnpaid;
}
```

Reutiliza `creditHasUnpaid`/`creditRemainingBalance` de `credit_calculator.dart` sin duplicar
lógica de saldo pendiente. No oculta ni redondea un resultado negativo — la UI decide cómo
advertir, el cálculo siempre es el número real.

### Providers

`commercialQuotasProvider` (Riverpod, junto a `creditsProvider`): CRUD estándar sobre
`CommercialQuotas`, mismo patrón que `creditsProvider` ya usa para `Credits`.

## UI

- **Pantalla Créditos**: los `LoanCredit` con `quotaId` no nulo se agrupan visualmente bajo una
  tarjeta de cupo — encabezado con la marca (`quota.brand`) y una barra de disponible/límite
  (`quotaAvailable(quota, loans)` / `quota.limit`). Las compras individuales aparecen como items
  dentro de esa tarjeta, no sueltas en la lista principal.
- **Wizard "Nuevo Crédito"**: nuevo paso condicional — solo aparece si existe al menos un
  `CommercialQuota` guardado, o si el usuario elige explícitamente "Es una compra de un cupo
  comercial". Ofrece: elegir un cupo existente, o "Crear cupo nuevo" (pide marca + límite en el
  momento, sin salir del flujo).
- **Detalle de compra**: si `interestUnknown == true`, se muestra una advertencia visible tipo
  "Cuenta sin intereses registrados" en vez de mostrar una tasa/E.A. calculada. Checkbox opcional
  "Si pago antes de la fecha de pago, no cobran interés" → setea `earlyPaymentWaivesInterest`.

## Manejo de errores / casos borde

1. **Compra que deja el cupo en negativo**: no se bloquea. Se muestra advertencia ámbar no
   bloqueante (mismo patrón visual que el aviso de entidad duplicada ya implementado) — el usuario
   puede tener condiciones que Kredit no conoce (aumento de cupo, fianza especial, etc.).
2. **Borrar un cupo con compras activas**: bloqueado por la FK `restrict` a nivel de base de
   datos; la UI debe interceptar el error y mostrar "Tiene N compras activas, ciérralas o muévelas
   primero" en vez de dejar pasar una excepción cruda al usuario.
3. **`interestUnknown` + el usuario llena una tasa > 0 después**: al guardar, si `interestRate > 0`
   se limpia `interestUnknown = false` automáticamente — nunca debe quedar la contradicción "no sé
   la tasa" + "tasa: 2.3%" visible a la vez.
4. **Migración**: columnas nuevas nullable/con default — Drift solo agrega columnas, no requiere
   backfill ni migración de datos existentes.

## Testing

- `commercial_quota_calculator_test.dart`: cupo sin compras (disponible = límite), con compras
  pagadas (no descuentan), con compras pendientes (descuentan su saldo real), y caso de disponible
  negativo (el cálculo lo permite, no lo clampa a 0).
- Test de integridad: borrar un `CommercialQuota` con compras activas falla; sin compras, funciona.
- Test de `LoanCredit.fromJson` sobre un JSON sin los 3 campos nuevos — debe parsear igual que hoy,
  sin excepciones ni pérdida de datos.
- Test de que guardar una compra con `interestRate > 0` limpia `interestUnknown` a `false`.
- Widget test del wizard: el paso de cupo comercial solo aparece cuando corresponde; el flujo
  "crear cupo nuevo" pide marca + límite y los persiste antes de continuar con la compra.

## Fuera de alcance (explícitamente, para esta iteración)

- No se modela el proveedor financiero real (Keypago, Tuya, Credifactory) como dato estructurado
  en ningún lado — ni siquiera como metadata oculta. Si en el futuro resulta útil, es una extensión
  separada, no parte de este spec.
- No se generaliza el beneficio de pronto-pago como comportamiento automático — sigue siendo un
  flag manual por compra.
- No se toca `bank_detector.dart`/`entity_templates.dart` ni el flujo de detección de duplicados de
  entidades bancarias — cupo comercial es independiente de eso.
