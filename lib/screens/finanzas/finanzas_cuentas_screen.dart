import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krezium/data/db/database.dart';
import 'package:krezium/data/models/finance_models.dart';
import 'package:krezium/providers/database_provider.dart';
import 'package:krezium/providers/finance_provider.dart';
import 'package:krezium/providers/theme_provider.dart';
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

String _fmt(double v) =>
    v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

// ─── Patrones de card (estilo voucher) ────────────────────────────────────────
enum _CardPattern {
  topographic,
  circuit,
  wave,
  dots,
  diagonal,
  hexagonal,
  diamond,
  organic,
}

_CardPattern _patternForId(String id) =>
    _CardPattern.values[id.hashCode.abs() % _CardPattern.values.length];

class _PatternPainter extends CustomPainter {
  final _CardPattern pattern;
  final Color color;

  _PatternPainter(this.pattern, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    switch (pattern) {
      case _CardPattern.topographic:
        _drawTopographic(canvas, size, paint);
      case _CardPattern.circuit:
        _drawCircuit(canvas, size, paint);
      case _CardPattern.wave:
        _drawWave(canvas, size, paint);
      case _CardPattern.dots:
        _drawDots(canvas, size, paint..style = PaintingStyle.fill);
      case _CardPattern.diagonal:
        _drawDiagonal(canvas, size, paint);
      case _CardPattern.hexagonal:
        _drawHexagonal(canvas, size, paint);
      case _CardPattern.diamond:
        _drawDiamond(canvas, size, paint);
      case _CardPattern.organic:
        _drawOrganic(canvas, size, paint);
    }
  }

