# Kredit — cómo funciona

Kredit es una app (PWA) 100% local para llevar el control de tus créditos colombianos —
tarjetas y préstamos/cupos — sin cuentas, sin nube, sin servidor. Todo vive en tu navegador
(IndexedDB vía Dexie), y funciona sin internet una vez cargada la primera vez.

Este archivo es la referencia de flujo/funcionamiento. El mismo contenido está disponible
dentro de la app en **Cuenta → Cómo funciona Kredit**.

## Los dos tipos de crédito

Kredit distingue dos tipos porque no funcionan igual en la vida real:

- **Préstamo / Cuotas Fijas**: compras algo (nevera, celular, auto) y pagas cuotas iguales
  con fecha de fin definida. El interés ya viene prorrateado en la cuota — si pagas una cuota
  antes de tiempo, esa cuota puntual no te cobra interés extra (como funcionan YOI, CrediPink
  y créditos de consumo similares).
- **Tarjeta de Crédito**: saldo que sube y baja, con fecha de corte (cuándo cierra el mes) y
  fecha límite (cuándo vence el pago), interés que se acumula día a día sobre el saldo
  (E.A./365 × días transcurridos), y cuota de manejo opcional.

La app reconoce automáticamente 11 entidades colombianas (Nequi, Bancolombia, Nu, Davivienda,
DaviPlata, BBVA, Rappi, Lulo, Banco de Bogotá, Falabella, Colpatria) y les aplica el diseño y
color real de marca en la tarjeta visual. Si escribes "Nequi" o "DaviPlata" como banco al elegir
tipo "Tarjeta", la app te avisa que esos productos suelen ser de cuota fija, no tarjeta rotativa
real (DaviPlata sí tiene una tarjeta rotativa nueva desde 2025, separada de su Nanocrédito de
cuota fija — por eso el aviso es una aclaración, no una regla fija).

> El interés de tarjetas se estima con interés simple diario (E.A./365) — es la aproximación
> estándar, pero cada banco puede aplicar promociones o su propia metodología de facturación
> que esta app no puede replicar exactamente sin acceso a tu estado de cuenta real.

## Las 3 pantallas principales

1. **Dashboard**: resumen de deuda total, carrusel de tus tarjetas activas (estilo Google
   Wallet), y los próximos 4 vencimientos con link a "Ver todos" si hay más.
2. **Créditos**: lista completa, buscable y ordenable (por próximo pago, mayor/menor deuda,
   nombre), con tabs Activos/Pagados.
3. **Cuenta**: tu perfil, estadísticas generales, personalización (color de acento y tono de
   fondo), y herramientas de datos (exportar/importar JSON, borrar todo).

## Flujo típico

**Agregar un crédito**: tocas el botón "+" → eliges tipo de crédito → llenas los datos → se
guarda localmente. Para un préstamo pides monto financiado, cantidad de cuotas y valor de
cuota; para una tarjeta pides cupo total, saldo actual, día de corte, días hasta fecha límite
y tasa de interés E.A.

**Pagar**: en un préstamo, marcas la cuota puntual (o usas "Registrar pago total" para saldar
todo de una vez); en una tarjeta, registras un "Cargo/Compra" o un "Pago" desde su detalle —
la app recalcula el saldo e interés automáticamente.

**Detalle de un crédito**: cada crédito tiene 3 tabs —
- **Resumen**: tarjeta visual + cifras clave (pendiente, monto financiado/cupo, interés, cuota).
- **Notas**: dónde se compró, con qué tarjeta/cuenta se paga, comentarios libres.
- **Cronograma** (préstamos) / **Movimientos** (tarjetas): cuotas pendientes y pagadas, o
  historial de cargos/pagos/intereses/cuotas de manejo.

**Datos**: puedes exportar todo a un archivo JSON de respaldo, e importarlo después (te pide
confirmación antes de reemplazar los datos actuales). "Borrar Base de Datos" en Zona de
Peligro elimina todo de forma permanente, con doble confirmación.

## Offline real

Un Service Worker (Workbox) cachea toda la app (HTML/CSS/JS/fuentes) la primera vez que la
abres — después funciona sin señal, incluso instalada como app en el celular (PWA).

## Créditos de ejemplo

Al abrir la app por primera vez ves 2 créditos marcados con el badge "Ejemplo" — son datos
de muestra para que veas cómo se ve todo funcionando, no son deuda real. Puedes editarlos,
pagarlos o borrarlos como cualquier otro crédito.
