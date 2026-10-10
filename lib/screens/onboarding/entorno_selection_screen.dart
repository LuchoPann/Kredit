import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krezium/providers/entorno_provider.dart';

class EntornoSelectionScreen extends ConsumerStatefulWidget {
  final VoidCallback onSelected;
  const EntornoSelectionScreen({super.key, required this.onSelected});

  @override
  ConsumerState<EntornoSelectionScreen> createState() => _EntornoSelectionScreenState();
}

class _EntornoSelectionScreenState extends ConsumerState<EntornoSelectionScreen> {
  Future<void> _select(Entorno entorno) async {
    ref.read(entornoProvider.notifier).state = entorno;
    await savePreferredEntorno(entorno);
    widget.onSelected();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text(
                '¿Por dónde empezamos?',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Elige la vista que quieres ver al abrir Krezium. Puedes cambiarla desde Cuenta en cualquier momento.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 40),
              _EntornoCard(
                icono: Icons.credit_card,
                titulo: 'Créditos',
                descripcion: 'Gestiona tus tarjetas, cupos de tienda y préstamos.',
                onTap: () => _select(Entorno.creditos),
              ),
              const SizedBox(height: 16),
              _EntornoCard(
                icono: Icons.account_balance_wallet,
                titulo: 'Finanzas',
                descripcion: 'Registra tus gastos e ingresos del día a día.',
                onTap: () => _select(Entorno.finanzas),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntornoCard extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final VoidCallback onTap;

  const _EntornoCard({required this.icono, required this.titulo, required this.descripcion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icono, size: 40, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(descripcion, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
