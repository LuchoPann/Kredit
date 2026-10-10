YO: Chat, yo no sé si tú conoces a la empresa Lily Pink, que tiene una subempresa llamada Joy. necesito que me digas cómo manejan ellos los intereses en su cupo de Joy.

CHATGPT: Sí, Lucho. Estuve revisando información actual de **Lili Pink / Joy** y hay un detalle importante: el producto de crédito que aparece documentado oficialmente por Lili Pink se llama **CrediPink**, y la forma en que manejan el interés es un poquito distinta a una tarjeta de crédito tradicional.

Según su centro de ayuda oficial:

* Te pueden asignar inicialmente un **cupo de $200.000**.
* Las compras se pueden diferir **hasta en 6 meses**.
* Se cobra **interés corriente** sobre el crédito.
* Ese interés se genera incluso si pagas **exactamente el día del vencimiento**.
* **Si pagas antes de la fecha de vencimiento, no te cobran intereses** y el dinero pagado se abona al capital de la siguiente cuota.
* No cobran **intereses de mora**, aunque sí mencionan otros costos, específicamente el **aval** asociado al crédito. ([conocimiento.lilipink.com][1])

### Lo interesante es cómo funciona matemáticamente

Por lo que describe Lili Pink, parece funcionar más como un **crédito de compra diferido** que como una tarjeta de crédito convencional.

Por ejemplo, supongamos que compras:

**$200.000 a 6 cuotas**

El sistema determina una cuota mensual que incluye:

> **Capital + interés corriente + eventualmente el costo del aval**

Pero si haces el pago **antes de la fecha límite**, Lili Pink indica que no se generan intereses y ese pago se aplica al capital de la siguiente cuota. ([conocimiento.lilipink.com][1])

Esto es bastante importante porque significa que **la fecha de pago cambia el costo real del crédito**.

---

### Pero hay algo que no pude confirmar

La página oficial que encontré **no publica la tasa exacta de interés corriente**. Dice explícitamente que se aplica interés corriente, pero no indica algo como:

> 2,XX % mensual
> 28,XX % E.A.

Por eso no te quiero inventar una tasa.

Y hay otra cosa que me parece especialmente interesante: encontré documentación antigua relacionada con créditos de **Lili Pink/Roland** donde aparecen conceptos como *interés diferido*, *interés de mora* y tasas vinculadas al segmento de consumo, pero eso corresponde a otro esquema/documentación y **no sería correcto asumir que es exactamente el mecanismo actual de Credipink**. ([Scribd][2])

Si tú me preguntas esto porque **quieres comparar el funcionamiento de Joy con Kredit**, ahí sí se pone interesante 👀. Puedo investigar específicamente **qué entidad financiera respalda el cupo Joy, cuál es la tasa vigente, cómo calculan el interés día a día/cuota a cuota, el aval, qué pasa cuando haces abonos anticipados y cómo queda el cupo disponible**, y con eso te puedo reconstruir prácticamente la fórmula que utilizan.

[1]: https://conocimiento.lilipink.com/centro-de-ayuda/adquiere-tu-credipink?utm_source=chatgpt.com "Adquiere tu Credipink Lili Pink & Yoi 💳"
[2]: https://www.scribd.com/document/871412367/Estado-de-Cuenta-Roland-Lilipink?utm_source=chatgpt.com "Estado de Cuenta Lili Pink y Roland | PDF | Economias"

YO: Va, investiga para ver

CHATGPT: Sí, Lucho. Me puse a buscarlo más a fondo y encontré algo bastante interesante. Hay que hacer una distinción porque **no estoy encontrando documentación pública actual que llame al producto “Cupo Joy”**. Lo que aparece oficialmente hoy es **CrediPink**, el crédito de Lili Pink & Yoi. ([LiliPink Conocimiento][1])

### Lo que pude confirmar

El esquema actual de CrediPink funciona así:

| Concepto        | Cómo funciona                                                         |
| --------------- | --------------------------------------------------------------------- |
| Cupo inicial    | $200.000                                                              |
| Cupo posterior  | Puede subir hasta $400.000 después de 3 meses con buen comportamiento |
| Plazo           | Hasta 6 cuotas mensuales                                              |
| Interés         | **Interés corriente**                                                 |
| Mora            | No cobran intereses de mora                                           |
| Pago anticipado | No se cobran intereses                                                |
| Aval            | Sí, se cobra por cada compra                                          |
| Amortización    | Se puede consultar el detalle de capital/cuotas                       |

Todo esto está descrito en el centro de ayuda oficial de Lili Pink. ([LiliPink Conocimiento][1])

Pero encontré **la pieza que faltaba: la tasa**.

### 🔎 La tasa aparentemente es 3,4% mensual

Encontré un material de **formación interna de personal de Lili Pink** publicado en Educaplay. No es una página financiera oficial, así que hay que tomarlo como evidencia secundaria, pero es bastante revelador.

El material pregunta específicamente:

> ¿Cuál es la tasa de interés corriente mensual de CrediPink?

Y las opciones son **3,4%, 4,3% o no se cobra interés corriente**. ([Educaplay][2])

Además, el mismo material pregunta por el porcentaje del aval y pone **9,9%** como una de las opciones. ([Educaplay][2])

Eso hace bastante plausible que el esquema que manejan sea:

**3,4% mensual de interés corriente + aval**

Pero **no tomaría el 3,4% y 9,9% como cifras contractuales definitivas sin ver el pagaré/T&C vigente**, porque el material no es el contrato.

---

### Y aquí viene lo más interesante para tu Kredit 👀

La documentación oficial dice algo aparentemente contradictorio a primera vista:

> Si pagas antes del vencimiento, **no se cobran intereses**.

Mientras que si pagas el mismo día del vencimiento, **sí se genera el interés corriente**. ([LiliPink Conocimiento][1])

Esto significa que **no parece ser simplemente "3,4% × saldo restante cada mes"**.

El comportamiento sería más parecido a:

**Compra → se genera una obligación → se programa una cuota → si pagas anticipadamente, evitas el interés correspondiente → si esperas hasta el vencimiento, se causa el interés.**

Y cuando haces pago total, Lili Pink indica que el valor incluye:

**capital pendiente + intereses generados + aval**. ([LiliPink Conocimiento][3])

Además, su sistema tiene una sección llamada **"Ver amortización"**, donde muestran las cuotas diferidas y su desglose. ([LiliPink Conocimiento][4])

---

### Encontré además un pagaré real de CrediPink

Hay un documento de 2024 asociado a **Fast Moda S.A.S.**, la sociedad que opera Lili Pink, donde aparece una compra de **$126.500** financiada en seis pagos.

En ese documento aparece:

* Capital: $126.500
* Interés: **3% mensual**
* Tasa equivalente: **1,5% quincenal**
* 6 pagos de aproximadamente $21.083 de capital
* $1.898 de intereses por cuota
* Sin intereses de mora

Es decir, en ese documento histórico el mecanismo era explícitamente **interés fijo sobre el capital original**, no un cálculo tipo tarjeta de crédito sobre saldo diario. ([Scribd][5])

De hecho:

**$126.500 × 3% = $3.795**

y dividido en dos quincenas:

**$3.795 / 2 = $1.897,50**

que coincide prácticamente exactamente con los **$1.898** que aparecen en cada cuota.

Eso es una pista MUY buena de cómo estructuraban el crédito anteriormente.

---

### Entonces, para entenderlo en términos de Kredit

Hay dos modelos diferentes que no deberíamos mezclar:

**Modelo histórico encontrado en el pagaré:**

> Interés = capital financiado × 3% mensual

Por ejemplo:

$126.500 × 3% = **$3.795 de interés mensual**

Si fueran 6 meses:

$3.795 × 6 = **$22.770 de interés**

más el capital.

Mientras que el material más reciente apunta a una tasa de **3,4% mensual**, por lo que parece que **la tasa cambió posteriormente**. ([Educaplay][2])

Y esto tiene una implicación importante para tu proyecto: **Kredit no debería asumir que todos los créditos de "cuotas fijas" calculan interés sobre saldo insoluto como lo haría un crédito bancario tradicional**. Hay comercios que calculan interés sobre el capital inicial y lo distribuyen entre las cuotas.

Eso cambia muchísimo el valor final.

**Mi siguiente paso sería reconstruir exactamente el algoritmo de CrediPink actual** —incluyendo 3,4%, aval, pago anticipado y cómo queda la amortización— y compararlo directamente con la lógica que tienes planteada para **Kredit**.

