/// Registro de cambios visible al usuario por versión.
/// Para añadir una release: insertar una nueva VersionEntry AL INICIO de [changelog].
/// La versión de pubspec.yaml es la única fuente de verdad — no duplicar aquí.
///
/// Nota: versiones 0.1.0–0.8.0 son reconstrucciones retrospectivas
/// (el proyecto no tenía versionado formal antes de 0.9.0).
library changelog;

class VersionEntry {
  final String version;
  final String date;
  final List<ChangeItem> changes;

  const VersionEntry({
    required this.version,
    required this.date,
    required this.changes,
  });
}

class ChangeItem {
  final ChangeType type;
  final String description;

  const ChangeItem(this.type, this.description);
}

enum ChangeType { nuevo, mejora, correccion }

const List<VersionEntry> changelog = [
  VersionEntry(
    version: '1.0.0',
    date: 'Octubre 2026',
    changes: [
      ChangeItem(ChangeType.nuevo,
          'El simulador ahora funciona con cupos de tienda y app (Addi, Sistecrédito, etc.), no solo con tarjetas de crédito.'),
      ChangeItem(ChangeType.nuevo,
          'Simulación en tiempo real: los resultados se actualizan automáticamente mientras escribes, sin necesidad de presionar un botón.'),
      ChangeItem(ChangeType.nuevo,
          'Al crear un crédito de tarjeta con saldo inicial, ahora puedes indicar la fecha en que comenzó esa deuda.'),
      ChangeItem(ChangeType.mejora,
          'El simulador ya no parpadea al cambiar valores — los datos se actualizan en su lugar sin rehacer la interfaz.'),
      ChangeItem(ChangeType.mejora,
          'Se eliminó la tabla "Comparar escenarios" del simulador de abono extra, que generaba más confusión que claridad.'),
      ChangeItem(ChangeType.correccion,
          'Las copias de respaldo automáticas ya no se disparan en cada reinicio de la app durante desarrollo.'),
      ChangeItem(ChangeType.correccion,
          'Se resolvió el conflicto de recursos duplicados del ícono de notificación que impedía compilar en Android.'),
    ],
  ),
  VersionEntry(
    version: '0.9.2',
    date: 'Octubre 2026',
    changes: [
      ChangeItem(ChangeType.nuevo,
          'Puedes deshacer un abono registrado por accidente: aparece un botón "DESHACER" durante 5 segundos en el mensaje de confirmación.'),
      ChangeItem(ChangeType.nuevo,
          'Los créditos de préstamo ahora permiten editar la fecha de inicio directamente desde la pantalla de edición.'),
      ChangeItem(ChangeType.mejora,
          'La sección de abonos se expande automáticamente al registrar uno nuevo, y el último abono recibe la etiqueta "Reciente".'),
      ChangeItem(ChangeType.correccion,
          'Corregido: el gráfico "Cuándo termina cada crédito" ahora muestra el progreso real de cuotas pagadas, no un estimado incorrecto.'),
      ChangeItem(ChangeType.mejora,
          'Los textos informativos y de advertencia en toda la app ahora tienen un estilo visual consistente (cursiva, tamaño uniforme, borde).'),
    ],
  ),
  VersionEntry(
    version: '0.9.1',
    date: 'Octubre 2026',
    changes: [
      ChangeItem(ChangeType.nuevo,
          'Simulador: nuevo tab "Libertad" que proyecta tu fecha libre de deuda y cuánto ahorras en intereses si pagas un monto extra al mes.'),
      ChangeItem(ChangeType.nuevo,
          'Estrategias Avalanche y Snowball en el simulador: elige la que mejor se adapte a tu perfil.'),
      ChangeItem(ChangeType.mejora,
          'El simulador muestra tu deuda total, interés mensual estimado y fecha libre de deuda desde que lo abres, sin necesidad de simular nada.'),
      ChangeItem(ChangeType.correccion,
          'Corregido crash al abrir las sub-vistas de "Respaldo automático" y "Seguridad" dentro del panel deslizable de configuración.'),
      ChangeItem(ChangeType.mejora,
          'Las sub-vistas de configuración ahora deslizan internamente dentro del panel, sin abrir una pantalla completa.'),
    ],
  ),
  VersionEntry(
    version: '0.9.0',
    date: 'Octubre 2026',
    changes: [
      ChangeItem(ChangeType.nuevo,
          'Respaldo automático: los archivos ahora se guardan en Kredit/backups/ del almacenamiento principal del teléfono.'),
      ChangeItem(ChangeType.nuevo,
          'Configuración de hora para el respaldo automático.'),
      ChangeItem(ChangeType.nuevo,
          'Ícono personalizado de Kredit en la barra de notificaciones.'),
      ChangeItem(ChangeType.mejora,
          'Nueva pantalla de cuenta: diseño limpio con foto de perfil editable y acceso rápido a cada sección.'),
      ChangeItem(ChangeType.mejora,
          'Los diálogos de confirmación ahora se muestran como paneles deslizables desde abajo.'),
      ChangeItem(ChangeType.mejora,
          'La edición de tarjetas y cupos de tienda tiene formularios separados adaptados a cada tipo.'),
      ChangeItem(ChangeType.mejora,
          'Mejoras visuales en el modo claro: colores más diferenciados entre variantes.'),
      ChangeItem(ChangeType.correccion,
          'Corregido error que impedía mostrar valores de días de pago fuera del rango del selector.'),
      ChangeItem(ChangeType.correccion,
          'Las notificaciones ahora se envían correctamente con todos sus parámetros.'),
    ],
  ),
  VersionEntry(
    version: '0.8.0',
    date: 'Septiembre 2026',
    changes: [
      ChangeItem(ChangeType.nuevo,
          'Rework completo del formulario de edición de créditos: secciones organizadas, advertencias claras y campo de saldo de solo lectura.'),
      ChangeItem(ChangeType.nuevo,
          'La hoja de movimientos de tarjeta fue rediseñada con mejor organización visual.'),
      ChangeItem(ChangeType.mejora,
          'El modo claro tiene ahora tres variantes visualmente más distintas: Puro, Nube y Arena.'),
      ChangeItem(ChangeType.correccion,
          'Corregida la lógica del ciclo de facturación: el corte ocurre al inicio del día indicado, no el día siguiente.'),
    ],
  ),
  VersionEntry(
    version: '0.7.0',
    date: 'Septiembre 2026',
    changes: [
      ChangeItem(ChangeType.nuevo,
          'Rediseño de la vista de detalle de tarjeta: fechas de ciclo en el encabezado, línea de tiempo visual del ciclo y marcador del día actual.'),
      ChangeItem(ChangeType.nuevo,
          'Flujo de tienda mejorado: hero de monto, primeros pagos y selector de voucher deslizable.'),
      ChangeItem(ChangeType.mejora,
          'La vista de resumen muestra ahora la gráfica completa del ciclo y el cupo debajo de la tarjeta.'),
      ChangeItem(ChangeType.correccion,
          'El picker de voucher ahora muestra la selección activa en tiempo real.'),
      ChangeItem(ChangeType.correccion,
          'Los vouchers en la vista de confirmación muestran el diseño correcto según el tipo de crédito.'),
    ],
  ),
  VersionEntry(
    version: '0.6.0',
    date: 'Septiembre 2026',
    changes: [
      ChangeItem(ChangeType.nuevo,
          'El registro de créditos ahora tiene flujos separados para tienda, tarjeta y préstamo, con una pantalla de selección inicial.'),
      ChangeItem(ChangeType.nuevo,
          'Nuevo campo "Día de pago" y política de interés a una cuota en tarjetas de crédito.'),
      ChangeItem(ChangeType.mejora,
          'Hints educativos en el flujo de registro para guiar al usuario en cada campo.'),
    ],
  ),
  VersionEntry(
    version: '0.5.0',
    date: 'Septiembre 2026',
    changes: [
      ChangeItem(ChangeType.nuevo,
          'Pantalla de carga animada con reveal direccional y efecto de brillo.'),
      ChangeItem(ChangeType.nuevo,
          'Arquitectura entidad-primero: el banco o tienda emisora ahora es el punto de partida al registrar un crédito.'),
      ChangeItem(ChangeType.nuevo,
          'Picker visual de entidades con búsqueda y presets de bancos y apps populares.'),
      ChangeItem(ChangeType.mejora,
          'La app ahora carga más rápido: SharedPreferences inyectado y tabs cargados de forma diferida.'),
    ],
  ),
  VersionEntry(
    version: '0.4.0',
    date: 'Agosto 2026',
    changes: [
      ChangeItem(ChangeType.nuevo,
          'Dashboard rediseñado con logo, tiles de próximos pagos y resumen de créditos.'),
      ChangeItem(ChangeType.nuevo,
          'Sistema tipográfico unificado (KreditTextSize) y escala de iconos consistente en toda la app.'),
      ChangeItem(ChangeType.nuevo,
          'Tarjeta de sección compartida (KreditSectionCard) en todas las pantallas.'),
      ChangeItem(ChangeType.mejora,
          'Buscador de créditos, estados vacíos y vista de detalle mejorados.'),
    ],
  ),
  VersionEntry(
    version: '0.3.0',
    date: 'Agosto 2026',
    changes: [
      ChangeItem(ChangeType.nuevo,
          'Voucher de comprobante estilo Nequi para registrar movimientos de cupos de tienda.'),
      ChangeItem(ChangeType.nuevo,
          'Abonos extra con reamortización real: las cuotas adelantadas se marcan correctamente.'),
      ChangeItem(ChangeType.nuevo,
          'Estimación de mora en el cronograma de pagos.'),
      ChangeItem(ChangeType.mejora,
          'El interés ya no se descuenta del cupo disponible, solo el capital.'),
    ],
  ),
  VersionEntry(
    version: '0.2.0',
    date: 'Agosto 2026',
    changes: [
      ChangeItem(ChangeType.nuevo,
          'Simulador financiero: calcula el impacto de una compra adicional o un abono extra.'),
      ChangeItem(ChangeType.nuevo,
          'Bloqueo de app con PIN y biometría (huella/face ID).'),
      ChangeItem(ChangeType.nuevo,
          'Re-autenticación requerida antes de borrar todos los datos.'),
      ChangeItem(ChangeType.correccion,
          'El teclado numérico nativo aparece correctamente en la pantalla de bloqueo.'),
    ],
  ),
  VersionEntry(
    version: '0.1.0',
    date: 'Agosto 2026',
    changes: [
      ChangeItem(ChangeType.nuevo,
          'Primera versión de Kredit: gestión de tarjetas de crédito, cupos de tienda y préstamos.'),
      ChangeItem(ChangeType.nuevo,
          'Registro de movimientos, cronograma de cuotas y resumen financiero.'),
      ChangeItem(ChangeType.nuevo,
          'Temas claro y oscuro con color de acento personalizable.'),
      ChangeItem(ChangeType.nuevo,
          'Exportación e importación de datos en formato JSON.'),
      ChangeItem(ChangeType.nuevo,
          'Recordatorios de vencimiento con notificaciones locales.'),
    ],
  ),
];
