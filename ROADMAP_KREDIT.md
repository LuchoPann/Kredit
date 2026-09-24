# Roadmap de evolucion de Kredit

Este documento guarda el plan de ejecucion para convertir Kredit de una app de
registro financiero en una herramienta que guia decisiones: que pagar, cuando
pagar, donde abonar y como mejorar la salud de deuda.

## Vision del producto

Kredit debe sentirse como un asistente financiero personal para creditos,
tarjetas y cupos colombianos. La app no solo debe almacenar informacion: debe
ayudar a entender la situacion, priorizar pagos y simular mejores decisiones.

Principios:

- Claridad antes que cantidad de datos.
- Recomendaciones accionables, no solo graficos.
- Lenguaje financiero explicado en terminos simples.
- Foco en productos colombianos: tarjetas, prestamos, cupos, tasas E.A.,
  fechas de corte, fechas limite, cuotas de manejo y abonos a capital.
- Privacidad local y confianza en el manejo de datos.

## Estado consolidado para GPT (leer esto primero, ahorra tener que revisar el proyecto)

Esta seccion es el canal de comunicacion directo entre Cloud y GPT sobre este
proyecto: resume TODO lo necesario para entender donde esta Kredit hoy sin
tener que abrir el codigo. Cloud la actualiza cada vez que cierra trabajo
nuevo. Si GPT menciona un punto (UX, layout, logica, copy, objetivo) que no
aparece aqui abajo explicitamente, es porque Cloud no lo ha cubierto — decirlo
asi de claro en vez de asumir que ya esta resuelto.

**Objetivo del producto (por que existe cada decision):** Kredit no es un
libro de contabilidad, es un asistente que le dice al usuario que hacer con
su dinero. Toda decision de UI/logica se juzga contra una pregunta: "¿esto
ayuda a decidir, o solo muestra un dato mas?". Si la respuesta es "solo
muestra un dato", se recorta o se convierte en una conclusion accionable.

**Como se dirige la experiencia de usuario (UX):**

- Tono de copy: espanol coloquial colombiano, informal ("tu abonarias", "tu
  cuota baja de..."), nunca "usted", nunca jerga tecnica en pantalla (el
  usuario ve "cuotas ya pagadas", nunca "installments paid: true"). Los
  numeros siempre en pesos con separador de miles (`$1.234.567`), nunca
  notacion cientifica ni decimales sueltos.
- Cada pantalla lidera con LA conclusion, no con el dato crudo: el dashboard
  muestra "DEUDA TOTAL" como cifra protagonista antes que cualquier lista;
  el simulador muestra "Tu cuota baja de $X a $Y" antes que la tabla de
  numeros; las estadisticas llevan una frase en espanol plano debajo de
  cada grafico ("Tu mes mas cargado es..."), nunca dejan que el usuario
  interprete un grafico solo.
- Ningun flujo bloquea al usuario con advertencias que el mismo no pidio:
  las alertas (tasa rara, cupo insuficiente, cuota que no cubre interes)
  son informativas por defecto y solo bloquean cuando la accion es
  matematicamente imposible de deshacer (ej. una cuota que nunca amortiza).
- Los datos de prueba NUNCA se mezclan con los datos reales del usuario —
  Cloud crea y borra creditos de prueba explicitamente marcados
  (`PRUEBA_BORRAR_*`) cuando necesita verificar algo en el dispositivo.

**Distribucion de layout / UI (convenciones visuales que TODA pantalla
nueva debe seguir):**

- Cero `boxShadow` en toda la app — regla dura, sin excepcion. Separacion
  visual entre superficies se logra con `border` tenue
  (`kredit.borderCard.withValues(alpha: ~0.5-0.78)`), nunca con sombra. Si
  un agente agrega una sombra en algun widget nuevo, es un bug de
  consistencia, no un estilo alternativo valido.
- Sistema de tokens obligatorio, definido en `lib/theme/app_theme.dart` —
  nunca hardcodear numeros de espaciado/tamano:
  - `KreditRadius`: `card` = 16 (tarjetas/sheets de nivel superior), `tile`
    = 12 (filas/tiles anidados), `chip` = 8 (badges/pills).
  - `KreditSpacing`: `card` = 16 (padding interno de tarjeta), `tile` = 12
    (padding de filas compactas), `section` = 20 (separacion vertical entre
    secciones de una pantalla).
  - `KreditTextSize`: `caption` = 12 (labels en mayuscula, hints, metadata),
    `body` = 14 (texto normal, valores de formulario), `heading` = 18
    (titulos de seccion a nivel pantalla).
  - `KreditIconSize`: `small` = 18 (la inmensa mayoria de iconos), `large`
    = 48 (icono unico de un estado vacio/error a pantalla completa).
  - `KreditColors` (theme extension): `textPrimary`/`textSecondary`/
    `textTertiary` para jerarquia tipografica, `borderCard` para bordes,
    `success`/`warning`/`danger` para semantica de estado — nunca un color
    hex suelto en un widget de pantalla.
- Patron de "tarjeta con header + subtitulo + contenido": casi toda seccion
  nueva se construye con `KreditSectionCard` (icono + titulo + subtitulo
  opcional) envolviendo el contenido — ver `_statsSectionHeader` en
  `stats_screen.dart` como ejemplo canonico.
- Patron de "insight en texto plano bajo un grafico o lista": un widget
  chico (`_InsightLine` en `stats_screen.dart`) que muestra una frase
  calculada en espanol, o se oculta por completo (`SizedBox.shrink()`) si
  no hay nada que decir — nunca un placeholder vacio ni "N/A".
- Patron de "fila de alerta/riesgo": icono de advertencia ambar + titulo en
  negrita + descripcion en `textSecondary` (`_RiskRow` en
  `stats_screen.dart`), reutilizado para toda alerta no bloqueante en el
  proyecto (ver tambien `_EditInterestRateWarningHint` en
  `edit_credit_sheet.dart`).
- Navegacion principal: `BottomNavigationBar` de 4 pestanas (Inicio /
  Creditos / Estadisticas / Cuenta) en `lib/main.dart`, con TODAS las
  pantallas montadas simultaneamente en un `Stack` (nunca destruidas al
  cambiar de pestana — preserva scroll/estado) y una transicion de
  desvanecimiento cruzado entre la activa y la anterior. Ver la nota de
  bug fix en la Fase de navegacion mas abajo si se toca este archivo.

**Logica de dominio (donde vive el "cerebro" de la app, para no
duplicarlo):**

- TODA la logica financiera vive en `lib/domain/*.dart`, sin ninguna
  dependencia de Flutter — se puede testear sin levantar widgets. Archivos
  clave: `loan_calculator.dart` (amortizacion francesa, abonos, mora),
  `card_calculator.dart` (interes de tarjetas, ciclos de corte),
  `interest_rate.dart` (normalizacion de tasas E.A./E.M./nominal a diaria),
  `recommendations.dart` (motor de recomendaciones, dos capas: un pago a
  la vez vs. comparar el conjunto de creditos).
  `credit_calculator.dart` (saldo restante, type-dispatch loan/card).
