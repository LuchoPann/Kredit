import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krezium/data/finance_categories_catalog.dart';
import 'package:krezium/data/finance_icon_map.dart';
import 'package:krezium/providers/finance_provider.dart';
import 'package:krezium/theme/app_theme.dart';

/// Muestra el selector de categorías en un bottom sheet.
/// [tipoInicial] puede ser 'gasto' o 'ingreso'.
/// Retorna la [CatalogoCategoria] seleccionada o null si se descartó.
Future<CatalogoCategoria?> showCategoriaSelectorSheet(
  BuildContext context,
  String tipoInicial,
) {
  return showModalBottomSheet<CatalogoCategoria>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CategoriaSelectorSheet(tipoInicial: tipoInicial),
  );
}

class _CategoriaSelectorSheet extends ConsumerStatefulWidget {
  final String tipoInicial;

  const _CategoriaSelectorSheet({required this.tipoInicial});

  @override
  ConsumerState<_CategoriaSelectorSheet> createState() =>
      _CategoriaSelectorSheetState();
}

class _CategoriaSelectorSheetState
    extends ConsumerState<_CategoriaSelectorSheet> {
  late String _tipo;
  final Set<String> _expandidos = {};

  @override
  void initState() {
    super.initState();
    _tipo = widget.tipoInicial;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final asyncCats = ref.watch(allFinanceCategoriesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              // AppBar row
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.card, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'Categoría',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Próximamente')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Segmented toggle
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.card, vertical: 8),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'gasto',
                      label: Text('Gasto'),
                      icon: Icon(Icons.arrow_upward, size: 16),
                    ),
                    ButtonSegment(
                      value: 'ingreso',
                      label: Text('Ingreso'),
                      icon: Icon(Icons.arrow_downward, size: 16),
                    ),
                  ],
                  selected: {_tipo},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _tipo = selection.first;
                      _expandidos.clear();
                    });
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return _tipo == 'ingreso'
                            ? const Color(0xFF22C55E).withValues(alpha: 0.2)
                            : const Color(0xFFEF4444).withValues(alpha: 0.2);
                      }
                      return null;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return _tipo == 'ingreso'
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFEF4444);
                      }
                      return null;
                    }),
                  ),
                ),
              ),
              const Divider(height: 1),
              // List
              Expanded(
                child: asyncCats.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (rawList) {
                    final all = rawList.whereType<CatalogoCategoria>().toList();
                    final padres = all.where((c) =>
                        c.parentId == null &&
                        (c.tipo == _tipo || c.tipo == 'ambos')).toList();

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: padres.length,
                      itemBuilder: (context, index) {
                        final padre = padres[index];
                        final hijos = all
                            .where((c) => c.parentId == padre.id)
                            .toList();
                        final isExpanded = _expandidos.contains(padre.id);

                        return Column(
                          children: [
                            // Fila padre
                            ListTile(
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor:
                                    padre.color.withValues(alpha: 0.2),
                                child: Icon(
                                  iconFromKey(padre.iconoKey),
                                  size: 16,
                                  color: padre.color,
                                ),
                              ),
                              title: Text(
                                padre.nombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              trailing: hijos.isEmpty
                                  ? null
                                  : Icon(
                                      isExpanded
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                    ),
                              onTap: () {
                                setState(() {
                                  if (isExpanded) {
                                    _expandidos.remove(padre.id);
                                  } else {
                                    _expandidos.add(padre.id);
                                  }
                                });
                              },
                            ),
                            // Hijos expandibles
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              child: isExpanded
                                  ? Column(
                                      children: hijos.map((hijo) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(left: 32),
                                          child: ListTile(
                                            leading: CircleAvatar(
                                              radius: 14,
                                              backgroundColor: hijo.color
                                                  .withValues(alpha: 0.2),
                                              child: Icon(
                                                iconFromKey(hijo.iconoKey),
                                                size: 16,
                                                color: hijo.color,
                                              ),
                                            ),
                                            title: Text(hijo.nombre),
                                            onTap: () {
                                              HapticFeedback.lightImpact();
                                              Navigator.of(context)
                                                  .pop(hijo);
                                            },
                                          ),
                                        );
                                      }).toList(),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
