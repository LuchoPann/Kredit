import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krezium/data/db/database.dart';
import 'package:krezium/data/finance_categories_catalog.dart';
import 'package:krezium/data/models/finance_models.dart';
import 'package:krezium/providers/database_provider.dart';
import 'package:krezium/providers/finance_provider.dart';
import 'package:krezium/screens/finanzas/categoria_selector_sheet.dart';
import 'package:krezium/theme/app_theme.dart';
import 'package:uuid/uuid.dart';

// ─── Color tokens por tipo ────────────────────────────────────────────────────
const _colorIngreso = Color(0xFF22C55E);
const _colorGasto = Color(0xFFEF4444);
const _colorTransfer = Color(0xFF3B82F6);

Color _tipoColor(String tipo) => switch (tipo) {
      'ingreso' => _colorIngreso,
      'gasto' => _colorGasto,
      _ => _colorTransfer,
    };

// ─── Public API ───────────────────────────────────────────────────────────────
Future<void> showNuevaTransaccionSheet(
  BuildContext context, {
  String? libroId,
  CatalogoCategoria? categoriaInicial,
  FinanceTemplate? template,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _NuevaTransaccionSheet(
      libroIdInicial: libroId,
      categoriaInicial: categoriaInicial,
      template: template,
    ),
  );
}

// ─── Widget principal ─────────────────────────────────────────────────────────
class _NuevaTransaccionSheet extends ConsumerStatefulWidget {
  final String? libroIdInicial;
  final CatalogoCategoria? categoriaInicial;
  final FinanceTemplate? template;

  const _NuevaTransaccionSheet({
    this.libroIdInicial,
    this.categoriaInicial,
    this.template,
  });

  @override
  ConsumerState<_NuevaTransaccionSheet> createState() =>
      _NuevaTransaccionSheetState();
}