[1]: https://conocimiento.lilipink.com/centro-de-ayuda/adquiere-tu-credipink?utm_source=chatgpt.com "Adquiere tu Credipink Lili Pink & Yoi 💳"
[2]: https://www.educaplay.com/learning-resources/26274563-reto_lili_pongamos_a_prueba_lo_aprendido.html?utm_source=chatgpt.com "Froggy Jumps: Reto Lili: ¡Pongamos a prueba lo aprendido! (formación de personal)"
[3]: https://conocimiento.lilipink.com/centro-de-ayuda/pago-total-credipink?utm_source=chatgpt.com "Pago total credipink"
[4]: https://conocimiento.lilipink.com/centro-de-ayuda/estado-credipink?utm_source=chatgpt.com "Estado credipink (cupo, saldo y situación general)"
[5]: https://fr.scribd.com/document/800968468/Pagare-Adjunto?utm_source=chatgpt.com "Pagare Adjunto | PDF | Pagos | Crédito"

YO: Entiendo. Bueno, mira, también te digo que no solo Joy tiene un parecido, sino que también Toto, la marca Toto, tiene recientemente un sistema también como de cupo parecido al de Joy. Entonces no sé si me ayudas investigando sobre Toto y ese nuevo sistema de cupos que tienen, que se parece al de Joy, pero no estoy seguro de cómo funciona en sí.

CHATGPT: Sí, Lucho. Y creo que ya encontré exactamente a qué te refieres: **Totto** (con doble T) tiene un sistema llamado **Keypago**, y efectivamente se parece bastante a lo que me estabas describiendo de Joy.

Lo interesante es que **Keypago está bastante mejor documentado públicamente**, así que podemos reconstruir cómo funciona.

### 🟢 ¿Qué es el “cupo” de Totto?

Keypago es un producto de crédito de **Credifactory S.A.S.**, no una tarjeta de crédito. El cupo funciona como una línea reutilizable para comprar en tiendas físicas autorizadas de **Totto y Topara**. ([qaw.keypago.com][1])

Por ejemplo:

> Te aprueban un cupo de $700.000

Compras un morral de:

> $300.000

Tu cupo disponible queda aproximadamente en:

> $400.000

Y esa compra de $300.000 se convierte en **un crédito independiente**.

Después puedes volver a comprar con los $400.000 restantes, generando otro crédito independiente. ([qaw.keypago.com][1])

Y cuando haces pagos que reduzcan el capital, **se libera nuevamente esa parte del cupo**. ([qaw.keypago.com][1])

Eso es muy parecido al concepto que estás viendo en Joy.

---

## 💰 ¿Cuánto cupo dan?

Actualmente, los términos publicados indican:

* **Clientes nuevos:** entre $100.000 y $700.000
* **Clientes existentes:** hasta $900.000
* El cupo tiene una vigencia de **90 días**
* No tiene cuota de manejo
* No es una tarjeta
* Si no utilizas el cupo aprobado, no genera endeudamiento reportado
* El cupo puede ser aumentado, reducido, bloqueado o desbloqueado según el perfil de riesgo del cliente. ([qaw.keypago.com][1])

Y aquí hay una diferencia importante frente a una tarjeta de crédito tradicional:

**el cupo no es el crédito.**

El cupo es la capacidad disponible y **cada compra genera su propio crédito**.

---

# 📈 ¿Y los intereses?

Aquí encontré algo bastante bueno.

Keypago establece que la tasa remuneratoria:

> es fija y corresponde a la tasa vigente al momento de realizar cada crédito.

Además, nunca puede superar la tasa máxima legal colombiana para crédito de consumo y ordinario. ([qaw.keypago.com][2])

En los términos publicados aparece como referencia para **julio de 2025**:

**1,84% mensual vencido**

equivalente a:

**24,46% efectivo anual.** ([qaw.keypago.com][2])

La tasa de mora publicada para ese mismo mes era:

**1,86% mensual vencido / 24,78% E.A.** ([qaw.keypago.com][2])

Ojo: **esas son tasas históricas de julio de 2025**, no te las presentaría como la tasa vigente de septiembre de 2026. Los términos dicen que la tasa se determina según la vigente al momento de generar el crédito.

---

# 🧮 Y tienen algo MUY parecido a Joy

Aquí está la parte que creo que te va a interesar más para **Kredit**.

Keypago tiene un **beneficio por pronto pago**.

Si compras algo y luego haces **el pago total del crédito en un solo pago como máximo un día antes del vencimiento de la primera cuota**, entonces:

**no te cobran intereses**

y además:

**no te cobran la fianza.**

Pero hay una diferencia importantísima:

### Pago total anticipado

Si pagas todo antes de esa fecha:

> Capital + **$0 intereses** + **$0 fianza**

### Pago parcial anticipado

Si haces solamente un abono:

> se cobra la **fianza completa**
>
> * los intereses corrientes generados hasta la fecha del pago

Esto está explícitamente establecido en los términos de Keypago. ([qaw.keypago.com][2])

Eso explica bastante bien el comportamiento que te estaba comentando antes con Joy.

---

# 🛡️ También tienen una fianza del 10%

Este es otro punto importante.

Cada crédito tiene una **fianza proporcionada por FGA Fondo de Garantías**.

El costo publicado es:

**10% del valor del crédito, IVA incluido.**

Y se distribuye uniformemente entre las cuotas.

Por ejemplo, hipotéticamente:

**Compra:** $300.000

**Fianza:** $30.000

Ese $30.000 se distribuye entre las cuotas del crédito.

Y algo importante:

> **Sobre la fianza no se cobran intereses de financiación.** ([qaw.keypago.com][2])

Por eso el costo real del crédito no es simplemente:

> $300.000 + intereses

sino algo más parecido a:

> **Capital + intereses + fianza**

---

# 🔥 Y mira esta similitud

Si juntamos lo que hemos encontrado:

| Característica                           | Keypago / Totto                   |
| ---------------------------------------- | --------------------------------- |
| Cupo reutilizable                        | ✅                                 |
| Cada compra genera crédito independiente | ✅                                 |
| Pago libera cupo                         | ✅                                 |
| Tarjeta física                           | ❌                                 |
| Cuota de manejo                          | ❌                                 |
| Plazo                                    | Hasta 6 meses                     |
| Interés                                  | Sí                                |
| Fianza                                   | 10%                               |
| Pago total muy anticipado                | Puede eliminar intereses + fianza |
| Pago parcial anticipado                  | Sí genera intereses + fianza      |
| Mora                                     | Sí                                |
| Reporte a centrales                      | Sí cuando utilizas el crédito     |
| Administrador del crédito                | Credifactory                      |
| Comercio                                 | Totto / Topara                    |

Todo esto está descrito en los términos de Keypago. ([qaw.keypago.com][2])

---

## 🧠 Hay algo todavía más interesante

La estructura de Keypago me parece **muy cercana a la arquitectura que tú estabas planteando para Kredit**.

Tienes conceptualmente:

```text
                 CUPO
                  │
        ┌─────────┴─────────┐
        │                   │
     Compra 1            Compra 2
     $300.000             $150.000
        │                   │
     Crédito A           Crédito B
     6 cuotas             3 cuotas
        │                   │
     intereses           intereses
     fianza              fianza
```

Y el cupo disponible sería algo como:

```text
Cupo aprobado
    - capital utilizado
    + capital amortizado
    = cupo disponible
```

Es decir, **no deberías tratar el cupo como una deuda**.

El cupo es una capacidad.

La deuda son los créditos que nacen de las utilizaciones.

Y eso, para Kredit, es una distinción de arquitectura de datos bastante importante.

Además, Keypago deja claro que los pagos se aplican **horizontalmente**, es decir, siguiendo un orden determinado sobre las cuotas y conceptos del crédito. ([qaw.keypago.com][2])

---

### Una última cosa que me parece clave

La similitud entre **Joy/CrediPink y Keypago** probablemente no significa que uno copie al otro. Lo que parece estar ocurriendo es que **varios comercios colombianos están utilizando modelos de “cupo de crédito + créditos independientes por compra”**, en lugar de crear una tarjeta de crédito convencional.

Y para tu investigación de **Kredit**, esto es oro porque podemos estudiar **tres modelos distintos**:

**CrediPink/Joy →** crédito de tienda
**Keypago/Totto →** cupo reutilizable + créditos independientes
**Tarjeta de crédito tradicional →** cupo revolvente + saldo/interés según reglas de tarjeta

