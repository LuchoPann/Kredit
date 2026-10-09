import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    return Scaffold(
      appBar: AppBar(title: const Text('Cómo funciona Krezium')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.card),
        children: [
          // ── Introducción ─────────────────────────────────────────────────
          const _Lead(
            'Krezium es tu registro financiero personal — 100 % local, sin cuentas, '
            'sin internet y sin servidores. Todos tus datos viven únicamente en tu '
            'dispositivo.',
          ),

          // ── Índice ───────────────────────────────────────────────────────
          _Index(kredit: kredit),
          const SizedBox(height: 8),
          Divider(height: 1, color: kredit.borderCard),

          // 1 ── Qué es y qué no es ─────────────────────────────────────────
          const _SectionTitle(number: '1', title: 'Qué es Krezium — y qué no es'),
          const _Body(
            'Krezium es una herramienta de control y planificación financiera personal. '
            'Funciona como un cuaderno de registro inteligente para tus créditos: '
            'calcula proyecciones, organiza cronogramas y te muestra el panorama '
            'completo de tu deuda.',
          ),
          const SizedBox(height: 14),
          const _CannotBlock(items: [
            'Conectarse a bancos ni acceder a tu saldo real — no existe ninguna integración.',
            'Pagar facturas, cuotas ni deudas — no mueve dinero.',
            'Reemplazar el estado de cuenta oficial de tu entidad financiera.',
            'Calcular con exactitud absoluta — usa amortización francesa estándar; '
                'tu cuota real puede diferir por redondeos, seguros o comisiones propias del banco.',
            'Funcionar en varios dispositivos de forma sincronizada — no hay nube.',
            'Operar con monedas distintas al peso colombiano (COP).',
            'Exportar reportes en PDF — solo exporta/importa en formato JSON.',
          ]),
          Divider(height: 1, color: kredit.borderCard),

          // 2 ── Tipos de crédito ────────────────────────────────────────────
          const _SectionTitle(number: '2', title: 'Los tres tipos de crédito'),
          const _SubSection(title: 'Préstamo / Cuotas fijas'),
          const _Body(
            'Compraste algo o tomaste un crédito y pagas cuotas iguales hasta una fecha '
            'de terminación. El interés ya está incluido en la cuota (amortización '
            'francesa). Si pagas antes de tiempo, esa cuota no genera intereses '
            'adicionales.\n\n'
            'Krezium calcula el cronograma completo con la cuota exacta, el '
            'desglose capital/interés por mes y el total de intereses que pagarás.',
          ),
          const _SubSection(title: 'Tarjeta de crédito'),
          const _Body(
            'Saldo variable con fecha de corte y fecha límite de pago. Los intereses '
            'se calculan sobre el saldo actual. Puedes registrar una cuota de '
            'mantenimiento mensual.\n\n'
            'Al registrar movimientos (compras y pagos), Krezium actualiza el saldo '
            'e intereses al instante.',
          ),
          const _SubSection(title: 'Cupo de tienda'),
          const _Body(
            'Crédito rotativo en una tienda específica: Alkosto, Falabella, Éxito, '
            'Addi, Sistecrédito, etc. Registras compras como "cargos" y abonos '
            'como "pagos".\n\n'
            'Cada movimiento genera un voucher visual con el detalle de la '
            'transacción — cada tienda tiene su propio estilo de tarjeta para '
            'identificación rápida.',
          ),
          Divider(height: 1, color: kredit.borderCard),

          // 3 ── Pantallas principales ───────────────────────────────────────
          const _SectionTitle(number: '3', title: 'Pantallas principales'),
          const _SubSection(title: 'Dashboard'),
          const _Body(
            '• Deuda total y ProgressRing: porcentaje pagado del mes en curso.\n'
            '• Próximos vencimientos: resaltados en rojo si vencen en 3 días o menos.\n'
            '• Lista compacta de créditos activos con la entidad de cada uno.\n'
            '• Widget de inicio: resumen rápido en la pantalla del teléfono, con '
            'montos ocultos por defecto para proteger tu privacidad.',
          ),
          const _SubSection(title: 'Créditos'),
          const _Body(
            '• Lista completa con buscador y ordenamiento.\n'
            '• Pestañas Activos / Pagados.\n'
            '• Toca cualquier crédito para ver su detalle completo: cronograma, '
            'movimientos, simulador y opciones de edición.',
          ),
          const _SubSection(title: 'Cuenta'),
          const _Body(
            '• Foto y nombre de perfil editables.\n'
            '• Estadísticas generales de tu cartera.\n'
            '• Personalización visual (tema, acento).\n'
            '• Herramientas de datos: exportar, importar, borrar.\n'
            '• Configuración de seguridad y respaldo automático.\n'
            '• Acceso a esta guía y al historial de versiones.',
          ),
          Divider(height: 1, color: kredit.borderCard),

          // 4 ── Registrar un crédito ────────────────────────────────────────
          const _SectionTitle(number: '4', title: 'Registrar un crédito'),
          const _Body(
            'Toca el botón "+" en la pantalla de Créditos. Krezium te pide '
            'primero el tipo (préstamo, tarjeta o cupo de tienda) y luego la '
            'entidad — esto define el diseño visual y los campos disponibles.',
          ),
          const _SubSection(title: 'Préstamo'),
          const _Body(
            'Ingresa: monto total, tasa de interés (mensual o anual), número de '
            'cuotas y fecha del primer pago. Krezium calcula el cronograma '
            'completo con amortización francesa.',
          ),
          const _SubSection(title: 'Tarjeta de crédito'),
          const _Body(
            'Ingresa: cupo total, saldo actual, tasa de interés, fecha de corte, '
            'fecha límite de pago y (opcional) cuota de mantenimiento mensual. '
            'Si la tarjeta ya tiene deuda, puedes indicar la fecha en que comenzó.',
          ),
          const _SubSection(title: 'Cupo de tienda'),
          const _Body(
            'Ingresa: cupo máximo, saldo disponible actual y (opcional) el día '
            'de pago mensual. Desde aquí también defines la tasa de interés si '
            'aplica. El simulador funciona con cupos de tienda igual que con tarjetas.',
          ),
          Divider(height: 1, color: kredit.borderCard),

          // 5 ── Pagos y movimientos ─────────────────────────────────────────
          const _SectionTitle(number: '5', title: 'Registrar pagos y movimientos'),
          const _SubSection(title: 'Préstamo — marcar cuota pagada'),
          const _Body(
            'En el detalle del crédito, abre la pestaña "Cronograma" y marca '
            'la cuota como pagada. Si el monto que pagaste difiere del calculado, '
            'ingresa el valor real; la diferencia se abona automáticamente a la '
            'siguiente cuota.\n\n'
            'Si marcas una cuota por error, aparece un botón "DESHACER" durante '
            '5 segundos en el mensaje de confirmación.',
          ),
          const _SubSection(title: 'Tarjeta — compras y pagos'),
          const _Body(
            'En el detalle usa "Registrar movimiento" para agregar un cargo '
            '(compra) o un pago. La app recalcula el saldo e intereses al instante.',
          ),
          const _SubSection(title: 'Cupo de tienda — cargos y abonos'),
          const _Body(
            'En la pestaña de movimientos registra compras y abonos. Cada '
            'movimiento genera un voucher descargable con el detalle de la '
            'transacción y el diseño visual de la tienda.',
          ),
          Divider(height: 1, color: kredit.borderCard),

          // 6 ── Abonos extra ────────────────────────────────────────────────
          const _SectionTitle(number: '6', title: 'Abonos extra a capital'),
          const _Body(
            'En cualquier préstamo activo puedes registrar un abono extraordinario '
            'desde el menú del detalle. El monto se aplica directamente al capital '
            'pendiente y Krezium recalcula el cronograma.\n\n'
            'Elige entre dos estrategias:\n'
            '• Reducir cuota: el préstamo termina en la misma fecha pero cada '
            'cuota es más barata.\n'
            '• Reducir plazo: la cuota se mantiene igual pero el préstamo '
            'termina antes.\n\n'
            'Si el monto del abono supera la deuda restante, Krezium lo ajusta '
            'automáticamente para saldar el crédito en cero.',
          ),
          Divider(height: 1, color: kredit.borderCard),

          // 7 ── Simulador ───────────────────────────────────────────────────
          const _SectionTitle(number: '7', title: 'Simulador financiero'),
          const _Body(
            'Disponible en el detalle de cualquier crédito activo. Calcula el '
            'impacto de una acción futura sin modificar los datos reales.',
          ),
          const _SubSection(title: 'Simulación de compra'),
          const _Body(
            '¿Cuánto cambiaría la cuota si hago una compra adicional de X pesos? '
            'Aplica a tarjetas y cupos de tienda.',
          ),
          const _SubSection(title: 'Simulación de abono extra'),
          const _Body(
            '¿Cuánto ahorro en intereses si abono Y pesos hoy? '
            'Los resultados se actualizan en tiempo real mientras escribes.',
          ),
          const _SubSection(title: 'Tab Libertad'),
          const _Body(
            'Proyecta tu fecha libre de deuda y el ahorro en intereses si pagas '
            'un monto extra al mes. Ofrece dos estrategias:\n'
            '• Avalanche: paga primero el crédito con mayor tasa de interés '
            '(ahorra más dinero total).\n'
            '• Snowball: paga primero el crédito más pequeño '
            '(da más motivación psicológica).\n\n'
            'El tab también muestra tu deuda total, interés mensual estimado y '
            'fecha libre desde que lo abres, sin necesidad de simular nada.',
          ),
          Divider(height: 1, color: kredit.borderCard),

          // 8 ── Alertas y mora ──────────────────────────────────────────────
          const _SectionTitle(number: '8', title: 'Alertas y mora estimada'),
          const _SubSection(title: 'Notificaciones de vencimiento'),
          const _Body(
            'Krezium puede enviarte recordatorios cuando una cuota está próxima '
            'a vencer. Configura los días de anticipación desde Cuenta → '
            'Notificaciones.',
          ),
          const _SubSection(title: 'Mora estimada'),
          const _Body(
            'Cuando una cuota queda vencida, Krezium muestra junto a ella un '
            'interés moratorio estimado (interés simple diario sobre el saldo '
            'vencido). Es informativo — cada banco tiene sus propias reglas de '
            'mora y este valor no se suma al total de deuda del dashboard.',
          ),
          const _SubSection(title: 'Detector de tasa de usura'),
          const _Body(
            'Al registrar la tasa de interés, Krezium la compara con los rangos '
            'habituales del mercado colombiano. Si el valor parece inconsistente '
            '(por ejemplo, una tasa mensual escrita en el campo anual), muestra '
            'una advertencia sin bloquear el guardado. Siempre confirma la tasa '
            'directamente con tu entidad.',
          ),
          Divider(height: 1, color: kredit.borderCard),

          // 9 ── Seguridad ───────────────────────────────────────────────────
          const _SectionTitle(number: '9', title: 'Seguridad y privacidad'),
          const _Body(
            'Protege la apertura de Krezium con:\n'
            '• PIN: código numérico de 4 a 6 dígitos.\n'
            '• Biometría: huella dactilar o reconocimiento facial '
            '(si el dispositivo lo soporta).\n\n'
            'Tras varios intentos fallidos, la app aplica un tiempo de espera '
            'progresivo antes de permitir un nuevo intento.\n\n'
            'El widget de pantalla de inicio muestra los montos ocultos por '
            'defecto. Puedes activar su visibilidad desde Cuenta → Seguridad.\n\n'
            'Krezium no transmite ningún dato fuera del dispositivo. No existe '
            'ninguna telemetría, analítica ni comunicación de red.',
          ),
          Divider(height: 1, color: kredit.borderCard),

          // 10 ── Respaldo ───────────────────────────────────────────────────
          const _SectionTitle(number: '10', title: 'Respaldo de datos'),
          const _SubSection(title: 'Exportación / importación manual'),
          const _Body(
            'Desde Cuenta → Datos y respaldos, exporta un archivo JSON con '
            'toda tu información. Guárdalo donde quieras (Drive, correo, USB).\n\n'
            'Para restaurar: importa ese archivo. Krezium pide confirmación '
            'antes de reemplazar los datos actuales. Los backups de versiones '
            'anteriores siempre son importables sin perder información.',
          ),
          const _SubSection(title: 'Respaldo automático'),
          const _Body(
            'Configura la frecuencia (diaria, semanal, quincenal o mensual) y '
            'la hora del respaldo. Los archivos se guardan en Krezium/backups/ '
            'del almacenamiento interno del teléfono, al mismo nivel que '
            'Descargas y Documentos.\n\n'
            'Elige entre sobreescribir siempre el mismo archivo o crear uno '
            'nuevo por cada respaldo.',
          ),
          Divider(height: 1, color: kredit.borderCard),

          // 11 ── Personalización ────────────────────────────────────────────
          const _SectionTitle(number: '11', title: 'Personalización'),
          const _SubSection(title: 'Tema'),
          const _Body(
            'Oscuro — Puro (negro intenso), Frío (azul medianoche) o Cálido '
            '(grafito con acento ámbar).\n'
            'Claro — Puro (fondo slate), Nube (azul pálido) o Arena (crema cálida).',
          ),
          const _SubSection(title: 'Color de acento'),
          const _Body(
            '14 opciones de color más el neutro blanco/negro. Define el tono '
            'de botones, iconos activos y elementos destacados en toda la app. '
            'El acento se mezcla sutilmente con el tono de fondo elegido para '
            'mantener coherencia visual.',
          ),
          const _SubSection(title: 'Perfil'),
          const _Body(
            'Foto de perfil (desde galería o cámara) y nombre visible en el '
            'encabezado de la pantalla de cuenta.',
          ),
          Divider(height: 1, color: kredit.borderCard),

          // 12 ── Limitaciones ───────────────────────────────────────────────
          const _SectionTitle(number: '12', title: 'Limitaciones importantes'),
          const _Body(
            'Para usarla bien, es importante saber qué no hace Krezium:',
          ),
          const SizedBox(height: 10),
          const _LimitationBlock(items: [
            _Limitation(
              icon: Icons.wifi_off_outlined,
              label: 'Sin conexión a bancos',
              detail: 'No accede a tu cuenta real ni descarga movimientos. '
                  'Los datos los ingresas tú manualmente.',
            ),
            _Limitation(
              icon: Icons.sync_disabled_outlined,
              label: 'Sin sincronización',
              detail: 'No existe nube ni cuenta. Al cambiar de teléfono necesitas '
                  'importar el backup manualmente.',
            ),
            _Limitation(
              icon: Icons.calculate_outlined,
              label: 'Cálculo aproximado',
              detail: 'Usa amortización francesa estándar. Tu cuota real puede '
                  'diferir por redondeos, seguros o comisiones específicas del banco.',
            ),
            _Limitation(
              icon: Icons.payments_outlined,
              label: 'No paga deudas',
              detail: 'Krezium no mueve dinero. Es solo un registro; los pagos '
                  'los haces tú directamente con tu banco.',
            ),
            _Limitation(
              icon: Icons.flag_outlined,
              label: 'Solo pesos colombianos',
              detail: 'La app está diseñada para el mercado colombiano (COP). '
                  'No admite otras monedas.',
            ),
            _Limitation(
              icon: Icons.picture_as_pdf_outlined,
              label: 'Sin exportación PDF',
              detail: 'Los respaldos son en formato JSON. No genera reportes '
                  'en PDF ni Excel.',
            ),
          ]),
          const SizedBox(height: AppSpacing.section),
          _Note(
            kredit: kredit,
            text: 'La fuente de verdad es siempre el estado de cuenta o la app '
                'oficial de tu entidad. Usa Krezium para planear y controlar tu '
                'deuda; confirma las cifras exactas directamente con el banco.',
          ),
          const SizedBox(height: AppSpacing.section),
        ],
      ),
    );
  }
}