class _NuevaTransaccionSheetState
    extends ConsumerState<_NuevaTransaccionSheet> {
  // ── estado ────────────────────────────────────────────────────────────────
  int _paso = 1;
  String _tipo = 'gasto';
  String? _libroId;
  String? _libroDestinoId; // solo transferencia
  CatalogoCategoria? _categoriaSeleccionada;
  late DateTime _fecha;
  late TimeOfDay _hora;
  final _montoCtrl = TextEditingController();
  final _ordenanteCtrl = TextEditingController();
  final _notaCtrl = TextEditingController();
  final _montoFocus = FocusNode();
  bool _guardando = false;
  bool _montoValido = false;

  @override
  void initState() {
    super.initState();
    _montoCtrl.addListener(_onMontoChanged);
    _fecha = DateTime.now();
    _hora = TimeOfDay.now();
    _libroId = widget.libroIdInicial;
    _categoriaSeleccionada = widget.categoriaInicial;

    final t = widget.template;
    if (t != null) {
      _tipo = t.tipo;
      _libroId = t.libroId ?? widget.libroIdInicial;
      _ordenanteCtrl.text = t.personaSitio ?? '';
      _notaCtrl.text = t.nota ?? '';
      if (t.monto != null) {
        _montoCtrl.text = t.monto! % 1 == 0
            ? t.monto!.toStringAsFixed(0)
            : t.monto!.toStringAsFixed(2);
      }
      // Buscar categoría del template en el catálogo
      try {
        _categoriaSeleccionada = catalogoFinanzas.firstWhere(
          (c) => c.id == t.categoryId,
        );
      } catch (_) {}
      // Ir directo al paso 2 si hay template
      _paso = 2;
    }
  }

  void _onMontoChanged() {
    final v = double.tryParse(_montoCtrl.text.replaceAll(',', '.'));
    final valid = v != null && v > 0;
    if (valid != _montoValido) setState(() => _montoValido = valid);
  }

  @override
  void dispose() {
    _montoCtrl.removeListener(_onMontoChanged);
    _montoCtrl.dispose();
    _ordenanteCtrl.dispose();
    _notaCtrl.dispose();
    _montoFocus.dispose();
    super.dispose();
  }

  // ── helpers ───────────────────────────────────────────────────────────────
  String _formatFecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatHora(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _pickHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _hora,
    );
    if (picked != null) setState(() => _hora = picked);
  }

  Future<void> _seleccionarCategoria() async {
    final tipo = _tipo == 'transferencia' ? 'gasto' : _tipo;
    final cat = await showCategoriaSelectorSheet(context, tipo);
    if (cat != null) setState(() => _categoriaSeleccionada = cat);
  }

  Future<void> _guardar(List<FinanceAccount> libros) async {
    if (_guardando) return;
    final monto = double.tryParse(_montoCtrl.text.replaceAll(',', '.'));
    if (monto == null || monto <= 0) return;
    if (_libroId == null) return;
    if (_categoriaSeleccionada == null && _tipo != 'transferencia') return;

    setState(() => _guardando = true);
    try {
      final db = ref.read(databaseProvider);
      final id = const Uuid().v4();
      final fechaStr =
          '${_fecha.year}-${_fecha.month.toString().padLeft(2, '0')}-${_fecha.day.toString().padLeft(2, '0')}';
      final horaStr = _formatHora(_hora);
      final ordenante = _ordenanteCtrl.text.trim();

      // Upsert lugar si hay texto
      if (ordenante.isNotEmpty) {
        // Buscar si ya existe para incrementar usados
        final places = await db.getFinancePlaces();
        final existing = places.where((p) => p.nombre.toLowerCase() == ordenante.toLowerCase()).firstOrNull;
        if (existing != null) {
          await db.upsertFinancePlace(FinancePlacesCompanion(
            id: Value(existing.id),
            nombre: Value(existing.nombre),
            usados: Value(existing.usados + 1),
          ));
        } else {
          await db.upsertFinancePlace(FinancePlacesCompanion(
            id: Value(const Uuid().v4()),
            nombre: Value(ordenante),
            usados: const Value(1),
          ));
        }
      }

      // Guardar transacción
      await db.upsertFinanceTransaction(FinanceTransactionsCompanion(
        id: Value(id),
        accountId: Value(_libroId!),
        categoryId: Value(_categoriaSeleccionada?.id ?? 'transferencia'),
        tipo: Value(_tipo),
        monto: Value(monto),
        fecha: Value(fechaStr),
        nota: Value(_notaCtrl.text.trim()),
        hora: Value(horaStr),
        personaSitio: Value(ordenante.isEmpty ? null : ordenante),
        transferToAccountId: Value(_tipo == 'transferencia' ? _libroDestinoId : null),
      ));

      await HapticFeedback.mediumImpact();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final tc = Theme.of(context).extension<AppThemeColors>()!;
    final librosAsync = ref.watch(financeAccountsProvider);
    final libros = librosAsync.valueOrNull?.map(FinanceAccount.fromRow).toList() ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: tc.bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: tc.borderCard,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, anim) {
                  final offset = child.key == const ValueKey(1)
                      ? const Offset(-1, 0)
                      : const Offset(1, 0);
                  return SlideTransition(
                    position: Tween(begin: offset, end: Offset.zero)
                        .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                    child: child,
                  );
                },
                child: _paso == 1
                    ? _Paso1(
                        key: const ValueKey(1),
                        tipo: _tipo,
                        libroId: _libroId,
                        libroDestinoId: _libroDestinoId,
                        libros: libros,
                        scrollCtrl: scrollCtrl,
                        onTipoChanged: (v) => setState(() => _tipo = v),
                        onLibroChanged: (v) => setState(() => _libroId = v),
                        onLibroDestinoChanged: (v) =>
                            setState(() => _libroDestinoId = v),
                        onContinuar: () {
                          if (_libroId != null) {
                            setState(() => _paso = 2);
                            Future.delayed(
                              const Duration(milliseconds: 320),
                              () => _montoFocus.requestFocus(),
                            );
                          }
                        },
                      )
                    : _Paso2(
                        key: const ValueKey(2),
                        tipo: _tipo,
                        categoriaSeleccionada: _categoriaSeleccionada,
                        fecha: _fecha,
                        hora: _hora,
                        montoCtrl: _montoCtrl,
                        ordenanteCtrl: _ordenanteCtrl,
                        notaCtrl: _notaCtrl,
                        montoFocus: _montoFocus,
                        guardando: _guardando,
                        montoValido: _montoValido,
                        scrollCtrl: scrollCtrl,
                        onSeleccionarCategoria: _seleccionarCategoria,
                        onPickFecha: _pickFecha,
                        onPickHora: _pickHora,
                        onFechaAnterior: () =>
                            setState(() => _fecha = _fecha.subtract(const Duration(days: 1))),
                        onFechaSiguiente: () =>
                            setState(() => _fecha = _fecha.add(const Duration(days: 1))),
                        onHoraAnterior: () {
                          final mins = _hora.hour * 60 + _hora.minute - 60;
                          final total = ((mins % 1440) + 1440) % 1440;
                          setState(() => _hora = TimeOfDay(hour: total ~/ 60, minute: total % 60));
                        },
                        onHoraSiguiente: () {
                          final mins = _hora.hour * 60 + _hora.minute + 60;
                          final total = mins % 1440;
                          setState(() => _hora = TimeOfDay(hour: total ~/ 60, minute: total % 60));
                        },
                        onVolver: () => setState(() => _paso = 1),
                        onGuardar: () => _guardar(libros),
                        formatFecha: _formatFecha,
                        formatHora: _formatHora,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Paso 1: picker rápido ────────────────────────────────────────────────────
class _Paso1 extends StatelessWidget {
  final String tipo;
  final String? libroId;
  final String? libroDestinoId;
  final List<FinanceAccount> libros;
  final ScrollController scrollCtrl;
  final ValueChanged<String> onTipoChanged;
  final ValueChanged<String?> onLibroChanged;
  final ValueChanged<String?> onLibroDestinoChanged;
  final VoidCallback onContinuar;

  const _Paso1({
    super.key,
    required this.tipo,
    required this.libroId,
    required this.libroDestinoId,
    required this.libros,
    required this.scrollCtrl,
    required this.onTipoChanged,
    required this.onLibroChanged,
    required this.onLibroDestinoChanged,
    required this.onContinuar,
  });

  @override
  Widget build(BuildContext context) {
    final tc = Theme.of(context).extension<AppThemeColors>()!;
    final color = _tipoColor(tipo);

    return ListView(
      controller: scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        // Título
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Text(
            'Nueva Transacción',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: AppTextSize.heading,
              fontWeight: FontWeight.w700,
              color: tc.textPrimary,
            ),
          ),
        ),

        // Tipo
        Text('Tipo', style: _labelStyle(tc)),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'ingreso', label: Text('Ingreso'), icon: Icon(Icons.arrow_downward)),
            ButtonSegment(value: 'gasto', label: Text('Gasto'), icon: Icon(Icons.arrow_upward)),
            ButtonSegment(value: 'transferencia', label: Text('Transferir'), icon: Icon(Icons.swap_horiz)),
          ],
          selected: {tipo},
          onSelectionChanged: (s) => onTipoChanged(s.first),
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: color.withValues(alpha: 0.18),
            selectedForegroundColor: color,
          ),
        ),
        const SizedBox(height: 24),

        // Libro origen
        Text('Libro', style: _labelStyle(tc)),
        const SizedBox(height: 8),
        _LibroSelector(
          libros: libros,
          libroId: libroId,
          onChanged: onLibroChanged,
          tc: tc,
        ),

        // Libro destino (transferencia)
        if (tipo == 'transferencia') ...[
          const SizedBox(height: 16),
          Text('Destino', style: _labelStyle(tc)),
          const SizedBox(height: 8),
          _LibroSelector(
            libros: libros,
            libroId: libroDestinoId,
            onChanged: onLibroDestinoChanged,
            tc: tc,
            excludeId: libroId,
          ),
        ],

        const SizedBox(height: 32),

        // Botón Continuar
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: libroId != null ? onContinuar : null,
            style: FilledButton.styleFrom(backgroundColor: color),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continuar',
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontWeight: FontWeight.w700,
                    fontSize: AppTextSize.body,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: AppIconSize.small),
              ],
            ),
          ),
        ),
      ],
    );
  }

  TextStyle _labelStyle(AppThemeColors tc) => TextStyle(
        fontFamily: 'Outfit',
        fontSize: AppTextSize.caption,
        fontWeight: FontWeight.w600,
        color: tc.textSecondary,
        letterSpacing: 0.8,
      );
}

