import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krezium/data/db/database.dart';
import 'package:krezium/data/finance_categories_catalog.dart';
import 'package:krezium/data/finance_icon_map.dart';
import 'package:krezium/data/models/finance_models.dart';
import 'package:krezium/providers/database_provider.dart';
import 'package:krezium/providers/finance_provider.dart';
import 'package:krezium/screens/finanzas/categoria_selector_sheet.dart';
import 'package:krezium/theme/app_theme.dart';
import 'package:uuid/uuid.dart';

Future<void> showEditarPlantillaSheet(
  BuildContext context, {
  required WidgetRef ref,
  FinanceTemplate? template,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditarPlantillaSheet(template: template, ref: ref),
  );
}

class _EditarPlantillaSheet extends StatefulWidget {
  final FinanceTemplate? template;
  final WidgetRef ref;

  const _EditarPlantillaSheet({required this.ref, this.template});

  @override
  State<_EditarPlantillaSheet> createState() => _EditarPlantillaSheetState();
}

class _EditarPlantillaSheetState extends State<_EditarPlantillaSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _montoCtrl;
  late final TextEditingController _notasCtrl;
  late String _tipo;
  CatalogoCategoria? _categoria;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _nombreCtrl = TextEditingController(text: t?.nombre ?? '');
    _montoCtrl = TextEditingController(
        text: t?.monto != null ? t!.monto!.toStringAsFixed(2) : '');
    _notasCtrl = TextEditingController(text: t?.nota ?? '');
    _tipo = t?.tipo ?? 'gasto';

    if (t != null) {
      try {
        _categoria = todoCatalogo.firstWhere((c) => c.id == t.categoryId);
      } catch (_) {
        _categoria = null;
      }
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _montoCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

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

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final db = widget.ref.read(databaseProvider);
    final id = widget.template?.id ?? const Uuid().v4();
    final monto = double.tryParse(_montoCtrl.text.trim());

    final companion = FinanceTemplatesCompanion(
      id: Value(id),
      nombre: Value(_nombreCtrl.text.trim()),
      tipo: Value(_tipo),
      monto: Value(monto),
      categoryId: Value(_categoria?.id ?? ''),
      nota: Value(_notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim()),
      libroId: const Value(null),
      personaSitio: const Value(null),
    );

    await db.upsertFinanceTemplate(companion);
    widget.ref.invalidate(financeTemplatesByTipoProvider(null));
    widget.ref.invalidate(financeTemplatesByTipoProvider('gasto'));
    widget.ref.invalidate(financeTemplatesByTipoProvider('ingreso'));

    HapticFeedback.mediumImpact();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final isEdit = widget.template != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: scrollCtrl,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.textTertiary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  isEdit ? 'Editar plantilla' : 'Nueva plantilla',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Nombre
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Ej. Café matutino',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nombre requerido' : null,
                ),
                const SizedBox(height: 20),

                // Tipo
                Center(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'gasto', label: Text('Gasto')),
                      ButtonSegment(value: 'ingreso', label: Text('Ingreso')),
                      ButtonSegment(
                          value: 'transferencia',
                          label: Text('Transferencia')),
                    ],
                    selected: {_tipo},
                    onSelectionChanged: (s) {
                      setState(() {
                        _tipo = s.first;
                        _categoria = null;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Monto (opcional)
                TextFormField(
                  controller: _montoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Monto (opcional)',
                    hintText: '0.00',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 20),

                // Categoría
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          _colorForTipo(_tipo).withValues(alpha: 0.15),
                      child: Icon(
                        iconFromKey(_categoria?.iconoKey ?? 'receipt'),
                        color: _colorForTipo(_tipo),
                        size: 20,
                      ),
                    ),
                    title: Text(_categoria?.nombre ?? 'Seleccionar categoría'),
                    subtitle: _categoria == null
                        ? const Text('Toca para elegir')
                        : null,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final cat = await showCategoriaSelectorSheet(
                          context, _tipo);
                      if (cat != null) {
                        setState(() => _categoria = cat);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Notas
                TextFormField(
                  controller: _notasCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    hintText: 'Agrega una nota...',
                    prefixIcon: Icon(Icons.notes),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 32),

                // Guardar
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _guardar,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(isEdit ? 'Guardar cambios' : 'Crear plantilla'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
