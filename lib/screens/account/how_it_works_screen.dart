import 'package:flutter/material.dart';

import '../../theme/app_theme.dart' show KreditColors, KreditSpacing;

/// Static help content ported from legacy_pwa/INFO.md — lenguaje visual
/// "sin cajas": jerarquía tipográfica (título de sección con más peso,
/// cuerpo normal) y un Divider fino entre secciones, sin Container/Card con
/// borde decorativo. Mismo patrón que dashboard_screen.dart.
class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Scaffold(
      appBar: AppBar(title: const Text('Cómo funciona Kredit')),
      body: ListView(
        padding: const EdgeInsets.all(KreditSpacing.card),
        children: [
          const _Lead(
            'Kredit es una aplicación 100% local para llevar el control de tus créditos '
            '— tarjetas de crédito y préstamos — sin cuentas, sin nube y sin '
            'servidores externos. Todos los datos se almacenan en tu dispositivo (SQLite local vía Drift).',
          ),
          Divider(height: 1, color: kredit.borderCard),
          _Section(
            title: 'Los dos tipos de crédito',
            body:
                'Préstamo / Cuotas fijas: compras algo y pagas cuotas iguales con fecha '
                'de finalización definida. El interés se incluye en la cuota; si pagas '
                'una cuota antes de tiempo, esa cuota no genera intereses adicionales.\n\n'
                'Tarjeta de crédito: saldo variable, con fecha de corte (cierre del ciclo) '
                'y fecha límite de pago, intereses calculados diariamente sobre el saldo '
                'y cuota de mantenimiento opcional.\n\n'
                'La aplicación reconoce automáticamente múltiples entidades bancarias '
                'y les aplica el diseño visual correspondiente.',
          ),
          Divider(height: 1, color: kredit.borderCard),
          _Section(
            title: 'Una aproximación, no el número exacto del banco',
            body:
                'Kredit calcula el cronograma de un préstamo con el sistema de '
                'amortización francesa estándar (cuota fija, interés decreciente, '
                'capital creciente) — el modelo matemático de referencia que usan la '
                'mayoría de bancos y entidades de crédito. Es una MUY BUENA '
                'aproximación, pero no es una copia exacta del sistema interno de tu '
                'banco.\n\n'
                'Cada entidad puede aplicar sus propias reglas de redondeo, comisiones, '
                'seguros o políticas de causación de intereses, así que tu cuota real '
                'puede diferir en unos pesos de la que ves aquí. Esto es esperado y '
                'normal — no significa que algo esté mal calculado.\n\n'
                'La fuente de verdad siempre es el estado de cuenta o la app oficial de '
                'tu banco. Usa Kredit para llevar el control y la planeación general de '
                'tu deuda, y confirma cifras exactas (saldos a pagar, total de intereses, '
                'fecha de terminación) directamente con tu entidad.',
          ),
          Divider(height: 1, color: kredit.borderCard),
          _Section(
            title: 'Detector de tasa de usura',
            body:
                'Al registrar la tasa de interés de un crédito, Kredit la compara con '
                'los rangos habituales del mercado colombiano y con el límite legal '
                'de la tasa de usura vigente. Si el valor ingresado parece '
                'inconsistente (por ejemplo, una tasa mensual escrita en el campo '
                'anual, o un valor que supera el techo legal), la aplicación muestra '
                'una advertencia — sin bloquear el guardado — para que puedas '
                'verificar el dato.',
          ),
          Divider(height: 1, color: kredit.borderCard),
          _Section(
            title: 'Abonos extra a capital',
            body:
                'En cualquier préstamo puedes registrar abonos extraordinarios, además '
                'de las cuotas normales. Un abono se aplica directamente al capital '
                'pendiente, reduciendo el saldo y adelantando cuotas futuras; si el '
                'monto ingresado supera la deuda restante, se ajusta automáticamente '
                'para que el préstamo quede saldado en cero sin perder el excedente. '
                'El nuevo cronograma que resulta es un recálculo estimado — confirma '
                'con tu banco el valor exacto de las próximas cuotas.\n\n'
                'Si lo que pagaste en una cuota no coincide con el valor calculado por '
                'Kredit, puedes registrar el monto real al marcarla como pagada: la '
                'diferencia se aplica a la siguiente cuota pendiente, igual que un '
                'abono.\n\n'
                'Al registrar el abono puedes elegir entre "reducir cuota" (mismo número '
                'de cuotas restantes, cada una más barata) o "reducir plazo" (misma '
                'cuota, el crédito termina antes) — las dos estrategias reales que ofrece '
                'un banco.',
          ),
          Divider(height: 1, color: kredit.borderCard),
          _Section(
            title: 'Mora estimada',
            body:
                'Cuando una cuota queda vencida, Kredit muestra junto a ella un interés '
                'moratorio ESTIMADO (interés simple diario sobre el saldo vencido) para '
                'darte una idea de cuánto puede estar costando el atraso. Es un cálculo '
                'simplificado, no la cifra real de tu banco — cada entidad tiene sus '
                'propias reglas de mora (algunas la componen, otras cobran cargos fijos de '
                'cobranza) y esta estimación no se suma al total de deuda mostrado en el '
                'resto de la app. Confirma el valor real de la mora directamente con tu '
                'banco.',
          ),
          Divider(height: 1, color: kredit.borderCard),
          _Section(
            title: 'Las 3 pantallas principales',
            body:
                '1. Dashboard: resumen de deuda total, carrusel de tus tarjetas activas '
                'y próximos vencimientos.\n\n'
                '2. Créditos: lista completa con búsqueda, ordenamiento y pestañas de '
                'Activos/Pagados.\n\n'
                '3. Cuenta: perfil, estadísticas generales, personalización (color de '
                'acento y tono de fondo) y herramientas de datos (exportar/importar '
                'JSON, borrar todo).',
          ),
          Divider(height: 1, color: kredit.borderCard),
          _Section(
            title: 'Flujo típico',
            body:
                'Agregar un crédito: presionas el botón "+" → eliges el tipo de crédito → '
                'completas los datos → se guarda localmente.\n\n'
                'Pagar: en un préstamo, seleccionas la cuota correspondiente (o usas "Registrar pago '
                'total"); en una tarjeta, registras un "Cargo/Compra" o un "Pago" desde '
                'su detalle — la aplicación recalcula el saldo y los intereses automáticamente.\n\n'
                'Detalle de un crédito: Resumen (tarjeta visual y cifras clave), Notas '
                '(dónde se compró, con qué cuenta se paga) y Cronograma (préstamos) / '
                'Movimientos (tarjetas).',
          ),
          Divider(height: 1, color: kredit.borderCard),
          _Section(
            title: 'Datos',
            body:
                'Puedes exportar todo a un archivo JSON de respaldo e importarlo '
                'posteriormente (solicita confirmación antes de reemplazar los datos actuales). '
                '"Borrar base de datos" en Zona de Peligro elimina todo de forma '
                'permanente, previa confirmación.',
          ),
          Divider(height: 1, color: kredit.borderCard),
          _Section(
            title: 'Seguridad y privacidad',
            body:
                'Puedes proteger la app con un PIN; tras varios intentos fallidos, '
                'Kredit aplica un tiempo de espera progresivo antes de dejarte '
                'intentar de nuevo. El widget de inicio también respeta tu '
                'privacidad: los montos aparecen ocultos por defecto hasta que '
                'decides mostrarlos.',
          ),
          Divider(height: 1, color: kredit.borderCard),
          _Section(
            title: 'Sin conexión',
            body:
                'Al no depender de un servidor externo ni de la nube, Kredit funciona '
                'completamente sin conexión a internet: todos tus datos permanecen guardados en el '
                'dispositivo.',
          ),
          const SizedBox(height: KreditSpacing.section),
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
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.5,
          color: kredit.textPrimary,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: kredit.textPrimary,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: kredit.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