- Regla de oro: si una funcion nueva de dominio puede reusar una ya
  existente (`applyLoanAbono`, `dailyRateFrom`, `getCreditRemainingBalance`,
  `urgencyScore`) en vez de reimplementar la formula, SIEMPRE reusarla —
  ver `simulateAbonoScenarios` (clona el credito y llama a `applyLoanAbono`
  real en vez de escribir una segunda formula de amortizacion) y
  `effectiveAnnualRate` (reusa `dailyRateFrom`) como los dos ejemplos mas
  recientes de este patron.
- Toda funcion de dominio nueva debe tener tests en `test/domain/`
  ANTES de darse por terminada — no hay excepcion documentada en este
  proyecto para logica financiera sin tests.

**Estado de las 9 fases (ver detalle completo de cada una mas abajo en este
mismo archivo, bajo su encabezado `## Fase N`):**

| Fase | Estado | Quien |
|---|---|---|
| 1. Base de datos y modelos | Hecho | Pre-roadmap |
| 2. Dashboard inteligente | Hecho | GPT + Cloud (fix de bug) |
| 3. Lista de creditos | Hecho | GPT + Cloud (fix de estilo) |
| 4. Crear credito | Hecho | GPT + Cloud (feature nueva: cuotas ya avanzadas) |
| 5. Detalle del credito | Hecho | Cloud |
| 6. Simulador fuerte | **Completo** | Cloud |
| 7. Estadisticas explicativas | Hecho | Cloud |
| 8. Cuenta/seguridad/respaldo | Hecho | Pre-roadmap + Cloud (fecha de respaldo) |
| 9. Motor de recomendaciones | Hecho | GPT + Cloud |

**Bug critico resuelto (por si GPT lo ve mencionado en otro lado y no sabe
si sigue vigente — YA NO):** navegacion entre pestanas se congelaba (no se
podia volver de Creditos/Estadisticas a Inicio). Causa: en `_TabFadeLayer`
(`lib/main.dart`), `TickerMode` envolvia a `AnimatedOpacity` en vez de al
reves, apagando el ticker de la animacion de fade de la pestana saliente.
Corregido invirtiendo el anidado. Commit `60c36ec`.

**Lo unico que queda pendiente en todo el proyecto (2026-09-23):**

- [ ] Mora acumulada con severidad basada en HISTORIAL real de dias en mora
  (hoy usa solo el estado actual, sin persistir historial — funciona pero
  es una aproximacion, no un registro real dia a dia). Requeriria una
  migracion Drift nueva. Sin urgencia.
- [ ] Alerta de cupo menor al saldo al CREAR una tarjeta (hoy solo existe
  al EDITAR una tarjeta existente, en `edit_credit_sheet.dart`) — es
  logicamente imposible que pase al crear (no hay saldo previo), asi que
  esto solo aplicaria si en el futuro se permite crear una tarjeta con
  saldo inicial mayor al limite, que hoy el formulario no permite.

Todo lo demas del roadmap original esta implementado y verificado en
dispositivo fisico.

## Brief operativo para Cloud

Esta seccion es para que Cloud pueda continuar el desarrollo sin perder la
direccion del producto. La prioridad no es agregar muchas pantallas, sino hacer
que Kredit se sienta como un asistente financiero colombiano: claro, confiable,
accionable y visualmente liviano.

### Estado actual del proyecto

Ya se implemento una primera base importante:

- Dashboard/Inicio:
  - `lib/domain/recommendations.dart` contiene la capa de dominio para pagos
    pendientes, resumen semanal y recomendacion principal.
  - `lib/screens/dashboard/dashboard_screen.dart` consume esa capa para mostrar
    deuda total, compromiso principal, siguientes pagos y creditos activos.
  - "Siguiente compromiso" y "Proximos pagos" estan fusionados en una sola
    tarjeta para reducir carga visual.
- Lista de creditos:
  - `lib/providers/credits_filter_provider.dart` tiene filtros rapidos y
    ordenamientos.
  - `lib/screens/credits/credits_list_screen.dart` permite buscar, ordenar,
    filtrar por estado/tipo y ver cada credito como tarjeta.
  - El progreso de cada credito aparece como una bandeja visual anidada bajo la
    tarjeta, no como dato flotante.
- Crear credito:
  - `lib/screens/credits/add_credit_sheet.dart` mantiene un flujo guiado de 3
    pasos.
  - Existen plantillas/sugerencias por entidad y advertencias contextuales de
    tasa.
  - Se redujeron textos permanentes para que el formulario se sienta menos
    pesado.
- Navegacion:
  - `lib/main.dart` mantiene las vistas principales montadas y usa transicion
    cruzada suave entre pestanas para evitar saltos visuales.
- Pruebas:
  - `test/domain/recommendations_test.dart` valida la logica de recomendaciones.
  - Antes de entregar cualquier cambio, ejecutar `flutter analyze` y
    `flutter test`.

### Reglas de trabajo para Cloud

- No rehacer pantallas desde cero si se puede evolucionar lo existente.
- Mantener el estilo sobrio y funcional: menos bloques, menos texto permanente,
  mas jerarquia visual.
- Usar los tokens existentes de `lib/theme/app_theme.dart`:
  `KreditSpacing`, `KreditRadius`, `KreditTextSize`, `KreditIconSize` y
  `KreditColors`.
- Mantener la logica financiera fuera de la UI cuando sea posible. Si una regla
  puede testearse, debe vivir en `lib/domain/`.
- Agregar o actualizar tests cuando se toque calculo financiero,
  recomendaciones, filtros, ordenamientos, importacion/exportacion o pagos.
- Evitar tarjetas dentro de tarjetas salvo cuando exista una relacion visual
  clara, como la bandeja de progreso anidada bajo una tarjeta de credito.
- No agregar dependencias nuevas sin justificar por que el framework actual no
  alcanza.
- No eliminar funcionalidad ya implementada sin explicar el motivo en este
  roadmap.
- Si una tarea queda a medias, marcarla aqui con `[ ]` y anotar exactamente que
  falta.

### Como debe actualizar este roadmap

Cada cambio debe dejar rastro:

- Cambiar `[ ]` a `[x]` solo cuando este implementado y validado.
- Debajo del item, agregar archivo(s) tocados, breve descripcion de como se
  hizo, pruebas ejecutadas y riesgos o pendientes.
- Si se decide retirar una idea, no borrarla: marcarla como reemplazada y
  explicar por que.

Formato sugerido:

```md
- [x] Nombre de la tarea.
  - Implementado en `ruta/archivo.dart`.
  - Como se hizo: ...
  - Validacion: `flutter analyze`, `flutter test`.
  - Pendiente/riesgo: ...
```

### Prioridad recomendada para Cloud

Trabajar en este orden:

1. Detalle del credito.
2. Simulador fuerte.
3. Estadisticas explicativas.
4. Cuenta, seguridad y respaldo.
5. Motor avanzado de recomendaciones.

