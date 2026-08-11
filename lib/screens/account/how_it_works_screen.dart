import 'package:flutter/material.dart';

import '../../theme/app_theme.dart' show KreditColors, KreditRadius, KreditSpacing;

/// Static help content ported from legacy_pwa/INFO.md — no markdown
/// renderer needed, just sectioned Text widgets with varying weight.
class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cómo funciona Kredit')),
      body: ListView(
        padding: const EdgeInsets.all(KreditSpacing.card),
        children: const [
          _Lead(
            'Kredit es una aplicación 100% local para llevar el control de tus créditos '
            '— tarjetas de crédito y préstamos — sin cuentas, sin nube y sin '
            'servidores externos. Todos los datos se almacenan en tu dispositivo (SQLite local vía Drift).',
          ),
          _Section(
            icon: Icons.credit_card_outlined,
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
          _Section(
            icon: Icons.dashboard_outlined,
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
          _Section(
            icon: Icons.route_outlined,
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
          _Section(
            icon: Icons.storage_outlined,
            title: 'Datos',
            body:
                'Puedes exportar todo a un archivo JSON de respaldo e importarlo '
                'posteriormente (solicita confirmación antes de reemplazar los datos actuales). '
                '"Borrar base de datos" en Zona de Peligro elimina todo de forma '
                'permanente, previa confirmación.',
          ),
          _Section(
            icon: Icons.wifi_off_outlined,
            title: 'Sin conexión',
            body:
                'Al no depender de un servidor externo ni de la nube, Kredit funciona '
                'completamente sin conexión a internet: todos tus datos permanecen guardados en el '
                'dispositivo.',
          ),
          SizedBox(height: KreditSpacing.section),
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
    return Container(
      margin: const EdgeInsets.only(bottom: KreditSpacing.section),
      padding: const EdgeInsets.all(KreditSpacing.card),
      decoration: BoxDecoration(
        color: kredit.bgCard,
        borderRadius: BorderRadius.circular(KreditRadius.card),
        border: Border.all(color: kredit.borderCard),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          height: 1.5,
          color: kredit.textSecondary,
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
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: kredit.textPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kredit.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
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