Si quieres, puedo hacerte ahora una **comparación técnica de Joy vs Keypago vs una tarjeta de crédito colombiana**, incluyendo las fórmulas de intereses, anticipos, liberación del cupo, fianza/aval y cómo debería modelarse cada uno en Kredit.

[1]: https://www.qaw.keypago.com/terminos-y-condiciones?utm_source=chatgpt.com "Landing Terminos y condiciones"
[2]: https://qaw.keypago.com/terminos-y-condiciones?utm_source=chatgpt.com "Landing Terminos y condiciones"

YO: Es que ese es el punto. Yo me doy cuenta que Totto y Joey tienen su propio crédito, pero es interno, es de la propia empresa, digamos así. Entonces no es un cupo como tal porque, por ejemplo, Nequi sí da un cupo, pero lo puedes usar en cualquier parte y es de Nequi, no es de otra empresa. Entonces, por ejemplo, Toto tiene su cupo, pero es solo Totto. No se puede usar en otro lado, solo en Totto. Entonces eso es lo que yo me pregunto, cómo podemos implementarlo dentro de credit.

CHATGPT: Sí, exacto. Y ahí está la distinción que creo que te estaba faltando para **Kredit**: **un cupo no necesariamente tiene que ser un producto financiero universal**. Puede ser una **línea de crédito restringida a un comercio o ecosistema**.

De hecho, lo que encontré de Keypago confirma exactamente esa estructura: el cupo pertenece a Credifactory, pero **solo puede utilizarse para comprar en tiendas Totto y Topara autorizadas**. Cada utilización genera un crédito independiente y los pagos sobre el capital vuelven a liberar disponible del cupo. ([qaw.keypago.com][1])

Y CrediPink hace algo conceptualmente parecido: asigna un cupo para utilizarlo en Lili Pink/Yoi y cada compra se financia en cuotas. ([LiliPink Conocimiento][2])

## Entonces, ¿cómo lo metería en Kredit?

Yo **no cambiaría el concepto de "Tarjeta de Crédito" que ya tienes**. Crearía un tercer tipo de producto:

### `Cupo comercial`

Y tendría una estructura más o menos así:

```text
                    KREDIT
                       │
             ┌─────────┼─────────┐
             │         │         │
          Préstamo   Tarjeta   Cupo comercial
             │         │         │
          crédito   crédito    cupo
          cerrado   revolvente restringido
                                │
                    ┌───────────┼───────────┐
                    │           │           │
                  Totto       Joy       Otro comercio
                    │           │
                 compras     compras
                    │           │
                 créditos    créditos
```

La clave es que **el cupo comercial no es una deuda**.

Es una capacidad de financiación.

---

# La estructura que yo usaría

Por ejemplo, imagina que agregas:

### 🛍️ Cupo Totto

```text
Cupo aprobado
$700.000

Disponible
$700.000

Utilizado
$0
```

Compras un morral de:

**$250.000**

Kredit crea internamente:

```text
Cupo Totto
├── Límite: $700.000
├── Disponible: $450.000
│
└── Crédito #001
    ├── Compra: $250.000
    ├── Plazo: 6 meses
    ├── Capital pendiente: $250.000
    ├── Intereses
    ├── Fianza
    └── Estado: Activo
```

Después compras otra cosa por $100.000:

```text
Cupo Totto
├── Límite: $700.000
├── Disponible: $350.000
│
├── Crédito #001 → $250.000
└── Crédito #002 → $100.000
```

Eso es **prácticamente la arquitectura que describen los términos de Keypago**. ([qaw.keypago.com][1])

---

# Y aquí viene una decisión importante para Kredit

Yo separaría tres conceptos:

### 1. Proveedor

Quién administra el crédito.

```text
Credifactory
Fast Moda
Otro
```

### 2. Comercio / marca

Dónde puedes utilizarlo.

```text
Totto
Topara
Lili Pink
Yoi
```

### 3. Producto financiero

Qué tipo de crédito es.

```text
Préstamo
Tarjeta
Cupo comercial
```

Así no amarras el sistema.

Porque mira el caso de Totto:

```text
Proveedor financiero:
Credifactory

Producto:
Cupo comercial

Comercios autorizados:
Totto + Topara
```

Eso está literalmente reflejado en los términos de Keypago: Credifactory ofrece el cupo y este puede utilizarse en Totto y Topara autorizadas. ([qaw.keypago.com][1])

---

# ¿Y Joy?

Ahí podrías hacer:

```text
Proveedor:
Fast Moda S.A.S.

Producto:
Cupo comercial

Comercios autorizados:
Lili Pink
Yoi

Nombre comercial:
CrediPink
```

Y nuevamente tendrías:

```text
Cupo
  ↓
Compra
  ↓
Crédito independiente
  ↓
Cuotas
  ↓
Pago
  ↓
Liberación de capital
  ↓
Cupo disponible
```

La propia documentación de Lili Pink confirma que el cupo se utiliza para compras en Lili Pink/Yoi y que el aval se aplica a cada compra. ([LiliPink Conocimiento][2])

---

# Esto además resuelve algo que me preocupaba de Kredit

Si simplemente metieras Joy o Totto dentro de **"Tarjeta de crédito"**, estarías modelando mal el producto.

Porque una tarjeta normalmente sería:

```text
Límite: $2.000.000

Compra $300.000
↓
Saldo utilizado: $300.000
↓
Otra compra $200.000
↓
Saldo utilizado: $500.000
```

Mientras que estos productos funcionan conceptualmente como:

```text
Cupo: $700.000
        │
        ├── Compra A → Crédito A
        │               └── 6 cuotas
        │
        ├── Compra B → Crédito B
        │               └── 3 cuotas
        │
        └── Compra C → Crédito C
                        └── 4 cuotas
```

Son **varias obligaciones independientes asociadas a una misma capacidad de crédito**.

Eso es mucho más parecido a lo que documenta Keypago. ([qaw.keypago.com][1])

---

## Y yo agregaría algo más a Kredit

Una entidad `Cupo` podría tener:

```text
Cupo
├── id
├── nombre
├── proveedor
├── comercio
├── límite
├── disponible
├── fecha_aprobación
├── fecha_vencimiento
├── estado
├── tasa_interés
├── costo_aval/fianza
└── créditos[]
```

Mientras que cada `Crédito` tendría:

```text
Crédito
├── id
├── cupo_id
├── fecha_compra
├── valor_compra
├── capital
├── tasa
├── plazo
├── interés
├── aval/fianza
├── cuota
├── saldo_capital
├── fecha_vencimiento
└── amortización[]
```

Y eso te permitiría representar perfectamente:

**Totto → Keypago → cupo $700k → compra $250k → crédito de 6 meses**

sin contaminar la lógica de las tarjetas.

---

### Lo más bacano

Esto incluso permite que **Kredit no tenga que conocer específicamente a Totto, Joy, Nequi, etc.**

La aplicación solamente conoce:

> **"Este es un cupo comercial restringido a determinados comercios"**

Y el usuario configura:

> **Totto — Keypago — $700.000**

o

> **Lili Pink — CrediPink — $400.000**

o incluso:

> **Mi tienda — Crédito propio — $500.000**

Eso convierte a Kredit en algo mucho más flexible: no estás programando "Totto" o "Joy", estás programando **el patrón financiero que utilizan**.

Y honestamente, para el objetivo que tú tenías con Kredit, **yo sí añadiría este tercer tipo de crédito** en lugar de intentar meter estos productos a la fuerza dentro de tarjeta de crédito.

[1]: https://www.qaw.keypago.com/terminos-y-condiciones?utm_source=chatgpt.com "Landing Terminos y condiciones"
[2]: https://conocimiento.lilipink.com/centro-de-ayuda/adquiere-tu-credipink?utm_source=chatgpt.com "Adquiere tu Credipink Lili Pink & Yoi 💳"

YO: Podrías ayudarme investigando todas las tiendas de colobia que contienen cupos propios y todas las entidades bancarias de Colombia que den creditos y tambien cupos/prestamos?

CHATGPT: Sí, Lucho. Y para **Kredit** te conviene muchísimo hacer este inventario, pero con una precisión: **“todas las tiendas de Colombia” literalmente sería un universo enorme y además cambia constantemente**. Lo correcto es construir un catálogo de los **modelos de financiación/cupo relevantes y verificables**, y luego ampliar por sectores.

Hice una revisión con información vigente en 2026 y ya aparecen varios patrones interesantes.

## 1. Primero: hay 4 tipos distintos que Kredit debería diferenciar

No metería todo bajo “cupo”.