La razon: Inicio, Creditos y Crear Credito ya tienen una base de experiencia.
El mayor salto de valor ahora esta en que cada credito explique mejor que esta
pasando y que accion conviene tomar.

### Tarea 1 para Cloud: Detalle del credito

- [x] 2026-09-23: completada. Ya estaba resuelta en su mayoria de rondas
  anteriores (antes de este roadmap); esta sesion confirmo lo existente por
  revision de codigo/dispositivo y cerro los 2 vacios reales que quedaban.

Objetivo: convertir la pantalla de detalle en el lugar donde el usuario entiende
el estado real de un credito y decide que hacer.

Nota: los archivos reales NO tienen una carpeta `tabs/` (ese path no existe en
el proyecto) - la estructura real es:

- `lib/screens/credit_detail/credit_detail_screen.dart`
- `lib/widgets/credit_detail/summary_tab.dart`
- `lib/widgets/credit_detail/schedule_tab.dart` (cronograma de cuotas)
- `lib/widgets/credit_detail/movements_tab.dart`
- `lib/domain/credit_calculator.dart`, `loan_calculator.dart`, `card_calculator.dart`

Requisitos:

- Para prestamos/cupos:
  - [x] mostrar saldo pendiente como dato principal (WalletCard "DEUDA
    RESTANTE" + `summary_tab.dart`).
  - [x] mostrar proxima cuota, fecha y estado (`_NextInstallmentCard`).
  - [x] mostrar progreso de cuotas con una pieza visual clara
    (`_LoanProgress`, barra + "$X pagado de $Y").
  - [x] destacar si hay cuotas vencidas (`schedule_tab.dart` agrupa
    VENCIDAS/PROXIMAS/FUTURAS/PAGADAS, con mora estimada visible).
  - [x] mantener acciones principales visibles: registrar pago (boton
    "Pagar"), abonar (Abono Extra / Pago total en Cronograma), simular
    (nuevo boton "Simular abono extra" en `_NextInstallmentCard`, abre
    `simulator_sheet.dart` con `initialCreditId` preseleccionado).
- Para tarjetas:
  - [x] mostrar saldo actual, cupo disponible, uso de cupo y fecha limite
    (`_CardUtilization`, `_CardCycleInfo`).
  - [x] destacar uso alto de cupo (acento de color cuando `pct >= 0.8`).
  - [x] mostrar corte y proximo pago en lenguaje simple.
  - [x] mantener acciones principales visibles: registrar movimiento/pago
    (`_CardQuickActions`). Simular impacto para tarjetas queda pendiente
    (el simulador de "Simular compra" ya existe para tarjetas mas general,
    pero no hay boton directo desde el detalle de tarjeta - ver pendiente
    abajo).
- [x] Evitar saturar: una tarjeta principal arriba, acciones claras,
  informacion secundaria en secciones compactas - ya cumplido.
- [x] Historial de abonos con impacto (redujo cuota / redujo plazo / ahorro
  de intereses estimado): `computeLastAbonoImpact` en `loan_calculator.dart`
  compara el ultimo abono contra su snapshot previo
  (`previousQuotaAmount`/`previousInstallmentsSnapshot`) y se muestra en
  `_AbonoTile` del Cronograma, solo para el abono mas reciente (los
  anteriores no tienen un "antes/ahora" confiable una vez el credito volvio
  a cambiar).

Pendiente/riesgo:

- [ ] Boton directo de "simular impacto" desde el detalle de TARJETA (hoy
  solo existe para prestamos). Bajo impacto: el simulador general sigue
  siendo accesible desde Estadisticas.
- [ ] `credit_detail_screen.dart` en si (el contenedor de tabs/badge) no se
  toco en esta ronda - solo sus tabs. Revisar si el badge de tipo y el
  AppBar necesitan algo mas al continuar con Fase 6/7.

Validacion: `flutter analyze` sin issues, `flutter test` 105/105 (4 tests
nuevos para `computeLastAbonoImpact`).

### Tarea 2 para Cloud: Simulador fuerte

Objetivo: que el simulador deje de ser accesorio y se vuelva una herramienta de
decision.

Archivos probables:

- `lib/screens/stats/simulator_sheet.dart`
- `lib/domain/loan_calculator.dart`
- `lib/domain/credit_calculator.dart`
- tests en `test/domain/`.

Requisitos:

- Comparar tres escenarios:
  - seguir igual;
  - abonar reduciendo cuota;
  - abonar reduciendo plazo.
- Mostrar resultado en lenguaje humano:
  - "Terminas X meses antes";
  - "Ahorras aproximadamente $X";
  - "Tu cuota baja de $X a $Y".
- Incluir botones rapidos de monto:
  - $50.000;
  - $100.000;
  - $200.000;
  - valor personalizado.
- Evitar graficos pesados si no ayudan a decidir.

Criterios de aceptacion:

- La comparacion debe ser clara aun sin leer todos los numeros.
- Las formulas deben estar testeadas.
- `flutter analyze` y `flutter test` deben pasar.

- [x] 2026-09-23: parcialmente completada por Cloud. Se agrego
  `_ScenarioComparisonTable` en `simulator_sheet.dart`: cada vez que el
  usuario simula un abono, el resultado se guarda en una lista de sesion
  (tope 5, no persistida) y se muestra una tabla comparando monto abonado
  vs. cuotas adelantadas/meses para saldar vs. interes ahorrado — permite
  comparar "¿que pasa si abono 100k vs 300k?" sin tener que recordar el
  resultado anterior. Pendiente real: los "tres escenarios" que pide la
  tarea (seguir igual / reducir cuota / reducir plazo) y los botones
  rapidos de monto ($50k/$100k/$200k) no se implementaron — la comparacion
  actual es entre montos que el usuario ya eligio simular, no una
  comparacion automatica de las 3 estrategias.

### Tarea 3 para Cloud: Estadisticas explicativas

Objetivo: que Estadisticas responda preguntas, no que solo muestre graficos.

Archivos probables:

- `lib/screens/stats/stats_screen.dart`
- `lib/domain/recommendations.dart`
- nuevo modulo de dominio si hace falta, por ejemplo
  `lib/domain/financial_insights.dart`.

Requisitos:

- Agregar conclusiones textuales debajo o encima de cada bloque.
- Responder preguntas como:
  - a quien le debo mas;
  - que pago se viene;
  - que deuda pesa mas;
  - donde conviene abonar primero.
- Reutilizar `PendingPayment`, `FinancialRecommendation` y futuras reglas de
  recomendacion cuando sea posible.
- Mantener visuales livianos: si un grafico no ayuda a decidir, reducirlo o
  reemplazarlo por insight.

Criterios de aceptacion:

- Cada seccion debe dejar una conclusion accionable.
- La pantalla no debe sentirse mas cargada que Inicio.
- `flutter analyze` y `flutter test` deben pasar.

- [x] 2026-09-23: parcialmente completada por Cloud. Se agrego una linea de
  insight en espanol (`_InsightLine`, `stats_screen.dart`) debajo de "Deuda
  proyectada por mes" (mes mas cargado y su % del total proyectado) y debajo
  de "Distribucion por entidad" (% concentrado en el acreedor principal).
  Tambien se agrego una seccion nueva "RIESGOS DETECTADOS" que muestra los
  resultados de `buildRiskRecommendations()` (ver Tarea 5) cuando aplican.

- [x] 2026-09-23 (2): se cerro el pendiente de "donde conviene abonar
  primero" — nueva `buildBestPrepaymentRecommendation()` en
  `recommendations.dart` compara la tasa efectiva anual normalizada
  (`effectiveAnnualRate()`, reutiliza `dailyRateFrom()` de
  interest_rate.dart) entre los prestamos activos y recomienda abonar
  primero el de tasa mas alta. Se muestra como insight bajo "Proyeccion de
  fin de pago" en stats_screen.dart. 5 tests nuevos.

### Tarea 4 para Cloud: Cuenta, seguridad y respaldo

Objetivo: aumentar confianza en el manejo de datos.

Archivos probables:

- `lib/screens/account/account_screen.dart`
- servicios de exportacion/importacion existentes.

Requisitos:

- Reorganizar Cuenta por grupos:
  - perfil;
  - apariencia;
  - seguridad;
  - notificaciones;
  - respaldo;
  - privacidad.
- Mejorar lenguaje de respaldo:
  - "Guardar copia de seguridad";
  - "Restaurar copia";
  - "Tus datos permanecen en este dispositivo".
- Mostrar, si existe la informacion, ultimo respaldo o ultima accion de
  exportacion.
- Explicar privacidad del widget Android sin usar textos largos.

Criterios de aceptacion:

- La pantalla se entiende sin leer parrafos largos.
- El usuario entiende donde estan sus datos.
- `flutter analyze` y `flutter test` deben pasar.

- [x] 2026-09-23: revisado por Cloud — esta tarea ya estaba casi completa
  desde antes del roadmap (no era trabajo pendiente real): `account_screen.dart`
  ya esta agrupado por Personalizacion / Notificaciones / Seguridad / Datos /
  Ayuda / Zona de riesgo; `SecuritySettingsTile` ya tiene bloqueo biometrico/PIN
  (`SetupLockScreen`) y el toggle de privacidad del widget; `DataToolsCard` ya
  exporta/importa un respaldo JSON completo via `share_plus` + file picker.
  Pendiente real: no se muestra fecha del ultimo respaldo hecho (requeriria
  persistir un timestamp en `SharedPreferences` tras cada export exitoso) —
  cambio pequeno, no urgente.

- [x] 2026-09-23 (2): cerrado el pendiente. Nuevo
  `lib/providers/last_backup_provider.dart` (`SharedPreferences`, mismo
  patron que `notification_settings_provider.dart`) persiste la fecha del
  ultimo export exitoso; `DataToolsCard` la muestra ("Ultimo respaldo: ...")
  y se actualiza justo despues de `Share.shareXFiles` en `_exportData`.

### Tarea 5 para Cloud: Motor avanzado de recomendaciones

Objetivo: fortalecer `lib/domain/recommendations.dart` para que alimente
dashboard, detalle y estadisticas.

Reglas pendientes:

- [x] Tarjeta con uso alto. — `buildRiskRecommendations()`, umbral 85% del cupo.
- [x] Deuda mas costosa. — `buildRiskRecommendations()`, compara
  `effectiveAnnualRate()` entre creditos activos; alerta si el mas caro
  supera 1.5x el promedio de los demas y su tasa es >=30% E.A.
- [x] Credito ideal para abonar. — `buildBestPrepaymentRecommendation()`,
  mismo mecanismo de tasa efectiva anual, aplicado solo a prestamos activos.
- [ ] Riesgo por mora acumulada. (requiere historial de dias en mora, no solo
  estado actual — no implementado)
- [ ] Alerta de cupo menor al saldo al crear/editar tarjeta.

Requisitos:

- Las recomendaciones deben ser objetos explicables:
  - titulo;
  - descripcion;
  - severidad;
  - credito relacionado;
  - accion sugerida si aplica.
- No mezclar reglas de UI con reglas financieras.
- Agregar tests de cada regla.

Criterios de aceptacion:

- Las reglas pueden probarse sin renderizar widgets.
- Las recomendaciones se pueden reutilizar en varias pantallas.
- `flutter analyze` y `flutter test` deben pasar.

- [x] 2026-09-23: parcialmente completada por Cloud. Se agrego
  `buildRiskRecommendations()` en `lib/domain/recommendations.dart`: detecta (1)
  concentracion de deuda cuando un solo acreedor representa >=60% de la deuda
  pendiente, y (2) tarjetas con >=85% de su cupo usado. Se reutiliza desde
  `stats_screen.dart` (seccion "RIESGOS DETECTADOS"). 4 tests nuevos en
  `test/domain/recommendations_test.dart`. Pendiente: comparar por tasa de
  interes real (no solo monto) para "deuda mas costosa", "credito ideal para
  abonar" y "riesgo por mora acumulada" (necesita historial de dias en mora,
  no solo el estado actual).