// ─── Selector de libro ────────────────────────────────────────────────────────
class _LibroSelector extends StatelessWidget {
  final List<FinanceAccount> libros;
  final String? libroId;
  final ValueChanged<String?> onChanged;
  final AppThemeColors tc;
  final String? excludeId;

  const _LibroSelector({
    required this.libros,
    required this.libroId,
    required this.onChanged,
    required this.tc,
    this.excludeId,
  });

  @override
  Widget build(BuildContext context) {
    final available = excludeId != null
        ? libros.where((l) => l.id != excludeId).toList()
        : libros;

    if (available.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tc.bgSecondary,
          borderRadius: BorderRadius.circular(AppRadius.tile),
          border: Border.all(color: tc.borderCard),
        ),
        child: Text(
          'No hay libros disponibles',
          style: TextStyle(color: tc.textSecondary, fontSize: AppTextSize.body),
        ),
      );
    }

    final selected = available.where((l) => l.id == libroId).firstOrNull;

    return Container(
      decoration: BoxDecoration(
        color: tc.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(color: tc.borderCard),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: libroId,
          hint: Text('Seleccionar libro', style: TextStyle(color: tc.textTertiary)),
          isExpanded: true,
          dropdownColor: tc.bgCard,
          items: available.map((l) => DropdownMenuItem(
            value: l.id,
            child: Row(
              children: [
                Icon(Icons.book_outlined, size: AppIconSize.small, color: tc.textSecondary),
                const SizedBox(width: 8),
                Text(l.nombre, style: TextStyle(color: tc.textPrimary, fontSize: AppTextSize.body)),
              ],
            ),
          )).toList(),
          onChanged: onChanged,
          selectedItemBuilder: selected != null
              ? (_) => available.map((_) => Row(
                    children: [
                      Icon(Icons.book_outlined, size: AppIconSize.small, color: tc.textSecondary),
                      const SizedBox(width: 8),
                      Text(selected.nombre, style: TextStyle(color: tc.textPrimary, fontSize: AppTextSize.body)),
                    ],
                  )).toList()
              : null,
        ),
      ),
    );
  }
}

