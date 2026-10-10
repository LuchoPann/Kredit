import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krezium/data/db/database.dart';
import 'package:krezium/data/finance_categories_catalog.dart';
import 'package:krezium/data/finance_icon_map.dart';
import 'package:krezium/providers/database_provider.dart';
import 'package:krezium/providers/finance_provider.dart';
import 'package:krezium/theme/app_theme.dart';
import 'package:uuid/uuid.dart';

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

  Future<void> _crearCategoria() async {
    final result = await showModalBottomSheet<CatalogoCategoria?>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _NuevaCategoriaSheet(tipoInicial: _tipo),
    );
    if (result != null && mounted) {
      ref.invalidate(allFinanceCategoriesProvider);
      Navigator.of(context).pop(result);
    }
  }

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
                      onPressed: _crearCategoria,
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

// ─── Sheet crear categoría personalizada ──────────────────────────────────────
class _NuevaCategoriaSheet extends ConsumerStatefulWidget {
  final String tipoInicial;
  const _NuevaCategoriaSheet({required this.tipoInicial});

  @override
  ConsumerState<_NuevaCategoriaSheet> createState() => _NuevaCategoriaSheetState();
}

class _NuevaCategoriaSheetState extends ConsumerState<_NuevaCategoriaSheet> {
  final _nombreCtrl = TextEditingController();
  late String _tipo;
  String _colorHex = 'EF4444';
  bool _guardando = false;

  static const _colores = [
    ('EF4444', 'Rojo'), ('3B82F6', 'Azul'), ('22C55E', 'Verde'),
    ('F59E0B', 'Amarillo'), ('8B5CF6', 'Morado'), ('EC4899', 'Rosa'),
    ('14B8A6', 'Verde azul'), ('F97316', 'Naranja'), ('6B7280', 'Gris'),
  ];

  @override
  void initState() {
    super.initState();
    _tipo = widget.tipoInicial;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) return;
    setState(() => _guardando = true);

    final db = ref.read(databaseProvider);
    final id = const Uuid().v4();
    await db.upsertFinanceCategory(FinanceCategoriesCompanion(
      id: Value(id),
      nombre: Value(nombre),
      icono: const Value('label'),
      color: Value('#$_colorHex'),
      tipo: Value(_tipo),
      archivada: const Value(false),
    ));

    // Retornar como CatalogoCategoria sintético para selección inmediata
    final cat = CatalogoCategoria(
      id: id,
      nombre: nombre,
      icono: Icons.label_outline,
      color: Color(int.parse('FF$_colorHex', radix: 16)),
      tipo: _tipo,
      iconoKey: 'label',
    );
    if (mounted) Navigator.of(context).pop(cat);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tc = theme.extension<AppThemeColors>()!;
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: tc.borderCard, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Nueva categoría', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'gasto', label: Text('Gasto'), icon: Icon(Icons.arrow_upward, size: 14)),
              ButtonSegment(value: 'ingreso', label: Text('Ingreso'), icon: Icon(Icons.arrow_downward, size: 14)),
              ButtonSegment(value: 'ambos', label: Text('Ambos'), icon: Icon(Icons.swap_vert, size: 14)),
            ],
            selected: {_tipo},
            onSelectionChanged: (s) => setState(() => _tipo = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nombreCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Nombre',
              hintText: 'Ej: Mascotas',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.tile)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Color', style: TextStyle(fontSize: AppTextSize.caption, color: tc.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _colores.map((c) {
              final selected = _colorHex == c.$1;
              final color = Color(int.parse('FF${c.$1}', radix: 16));
              return GestureDetector(
                onTap: () => setState(() => _colorHex = c.$1),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: color, shape: BoxShape.circle,
                    border: selected ? Border.all(color: theme.colorScheme.onSurface, width: 3) : null,
                  ),
                  child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Crear categoría'),
            ),
          ),
        ],
      ),
    );
  }
}