| Tipo                           | Ejemplo          | ¿Dónde se usa?                      | ¿Qué genera?             |
| ------------------------------ | ---------------- | ----------------------------------- | ------------------------ |
| **Cupo comercial restringido** | Totto/Keypago    | Solo comercio/ecosistema autorizado | Uno o varios créditos    |
| **Cupo comercial de cadena**   | CrediÉxito       | Solo Éxito                          | Crédito rotativo         |
| **Cupo multi-comercio**        | Addi             | Miles de comercios aliados          | Créditos por compra      |
| **Cupo financiero general**    | BBVA/Bancolombia | Según producto                      | Crédito/consumos/avances |

Esto es importantísimo porque **Totto y Éxito pueden parecer iguales desde fuera, pero técnicamente no son idénticos**.

---

# 🛍️ 2. Comercios/cadenas con financiación propia o restringida

### 🟢 Totto / Topara — Keypago

Este es el caso que ya veníamos estudiando.

**Proveedor:** Credifactory S.A.S.
**Marca del producto:** Keypago
**Comercios:** Totto y Topara
**Cupo:** $100.000–$700.000 para nuevos clientes y hasta $900.000 para existentes, según los términos publicados.
**Modelo:** cada utilización genera un crédito independiente y los pagos de capital vuelven a liberar cupo. ([qaw.keypago.com][1])

Totto actualmente incluso presenta Keypago junto con Addi y Sistecrédito como medios de financiación. ([Totto Colombia][2])

**Para Kredit:** `Cupo comercial restringido → múltiples créditos`.

---

### 🟢 Éxito — CrediÉxito

Este es especialmente interesante.

**Proveedor:** Tuya S.A.
**Producto:** CrediÉxito
**Uso:** únicamente en Almacenes Éxito.
**Cupo publicado:** $300.000 hasta $5.550.000 en una de las modalidades publicadas.
**Plazos:** 1–36 cuotas.
**Modelo:** el cupo se renueva a medida que pagas. ([Tuya][3])

La página de CrediÉxito lo describe expresamente como **crédito rotativo de consumo de bajo monto** y señala que cada pago libera nuevamente el cupo. 

Aquí Kredit debería registrar:

```text
Cupo Éxito
├── Límite
├── Disponible
├── Saldo utilizado
└── Créditos/compras
```

Pero a diferencia de Keypago, el producto está estructurado explícitamente como **crédito rotativo**.

---

### 🟢 Éxito — CrediCompras

Tuya también tiene **CrediCompras** para compras específicas en Éxito.

Publica:

* Cupo de $200.000 a $15 millones
* 3, 6, 12, 18, 24 o 36 meses
* Cuota de manejo $0
* Cuotas fijas
* Uso en categorías como tecnología, electrodomésticos, muebles, colchones, llantas, bicicletas, motos y movilidad eléctrica. ([Tuya][4])

Este sería otro producto que Kredit debería poder representar aunque pertenezca al mismo ecosistema.

---

### 🟢 Brilla

Aquí se abre otro mundo.

**Brilla** funciona mediante empresas de servicios públicos y permite utilizar un cupo para financiar productos y servicios en comercios aliados.

Por ejemplo, **Brilla Efigas** actualmente permite financiar productos y publica una tasa mensual vencida de **2,16% para septiembre de 2026**. ([Brilla Efigas][5])

En **Brilla Gases de Occidente**, los términos describen expresamente el producto como un **cupo rotativo**, con cuotas calculadas sobre el saldo actual y una tasa variable dentro de los límites legales. ([Brilla - Cupo de Crédito][6])

Y esto es particularmente interesante porque **Brilla no es una tienda**:

```text
Empresa de servicios
        ↓
      BRILLA
        ↓
      CUPO
        ↓
Comercios aliados
        ↓
    Compra/crédito
```

Es decir, para Kredit conviene que el “proveedor del cupo” y los “comercios donde se utiliza” sean entidades separadas.

---

### 🟡 Homecenter

Homecenter tiene varias modalidades de financiación, por ejemplo **CMR Falabella, Codensa, Colsubsidio, crédito directo, Brilla y Crediuno**. ([Homecenter][7])

Aquí ya no podemos decir simplemente “Homecenter tiene un cupo propio”, porque diferentes productos pertenecen a diferentes entidades.

Por ejemplo, el crédito Colsubsidio permite comprar en Homecenter y también utilizarse en otros servicios de la caja. ([Homecenter][7])

Eso refuerza muchísimo la arquitectura que te estaba proponiendo.

---

### 🟡 Alkosto / Ktronix

Tienen financiación mediante **Tarjeta Alkosto**, administrada por Tuya, y actualmente también ofrecen Addi.

La información de Tuya indica que la alianza Alkosto–Tuya lleva años financiando compras en Alkosto y Ktronix. ([Tuya][8])

Pero **no la clasificaría como cupo comercial restringido puro**, porque la tarjeta Alkosto tiene alcance mucho mayor que solamente Alkosto/Ktronix.

---

### 🟡 Falabella

CMR es otro caso híbrido.

La tarjeta CMR tiene un cupo, puede utilizarse en miles de comercios aliados y ofrece plazos de compra; además existen extracupos puntuales según comportamiento. 

Por tanto:

**No sería:**

> Cupo Falabella = solo Falabella

sino:

> Tarjeta/cupo financiero + ecosistema Falabella + comercios aliados.

---

# 🟢 3. Addi

Este es probablemente el ejemplo más importante para entender la diferencia.

Addi actualmente habla explícitamente de un **“Cupo”** y de un **“Crédito Grande”**.

El Cupo permite compras de 1–6 cuotas y cada pago libera nuevamente cupo. El Crédito Grande está diseñado para una sola compra y puede ir de 6 a 24 cuotas. Addi informa además que tiene más de **26.000 aliados**. ([Addi][9])

Sus términos dicen que el cupo es un monto preaprobado para comprar **en comercios aliados de Addi**, y que la cantidad de compras que puede realizarse depende del perfil de riesgo y comportamiento. ([Addi][10])

Por eso:

```text
              ADDI
                │
             CUPO
                │
       ┌────────┼────────┐
       ↓        ↓        ↓
    Compra A  Compra B  Compra C
       ↓        ↓        ↓
   Crédito A Crédito B Crédito C
```

Es muy parecido conceptualmente a Keypago, **pero con miles de comercios**.

---

# 🏦 4. Entidades financieras colombianas

Aquí no conviene hacer una lista improvisada. La fuente oficial para el universo de entidades vigiladas es la **Superintendencia Financiera de Colombia**, que separa establecimientos bancarios, corporaciones financieras, compañías de financiamiento, cooperativas financieras e instituciones oficiales especiales. ([Superintendencia Financiera][11])

Entre los establecimientos que aparecen actualmente en los registros de la SFC están, entre otros:

### Bancos comerciales / universales

* Bancolombia
* Banco de Bogotá
* Banco de Occidente
* Banco Popular
* Banco Caja Social
* Davivienda
* BBVA Colombia
* Banco AV Villas
* Banco Agrario
* Banco GNB Sudameris
* Banco Falabella
* Banco Finandina
* Banco Pichincha
* Bancoomeva
* Banco Santander Colombia
* Banco Serfinanza
* Banco Unión
* Banco W
* Bancamía
* Banco Mundo Mujer
* Banco Contactar
* BAN100

La SFC mantiene el listado oficial y sus estadísticas de establecimientos de crédito. ([Superintendencia Financiera][12])

Y aquí aparece otro dato importante: **Nequi ya debe tratarse de forma diferente a cuando comenzamos a hablar de esto**. Desde el **1 de septiembre de 2026**, Nequi S.A. Compañía de Financiamiento administra sus propios créditos; antes los administraba Bancolombia. ([Ayuda Nequi][13])

---

# 💳 5. Ejemplos de productos de esos bancos

Para Kredit no basta con guardar:

> Bancolombia → crédito

porque un mismo proveedor puede tener **varios modelos financieros**.

### Bancolombia

Tiene, entre otros:

* Tarjetas de crédito
* Crédito de libre inversión
* Libranza
* Compra de cartera
* Crediágil
* Créditos preaprobados
* Crédito para compras
* Sobregiros
* Líneas para empresas

Por ejemplo, **Crediágil** es explícitamente un crédito rotativo: el usuario tiene un cupo disponible que puede activar y utilizar, y Bancolombia publica una comisión mensual por tenerlo disponible o en uso. ([Bancolombia][14])

Además, sus créditos preaprobados pueden incluir libre inversión, libranza, Crediágil, rediferidos y aumentos de cupo. ([Bancolombia][15])

