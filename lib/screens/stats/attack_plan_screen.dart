import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../data/models/credit.dart';
import '../../domain/debt_attack_simulator.dart';
import '../../providers/credits_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/credit_display_utils.dart';

class AttackPlanScreen extends ConsumerStatefulWidget {
  const AttackPlanScreen({super.key});

  @override
  ConsumerState<AttackPlanScreen> createState() => _AttackPlanScreenState();
}

class _AttackPlanScreenState extends ConsumerState<AttackPlanScreen> {
  AttackStrategy _strategy = AttackStrategy.avalanche;
  double _extra = 0;
  final _extraCtrl = TextEditingController(text: '0');
  AttackPlanResult? _result;
  final _repaintKey = GlobalKey();

  @override
  void dispose() {
    _extraCtrl.dispose();
    super.dispose();
  }

  void _recalculate(List<Credit> credits) {
    paidOffTracker.clear();
    final r = simulateAttackPlan(credits, _strategy,
        extraMonthlyPayment: _extra);
    setState(() => _result = r);
  }

  Future<void> _share() async {
    final boundary =
        _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 2.5);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final bytes = byteData.buffer.asUint8List();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/plan_de_ataque.png');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)],
        text: 'Mi plan de ataque con Kredit');
  }

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    final credits = ref.watch(creditsProvider).value ?? [];

    if (_result == null && credits.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _recalculate(credits));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan de ataque'),
        actions: [
          if (_result != null)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Compartir',
              onPressed: _share,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(KreditSpacing.card),
        children: [
          // Strategy selector
          _SectionLabel(text: 'ESTRATEGIA'),
          const SizedBox(height: 8),
          SegmentedButton<AttackStrategy>(
            segments: const [
              ButtonSegment(
                value: AttackStrategy.avalanche,
                label: Text('Avalanche'),
                icon: Icon(Icons.trending_down_rounded),
              ),
              ButtonSegment(
                value: AttackStrategy.snowball,
                label: Text('Snowball'),
                icon: Icon(Icons.ac_unit_rounded),
              ),
            ],
            selected: {_strategy},
            onSelectionChanged: (s) {
              setState(() => _strategy = s.first);
              _recalculate(credits);
            },
          ),
          const SizedBox(height: 6),
          Text(
            _strategy == AttackStrategy.avalanche
                ? 'Paga primero el crédito con mayor tasa de interés. Minimiza el total de intereses pagados.'
                : 'Paga primero el crédito con menor saldo. Genera motivación al cerrar créditos rápido.',
            style: TextStyle(
                fontSize: KreditTextSize.body, color: kredit.textSecondary),
          ),

          const SizedBox(height: 20),
          _SectionLabel(text: 'PAGO EXTRA MENSUAL'),
          const SizedBox(height: 8),
          TextField(
            controller: _extraCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            decoration: InputDecoration(
              prefixText: '\$ ',
              hintText: '0',
              helperText: 'Dinero adicional que puedes destinar cada mes',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(KreditRadius.tile),
              ),
            ),
            onChanged: (v) {
              final parsed = double.tryParse(v.replaceAll('.', '').replaceAll(',', '')) ?? 0;
              if (parsed != _extra) {
                _extra = parsed;
                _recalculate(credits);
              }
            },
          ),

          const SizedBox(height: 24),

          if (_result == null || _result!.months.isEmpty)
            _EmptyPlan(kredit: kredit)
          else ...[
            RepaintBoundary(
              key: _repaintKey,
              child: _SummaryCard(result: _result!, kredit: kredit, accent: accent),
            ),
            const SizedBox(height: 16),
            _SectionLabel(text: 'CRONOGRAMA MES A MES'),
            const SizedBox(height: 8),
            _MonthlyTable(months: _result!.months, kredit: kredit, accent: accent),
          ],
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final AttackPlanResult result;
  final KreditColors kredit;
  final Color accent;

  const _SummaryCard({required this.result, required this.kredit, required this.accent});

  @override
  Widget build(BuildContext context) {
    final monthsFmt = DateFormat('MMMM yyyy', 'es_CO');
    final months = result.months.length;
    final savings = result.savingsVsMinimums;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kredit.bgCard,
        borderRadius: BorderRadius.circular(KreditRadius.card),
        border: Border.all(color: kredit.borderCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: kredit.success.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.shield_outlined,
                    size: KreditIconSize.small, color: kredit.success),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LIBRE EN',
                      style: TextStyle(
                        fontSize: KreditTextSize.body,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: kredit.textTertiary,
                      ),
                    ),
                    Text(
                      monthsFmt.format(result.freedomDate).toUpperCase(),
                      style: TextStyle(
                        fontSize: KreditTextSize.heading,
                        fontWeight: FontWeight.w800,
                        color: kredit.success,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MetricTile(
                label: 'Meses',
                value: '$months',
                color: accent,
                kredit: kredit,
              ),
              const SizedBox(width: 8),
              _MetricTile(
                label: 'Intereses totales',
                value: formatCOP(result.totalInterest),
                color: kredit.danger,
                kredit: kredit,
              ),
              if (savings > 0) ...[
                const SizedBox(width: 8),
                _MetricTile(
                  label: 'Ahorro vs mínimos',
                  value: formatCOP(savings),
                  color: kredit.success,
                  kredit: kredit,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final KreditColors kredit;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
    required this.kredit,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(KreditRadius.tile),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: KreditTextSize.body,
                fontWeight: FontWeight.w800,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                  fontSize: KreditTextSize.caption, color: kredit.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyTable extends StatelessWidget {
  final List<MonthlySnapshot> months;
  final KreditColors kredit;
  final Color accent;

  const _MonthlyTable({
    required this.months,
    required this.kredit,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final monthFmt = DateFormat('MMM yyyy', 'es_CO');
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: kredit.bgCard,
            borderRadius: BorderRadius.circular(KreditRadius.tile),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Mes',
                    style: TextStyle(
                        fontSize: KreditTextSize.caption,
                        fontWeight: FontWeight.w700,
                        color: kredit.textTertiary,
                        letterSpacing: 0.8)),
              ),
              Expanded(
                flex: 3,
                child: Text('Crédito atacado',
                    style: TextStyle(
                        fontSize: KreditTextSize.caption,
                        fontWeight: FontWeight.w700,
                        color: kredit.textTertiary,
                        letterSpacing: 0.8)),
              ),
              Expanded(
                flex: 2,
                child: Text('Deuda restante',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: KreditTextSize.caption,
                        fontWeight: FontWeight.w700,
                        color: kredit.textTertiary,
                        letterSpacing: 0.8)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        for (var i = 0; i < months.length; i++) ...[
          _MonthRow(
            snap: months[i],
            monthFmt: monthFmt,
            kredit: kredit,
            accent: accent,
            isLast: i == months.length - 1,
          ),
          if (i < months.length - 1)
            Divider(height: 1, color: kredit.borderCard.withValues(alpha: 0.5)),
        ],
      ],
    );
  }
}

class _MonthRow extends StatelessWidget {
  final MonthlySnapshot snap;
  final DateFormat monthFmt;
  final KreditColors kredit;
  final Color accent;
  final bool isLast;

  const _MonthRow({
    required this.snap,
    required this.monthFmt,
    required this.kredit,
    required this.accent,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final debtColor = isLast ? kredit.success : kredit.textPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              monthFmt.format(snap.month),
              style: TextStyle(
                  fontSize: KreditTextSize.body,
                  color: kredit.textSecondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: snap.attackedCreditName != null
                ? Row(
                    children: [
                      Icon(Icons.bolt_rounded,
                          size: 12, color: accent),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          snap.attackedCreditName!,
                          style: TextStyle(
                              fontSize: KreditTextSize.body,
                              color: kredit.textPrimary,
                              fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : Text('—',
                    style: TextStyle(
                        fontSize: KreditTextSize.body,
                        color: kredit.textTertiary)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatCOP(snap.totalDebt),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: KreditTextSize.body,
                fontWeight: FontWeight.w700,
                color: debtColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Text(
      text,
      style: TextStyle(
        fontSize: KreditTextSize.body,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: kredit.textTertiary,
      ),
    );
  }
}

class _EmptyPlan extends StatelessWidget {
  final KreditColors kredit;
  const _EmptyPlan({required this.kredit});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline,
                size: KreditIconSize.large, color: kredit.success),
            const SizedBox(height: 12),
            Text(
              'Sin deudas activas',
              style: TextStyle(
                  fontSize: KreditTextSize.heading,
                  fontWeight: FontWeight.bold,
                  color: kredit.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              '¡Estás libre de deudas! Agrega créditos para ver tu plan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: KreditTextSize.body, color: kredit.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