### Que debe evitar Cloud por ahora

- No crear una landing page ni pantallas de marketing.
- No redisenar toda la identidad visual.
- No agregar sincronizacion en nube todavia.
- No agregar autenticacion remota.
- No mover datos a backend.
- No reemplazar Riverpod ni la estructura actual.
- No cambiar formulas financieras sin pruebas.
- No aumentar la densidad visual de Inicio ni Creditos.

### Prompt sugerido para pedirle trabajo a Cloud

Puedes copiar este bloque y darselo a Cloud cuando quieras que implemente una
tarea:

```text
Estas trabajando en Kredit, una app Flutter para gestionar creditos, tarjetas y
cupos colombianos. Antes de codificar, lee `ROADMAP_KREDIT.md` completo y sigue
la seccion "Brief operativo para Cloud".

Objetivo de esta tarea:
[PON AQUI LA TAREA EXACTA, por ejemplo: "Implementar Tarea 1 para Cloud:
Detalle del credito".]

Reglas:
- No rehagas pantallas desde cero si puedes evolucionar lo existente.
- Usa los tokens de `lib/theme/app_theme.dart`.
- Mantén la logica financiera en `lib/domain/` cuando sea testeable.
- Actualiza `ROADMAP_KREDIT.md` marcando lo que completes y explicando como lo
  hiciste.
- Ejecuta `flutter analyze` y `flutter test` antes de terminar.
- Si no puedes completar algo, dejalo anotado como pendiente en el roadmap.

Entrega esperada:
- Cambios implementados.
- Roadmap actualizado.
- Resumen corto de archivos modificados.
- Resultado de `flutter analyze` y `flutter test`.
```

### Prompt sugerido para que Cloud trabaje el detalle del credito

