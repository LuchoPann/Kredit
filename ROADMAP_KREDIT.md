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

## Como funciona Kredit hoy (guia funcional completa, pantalla por pantalla)

**Regla de mantenimiento de esta seccion (para Cloud, en toda sesion
futura):** esta seccion describe el comportamiento REAL y ACTUAL de la app,
no el historico de cambios (eso vive en las secciones fechadas mas abajo).
Cada vez que un cambio de codigo altere lo que una pantalla hace, que
campos pide, que valida o que guarda, ESTA seccion se actualiza en el mismo
commit/sesion — no se deja para despues. Si un cambio es puramente visual
(colores, espaciado, animaciones) sin alterar comportamiento/flujo, no hace
falta tocar esta seccion, solo la bitacora fechada. La idea es que alguien
sin acceso al codigo (GPT, o Cloud en una sesion nueva) pueda leer
UNICAMENTE esta seccion y entender exactamente que hace la app hoy, sin
tener que abrir un solo archivo.

Kredit es 100% local — no hay backend, no hay red, todo vive en SQLite
(Drift) en el dispositivo. La navegacion principal es una barra inferior de
4 pestanas (Inicio / Creditos / Estadisticas / Cuenta) que mantiene las 4
pantallas montadas a la vez (nunca se destruyen al cambiar de pestana) con
un fade cruzado entre la activa y la anterior.

### Modelo de datos: que es un "credito" en Kredit

Todo objeto financiero del usuario es un `Credit`, que en la practica es
uno de dos subtipos, discriminados por el campo `type` en una unica tabla
(`Credits`, columnas nullable segun el tipo):

- **`LoanCredit`** ("Prestamo / Cupo en cuotas"): monto financiado, numero
  de cuotas, tasa de interes (y su tipo: E.A./E.M./nominal mensual), fecha
  de la primera cuota, frecuencia (mensual/quincenal/semanal), y la lista
  de cuotas (`installments`) generadas por amortizacion francesa. Tiene un
  flag interno `scheduleManuallyAdjusted`: una vez que un abono extra
  reamortiza el cronograma, este flag se prende y el cronograma YA NUNCA se
  vuelve a recalcular desde cero automaticamente (evita perder el ajuste
  manual).
- **`CardCredit`** ("Tarjeta de credito"): limite, saldo actual, tasa de
  interes, dia de corte, dias entre corte y fecha limite de pago, cuota de
  manejo (y su frecuencia), y una lista de `movements` (cargos/pagos/
  intereses/cuotas de manejo acumulados por ciclo).

Ambos comparten: nombre (el que el usuario le puso, visible ahora en la
tarjeta visual como chip de alto contraste), banco/entidad (texto libre,
sin tabla de entidades — ver seccion "Una entidad, un registro" mas abajo
para el trabajo en curso sobre esto), color, notas.

### Pantalla 1 — Bienvenida (solo primera vez)

Se muestra una unica vez (controlado por `onboardingProvider`). Explica que
la app viene con 2 creditos de ejemplo marcados "EJEMPLO" (editables o
borrables como cualquier otro). Ofrece, sin obligar: activar PIN/biometria
(lleva a la pantalla de configurar bloqueo) y activar notificaciones de
vencimiento (recomendado, default apagado — al activarlo se despliega ahi
mismo la configuracion completa de dias de anticipacion/hora/frecuencia).
Boton "Empezar" marca el onboarding como visto y entra a la app.

### Pantalla 2 — Inicio (Dashboard)

Responde "¿que tengo que pagar pronto?". De arriba a abajo:
- Saludo segun la hora + "DEUDA TOTAL" como cifra protagonista, con un
  anillo de progreso (% del total de cuotas de prestamos ya pagadas — las
  tarjetas no cuentan para este %, son saldo rotativo, no amortizacion).
- Dos cifras secundarias: cuanto vence en los proximos 7 dias, y cuantos
  creditos activos hay.
- "Prioridad de hoy": el pago mas urgente (calculado por el motor de
  recomendaciones), con boton "Ver detalle", boton "Marcar como pagada"
  (solo si es una cuota de prestamo) y, debajo, hasta 3 pagos siguientes
  ("Despues") con un boton para ver todos los pendientes en un sheet.
- "Tus creditos": lista compacta de tarjetas visuales, tap abre el
  detalle.
- "¿Que pasa si...?": fila que abre el simulador.
- Boton flotante (+) para registrar un credito nuevo.

### Pantalla 3 — Creditos (lista completa)

Buscador + boton de orden (urgencia, proximo pago, mayor/menor deuda,
entidad, nombre) + chips de filtro rapido (Todos/Vencidos/Proximos/
Tarjetas/Prestamos) + tabs Activos/Finalizados. Cada fila es la tarjeta
visual completa (`WalletCard`) con una franja debajo mostrando uso de cupo
(tarjetas) o progreso pagado (prestamos). Tap abre el detalle. Boton
flotante (+) para registrar un credito nuevo. Vacio muestra un aviso de
privacidad ("tus datos permanecen en tu dispositivo").

Las compras que pertenecen a un **cupo comercial** (Totto, Lili Pink,
Exito CrediCompras...) no aparecen sueltas en esta lista — se agrupan bajo
una tarjeta separada que muestra la marca (nunca la entidad financiera
real detras) y una barra de disponible/limite, con cada compra como fila
tocable debajo (abre su detalle igual que cualquier otro credito). Un
cupo sin compras todavia se muestra igual (con 0), y tiene su propio
boton eliminar (con confirmacion; falla con mensaje claro si aun tiene
compras activas). Ver seccion "Cupo comercial — 2026-09-27" mas abajo.

### Pantalla 4 — Registrar Nuevo Credito (asistente de 4 pasos)

- **Paso 1 — Tipo de credito:** elegir Prestamo/Cupo o Tarjeta de credito
  (cada uno con su propio icono en avatar circular), nombre del
  credito/tarjeta, banco/entidad (lista desplegable + opcion "Otro..." con
  texto libre; si el banco tiene sub-marcas conocidas como CMR Falabella
  aparece un segundo desplegable). Avisos automaticos, no bloqueantes: si
  se elige Nequi o DaviPlata como Tarjeta, sugiere cambiar a Prestamo (esos
  productos no son tarjeta rotativa); y si ya existe un credito ACTIVO del
  mismo tipo con el mismo banco detectado, avisa "Ya tienes [un cupo/una
  tarjeta] activo con esta entidad: [nombre]" con boton para abrir ese en
  vez de crear otro — nunca bloquea seguir (hay casos reales de tener dos
  productos legitimos del mismo banco, o usar el credito de otra persona).
  Para prestamo, un toggle opcional "Es una compra de un cupo comercial"
  (Totto, Lili Pink, Exito CrediCompras...) justo debajo del tipo elegido:
  al activarlo, el campo Banco/Prestamista (y sus avisos de banco/
  duplicado) desaparecen por completo — la marca del cupo ES la entidad,
  nunca hay un banco aparte. Permite elegir un cupo ya creado o "Crear
  cupo nuevo" (pide marca + limite ahi mismo, sin salir del asistente).
- **Paso 2 — Monto y cuotas (prestamo) / Cupo de la tarjeta (tarjeta):**
  panel grande en vivo mostrando la cuota calculada (amortizacion
  francesa) o el cupo disponible segun se va escribiendo; campos: monto a
  financiar, numero de cuotas, interes anual y su tipo de expresion (E.A./
  E.M./nominal mensual) para prestamo; limite y saldo actual para tarjeta.
  Para prestamo, un toggle "No conozco la tasa" reemplaza el campo de
  interes por el aviso "Cuenta sin intereses registrados" — Kredit nunca
  obliga a conocer ni sintetiza una tasa que el usuario no dio. Si la
  compra pertenece a un cupo comercial, aparece ademas "Si pago antes de
  la fecha de pago, no cobran interes" (siempre manual, nunca asumido).
- **Paso 3 — Fecha de pago (prestamo) / Interes y costos (tarjeta):**
  frecuencia de cuotas + fecha de la primera cuota, y un campo siempre
  visible (no oculto tras un desplegable) "¿Ya venias pagando este
  credito?" para marcar cuantas cuotas ya estaban pagadas ANTES de
  registrarlo (asi el cronograma arranca en la cuota correcta, no desde
  cero). Para tarjeta: interes, cuota de manejo, dia de corte y dias hasta
  la fecha limite de pago (autocompletados por una plantilla por banco si
  el usuario no los toca a mano).
- **Paso 4 — Confirmacion:** vista previa de la tarjeta visual tal como
  quedaria, mas una tabla de 2 columnas con todos los datos ingresados.
  Boton "Registrar Credito" guarda todo.

Salir del asistente con datos sin guardar pide confirmar el descarte.

### Pantalla 5 — Detalle de un Credito

AppBar con nombre + badge de tipo. Dos tabs segun el tipo:

