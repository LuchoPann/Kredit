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
import 'package:shared_preferences/shared_preferences.dart';

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

  void _mostrarNuevoLibroSheet() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Crear libro — Próximamente')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncLibros = ref.watch(financeAccountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuentas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Configurar categorías — Próximamente'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _mostrarNuevoLibroSheet,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarNuevoLibroSheet,
        child: const Icon(Icons.add),
      ),
      body: asyncLibros.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rows) {
          if (rows.isEmpty) return _EmptyState(onCrear: _mostrarNuevoLibroSheet);
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
        const SnackBar(content: Text('Libro predeterminado actualizado')),
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
            'Crea tu primer libro de registro',
            style: TextStyle(
              fontSize: AppTextSize.body,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          ElevatedButton(
            onPressed: onCrear,
            child: const Text('Crear libro'),
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