```text
Lee `ROADMAP_KREDIT.md` completo. Implementa la "Tarea 1 para Cloud: Detalle del
credito".

Quiero que mejores la pantalla de detalle sin redisenar toda la app:
- Para prestamos/cupos, que el usuario vea saldo pendiente, proxima cuota,
  fecha, progreso de cuotas, cuotas vencidas si existen y acciones principales.
- Para tarjetas, que vea saldo actual, cupo disponible, uso de cupo, fecha de
  corte, fecha limite y acciones principales.
- Mantén una jerarquia simple: una tarjeta principal arriba, acciones claras y
  secciones secundarias compactas.
- Si agregas reglas de estado o recomendaciones, ponlas en `lib/domain/` y
  cubrelas con tests.
- Usa el lenguaje visual actual de Kredit y los tokens de `app_theme.dart`.
- Actualiza `ROADMAP_KREDIT.md` explicando que hiciste.
- Ejecuta `flutter analyze` y `flutter test`.
```

### Prompt sugerido para que Cloud trabaje el simulador

```text
Lee `ROADMAP_KREDIT.md` completo. Implementa la "Tarea 2 para Cloud: Simulador
fuerte".

Quiero que el simulador compare claramente:
- seguir igual;
- abonar reduciendo cuota;
- abonar reduciendo plazo.

Debe explicar los resultados en lenguaje humano:
- "Terminas X meses antes";
- "Ahorras aproximadamente $X";
- "Tu cuota baja de $X a $Y".

Agrega botones rapidos de monto: $50.000, $100.000, $200.000 y valor
personalizado. Evita graficos pesados si no ayudan a decidir.

Si tocas formulas financieras, agrega tests en `test/domain/`. Actualiza
`ROADMAP_KREDIT.md` y ejecuta `flutter analyze` y `flutter test`.
```

### Prompt sugerido para que Cloud trabaje estadisticas

```text
Lee `ROADMAP_KREDIT.md` completo. Implementa la "Tarea 3 para Cloud:
Estadisticas explicativas".

Quiero que Estadisticas responda preguntas concretas:
- a quien le debo mas;
- que pago se viene;
- que deuda pesa mas;
- donde conviene abonar primero.

Agrega conclusiones accionables, reutiliza `lib/domain/recommendations.dart`
cuando aplique y evita que la pantalla se vea mas cargada que Inicio.

Actualiza `ROADMAP_KREDIT.md` con lo realizado y ejecuta `flutter analyze` y
`flutter test`.
```

### Como debe revisar Codex despues

Cuando Cloud termine una tarea, pedir revision a Codex con este enfoque:

- Revisar bugs, regresiones y riesgos antes que estilo.
- Confirmar que no se rompio la jerarquia visual ni se agrego carga excesiva.
- Validar que las reglas financieras nuevas esten testeadas.
- Revisar que `ROADMAP_KREDIT.md` haya quedado actualizado con lo real, no con
  promesas.
- Ejecutar o verificar `flutter analyze` y `flutter test`.

## Nota de UX: simplificacion visual

- [x] 2026-09-23: se redujo la carga visual de las pantallas principales para
  que cada vista tenga una intencion dominante.
  - Inicio conserva el resumen, la recomendacion principal y los proximos
    pagos; se retiraron bloques secundarios que repetian informacion o acciones.
  - 2026-09-23: "Siguiente compromiso" y "Proximos pagos" se fusionaron en
    una sola tarjeta: el compromiso urgente lidera y los siguientes pagos
    quedan debajo como lista compacta. "Tus creditos" permanece separado.
  - Creditos conserva busqueda, orden, filtros rapidos, pestanas y lista; se
    retiro el encabezado comparador y el filtro por entidad visible para evitar
    doble filtrado en la primera vista.
  - 2026-09-23: el progreso de cada credito en la lista se convirtio en una
    bandeja visual anidada debajo de la tarjeta, para que se sienta parte del
    mismo objeto y no un dato flotante.
  - 2026-09-23: el cambio entre vistas principales usa una transicion cruzada
    suave, manteniendo cada pantalla montada para conservar scroll, filtros y
    estado local.
  - Crear credito conserva el flujo guiado de 3 pasos, pero elimina tarjetas de
    ayuda permanentes y textos repetidos; las advertencias quedan solo cuando
    aportan contexto directo.

## Fase 1: Claridad del producto

Objetivo: hacer que la app sea mas facil de entender desde la primera pantalla.

Cambios propuestos:

1. Revisar el lenguaje general de la app.
2. Separar con claridad tarjetas, prestamos y cupos.
3. Ajustar textos de botones, mensajes vacios, ayudas y alertas.
4. Definir estados comunes: al dia, por vencer, vencido, pagado, alto uso de
   cupo.
5. Consolidar criterios visuales para urgencia, exito, advertencia y accion
   principal.

Criterio de exito:

El usuario entiende que debe hacer sin necesitar interpretar todos los datos
financieros manualmente.

## Fase 2: Dashboard inteligente

Objetivo: convertir Inicio en el centro de decision diaria.

Cambios propuestos:

- [x] Fortalecer la tarjeta "Prioridad de hoy".
  - Implementado con `FinancialRecommendation` en
    `lib/domain/recommendations.dart` y presentado en
    `lib/screens/dashboard/dashboard_screen.dart`.
  - La tarjeta ahora consume una recomendacion de dominio en vez de calcular
    todo directamente en la UI.
- [x] Agregar resumen semanal:
  - [x] total por pagar en los proximos 7 dias;
  - [x] pagos vencidos;
  - [x] pagos de hoy;
  - [x] siguiente pago.
  - Implementado con `PaymentWeekSummary`; luego se integro en la tarjeta de
    recomendacion principal para reducir bloques compitiendo en Inicio.
- [x] Agregar acciones rapidas:
  - [x] nuevo credito;
  - [x] simular;
  - [x] ir a creditos;
  - [x] ir a estadisticas.
  - Implementado inicialmente con `_QuickActionsPanel` y retirado en la pasada
    de simplificacion visual. Las acciones contextuales se mantendran en el FAB,
    la navegacion principal y los detalles de credito.
- [x] Mostrar una frase de salud financiera:
  - [x] "Todo esta al dia";
  - [x] "Tienes pagos por resolver";
  - [x] "Tienes pagos para hoy";
  - [x] "Tienes compromisos en los proximos 7 dias".
  - Implementado con `buildFinancialHealthLine`.

Criterio de exito:

Al abrir Kredit, el usuario sabe cual es la accion mas importante del dia.

## Fase 3: Lista de creditos mas util

Objetivo: transformar la lista de creditos en una herramienta de comparacion.

Cambios propuestos:

- [x] Agregar filtros:
  - [x] todos;
  - [x] vencidos;
  - [x] proximos;
  - [x] tarjetas;
  - [x] prestamos/cupos;
  - [x] pagados.
  - Implementado con `CreditsQuickFilter` en
    `lib/providers/credits_filter_provider.dart`. Los pagados se mantienen en
    la pestana "Finalizados" para no mezclar estado historico con urgencia o
    tipo.