---

### BBVA

Tiene:

* Crédito de libre inversión
* Cupo rotativo
* Compra de cartera
* Libranza
* Crédito educativo
* Vehículo
* Vivienda
* Tarjetas de crédito

Su **Cupo Rotativo** permite disponer de dinero cuando se necesita, mientras que libre inversión es un crédito tradicional amortizado. ([BBVA Colombia][16])

Eso significa que dentro de Kredit:

```text
BBVA
│
├── Tarjeta
├── Crédito cerrado
├── Cupo rotativo
├── Libranza
├── Compra de cartera
└── Crédito garantizado
```

No deberíamos tratar todos como el mismo objeto.

---

# 🧠 Entonces creo que ya tenemos una arquitectura bastante clara para Kredit

Después de revisar estos casos, yo cambiaría ligeramente la propuesta anterior.

En vez de:

```text
Kredit
├── Préstamos
├── Tarjetas
└── Cupos comerciales
```

haría:

```text
Kredit
│
├── Créditos
│   ├── Préstamo cerrado
│   ├── Crédito de compra
│   ├── Libranza
│   └── Otros
│
├── Líneas / Cupos
│   ├── Cupo rotativo
│   ├── Cupo comercial restringido
│   └── Cupo multi-comercio
│
└── Tarjetas
    ├── Crédito tradicional
    └── Tarjeta de marca
```

Y cada **Cupo/Línea** tendría:

```text
Proveedor
Nombre comercial
Límite
Disponible
Saldo utilizado
Tasa
Periodicidad
Cuota de manejo
Vigencia
Comercios autorizados
Tipo de utilización
```

Y cada utilización podría crear:

```text
Utilización
├── Comercio
├── Fecha
├── Monto
├── Crédito asociado
├── Plazo
├── Tasa
├── Intereses
├── Seguro
├── Aval/Fianza
└── Amortización
```

---

## 🔥 Los modelos que ya podemos identificar

| Producto               | Proveedor                  | Restricción       | Modelo Kredit            |
| ---------------------- | -------------------------- | ----------------- | ------------------------ |
| **Keypago**            | Credifactory               | Totto/Topara      | Cupo comercial           |
| **CrediPink**          | Fast Moda/entidad asociada | Lili Pink/Yoi     | Cupo/compras financiadas |
| **CrediÉxito**         | Tuya                       | Éxito             | Cupo rotativo comercial  |
| **CrediCompras**       | Tuya                       | Éxito             | Crédito dirigido         |
| **Brilla**             | Empresas Brilla/aliados    | Red de aliados    | Cupo rotativo            |
| **Addi Cupo**          | Addi                       | +26.000 aliados   | Cupo multi-comercio      |
| **Tarjeta Alkosto**    | Tuya                       | Amplia red        | Tarjeta/cupo             |
| **CMR**                | Banco Falabella            | Amplia red        | Tarjeta/cupo             |
| **Crediágil**          | Bancolombia                | General           | Cupo rotativo            |
| **Cupo Rotativo**      | BBVA                       | General           | Cupo rotativo            |
| **Tarjetas bancarias** | Bancos                     | Red de franquicia | Tarjeta                  |
| **Libre inversión**    | Bancos                     | No restringido    | Crédito cerrado          |

Y esto ya nos da una **taxonomía financiera bastante seria para Kredit**, en vez de simplemente meter “cupo” como una categoría genérica.

### Una observación importante

No llamaría a todos estos productos **“crédito propio de la tienda”**. En varios casos la tienda solamente es el canal de uso y **la obligación financiera pertenece a otra entidad**. Keypago, por ejemplo, deja explícito que el acreedor es Credifactory y/o FGA, mientras Totto actúa como comercio aliado. ([qaw.keypago.com][1])

Eso es precisamente lo que hace que el modelo de datos de Kredit deba separar **proveedor financiero**, **marca/comercio**, **producto financiero** y **obligación**.

Si el objetivo es hacer el inventario para el desarrollo de Kredit, el siguiente paso útil sería convertir esto en una **matriz maestra de Colombia** con columnas como `Entidad | Producto | Tipo | Cupo | Uso restringido | Comercios | Tasa | Plazo | Fianza/Aval | Cuota de manejo | Pago anticipado | Libera cupo | Fórmula de interés | Fuente oficial | Vigencia`, porque ahí sí podríamos ir agregando productos uno por uno sin que el modelo se vuelva un arroz con mango.

[1]: https://qaw.keypago.com/terminos-y-condiciones?utm_source=chatgpt.com "Landing Terminos y condiciones"
[2]: https://co.totto.com/medios-de-pago?utm_source=chatgpt.com "¡Compra ahora y paga después con Keypago, Addi y más opciones!"
[3]: https://www.tuya.com.co/solicitud-crediexito?utm_source=chatgpt.com "Crediéxito | Tuya"
[4]: https://www.tuya.com.co/disfruta-tu-credicompras?utm_source=chatgpt.com "¡Disfruta tu CrediCompras! | Tuya"
[5]: https://www.brilladeefigas.com/tu-cupo?utm_source=chatgpt.com "Tu Cupo Brilla de Efigas | Brilla de Efigas S.A."
[6]: https://brilla.com.co/web/gdo/conoce-tu-credito/?utm_source=chatgpt.com "Solicita tu cupo / crédito | Brilla Gases de Occidente"
[7]: https://www.homecenter.com.co/homecenter-co/content/financiacion-colsubsidio/?utm_source=chatgpt.com "Financiación Colsubsidio| Homecenter"
[8]: https://www.tuya.com.co/sites/default/files/2026-02/informe-de-gestion-2025.pdf?utm_source=chatgpt.com "Informe de gestión 2025"
[9]: https://co.addi.com/creditos?utm_source=chatgpt.com "Tu crédito Addi sin cuota de manejo ni costos ocultos"
[10]: https://co.addi.com/tyc-addicupo?utm_source=chatgpt.com "Términos y Condiciones Cupo"
[11]: https://www.superfinanciera.gov.co/publicaciones/10114906/lista-de-entidades/ "Lista de entidades"
[12]: https://www.superfinanciera.gov.co/publicaciones/10114906/lista-de-entidades/?utm_source=chatgpt.com "Lista de entidades"
[13]: https://ayuda.nequi.com.co/hc/es/articles/47783348330509--Qu%C3%A9-cambia-con-tu-cr%C3%A9dito-Nequi-desde-septiembre-de-2026?utm_source=chatgpt.com "¿Qué cambia con tu crédito Nequi desde septiembre de 2026? – Centro de ayuda"
[14]: https://www.bancolombia.com/personas/productos/creditos/crediagil?utm_source=chatgpt.com "Crediágil rotativo de Bancolombia"
[15]: https://www.bancolombia.com/centro-de-ayuda/preguntas-frecuentes/que-es-preaprobado?utm_source=chatgpt.com "¿Qué es un Crédito preaprobado Bancolombia?"
[16]: https://www.bbva.com.co/personas/productos/prestamos/consumo.html?utm_source=chatgpt.com "Créditos de Consumo | BBVA Colombia"

YO: pero la idea principal para que Kredit cumpla el objetivo es que todo sea facil de hacer, por eso estaba pensando en que sería bueno que se puyeda innovar dentro de la app para hacer el procedimiento de gestion y registro de manera facil y sencilla, y al mismo tiempo que no dependa de la app los datos de las tarjetas o cupos, porque eso podrías complicarnos a nosotros, haría que dependa de nosotros los datos reales, así que la idea e sque el usuario registre su tarjeta o cupo con la entidad que corresponde y le quede allí para su gestion y cuando se registre algo solo sea que se adapte a la info que el usuario tiene de su entidad, pienso más o menos así pero me gustaría saber que me puedes proponer al respecto

CHATGPT: Sí, Lucho. Y de hecho creo que esa idea va **mucho más alineada con el objetivo original de Kredit**: que sea una herramienta de gestión personal y local, no una plataforma que intente convertirse en intermediario financiero.

La clave sería cambiar un poco la mentalidad:

> **Kredit no debería saber cómo funciona cada entidad. Kredit debería permitirle al usuario decirle cómo funciona su producto y luego ayudarlo a gestionarlo.**

Eso reduce muchísimo la complejidad.

## 1. El principio central: Kredit registra, no administra el crédito

Yo establecería esta regla desde el diseño:

> **Kredit nunca es la fuente de verdad del crédito. La fuente de verdad es la entidad financiera y el estado de cuenta del usuario.**