- **Prestamo → Resumen + Cronograma.** Resumen: tarjeta visual, monto/
  tasa (o "Cuenta sin intereses registrados" si la compra se registro sin
  tasa conocida — nunca un "0.0%" enganoso), progreso de amortizacion,
  proxima cuota con boton "Pagar" (permite
  ingresar un monto distinto al esperado — la diferencia se aplica como
  abono o cargo a la siguiente cuota) y acceso directo al simulador de
  abono. Cronograma: cuotas agrupadas en Vencidas → Proximas → Futuras →
  Pagadas (colapsable), seccion de Abonos Registrados (colapsable, muestra
  el impacto real del ultimo abono: cuanto bajo la cuota o cuantas cuotas
  se adelantaron, e interes ahorrado), y botones "Abono Extra" / "Pago
  total" (se resaltan en rojo si hay mora). Eliminar una cuota pagada o un
  abono pide confirmacion y recalcula el saldo.
- **Tarjeta → Resumen + Movimientos.** Resumen: cupo disponible
  destacado, fechas de corte/limite del ciclo actual, botones rapidos
  Cargo/Compra y Registrar Pago. Movimientos: historial agrupado por mes
  (cargo/pago/interes/cuota de manejo), cada uno se puede eliminar
  (recalcula el saldo) con `Dismissible` (deslizar).

Notas del credito visibles al final. Bottom bar: Editar Credito / Eliminar
(con confirmacion doble, mencionando el nombre exacto del credito).

### Pantalla 6 — Editar Credito

Sheet arrastrable con vista previa en vivo de la tarjeta. No se puede
cambiar el tipo (prestamo ↔ tarjeta) desde aca — es un dato fijo desde la
creacion. Permite editar: comercio/ubicacion y notas (prestamo); monto y
cuota (con aviso BLOQUEANTE — pide confirmar explicitamente — si la nueva
cuota no alcanza a cubrir ni el interes del periodo, porque esa
configuracion nunca terminaria de pagarse); limite, interes, corte, fecha
limite y mantenimiento (tarjeta, con aviso no bloqueante si el nuevo limite
queda por debajo del saldo actual). Un cambio de tasa en tarjeta cierra los
intereses ya acumulados con la tasa vieja antes de aplicar la nueva.

### Pantalla 7 — Simulador ("¿Que pasa si...?")

Sheet con 2 tabs (cual se abre primero depende de si viniste desde un
prestamo o una tarjeta): "Simular compra" (solo tiene sentido en tarjetas —
monto + cuotas → cuota mensual resultante, nuevo saldo, cupo que quedaria
disponible, costo estimado en intereses, con alerta si el uso de cupo
supera 80%) y "Abonar extra" (disponible para ambos tipos — monto libre o
chips rapidos $50.000/$100.000/$200.000). Para prestamo calcula cuantas
cuotas se adelantan y cuanto interes se ahorra, y muestra 3 escenarios
comparativos lado a lado: seguir igual, reducir cuota, reducir plazo. Para
tarjeta calcula en cuantos meses quedaria saldada pagando el minimo.

Todo lo que se ve aca es una SIMULACION — no toca los datos reales del
credito, salvo que el usuario pulse explicitamente "Registrar este abono
ahora", que ahi si aplica el abono/pago real (mismos metodos que usar el
boton de pago desde el detalle). Los escenarios calculados se guardan en
`SharedPreferences` (hasta 5 por credito) para que la comparativa persista
entre sesiones. Aviso fijo en pantalla: "resultados aproximados, consulta
con tu entidad".

### Pantalla 8 — Estadisticas avanzadas

Panel superior: "DEUDA ACTIVA TOTAL" con anillo de progreso, un pill de
"N riesgos" si el motor de riesgos detecto algo, y 3 cifras (creditos
activos / cupo disponible / total pagado historico — antes eran 6, se
redujo por feedback de que sobraba informacion). Grupo "Proyecciones":
grafico de barras (deuda proyectada proximos 6 meses) + grafico de torta
(distribucion de deuda por entidad), cada uno con una frase en espanol
plano debajo explicando el dato ("Tu mes mas cargado es..."). Si hay
riesgos detectados, seccion "RIESGOS DETECTADOS" (deuda concentrada en una
entidad, cupo casi agotado, la deuda mas costosa por tasa, mora
acumulada). Grupo "Historial y Herramientas": resumen de abonos extra ya
realizados + proyeccion de cuando terminarias de pagar cada prestamo
activo. Ya NO tiene acceso al simulador (se quito de aca — vive solo en
Inicio).

### Pantalla 9 — Cuenta