- [x] Agregar ordenamiento:
  - [x] por urgencia;
  - [x] por deuda mayor;
  - [x] por fecha proxima;
  - [x] por entidad.
  - Implementado con `CreditsSortOption.urgency` y
    `CreditsSortOption.entity`.
- [x] Redisenar la pantalla para comparar mejor:
  - [x] monto pendiente total;
  - [x] creditos activos;
  - [x] vencidos;
  - [x] proximos 7 dias;
  - [x] tarjetas vs prestamos.
  - Implementado inicialmente con `_CreditsComparisonHeader` y retirado en la
    pasada de simplificacion visual para que la lista empiece directo con
    busqueda, filtros y tarjetas. La comparacion global queda como candidata
    para Estadisticas o una vista dedicada.
- [x] Redisenar cada tarjeta para mostrar con mas claridad:
  - [x] monto pendiente;
  - [x] fecha proxima;
  - [x] estado general mediante filtros y orden;
  - [x] progreso de prestamo o uso de cupo mas explicito dentro de cada
    tarjeta.
  - Implementado con `_CreditComparisonStrip`: tarjetas muestran uso de cupo
    y prestamos muestran cuotas pagadas/progreso porcentual.
- [ ] Evaluar agrupacion opcional por entidad financiera.

Criterio de exito:

La pantalla permite comparar rapidamente que credito requiere atencion y por
que.

## Fase 4: Crear credito como asistente guiado

Objetivo: reducir la friccion al registrar un credito nuevo.

Flujo propuesto:

- [x] Elegir tipo de credito:
  - [x] tarjeta de credito;
  - [x] prestamo/cupo de cuotas.
  - Implementado con tarjetas explicativas en `_CreditTypePicker`.
- [x] Elegir entidad financiera.
- [x] Registrar monto, cupo o saldo.
- [x] Registrar fechas importantes.
- [x] Registrar tasa e intereses.
- [x] Revisar y confirmar.
  - El flujo sigue dividido en 3 pasos; la pasada de simplificacion retiro
    `_StepGuideCard` para que el usuario llegue antes a los campos.

Mejoras:

- [x] Microayudas para fecha de corte, fecha limite y tasa E.A.
  - Se conservaron ayudas contextuales solo cuando hay una advertencia o
    sugerencia concreta, como tasa sospechosa o plantilla de entidad.
- [ ] Microayudas para reducir cuota y reducir plazo.
  - Pendiente para el flujo de abonos/simulador, donde esos conceptos se usan
    directamente.
- [x] Deteccion de posibles errores:
  - [x] tasa sospechosa;
  - [x] cuota insuficiente;
  - [x] fecha faltante;
  - [ ] cupo menor al saldo.
- [x] Logos y plantillas por entidad mas visibles.
  - El selector de entidad mantiene presets y plantillas automaticas de corte
    y fecha limite.

Criterio de exito:

Registrar un credito se siente guiado, no como llenar un formulario financiero
largo.

## Fase 5: Detalle del credito

Objetivo: hacer que cada credito tenga una pantalla poderosa, clara y accionable.

### Prestamos y cupos

Cambios propuestos:

1. Resumen superior:
   - saldo pendiente;
   - progreso;
   - proxima cuota;
   - fecha estimada de finalizacion.
2. Acciones principales:
   - registrar pago;
   - hacer abono;
   - simular abono.
3. Linea de tiempo de cuotas.
4. Historial de abonos con impacto:
   - redujo cuota;
   - redujo plazo;
   - ahorro intereses estimados.

### Tarjetas

Cambios propuestos:

1. Resumen de ciclo:
   - saldo;
   - cupo disponible;
   - fecha de corte;
   - fecha limite.
2. Uso de cupo visual.
3. Movimientos agrupados por ciclo.
4. Alertas:
   - cupo usado alto;
   - saldo cerca de vencerse;
   - cuota de manejo activa.

Criterio de exito:

El detalle responde que esta pasando con ese credito y que accion conviene
hacer.

## Fase 6: Simulador como funcion estrella

Objetivo: convertir el simulador en el diferencial principal de Kredit.

Cambios propuestos:

1. Hacerlo accesible desde:
   - dashboard;
   - detalle del credito;
   - estadisticas.
2. Comparar escenarios:
   - seguir igual;
   - abonar reduciendo cuota;
   - abonar reduciendo plazo.
3. Mostrar resultados en lenguaje claro:
   - "Terminas 4 meses antes";
   - "Ahorras aproximadamente $X";
   - "Tu cuota baja de $X a $Y".
4. Agregar botones rapidos:
   - $50.000;
   - $100.000;
   - $200.000;
   - valor personalizado.

Criterio de exito:

El usuario puede tomar una decision antes de pagar, no solo registrar lo que ya
hizo.

### Implementacion real (Cloud, 2026-09-23)

Estado: **parcial, avanzado**. Archivo principal:
`lib/screens/stats/simulator_sheet.dart` (~1050 lineas). No se reconstruyo
desde cero — ya existia un simulador funcional (compra + abono extra) de
sesiones previas; esta ronda lo llevo mas cerca del criterio de exito.

**Estructura del archivo (para orientarse rapido):**

- `openSimulatorSheet(context, {initialCreditId})` — funcion de entrada, abre
  un `showModalBottomSheet` con `SimulatorSheet`.
- `SimulatorSheet` — `ConsumerStatefulWidget` con `TabController` de 2
  pestanas: "Simular compra" (index 0, solo tarjetas) y "Abonar extra"
  (index 1, tarjetas y prestamos). Si `initialCreditId` apunta a un
  `LoanCredit`, abre directo en index 1 (las tarjetas no aplican para
  "Simular compra" en un prestamo).
- `_PurchaseTab` / `_PurchaseTabState` — simulador de compra a cuotas sobre
  una tarjeta: monto + cuotas -> cuota mensual, costo total con interes,
  nueva utilizacion del cupo.
- `_ExtraPaymentTab` / `_ExtraPaymentTabState` — el simulador de abono
  extra, el que mas se toco esta sesion. Aqui vive `_scenarios`
  (`List<_PaymentResult>`), la lista comparativa.
- `_PaymentResult` — clase inmutable con el resultado de una simulacion
  (monto abonado, cuotas adelantadas o meses para saldar, interes ahorrado,
  nuevo saldo). Tiene `toJson()`/`fromJson()` propios (ver persistencia
  abajo).
- `_QuickAmountRow` — chips `$50.000` / `$100.000` / `$200.000` que
  autocompletan el campo de monto (`ActionChip`, `Wrap` con `spacing: 8`).
- `_ScenarioComparisonTable` — la tabla comparativa: una fila por escenario,
  la mas reciente resaltada con `accent.withValues(alpha: 0.08)` de fondo.
  Cada fila muestra: monto abonado (columna izquierda, negrita en la fila
  activa), cuotas adelantadas o "N mes(es) para saldar" (columna central),
  interes ahorrado o saldo restante (columna derecha, color `kredit.success`).