Por ejemplo, si tienes:

**Totto → Keypago**

Kredit no necesita conectarse a Keypago ni saber automáticamente cuánto debes.

El usuario registra:

```text
Mi cupo
────────────────────
Nombre: Keypago
Entidad: Credifactory
Tipo: Cupo comercial

Límite:       $700.000
Disponible:   $450.000
```

Y listo.

Luego registra una compra:

```text
Compra
────────────────────
Comercio: Totto
Valor: $250.000
Fecha: 15/09/2026
Cuotas: 6
Tasa: 1,84% M.V.
```

Kredit **calcula y organiza** a partir de esos datos.

---

# 2. Yo haría que Kredit tenga "productos configurables"

En lugar de programar:

```text
if entidad == "Totto"
if entidad == "Joy"
if entidad == "Nequi"
if entidad == "Bancolombia"
...
```

❌ Eso sería una pesadilla de mantenimiento.

Haría:

```text
Producto financiero
        ↓
Configuración
        ↓
Reglas
        ↓
Créditos / movimientos
```

Por ejemplo:

### Tarjeta de crédito

```text
Tipo:
Tarjeta

Entidad:
Nu

Cupo:
$2.000.000

Fecha de corte:
15

Fecha de pago:
5

Tasa:
X%

Cuota de manejo:
$0
```

---

### Cupo comercial

```text
Tipo:
Cupo comercial

Entidad:
Credifactory

Marca:
Totto

Cupo:
$700.000

Tasa:
1,84% M.V.

Fianza:
10%

Plazo máximo:
6 meses
```

---

### Crédito de libre inversión

```text
Tipo:
Préstamo

Entidad:
Bancolombia

Capital:
$5.000.000

Plazo:
24 meses

Tasa:
X%

Sistema:
Cuota fija
```

Kredit no necesita saber previamente que existe “Keypago”.

El usuario simplemente configura **qué tiene**.

---

# 3. Pero aquí hay una idea que creo que mejoraría muchísimo la UX

En vez de hacer que el usuario rellene un formulario gigante...

```text
Entidad
Tipo
Tasa
Tasa efectiva
Tasa nominal
Plazo
Fianza
Seguro
Fecha de corte
Fecha de pago
...
```

💀

Yo haría un **asistente de registro**.

### Paso 1 — ¿Qué quieres registrar?

```text
¿Qué tienes?

[ 💳 Tarjeta ]
[ 💰 Préstamo ]
[ 🔄 Cupo ]
[ 🛍️ Crédito de compra ]
```

---

### Paso 2 — ¿Con quién?

```text
¿Quién te lo proporciona?

🔎 Buscar entidad...

Bancolombia
Nequi
Nu
Davivienda
Totto / Keypago
Lili Pink / CrediPink
Otra entidad
```

Pero aquí viene la innovación:

### "No encuentro mi entidad"

```text
[ Crear manualmente ]
```

Y Kredit no se rompe.

---

# 4. Después Kredit pregunta únicamente lo necesario

Este punto es **muy importante**.

Si el usuario selecciona:

> Tarjeta

Kredit pregunta:

```text
¿Cuál es tu cupo?

$ __________

¿Cuánto tienes utilizado?

$ __________

Fecha de corte

[ 15 ]

Fecha límite de pago

[ 05 ]

¿Tiene cuota de manejo?

[ Sí ] [ No ]
```

Y después:

> ¿Quieres configurar la tasa?

```text
○ Sí, conozco la tasa
○ La configuraré después
○ No quiero calcular intereses
```

No obligas al usuario a conocer todos los datos.

---

# 5. Para un cupo sería todavía más sencillo

Por ejemplo:

### "Registrar cupo"

```text
Nombre
[ Keypago ]

Tipo
[ Cupo comercial ]

Cupo aprobado
[ $700.000 ]

Disponible actualmente
[ $450.000 ]

Tasa
[ 1,84% mensual ]

¿Tiene costo adicional?
[ Sí ]

Tipo
[ Fianza ]

Valor
[ 10% ]
```

Y luego:

> **¿Dónde puedes utilizarlo?**

```text
[ Totto ]
[ Topara ]
```

Pero incluso esto podría ser opcional.

---

# 6. Y aquí está una de mis ideas favoritas para Kredit

## "Registrar desde estado de cuenta"

En lugar de obligar al usuario a introducir todo manualmente.

Podrías permitir:

```text
┌─────────────────────────────┐
│  📄 Importar estado de      │
│     cuenta                  │
│                             │
│  PDF / imagen / documento   │
│                             │
│       [ Analizar ]          │
└─────────────────────────────┘
```

Kredit podría extraer:

```text
Entidad: Nu
Cupo: $2.500.000
Saldo: $840.000
Tasa: XX%
Fecha de corte: 15
Pago mínimo: $120.000
Pago total: $840.000
Fecha límite: 05/10/2026
```

Y mostrar:

> **Encontramos estos datos**

```text
✓ Cupo: $2.500.000
✓ Saldo: $840.000
✓ Corte: día 15
✓ Pago: día 5

[ Confirmar ]
```

**Pero no necesitas almacenar el documento.**

Ese detalle es importantísimo para el modelo de privacidad que quieres.

---

# 7. Y todavía mejor: "datos temporales"

Podrías tener algo como:

```text
Documento
   ↓
Procesamiento local
   ↓
Extracción
   ↓
Usuario confirma
   ↓
Datos estructurados
   ↓
Documento eliminado
```

Así Kredit conserva:

```text
cupo = 2.500.000
saldo = 840.000
corte = 15
```

pero no necesita guardar:

> el PDF completo del banco.

Eso encaja **perfectamente** con tu idea de local-first.

---

# 8. Y los datos sensibles ni siquiera deberían ser necesarios

Yo establecería como regla:

### ❌ Kredit NO necesita

* Número completo de tarjeta
* CVV
* Contraseña bancaria
* Usuario bancario
* PIN
* Datos de autenticación
* Número completo de cuenta
* Tokens bancarios
* Credenciales de Nequi/Bancolombia/etc.

### ✅ Kredit SÍ puede necesitar

* Nombre de la entidad
* Tipo de producto
* Cupo
* Saldo
* Tasa
* Fechas
* Cuotas
* Compras
* Intereses
* Costos
* Estado de pago

Y eso cambia completamente el riesgo.

---

# 9. Incluso podríamos ocultar parcialmente los identificadores

Si el usuario quiere distinguir sus tarjetas:

```text
Nu
•••• 4821
```

Kredit podría guardar solamente:

```text
last4 = 4821
```

Nunca el número completo.

Y lo mismo con cuentas o productos.

---

# 10. Ahora viene el verdadero "cerebro" de Kredit

Yo separaría **datos** de **reglas**.

Por ejemplo:

```text
PRODUCTO
──────────────
Entidad: Keypago
Tipo: Cupo comercial
Cupo: $700.000

REGLAS
──────────────
Interés: 1,84% MV
Fianza: 10%
Plazo máximo: 6
Pago anticipado: Sí
Libera cupo: Sí
```

Y entonces Kredit utiliza esas reglas.

Esto permite que el usuario pueda modificarlas:

> "Mi entidad cambió la tasa"

```text
Tasa anterior
1,84%

Nueva tasa
1,79%

[ Actualizar ]
```

Y **Kredit no necesita que nosotros lancemos una actualización de la aplicación**.

---

# 11. Incluso podríamos tener "plantillas"

Esto sería buenísimo.

Kredit podría venir con:

### Plantillas oficiales/preconfiguradas

```text
💳 Nu
💳 Bancolombia
💳 Davivienda
💳 BBVA
💳 RappiCard

🔄 Addi
🔄 Keypago
🔄 CrediPink
🔄 CrediÉxito

💰 Bancolombia Libre Inversión
💰 Davivienda Libre Inversión
💰 BBVA Libre Inversión
```

Pero esas plantillas **no contienen la deuda del usuario**.

Contienen únicamente:

> "Así suele configurarse este tipo de producto".

El usuario luego introduce sus propios valores.

---

# 12. Y si una entidad cambia algo...

Aquí está la magia.

Supongamos que Keypago cambia:

```text
Tasa:
1,84% → 1,75%
```

Kredit no debería modificar automáticamente los créditos antiguos.

Porque:

> **La tasa de una obligación pertenece a las condiciones con las que se generó esa obligación.**

Entonces:

```text
Crédito #001
Tasa: 1,84%
Fecha: 2026-08-01

Crédito #002
Tasa: 1,75%
Fecha: 2026-09-20
```