// ─── Paso 2: detalle ──────────────────────────────────────────────────────────
class _Paso2 extends ConsumerWidget {
  final String tipo;
  final CatalogoCategoria? categoriaSeleccionada;
  final DateTime fecha;
  final TimeOfDay hora;
  final TextEditingController montoCtrl;
  final TextEditingController ordenanteCtrl;
  final TextEditingController notaCtrl;
  final FocusNode montoFocus;
  final bool guardando;
  final bool montoValido;
  final ScrollController scrollCtrl;
  final VoidCallback onSeleccionarCategoria;
  final VoidCallback onPickFecha;
  final VoidCallback onPickHora;
  final VoidCallback onFechaAnterior;
  final VoidCallback onFechaSiguiente;
  final VoidCallback onHoraAnterior;
  final VoidCallback onHoraSiguiente;
  final VoidCallback onVolver;
  final VoidCallback onGuardar;
  final String Function(DateTime) formatFecha;
  final String Function(TimeOfDay) formatHora;

  const _Paso2({
    super.key,
    required this.tipo,
    required this.categoriaSeleccionada,
    required this.fecha,
    required this.hora,
    required this.montoCtrl,
    required this.ordenanteCtrl,
    required this.notaCtrl,
    required this.montoFocus,
    required this.guardando,
    required this.montoValido,
    required this.scrollCtrl,
    required this.onSeleccionarCategoria,
    required this.onPickFecha,
    required this.onPickHora,
    required this.onFechaAnterior,
    required this.onFechaSiguiente,
    required this.onHoraAnterior,
    required this.onHoraSiguiente,
    required this.onVolver,
    required this.onGuardar,
    required this.formatFecha,
    required this.formatHora,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = Theme.of(context).extension<AppThemeColors>()!;
    final color = _tipoColor(tipo);
    final placesAsync = ref.watch(financePlacesProvider);
    final places = placesAsync.valueOrNull ?? [];
    // Sort by usados DESC
    final placesSorted = [...places]..sort((a, b) => b.usados.compareTo(a.usados));

    return ListView(
      controller: scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        // Encabezado con botón volver
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onVolver,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Text(
              switch (tipo) {
                'ingreso' => 'Nuevo Ingreso',
                'gasto' => 'Nuevo Gasto',
                _ => 'Transferencia',
              },
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: AppTextSize.heading,
                fontWeight: FontWeight.w700,
                color: tc.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Campo Importe
        TextField(
          controller: montoCtrl,
          focusNode: montoFocus,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [_MontoFormatter()],
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: color,
          ),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color.withValues(alpha: 0.35),
            ),
            prefixText: '\$  ',
            prefixStyle: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color.withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor: color.withValues(alpha: 0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.tile),
              borderSide: BorderSide(color: color.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.tile),
              borderSide: BorderSide(color: color.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.tile),
              borderSide: BorderSide(color: color, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Fecha
        _SectionLabel('Fecha', tc),
        const SizedBox(height: 6),
        _DateTimeRow(
          label: formatFecha(fecha),
          onPrev: onFechaAnterior,
          onNext: onFechaSiguiente,
          onTap: onPickFecha,
          tc: tc,
        ),
        const SizedBox(height: 16),

        // Hora
        _SectionLabel('Hora', tc),
        const SizedBox(height: 6),
        _DateTimeRow(
          label: formatHora(hora),
          onPrev: onHoraAnterior,
          onNext: onHoraSiguiente,
          onTap: onPickHora,
          tc: tc,
        ),
        const SizedBox(height: 20),

        // Ordenante / Lugar
        _SectionLabel('Lugar / Ordenante', tc),
        const SizedBox(height: 6),
        _OrdenanteField(
          ordenanteCtrl: ordenanteCtrl,
          placesSorted: placesSorted,
          tc: tc,
        ),
        const SizedBox(height: 20),

        // Categoría
        _SectionLabel('Categoría', tc),
        const SizedBox(height: 6),
        OutlinedButton(
          onPressed: tipo != 'transferencia' ? onSeleccionarCategoria : null,
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            side: BorderSide(color: tc.borderCard),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.tile),
            ),
          ),
          child: categoriaSeleccionada != null
              ? Row(
                  children: [
                    CircleAvatar(
                      radius: 8,
                      backgroundColor: categoriaSeleccionada!.color,
                    ),
                    const SizedBox(width: 8),
                    Icon(categoriaSeleccionada!.icono, size: AppIconSize.small, color: categoriaSeleccionada!.color),
                    const SizedBox(width: 8),
                    Text(
                      categoriaSeleccionada!.nombre,
                      style: TextStyle(color: tc.textPrimary, fontSize: AppTextSize.body),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Icon(Icons.label_outline, size: AppIconSize.small, color: tc.textTertiary),
                    const SizedBox(width: 8),
                    Text(
                      tipo == 'transferencia' ? 'Sin categoría (transferencia)' : 'Seleccionar categoría',
                      style: TextStyle(color: tc.textTertiary, fontSize: AppTextSize.body),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 20),

        // Notas
        _SectionLabel('Notas (opcional)', tc),
        const SizedBox(height: 6),
        TextField(
          controller: notaCtrl,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Descripción adicional…',
            hintStyle: TextStyle(color: tc.textTertiary, fontSize: AppTextSize.body),
            filled: true,
            fillColor: tc.bgSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.tile),
              borderSide: BorderSide(color: tc.borderCard),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.tile),
              borderSide: BorderSide(color: tc.borderCard),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.tile),
              borderSide: BorderSide(color: tc.textSecondary),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Botón Guardar
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: guardando || !montoValido ? null : onGuardar,
            style: FilledButton.styleFrom(backgroundColor: color),
            child: guardando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check, size: AppIconSize.small),
                      const SizedBox(width: 8),
                      const Text(
                        'Guardar',
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontWeight: FontWeight.w700,
                          fontSize: AppTextSize.body,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  final AppThemeColors tc;

  const _SectionLabel(this.text, this.tc);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: AppTextSize.caption,
          fontWeight: FontWeight.w600,
          color: tc.textSecondary,
          letterSpacing: 0.8,
        ),
      );
}

// ─── Ordenante autocomplete ───────────────────────────────────────────────────
// Stateless: el Autocomplete mantiene su propio controller; el valor inicial
// se siembra con initialValue y los cambios se propagan a ordenanteCtrl.
class _OrdenanteField extends StatelessWidget {
  final TextEditingController ordenanteCtrl;
  final List<FinancePlace> placesSorted;
  final AppThemeColors tc;