**Como se ve:** dentro del bottom sheet, debajo del boton "Simular abono" y
del resultado del ultimo calculo, aparece un titulo pequeno "Comparar
escenarios de esta sesion" y una tarjeta con borde tenue (mismo lenguaje
visual que el resto de la app — sin `boxShadow`) que contiene la lista de
filas descrita arriba, separadas por un divisor tenue horizontal.

**Persistencia de escenarios (lo que resuelve "guardar simulaciones"):**
cada escenario simulado se guarda en `SharedPreferences` bajo la clave
`sim_scenarios_<creditId>` como una lista JSON (`jsonEncode`/`jsonDecode`).
Al abrir el simulador con un credito preseleccionado, o al cambiar el
credito en el dropdown, `_loadScenarios(credit)` lee esa clave y repuebla
`_scenarios` — asi los escenarios sobreviven a cerrar el simulador o la app
entera, sin necesitar una tabla nueva en la base de datos Drift (es una
previsualizacion, no un abono real, asi que vivir fuera de la base de datos
de creditos es la decision correcta). Tope de 5 escenarios por credito
(`_maxScenarios`), mas antiguo se descarta.

- [x] 2026-09-23 (2): cerrado el resto del criterio de exito.

**Comparacion automatica de los 3 escenarios fijos** — lo mas importante de
esta ronda. Nueva funcion `simulateAbonoScenarios(LoanCredit loan, double
amount)` en `lib/domain/loan_calculator.dart` (dominio puro, sin Flutter,
testeable sin widgets). Decision de diseno clave: en vez de escribir una
SEGUNDA formula matematica "de mentiras" solo para previsualizar, esta
funcion CLONA el credito completo con `LoanCredit.fromJson(loan.toJson())`
(round-trip, deep copy real) y le aplica `applyLoanAbono()` — la misma
funcion que ya usa un abono REAL — sobre el clon, una vez por cada
`AbonoStrategy` (`reducirCuota`, `reducirPlazo`). El original nunca se toca.
Esto garantiza que la simulacion SIEMPRE coincide exactamente con lo que
pasaria si el usuario abonara de verdad — no hay dos formulas que mantener
sincronizadas a mano.

Devuelve `List<AbonoScenarioResult>` (3 elementos: index 0 es el baseline
"seguir igual" con `strategy: null`, luego uno por cada `AbonoStrategy`).
Cada resultado trae: `quota`, `remainingInstallments`, `payoffDate`,
`totalInterestRemaining`, y — comparado contra el baseline —
`installmentsSaved` / `interestSaved`.

**Como se ve:** en `lib/screens/stats/simulator_sheet.dart`, cada vez que el
usuario toca "Simular abono" (para un prestamo — las tarjetas no tienen
"estrategia" de abono, solo reducen saldo), aparece una tarjeta nueva
"Compara tus 3 opciones" (`_ThreeScenariosCard`) ENTRE el resultado del
abono y la tabla de comparacion por monto que ya existia. Es una tarjeta
con 3 filas (`_ScenarioTile`), cada una con un icono (circulo tenue para
"Seguir igual", flecha hacia abajo verde `kredit.success` para las otras
dos) + titulo en negrita + descripcion en lenguaje humano exacto al que
pide el roadmap:
- "Seguir igual": "Sin abonar, terminas en 7 Mar, 2027 — $450.000 en
  interes restante por pagar."
- "Reducir cuota": "Tu cuota baja de $370.433 a $310.200 — sigues pagando 6
  cuota(s), pero cada una mas liviana. Ahorras aprox. $85.000 en intereses."
- "Reducir plazo": "Terminas 2 cuota(s) antes (7 Ene, 2027 en vez de 7 Mar,
  2027) — misma cuota de $370.433. Ahorras aprox. $92.000 en intereses."

**Acceso desde el dashboard:** `lib/screens/dashboard/dashboard_screen.dart`
ahora tiene una fila "¿Que pasa si...?" (icono `calculate_outlined`) debajo
de la tarjeta "Tus creditos", visible solo si hay creditos activos — mismo
patron visual (`ListTile` dentro de `KreditSectionCard`) que
`_SimulatorEntryRow` en `stats_screen.dart`. No se pudo importar esa clase
directamente porque es privada de ese archivo; se replico en vez de
exportarla, para no acoplar dos pantallas por un widget tan chico.

7 tests nuevos en `test/domain/loan_calculator_test.dart` (grupo
`simulateAbonoScenarios`): valida que no muta el original, que
`reducirPlazo` mantiene la cuota y reduce cuotas, que `reducirCuota`
mantiene el plazo y reduce la cuota, que ambas estrategias ahorran interes
vs. el baseline, y los casos borde (sin cuotas pendientes, monto <= 0).

Criterio de exito de la Fase 6: **completo**.

## Fase 7: Estadisticas que expliquen

Objetivo: que Estadisticas responda preguntas concretas y no solo muestre
graficos.

Secciones sugeridas:

1. A quien le debo mas?
2. Que pago se viene?
3. Cuando termino?
4. Que deuda pesa mas?
5. Donde conviene abonar?

Mejoras:

- Agregar conclusiones debajo de graficos.
- Reducir visuales que no aporten decision.
- Agregar comparacion mensual:
  - deuda anterior vs deuda actual;
  - pagos realizados;
  - abonos extra.

Criterio de exito:

Cada bloque de Estadisticas debe dejar una conclusion clara.

## Fase 8: Cuenta, seguridad y respaldo

Objetivo: aumentar confianza, control y claridad sobre los datos.

Cambios propuestos:

1. Reorganizar Cuenta por grupos:
   - perfil;
   - apariencia;
   - seguridad;
   - notificaciones;
   - respaldo;
   - privacidad.
2. Mostrar ultimo respaldo.
3. Mejorar lenguaje:
   - "Guardar copia de seguridad";
   - "Restaurar copia".
4. Explicar que los datos son locales.
5. Aclarar la privacidad del widget de Android.

Criterio de exito:

El usuario siente que sus datos estan bajo control.

## Fase 9: Motor de recomendaciones

Objetivo: crear una capa reusable de inteligencia financiera para alimentar
dashboard, detalle y estadisticas.

Reglas iniciales:

- [x] Pago mas urgente.
  - Implementado inicialmente con `buildPendingPayments` y
    `buildPrimaryRecommendation`.
- [x] Deuda mas costosa. — `buildRiskRecommendations()`, ver detalle abajo.
- [x] Tarjeta con uso alto. — `buildRiskRecommendations()`, umbral 85% del cupo.
- [x] Credito ideal para abonar. — `buildBestPrepaymentRecommendation()`.
- [x] Pagos proximos.
  - Implementado como lista de `PendingPayment`, reusable fuera del dashboard.
- [x] Riesgo por mora o vencimiento.
  - Implementado por severidad `danger`/`warning` segun dias de vencimiento
    (`buildPrimaryRecommendation`) + regla de mora acumulada agregada esta
    sesion (ver detalle abajo).