Ambos pueden coexistir.

Esto es importantísimo para que los cálculos históricos no se dañen.

---

# 13. Yo llevaría esto incluso un paso más allá

Crear un concepto llamado:

## "Perfil financiero"

El usuario tendría:

```text
MI PERFIL FINANCIERO
────────────────────────

💳 Tarjetas
   ├── Nu
   ├── Bancolombia
   └── RappiCard

🔄 Cupos
   ├── Keypago / Totto
   ├── Addi
   └── CrediÉxito

💰 Préstamos
   ├── Bancolombia
   └── Davivienda
```

Y desde **Inicio**:

```text
┌─────────────────────────────┐
│ Disponible total            │
│                             │
│ $4.850.000                  │
└─────────────────────────────┘

Próximos pagos

Nu                  $320.000
Keypago             $85.000
Bancolombia         $240.000
```

Pero sin que Kredit tenga conexión alguna con esas entidades.

---

# 14. La arquitectura conceptual quedaría así

```text
                         KREDIT
                            │
                  ┌─────────┴─────────┐
                  │                   │
             PRODUCTOS             MOVIMIENTOS
                  │                   │
        ┌─────────┼─────────┐         │
        │         │         │         │
     Tarjeta    Cupo     Préstamo     │
        │         │         │         │
        └─────────┼─────────┘         │
                  │                   │
              REGLAS              COMPRAS
                  │                   │
            ┌─────┴─────┐             │
            │           │             │
        Intereses    Costos       Pagos/abonos
```

Y **todo vive localmente**.

```text
              DISPOSITIVO
                   │
              IndexedDB
                / Dexie
                   │
        ┌──────────┼──────────┐
        │          │          │
     Productos   Créditos   Movimientos
        │          │          │
        └──────────┼──────────┘
                   │
              Sin servidor
```

---

# 15. Y esto encaja perfecto con lo que ya querías de Kredit

Recuerdo que la idea inicial era que Kredit fuera **local-first**, sin cuentas, sin nube y sin almacenar datos sensibles de tarjetas. Esta propuesta no cambia esa filosofía; al contrario, la refuerza.

La aplicación no sería:

> "Kredit sabe cuánto debes en Bancolombia."

Sería:

> **"Tú le dices a Kredit qué productos tienes y cómo funcionan, y Kredit hace las cuentas, organiza las obligaciones y te ayuda a gestionarlas."**

Esa diferencia es enorme.

Y además evita que ustedes tengan que mantener una base de datos absurda de:

> 80 entidades × 10 productos × 20 reglas × cambios de tasas × cambios de condiciones...

Porque terminarían convirtiéndose en **Wikipedia financiera con dolor de cabeza** 😂

---

## Mi propuesta concreta para Kredit

Yo dejaría **4 tipos principales**:

```text
1. 💳 TARJETA
   Cupo + consumos + corte + pago

2. 🔄 CUPO
   Límite + utilizaciones + créditos asociados

3. 💰 PRÉSTAMO
   Capital + amortización + cuotas

4. 🛍️ CRÉDITO DE COMPRA
   Una compra → una obligación
```

Y encima de ellos pondría un sistema de:

**Plantillas + configuración manual + importación de estado de cuenta + edición de reglas.**

Así Kredit puede soportar desde:

> **Nu**

hasta:

> **Totto / Keypago**

sin que nosotros tengamos que construir una integración específica para cada uno.

Y sobre todo mantiene una filosofía que me parece muy buena para el proyecto: **Kredit no controla tu dinero, no toca tu banco y no necesita tus credenciales; simplemente convierte la información que tú ya tienes en una herramienta útil para entender y gestionar tus obligaciones.**

YO: Bueno, mira, no me parece malo, pero debo comentarte que, por ejemplo, yo usuario, a mí no me gustaría que si tengo cupo en Toto tenga que elegir Kipago. El usuario no va a saber qué es Kipago. O sea, el usuario sabe que debe en Toto. Toto utiliza Kipago como medio financiero o como se le llame, pero para el usuario técnicamente le está pagando a Toto, no a Kipago. Visualmente y sistemáticamente el usuario va a una tienda Toto, paga su cuota y listo. No tiene que decir es otra entidad que financia por detrás o algo. Entonces este método no me parece malo, pero para un usuario promedio no creo que sea lo más indicado. Hay que pensar en el usuario donde llega a ser su crédito y ya. ¿Sí me entiendes? Entonces la idea es mantenerlo lo más cerrado posible al lugar donde se está haciendo la compra con crédito con cupo y no indicar al usuario cuál es la entidad financiera, porque eso es más enredado.

CHATGPT: Sí, te entiendo perfectamente. Y creo que ese ajuste **mejora bastante la experiencia de Kredit**.

El usuario no debería pensar en la arquitectura financiera que existe detrás. Si él compró en Totto, para él su producto financiero es:

> **“Mi cupo de Totto”**

No:

> “Mi cupo de Credifactory mediante Keypago utilizado en Totto”.

Eso último puede ser cierto jurídicamente, pero **es información de segundo nivel para el usuario**.

## Yo cambiaría la estructura así

En lugar de:

```text
Entidad financiera
      ↓
Producto
      ↓
Comercio
```

para la interfaz del usuario:

```text
Comercio / Marca
      ↓
Producto financiero
      ↓
Cupo / Crédito
      ↓
Pagos
```

Por ejemplo:

```text
🛍️ Totto

Cupo disponible
$450.000

Cupo total
$700.000

Deuda actual
$250.000
```

Y debajo:

```text
Tus compras

🎒 Morral
$250.000
6 cuotas

Próximo pago
$48.500
05 de octubre
```

**Y ya.**

El usuario nunca tuvo que saber qué es Keypago.

---

# Entonces hay que separar "lo que Kredit sabe" de "lo que Kredit muestra"

Esto me parece fundamental.

Internamente podríamos tener:

```text
Producto
├── comercio: Totto
├── proveedor_financiero: Credifactory
├── plataforma: Keypago
├── tipo: cupo_comercial
├── límite: 700000
└── reglas...
```

Pero la interfaz solamente muestra:

```text
Totto
Cupo
$700.000
```

La información financiera detrás puede existir en el modelo de datos **sin convertirse en parte del flujo de usuario**.

Incluso yo iría un poco más lejos:

### Para un usuario normal, ni siquiera preguntaría por la entidad financiera.

Cuando diga:

> **Agregar producto**

Kredit podría mostrar:

```text
¿Dónde tienes tu crédito?

🔎 Buscar comercio

Totto
Lili Pink
Éxito
Falabella
Addi
Bancolombia
Nequi
Davivienda
Nu
...
```

Pero fíjate en algo:

**Addi aparece porque el usuario lo reconoce como producto financiero**, mientras que Keypago no necesariamente.

Si selecciona:

> **Totto**

Kredit automáticamente puede cargar una plantilla:

```text
Totto
Tipo: Cupo comercial
```

Y listo.

---

# ¿Y qué pasa si el usuario tiene algo que no conocemos?

Aquí está la parte importante para que Kredit no dependa de nosotros.

Después de buscar:

```text
¿Dónde tienes tu crédito?

[ 🔎 Buscar ]

No encuentro mi comercio
        ↓
[ Agregar otro ]
```

Y entonces:

```text
Nombre
_________________

¿Qué tienes?

○ Tarjeta
○ Cupo
○ Préstamo
○ Crédito de compra
```

El usuario podría crear:

> **Tienda XYZ**

y Kredit simplemente crea:

```text
Tienda XYZ
Cupo
$500.000
```

Sin necesidad de que nosotros conozcamos absolutamente nada de esa empresa.

---

# Y esto nos lleva a una arquitectura mucho más limpia

Yo tendría una entidad principal llamada:

## `FinancialProduct`

Pero **el usuario la percibe como una cuenta/producto que tiene con una marca**.

Por ejemplo:

```text
FinancialProduct

id
name
brand
type
limit
balance
available
currency
```

Y opcionalmente:

```text
provider
```

Pero `provider` sería **metadata interna**, no un campo obligatorio en el flujo.

---

# Incluso podemos hacer que "marca" sea el concepto principal

Esto es importante porque después Kredit puede soportar cosas como:

### Totto

```text
Totto
└── Cupo
    ├── límite
    ├── disponible
    └── créditos
```

### Lili Pink

```text
Lili Pink
└── Cupo
    ├── límite
    ├── disponible
    └── créditos
```

### Éxito

```text
Éxito
└── Cupo
    ├── límite
    ├── disponible
    └── créditos
```

