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

Objetivo: convertir la pantalla de detalle en el lugar donde el usuario entiende
el estado real de un credito y decide que hacer.

Archivos probables:

- `lib/screens/credit_detail/credit_detail_screen.dart`
- `lib/screens/credit_detail/tabs/summary_tab.dart`
- `lib/screens/credit_detail/tabs/installments_tab.dart`
- `lib/screens/credit_detail/tabs/movements_tab.dart`
- `lib/domain/credit_calculator.dart`
- `lib/domain/loan_calculator.dart`
- `lib/domain/card_calculator.dart`

Requisitos:

- Para prestamos/cupos:
  - mostrar saldo pendiente como dato principal;
  - mostrar proxima cuota, fecha y estado;
  - mostrar progreso de cuotas con una pieza visual clara;
  - destacar si hay cuotas vencidas;
  - mantener acciones principales visibles: registrar pago, abonar, simular.
- Para tarjetas:
  - mostrar saldo actual, cupo disponible, uso de cupo y fecha limite;
  - destacar uso alto de cupo;
  - mostrar corte y proximo pago en lenguaje simple;
  - mantener acciones principales visibles: registrar movimiento/pago,
    simular impacto si aplica.
- Evitar saturar:
  - una tarjeta principal arriba;
  - acciones claras;
  - informacion secundaria en secciones compactas.
- Si se agrega logica nueva de estado, moverla a `lib/domain/` y testearla.

Criterios de aceptacion:

- El usuario puede responder en menos de 5 segundos cuanto debe, cuando vence
  lo proximo y que accion puede hacer ahora.
- `flutter analyze` sin issues.
- `flutter test` pasando.

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

### Tarea 5 para Cloud: Motor avanzado de recomendaciones

Objetivo: fortalecer `lib/domain/recommendations.dart` para que alimente
dashboard, detalle y estadisticas.

Reglas pendientes:

- [ ] Deuda mas costosa.
- [ ] Tarjeta con uso alto.
- [ ] Credito ideal para abonar.
- [ ] Riesgo por mora acumulada.
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
- [ ] Deuda mas costosa.
- [ ] Tarjeta con uso alto.
- [ ] Credito ideal para abonar.
- [x] Pagos proximos.
  - Implementado como lista de `PendingPayment`, reusable fuera del dashboard.
- [x] Riesgo por mora o vencimiento.
  - Implementado por severidad `danger`/`warning` segun dias de vencimiento.

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
