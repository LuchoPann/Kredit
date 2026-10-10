import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krezium/data/finance_categories_catalog.dart';
import 'package:krezium/data/finance_icon_map.dart';
import 'package:krezium/data/models/finance_models.dart';
import 'package:krezium/providers/database_provider.dart';
import 'package:krezium/providers/finance_provider.dart';
import 'package:krezium/screens/finanzas/editar_plantilla_sheet.dart';
import 'package:krezium/screens/finanzas/nueva_transaccion_sheet.dart';

class FinanzasPlantillasScreen extends ConsumerStatefulWidget {
  const FinanzasPlantillasScreen({super.key});

  @override
  ConsumerState<FinanzasPlantillasScreen> createState() =>
      _FinanzasPlantillasScreenState();
}

class _FinanzasPlantillasScreenState
    extends ConsumerState<FinanzasPlantillasScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Plantillas'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Gastos'),
              Tab(text: 'Ingresos'),
              Tab(text: 'Todos'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PlantillasTab(tipo: 'gasto'),
            _PlantillasTab(tipo: 'ingreso'),
            _PlantillasTab(tipo: null),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            showEditarPlantillaSheet(context, ref: ref);
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _PlantillasTab extends ConsumerWidget {
  final String? tipo;

  const _PlantillasTab({required this.tipo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(financeTemplatesByTipoProvider(tipo));

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: async.when(
        loading: () => const Center(
          key: ValueKey('loading'),
          child: CircularProgressIndicator(),
        ),
        error: (e, _) => Center(
          key: const ValueKey('error'),
          child: Text('Error: $e'),
        ),
        data: (templates) {
          if (templates.isEmpty) {
            return Center(
              key: const ValueKey('empty'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('Sin plantillas',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Toca + para crear una',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            );
          }
          return ListView.builder(
            key: const ValueKey('list'),
            itemCount: templates.length,
            itemBuilder: (ctx, i) =>
                _PlantillaTile(template: templates[i], tipo: tipo),
          );
        },
      ),
    );
  }
}

class _PlantillaTile extends ConsumerWidget {
  final FinanceTemplate template;
  final String? tipo;

  const _PlantillaTile({required this.template, required this.tipo});

  Color _colorForTipo(String t) {
    switch (t) {
      case 'ingreso':
        return const Color(0xFF22C55E);
      case 'gasto':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  String? _nombreCategoria(String categoryId) {
    try {
      return todoCatalogo
          .firstWhere((c) => c.id == categoryId)
          .nombre;
    } catch (_) {
      return null;
    }
  }

  String? _iconoKeyCategoria(String categoryId) {
    try {
      return todoCatalogo
          .firstWhere((c) => c.id == categoryId)
          .iconoKey;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _colorForTipo(template.tipo);
    final nombreCat = _nombreCategoria(template.categoryId);
    final iconoKey = _iconoKeyCategoria(template.categoryId);
    final montoStr = template.monto != null
        ? '\$${template.monto!.toStringAsFixed(2)}'
        : 'Sin monto fijo';
    final subtitleStr =
        nombreCat != null ? '$montoStr · $nombreCat' : montoStr;

    return Dismissible(
      key: ValueKey(template.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Eliminar plantilla'),
            content:
                Text('¿Eliminar "${template.nombre}"? Esta acción no se puede deshacer.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Eliminar',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        final db = ref.read(databaseProvider);
        await db.deleteFinanceTemplate(template.id);
        ref.invalidate(financeTemplatesByTipoProvider(null));
        ref.invalidate(financeTemplatesByTipoProvider('gasto'));
        ref.invalidate(financeTemplatesByTipoProvider('ingreso'));
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(
            iconFromKey(iconoKey ?? 'receipt'),
            color: color,
            size: 20,
          ),
        ),
        title: Text(template.nombre),
        subtitle: Text(
          subtitleStr,
          style: TextStyle(
            color: Theme.of(context).colorScheme.outline,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton<String>(
              onSelected: (val) async {
                if (val == 'editar') {
                  HapticFeedback.lightImpact();
                  await showEditarPlantillaSheet(context,
                      ref: ref, template: template);
                } else if (val == 'eliminar') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Eliminar plantilla'),
                      content: Text(
                          '¿Eliminar "${template.nombre}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Eliminar',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final db = ref.read(databaseProvider);
                    await db.deleteFinanceTemplate(template.id);
                    ref.invalidate(financeTemplatesByTipoProvider(null));
                    ref.invalidate(financeTemplatesByTipoProvider('gasto'));
                    ref.invalidate(financeTemplatesByTipoProvider('ingreso'));
                  }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'editar', child: Text('Editar')),
                PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
              ],
            ),
          ],
        ),
        onTap: () {
          HapticFeedback.lightImpact();
          showNuevaTransaccionSheet(context, template: template);
        },
      ),
    );
  }
}
