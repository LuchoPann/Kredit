import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/card_movement.dart';
import '../../data/models/credit.dart';
import '../../domain/date_utils.dart';
import '../../domain/interest_rate.dart';
import '../../domain/loan_calculator.dart';
import '../../providers/credits_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_input_formatter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Formateo de moneda (reutiliza la misma lógica que stats_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────

String _fmtCOP(double v) {
  final n = v.round().abs();
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '\$${buf.toString()}';
}

// ── Freedom tab helpers ───────────────────────────────────────────────────────

String _monthsToDateStr(int months) {
  if (months <= 0) return 'Ya saldado';
  if (months >= 600) return 'Más de 50 años';
  final date = DateTime.now().add(Duration(days: months * 30));
  const names = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
  return '${names[date.month - 1]} ${date.year}';
}

String _monthsLabel(int months) {
  if (months <= 0) return 'saldado';
  if (months == 1) return '1 mes';
  return '$months meses';
}

double _remainingBalanceOf(Credit credit) {
  if (credit is LoanCredit) return getLoanRemainingPrincipal(credit);
  if (credit is CardCredit) return credit.currentBalance;
  return 0;
}

double _remainingInterestOf(Credit credit) {
  if (credit is LoanCredit) {
    return credit.installments
        .where((i) => !i.paid)
        .fold(0.0, (s, i) => s + i.interest);
  }
  if (credit is CardCredit) {
    final dailyRate =
        credit.interestRate > 0 ? credit.interestRate / 100 / 365 : 0.0;
    final monthlyRate = dailyRate * 30;
    var balance = credit.currentBalance;
    var totalInterest = 0.0;
    var months = 0;
    while (balance > 0 && months < 600) {
      final interest = balance * monthlyRate;
      totalInterest += interest;
      final minPay = math.max(balance * 0.02, 50000.0);
      if (minPay >= balance + interest) break;
      balance = balance + interest - minPay;
      months++;
    }
    return totalInterest;
  }
  return 0;
}

double _monthlyBaseOf(Credit credit) {
  if (credit is LoanCredit) return credit.quotaAmount;
  if (credit is CardCredit) return math.max(credit.currentBalance * 0.02, 50000.0);
  return 0;
}

double _interestRateOf(Credit c) {
  if (c is LoanCredit) return c.interestRate;
  if (c is CardCredit) return c.interestRate;
  return 0;
}

int _monthsWithPayment(Credit credit, double monthlyPayment) {
  if (monthlyPayment <= 0) return 600;
  if (credit is LoanCredit) {
    final unpaid = credit.installments.where((i) => !i.paid).toList();
    if (unpaid.isEmpty) return 0;
    final balance = unpaid.fold(0.0, (s, i) => s + i.principal);
    if (balance <= 0) return 0;
    final periodRate = periodicRateFrom(
        credit.interestRate, credit.interestRateType, credit.frequency);
    if (periodRate <= 0) return (balance / monthlyPayment).ceil().clamp(1, 600);
    if (monthlyPayment <= balance * periodRate) return 600;
    final n =
        math.log(monthlyPayment / (monthlyPayment - balance * periodRate)) /
            math.log(1 + periodRate);
    if (n.isNaN || n.isInfinite || n < 0) return 600;
    return n.ceil().clamp(1, 600);
  }
  if (credit is CardCredit) {
    var balance = credit.currentBalance;
    if (balance <= 0) return 0;
    final dailyRate =
        credit.interestRate > 0 ? credit.interestRate / 100 / 365 : 0.0;
    final monthlyRate = dailyRate * 30;
    var months = 0;
    while (balance > 0 && months < 600) {
      final interest = balance * monthlyRate;
      final payment =
          math.max(monthlyPayment, math.max(balance * 0.02, 50000.0));
      if (payment >= balance + interest) {
        months++;
        break;
      }
      balance = balance + interest - payment;
      months++;
    }
    return months;
  }
  return 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// Entry point: abre el sheet
// ─────────────────────────────────────────────────────────────────────────────

void openSimulatorSheet(BuildContext context, {String? initialCreditId}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SimulatorSheet(initialCreditId: initialCreditId),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet principal
// ─────────────────────────────────────────────────────────────────────────────

class SimulatorSheet extends ConsumerStatefulWidget {
  final String? initialCreditId;
  const SimulatorSheet({super.key, this.initialCreditId});

  @override
  ConsumerState<SimulatorSheet> createState() => _SimulatorSheetState();
}

class _SimulatorSheetState extends ConsumerState<SimulatorSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    // Sin crédito específico → abrir en Libertad (tab 2) para mostrar visión global.
    // Con crédito específico → Abonar extra (1) para préstamos, Simular compra (0) para tarjetas.
    final initialIndex = widget.initialCreditId != null
        ? () {
            final credits =
                ref.read(creditsProvider).valueOrNull ?? const <Credit>[];
            final match =
                credits.where((c) => c.id == widget.initialCreditId).toList();
            if (match.isNotEmpty && match.first is LoanCredit) return 1;
            return 0;
          }()
        : 2;
    _tabCtrl = TabController(length: 3, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final creditsAsync = ref.watch(creditsProvider);
    final credits = creditsAsync.valueOrNull ?? [];

    final accent = Theme.of(context).colorScheme.primary;
    final activeCredits = credits.where((c) {
      if (c is LoanCredit) return c.installments.any((i) => !i.paid);
      if (c is CardCredit) return c.currentBalance > 0;
      return false;
    }).toList();
    final baseline =
        activeCredits.isNotEmpty ? _computeFreedom(activeCredits, 0, true) : null;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, sc) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: kredit.borderCard,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.calculate_outlined,
                    size: KreditIconSize.small, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Simulador financiero',
                    style: TextStyle(
                      fontSize: KreditTextSize.heading,
                      fontWeight: FontWeight.w700,
                      color: kredit.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Stat strip: snapshot rápido de toda la deuda activa
          if (baseline != null && baseline.rows.isNotEmpty) ...[
            const SizedBox(height: 10),
            _DebtSnapshotStrip(baseline: baseline, kredit: kredit, accent: accent),
          ] else ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 52, right: 20),
              child: Text(
                '¿Qué pasaría si…? Resultados aproximados.',
                style: TextStyle(
                    fontSize: KreditTextSize.body, color: kredit.textTertiary),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Tabs
          TabBar(
            controller: _tabCtrl,
            tabs: const [
              Tab(icon: Icon(Icons.shopping_cart_outlined, size: KreditIconSize.small), text: 'Simular compra'),
              Tab(icon: Icon(Icons.payments_outlined, size: KreditIconSize.small), text: 'Abonar extra'),
              Tab(icon: Icon(Icons.rocket_launch_outlined, size: KreditIconSize.small), text: 'Libertad'),
            ],
          ),
          // Content — cada tab maneja su propio ScrollController para evitar
          // el error de AccessibilityBridge al compartir un mismo controller
          // entre múltiples ListView montados simultáneamente en TabBarView.
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _PurchaseTab(credits: credits),
                _ExtraPaymentTab(
                  credits: credits,
                  initialCreditId: widget.initialCreditId,
                ),
                _FreedomTab(credits: credits),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header: snapshot rápido de la deuda activa
// ─────────────────────────────────────────────────────────────────────────────

class _DebtSnapshotStrip extends StatelessWidget {
  final _FreedomResult baseline;
  final KreditColors kredit;
  final Color accent;
  const _DebtSnapshotStrip(
      {required this.baseline, required this.kredit, required this.accent});

  @override
  Widget build(BuildContext context) {
    final totalDebt = baseline.rows
        .fold(0.0, (s, r) => s + _remainingBalanceOf(r.credit));
    final monthlyInterest = baseline.rows.fold(0.0, (s, r) {
      if (r.credit is LoanCredit) {
        final unpaid =
            (r.credit as LoanCredit).installments.where((i) => !i.paid).toList();
        if (unpaid.isEmpty) return s;
        return s + unpaid.first.interest;
      }
      if (r.credit is CardCredit) {
        final c = r.credit as CardCredit;
        final dailyRate = c.interestRate > 0 ? c.interestRate / 100 / 365 : 0.0;
        return s + c.currentBalance * dailyRate * 30;
      }
      return s;
    });
    final freeDate = _monthsToDateStr(baseline.baseMonthsTotal);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _SnapStat(
            label: 'Deuda total',
            value: _fmtCOP(totalDebt),
            kredit: kredit,
          ),
          _SnapDivider(kredit: kredit),
          _SnapStat(
            label: 'Interés/mes',
            value: _fmtCOP(monthlyInterest),
            valueColor: Colors.redAccent,
            kredit: kredit,
          ),
          _SnapDivider(kredit: kredit),
          _SnapStat(
            label: 'Libre en',
            value: freeDate,
            valueColor: accent,
            kredit: kredit,
          ),
        ],
      ),
    );
  }
}

