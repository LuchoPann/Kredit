import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krezium/data/db/database.dart';
import 'package:krezium/data/models/finance_models.dart';
import 'package:krezium/providers/database_provider.dart';
import 'package:krezium/providers/finance_provider.dart';
import 'package:krezium/screens/finanzas/finanzas_libro_transacciones_screen.dart';
import 'package:krezium/theme/app_theme.dart';
import 'package:krezium/widgets/color_picker_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// ─── Color helper ─────────────────────────────────────────────────────────────
Color _colorFromHex(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

// ─── Public screen ────────────────────────────────────────────────────────────
class FinanzasCuentasScreen extends ConsumerStatefulWidget {
  const FinanzasCuentasScreen({super.key});

  @override
  ConsumerState<FinanzasCuentasScreen> createState() =>
      _FinanzasCuentasScreenState();
}

class _FinanzasCuentasScreenState extends ConsumerState<FinanzasCuentasScreen> {
  bool _autoPushDone = false;

  @override
  void initState() {
    super.initState();
    // listenManual (no ref.listen): permite fireImmediately fuera de build.
    ref.listenManual<AsyncValue<List<FinanceAccountRow>>>(
      financeAccountsProvider,
      (prev, next) {
        if (next.hasValue && !_autoPushDone) {
          _checkAndAutoPush(next.value!);
        }
      },
      fireImmediately: true,
    );
  }

  Future<void> _checkAndAutoPush(List<FinanceAccountRow> rows) async {
    if (_autoPushDone) return;
    final prefs = await SharedPreferences.getInstance();
    final defaultId = prefs.getString('finanzas_libro_default');
    if (defaultId == null || !mounted) return;

    final match = rows.where((r) => r.id == defaultId).toList();
    if (match.isEmpty || !mounted) return;

    _autoPushDone = true;
    final libro = FinanceAccount.fromRow(match.first);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FinanzasLibroTransaccionesScreen(libro: libro),
      ),
    );
  }

  void _mostrarNuevoRegistroSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (_) => _NuevoRegistroSheet(
        onCreado: () => ref.invalidate(financeAccountsProvider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncLibros = ref.watch(financeAccountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registros'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _mostrarNuevoRegistroSheet,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarNuevoRegistroSheet,
        child: const Icon(Icons.add),
      ),
      body: asyncLibros.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rows) {
          if (rows.isEmpty) return _EmptyState(onCrear: _mostrarNuevoRegistroSheet);
          final libros = rows.map(FinanceAccount.fromRow).toList();
          return ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.card,
              vertical: AppSpacing.section,
            ),
            itemCount: libros.length,
            itemBuilder: (context, index) {
              final libro = libros[index];
              return _LibroCard(
                libro: libro,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        FinanzasLibroTransaccionesScreen(libro: libro),
                  ),
                ),
                onFavorito: () => _marcarFavorito(libro),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _marcarFavorito(FinanceAccount libro) async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('finanzas_libro_default', libro.id);

    final db = ref.read(databaseProvider);
    await db.clearFinanceAccountFavoritos();
    if (!mounted) return;
    await db.upsertFinanceAccount(
      FinanceAccountsCompanion(
        id: Value(libro.id),
        nombre: Value(libro.nombre),
        tipo: Value(libro.tipo),
        icono: Value(libro.icono),
        color: Value(libro.color),
        saldoInicial: Value(libro.saldoInicial),
        activa: Value(libro.activa),
        orden: Value(libro.orden),
        esFavorito: const Value(true),
      ),
    );
    ref.invalidate(financeAccountsProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro predeterminado actualizado')),
      );
    }
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onCrear;
  const _EmptyState({required this.onCrear});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.book_outlined,
            size: AppIconSize.large,
            color: colors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.card),
          Text(
            'Crea tu primer registro',
            style: TextStyle(
              fontSize: AppTextSize.body,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          ElevatedButton(
            onPressed: onCrear,
            child: const Text('Nuevo registro'),
          ),
        ],
      ),
    );
  }
}

