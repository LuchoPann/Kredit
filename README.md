# Kredit

Kredit es una app Flutter para gestionar créditos y préstamos en Colombia:
tarjetas de crédito, préstamos de cuota fija y productos tipo cupo.

La meta del proyecto es ir más allá de una lista de deudas. Kredit busca
ayudar a decidir qué pagar, cuándo pagar y qué impacto tienen los abonos a
capital sobre el plazo, la cuota y el costo total.

## Estado actual

- App Flutter multiplataforma con foco móvil.
- Persistencia local con Drift/SQLite.
- Estado reactivo con Riverpod.
- Cálculo de préstamos con amortización francesa.
- Soporte para tarjetas de crédito rotativas.
- Abonos a capital con estrategia de reducir cuota o reducir plazo.
- Importación y exportación de respaldos JSON versionados.
- Recordatorios locales de vencimientos.
- Bloqueo de app y almacenamiento seguro para preferencias sensibles.
- Widget Android con privacidad configurable.
- Logos y detección de entidades financieras colombianas.

También se conserva una versión PWA anterior en `legacy_pwa/` como referencia
histórica del producto.

## Enfoque de producto

Kredit está pensado para una persona que quiere entender rápido su situación:

- cuánto debe;
- qué pago es más urgente;
- cuánto tiene que cubrir esta semana;
- qué pasa si hace un abono extra;
- qué tarjeta o cupo le está consumiendo más dinero.

El diferencial debe estar en traducir lógica financiera compleja a decisiones
claras y accionables.

## Estructura principal

- `lib/domain/`: reglas financieras, cálculos de préstamos, tarjetas, tasas,
  urgencia, importación/exportación.
- `lib/data/`: modelos y base de datos Drift.
- `lib/providers/`: estado de créditos, tema, navegación, bloqueo,
  notificaciones y preferencias.
- `lib/screens/`: pantallas principales de la app.
- `lib/widgets/`: componentes reutilizables.
- `test/`: pruebas de dominio y persistencia.
- `legacy_pwa/`: versión PWA anterior.

## Ejecutar

```bash
flutter pub get
flutter run
```

## Probar

```bash
flutter test
```

## Visión de desarrollo

Las próximas mejoras deberían priorizar:

1. Recomendaciones inteligentes de pago.
2. Simuladores de abonos más visibles y accionables.
3. Flujos de creación más guiados para usuarios no financieros.
4. Mejor explicación de tasas colombianas, fechas de corte y fechas límite.
5. Visualizaciones que respondan preguntas concretas, no solo gráficos.