class _SnapStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final KreditColors kredit;
  const _SnapStat(
      {required this.label,
      required this.value,
      this.valueColor,
      required this.kredit});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: KreditTextSize.caption, color: kredit.textTertiary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: KreditTextSize.body,
              fontWeight: FontWeight.w700,
              color: valueColor ?? kredit.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SnapDivider extends StatelessWidget {
  final KreditColors kredit;
  const _SnapDivider({required this.kredit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: kredit.borderCard,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB A — Simulador de Compra
// ─────────────────────────────────────────────────────────────────────────────

class _PurchaseTab extends StatefulWidget {
  final List<Credit> credits;
  const _PurchaseTab({required this.credits});

  @override
  State<_PurchaseTab> createState() => _PurchaseTabState();
}

class _PurchaseTabState extends State<_PurchaseTab> {
  final _amountCtrl = TextEditingController();
  final _quotasCtrl = TextEditingController(text: '1');
  CardCredit? _selectedCard;
  _PurchaseResult? _result;

  List<CardCredit> get _cards =>
      widget.credits.whereType<CardCredit>().toList();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _quotasCtrl.dispose();
    super.dispose();
  }

  void _simulate() {
    final amount = double.tryParse(CurrencyInputFormatter.unformat(_amountCtrl.text));
    final quotas = int.tryParse(_quotasCtrl.text);
    final card = _selectedCard;
    if (amount == null || amount <= 0 || quotas == null || quotas <= 0 || card == null) return;

    final newBalance = card.currentBalance + amount;
    final available = math.max(0.0, card.creditLimit - newBalance);
    final utilizationPct = card.creditLimit > 0 ? (newBalance / card.creditLimit) * 100 : 0.0;

    // Cuota mensual = monto / cuotas (sin interés extra por cuotas — típico Colombia)
    final monthlyInstallment = amount / quotas;

    // Costo total estimado si solo paga mínimo (interés diario E.A./365 sobre saldo)
    final dailyRate = card.interestRate > 0 ? (card.interestRate / 100 / 365) : 0.0;
    final monthlyRate = dailyRate * 30;
    double totalInterestCost = 0;
    if (monthlyRate > 0) {
      // Amortización francesa simple para el saldo nuevo
      final r = monthlyRate;
      final n = quotas;
      final pmt = (amount * r * math.pow(1 + r, n)) / (math.pow(1 + r, n) - 1);
      totalInterestCost = (pmt * n) - amount;
    }

    setState(() {
      _result = _PurchaseResult(
        purchaseAmount: amount,
        quotas: quotas,
        monthlyInstallment: monthlyInstallment,
        newTotalBalance: newBalance,
        availableCredit: available,
        utilizationPct: utilizationPct,
        estimatedInterestCost: totalInterestCost,
        cardName: card.name,
        cardLimit: card.creditLimit,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Tarjeta selector
        if (_cards.isEmpty)
          _InfoBanner(
            kredit: kredit,
            icon: Icons.credit_card_off_outlined,
            text: 'No tienes tarjetas de crédito registradas. Agrega una primero.',
          )
        else ...[
          Text('¿Con qué tarjeta harías la compra?',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: KreditTextSize.body,
                  color: kredit.textPrimary)),
          const SizedBox(height: 8),
          DropdownButtonFormField<CardCredit>(
            initialValue: _selectedCard,
            decoration: const InputDecoration(labelText: 'Seleccionar tarjeta'),
            items: _cards
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(
                        '${c.name} — ${_fmtCOP(math.max(0, c.creditLimit - c.currentBalance))} disponible',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() {
              _selectedCard = v;
              _result = null;
            }),
          ),
          const SizedBox(height: 16),
          Text('¿Cuánto vale la compra?',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: KreditTextSize.body,
                  color: kredit.textPrimary)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [CurrencyInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Valor de la compra (\$)',
                    prefixText: '\$ ',
                  ),
                  onChanged: (_) => setState(() => _result = null),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _quotasCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cuotas'),
                  onChanged: (_) => setState(() => _result = null),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _simulate,
            icon: const Icon(Icons.play_arrow_outlined),
            label: const Text('Simular compra'),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            _PurchaseResultCard(result: _result!, kredit: kredit, accent: accent),
          ],
          const SizedBox(height: 16),
          _DisclaimerBanner(kredit: kredit),
        ],
      ],
    );
  }
}

class _PurchaseResult {
  final double purchaseAmount;
  final int quotas;
  final double monthlyInstallment;
  final double newTotalBalance;
  final double availableCredit;
  final double utilizationPct;
  final double estimatedInterestCost;
  final String cardName;
  final double cardLimit;

  const _PurchaseResult({
    required this.purchaseAmount,
    required this.quotas,
    required this.monthlyInstallment,
    required this.newTotalBalance,
    required this.availableCredit,
    required this.utilizationPct,
    required this.estimatedInterestCost,
    required this.cardName,
    required this.cardLimit,
  });
}

class _PurchaseResultCard extends StatelessWidget {
  final _PurchaseResult result;
  final KreditColors kredit;
  final Color accent;
  const _PurchaseResultCard(
      {required this.result, required this.kredit, required this.accent});

  @override
  Widget build(BuildContext context) {
    final highUtilization = result.utilizationPct > 80;
    final accentColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Cuota hero ────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(KreditRadius.card),
            border: Border.all(color: accentColor.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Text(
                'CUOTA MENSUAL ESTIMADA',
                style: TextStyle(
                  fontSize: KreditTextSize.caption,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _fmtCOP(result.monthlyInstallment),
                style: TextStyle(
                  fontSize: KreditTextSize.emphasis,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: accentColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                'por ${result.quotas} cuota${result.quotas == 1 ? '' : 's'}',
                style: TextStyle(
                    fontSize: KreditTextSize.body, color: kredit.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Grid de stats ─────────────────────────────────────────────────
        _SimSectionCard(
          title: 'Impacto en tu tarjeta',
          rows: [
            _StatRow(
              left: _StatTileData(
                label: 'Nuevo saldo',
                value: _fmtCOP(result.newTotalBalance),
                icon: Icons.account_balance_wallet_outlined,
              ),
              right: _StatTileData(
                label: 'Cupo disponible',
                value: _fmtCOP(result.availableCredit),
                icon: Icons.credit_card_outlined,
                valueColor: result.availableCredit < result.cardLimit * 0.2
                    ? Colors.redAccent
                    : kredit.textPrimary,
              ),
            ),
            if (result.estimatedInterestCost > 0)
              _StatRow(
                left: _StatTileData(
                  label: 'Costo en intereses',
                  value: _fmtCOP(result.estimatedInterestCost),
                  icon: Icons.trending_up_outlined,
                  valueColor: Colors.redAccent,
                ),
                right: _StatTileData(
                  label: 'Utilización del cupo',
                  value: '${result.utilizationPct.toStringAsFixed(1)}%',
                  icon: Icons.donut_small_outlined,
                  valueColor: highUtilization ? Colors.redAccent : kredit.success,
                ),
              )
            else
              _StatTile(
                data: _StatTileData(
                  label: 'Utilización del cupo',
                  value: '${result.utilizationPct.toStringAsFixed(1)}%',
                  icon: Icons.donut_small_outlined,
                  valueColor: highUtilization ? Colors.redAccent : kredit.success,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Barra de utilización ──────────────────────────────────────────
        _UtilizationBar(
          pct: result.utilizationPct,
          kredit: kredit,
          highUtilization: highUtilization,
        ),
        if (highUtilization) ...[
          const SizedBox(height: 12),
          _WarningBanner(
            text:
                'Alta utilización (${result.utilizationPct.round()}%). Se recomienda mantenerla por debajo del 80%.',
          ),
        ],
      ],
    );
  }
}

class _UtilizationBar extends StatelessWidget {
  final double pct;
  final KreditColors kredit;
  final bool highUtilization;

  const _UtilizationBar(
      {required this.pct,
      required this.kredit,
      required this.highUtilization});

  @override
  Widget build(BuildContext context) {
    final barColor = highUtilization ? Colors.redAccent : Colors.green;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Utilización del cupo',
                style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textSecondary)),
            Text('${pct.toStringAsFixed(1)}%',
                style: TextStyle(
                    fontSize: KreditTextSize.body,
                    fontWeight: FontWeight.w700,
                    color: barColor)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (pct.clamp(0, 100)) / 100,
            backgroundColor: kredit.borderCard,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB B — Simulador de Abono Extra
// ─────────────────────────────────────────────────────────────────────────────

class _ExtraPaymentTab extends StatefulWidget {
  final List<Credit> credits;
  final String? initialCreditId;
  const _ExtraPaymentTab({required this.credits, this.initialCreditId});

  @override
  State<_ExtraPaymentTab> createState() => _ExtraPaymentTabState();
}

class _ExtraPaymentTabState extends State<_ExtraPaymentTab> {
  final _paymentCtrl = TextEditingController();
  Credit? _selectedCredit;
  _PaymentResult? _result;

  // Tarea 2 del roadmap ("comparativas" + "guardar escenarios"): guarda los
  // últimos escenarios simulados por crédito en SharedPreferences (clave
  // `sim_scenarios_<creditId>`), así sobreviven a cerrar el simulador o la
  // app — a diferencia de un abono real, esto es solo una previsualización,
  // así que no necesita vivir en la base de datos de créditos. Más reciente
  // primero, tope de 5 para que la tabla no crezca sin límite.
  final List<_PaymentResult> _scenarios = [];
  static const _maxScenarios = 5;

  // Fase 6 del roadmap: comparacion automatica de los 3 escenarios fijos
  // (seguir igual / reducir cuota / reducir plazo) para el monto que se
  // acaba de simular — a diferencia de `_scenarios` (que compara distintos
  // MONTOS elegidos por el usuario), esto compara distintas ESTRATEGIAS
  // para el mismo monto. Solo aplica a prestamos (una tarjeta no tiene
  // "estrategia de abono", solo reduce saldo).
  List<AbonoScenarioResult> _threeScenarios = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialCreditId != null) {
      final match = widget.credits
          .where((c) => c.id == widget.initialCreditId)
          .toList();
      if (match.isNotEmpty) _selectedCredit = match.first;
    }
    if (_selectedCredit != null) _loadScenarios(_selectedCredit!);
  }

  String _scenariosKey(Credit credit) => 'sim_scenarios_${credit.id}';

  Future<void> _loadScenarios(Credit credit) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_scenariosKey(credit));
    if (raw == null || !mounted) return;
    final decoded = jsonDecode(raw) as List<dynamic>;
    setState(() {
      _scenarios
        ..clear()
        ..addAll(
          decoded.map((e) => _PaymentResult.fromJson(e as Map<String, dynamic>, credit)),
        );
    });
  }

  Future<void> _persistScenarios(Credit credit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _scenariosKey(credit),
      jsonEncode(_scenarios.map((s) => s.toJson()).toList()),
    );
  }

  @override
  void dispose() {
    _paymentCtrl.dispose();
    super.dispose();
  }

  void _simulate() {
    final amount = double.tryParse(CurrencyInputFormatter.unformat(_paymentCtrl.text));
    final credit = _selectedCredit;
    if (amount == null || amount <= 0 || credit == null) return;

    if (credit is LoanCredit) {
      _simulateLoan(credit, amount);
    } else if (credit is CardCredit) {
      _simulateCard(credit, amount);
    }
  }

  void _simulateLoan(LoanCredit loan, double extraPayment) {
    final unpaid = loan.installments.where((i) => !i.paid).toList();
    if (unpaid.isEmpty) return;

    setState(() {
      _threeScenarios = simulateAbonoScenarios(loan, extraPayment);
    });

    final currentBalance = unpaid.fold(0.0, (s, i) => s + i.amount);
    final newBalance = math.max(0.0, currentBalance - extraPayment);
    final quota = loan.quotaAmount;

    // Cuántas cuotas se saltan
    final quotasSkipped = quota > 0 ? (extraPayment / quota).floor() : 0;
    final saving = unpaid
        .take(quotasSkipped)
        .fold(0.0, (s, i) => s + i.interest);

    _addScenario(_PaymentResult(
      credit: loan,
      creditName: loan.name,
      extraPayment: extraPayment,
      currentBalance: currentBalance,
      newBalance: newBalance,
      quotasSkipped: quotasSkipped,
      interestSaving: saving,
      isCard: false,
      monthsToPayoff: 0,
    ));
  }

  void _simulateCard(CardCredit card, double extraPayment) {
    final newBalance = math.max(0.0, card.currentBalance - extraPayment);
    final dailyRate = card.interestRate > 0 ? (card.interestRate / 100 / 365) : 0.0;
    final monthlyRate = dailyRate * 30;

    // Meses para saldar con mínimo (2% del saldo o $50k, lo que sea mayor)
    int monthsToPayoff = 0;
    if (monthlyRate > 0 && newBalance > 0) {
      var balance = newBalance;
      while (balance > 0 && monthsToPayoff < 600) {
        final interest = balance * monthlyRate;
        final minPayment = math.max(balance * 0.02, 50000.0);
        if (minPayment >= balance + interest) {
          monthsToPayoff++;
          break;
        }
        balance = balance + interest - minPayment;
        monthsToPayoff++;
      }
    }

    _addScenario(_PaymentResult(
      credit: card,
      creditName: card.name,
      extraPayment: extraPayment,
      currentBalance: card.currentBalance,
      newBalance: newBalance,
      quotasSkipped: 0,
      interestSaving: 0,
      isCard: true,
      monthsToPayoff: monthsToPayoff,
      newAvailable: math.max(0, card.creditLimit - newBalance),
    ));
  }

  void _addScenario(_PaymentResult result) {
    setState(() {
      _result = result;
      _scenarios.insert(0, result);
      if (_scenarios.length > _maxScenarios) {
        _scenarios.removeRange(_maxScenarios, _scenarios.length);
      }
    });
    _persistScenarios(result.credit);
  }

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;

    if (widget.credits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: _InfoBanner(
          kredit: kredit,
          icon: Icons.account_balance_outlined,
          text: 'No tienes créditos registrados aún.',
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('¿A qué crédito harías el abono?',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: KreditTextSize.body,
                color: kredit.textPrimary)),
        const SizedBox(height: 8),
        DropdownButtonFormField<Credit>(
          initialValue: _selectedCredit,
          decoration: const InputDecoration(labelText: 'Seleccionar crédito'),
          items: widget.credits
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(
                      c.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            setState(() {
              _selectedCredit = v;
              _result = null;
              _scenarios.clear();
              _threeScenarios = [];
            });
            if (v != null) _loadScenarios(v);
          },
        ),
        const SizedBox(height: 16),
        Text('¿Cuánto abonarías?',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: KreditTextSize.body,
                color: kredit.textPrimary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _paymentCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: const [CurrencyInputFormatter()],
          decoration: const InputDecoration(
            labelText: 'Monto del abono (\$)',
            prefixText: '\$ ',
          ),
          onChanged: (_) => setState(() {
            _result = null;
            _threeScenarios = [];
          }),
        ),
        const SizedBox(height: 10),
        _QuickAmountRow(
          kredit: kredit,
          onPick: (amount) => setState(() {
            _paymentCtrl.text = CurrencyInputFormatter.format(amount);
            _result = null;
            _threeScenarios = [];
          }),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _simulate,
          icon: const Icon(Icons.play_arrow_outlined),
          label: const Text('Simular abono'),
        ),
        if (_result != null) ...[
          const SizedBox(height: 24),
          _PaymentResultCard(result: _result!, kredit: kredit, accent: accent),
        ],
        if (_threeScenarios.isNotEmpty) ...[
          const SizedBox(height: 20),
          _ThreeScenariosCard(scenarios: _threeScenarios, kredit: kredit, accent: accent),
        ],
        if (_scenarios.length > 1) ...[
          const SizedBox(height: 20),
          _ScenarioComparisonTable(scenarios: _scenarios, kredit: kredit),
        ],
        const SizedBox(height: 16),
        _DisclaimerBanner(kredit: kredit),
      ],
    );
  }
}

class _PaymentResult {
  final Credit credit;
  final String creditName;
  final double extraPayment;
  final double currentBalance;
  final double newBalance;
  final int quotasSkipped;
  final double interestSaving;
  final bool isCard;
  final int monthsToPayoff;
  final double? newAvailable;

  const _PaymentResult({
    required this.credit,
    required this.creditName,
    required this.extraPayment,
    required this.currentBalance,
    required this.newBalance,
    required this.quotasSkipped,
    required this.interestSaving,
    required this.isCard,
    required this.monthsToPayoff,
    this.newAvailable,
  });

  // Serializa solo los campos primitivos — `credit` se re-adjunta al leer
  // (no tiene sentido serializar el crédito completo cuando ya lo tenemos
  // en memoria; solo cambia su `id`, que ya es la clave de SharedPreferences
  // bajo la que se guarda esta lista).
  Map<String, dynamic> toJson() => {
        'creditName': creditName,
        'extraPayment': extraPayment,
        'currentBalance': currentBalance,
        'newBalance': newBalance,
        'quotasSkipped': quotasSkipped,
        'interestSaving': interestSaving,
        'isCard': isCard,
        'monthsToPayoff': monthsToPayoff,
        'newAvailable': newAvailable,
      };

  factory _PaymentResult.fromJson(Map<String, dynamic> json, Credit credit) {
    return _PaymentResult(
      credit: credit,
      creditName: json['creditName'] as String,
      extraPayment: (json['extraPayment'] as num).toDouble(),
      currentBalance: (json['currentBalance'] as num).toDouble(),
      newBalance: (json['newBalance'] as num).toDouble(),
      quotasSkipped: json['quotasSkipped'] as int,
      interestSaving: (json['interestSaving'] as num).toDouble(),
      isCard: json['isCard'] as bool,
      monthsToPayoff: json['monthsToPayoff'] as int,
      newAvailable: (json['newAvailable'] as num?)?.toDouble(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Freedom tab data model
// ─────────────────────────────────────────────────────────────────────────────

class _FreedomRow {
  final Credit credit;
  final double monthlyBase;
  final double monthlyExtra;
  final int baseMonths;
  final int newMonths;
  final double baseInterest;

  const _FreedomRow({
    required this.credit,
    required this.monthlyBase,
    required this.monthlyExtra,
    required this.baseMonths,
    required this.newMonths,
    required this.baseInterest,
  });

  int get monthsSaved => (baseMonths - newMonths).clamp(0, 600);

  double get interestSaved {
    if (monthlyExtra <= 0 || baseMonths <= 0) return 0;
    return baseInterest * (monthsSaved / baseMonths);
  }
}

class _FreedomResult {
  final List<_FreedomRow> rows;
  final double totalBaseInterest;

  const _FreedomResult({required this.rows, required this.totalBaseInterest});

  int get baseMonthsTotal =>
      rows.isEmpty ? 0 : rows.map((r) => r.baseMonths).reduce(math.max);

  double get totalInterestSaved => rows.fold(0.0, (s, r) => s + r.interestSaved);
}

_FreedomResult _computeFreedom(
    List<Credit> credits, double extraMonthly, bool isAvalanche) {
  final active = credits.where((c) {
    if (c is LoanCredit) return c.installments.any((i) => !i.paid);
    if (c is CardCredit) return c.currentBalance > 0;
    return false;
  }).toList();
  if (active.isEmpty) {
    return const _FreedomResult(rows: [], totalBaseInterest: 0);
  }
  active.sort((a, b) => isAvalanche
      ? _interestRateOf(b).compareTo(_interestRateOf(a))
      : _remainingBalanceOf(a).compareTo(_remainingBalanceOf(b)));
  final rows = <_FreedomRow>[];
  double totalBaseInterest = 0;
  for (var i = 0; i < active.length; i++) {
    final credit = active[i];
    final base = _monthlyBaseOf(credit);
    final extra = i == 0 ? extraMonthly : 0.0;
    final baseMonths = _monthsWithPayment(credit, base);
    final newMonths =
        extra > 0 ? _monthsWithPayment(credit, base + extra) : baseMonths;
    final baseInterest = _remainingInterestOf(credit);
    totalBaseInterest += baseInterest;
    rows.add(_FreedomRow(
      credit: credit,
      monthlyBase: base,
      monthlyExtra: extra,
      baseMonths: baseMonths,
      newMonths: newMonths,
      baseInterest: baseInterest,
    ));
  }
  return _FreedomResult(rows: rows, totalBaseInterest: totalBaseInterest);
}

/// Fila de chips con montos típicos ($50k/$100k/$200k) para no tener que
/// escribir el número a mano cada vez — pedido explícito de la Tarea 2 del
/// roadmap ("Simulador fuerte").
class _QuickAmountRow extends StatelessWidget {
  final KreditColors kredit;
  final ValueChanged<double> onPick;
  const _QuickAmountRow({required this.kredit, required this.onPick});

  static const _amounts = [50000.0, 100000.0, 200000.0];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final amount in _amounts)
          ActionChip(
            label: Text('\$${CurrencyInputFormatter.format(amount)}'),
            onPressed: () => onPick(amount),
            backgroundColor: kredit.bgCard,
            side: BorderSide(color: kredit.borderCard.withValues(alpha: 0.78)),
          ),
      ],
    );
  }
}

/// Fase 6 del roadmap: compara automáticamente los 3 escenarios fijos para
/// el monto recién simulado — "seguir igual" (baseline), "reducir cuota" y
/// "reducir plazo" — en el mismo lenguaje humano que pide el roadmap
/// ("Terminas X meses antes", "Tu cuota baja de $X a $Y"). A diferencia de
/// `_ScenarioComparisonTable` (que compara MONTOS distintos elegidos por el
/// usuario), esta tarjeta compara ESTRATEGIAS para el mismo monto.
class _ThreeScenariosCard extends StatelessWidget {
  final List<AbonoScenarioResult> scenarios;
  final KreditColors kredit;
  final Color accent;
  const _ThreeScenariosCard({
    required this.scenarios,
    required this.kredit,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final baseline = scenarios.firstWhere((s) => s.strategy == null);
    final others = scenarios.where((s) => s.strategy != null).toList();
    if (others.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Elige tu estrategia',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: KreditTextSize.heading,
            color: kredit.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '¿Qué prefieres hacer con el abono?',
          style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textSecondary),
        ),
        const SizedBox(height: 12),
        // Seguir igual — opción neutra
        _StrategyOptionCard(
          icon: Icons.pause_circle_outline,
          title: 'Seguir igual',
          subtitle: 'Sin abonar extra',
          stats: [
            _StatTileData(label: 'Terminas en', value: formatDate(baseline.payoffDate)),
            _StatTileData(
              label: 'Interés restante',
              value: _fmtCOP(baseline.totalInterestRemaining),
              valueColor: Colors.redAccent,
            ),
          ],
          isHighlight: false,
          kredit: kredit,
          accent: kredit.textTertiary,
        ),
        const SizedBox(height: 8),
        for (final s in others) ...[
          _StrategyOptionCard(
            icon: s.strategy == AbonoStrategy.reducirCuota
                ? Icons.compress_outlined
                : Icons.fast_forward_outlined,
            title: s.strategy == AbonoStrategy.reducirCuota
                ? 'Reducir cuota'
                : 'Reducir plazo',
            subtitle: s.strategy == AbonoStrategy.reducirCuota
                ? 'Pagas menos cada mes'
                : 'Terminas antes',
            stats: s.strategy == AbonoStrategy.reducirCuota
                ? [
                    _StatTileData(
                      label: 'Nueva cuota',
                      value: _fmtCOP(s.quota),
                      valueColor: accent,
                    ),
                    _StatTileData(
                      label: s.interestSaved > 0 ? 'Ahorras en intereses' : 'Cuotas restantes',
                      value: s.interestSaved > 0
                          ? _fmtCOP(s.interestSaved)
                          : '${s.remainingInstallments}',
                      valueColor: s.interestSaved > 0 ? kredit.success : kredit.textPrimary,
                    ),
                  ]
                : [
                    _StatTileData(
                      label: 'Terminas en',
                      value: formatDate(s.payoffDate),
                      valueColor: accent,
                    ),
                    _StatTileData(
                      label: s.interestSaved > 0 ? 'Ahorras en intereses' : 'Cuotas adelantadas',
                      value: s.interestSaved > 0
                          ? _fmtCOP(s.interestSaved)
                          : '${s.installmentsSaved}',
                      valueColor: s.interestSaved > 0 ? kredit.success : kredit.textPrimary,
                    ),
                  ],
            isHighlight: true,
            kredit: kredit,
            accent: accent,
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _StrategyOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<_StatTileData> stats;
  final bool isHighlight;
  final KreditColors kredit;
  final Color accent;

  const _StrategyOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.stats,
    required this.isHighlight,
    required this.kredit,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isHighlight ? accent.withValues(alpha: 0.07) : kredit.bgCard;
    final border = isHighlight ? accent.withValues(alpha: 0.3) : kredit.borderCard;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(KreditRadius.card),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(icon,
                    size: KreditIconSize.small,
                    color: isHighlight ? accent : kredit.textTertiary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: KreditTextSize.body,
                          color: isHighlight ? accent : kredit.textSecondary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: KreditTextSize.caption,
                          color: kredit.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: kredit.borderCard),
          _StatRow(left: stats[0], right: stats[1]),
        ],
      ),
    );
  }
}

/// Tabla compacta de comparación entre los últimos montos de abono
/// simulados en esta sesión (Tarea 2 del roadmap: "comparativas"). Muestra
/// una fila por escenario, con el más reciente (el que está en pantalla en
/// `_PaymentResultCard`) resaltado con el color de acento.
class _ScenarioComparisonTable extends StatelessWidget {
  final List<_PaymentResult> scenarios;
  final KreditColors kredit;
  const _ScenarioComparisonTable({required this.scenarios, required this.kredit});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comparar escenarios de esta sesión',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: KreditTextSize.body,
            color: kredit.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: kredit.borderCard.withValues(alpha: 0.78)),
            borderRadius: BorderRadius.circular(KreditRadius.card),
          ),
          child: Column(
            children: [
              for (var i = 0; i < scenarios.length; i++)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: i == scenarios.length - 1
                        ? null
                        : Border(bottom: BorderSide(color: kredit.borderCard.withValues(alpha: 0.5))),
                    color: i == 0 ? accent.withValues(alpha: 0.08) : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          _fmtCOP(scenarios[i].extraPayment),
                          style: TextStyle(
                            fontSize: KreditTextSize.body,
                            fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w500,
                            color: kredit.textPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          scenarios[i].isCard
                              ? '${scenarios[i].monthsToPayoff} mes(es) para saldar'
                              : '${scenarios[i].quotasSkipped} cuota(s) adelantadas',
                          style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textSecondary),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          scenarios[i].isCard
                              ? '${_fmtCOP(scenarios[i].newBalance)} restante'
                              : scenarios[i].interestSaving > 0
                                  ? '${_fmtCOP(scenarios[i].interestSaving)} ahorrados'
                                  : 'Sin ahorro en intereses',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: KreditTextSize.body,
                            fontWeight: FontWeight.w600,
                            color: kredit.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentResultCard extends ConsumerStatefulWidget {
  final _PaymentResult result;
  final KreditColors kredit;
  final Color accent;
  const _PaymentResultCard(
      {required this.result, required this.kredit, required this.accent});

  @override
  ConsumerState<_PaymentResultCard> createState() => _PaymentResultCardState();
}

class _PaymentResultCardState extends ConsumerState<_PaymentResultCard> {
  bool _registering = false;

  Future<void> _registerNow() async {
    final result = widget.result;
    setState(() => _registering = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      if (!result.isCard) {
        final abono = await ref.read(creditsProvider.notifier).registerLoanAbono(
              result.credit.id,
              result.extraPayment,
              note: 'Registrado desde el simulador',
            );
        if (!mounted) return;
        final skipped = abono.installmentsSkipped;
        final message = abono.wasCapped
            ? 'Se aplicaron \$${abono.amount.toStringAsFixed(0)} de los '
                '\$${abono.requestedAmount.toStringAsFixed(0)} solicitados — '
                '¡crédito saldado por completo! 🎉'
            : 'Abono de \$${abono.amount.toStringAsFixed(0)} registrado'
                '${skipped > 0 ? ' — $skipped cuota(s) adelantada(s)' : ''}';
        navigator.pop(); // cierra el sheet del simulador
        messenger.showSnackBar(SnackBar(content: Text(message)));
      } else {
        await ref.read(creditsProvider.notifier).registerMovement(
              result.credit.id,
              CardMovementType.payment,
              result.extraPayment,
              'Registrado desde el simulador',
            );
        if (!mounted) return;
        navigator.pop(); // cierra el sheet del simulador
        messenger.showSnackBar(
          const SnackBar(content: Text('Pago registrado')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _registering = false);
        messenger.showSnackBar(
          SnackBar(content: Text('No se pudo registrar el abono: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final kredit = widget.kredit;
    final accent = widget.accent;
    final isSaldado = result.newBalance == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Antes → Después ───────────────────────────────────────────────
        _SimSectionCard(
          title: 'Impacto del abono',
          highlightColor: isSaldado ? kredit.success : null,
          rows: [
            _StatRow(
              left: _StatTileData(
                label: 'Saldo antes',
                value: _fmtCOP(result.currentBalance),
                icon: Icons.account_balance_wallet_outlined,
                valueColor: kredit.textSecondary,
              ),
              right: _StatTileData(
                label: 'Saldo después',
                value: isSaldado ? 'Saldado' : _fmtCOP(result.newBalance),
                icon: Icons.trending_down_outlined,
                valueColor: isSaldado ? kredit.success : kredit.textPrimary,
              ),
            ),
            if (!result.isCard) ...[
              _StatRow(
                left: _StatTileData(
                  label: result.quotasSkipped > 0
                      ? 'Cuotas adelantadas'
                      : 'Abono aplicado',
                  value: result.quotasSkipped > 0
                      ? '~${result.quotasSkipped} cuota${result.quotasSkipped == 1 ? '' : 's'}'
                      : _fmtCOP(result.extraPayment),
                  icon: Icons.fast_forward_outlined,
                  valueColor: accent,
                ),
                right: _StatTileData(
                  label: result.interestSaving > 0
                      ? 'Ahorro en intereses'
                      : 'En intereses',
                  value: result.interestSaving > 0
                      ? _fmtCOP(result.interestSaving)
                      : 'Sin ahorro',
                  icon: Icons.savings_outlined,
                  valueColor:
                      result.interestSaving > 0 ? kredit.success : kredit.textTertiary,
                ),
              ),
            ] else ...[
              _StatRow(
                left: _StatTileData(
                  label: 'Cupo disponible',
                  value: result.newAvailable != null
                      ? _fmtCOP(result.newAvailable!)
                      : '—',
                  icon: Icons.credit_card_outlined,
                ),
                right: _StatTileData(
                  label: 'Meses para saldar',
                  value: result.monthsToPayoff > 0
                      ? '~${result.monthsToPayoff} mes${result.monthsToPayoff == 1 ? '' : 'es'}'
                      : '¡Saldado!',
                  icon: Icons.schedule_outlined,
                  valueColor:
                      result.monthsToPayoff == 0 ? kredit.success : kredit.textPrimary,
                ),
              ),
            ],
          ],
        ),
        if (isSaldado) ...[
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.celebration_outlined,
                  color: kredit.success, size: KreditIconSize.small),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '¡Con este abono saldarías por completo este crédito!',
                  style: TextStyle(
                      fontSize: KreditTextSize.body,
                      color: kredit.success,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _registering ? null : _registerNow,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(_registering
                ? 'Registrando...'
                : 'Registrar este abono ahora'),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Esto aplicará el abono de forma permanente sobre ${result.creditName}.',
          style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB C — Libertad financiera
// ─────────────────────────────────────────────────────────────────────────────

class _FreedomTab extends StatefulWidget {
  final List<Credit> credits;
  const _FreedomTab({required this.credits});

  @override
  State<_FreedomTab> createState() => _FreedomTabState();
}

class _FreedomTabState extends State<_FreedomTab> {
  final _extraCtrl = TextEditingController();
  bool _isAvalanche = true;
  _FreedomResult? _result;

  @override
  void dispose() {
    _extraCtrl.dispose();
    super.dispose();
  }

  void _simulate() {
    final extra =
        double.tryParse(CurrencyInputFormatter.unformat(_extraCtrl.text)) ?? 0;
    setState(() {
      _result = _computeFreedom(widget.credits, extra, _isAvalanche);
    });
  }

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;

    final active = widget.credits.where((c) {
      if (c is LoanCredit) return c.installments.any((i) => !i.paid);
      if (c is CardCredit) return c.currentBalance > 0;
      return false;
    }).toList();

    if (active.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: _InfoBanner(
          kredit: kredit,
          icon: Icons.celebration_outlined,
          text: '¡No tienes deudas activas! Aquí verás tu proyección de libertad financiera cuando registres créditos.',
        ),
      );
    }

    final baseline = _computeFreedom(active, 0, _isAvalanche);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _BaselineCard(baseline: baseline, kredit: kredit, accent: accent),
        const SizedBox(height: 20),
        Text(
          '¿Cuánto extra puedes pagar al mes?',
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: KreditTextSize.body,
              color: kredit.textPrimary),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _extraCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: const [CurrencyInputFormatter()],
          decoration: const InputDecoration(
            labelText: 'Abono extra mensual (\$)',
            prefixText: '\$ ',
          ),
          onChanged: (_) => setState(() => _result = null),
        ),
        const SizedBox(height: 10),
        _QuickAmountRow(
          kredit: kredit,
          onPick: (amount) => setState(() {
            _extraCtrl.text = CurrencyInputFormatter.format(amount);
            _result = null;
          }),
        ),
        const SizedBox(height: 16),
        Text(
          'Estrategia de pago',
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: KreditTextSize.body,
              color: kredit.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          'Avalanche: mayor tasa primero (ahorra más). Snowball: menor saldo primero (motivación más rápida).',
          style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
        ),
        const SizedBox(height: 8),
        _StrategyToggle(
          isAvalanche: _isAvalanche,
          onChanged: (v) => setState(() {
            _isAvalanche = v;
            _result = null;
          }),
          kredit: kredit,
          accent: accent,
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _simulate,
          icon: const Icon(Icons.auto_graph_outlined),
          label: const Text('Proyectar libertad'),
        ),
        if (_result != null) ...[
          const SizedBox(height: 24),
          _FreedomResultCard(result: _result!, kredit: kredit, accent: accent),
        ],
        const SizedBox(height: 16),
        _DisclaimerBanner(kredit: kredit),
      ],
    );
  }
}

class _BaselineCard extends StatelessWidget {
  final _FreedomResult baseline;
  final KreditColors kredit;
  final Color accent;
  const _BaselineCard(
      {required this.baseline, required this.kredit, required this.accent});

  @override
  Widget build(BuildContext context) {
    final creditsLabel =
        '${baseline.rows.length} crédito${baseline.rows.length == 1 ? '' : 's'}';
    return _SimSectionCard(
      title: 'Tu situación actual',
      rows: [
        _StatRow(
          left: _StatTileData(
            label: 'Libre de deuda en',
            value: _monthsToDateStr(baseline.baseMonthsTotal),
            icon: Icons.event_outlined,
            valueColor: accent,
          ),
          right: _StatTileData(
            label: 'Intereses pendientes',
            value: _fmtCOP(baseline.totalBaseInterest),
            icon: Icons.trending_up_outlined,
            valueColor: Colors.redAccent,
          ),
        ),
        _StatTile(
          data: _StatTileData(
            label: 'Créditos activos incluidos',
            value: creditsLabel,
            icon: Icons.credit_card_outlined,
          ),
        ),
      ],
    );
  }
}

class _FreedomResultCard extends StatelessWidget {
  final _FreedomResult result;
  final KreditColors kredit;
  final Color accent;
  const _FreedomResultCard(
      {required this.result, required this.kredit, required this.accent});

  @override
  Widget build(BuildContext context) {
    final first = result.rows.first;
    final monthsSaved = first.monthsSaved;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (monthsSaved > 0) ...[
          _SimSectionCard(
            highlightColor: accent,
            rows: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$monthsSaved',
                          style: TextStyle(
                            fontSize: KreditTextSize.emphasis,
                            fontWeight: FontWeight.w800,
                            color: accent,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'meses antes terminarías ${first.credit.name}',
                          style: TextStyle(
                            fontSize: KreditTextSize.body,
                            fontWeight: FontWeight.w600,
                            color: kredit.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (result.totalInterestSaved > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.savings_outlined,
                              size: KreditIconSize.small, color: kredit.success),
                          const SizedBox(width: 6),
                          Text(
                            'Ahorras ${_fmtCOP(result.totalInterestSaved)} en intereses',
                            style: TextStyle(
                              fontSize: KreditTextSize.body,
                              fontWeight: FontWeight.w600,
                              color: kredit.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kredit.bgCard,
              borderRadius: BorderRadius.circular(KreditRadius.card),
              border: Border.all(color: kredit.borderCard),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    size: KreditIconSize.small, color: kredit.textTertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Con ese monto el ahorro es marginal. Aumenta el abono extra para ver un impacto mayor.',
                    style: TextStyle(
                        fontSize: KreditTextSize.body, color: kredit.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          'Orden de pago recomendado',
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: KreditTextSize.body,
              color: kredit.textPrimary),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: kredit.borderCard.withValues(alpha: 0.78)),
            borderRadius: BorderRadius.circular(KreditRadius.card),
          ),
          child: Column(
            children: [
              for (var i = 0; i < result.rows.length; i++)
                _FreedomCreditTile(
                  row: result.rows[i],
                  index: i,
                  isLast: i == result.rows.length - 1,
                  maxMonths: result.baseMonthsTotal,
                  kredit: kredit,
                  accent: accent,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FreedomCreditTile extends StatelessWidget {
  final _FreedomRow row;
  final int index;
  final bool isLast;
  final int maxMonths; // para escalar la barra de progreso
  final KreditColors kredit;
  final Color accent;
  const _FreedomCreditTile({
    required this.row,
    required this.index,
    required this.isLast,
    required this.maxMonths,
    required this.kredit,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isPriority = index == 0 && row.monthlyExtra > 0;
    final saved = row.monthsSaved;
    final displayMonths = isPriority ? row.newMonths : row.baseMonths;
    final progressFraction = maxMonths > 0
        ? (displayMonths / maxMonths).clamp(0.0, 1.0)
        : 0.0;
    final barColor = isPriority ? accent : kredit.textTertiary.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPriority ? accent.withValues(alpha: 0.06) : null,
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: kredit.borderCard.withValues(alpha: 0.5))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Número de orden
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isPriority ? accent : kredit.borderCard.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: KreditTextSize.caption,
                      fontWeight: FontWeight.w700,
                      color: isPriority ? Colors.white : kredit.textTertiary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  row.credit.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: KreditTextSize.body,
                    color: kredit.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (saved > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kredit.success.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(KreditRadius.chip),
                  ),
                  child: Text(
                    '-$saved m',
                    style: TextStyle(
                      color: kredit.success,
                      fontWeight: FontWeight.w700,
                      fontSize: KreditTextSize.caption,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Barra de tiempo restante
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progressFraction,
              backgroundColor: kredit.borderCard,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            isPriority
                ? '${_fmtCOP(row.monthlyBase + row.monthlyExtra)}/mes · ${_monthsLabel(displayMonths)}'
                : '${_fmtCOP(row.monthlyBase)}/mes · ${_monthsLabel(displayMonths)}',
            style: TextStyle(
              fontSize: KreditTextSize.body,
              color: isPriority ? accent : kredit.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StrategyToggle extends StatelessWidget {
  final bool isAvalanche;
  final ValueChanged<bool> onChanged;
  final KreditColors kredit;
  final Color accent;
  const _StrategyToggle({
    required this.isAvalanche,
    required this.onChanged,
    required this.kredit,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: kredit.borderCard.withValues(alpha: 0.78)),
        borderRadius: BorderRadius.circular(KreditRadius.card),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StrategyOption(
              label: 'Avalanche',
              description: 'Mayor tasa primero',
              icon: Icons.local_fire_department_outlined,
              selected: isAvalanche,
              onTap: () => onChanged(true),
              kredit: kredit,
              accent: accent,
              isLeft: true,
            ),
          ),
          Container(width: 1, color: kredit.borderCard),
          Expanded(
            child: _StrategyOption(
              label: 'Snowball',
              description: 'Menor saldo primero',
              icon: Icons.ac_unit_outlined,
              selected: !isAvalanche,
              onTap: () => onChanged(false),
              kredit: kredit,
              accent: accent,
              isLeft: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _StrategyOption extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final KreditColors kredit;
  final Color accent;
  final bool isLeft;
  const _StrategyOption({
    required this.label,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.kredit,
    required this.accent,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.horizontal(
      left: isLeft ? Radius.circular(KreditRadius.card - 1) : Radius.zero,
      right: isLeft ? Radius.zero : Radius.circular(KreditRadius.card - 1),
    );
    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.1) : null,
          borderRadius: radius,
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? accent : kredit.textTertiary,
                size: KreditIconSize.small),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: KreditTextSize.body,
                color: selected ? accent : kredit.textPrimary,
              ),
            ),
            Text(
              description,
              style: TextStyle(
                  fontSize: KreditTextSize.caption, color: kredit.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets de apoyo reutilizables
// ─────────────────────────────────────────────────────────────────────────────

/// Alerta de utilización alta: solo tipografía + ícono en el color de
/// advertencia del tema, sin fondo relleno ni borde — la distinción frente
/// al texto informativo vive en el color, no en una caja.
class _WarningBanner extends StatelessWidget {
  final String text;
  const _WarningBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.warning_amber_rounded,
            size: KreditIconSize.small, color: AppColors.warning),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: KreditTextSize.body,
              fontWeight: FontWeight.w600,
              color: AppColors.warning,
            ),
          ),
        ),
      ],
    );
  }
}

/// Texto informativo simple (sin tarjetas ni casos de acción) para estados
/// vacíos del simulador — tipografía secundaria + ícono pequeño inline.
class _InfoBanner extends StatelessWidget {
  final KreditColors kredit;
  final IconData icon;
  final String text;
  const _InfoBanner(
      {required this.kredit, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: kredit.textTertiary, size: KreditIconSize.small),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textSecondary)),
        ),
      ],
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  final KreditColors kredit;
  const _DisclaimerBanner({required this.kredit});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: KreditIconSize.small, color: kredit.textTertiary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Simulación aproximada con base en los datos registrados. '
            'Consulta con tu entidad financiera para información oficial.',
            style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets de stat grid — reemplazan _ResultRow (horizontal) con un layout
// vertical que nunca trunca el label ni aprieta el valor.
// ─────────────────────────────────────────────────────────────────────────────

class _StatTileData {
  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;

  const _StatTileData({
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
  });
}

/// Celda de stat: etiqueta en caption arriba, valor en heading bold abajo.
/// Nunca pierde información porque label y valor tienen su propio espacio.
class _StatTile extends StatelessWidget {
  final _StatTileData data;
  const _StatTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.icon != null) ...[
            Icon(data.icon, size: 13, color: kredit.textTertiary),
            const SizedBox(height: 5),
          ],
          Text(
            data.label.toUpperCase(),
            style: TextStyle(
              fontSize: KreditTextSize.caption,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: kredit.textTertiary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            data.value,
            style: TextStyle(
              fontSize: KreditTextSize.heading,
              fontWeight: FontWeight.w700,
              color: data.valueColor ?? kredit.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dos stat tiles lado a lado, separados por línea vertical.
class _StatRow extends StatelessWidget {
  final _StatTileData left;
  final _StatTileData right;

  const _StatRow({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _StatTile(data: left)),
          Container(width: 1, color: kredit.borderCard),
          Expanded(child: _StatTile(data: right)),
        ],
      ),
    );
  }
}

/// Contenedor de sección de resultado: fondo suave + borde + separadores entre filas.
class _SimSectionCard extends StatelessWidget {
  final String? title;
  final List<Widget> rows;
  final Color? highlightColor;

  const _SimSectionCard({
    this.title,
    required this.rows,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final bg = highlightColor != null
        ? highlightColor!.withValues(alpha: 0.07)
        : kredit.bgCard;
    final borderColor = highlightColor != null
        ? highlightColor!.withValues(alpha: 0.3)
        : kredit.borderCard;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(KreditRadius.card),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Text(
                title!.toUpperCase(),
                style: TextStyle(
                  fontSize: KreditTextSize.caption,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: highlightColor ?? kredit.textTertiary,
                ),
              ),
            ),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: kredit.borderCard),
            rows[i],
          ],
        ],
      ),
    );
  }
}