// ─── Libro card ───────────────────────────────────────────────────────────────
class _LibroCard extends StatelessWidget {
  final FinanceAccount libro;
  final VoidCallback onTap;
  final VoidCallback onFavorito;

  const _LibroCard({
    required this.libro,
    required this.onTap,
    required this.onFavorito,
  });

  @override
  Widget build(BuildContext context) {
    final libroColor = _colorFromHex(libro.color);
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    return Dismissible(
      key: ValueKey(libro.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: AppSpacing.card),
        color: libroColor.withValues(alpha: 0.2),
        child: Icon(Icons.star, color: libroColor),
      ),
      confirmDismiss: (direction) async {
        onFavorito();
        return false; // don't actually dismiss
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.tile),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border(
              left: BorderSide(color: libroColor, width: 4),
              top: BorderSide(color: colors.borderCard),
              right: BorderSide(color: colors.borderCard),
              bottom: BorderSide(color: colors.borderCard),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.card),
            child: Row(
              children: [
                Hero(
                  tag: 'libro_icon_${libro.id}',
                  child: CircleAvatar(
                    backgroundColor: libroColor.withValues(alpha: 0.2),
                    radius: 24,
                    child: Text(
                      libro.icono.isNotEmpty ? libro.icono[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: libroColor,
                        fontWeight: FontWeight.bold,
                        fontSize: AppTextSize.heading,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.tile),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        libro.nombre,
                        style: const TextStyle(
                          fontSize: AppTextSize.body,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        libro.tipo,
                        style: TextStyle(
                          fontSize: AppTextSize.caption,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${libro.saldoInicial.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: AppTextSize.heading,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Ingresos: —',
                            style: TextStyle(
                              fontSize: AppTextSize.caption,
                              color: colors.success,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.tile),
                          Text(
                            'Gastos: —',
                            style: TextStyle(
                              fontSize: AppTextSize.caption,
                              color: colors.danger,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (libro.esFavorito)
                  const Icon(Icons.star, color: Colors.amber, size: AppIconSize.small),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sheet crear registro ─────────────────────────────────────────────────────
class _NuevoRegistroSheet extends ConsumerStatefulWidget {
  final VoidCallback onCreado;
  const _NuevoRegistroSheet({required this.onCreado});

  @override
  ConsumerState<_NuevoRegistroSheet> createState() => _NuevoRegistroSheetState();
}

class _NuevoRegistroSheetState extends ConsumerState<_NuevoRegistroSheet> {
  final _nombreController = TextEditingController();
  final _saldoController = TextEditingController(text: '0');
  Color _color = const Color(0xFFEF4444);
  bool _guardando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _saldoController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) return;
    setState(() => _guardando = true);
    final db = ref.read(databaseProvider);
    final id = const Uuid().v4();
    final inicial = double.tryParse(_saldoController.text.replaceAll(',', '.')) ?? 0.0;
    await db.upsertFinanceAccount(FinanceAccountsCompanion.insert(
      id: id,
      nombre: nombre,
      tipo: 'registro',
      icono: nombre,
      color: '#${colorToHex(_color)}',
      saldoInicial: Value(inicial),
    ));
    widget.onCreado();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kredit = theme.extension<AppThemeColors>()!;
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
              decoration: BoxDecoration(
                color: kredit.borderCard,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Nuevo registro', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            controller: _nombreController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Nombre del registro',
              hintText: 'Ej: Gastos personales',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.tile)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _saldoController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Saldo inicial (opcional)',
              prefixText: '\$ ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.tile)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Color', style: TextStyle(fontSize: AppTextSize.caption, color: kredit.textSecondary)),
          const SizedBox(height: 8),
          ColorPickerField(
            color: _color,
            onColorChanged: (c) => setState(() => _color = c),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Crear registro'),
            ),
          ),
        ],
      ),
    );
  }
}