  const _OrdenanteField({
    required this.ordenanteCtrl,
    required this.placesSorted,
    required this.tc,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<FinancePlace>(
      initialValue: TextEditingValue(text: ordenanteCtrl.text),
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return placesSorted;
        return placesSorted.where((p) => p.nombre
            .toLowerCase()
            .contains(textEditingValue.text.toLowerCase()));
      },
      displayStringForOption: (p) => p.nombre,
      fieldViewBuilder: (ctx, ctrl, focusNode, onSubmit) {
        return TextField(
          controller: ctrl,
          focusNode: focusNode,
          onEditingComplete: onSubmit,
          onChanged: (val) => ordenanteCtrl.text = val,
          decoration: InputDecoration(
            hintText: 'Tienda, persona, lugar…',
            hintStyle: TextStyle(color: tc.textTertiary, fontSize: AppTextSize.body),
            prefixIcon: Icon(Icons.place_outlined, size: AppIconSize.small, color: tc.textTertiary),
            filled: true,
            fillColor: tc.bgSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.tile),
              borderSide: BorderSide(color: tc.borderCard),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.tile),
              borderSide: BorderSide(color: tc.borderCard),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.tile),
              borderSide: BorderSide(color: tc.textSecondary),
            ),
          ),
        );
      },
      onSelected: (p) => ordenanteCtrl.text = p.nombre,
      optionsViewBuilder: (ctx, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          color: tc.bgCard,
          borderRadius: BorderRadius.circular(AppRadius.tile),
          elevation: 4,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200, maxWidth: 320),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (_, i) {
                final p = options.elementAt(i);
                return ListTile(
                  dense: true,
                  leading: Icon(Icons.place_outlined, size: AppIconSize.small, color: tc.textSecondary),
                  title: Text(p.nombre, style: TextStyle(color: tc.textPrimary, fontSize: AppTextSize.body)),
                  subtitle: Text('${p.usados}x', style: TextStyle(color: tc.textTertiary, fontSize: AppTextSize.caption)),
                  onTap: () => onSelected(p),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DateTimeRow extends StatelessWidget {
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onTap;
  final AppThemeColors tc;

  const _DateTimeRow({
    required this.label,
    required this.onPrev,
    required this.onNext,
    required this.onTap,
    required this.tc,
  });

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrev,
            color: tc.textSecondary,
          ),
          TextButton(
            onPressed: onTap,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: AppTextSize.body,
                fontWeight: FontWeight.w600,
                color: tc.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
            color: tc.textSecondary,
          ),
        ],
      );
}

// ─── Formatter: sobreescribir "0" al escribir el primer dígito ────────────────
class _MontoFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;
    final oldText = oldValue.text;

    // Si el campo tenía exactamente "0" y se agregó un dígito al final, quitar el 0
    if (oldText == '0' && newText.length == 2 && newText.startsWith('0')) {
      final digit = newText[1];
      return TextEditingValue(
        text: digit,
        selection: TextSelection.collapsed(offset: 1),
      );
    }

    // Evitar múltiples ceros al inicio (ej: "00")
    if (newText.length > 1 && newText.startsWith('0') && newText[1] != '.') {
      final trimmed = newText.replaceFirst(RegExp(r'^0+'), '');
      final text = trimmed.isEmpty ? '0' : trimmed;
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }

    return newValue;
  }
}