Perfil (foto/nombre editables) + resumen rapido ("N creditos activos · $X
pendiente"). Personalizacion: color de acento (7 opciones), modo oscuro,
variante de tono (Oscuro Puro/Frio-Azul/Grafito). Notificaciones: mismo
bloque de 3 pasos que en la Bienvenida (dias de anticipacion, hora,
frecuencia unico/diario). Seguridad: activar/gestionar PIN o biometria, y
el switch "Mostrar montos en el widget" (default apagado — el widget de
pantalla de inicio de Android es visible SIN desbloquear el telefono, asi
que mostrar cifras reales ahi es opt-in explicito). Datos: exportar
respaldo (JSON plano sin cifrar, se comparte por donde el usuario elija con
`share_plus`, con aviso de que no esta cifrado; actualiza la fecha del
"ultimo respaldo") e importar respaldo (reemplaza TODOS los datos actuales,
pide confirmacion). Ayuda: guia rapida de la app. Zona de riesgo: borrar
toda la base de datos (doble confirmacion + reautenticacion con PIN/
biometria si hay bloqueo configurado).

### Bloqueo de la app (PIN/biometria)

Opcional, configurable desde Bienvenida o Cuenta. El PIN se guarda como
hash salado (nunca en texto plano) en almacenamiento seguro del sistema
operativo (`flutter_secure_storage`). Bloqueo progresivo tras varios
intentos fallidos. La biometria usa el sistema del propio telefono (huella/
rostro) con fallback a PIN/patron del SO si falla. La app se re-bloquea
automaticamente al volver de segundo plano.

### Widget de pantalla de inicio (Android)

Widget nativo opcional que el usuario agrega manualmente al home screen del
telefono (Kredit no lo agrega solo). Se actualiza cada vez que cambian los
creditos, el tema (acento/tono) o el switch de privacidad. Muestra: deuda
total, % pagado (con barra, oculto si no aplica), y la proxima cuota
(nombre + monto + fecha relativa) — o, si el switch "Mostrar montos" esta
apagado, solo texto generico sin cifras ("N creditos activos", "Tienes
pagos pendientes"). Tap en el widget abre la app. Aparece en el selector de
widgets de Android como "Resumen" (con una descripcion corta), no solo
como "Kredit". Se adapta al color de acento y al tono de fondo elegidos en
Cuenta.

### Como se conecta todo (motor de dominio → pantallas)

Toda la logica financiera vive en `lib/domain/*.dart`, sin ninguna
dependencia de Flutter (testeable sin UI). Los archivos clave y que
pantalla alimentan, en resumen: `loan_calculator.dart` (amortizacion
francesa, abonos, mora) alimenta Dashboard/Detalle/Simulador;
`card_calculator.dart` (ciclos de corte, acumulacion de intereses)
alimenta Detalle de tarjeta/Simulador; `interest_rate.dart` (normalizar
E.A./E.M./nominal a tasa diaria) alimenta el asistente de creacion y el
simulador; `recommendations.dart` (que pago priorizar, que riesgos existen
entre el conjunto de creditos, que credito conviene abonar primero)
alimenta Dashboard y Estadisticas; `credit_calculator.dart` (saldo
restante, si un credito tiene cuotas pendientes) se usa en casi todas las
pantallas.

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

## Revision GPT / Codex — 2026-09-24

Esta revision se hizo despues del trabajo fuerte de Cloud sobre las fases del
roadmap. Estado tecnico validado por GPT:

- `flutter analyze`: sin issues.
- `flutter test`: 128 tests pasando.
- El repositorio esta 30 commits por delante de `origin/master`.
- No hay cambios de codigo sin commit en archivos trackeados al momento de la
  revision.
- Archivos sueltos sin trackear:
  - `UltimoChatConClaude.txt`
  - `owasp_m1_secrets_scan.json`
  - `owasp_m5_network_scan.json`
  - `owasp_m9_storage_scan.json`

### Evaluacion general

El avance de Cloud va en buena direccion. La app ya no se siente como un
registro pasivo: Inicio, Creditos, Detalle, Simulador y Estadisticas empiezan a
empujar decisiones concretas. La separacion entre UI y dominio tambien mejoro:
`recommendations.dart`, `loan_calculator.dart` e `interest_rate.dart` concentran
la mayor parte del "cerebro" financiero y tienen tests.

La prioridad ahora NO debe ser agregar mas features grandes. La prioridad debe
ser cerrar inconsistencias, revisar exactitud financiera del simulador de
tarjetas y hacer una pasada real de QA visual/UX en dispositivo.

### Hallazgo prioritario para Cloud

- [ ] Corregir calculo de tasas de tarjeta dentro del simulador.
  - Problema detectado por GPT: `lib/screens/stats/simulator_sheet.dart` aun
    calcula intereses de tarjeta con `card.interestRate / 100 / 365` en:
    - `_PurchaseTabState._simulate()`
    - `_ExtraPaymentTabState._simulateCard()`
  - Esto asume que toda tasa de tarjeta es efectiva anual, pero Kredit ya
    soporta `InterestRateType.effectiveAnnual`,
    `InterestRateType.effectiveMonthly` y `InterestRateType.nominalMonthly`.
  - Instruccion: reemplazar esa conversion manual por
    `dailyRateFrom(card.interestRate, card.interestRateType)` desde
    `lib/domain/interest_rate.dart`.
  - Idealmente extraer la logica de simulacion de tarjetas a una funcion pura
    testeable en `lib/domain/` para no dejar calculo financiero importante
    dentro de un widget privado.
  - Agregar tests que cubran al menos:
    - tarjeta con tasa E.A.;
    - tarjeta con tasa efectiva mensual;
    - tarjeta con tasa nominal mensual;
    - tasa 0.
  - Validacion requerida: `flutter analyze` y `flutter test`.

### Limpieza necesaria del roadmap

- [ ] Consolidar el roadmap para que diga una sola verdad.
  - Ahora mismo hay secciones nuevas arriba que dicen "completo" y secciones
    historicas mas abajo que aun dicen "parcial" o mantienen `[ ]`.
  - Ejemplos:
    - Fase 6 aparece como completa en el estado consolidado, pero mas abajo
      conserva texto de "Estado: parcial, avanzado" antes de documentar el
      cierre.
    - Fase 9 dice que casi todo esta cerrado, pero conserva una lista antigua
      de pendientes que ya fue parcialmente resuelta.
    - "Boton directo de simular impacto desde detalle de tarjeta" aparece como
      pendiente en Tarea 1, pero no aparece en "Lo unico que queda pendiente".
  - Instruccion: NO borrar historial util, pero si reorganizarlo:
    - arriba: "Estado actual verdadero";
    - luego: "Pendientes reales";
    - luego: "Historial de implementacion";
    - marcar como "reemplazado/cerrado" lo viejo que ya no aplique.

### QA visual/UX requerido antes de seguir

- [ ] Hacer una pasada en dispositivo fisico o emulador por estas pantallas:
  - Inicio.
  - Creditos.
  - Detalle de prestamo.
  - Detalle de tarjeta.
  - Simulador.
  - Estadisticas.
  - Cuenta.
- Criterios de revision:
  - Que ninguna pantalla vuelva a sentirse cargada.
  - Que cada pantalla tenga una conclusion o accion dominante.
  - Que los textos largos no empujen controles importantes fuera de vista.
  - Que la transicion entre pestanas no bloquee taps ni deje pantallas
    superpuestas.
  - Que no haya `boxShadow` nuevo salvo que se decida cambiar explicitamente el
    lenguaje visual de toda la app.
  - Que los estados vacios, con datos, con deuda vencida y con tarjeta sin cupo
    definido se vean bien.

### Archivos sin trackear

- [ ] Decidir que hacer con los archivos sueltos.
  - `UltimoChatConClaude.txt`: si sirve como memoria historica, moverlo a
    `docs/` o resumirlo en este roadmap. Si no aporta, dejarlo fuera del commit.
  - `owasp_*.json`: si son reportes de seguridad utiles, moverlos a una carpeta
    clara como `reports/security/` o documentar que son artefactos locales. No
    mezclarlos con codigo de producto sin contexto.

### Como debe continuar Cloud

Orden recomendado:

1. Corregir el calculo de tasas de tarjeta en simulador y testearlo.
2. Limpiar contradicciones del roadmap.
3. Hacer QA visual/UX en dispositivo.
4. Solo despues de eso, proponer nuevas mejoras.

Importante: cualquier nueva mejora debe preservar la direccion actual de Kredit:
menos bloques, mas decision; menos datos crudos, mas conclusion accionable; mas
logica testeable en dominio y menos formulas dentro de widgets.

## Sesion Cloud — 2026-09-24/25 (noche): rediseno visual, animaciones,
## rename de paquete, widget de inicio, y Estadisticas

Bitacora completa de esta sesion, a pedido explicito del usuario ("todo debe
ir registrado alli, sin excepcion, usalo como bitacora e historial"). Incluye
tanto lo implementado como lo discutido/propuesto y NO implementado todavia.

**IMPORTANTE — pendiente de la revision GPT anterior AUN NO RESUELTO:** el
hallazgo prioritario de la seccion "Revision GPT / Codex — 2026-09-24" (fix de
`card.interestRate / 100 / 365` en `simulator_sheet.dart`, lineas ~213 y ~600)
sigue sin corregir. Esta sesion se enfoco en otras cosas a pedido del usuario;
sigue siendo la correccion tecnica mas importante pendiente.

### 1. Bug real corregido: crash al crear tarjeta

`add_credit_sheet.dart` — el `DropdownButtonFormField<int>` de "Dias para
pagar despues del corte" tenia una lista fija `[10,15,20,25,30,35,40]`. Las
plantillas de banco en `entity_templates.dart` usan valores fuera de esa
lista (Bancolombia = 21, otras = 22) — al autocompletar esa entidad, Flutter
lanzaba `'there should be exactly one item with value X'` y la app crasheaba
por completo. Corregido generando la lista de items como union dinamica entre
el set fijo y el valor actual de la plantilla. Verificado en dispositivo
fisico con credito de prueba `PRUEBA_BORRAR_card1` (Bancolombia, offset 21)
sin crash.

### 2. Rediseno del asistente "Nuevo Credito" (3 pasos -> 4 pasos)

Motivado por feedback repetido de que el paso 2 se sentia "muy cargado" y con
lenguaje muy tecnico.

- Paso 2 ("Datos Financieros") se partio en dos pasos: **Paso 2 "Monto y
  cuotas"/"Cupo de la tarjeta"** (solo lo minimo indispensable) y **Paso 3
  "Fecha de pago"/"Interes y costos"** (calendario + casos opcionales).
- Nuevo panel **`_LiveFinancialHero`**: reacciona en vivo a lo que el usuario
  teclea, mostrando "VALOR DE LA CUOTA" (prestamo) o "CUPO DISPONIBLE"
  (tarjeta, con barra de uso de cupo) en tipografia grande tipo dashboard —
  antes esos numeros aparecian chiquitos y duplicados (una vez arriba, una
  vez en un campo deshabilitado mas abajo). Se elimino el campo deshabilitado
  duplicado; su logica de validacion se movio a `_nextStep()`.
- Encabezados de seccion internos renombrados para no repetir literalmente el
  titulo del paso (ej. "Monto y cuotas" como titulo de paso y "DATOS DEL
  CREDITO" como header interno, en vez de repetir "Monto y cuotas" dos veces).
- Lenguaje de campos simplificado: "Monto Financiado" -> "Monto a
  financiar", "Cantidad de Cuotas" -> "Numero de cuotas", etc. Pendiente:
  extender esta revision de lenguaje "neutro, no tecnico" al resto del
  proyecto si el usuario lo pide explicitamente (por ahora solo se aplico al
  wizard de creacion, a peticion puntual).
- "¿Ya llevas cuotas pagadas?" dejo de ser un desplegable colapsado — ahora
  es un campo siempre visible, marcado como opcional, ubicado despues de
  "Fecha y Frecuencia" (antes) dentro del Paso 3.
- Seccion "Detalles adicionales" (comercio/notas) eliminada del asistente de
  creacion (tanto prestamo como tarjeta) — esos campos se pueden seguir
  editando despues desde `edit_credit_sheet.dart`, que si los conserva.
- Paso 4 (Confirmacion): se quito el titulo "Confirmacion" repetido (ya lo
  dice el indicador de pasos arriba). El resumen de datos paso de una lista
  vertical "label izquierda / valor derecha" a una tarjeta de **2 columnas**
  con una linea divisoria interna sutil, todo el texto alineado a la
  izquierda dentro de cada columna (`_SummaryGrid` + `_SummaryTile`).
- Texto "Paso X de 4: <titulo>" debajo de los circulos del stepper:
  **eliminado por completo** (duplicaba el titulo grande de cada paso; el
  usuario pidio quitarlo por no encontrarle utilidad).
- Animacion entre pasos: slide de pantalla completa (el paso saliente se
  esconde del todo hacia un lado, el entrante aparece del todo desde el
  otro), 420ms, `AnimatedSwitcher` + `SlideTransition` con direccion segun
  se avance o retroceda (`_stepDirection`). Iteracion previa (offset sutil
  del 6% del ancho) se descarto por sentirse "muy discreta".

### 3. Animaciones de navegacion general

- Fade entre pestanas (`_TabFadeLayer`, `lib/main.dart`): duracion subida de
  220ms a **340ms** (termino medio, ni muy rapido ni muy lento).
- Apertura/cierre de "Nuevo Credito" (`/add-credit` en `onGenerateRoute`):
  antes usaba el slide-desde-la-derecha por defecto de `MaterialPageRoute`;
  ahora usa un `PageRouteBuilder` con **fade puro** (340ms, `easeOutCubic`),
  igual en ambas direcciones (abrir/cerrar), para que se sienta como el
  mismo lenguaje de transicion que el resto de la app.

### 4. Rename de paquete: `com.kredit.kredit` -> `com.luchopan.kredit`

Cambiado en: `android/app/build.gradle.kts` (namespace + applicationId),
carpetas Kotlin movidas a `android/app/src/main/kotlin/com/luchopan/kredit/`
(`MainActivity.kt`, `KreditHomeWidgetProvider.kt`, con su `package` interno
actualizado), `ios/Runner.xcodeproj/project.pbxproj` y
`macos/Runner.xcodeproj/project.pbxproj` (`PRODUCT_BUNDLE_IDENTIFIER`).
`AndroidManifest.xml` no necesito cambios (usa nombres relativos `.MainActivity`
/ `.KreditHomeWidgetProvider`).

**Consecuencia importante or ambos agentes deben tener presente:** Android
trata esto como una app DISTINTA. La app vieja instalada
(`com.kredit.kredit`) y la nueva (`com.luchopan.kredit`) coexisten como dos
apps separadas — los datos NO se migran solos. Flujo seguido: exportar
respaldo desde Cuenta > Datos en la app vieja, reinstalar con
`flutter run` desde cero (esto no aplica con hot reload/restart), importar el
respaldo en la app nueva. Confirmado funcionando en dispositivo fisico.

### 5. Pantalla de bienvenida (`welcome_screen.dart`)

- Icono superior cambiado de un `Icons.account_balance_wallet_rounded`
  generico al **logo real de Kredit** (`KreditLogo`, el mismo SVG que usa el
  dashboard).
- Copy de "Protege tu informacion" simplificado (se quito "desbloqueo
  biometrico", "bloqueo temporal tras varios intentos fallidos" y la mencion
  al widget — informacion tecnica/tangencial que no aportaba en el contexto
  de bienvenida).
- Copy de "No te pierdas un vencimiento" simplificado.
- El switch de notificaciones ahora dice **"Notificaciones de vencimiento
  (Recomendado)"** y por defecto viene **desactivado** (antes el default
  global de `NotificationSettings.defaults.enabled` era `true`; se cambio a
  `false` en `notification_settings_provider.dart` — este es un cambio de
  default para TODA la app, no solo la bienvenida).
- Al activar el switch, aparece debajo (con `AnimatedSize`, 260ms) la
  configuracion completa de dias/hora/frecuencia — la misma que ya existia
  en Cuenta > Notificaciones — sin tener que salir de la bienvenida ni ir a
  Cuenta despues.

### 6. Rediseno de `NotificationSettingsTile` (compartido por Cuenta y Bienvenida)

Motivo: el usuario senalo que el layout no era simetrico ni prolijo (el paso
1 no tenia caja mientras los pasos 2 y 3 si).

- Se agrego `showHeader` (bool, default `true`) para poder insertar el mismo
  widget en la bienvenida sin duplicar el switch maestro (la bienvenida trae
  el suyo propio).
- Los 3 pasos (dias de anticipacion / hora / frecuencia) reemplazaron sus
  encabezados de circulo numerado (1-2-3) por el patron de icono + texto en
  mayusculas ya usado en el resto de la app (`_StepHeader`, mismo lenguaje
  que `_SectionCard` en `add_credit_sheet.dart`).
- El selector de "dias de anticipacion" ahora vive dentro de una caja con
  borde igual a los otros dos pasos (antes era el unico "flotando" sin caja
  — causa raiz de la asimetria reportada).
- Las tarjetas de "Un solo aviso" / "Recordatorio diario" perdieron su
  icono decorativo (dejaba espacio vacio debajo cuando el subtitulo
  ocupaba 2 lineas) — ahora solo llevan el radio de seleccion + texto, con
  todo el ancho disponible.

### 7. Widget de pantalla de inicio (Android) — rediseno completo

El usuario no sabia que este widget existia (`widget_privacy_provider.dart` +
`home_widget_service.dart`, preexistente); al mostrarselo senalo que el
diseno "no estaba muy bien trabajado" y pidio aprovecharlo a fondo.

- **Layout nuevo** (`android/app/src/main/res/layout/kredit_widget_layout.xml`):
  tarjeta con fondo redondeado (`kredit_widget_background_pure.xml`, mismo
  lenguaje visual bgCard/borderCard de la app en vez del negro plano
  anterior), icono de marca pequeno y NO invasivo (14dp, `@mipmap/ic_launcher`)
  en vez de un titulo de texto "Kredit" grande.
- **Datos nuevos mostrados:** ademas de deuda total, ahora se ve el **%
  pagado** (barra de progreso + etiqueta, oculta automaticamente cuando no
  aplica — solo tarjetas, sin prestamos) y la **proxima cuota** (nombre +
  monto + fecha relativa, antes era un solo string concatenado).
- **Tap para abrir la app:** antes el widget no reaccionaba a ningun toque.
  Ahora tiene un `PendingIntent` que abre `MainActivity` (bug reportado por
  el usuario, corregido en `KreditHomeWidgetProvider.kt`).
- **Nombre e identificacion en el selector de widgets de Android:** antes
  aparecia solo como "Kredit" (el nombre de la app, no describia la
  funcion). Ahora tiene `android:label="Resumen"` en el `<receiver>` del
  manifest y una `android:description="Deuda total, progreso y proxima
  cuota"` en `kredit_widget_info.xml`.
- **Se adapta al tema elegido por el usuario:**
  - Color de acento (las 7 opciones de Cuenta > Personalizacion) tine la
    cifra de deuda total y el monto de la proxima cuota
    (`setTextColor` en Kotlin, leyendo `accent_color` como hex).
  - Tono de fondo (Oscuro Puro / Frio-Azul / Grafito) selecciona entre 3
    drawables de fondo (`kredit_widget_background_pure/cool/warm.xml`) via
    `setBackgroundResource`, en vez de un color fijo — se eligio este
    metodo (en vez de tintar un solo drawable) porque `RemoteViews` no
    soporta tintar backgrounds arbitrarios sin API 31+, pero si soporta
    cambiar de recurso a cualquier nivel de API.
  - Pendiente/limitacion conocida: la barra de progreso (`ProgressBar`) NO
    se tine con el color de acento (RemoteViews no expone un metodo
    compatible con todas las APIs para tintar `ProgressBar` dinamicamente
    sin subir el `minSdk` a 31). Queda blanca. Se documenta para que GPT no
    lo reporte como "olvidado" — fue una decision consciente de alcance.
  - `home_widget_service.dart` ahora escribe `progress_percent`,
    `next_payment_name/amount/date`, `accent_color` y `bg_tone` (antes solo
    escribia `total_debt` y un `next_payment` concatenado). `main.dart`
    ahora tambien escucha `themePreferencesProvider` para resincronizar el
    widget cuando el usuario cambia de acento/tono (antes solo reaccionaba a
    cambios de creditos y del switch de privacidad).
- Este cambio es codigo nativo (Kotlin + recursos XML de Android) — **no
  aplica con hot reload/restart**, requiere detener y volver a correr
  `flutter run`.

### 8. Estadisticas avanzadas (`stats_screen.dart`) — reduccion de densidad

- El panel superior tenia **6 cifras** apiladas en dos filas: fila 1
  (Creditos activos / Cupo disponible / Limite total) del
  `_DebtOverviewPanel`, fila 2 (Finalizados / Total pagado / Total prestado)
  del widget separado `StatsGrid`. Feedback del usuario: "tanto cuadro no es
  util". Se redujo a **una sola fila de 3**: Creditos activos, Cupo
  disponible, Total pagado. Se descartaron "Limite total" (redundante con
  Cupo disponible) y "Finalizados"/"Total prestado" (poco accionables).
- `lib/widgets/account/stats_grid.dart` **se elimino por completo** (ya no
  se usaba en ningun lado tras la fusion de arriba). Su helper de formato
  `NumberFormatLike` tambien se elimino de `stats_screen.dart`; los 4 usos
  que quedaban ahi se migraron a `formatCOP()` (`credit_display_utils.dart`,
  el formateador estandar del resto de la app).
- Se elimino el punto de entrada al simulador ("¿Que pasa si...?") que vivia
  al final de Estadisticas (`_SimulatorEntryRow`) — el usuario senalo que
  el simulador ya tiene su propia entrada, mas visible, en el Dashboard, y
  que duplicarlo en Estadisticas "no encaja del todo bien". El simulador
  ahora se accede SOLO desde Inicio.
- **Pendiente, senalado por el usuario pero NO resuelto todavia:** las
  secciones "RIESGOS DETECTADOS" e "HISTORIAL Y HERRAMIENTAS" muestran
  informacion que el usuario considera util pero cree que "no la estamos
  mostrando como deberiamos" — sin una propuesta concreta todavia de que
  cambiar ahi. Queda abierto para la proxima sesion.

### 9. IDEAS DISCUTIDAS — NO IMPLEMENTADAS (para que GPT las tenga en cuenta)

Estas tres ideas se hablaron en profundidad con el usuario pero **no se
escribio ninguna linea de codigo todavia** — son cambios de arquitectura de
datos/dominio, no ajustes de UI, y requieren pasar por diseno antes de
implementarse (ver regla de "brainstorming" del propio Cloud: cambios
arquitectonicos necesitan spec escrita antes de tocar codigo).

**A. Catalogo de entidades como base de tarjetas/cupos (en vez de "crear un
credito especifico por banco").**

Idea del usuario: hoy, registrar un credito significa llenar un formulario
generico eligiendo un banco de una lista (`_presetLenders` en
`add_credit_sheet.dart`) y llenando montos a mano. El usuario propone invertir
el flujo: que existan **entidades registradas en base de datos**, clasificadas
por como opera su producto —

- **"Cupo"**: linea de credito de uso general (no maneja necesariamente
  ciclo de corte/fecha limite tipo tarjeta).
- **"Tarjeta de credito"**: opera con ciclo de facturacion (fecha de corte +
  fecha limite de pago), igual que una tarjeta bancaria tradicional.

El usuario cayo en cuenta de que **RappiCard funciona como tarjeta de
credito real** (corte + fecha limite), no como un cupo generico — esto
implica reclasificar las plantillas existentes de `entity_templates.dart`
por tipo de producto, no solo por banco.

Requisito explicito: al elegir tipo "Cupo" en el asistente, solo deben
listarse las entidades que operan como cupo; al elegir "Tarjeta de credito",
solo las que operan como tarjeta. Las dos fechas (corte y limite de pago)
deben ser **configurables por el usuario al registrar cada tarjeta** — hoy
`CardCredit` YA tiene `cutoffDay`/`paymentDueOffsetDays` configurables por
formulario, pero la reclasificacion "que entidades aparecen segun el tipo
elegido" no existe todavia.

Impacto tecnico a evaluar (no resuelto, para que GPT lo piense tambien):
cambios en `entity_templates.dart` (agregar campo de "tipo de producto" por
plantilla), en `add_credit_sheet.dart` (filtrar `_presetLenders`/plantillas
segun `_type` elegido), y potencialmente en el modelo de datos si se quiere
separar "entidad" de "instancia de credito del usuario" (hoy `CardCredit`/
`LoanCredit` no referencian una tabla de entidades, guardan `lender` como
string libre).

**B. Extracto propio de Kredit (estilo estado de cuenta bancario).**

Idea del usuario: que Kredit muestre algo equivalente al extracto que emite
un banco — un resumen por CICLO de facturacion, no solo un saldo corriente.
Logica que el usuario describio (y que YA esta implementada correctamente en
`card_calculator.dart` / `getCardCycleDates`, verificado en esta sesion con
un credito de prueba Bancolombia: ciclo cierra el 15, fecha limite de pago
cae 21 dias despues, el 6 del mes siguiente): del dia de corte de un mes al
dia de corte del mes siguiente es la "ventana de compra"; todo lo comprado
en esa ventana se factura y su fecha limite de pago es N dias despues del
cierre de esa ventana.

Lo que falta (no implementado): una VISTA dedicada tipo "extracto" por ciclo
— hoy la app calcula las fechas correctamente pero no las presenta como un
documento/resumen de ciclo cerrado (tipo "extracto de Septiembre: compraste
$X, tu pago vence el Y"). Seria una pantalla o seccion nueva dentro del
detalle de tarjeta.

**C. Capa de "asistente de gestion" mas fuerte (guias, no solo datos).**

El usuario recordo que el roadmap original de GPT mencionaba que Kredit
deberia comportarse como un asistente que da PAUTAS de como manejarse con
los creditos/cupos (no solo mostrar cifras) — confirmar si el usuario va
bien encaminado, sugerir la siguiente mejor accion, etc. Esto ya existe de
forma parcial en `lib/domain/recommendations.dart`
(`buildPrimaryRecommendation`, `buildRiskRecommendations`,
`buildBestPrepaymentRecommendation`), pero el usuario quiere que esta idea
se profundice — mas alla de alertas puntuales, hacia algo mas parecido a un
"coach" persistente. Sin propuesta concreta todavia; queda para discutir
enfoque (¿una pantalla dedicada? ¿mas reglas en el motor existente? ¿un
resumen semanal/mensual tipo "como te fue"?).

## "Una entidad, un registro" — 2026-09-27

Nueva conversacion sobre un problema real que el usuario detecto: hoy Kredit
no distingue entre "ya tengo esta entidad registrada" y "crear un producto
nuevo" — cada vez que terminas el asistente de "Registrar Nuevo Credito" se
crea una fila 100% independiente, sin revisar si ya existia algo con esa
misma entidad.

### Investigacion (confirmada leyendo el codigo real, antes de proponer nada)

- `Credits` table (`lib/data/db/tables.dart`): `lender` es texto libre, sin
  tabla de entidades, sin ID unico, sin ninguna restriccion que impida
  duplicar. Confirmado: hoy SI se duplica.
- `entity_templates.dart` (16 plantillas): ya distingue implicitamente por
  comentario que Nequi y DaviPlata NO tienen producto de tarjeta rotativa
  (son cupo/cuotas fijas) — pero no hay un campo formal de "tipo de
  producto", y la lista de bancos del paso 1 del asistente es identica sin
  importar si eliges "Cupo" o "Tarjeta de credito".
- `bank_detector.dart`: Falabella YA esta modelado como dos sub-entidades
  separadas ("Banco Falabella" = cupo/libre inversion, "CMR Falabella" =
  tarjeta) — es el precedente exacto de como tratar una entidad que ofrece
  ambos productos.
- `wallet_card.dart`: `credit.name` (el nombre que el usuario le pone al
  crear el credito) nunca se pintaba en ningun lado de la tarjeta visual —
  dos tarjetas del mismo banco eran indistinguibles a simple vista pese a
  que el dato ya existia en el modelo.

Diseno completo (2 enfoques con tradeoffs, mockups) publicado como Artifact:
https://claude.ai/artifact/DUZRw4yULcXtnsapupFK5i

### Decision del usuario

- Aprobo la **Opcion A** (aviso de posible duplicado, no bloqueo — nunca
  impedir crear un segundo producto de la misma entidad, porque hay casos
  reales como usar el cupo/tarjeta de otra persona).
- Pidio ademas, como parte de la misma solucion: el nombre del
  credito/tarjeta debe verse en la tarjeta visual, en alto contraste (no
  discreto), para poder diferenciar "mi RappiCard" de "el RappiCard de mi
  novia" de un vistazo.
- La clasificacion "cupo vs tarjeta vs ambos" por entidad queda para una
  siguiente ronda — el usuario pidio investigar entidad por entidad antes
  de decidir (ver preguntas abiertas mas abajo).

### Implementado en esta sesion

- [x] **Nombre visible en `WalletCard`** (`lib/widgets/wallet_card.dart`):
  chip de alto contraste en la esquina superior derecha (fondo blanco/negro
  segun el tono de la tarjeta, invertido respecto al color de tinta) que
  muestra `credit.name`. Antes ese campo nunca se pintaba en la tarjeta.
  Verificado en dispositivo fisico con los 2 creditos reales — se ve en
  ambas tarjetas ("Totto (Bolso y Lonchera...)" y "Varias cosas con mi
  b...").
- [x] **Aviso de posible duplicado** (`add_credit_sheet.dart`): nuevo
  getter `_duplicateActiveCredit` — compara el banco detectado
  (`detectBank`) del lender que se esta escribiendo contra los creditos
  ACTIVOS existentes del mismo tipo (prestamo/cupo vs tarjeta). Si
  coincide, aparece un aviso amarillo (mismo lenguaje visual que el aviso
  de "Nequi no opera con tarjeta rotativa" ya existente) con el nombre del
  credito existente y un boton "Abrir el que ya tengo" (navega directo a
  su detalle). Nunca bloquea `Siguiente` — el usuario puede seguir y crear
  el segundo de todos modos. Se excluye expresamente 'bank-generic' (el
  fallback de lenders no reconocidos) para no disparar falsos positivos
  entre dos entidades "Otro..." distintas.
  - Verificado en dispositivo fisico: crear un prestamo de prueba
    (`PRUEBA_BORRAR_rappi2`) eligiendo "RappiCard" mostro correctamente el
    aviso mencionando el credito real ya activo con esa entidad, con el
    boton funcionando y sin bloquear el avance al paso 2. Descartado sin
    guardar al terminar la prueba.
- `flutter analyze`: 0 issues. Requirio agregar el import de
  `creditHasUnpaid` (`credit_calculator.dart`) que faltaba — atrapado por
  el propio `flutter analyze` antes de llegar al dispositivo.

### Preguntas abiertas para la proxima ronda (clasificacion por tipo de producto)

Confirmado por el propio codigo (alta confianza):
- Nequi, DaviPlata → solo Cupo.
- RappiCard → solo Tarjeta de credito (confirmado por el usuario esta
  sesion: opera con corte + fecha limite, no como cupo generico).
- Banco Falabella (cupo) / CMR Falabella (tarjeta) → ya modeladas como 2
  entidades separadas, patron a replicar.

Probable "ambos", pendiente de confirmar con el usuario (bancos completos
que probablemente ofrecen libre inversion + tarjeta, pero no verificado
oficialmente): Bancolombia, Davivienda, BBVA, Banco de Bogota, Scotiabank
Colpatria, Banco Popular, Banco AV Villas, Banco de Occidente, Itau.

Genuinamente incierto, el usuario dijo que lo confirmaria:
- Nu (Nubank): ¿solo tarjeta, o ya tiene tambien cupo/prestamo en Colombia?
- Lulo Bank: ¿su "Cupo Lulo" y una tarjeta son productos separados?
- Tarjeta Tuya / Exito: ¿solo tarjeta de marca propia, o tambien cupo?

No implementar la clasificacion todavia — falta la confirmacion del usuario
sobre estos 3 casos y su visto bueno a tratar los "probable ambos" como
entidades separadas (replicando el patron Falabella).

## Cupo comercial — 2026-09-27

El usuario hablo con ChatGPT sobre como funcionan productos de credito
comercial colombianos (Totto/Keypago, Lili Pink-Yoi/CrediPink, Exito
Tarjeta Tuya/CrediCompras) y trajo esa conversacion (`UltimoChatConGPT.md`)
para ver que le sirve a Kredit, con la prioridad explicita de que la app
siga siendo simple para un usuario promedio: nada de jerga tecnica ni
datos obligatorios que no necesita.

**Investigacion (con fuentes, antes de disenar nada):**
- Totto/Keypago, Lili Pink/Yoi (CrediPink) y Exito (Tarjeta Tuya /
  CrediCompras): las tres funcionan igual — el usuario tiene un **cupo**
  con un limite, y dentro de el hace **compras independientes**, cada una
  con su propio numero de cuotas. El cupo se libera a medida que se paga.
- Pronto-pago sin interes: confirmado **solo en Lili Pink** (CrediPink) —
  si pagas antes de la fecha de pago, no cobran interes y el abono va a
  capital. **No confirmado** en Totto/Keypago ni en Exito — no se puede
  generalizar como comportamiento automatico de Kredit.

**Decision de diseno (idea central del usuario, no de GPT):** el usuario
nunca debe ver ni configurar la entidad financiera real detras de una
marca (Keypago, Tuya, Credifactory) — solo ve la marca ("tengo un cupo en
Totto", nunca "tengo un producto de Credifactory via Keypago en Totto").
Los bancos existentes (Bancolombia, Nu, etc.) no se tocan; "cupo
comercial" es una capa agrupadora ligera sobre `LoanCredit`, no un tipo de
`Credit` nuevo — cada compra sigue siendo un prestamo normal.

**Que se construyo** (spec completo en
`docs/superpowers/specs/2026-09-27-cupo-comercial-design.md`, plan de
implementacion en `docs/superpowers/plans/2026-09-27-cupo-comercial.md`):
- `CommercialQuota` (modelo) + tabla `CommercialQuotas` (marca, limite),
  con 3 columnas nuevas en `Credits`: `quotaId` (FK, `onDelete: restrict`
  para que borrar un cupo con compras activas falle en vez de perder
  datos), `interestUnknown` y `earlyPaymentWaivesInterest`.
- `quotaAvailable()` (`lib/domain/commercial_quota_calculator.dart`):
  reutiliza 100% la logica existente de saldo pendiente
  (`getCreditRemainingBalance`/`creditHasUnpaid`), cero calculo financiero
  nuevo.
- `commercialQuotasProvider`: CRUD de cupos, mismo patron manual
  (`AsyncNotifierProvider`) que ya usa `creditsProvider` en este proyecto.
- Regla: si el usuario llena una tasa real (`interestRate > 0`), el flag
  `interestUnknown` se limpia automaticamente al guardar — nunca puede
  quedar "no se la tasa" y "tasa: 2.3%" visibles a la vez.
- Pantalla Creditos: las compras con `quotaId` se agrupan bajo una
  `CommercialQuotaCard` (marca + barra de disponible/limite), en vez de
  aparecer sueltas. Todo cupo se muestra siempre, incluso con 0 compras
  (recien creado, o huerfano tras borrar su unica compra) — invisibilidad
  silenciosa de un cupo vacio era un bug real encontrado en pruebas.
- Wizard "Nuevo Credito": nuevo toggle "Es una compra de un cupo
  comercial" justo despues de elegir el tipo (preferencia explicita del
  usuario tras ver el primer orden, que le parecio "enredado" con el
  campo Banco/Prestamista todavia visible). Al activarlo, el campo
  Banco/Prestamista se oculta por completo — la marca del cupo ES la
  entidad, nunca hay un banco aparte.
- Detalle de compra: si `interestUnknown`, se muestra "Cuenta sin
  intereses registrados" en vez de una tasa/E.A. (nunca se sintetiza un
  0% como si fuera un dato real).

**Hallazgos reales encontrados en la prueba en dispositivo** (motorola
edge 50 fusion, con datos `PRUEBA_BORRAR_*`, eliminados al terminar) que
no estaban en el plan original y se corrigieron en el momento:
1. La vista previa (paso 4 del wizard) seguia mostrando "Bancolombia"
   como entidad aunque el usuario hubiera elegido un cupo comercial —
   corregido sincronizando el campo de entidad con la marca del cupo en
   todos los casos (cupo nuevo o existente).
2. Las compras dentro de una `CommercialQuotaCard` no eran tocables (sin
   navegacion al detalle) — agregado.
3. El detalle de credito mostraba "0.0%" en vez de "Cuenta sin intereses
   registrados" para compras con `interestUnknown` — el spec lo pedia
   pero no tenia tarea propia en el plan; corregido con su propio test.
4. No existia forma de eliminar un cupo desde la UI (el manejo de error
   "borrar cupo con compras activas" presuponia un boton que no estaba
   implementado) — se agrego boton eliminar + confirmacion + mensaje
   claro si el cupo aun tiene compras activas.
5. Un cupo sin compras en la pestana activa dejaba de renderizarse por
   completo — corregido para que todo cupo se muestre siempre.

## Revision final del plan + voucher generico para cupos — 2026-09-27 (tarde)

Tras completar el plan de cupo comercial (8 tareas + push a `origin/master`),
se hizo la revision final de rama con un revisor fresco (Opus, sin contexto
previo) sobre el diff completo + spec + plan. Encontro 1 hallazgo critico y
varios importantes, todos corregidos antes de seguir:

- **Critico:** el respaldo/restauracion (exportar/importar JSON) no incluia
  `CommercialQuotas`, y con las FK ya activas (`PRAGMA foreign_keys=ON`) una
  restauracion con creditos de cupo podia fallar a mitad de camino, dejando
  los datos del usuario parcialmente borrados e irrecuperables. Corregido:
  el formato de respaldo subio a version 3 (incluye cupos), y
  `replaceAllData` reemplaza creditos + cupos en una sola transaccion.
- Eliminar un cupo se bloqueaba incluso si todas sus compras ya estaban
  pagadas, con un mensaje generico y enganoso — ahora solo bloquea si hay
  compras activas de verdad (con el conteo real en el mensaje), y las
  pagadas se desvinculan sin perder su historial.
- Una compra con `quotaId` apuntando a un cupo borrado/no cargado
  desaparecia de la lista en vez de volver a mostrarse suelta; el
  disponible de un cupo se calculaba sobre la lista YA filtrada (busqueda/
  tabs), mostrando cifras erroneas al buscar o en la pestana Finalizados.
- Bugs de estado en el wizard: cambiar a Tarjeta con el cupo activo dejaba
  el campo Banco/Emisora oculto sin forma de corregirlo; apagar el toggle
  dejaba el campo de banco con la marca del cupo en vez de restaurarlo;
  controladores nuevos sin `dispose()`.
- Aviso de sobre-cupo (requisito del spec que no tenia tarea propia):
  agregado como banner no bloqueante en el wizard.

**Cupo comercial con diseno de voucher generico:** pedido nuevo del usuario
tras el cierre del plan — los cupos comerciales (Totto, Lili Pink, Exito
CrediCompras) no tienen tarjeta fisica, asi que sus compras ahora usan el
mismo formato "voucher" (recorte con muescas, borde punteado) que ya
existia para los adelantos tipo Nequi en `WalletCard`, pero con colores
genericos/neutros — nunca el morado/magenta especifico de Nequi. Decision
del usuario: siempre voucher para cupo comercial, sin excepcion por marca
(no se agrego un campo "tiene tarjeta fisica" en `CommercialQuota`). El
detalle de la compra muestra "Compra (marca)" en vez de "Adelanto (marca)".
Alcance acordado con el usuario: el voucher aplica solo al detalle de la
compra (`WalletCard`), no a las filas dentro de `CommercialQuotaCard` en la
lista de Creditos (esas siguen como filas simples).

Todo verificado en dispositivo real (motorola edge 50 fusion) con datos
`PRUEBA_BORRAR_*`, eliminados al terminar cada prueba. 158/158 tests verdes.

## Rediseno del cupo comercial: voucher unico + detalle agrupado — 2026-09-27 (noche)

Tras usar la funcion en la practica, el usuario pidio un rediseno completo
de como se ve y navega un cupo comercial (varias iteraciones de feedback
en vivo, cada una implementada de inmediato):

- **Pantalla Creditos:** el cuadro "marca + barra + vouchers sueltos
  adentro + boton eliminar" desaparecio. Ahora cada cupo es **un solo
  voucher**, con la misma forma recortada que cualquier otro voucher, y
  una franja inferior (como "PROGRESO PAGADO" en un credito normal) que
  muestra DISPONIBLE / COMPRAS. Un chevron "Ver N compras" despliega el
  detalle de cada compra sin salir de la lista ni abrir otra pantalla.
- **Diseno del voucher:** dejo de reciclar el motivo de olas de Nequi en
  otro color (lo que el usuario ya habia rechazado explicitamente antes).
  Ahora es un relleno plano **minimalista con el color de acento que el
  usuario eligio en Ajustes** (no un color fijo), con el color de texto
  calculado automaticamente para contraste (`legibleForegroundOn`). El
  adelanto real de Nequi/DaviPlata conserva su propio diseno de olas sin
  tocar — esto solo aplicaba a cupos comerciales.
  Tambien se ajusto el sello generico "K REDIT" (usado cuando no hay
  logo real de banco): la K es el icono real de la app, "REDIT" ahora en
  el mismo tamano visual que la K (antes se veia desproporcionadamente
  chico) y ambos en negro.
- **Detalle agrupado por cupo:** tocar el voucher abre el detalle de
  **todas las compras de ese cupo juntas** (la tocada primero, el resto
  por fecha mas reciente) — no solo la compra individual. Tab Resumen:
  cada compra con su propio voucher + boton editar/eliminar. Tab
  Cronograma: una seccion desplegable por compra (la mas reciente
  expandida por defecto), en vez de mezclar las cuotas de varias compras
  en una sola lista confusa. "Eliminar cupo" se movio al AppBar de este
  detalle (antes vivia en la tarjeta de la lista, lo cual ya no aplica
  con un solo voucher).
- Un cupo sin compras (recien creado o huerfano) sigue siendo eliminable:
  tocar su voucher sin compras abre directamente el dialogo de confirmar
  borrado, en vez de navegar a una pantalla vacia.

Implementacion: `voucherOutline`/`VoucherClipper`/`VoucherBorderPainter`/
`VoucherWaveCornerPainter` se sacaron de privados a publicos en
`wallet_card.dart` para reutilizarse en el nuevo voucher agregado
(`CommercialQuotaCard`). Nuevo archivo
`lib/widgets/credit_detail/quota_group_tabs.dart` con
`QuotaGroupSummaryTab`/`QuotaGroupScheduleTab`. `CreditDetailScreen`
detecta si el credito tocado tiene `quotaId` y arma el grupo completo de
compras de ese cupo antes de decidir que tabs mostrar.

Verificado en dispositivo real con datos reales del usuario (cupo "Joy" /
"Regalos para mi nina"), sin necesidad de datos de prueba. 158/158 tests.

## Auditoria de codigo Cloud — 2026-09-25 (madrugada)

Mientras el usuario dormia, pidio explicitamente 3 auditorias de codigo de
solo lectura (arquitectura/modularizacion, rendimiento/codigo muerto,
calidad/seguridad de datos), ejecutadas via 3 subagentes en paralelo. Cero
archivos modificados durante la auditoria. `flutter analyze` (0 issues) y
`flutter test` (128/128) corridos antes, ambos limpios. Resultado completo,
con contexto y sugerencia de arreglo por hallazgo, publicado como Artifact:
https://claude.ai/artifact/Jts8sQnuDMhZbCtSE55ybt — esta seccion es el
resumen para que quede tambien como bitacora en texto plano.

### Auditoria 1 — Arquitectura y modularizacion

**Alto impacto**
- [ ] `_calcSuggestedQuota()` en `add_credit_sheet.dart:180` reimplementa a
  mano la misma formula PMT que ya existe (privada) como `_pmt()` en
  `loan_calculator.dart:459`. Riesgo: si se corrige un redondeo o cambia la
  convencion de tasa en un lado, el otro queda desincronizado en silencio.
  Arreglo: exportar `_pmt` (o un wrapper publico `calculateLoanQuota()`) y
  que la UI la reuse.
- [ ] **Reincidencia de un hallazgo YA reportado por GPT y aun sin
  corregir:** `simulator_sheet.dart:213` y `:600` calculan interes de
  tarjeta a mano (`card.interestRate / 100 / 365`, asumiendo siempre E.A.)
  en vez de `dailyRateFrom()`. Ver seccion "Revision GPT / Codex —
  2026-09-24" mas arriba para el detalle original.
- [ ] `add_credit_sheet.dart` tiene 1765 lineas, con una sola clase State de
  ~1250 lineas mezclando formulario + calculo financiero + mapeo banco→color
  (switch de ~15 casos) + los 4 pasos del wizard. Arreglo sugerido: separar
  en `add_credit_form_state.dart`, `add_credit_steps.dart`, y mover el mapeo
  de color a `bank_detector.dart`.

**Impacto medio**
- [ ] Patron "columna de estadistica con divisor" triplicado:
  `_SecondaryStat` (dashboard_screen.dart), `_StatColumn` (stats_screen.dart),
  `_CardStatColumn` (wallet_card.dart:749) — unificar en un
  `KreditStatColumn` compartido.
- [ ] Tres sistemas paralelos de "tarjeta con header+icono":
  `KreditSectionCard` (con caja), `_SectionCard` privado en
  add_credit_sheet.dart (sin caja), `_statsSectionHeader` (funcion suelta en
  stats_screen.dart) — decidir una sola API con un flag `boxed: bool`.
- [ ] Logica financiera real en `lib/utils/credit_display_utils.dart`
  (`getLoansProgressPercent()` linea 62, `getDueSoonTotal()` linea 105) en
  vez de `lib/domain/` — viola la regla propia del proyecto y por eso no
  tiene tests. Mover a `credit_calculator.dart`.

**Bajo impacto**
- [ ] `lib/screens/credit_detail/schedule_tab.dart` (789 lineas) casi
  duplica a sus hermanos `summary_tab.dart` (487) y `movements_tab.dart`
  (412) — revision puntual, no urgente.
- Providers (`lib/providers/*.dart`): consistentes, sin hallazgos.

### Auditoria 2 — Rendimiento y codigo muerto

**Alto impacto**
- [ ] `updateHomeWidget(...)` se llama desde `ref.listen` en `main.dart:211`
  sin `await` ni manejo de errores, y `home_widget_service.dart` no tiene
  ningun `try/catch` alrededor de las llamadas al plugin nativo — una falla
  de canal de plataforma queda como excepcion async no capturada. Arreglo:
  try/catch en `updateHomeWidget` o `.catchError` en los 3 listeners.
- [ ] `home_widget_service.dart:38-73` hace hasta 6 `await` secuenciales a
  SharedPreferences por cada sync (independientes entre si) — se dispara en
  cada cambio de creditos, tema o privacidad. Arreglo: agrupar con
  `Future.wait([...])`.

**Impacto medio**
- [ ] 3 funciones confirmadas SIN NINGUN llamador (verificado con grep en
  todo `lib/` y `test/`):
  - `getTotalBorrowed()` — `credit_calculator.dart:25` (huerfana desde que
    se borro `stats_grid.dart` en la sesion de rediseno de Estadisticas de
    hoy mismo).
  - `getDueSoonTotal()` — `credit_display_utils.dart:105`.
  - `buildFinancialHealthLine()` — `recommendations.dart:362`.
  - Accion: eliminar las 3, o dejar comentario explicito si son API para
    uso inmediato.
- [ ] `buildRiskRecommendations(credits)` se ejecuta 3 veces en el mismo
  build de Estadisticas (`stats_screen.dart:96`, `:101`, `:351` dentro de
  `_RiskCountPill`) — calcularla una vez y pasarla como parametro.
- [ ] `buildPrimaryRecommendation` (`recommendations.dart:144`) vuelve a
  llamar `buildPendingPayments` internamente aunque
  `dashboard_screen.dart:168-170` ya la habia calculado — doble escaneo de
  todos los creditos por build. Agregar parametro opcional `payments`.
- [ ] `dashboard_screen.dart:164` — `ref.watch(themePreferencesProvider)
  .profileName` reconstruye TODO el dashboard ante cualquier cambio de tema
  (mas frecuente ahora que ese provider sincroniza el widget de inicio).
  Usar `.select((p) => p.profileName)`.

**Bajo impacto / notas verificadas sin hallazgo**
- Sin archivos huerfanos. `ListView` sin `.builder` solo en listas cortas y
  fijas (correcto); la lista que puede crecer ya usa `.builder`.

### Auditoria 3 — Calidad, consistencia y privacidad de datos

**Alto impacto**
- [ ] `pubspec.yaml`: `animations: ^2.2.0` y `uuid: ^4.5.1` declaradas sin
  ninguna referencia en `lib/` (verificado con grep) — quitarlas o
  confirmar uso futuro inmediato.
- [ ] `lib/domain/upcoming_payment.dart` (`findNextUpcomingPayment`)
  duplica lo que `buildPendingPayments()` (recommendations.dart) ya
  resuelve de forma mas general. Su docstring (linea 7-8) referencia
  `_buildUpcomingItems` de `dashboard_screen.dart`, funcion que **ya no
  existe** (comentario huerfano de un refactor anterior). Arreglo:
  eliminar `findNextUpcomingPayment`, usar
  `buildPendingPayments(credits).firstOrNull` en `home_widget_service.dart`.
- [ ] Sin tests: `lib/domain/credit_calculator.dart`
  (`getCreditRemainingBalance`, `creditHasUnpaid`, `getTotalBorrowed`) y
  `lib/domain/upcoming_payment.dart`, pese a alimentar dashboard,
  estadisticas y el widget de inicio. Agregar
  `test/domain/credit_calculator_test.dart` como minimo.

**Impacto medio**
- [ ] `getNextDueDate` vive en `credit_display_utils.dart` (utils) pero lo
  consume tambien `upcoming_payment.dart` (dominio) — una capa de dominio
  importando de utils es la senal de que esta mal ubicada. Mover a
  `credit_calculator.dart`.
- 13 usos de `debugPrint('...failed: $e')` en catches de guardado
  (export/import, borrar todo, eliminar movimiento/abono, notificaciones).
  No filtran montos/nombres (sin fuga de privacidad), pero el usuario no se
  entera si un guardado fallo mas alla de un log invisible — impacto de UX
  de confiabilidad, no de privacidad.

**Verificado SIN hallazgo (para que quede constancia, no solo lo malo):**
- Cero `boxShadow` en todo el proyecto — la regla se cumple sin excepcion.
- `catch (_) {}` en `notification_service.dart:53` y
  `app_lock_provider.dart:199,215` son fail-safe intencionales
  (timezone/biometria), no un problema.
- Colores hex en `wallet_card.dart` son paletas de marca por banco — uso
  legitimo, no viola la regla de `KreditColors`.

### Como priorizar esto (sugerencia de Cloud, no una decision tomada)

1. El fix de tasas de tarjeta en el simulador sigue siendo lo mas urgente
  (es el unico hallazgo que es un bug de calculo financiero real afectando
  al usuario, no solo estructura de codigo).
2. Los 2 hallazgos de "alto impacto" de rendimiento (manejo de errores del
  widget + escrituras secuenciales) son faciles de corregir y bajan riesgo
  real de crashes silenciosos.
3. Los 3 hallazgos de codigo muerto se pueden borrar en un commit chico sin
  riesgo.
4. El refactor de `add_credit_sheet.dart` (separar en 3 archivos) es el mas
  grande de todos — dejar para una sesion dedicada, no mezclarlo con otros
  cambios.

### Testeo en dispositivo fisico — 2026-09-25 (manana, ventana de 10 min)

El usuario dio acceso al dispositivo por 10 minutos antes de una reunion.
Durante esta ventana se encontro y corrigio un BUG REAL DE BUILD:

- [x] **Corregido:** `android/app/src/main/res/xml/kredit_widget_info.xml:9`
  — `android:description="Deuda total, progreso y proxima cuota"` como texto
  literal hacia fallar el build de Android por completo
  (`AAPT: error: ... incompatible with attribute description (attr)
  reference` — ese atributo exige una referencia `@string/`, no un literal).
  Se creo `android/app/src/main/res/values/strings.xml` con
  `widget_description` y se referencio como `@string/widget_description`.
  Build reintentado, exitoso.
- Contexto: el usuario no habia podido correr `flutter run` manualmente
  desde el cambio del widget de inicio; todas las verificaciones visuales
  anteriores de esa sesion (incluida la que reporto "Estadisticas sigue
  mostrando 6 cuadros") corrieron sobre un APK instalado VIEJO, sin los
  ultimos cambios. Cloud corrio `flutter run -d ZY22LBQ8XS` el mismo
  (autorizado explicitamente por el usuario, "no puedo hacerlo manualmente
  por la reunion"), encontro el error de build de arriba, lo corrigio, y
  volvio a correr — exitoso.

**Verificado funcionando en dispositivo real (build nuevo):**
- [x] Asistente "Nuevo Credito" de punta a punta, los 4 pasos: paso 1
  (iconos en avatar circular, sin "Paso X de 4"), paso 2 (hero "VALOR DE LA
  CUOTA" reaccionando en vivo al escribir monto/cuotas, sin duplicar "Monto
  y cuotas"), paso 3 ("¿Ya venias pagando?" siempre visible, sin
  colapsable, sin "Detalles adicionales"), paso 4 ("¡Ya casi esta!" sin
  "Confirmacion" duplicada, grid de 2 columnas con divisor interno,
  alineado a la izquierda). Probado con credito de prueba
  `PRUEBA_BORRAR_test1`, registrado y luego eliminado sin dejar rastro.
- [x] Estadisticas: confirmado que ahora muestra 3 stats (Creditos activos
  / Cupo disponible / Total pagado), no 6 — la version anterior que parecia
  mostrar el bug era el APK viejo, no un error de codigo.
- [x] Dashboard: confirmado que la fila de accesos rapidos ya no aparece
  (se habia revertido a pedido del usuario en la sesion anterior); "¿Que
  pasa si...?" sigue presente al final.

**NO alcanzado a verificar por limite de tiempo (queda para la proxima
sesion con el usuario presente):**
- [ ] Animacion de slide completo entre pasos del asistente (420ms) — se
  ve el cambio de contenido correctamente, pero no se confirmo visualmente
  el movimiento de la animacion en si.
- [ ] Fade de apertura/cierre de "Nuevo Credito" (340ms).
- [ ] Widget de pantalla de inicio — requiere agregarlo manualmente al home
  screen del telefono, no se hizo en esta ventana.
- [ ] Rediseno de `NotificationSettingsTile` en Cuenta y en la Bienvenida.

Reporte completo (con este mismo contenido) tambien publicado como seccion
nueva en el Artifact de auditoria:
https://claude.ai/artifact/Jts8sQnuDMhZbCtSE55ybt

### Bug real encontrado tras perder conexion con el dispositivo — corregido

Despues de la ventana de 10 minutos, `flutter run` perdio la conexion con
el telefono ("Lost connection to device" — no fue un crash de la app, la
sesion de debug se corto, probablemente por bloqueo de pantalla/USB durante
la reunion). Revisando el log de esa corrida aparecio una excepcion real de
Flutter, no fatal pero real:

- [x] **Corregido:** `ListTile background color or ink splashes may be
  invisible` — dos ListTile (el "¿Que pasa si...?" en
  `dashboard_screen.dart` y "Como funciona Kredit" en `account_screen.dart`)
  viven dentro de `KreditSectionCard`, que pinta su fondo con un
  `DecoratedBox` en vez de un `Material`. El ink splash del `ListTile` pinta
  sobre el `Material` ancestro mas cercano (mucho mas arriba en el arbol,
  detras de esa caja), asi que el splash del tap quedaba invisible. Arreglo
  aplicado en ambos: envolver el `ListTile` en un `Material(color:
  Colors.transparent, child: ...)` justo antes de el, para que el splash
  pinte encima del `DecoratedBox` como corresponde. `flutter analyze` (0
  issues) y `flutter test` (128/128) verificados despues del fix.
- Nota para GPT: si aparece este mismo warning en OTRO ListTile dentro de
  un `KreditSectionCard` en el futuro (o en cualquier widget que use
  `DecoratedBox`/`Container` con color en vez de `Material`), es el mismo
  patron — envolver ese `ListTile` (o el widget con `InkWell`/splash) en un
  `Material(color: Colors.transparent, ...)`.

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