// ── Componentes ───────────────────────────────────────────────────────────────

class _Lead extends StatelessWidget {
  final String text;
  const _Lead(this.text);

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppTextSize.heading,
          fontWeight: FontWeight.w600,
          height: 1.55,
          color: kredit.textPrimary,
        ),
      ),
    );
  }
}

class _Index extends StatelessWidget {
  final AppThemeColors kredit;
  const _Index({required this.kredit});

  static const _entries = [
    (n: '1', title: 'Qué es Krezium — y qué no es'),
    (n: '2', title: 'Los tres tipos de crédito'),
    (n: '3', title: 'Pantallas principales'),
    (n: '4', title: 'Registrar un crédito'),
    (n: '5', title: 'Registrar pagos y movimientos'),
    (n: '6', title: 'Abonos extra a capital'),
    (n: '7', title: 'Simulador financiero'),
    (n: '8', title: 'Alertas y mora estimada'),
    (n: '9', title: 'Seguridad y privacidad'),
    (n: '10', title: 'Respaldo de datos'),
    (n: '11', title: 'Personalización'),
    (n: '12', title: 'Limitaciones importantes'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(AppSpacing.card),
      decoration: BoxDecoration(
        color: kredit.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(color: kredit.borderCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONTENIDO',
            style: TextStyle(
              fontSize: AppTextSize.caption,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: kredit.textTertiary,
            ),
          ),
          const SizedBox(height: 10),
          ...(_entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${e.n}.',
                        style: TextStyle(
                          fontSize: AppTextSize.body,
                          fontWeight: FontWeight.w700,
                          color: kredit.textTertiary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        e.title,
                        style: TextStyle(
                          fontSize: AppTextSize.body,
                          color: kredit.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ))),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String number;
  final String title;
  const _SectionTitle({required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: TextStyle(
                fontSize: AppTextSize.body,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: AppTextSize.heading,
                fontWeight: FontWeight.w700,
                color: kredit.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubSection extends StatelessWidget {
  final String title;
  const _SubSection({required this.title});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: AppTextSize.body,
          fontWeight: FontWeight.w700,
          color: kredit.textPrimary,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final String text;
  const _Body(this.text);

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    return Text(
      text,
      style: TextStyle(
        fontSize: AppTextSize.body,
        height: 1.6,
        color: kredit.textSecondary,
      ),
    );
  }
}

class _CannotBlock extends StatelessWidget {
  final List<String> items;
  const _CannotBlock({required this.items});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.all(AppSpacing.card),
      decoration: BoxDecoration(
        color: kredit.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(color: kredit.borderCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.block_outlined, size: 16, color: AppColors.danger),
              const SizedBox(width: 6),
              Text(
                'KREZIUM NO PUEDE',
                style: TextStyle(
                  fontSize: AppTextSize.caption,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: AppTextSize.body,
                          height: 1.5,
                          color: kredit.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _Limitation {
  final IconData icon;
  final String label;
  final String detail;
  const _Limitation({required this.icon, required this.label, required this.detail});
}

class _LimitationBlock extends StatelessWidget {
  final List<_Limitation> items;
  const _LimitationBlock({required this.items});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    return Column(
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(item.icon, size: AppIconSize.small, color: kredit.textTertiary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: AppTextSize.body,
                      fontWeight: FontWeight.w700,
                      color: kredit.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.detail,
                    style: TextStyle(
                      fontSize: AppTextSize.body,
                      height: 1.5,
                      color: kredit.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

class _Note extends StatelessWidget {
  final AppThemeColors kredit;
  final String text;
  const _Note({required this.kredit, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.card),
      decoration: BoxDecoration(
        color: kredit.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(color: kredit.borderCard),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: AppIconSize.small, color: kredit.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: AppTextSize.body,
                height: 1.55,
                fontStyle: FontStyle.italic,
                color: kredit.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