### Nu

```text
Nu
└── Tarjeta
    ├── límite
    ├── disponible
    └── consumos
```

### Bancolombia

```text
Bancolombia
├── Tarjeta
├── Crédito libre inversión
└── Cupo rotativo
```

Ahí el usuario **piensa en sus productos**, no en cómo está estructurado el sistema financiero detrás.

---

# Pero hay una diferencia importante

No quiero que esto termine significando que Kredit tenga que asumir que:

> **"Totto = cupo"**

porque mañana Totto puede cambiar de proveedor o producto.

Por eso yo haría que **la plantilla de Totto solamente sea una ayuda inicial**.

Por ejemplo:

```text
Totto

Tipo de producto
[ Cupo comercial ▼ ]

Cupo aprobado
$ __________

Disponible
$ __________

Fecha de pago
__ / __ / __

Tasa
[ Configurar ]

Costos adicionales
[ Configurar ]
```

El usuario puede aceptar y continuar.

Y si la estructura cambia en el futuro, **el producto del usuario no se rompe**, porque sus datos son propios.

---

# Esto también soluciona el problema de la dependencia

Imagínate que Kredit tiene 100.000 usuarios.

Si ustedes almacenaran:

```text
Totto → API
Lili Pink → API
Nu → API
Bancolombia → API
Davivienda → API
...
```

sería una locura.

Tendrían que mantener:

* APIs
* autenticaciones
* cambios de endpoints
* permisos
* seguridad
* términos legales
* disponibilidad
* cambios de productos
* cambios de tasas
* errores de sincronización

Y además estarían tocando información financiera real.

Mientras que con tu enfoque:

```text
Entidad
   ↓
Usuario
   ↓
Kredit
```

Kredit simplemente administra **la información que el usuario decide registrar**.

---

# Incluso el usuario podría modificarlo manualmente

Supongamos que Totto cambia las condiciones.

El usuario entra:

**Totto → Configuración**

```text
Cupo aprobado
$900.000

Disponible
$620.000

Tasa
1,79%

Fecha de pago
15

[ Guardar cambios ]
```

Y Kredit se adapta.

No hay que esperar a que ustedes actualicen la aplicación.

---

# Y yo agregaría una cosa que puede ser muy buena

## "¿No sabes la tasa?"

No obliguemos al usuario a conocerla.

Por ejemplo:

```text
Tasa de interés

○ Conozco la tasa
○ No la conozco
○ No quiero calcular intereses
```

Si dice:

> **No la conozco**

Kredit puede registrar simplemente:

```text
Interés
No configurado
```

Y seguir funcionando para:

* registrar compras
* registrar pagos
* mostrar vencimientos
* calcular saldo
* controlar cupo

Luego el usuario puede configurarla cuando quiera.

Esto es **mucho más amigable** que exigirle al usuario que sepa qué significa E.A., M.V., tasa nominal, etc.

---

# Y aquí está, para mí, la idea central de Kredit

Yo lo resumiría así:

> **Kredit no debe intentar entender a todas las entidades financieras. Debe entender al usuario.**

El usuario dice:

> "Tengo $700.000 de cupo en Totto."

Kredit responde:

> "Perfecto."

Y le permite registrar:

```text
Totto
Cupo: $700.000

Compra
$250.000
6 cuotas

Pago
$50.000

Disponible
$500.000
```

No necesita saber si detrás existe Keypago, Credifactory, Tuya, una compañía de financiamiento, una cooperativa o el mismísimo señor de los créditos escondido debajo del mostrador 😂

Eso queda **abstraído**.

Y técnicamente podemos conservar ese dato como metadata si algún día resulta útil, pero **no debe formar parte del modelo mental principal del usuario**.

### Yo dejaría entonces la filosofía de Kredit en tres capas:

**1. Usuario**

> "Tengo un cupo en Totto"

**2. Kredit**

> "Es un cupo comercial con estas reglas"

**3. Infraestructura**

> "Totto → Keypago → Credifactory → FGA..."

La tercera capa **no tiene por qué existir para el usuario**.

Y creo que esa separación nos permite conseguir justamente lo que buscas: **una aplicación sencilla para el usuario, pero suficientemente flexible por debajo para representar prácticamente cualquier producto de crédito sin depender de APIs ni de mantener información financiera real de terceros.**

YO: Bueno, mira, aquí te entrego un roadmap que tuve con otor chat de GPT y con Claude, creo que con esta información puedes tener en cuenta cómo funciona Kredit y su estado actual, para que puedas dar una mejor información de cómo aplicar los cambios y todo lo demás, claramente esta conversación la verá Claude para que el entienda como debe hacer todo en términos de lógica par ala app, ya del codigo se encarga el

CHATGPT: Sí, Lucho. Ya tengo el roadmap como **fuente de contexto para esta conversación**, y la verdad es que ayuda muchísimo porque deja bastante claro dónde está Kredit realmente y qué cosas son ideas futuras frente a funcionalidades ya implementadas.

Lo más importante que me queda establecido es:

* Kredit **ya está funcional**, no estamos diseñando una app desde cero
* El modelo actual gira alrededor de `Credit`, con `LoanCredit` y `CardCredit` 
* La lógica financiera debe permanecer en `lib/domain/`, separada de la UI y con tests para cada función nueva 
* La experiencia debe priorizar **conclusiones y acciones**, no simplemente acumular información 
* Ya existe una distinción funcional entre préstamos/cupos y tarjetas, pero la clasificación de las entidades todavía no está formalizada
* La idea de convertir las entidades en algo más estructurado **está explícitamente marcada como no implementada**, por lo que no debemos asumir que existe actualmente 
* Ya existe el aviso de posible duplicado, pero deliberadamente **no bloquea** la creación de otro producto de la misma entidad 
* El nombre que el usuario asigna al crédito ya se muestra en la `WalletCard`, precisamente para diferenciar productos similares 

Y esto conecta directamente con lo que veníamos hablando de **Totto, CrediPink/Lili Pink y los cupos comerciales**.

### La conclusión importante

No creo que debamos llevar Kredit hacia:

> `Usuario → Entidad financiera → Producto`

sino más bien hacia algo conceptualmente como:

> **Usuario → Dónde tiene el crédito → Qué producto tiene → Cómo funciona ese producto**

Porque para el usuario:

> "Tengo un cupo en Totto"

es una unidad de información perfectamente válida.

No necesita saber:

> "Tengo un producto financiero originado por Credifactory mediante Keypago y comercializado por Totto"

Eso puede existir **internamente como metadata**, pero no debería convertirse en una decisión que el usuario tenga que tomar durante el registro.

Esto además encaja mejor con el principio que ya tiene el roadmap de que Kredit debe hablar en términos simples y no obligar al usuario a conocer jerga financiera o técnica. 

### Y hay otro punto importante

El roadmap actualmente habla de **"entidad financiera"** y de crear un catálogo de entidades, pero esa definición probablemente se nos queda corta ahora que estamos incorporando productos comerciales.

Por ejemplo:

```text
Totto
 └── Cupo comercial
      ├── Límite: $700.000
      ├── Disponible: $450.000
      └── Compras/obligaciones
```

mientras que:

```text
RappiCard
 └── Tarjeta de crédito
      ├── Cupo
      ├── Corte
      ├── Fecha límite
      └── Movimientos
```

Y otra posibilidad:

```text
Éxito
 ├── Tarjeta Tuya
 └── CrediCompras
```

Es decir, **la marca/comercio y el producto financiero no necesariamente son lo mismo**, y tampoco necesariamente coinciden con el proveedor financiero que está detrás.

Eso significa que antes de que Claude toque código, yo haría primero una **especificación de dominio pequeña y muy concreta** para esta nueva etapa. Así evitamos que Claude simplemente convierta el actual `lender` en una tabla `entities` y terminemos con una estructura técnicamente bonita pero conceptualmente equivocada.

Y sí: **Claude puede encargarse del código**. Mi papel aquí puede ser ayudarte a definir exactamente **qué debe significar cada entidad, producto, cupo, compra, obligación y proveedor**, y luego darle a Claude una especificación suficientemente precisa para implementarlo sin inventarse reglas.

El roadmap ya deja incluso advertido que los cambios arquitectónicos deben pasar primero por diseño antes de tocar código. 

Así que a partir de ahora, para Kredit, voy a tomar **este roadmap + las decisiones que acabamos de establecer sobre los cupos comerciales** como el contexto de trabajo, en vez de tratar Kredit como una app genérica de créditos.