Implementacion sugerida:

- Crear un modulo de dominio para recomendaciones.
- Mantener reglas testeables y explicables.
- Exponer recomendaciones como objetos con:
  - titulo;
  - descripcion;
  - severidad;
  - credito relacionado;
  - accion sugerida.

Criterio de exito:

Kredit empieza a actuar como asistente financiero, no solo como registro de
deudas.

### Implementacion real (Cloud, 2026-09-23)

Estado: **avanzado**. Archivo: `lib/domain/recommendations.dart` (~280
lineas, cero dependencias de Flutter — es dominio puro, se puede testear sin
levantar widgets). Estructura de dos capas que conviene entender antes de
tocarlo:

**Capa 1 — "un pago a la vez" (ya existia antes de esta sesion):**

- `PendingPayment` — envuelve un `Credit` con su proxima fecha de pago y
  monto. `daysUntilDue()` y `urgency()` (reusa `urgencyScore()` de
  `urgency_score.dart`) son metodos, no campos, para que siempre reflejen
  el `now` que se les pase (facilita testear con fechas fijas).
- `buildPendingPayments(credits, {now})` — recorre todos los creditos y arma
  la lista de `PendingPayment`, ordenada por urgencia descendente. Para
  `LoanCredit` toma la primera cuota `!paid`; para `CardCredit` con saldo,
  usa `getCardCycleDates(c).dueDate`.
- `buildPaymentWeekSummary(payments, {now})` — cuenta vencidos, vencen-hoy,
  vencen-en-7-dias y el total a pagar en la semana. Alimenta el resumen del
  dashboard.
- `buildPrimaryRecommendation(credits, {now})` — la UNA recomendacion mas
  importante ahora mismo (vencido > vence-hoy > vence-en-3-dias > proximo >
  todo-al-dia). Es lo que ve el usuario como "Siguiente compromiso" en el
  dashboard.

**Capa 2 — "comparar el conjunto completo" (`buildRiskRecommendations`,
nueva esta sesion):** a diferencia de la Capa 1, que mira un pago a la vez,
esta funcion compara TODOS los creditos activos entre si para encontrar
riesgos que solo se ven al verlos juntos. Devuelve `List<FinancialRecommendation>`
(puede haber 0, 1 o varias a la vez — no es "la unica" como
`buildPrimaryRecommendation`). Cuatro reglas, en este orden dentro de la
funcion:

1. **Deuda concentrada** — si un solo acreedor representa >=60% de la deuda
   pendiente total (comparando `getCreditRemainingBalance()` de cada
   credito). Severidad `warning`.
2. **Cupo casi agotado** — cualquier `CardCredit` con `currentBalance /
   creditLimit >= 0.85`. Severidad `warning`.
3. **Deuda mas costosa** — compara `effectiveAnnualRate()` (ver abajo) entre
   todos los creditos con saldo pendiente; si el mas caro tiene una tasa
   >=1.5x el promedio de los demas Y esa tasa es >=30% E.A., alerta.
   Severidad `warning`. Esto es lo que responde "a quien le debo mas caro",
   no solo "a quien le debo mas" (eso ya lo cubria "Deuda concentrada").
4. **Mora acumulada** (agregada en esta ronda) — NO requiere una tabla nueva
   en la base de datos ni guardar historial: se calcula sobre los pagos
   vencidos que ya existen ahora mismo, via `buildPendingPayments(now:
   now).where((p) => p.daysUntilDue(now) < 0)`. Dispara cuando el problema
   ya es sistemico: 2+ creditos vencidos simultaneamente, o uno solo
   vencido por 30+ dias. Severidad `danger` (la unica de las 4 reglas que
   usa `danger` — las otras son advertencias, esta es una senal de alarma
   real). Un solo pago vencido reciente NO dispara esta regla — eso ya lo
   cubre `buildPrimaryRecommendation` de la Capa 1, y repetirlo aqui seria
   ruido.

**`effectiveAnnualRate(Credit credit)`** — normaliza la tasa de CUALQUIER
credito (loan o card, cualquier periodicidad: E.A./E.M./nominal mensual) a
una tasa efectiva anual comparable. Reutiliza `dailyRateFrom()` de
`interest_rate.dart` (que ya existia para el calculo de intereses de
tarjetas) y la anualiza: `(1 + dailyRate)^365 - 1`. Esta funcion es LA
PIEZA CLAVE que permite comparar "cuesta mas" entre un prestamo al 24% E.A.
y una tarjeta al 2.5% mensual sin convertir manualmente — todo se reduce a
la misma unidad antes de comparar.

**`buildBestPrepaymentRecommendation(credits)`** — entre los `LoanCredit`
con cuotas pendientes (2 o mas; con uno solo no hay "primero" que elegir),
recomienda abonar primero al de mayor `effectiveAnnualRate()`. Devuelve
`null` si no hay suficientes prestamos activos para comparar. Severidad
`info` (es una sugerencia, no una alerta).

**Donde se consume (para que GPT sepa donde buscar el efecto visual):**
`lib/screens/stats/stats_screen.dart` — seccion nueva "RIESGOS DETECTADOS"
(solo aparece si `buildRiskRecommendations()` devuelve algo, cada item como
`_RiskRow`: icono de advertencia ambar + titulo en negrita + descripcion) y
una linea de insight bajo "Proyeccion de fin de pago" que usa
`buildBestPrepaymentRecommendation()?.description` directamente (widget
`_InsightLine`, texto tenue, se oculta solo si es null).

Que falta para el criterio de exito completo:

- [ ] "Riesgo por mora acumulada" en su version completa (con severidad
  progresiva segun dias exactos en mora) requeriria guardar un historial de
  dias-en-mora por credito, no solo mirar el estado actual — eso si es un
  cambio de modelo de datos (migracion Drift), y se descarto por ahora a
  proposito para no tocar la base de datos sin necesidad real.

## Orden recomendado de implementacion

1. Dashboard inteligente.
2. Lista de creditos mejorada.
3. Crear credito guiado.
4. Detalle del credito.
5. Simulador fuerte.
6. Estadisticas explicativas.
7. Cuenta, seguridad y respaldo.
8. Motor avanzado de recomendaciones.

## Primera iteracion sugerida

La primera tarea grande deberia ser:

- [x] Crear un modelo de recomendacion financiera.
  - `FinancialRecommendation`, `PendingPayment`,
    `RecommendationSeverity` y `PaymentWeekSummary`.
- [x] Mejorar dashboard con:
  - [x] prioridad;
  - [x] resumen semanal;
  - [x] acciones rapidas;
  - [x] estado general.
- [x] Ajustar visualmente la jerarquia del Inicio.
  - La pantalla mantiene la deuda total como dato principal, luego muestra
    prioridad, semana y acciones.
- [x] Agregar pruebas para la logica de recomendacion.
  - `test/domain/recommendations_test.dart`.

Esta iteracion crea una base para que las demas pantallas reutilicen la misma
logica de decision.
