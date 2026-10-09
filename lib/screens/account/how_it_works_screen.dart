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
            'Krezium es una aplicación 100 % local para llevar el control de tus '
            'créditos — tarjetas, préstamos y cupos de tienda — sin cuentas, sin '
            'nube y sin servidores externos. Todos los datos viven en tu dispositivo.',
          ),
          Divider(height: 1, color: kredit.borderCard),

          // ── Tipos de crédito ─────────────────────────────────────────────
          const _Section(
            icon: Icons.credit_card_outlined,
            title: 'Los tres tipos de crédito',
            body:
                'Préstamo / Cuotas fijas: compraste algo y pagas cuotas iguales '
                'hasta una fecha de terminación. El interés está incluido en la cuota; '
                'si pagas antes de tiempo, esa cuota no genera intereses adicionales.\n\n'
                'Tarjeta de crédito: saldo variable con fecha de corte y fecha límite '
                'de pago. Los intereses se calculan diariamente sobre el saldo y existe '
                'opción de cuota de mantenimiento mensual.\n\n'
                'Cupo de tienda: funciona como un crédito rotativo en una tienda '
                'específica (Alkosto, Falabella, Éxito, etc.). Registras compras '
                'como "cargos" y abonos como "pagos"; Krezium genera un voucher '
                'visual por cada movimiento — cada tienda tiene su propio diseño '
                'de tarjeta — para que tengas el comprobante a mano.',
          ),
          Divider(height: 1, color: kredit.borderCard),

          // ── Pantallas ────────────────────────────────────────────────────
          const _Section(
            icon: Icons.grid_view_outlined,
            title: 'Las tres pantallas principales',
            body:
                'Dashboard: resumen de tu deuda total, ProgressRing con el porcentaje '
                'pagado del mes, próximos vencimientos urgentes (resaltados en rojo '
                'si vencen en 3 días o menos) y lista compacta de tus créditos '
                'activos con el banco o tienda de cada uno.\n\n'
                'Créditos: lista completa con buscador, ordenamiento y pestañas '
                'Activos / Pagados. Toca cualquier crédito para ver su detalle.\n\n'
                'Cuenta: foto de perfil editable, estadísticas generales, '
                'personalización visual, herramientas de datos y acceso a configuración '
                'de seguridad y respaldo.',
          ),
          Divider(height: 1, color: kredit.borderCard),

          // ── Registrar crédito ────────────────────────────────────────────
          const _Section(
            icon: Icons.add_circle_outline,
            title: 'Registrar un crédito',
            body:
                'Toca el botón "+" en la pantalla de Créditos. Krezium te pide primero '
                'que elijas el tipo (préstamo, tarjeta o cupo de tienda) y luego la '
                'entidad bancaria o tienda — esto define el diseño visual y los campos '
                'disponibles.\n\n'
                'Préstamo: ingresa el monto total, tasa de interés, número de cuotas '
                'y fecha del primer pago. Krezium calcula el cronograma completo con '
                'amortización francesa.\n\n'
                'Tarjeta: ingresa el cupo total, saldo actual, tasa de interés, fecha '
                'de corte y fecha límite de pago.\n\n'
                'Cupo de tienda: ingresa el cupo máximo y el saldo actual disponible. '
                'Puedes indicar el día de pago mensual.',
          ),
          Divider(height: 1, color: kredit.borderCard),

          // ── Registrar movimientos ────────────────────────────────────────
          const _Section(
            icon: Icons.swap_horiz_outlined,
            title: 'Registrar pagos y movimientos',
            body:
                'Préstamo: en el detalle del crédito, abre la pestaña "Cronograma" '
                'y marca la cuota como pagada. Si el monto que pagaste difiere del '
                'calculado, puedes ingresar el valor real; la diferencia se abona '
                'automáticamente a la siguiente cuota.\n\n'
                'Tarjeta: abre el detalle y usa "Registrar movimiento" para agregar '
                'un cargo (compra) o un pago. La aplicación recalcula el saldo e '
                'intereses al instante.\n\n'
                'Cupo de tienda: en la pestaña de movimientos registra compras y '
                'abonos. Cada movimiento genera un voucher con el detalle de la '
                'transacción — el diseño visual varía según la tienda para '
                'facilitar la identificación rápida.',
          ),
          Divider(height: 1, color: kredit.borderCard),

          // ── Abonos extra ─────────────────────────────────────────────────
          const _Section(
            icon: Icons.trending_down_outlined,
            title: 'Abonos extra a capital',
            body:
                'En cualquier préstamo puedes registrar un abono extraordinario desde '
                'el menú del detalle. El monto se aplica directamente al capital '
                'pendiente y Krezium recalcula el cronograma.\n\n'
                'Al abonar puedes elegir entre dos estrategias:\n'
                '• Reducir cuota: el préstamo termina en la misma fecha pero cada '
                'cuota es más barata.\n'
                '• Reducir plazo: la cuota se mantiene igual pero el préstamo '
                'termina antes.\n\n'
                'Si el monto del abono supera la deuda restante, Krezium lo ajusta '
                'automáticamente para saldar el crédito en cero.',
          ),
          Divider(height: 1, color: kredit.borderCard),

          // ── Simulador ────────────────────────────────────────────────────
          const _Section(
            icon: Icons.calculate_outlined,
            title: 'Simulador financiero',
            body:
                'Disponible en el detalle de cualquier crédito activo. Te permite '
                'calcular el impacto de una acción futura sin afectar los datos reales:\n\n'
                '• Compra adicional: ¿cuánto cambiaría la cuota si hago una compra '
                'de X pesos?\n'
                '• Abono extra: ¿cuánto ahorro en intereses si abono Y pesos hoy?\n\n'
                'Los resultados son proyecciones estimadas — no modifican el crédito '
                'hasta que confirmes la operación real.',
          ),
          Divider(height: 1, color: kredit.borderCard),

          // ── Mora estimada ────────────────────────────────────────────────
          const _Section(
            icon: Icons.warning_amber_outlined,
            title: 'Mora estimada',
            body:
                'Cuando una cuota queda vencida, Krezium muestra junto a ella un '
                'interés moratorio estimado (interés simple diario sobre el saldo '
                'vencido). Es una aproximación informativa — cada banco tiene sus '
                'propias reglas de mora y este valor no se suma al total de deuda '
                'mostrado en el resto de la app.',
          ),
          Divider(height: 1, color: kredit.borderCard),

          // ── Detector usura ───────────────────────────────────────────────
          const _Section(
            icon: Icons.policy_outlined,
            title: 'Detector de tasa de usura',
            body:
                'Al registrar la tasa de interés, Krezium la compara con los rangos '
                'habituales del mercado colombiano y con el límite legal vigente. Si '
                'el valor parece inconsistente (por ejemplo, una tasa mensual escrita '
                'en el campo anual), la app muestra una advertencia sin bloquear el '
                'guardado. Siempre puedes confirmar la tasa directamente con tu entidad.',
          ),
          Divider(height: 1, color: kredit.borderCard),

          // ── Respaldo ─────────────────────────────────────────────────────
          const _Section(
            icon: Icons.backup_outlined,
            title: 'Respaldo de datos',
            body:
                'Krezium ofrece dos formas de respaldar tus datos:\n\n'
                'Manual: desde Cuenta → Datos y respaldos, exporta un archivo JSON '
                'con toda la información. Puedes importarlo en cualquier momento para '
                'restaurar — la app pide confirmación antes de reemplazar los datos '
                'actuales.\n\n'
                'Automático: configura la frecuencia (diaria, semanal, quincenal o '
                'mensual) y la hora del respaldo. Los archivos se guardan en la '
                'carpeta Krezium/backups/ del almacenamiento interno del teléfono, al '
                'mismo nivel que Descargas y Documentos. Puedes elegir entre '
                'sobreescribir siempre el mismo archivo o crear uno nuevo por cada '
                'respaldo.',
          ),
          Divider(height: 1, color: kredit.borderCard),

          // ── Seguridad ────────────────────────────────────────────────────
          const _Section(
            icon: Icons.security_outlined,
            title: 'Seguridad y privacidad',
            body:
                'Puedes proteger la apertura de Krezium con:\n'
                '• PIN: código numérico de 4 a 6 dígitos.\n'
                '• Biometría: huella dactilar o reconocimiento facial (si el '
                'dispositivo lo soporta).\n\n'
                'Tras varios intentos fallidos, la app aplica un tiempo de espera '
                'progresivo antes de dejarte intentar de nuevo.\n\n'
                'El widget de pantalla de inicio respeta tu privacidad: los montos '
                'aparecen ocultos por defecto. Puedes activar su visibilidad desde '
                'Cuenta → Seguridad.',
          ),
          Divider(height: 1, color: kredit.borderCard),

          // ── Personalización ──────────────────────────────────────────────
          const _Section(
            icon: Icons.palette_outlined,
            title: 'Personalización',
            body:
                'Desde Cuenta → Apariencia puedes ajustar:\n\n'
                '• Tema: oscuro — Puro (negro intenso), Frío (azul medianoche) '
                'o Cálido (grafito ámbar). Claro — Puro (fondo slate), Nube '
                '(azul pálido) o Arena (crema cálida).\n\n'
                '• Color de acento: 14 opciones de color más el neutro '
                'blanco/negro — define el tono de botones, iconos activos y '
                'elementos destacados en toda la app. El acento se adapta '
                'automáticamente al tono de fondo elegido.\n\n'
                '• Foto y nombre de perfil: visibles en el encabezado de la '
                'pantalla de cuenta.',
          ),
          Divider(height: 1, color: kredit.borderCard),

          // ── Aproximación ─────────────────────────────────────────────────
          const _Section(
            icon: Icons.info_outline,
            title: 'Una aproximación, no el número exacto del banco',
            body:
                'Krezium usa amortización francesa estándar (cuota fija, interés '
                'decreciente, capital creciente) — el modelo de referencia de la '
                'mayoría de entidades. Tu cuota real puede diferir en unos pesos '
                'por redondeos, seguros o comisiones propias de cada banco.\n\n'
                'La fuente de verdad es siempre el estado de cuenta o la app oficial '
                'de tu entidad. Usa Krezium para planear y controlar tu deuda; '
                'confirma las cifras exactas directamente con el banco.',
          ),
          Divider(height: 1, color: kredit.borderCard),

          // ── Sin conexión ─────────────────────────────────────────────────
          const _Section(
            icon: Icons.wifi_off_outlined,
            title: 'Sin conexión, sin cuentas',
            body:
                'Krezium no requiere internet ni registro. Todos los datos se '
                'almacenan localmente en tu dispositivo mediante SQLite (Drift). '
                'La app funciona completamente sin conexión y ninguna información '
                'tuya sale del teléfono.',
          ),
          const SizedBox(height: AppSpacing.section),
        ],
      ),
    );
  }
}

class _Lead extends StatelessWidget {
  final String text;
  const _Lead(this.text);

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
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

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _Section({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppIconSize.small, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: AppTextSize.heading,
                    fontWeight: FontWeight.w700,
                    color: kredit.textPrimary,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: TextStyle(
              fontSize: AppTextSize.body,
              height: 1.55,
              color: kredit.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
