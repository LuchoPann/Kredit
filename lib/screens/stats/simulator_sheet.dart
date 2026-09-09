import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/card_movement.dart';
import '../../data/models/credit.dart';
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

// ─────────────────────────────────────────────────────────────────────────────
// Entry point: abre el sheet
// ─────────────────────────────────────────────────────────────────────────────

void openSimulatorSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const SimulatorSheet(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet principal
// ─────────────────────────────────────────────────────────────────────────────

class SimulatorSheet extends ConsumerStatefulWidget {
  const SimulatorSheet({super.key});

  @override
  ConsumerState<SimulatorSheet> createState() => _SimulatorSheetState();
}

class _SimulatorSheetState extends ConsumerState<SimulatorSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
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

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Column(
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
                    size: KreditIconSize.small, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  'Simulador financiero',
                  style: TextStyle(
                    fontSize: KreditTextSize.heading,
                    fontWeight: FontWeight.w700,
                    color: kredit.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 52, right: 20),
            child: Text(
              '¿Qué pasaría si…? Resultados aproximados.',
              style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
            ),
          ),
          const SizedBox(height: 12),
          // Tabs
          TabBar(
            controller: _tabCtrl,
            tabs: const [
              Tab(icon: Icon(Icons.shopping_cart_outlined, size: KreditIconSize.small), text: 'Simular compra'),
              Tab(icon: Icon(Icons.payments_outlined, size: KreditIconSize.small), text: 'Abonar extra'),
            ],
          ),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _PurchaseTab(credits: credits, scrollController: scrollController),
                _ExtraPaymentTab(credits: credits, scrollController: scrollController),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB A — Simulador de Compra
// ─────────────────────────────────────────────────────────────────────────────

class _PurchaseTab extends StatefulWidget {
  final List<Credit> credits;
  final ScrollController scrollController;
  const _PurchaseTab({required this.credits, required this.scrollController});

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
      controller: widget.scrollController,
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
                  fontSize: KreditTextSize.caption,
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
                  fontSize: KreditTextSize.caption,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resultado de la simulación',
          style: TextStyle(
              fontSize: KreditTextSize.body,
              fontWeight: FontWeight.w700,
              color: kredit.textPrimary),
        ),
        const SizedBox(height: 4),
        Column(
          children: _withDividers(
            kredit,
            [
              _ResultRow(
                icon: Icons.receipt_long_outlined,
                label: 'Cuota mensual estimada',
                value: _fmtCOP(result.monthlyInstallment),
                valueColor: accent,
                kredit: kredit,
              ),
              _ResultRow(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Nuevo saldo total en ${result.cardName}',
                value: _fmtCOP(result.newTotalBalance),
                valueColor: kredit.textPrimary,
                kredit: kredit,
              ),
              _ResultRow(
                icon: Icons.credit_card_outlined,
                label: 'Cupo disponible tras la compra',
                value: _fmtCOP(result.availableCredit),
                valueColor: kredit.textPrimary,
                kredit: kredit,
              ),
              if (result.estimatedInterestCost > 0)
                _ResultRow(
                  icon: Icons.trending_up_outlined,
                  label: 'Costo estimado en intereses (${result.quotas} cuotas)',
                  value: _fmtCOP(result.estimatedInterestCost),
                  valueColor: Colors.redAccent,
                  kredit: kredit,
                ),
            ],
          ),
        ),
        // Barra de utilización
        const SizedBox(height: 16),
        _UtilizationBar(
          pct: result.utilizationPct,
          kredit: kredit,
          highUtilization: highUtilization,
        ),
        if (highUtilization) ...[
          const SizedBox(height: 16),
          _WarningBanner(
            text:
                'Alta utilización del crédito (${result.utilizationPct.round()}%). Se recomienda mantenerla por debajo del 80% para no afectar tu perfil crediticio.',
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
                style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textSecondary)),
            Text('${pct.toStringAsFixed(1)}%',
                style: TextStyle(
                    fontSize: KreditTextSize.caption,
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
  final ScrollController scrollController;
  const _ExtraPaymentTab(
      {required this.credits, required this.scrollController});

  @override
  State<_ExtraPaymentTab> createState() => _ExtraPaymentTabState();
}

class _ExtraPaymentTabState extends State<_ExtraPaymentTab> {
  final _paymentCtrl = TextEditingController();
  Credit? _selectedCredit;
  _PaymentResult? _result;

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

    final currentBalance = unpaid.fold(0.0, (s, i) => s + i.amount);
    final newBalance = math.max(0.0, currentBalance - extraPayment);
    final quota = loan.quotaAmount;

    // Cuántas cuotas se saltan
    final quotasSkipped = quota > 0 ? (extraPayment / quota).floor() : 0;
    final saving = unpaid
        .take(quotasSkipped)
        .fold(0.0, (s, i) => s + i.interest);

    setState(() {
      _result = _PaymentResult(
        credit: loan,
        creditName: loan.name,
        extraPayment: extraPayment,
        currentBalance: currentBalance,
        newBalance: newBalance,
        quotasSkipped: quotasSkipped,
        interestSaving: saving,
        isCard: false,
        monthsToPayoff: 0,
      );
    });
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

    setState(() {
      _result = _PaymentResult(
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
      );
    });
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
      controller: widget.scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        Text('¿A qué crédito harías el abono?',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: KreditTextSize.caption,
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
          onChanged: (v) => setState(() {
            _selectedCredit = v;
            _result = null;
          }),
        ),
        const SizedBox(height: 16),
        Text('¿Cuánto abonarías?',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: KreditTextSize.caption,
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
          onChanged: (_) => setState(() => _result = null),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resultado del abono',
          style: TextStyle(
              fontSize: KreditTextSize.body,
              fontWeight: FontWeight.w700,
              color: kredit.textPrimary),
        ),
        const SizedBox(height: 4),
        Column(
          children: _withDividers(
            kredit,
            [
              _ResultRow(
                icon: Icons.savings_outlined,
                label: 'Abono aplicado a ${result.creditName}',
                value: _fmtCOP(result.extraPayment),
                valueColor: Colors.green,
                kredit: kredit,
              ),
              _ResultRow(
                icon: Icons.trending_down_outlined,
                label: 'Saldo anterior',
                value: _fmtCOP(result.currentBalance),
                valueColor: kredit.textSecondary,
                kredit: kredit,
              ),
              _ResultRow(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Nuevo saldo',
                value: _fmtCOP(result.newBalance),
                valueColor:
                    result.newBalance == 0 ? Colors.green : kredit.textPrimary,
                kredit: kredit,
              ),
              if (!result.isCard && result.quotasSkipped > 0)
                _ResultRow(
                  icon: Icons.fast_forward_outlined,
                  label: 'Cuotas adelantadas',
                  value:
                      '~${result.quotasSkipped} cuota${result.quotasSkipped == 1 ? '' : 's'}',
                  valueColor: accent,
                  kredit: kredit,
                ),
              if (!result.isCard && result.interestSaving > 0)
                _ResultRow(
                  icon: Icons.attach_money_outlined,
                  label: 'Ahorro estimado en intereses',
                  value: _fmtCOP(result.interestSaving),
                  valueColor: Colors.green,
                  kredit: kredit,
                ),
              if (result.isCard && result.newAvailable != null)
                _ResultRow(
                  icon: Icons.credit_card_outlined,
                  label: 'Nuevo cupo disponible',
                  value: _fmtCOP(result.newAvailable!),
                  valueColor: kredit.textPrimary,
                  kredit: kredit,
                ),
              if (result.isCard && result.monthsToPayoff > 0)
                _ResultRow(
                  icon: Icons.schedule_outlined,
                  label: 'Meses estimados para saldar (pago mínimo)',
                  value:
                      '~${result.monthsToPayoff} mes${result.monthsToPayoff == 1 ? '' : 'es'}',
                  valueColor: kredit.textSecondary,
                  kredit: kredit,
                ),
            ],
          ),
        ),
        if (result.newBalance == 0) ...[
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.celebration_outlined,
                  color: Colors.green, size: KreditIconSize.small),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '¡Con este abono saldarías por completo este crédito!',
                  style: TextStyle(
                      fontSize: KreditTextSize.caption,
                      color: kredit.textPrimary,
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
          'Esto aplicará el abono real de forma permanente sobre ${result.creditName}.',
          style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets de apoyo reutilizables
// ─────────────────────────────────────────────────────────────────────────────

/// Intercala un `Divider` fino entre cada elemento de [rows], siguiendo el
/// lenguaje "sin cajas" del dashboard: las filas de resultado se separan por
/// líneas, no por tarjetas o fondos.
List<Widget> _withDividers(KreditColors kredit, List<Widget> rows) {
  final divider = Divider(height: 1, color: kredit.borderCard);
  final result = <Widget>[];
  for (var i = 0; i < rows.length; i++) {
    if (i > 0) {
      result.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: divider,
      ));
    }
    result.add(rows[i]);
  }
  return result;
}

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;
  final KreditColors kredit;

  const _ResultRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.kredit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: KreditIconSize.small, color: kredit.textTertiary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textSecondary)),
        ),
        Text(
          value,
          style: TextStyle(
              fontSize: KreditTextSize.body, fontWeight: FontWeight.w700, color: valueColor),
        ),
      ],
    );
  }
}

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
              fontSize: KreditTextSize.caption,
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
              style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textSecondary)),
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
            style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
          ),
        ),
      ],
    );
  }
}