  void _drawTopographic(Canvas canvas, Size size, Paint paint) {
    for (int i = 0; i < 5; i++) {
      final y = size.height * (0.2 + i * 0.18);
      final path = Path();
      path.moveTo(0, y);
      for (double x = 0; x <= size.width; x += 4) {
        final dy = math.sin((x / size.width) * math.pi * 3 + i) * 10;
        path.lineTo(x, y + dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawCircuit(Canvas canvas, Size size, Paint paint) {
    final points = <Offset>[
      Offset(size.width * 0.1, size.height * 0.2),
      Offset(size.width * 0.4, size.height * 0.2),
      Offset(size.width * 0.4, size.height * 0.5),
      Offset(size.width * 0.7, size.height * 0.5),
      Offset(size.width * 0.7, size.height * 0.8),
      Offset(size.width * 0.9, size.height * 0.8),
      Offset(size.width * 0.2, size.height * 0.7),
      Offset(size.width * 0.2, size.height * 0.4),
      Offset(size.width * 0.6, size.height * 0.4),
    ];
    for (int i = 0; i < points.length - 1; i += 2) {
      canvas.drawLine(points[i], points[i + 1], paint);
      canvas.drawCircle(points[i], 3, paint..style = PaintingStyle.fill);
    }
    paint.style = PaintingStyle.stroke;
  }

  void _drawWave(Canvas canvas, Size size, Paint paint) {
    for (int i = 0; i < 7; i++) {
      final path = Path();
      final y = size.height * (i / 7);
      path.moveTo(0, y);
      for (double x = 0; x <= size.width; x += 2) {
        path.lineTo(x, y + math.sin(x / 20 + i) * 6);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawDots(Canvas canvas, Size size, Paint paint) {
    const spacing = 14.0;
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  void _drawDiagonal(Canvas canvas, Size size, Paint paint) {
    const step = 14.0;
    for (double offset = -size.height; offset < size.width + size.height; offset += step) {
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset + size.height, size.height),
        paint,
      );
    }
  }

  void _drawHexagonal(Canvas canvas, Size size, Paint paint) {
    const r = 14.0;
    const w = r * 1.732;
    const h = r * 2;
    int row = 0;
    for (double y = 0; y < size.height + h; y += h * 0.75) {
      final xOffset = (row % 2 == 0) ? 0.0 : w / 2;
      for (double x = xOffset; x < size.width + w; x += w) {
        _drawHex(canvas, Offset(x, y), r, paint);
      }
      row++;
    }
  }

  void _drawHex(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = math.pi / 3 * i - math.pi / 6;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawDiamond(Canvas canvas, Size size, Paint paint) {
    const step = 18.0;
    for (double x = 0; x < size.width + step; x += step) {
      for (double y = 0; y < size.height + step; y += step) {
        final path = Path()
          ..moveTo(x, y - step / 2)
          ..lineTo(x + step / 2, y)
          ..lineTo(x, y + step / 2)
          ..lineTo(x - step / 2, y)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawOrganic(Canvas canvas, Size size, Paint paint) {
    final centers = [
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.7, size.height * 0.2),
      Offset(size.width * 0.5, size.height * 0.7),
      Offset(size.width * 0.85, size.height * 0.65),
    ];
    for (final c in centers) {
      for (double r = 8; r <= 32; r += 8) {
        canvas.drawCircle(c, r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_PatternPainter old) =>
      old.pattern != pattern || old.color != color;
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
    final prefs = ref.watch(themePreferencesProvider);
    final accentColor = resolveEffectiveAccent(prefs.accentColor, prefs.isDarkMode);

    return Scaffold(
      body: asyncLibros.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rows) {
          if (rows.isEmpty) {
            return _EmptyState(
              accentColor: accentColor,
              onCrear: _mostrarNuevoRegistroSheet,
            );
          }
          final libros = rows.map(FinanceAccount.fromRow).toList();
          return CustomScrollView(
            slivers: [
              _GlobalHeader(
                libros: libros,
                accentColor: accentColor,
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
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
                    childCount: libros.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: asyncLibros.hasValue && asyncLibros.value!.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _mostrarNuevoRegistroSheet,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nuevo registro'),
            )
          : null,
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

// ─── Header global con balance total ─────────────────────────────────────────
class _GlobalHeader extends ConsumerWidget {
  final List<FinanceAccount> libros;
  final Color accentColor;

  const _GlobalHeader({
    required this.libros,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double totalIngresos = 0;
    double totalGastos = 0;
    double totalInicial = 0;
    bool loading = false;

    for (final libro in libros) {
      totalInicial += libro.saldoInicial;
      final summary = ref.watch(financeAccountSummaryProvider(libro.id));
      summary.when(
        data: (s) {
          totalIngresos += s.ingresos;
          totalGastos += s.gastos;
        },
        loading: () => loading = true,
        error: (e, st) {},
      );
    }

    final balance = totalInicial + totalIngresos - totalGastos;
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final topPad = MediaQuery.of(context).padding.top;

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.card, topPad + AppSpacing.card, AppSpacing.card, AppSpacing.tile,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Título ──────────────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MIS REGISTROS',
                  style: TextStyle(
                    fontSize: AppTextSize.caption,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: colors.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${libros.length} ${libros.length == 1 ? 'registro' : 'registros'}',
                  style: TextStyle(
                    fontSize: AppTextSize.body,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.section),
            // ── Card de balance ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.card),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: colors.borderCard),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BALANCE TOTAL',
                    style: TextStyle(
                      fontSize: AppTextSize.caption,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  loading
                      ? SizedBox(
                          height: AppTextSize.hero,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                color: accentColor, strokeWidth: 2,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          '\$${_fmt(balance)}',
                          style: TextStyle(
                            fontSize: AppTextSize.hero,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.2,
                            height: 1.0,
                            color: colors.textPrimary,
                          ),
                        ),
                  if (!loading) ...[
                    const SizedBox(height: AppSpacing.card),
                    // Separador
                    Divider(color: colors.borderCard, height: 1),
                    const SizedBox(height: AppSpacing.card),
                    // Fila ingresos / gastos
                    Row(
                      children: [
                        _BalanceStat(
                          label: 'Ingresos',
                          value: '\$${_fmt(totalIngresos)}',
                          icon: Icons.arrow_downward_rounded,
                          iconColor: const Color(0xFF22C55E),
                          colors: colors,
                        ),
                        const SizedBox(width: AppSpacing.section),
                        _BalanceStat(
                          label: 'Gastos',
                          value: '\$${_fmt(totalGastos)}',
                          icon: Icons.arrow_upward_rounded,
                          iconColor: const Color(0xFFEF4444),
                          colors: colors,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final AppThemeColors colors;

  const _BalanceStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
          child: Icon(icon, color: iconColor, size: AppIconSize.micro),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: AppTextSize.caption,
                color: colors.textTertiary,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: AppTextSize.body,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final Color accentColor;
  final VoidCallback onCrear;

  const _EmptyState({required this.accentColor, required this.onCrear});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 40,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Empieza a registrar',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Crea tu primer registro para llevar el control de tus ingresos y gastos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTextSize.body,
                  color: colors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: onCrear,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Crear registro'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Libro card con patrón único ──────────────────────────────────────────────
class _LibroCard extends ConsumerWidget {
  final FinanceAccount libro;
  final VoidCallback onTap;
  final VoidCallback onFavorito;

  const _LibroCard({
    required this.libro,
    required this.onTap,
    required this.onFavorito,
  });

  // Determina si el color de fondo es claro para elegir el ink correcto
  static bool _isLight(Color c) =>
      ThemeData.estimateBrightnessForColor(c) == Brightness.light;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libroColor = _colorFromHex(libro.color);
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final pattern = _patternForId(libro.id);
    final summary = ref.watch(financeAccountSummaryProvider(libro.id));
    final light = _isLight(libroColor);
    final ink = light ? Colors.black : Colors.white;

    return Dismissible(
      key: ValueKey(libro.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: AppSpacing.card),
        decoration: BoxDecoration(
          color: libroColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            Icon(Icons.star_rounded, color: libroColor),
            const SizedBox(width: 8),
            Text(
              'Predeterminado',
              style: TextStyle(
                color: libroColor,
                fontWeight: FontWeight.w600,
                fontSize: AppTextSize.body,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        onFavorito();
        return false;
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.tile),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colors.borderCard),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // ── Zona superior coloreada ──────────────────────────────
              Stack(
                children: [
                  // Fondo de color del registro
                  Container(
                    width: double.infinity,
                    height: 96,
                    color: libroColor,
                  ),
                  // Patrón superpuesto con más opacidad para que se vea
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PatternPainter(pattern, ink),
                    ),
                  ),
                  // Contenido de la zona superior
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.card, AppSpacing.card,
                      AppSpacing.card, AppSpacing.card,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Inicial en círculo
                        Hero(
                          tag: 'libro_icon_${libro.id}',
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: ink.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              libro.nombre.isNotEmpty
                                  ? libro.nombre[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: ink,
                                fontWeight: FontWeight.w800,
                                fontSize: AppTextSize.heading,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.tile),
                        // Nombre
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                libro.nombre,
                                style: TextStyle(
                                  fontSize: AppTextSize.heading,
                                  fontWeight: FontWeight.w700,
                                  color: ink,
                                  height: 1.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (libro.esFavorito) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      color: ink.withValues(alpha: 0.7),
                                      size: AppIconSize.micro,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Principal',
                                      style: TextStyle(
                                        color: ink.withValues(alpha: 0.7),
                                        fontSize: AppTextSize.caption,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Flecha
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: ink.withValues(alpha: 0.55),
                          size: AppIconSize.small,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // ── Zona inferior neutra ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.card,
                  vertical: AppSpacing.tile,
                ),
                child: summary.when(
                  loading: () => SizedBox(
                    height: 36,
                    child: Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: libroColor,
                        ),
                      ),
                    ),
                  ),
                  error: (e, st) => const SizedBox(height: 36),
                  data: (s) {
                    final balance = libro.saldoInicial + s.ingresos - s.gastos;
                    final positivo = balance >= 0;
                    final balanceColor = positivo
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444);

                    return Row(
                      children: [
                        // Ingresos
                        _StatColumn(
                          label: 'Ingresos',
                          value: '\$${_fmt(s.ingresos)}',
                          valueColor: const Color(0xFF22C55E),
                          colors: colors,
                        ),
                        // Separador vertical
                        Container(
                          width: 1,
                          height: 32,
                          color: colors.borderCard,
                          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.card),
                        ),
                        // Gastos
                        _StatColumn(
                          label: 'Gastos',
                          value: '\$${_fmt(s.gastos)}',
                          valueColor: const Color(0xFFEF4444),
                          colors: colors,
                        ),
                        const Spacer(),
                        // Balance neto destacado
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Balance',
                              style: TextStyle(
                                fontSize: AppTextSize.caption,
                                color: colors.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${positivo ? '+' : ''}\$${_fmt(balance)}',
                              style: TextStyle(
                                fontSize: AppTextSize.heading,
                                fontWeight: FontWeight.w800,
                                color: balanceColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final AppThemeColors colors;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppTextSize.caption,
            color: colors.textTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: AppTextSize.body,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
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
