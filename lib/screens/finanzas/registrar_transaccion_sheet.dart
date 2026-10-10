import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;
import 'package:krezium/data/db/database.dart';
import 'package:krezium/data/finance_categories_catalog.dart';
import 'package:krezium/providers/database_provider.dart';
import 'package:krezium/providers/finance_provider.dart';

class RegistrarTransaccionSheet extends ConsumerStatefulWidget {
  const RegistrarTransaccionSheet({super.key});

  @override
  ConsumerState<RegistrarTransaccionSheet> createState() => _RegistrarTransaccionSheetState();
}

class _RegistrarTransaccionSheetState extends ConsumerState<RegistrarTransaccionSheet> {
  String _tipo = 'gasto';
  String? _categoryId;
  String? _accountId;
  final String _fecha = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final _montoCtrl = TextEditingController();
  final _notaCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _montoCtrl.dispose();
    _notaCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final montoStr = _montoCtrl.text.replaceAll('.', '').replaceAll(',', '.');
    final monto = double.tryParse(montoStr);
    if (monto == null || monto <= 0 || _categoryId == null || _accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos requeridos')),
      );
      return;
    }
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    await db.upsertFinanceTransaction(FinanceTransactionsCompanion.insert(
      id: const Uuid().v4(),
      accountId: _accountId!,
      categoryId: _categoryId!,
      tipo: _tipo,
      monto: monto,
      fecha: _fecha,
      nota: Value(_notaCtrl.text),
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(financeAccountsProvider);
    final cats = catalogoFinanzas.where((c) => c.tipo == _tipo || c.tipo == 'ambos').toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nueva transacción', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'ingreso', label: Text('Ingreso'), icon: Icon(Icons.arrow_upward)),
                ButtonSegment(value: 'gasto', label: Text('Gasto'), icon: Icon(Icons.arrow_downward)),
              ],
              selected: {_tipo},
              onSelectionChanged: (s) => setState(() { _tipo = s.first; _categoryId = null; }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _montoCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monto', prefixText: r'$ '),
            ),
            const SizedBox(height: 16),
            Text('Categoría', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cats.map((c) {
                final sel = _categoryId == c.id;
                return FilterChip(
                  avatar: Icon(c.icono, size: 16, color: c.color),
                  label: Text(c.nombre),
                  selected: sel,
                  onSelected: (_) => setState(() => _categoryId = c.id),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            accountsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error cuentas: $e'),
              data: (accounts) {
                if (accounts.isEmpty) {
                  return const Text('No tienes cuentas. Crea una desde Cuenta → Finanzas.');
                }
                _accountId ??= accounts.first.id;
                return DropdownButtonFormField<String>(
                  value: _accountId,
                  decoration: const InputDecoration(labelText: 'Cuenta'),
                  items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.nombre))).toList(),
                  onChanged: (v) => setState(() => _accountId = v),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(controller: _notaCtrl, decoration: const InputDecoration(labelText: 'Nota (opcional)')),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
