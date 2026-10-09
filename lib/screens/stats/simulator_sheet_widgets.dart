// ignore_for_file: unused_element
part of 'simulator_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Header: snapshot rápido de la deuda activa
// ─────────────────────────────────────────────────────────────────────────────

class _DebtSnapshotStrip extends StatelessWidget {
  final _FreedomResult baseline;
  final AppThemeColors kredit;
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
            value: formatCOP(totalDebt),
            kredit: kredit,
          ),
          _SnapDivider(kredit: kredit),
          _SnapStat(
            label: 'Interés/mes',
            value: formatCOP(monthlyInterest),
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
  final AppThemeColors kredit;
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
                fontSize: AppTextSize.caption, color: kredit.textTertiary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: AppTextSize.body,
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
  final AppThemeColors kredit;
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
// TAB A — Simulador de Compra  (tarjetas de crédito y cupos de tienda)
// ─────────────────────────────────────────────────────────────────────────────

/// Objetivo de simulación: tarjeta o cupo de tienda.
sealed class _SimTarget {
  String get displayName;
  double get limit;
  double get usedBalance;
  double get available => math.max(0, limit - usedBalance);
}

class _CardTarget extends _SimTarget {
  final CardCredit card;
  _CardTarget(this.card);

  @override
  String get displayName => card.name;
  @override
  double get limit => card.creditLimit;
  @override
  double get usedBalance => card.currentBalance;
}

class _QuotaTarget extends _SimTarget {
  final CommercialQuota quota;
  final double _used;
  _QuotaTarget(this.quota, this._used);

  @override
  String get displayName => quota.brand;
  @override
  double get limit => quota.limit;
  @override
  double get usedBalance => _used;
}

class _PurchaseTab extends ConsumerStatefulWidget {
  final List<Credit> credits;
  const _PurchaseTab({required this.credits});

  @override
  ConsumerState<_PurchaseTab> createState() => _PurchaseTabState();
}

class _PurchaseTabState extends ConsumerState<_PurchaseTab> {
  final _amountCtrl = TextEditingController();
  final _quotasCtrl = TextEditingController(text: '1');
  // Guardamos el id (card.id o quota.id) en lugar de la instancia para evitar
  // problemas de igualdad cuando el build() reconstruye los targets.
  String? _selectedId;
  _PurchaseResult? _result;
  List<_SimTarget> _targets = [];

  @override
  void initState() {
    super.initState();
    _amountCtrl.addListener(_autoSimulate);
    _quotasCtrl.addListener(_autoSimulate);
  }

  @override
  void dispose() {
    _amountCtrl.removeListener(_autoSimulate);
    _quotasCtrl.removeListener(_autoSimulate);
    _amountCtrl.dispose();
    _quotasCtrl.dispose();
    super.dispose();
  }

  void _autoSimulate() {
    final id = _selectedId;
    if (id == null) return;
    try {
      final target = _targets.firstWhere((t) => _idOf(t) == id);
      _simulate(target);
    } catch (e) {
      debugPrint('_autoSimulate: target not found: $e');
    }
  }

  void _simulate(_SimTarget? target) {
    final raw = CurrencyInputFormatter.unformat(_amountCtrl.text);
    final amount = double.tryParse(raw);
    final quotas = int.tryParse(_quotasCtrl.text);
    if (target == null) return;
    if (amount == null || amount <= 0) {
      if (_result != null) setState(() => _result = null);
      return;
    }
    if (quotas == null || quotas <= 0) return;

    final newBalance = target.usedBalance + amount;
    final available = math.max(0.0, target.limit - newBalance);
    final utilizationPct =
        target.limit > 0 ? (newBalance / target.limit) * 100 : 0.0;
    final monthlyInstallment = amount / quotas;

    double totalInterestCost = 0;
    if (target is _CardTarget) {
      final dailyRate =
          target.card.interestRate > 0 ? (target.card.interestRate / 100 / 365) : 0.0;
      final monthlyRate = dailyRate * 30;
      if (monthlyRate > 0) {
        totalInterestCost = frenchTotalInterest(amount, monthlyRate, quotas);
      }
    }

    setState(() {
      _result = _PurchaseResult(
        purchaseAmount: amount,
        quotas: quotas,
        monthlyInstallment: monthlyInstallment,
        prevBalance: target.usedBalance,
        newTotalBalance: newBalance,
        prevAvailable: target.available,
        availableCredit: available,
        prevUtilizationPct:
            target.limit > 0 ? (target.usedBalance / target.limit) * 100 : 0.0,
        utilizationPct: utilizationPct,
        estimatedInterestCost: totalInterestCost,
        targetName: target.displayName,
        targetLimit: target.limit,
        isQuota: target is _QuotaTarget,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    final accent = Theme.of(context).colorScheme.primary;

    final quotasAsync = ref.watch(commercialQuotasProvider);
    final allQuotas = quotasAsync.valueOrNull ?? [];
    final quotaTargets = allQuotas
        .where((q) => q.entityType != EntityType.bank && q.limit > 0)
        .toList();

    // Calcular saldo usado por cupo (suma cuotas impagas de créditos ligados)
    List<_SimTarget> targets = [
      ...widget.credits.whereType<CardCredit>().map(_CardTarget.new),
      ...quotaTargets.map((q) {
        final used = widget.credits
            .whereType<LoanCredit>()
            .where((l) => l.quotaId == q.id)
            .fold(0.0, (s, l) => s + l.installments.where((i) => !i.paid).fold(0.0, (si, i) => si + i.amount));
        return _QuotaTarget(q, used);
      }),
    ];
    // Sync _targets so listeners can resolve the selected target
    _targets = targets;

    if (targets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: _InfoBanner(
          kredit: kredit,
          icon: Icons.credit_card_off_outlined,
          text: 'No tienes tarjetas ni cupos de tienda registrados.',
        ),
      );
    }

    // Resolver el target seleccionado a partir del id guardado
    final selectedTarget =
        _selectedId == null ? null : targets.where((t) => _idOf(t) == _selectedId).firstOrNull;

    // Si el id ya no existe (target eliminado), limpiar
    if (_selectedId != null && selectedTarget == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() { _selectedId = null; _result = null; });
      });
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        // ── Bloque de entrada ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          decoration: BoxDecoration(
            color: kredit.bgCard,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: kredit.borderCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DATOS DE LA COMPRA',
                style: TextStyle(
                  fontSize: AppTextSize.caption,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: kredit.textTertiary,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _selectedId,
                decoration: const InputDecoration(
                  labelText: 'Tarjeta / Cupo',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: targets
                    .map((t) => DropdownMenuItem(
                          value: _idOf(t),
                          child: Text(
                            '${t.displayName} — ${formatCOP(t.available)} disp.',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  setState(() => _selectedId = v);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _autoSimulate();
                  });
                },
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [CurrencyInputFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Valor',
                        prefixText: '\$ ',
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quotasCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cuotas',
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_result != null) ...[
          const SizedBox(height: 14),
          _PurchaseResultCard(result: _result!, kredit: kredit, accent: accent),
        ],
        const SizedBox(height: 10),
        _DisclaimerBanner(kredit: kredit),
      ],
    );
  }

  String _idOf(_SimTarget t) {
    if (t is _CardTarget) return 'card_${t.card.id}';
    if (t is _QuotaTarget) return 'quota_${t.quota.id}';
    return t.displayName;
  }
}

class _PurchaseResult {
  final double purchaseAmount;
  final int quotas;
  final double monthlyInstallment;
  final double prevBalance;
  final double newTotalBalance;
  final double prevAvailable;
  final double availableCredit;
  final double prevUtilizationPct;
  final double utilizationPct;
  final double estimatedInterestCost;
  final String targetName;
  final double targetLimit;
  final bool isQuota;

  const _PurchaseResult({
    required this.purchaseAmount,
    required this.quotas,
    required this.monthlyInstallment,
    required this.prevBalance,
    required this.newTotalBalance,
    required this.prevAvailable,
    required this.availableCredit,
    required this.prevUtilizationPct,
    required this.utilizationPct,
    required this.estimatedInterestCost,
    required this.targetName,
    required this.targetLimit,
    required this.isQuota,
  });
}

class _PurchaseResultCard extends StatelessWidget {
  final _PurchaseResult result;
  final AppThemeColors kredit;
  final Color accent;
  const _PurchaseResultCard(
      {required this.result, required this.kredit, required this.accent});

  @override
  Widget build(BuildContext context) {
    final highUtilization = result.utilizationPct > 80;
    final accentColor = Theme.of(context).colorScheme.primary;
    final barColorBefore =
        result.prevUtilizationPct > 80 ? Colors.redAccent : Colors.green;
    final barColorAfter = highUtilization ? Colors.redAccent : Colors.green;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Cuota hero ────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: accentColor.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Text(
                'CUOTA MENSUAL ESTIMADA',
                style: TextStyle(
                  fontSize: AppTextSize.caption,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                formatCOP(result.monthlyInstallment),
                style: TextStyle(
                  fontSize: AppTextSize.emphasis,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: accentColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                'por ${result.quotas} cuota${result.quotas == 1 ? '' : 's'}',
                style: TextStyle(
                    fontSize: AppTextSize.body, color: kredit.textSecondary),
              ),
              if (result.estimatedInterestCost > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Intereses estimados: ${formatCOP(result.estimatedInterestCost)}',
                  style: TextStyle(
                      fontSize: AppTextSize.caption,
                      color: Colors.redAccent.withValues(alpha: 0.85)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ── Panel antes / después ─────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          decoration: BoxDecoration(
            color: kredit.bgCard,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: kredit.borderCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'IMPACTO EN ${result.isQuota ? 'TU CUPO' : 'TU TARJETA'}',
                style: TextStyle(
                  fontSize: AppTextSize.caption,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: kredit.textTertiary,
                ),
              ),
              const SizedBox(height: 12),
              // Fila de comparación: antes / después
              IntrinsicHeight(
                child: Row(
                  children: [
                    // ANTES
                    Expanded(
                      child: _BeforeAfterColumn(
                        label: 'ANTES',
                        balance: result.prevBalance,
                        available: result.prevAvailable,
                        kredit: kredit,
                        isAfter: false,
                      ),
                    ),
                    // Flecha central
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_forward_rounded,
                              size: 20, color: kredit.textTertiary),
                        ],
                      ),
                    ),
                    // DESPUÉS
                    Expanded(
                      child: _BeforeAfterColumn(
                        label: 'DESPUÉS',
                        balance: result.newTotalBalance,
                        available: result.availableCredit,
                        kredit: kredit,
                        isAfter: true,
                        highUtilization: highUtilization,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Barra de utilización: antes y después superpuestas
              _DoubleUtilizationBar(
                prevPct: result.prevUtilizationPct,
                newPct: result.utilizationPct,
                kredit: kredit,
                barColorBefore: barColorBefore,
                barColorAfter: barColorAfter,
              ),
            ],
          ),
        ),

        if (highUtilization) ...[
          const SizedBox(height: 8),
          _WarningBanner(
            text:
                'Alta utilización (${result.utilizationPct.round()}%). Se recomienda mantenerla por debajo del 80%.',
          ),
        ],
      ],
    );
  }
}

class _BeforeAfterColumn extends StatelessWidget {
  final String label;
  final double balance;
  final double available;
  final AppThemeColors kredit;
  final bool isAfter;
  final bool highUtilization;

  const _BeforeAfterColumn({
    required this.label,
    required this.balance,
    required this.available,
    required this.kredit,
    required this.isAfter,
    this.highUtilization = false,
  });

  @override
  Widget build(BuildContext context) {
    final balanceColor = isAfter && highUtilization
        ? Colors.redAccent
        : kredit.textPrimary;
    final availColor = isAfter && highUtilization
        ? Colors.redAccent.withValues(alpha: 0.7)
        : kredit.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: kredit.bgSecondary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kredit.borderCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: kredit.textTertiary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Saldo',
            style: TextStyle(fontSize: AppTextSize.caption, color: kredit.textTertiary),
          ),
          Text(
            formatCOP(balance),
            style: TextStyle(
              fontSize: AppTextSize.body,
              fontWeight: FontWeight.w700,
              color: balanceColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Disponible',
            style: TextStyle(fontSize: AppTextSize.caption, color: kredit.textTertiary),
          ),
          Text(
            formatCOP(available),
            style: TextStyle(
              fontSize: AppTextSize.body,
              fontWeight: FontWeight.w700,
              color: availColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoubleUtilizationBar extends StatelessWidget {
  final double prevPct;
  final double newPct;
  final AppThemeColors kredit;
  final Color barColorBefore;
  final Color barColorAfter;

  const _DoubleUtilizationBar({
    required this.prevPct,
    required this.newPct,
    required this.kredit,
    required this.barColorBefore,
    required this.barColorAfter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Utilización del cupo',
                style: TextStyle(
                    fontSize: AppTextSize.caption, color: kredit.textSecondary)),
            Row(
              children: [
                Text('${prevPct.toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontSize: AppTextSize.caption,
                        color: barColorBefore,
                        fontWeight: FontWeight.w600)),
                Text(' → ',
                    style: TextStyle(
                        fontSize: AppTextSize.caption, color: kredit.textTertiary)),
                Text('${newPct.toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontSize: AppTextSize.caption,
                        color: barColorAfter,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            // Barra base (fondo)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (newPct.clamp(0, 100)) / 100,
                backgroundColor: kredit.borderCard,
                valueColor: AlwaysStoppedAnimation<Color>(
                    barColorAfter.withValues(alpha: 0.35)),
                minHeight: 10,
              ),
            ),
            // Marcador del nivel anterior
            FractionallySizedBox(
              widthFactor: (prevPct.clamp(0, 100)) / 100,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: barColorBefore.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(width: 10, height: 4, decoration: BoxDecoration(color: barColorBefore.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 4),
            Text('Antes', style: TextStyle(fontSize: 9, color: kredit.textTertiary)),
            const SizedBox(width: 10),
            Container(width: 10, height: 4, decoration: BoxDecoration(color: barColorAfter.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 4),
            Text('Después', style: TextStyle(fontSize: 9, color: kredit.textTertiary)),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB B — Simulador de Abono Extra
// ─────────────────────────────────────────────────────────────────────────────

class _ExtraPaymentTab extends ConsumerStatefulWidget {
  final List<Credit> credits;
  final String? initialCreditId;
  const _ExtraPaymentTab({required this.credits, this.initialCreditId});

  @override
  ConsumerState<_ExtraPaymentTab> createState() => _ExtraPaymentTabState();
}

class _ExtraPaymentTabState extends ConsumerState<_ExtraPaymentTab> {
  final _paymentCtrl = TextEditingController();
  Credit? _selectedCredit;
  _PaymentResult? _result;
  bool _registering = false;

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
    _paymentCtrl.addListener(_autoSimulate);
  }

  void _autoSimulate() {
    final credit = _selectedCredit;
    if (credit == null) return;
    final amount = double.tryParse(CurrencyInputFormatter.unformat(_paymentCtrl.text));
    if (amount == null || amount <= 0) {
      if (_result != null) setState(() { _result = null; _threeScenarios = []; });
      return;
    }
    _simulate();
  }


  @override
  void dispose() {
    _paymentCtrl.removeListener(_autoSimulate);
    _paymentCtrl.dispose();
    super.dispose();
  }

  Future<void> _registerNow() async {
    final result = _result;
    if (result == null) return;
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
                '¡crédito saldado por completo!'
            : 'Abono de \$${abono.amount.toStringAsFixed(0)} registrado'
                '${skipped > 0 ? ' — $skipped cuota(s) adelantada(s)' : ''}';
        navigator.pop();
        final creditId = result.credit.id;
        final capturedAbono = abono;
        messenger.showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'DESHACER',
              onPressed: () async {
                try {
                  await ref
                      .read(creditsProvider.notifier)
                      .deleteLoanAbono(creditId, capturedAbono);
                } catch (_) {}
              },
            ),
          ),
        );
      } else {
        await ref.read(creditsProvider.notifier).registerMovement(
              result.credit.id,
              CardMovementType.payment,
              result.extraPayment,
              'Registrado desde el simulador',
            );
        if (!mounted) return;
        navigator.pop();
        messenger.showSnackBar(const SnackBar(content: Text('Pago registrado')));
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

  void _simulate() {
    final amount = double.tryParse(CurrencyInputFormatter.unformat(_paymentCtrl.text));
    final credit = _selectedCredit;
    if (credit == null) return;
    if (amount == null || amount <= 0) return;

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
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    final accent = Theme.of(context).colorScheme.primary;

    final quotasAsync = ref.watch(commercialQuotasProvider);
    final quotaMap = {
      for (final q in quotasAsync.valueOrNull ?? []) q.id: q.brand,
    };

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        // ── Bloque de entrada ───────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          decoration: BoxDecoration(
            color: kredit.bgCard,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: kredit.borderCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DATOS DEL ABONO',
                style: TextStyle(
                  fontSize: AppTextSize.caption,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: kredit.textTertiary,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<Credit>(
                initialValue: _selectedCredit,
                decoration: const InputDecoration(
                  labelText: 'Crédito',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: widget.credits.map((c) {
                  final quotaBrand = c is LoanCredit && c.quotaId != null
                      ? quotaMap[c.quotaId]
                      : null;
                  final label = quotaBrand != null
                      ? '${c.name} · $quotaBrand'
                      : c.name;
                  return DropdownMenuItem(
                    value: c,
                    child: Text(label, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedCredit = v;
                    _threeScenarios = [];
                  });
                  if (v != null) {
                    _autoSimulate();
                  } else {
                    setState(() => _result = null);
                  }
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _paymentCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: const [CurrencyInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Monto del abono (\$)',
                  prefixText: '\$ ',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 8),
              _QuickAmountRow(
                kredit: kredit,
                onPick: (amount) {
                  _paymentCtrl.text = CurrencyInputFormatter.format(amount);
                  // listener will trigger _autoSimulate
                },
              ),
            ],
          ),
        ),
        if (_result != null) ...[
          const SizedBox(height: 14),
          _PaymentResultCard(result: _result!, kredit: kredit, accent: accent),
          const SizedBox(height: 12),
          _SaveScenarioButton(
            onSave: (nombre) async {
              final r = _result!;
              await _saveNamedScenario(_NamedScenario(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                nombre: nombre,
                fecha: DateTime.now().toIso8601String().substring(0, 10),
                tipo: 'abono',
                resumen:
                    '${r.creditName} · abono ${formatCOP(r.extraPayment)} · ahorro ${formatCOP(r.interestSaving)}',
              ));
            },
          ),
        ],
        if (_threeScenarios.isNotEmpty) ...[
          const SizedBox(height: 8),
          _StrategySelector(
            scenarios: _threeScenarios,
            kredit: kredit,
            accent: accent,
            onRegister: _registering ? null : _registerNow,
            registering: _registering,
          ),
        ],
        const SizedBox(height: 10),
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

/// Fila de chips con montos típicos ($50k/$100k/$200k) para acceso rápido.
class _QuickAmountRow extends StatelessWidget {
  final AppThemeColors kredit;
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

class _StrategySelector extends StatefulWidget {
  final List<AbonoScenarioResult> scenarios;
  final AppThemeColors kredit;
  final Color accent;
  final VoidCallback? onRegister;
  final bool registering;

  const _StrategySelector({
    required this.scenarios,
    required this.kredit,
    required this.accent,
    required this.onRegister,
    required this.registering,
  });

  @override
  State<_StrategySelector> createState() => _StrategySelectorState();
}

class _StrategySelectorState extends State<_StrategySelector> {
  int? _selectedIdx;

  List<_StrategyItem> _buildItems() {
    final kredit = widget.kredit;
    final accent = widget.accent;
    final scenarios = widget.scenarios;

    final baseline = scenarios.firstWhere((s) => s.strategy == null);
    final reducirPlazo =
        scenarios.where((s) => s.strategy == AbonoStrategy.reducirPlazo).firstOrNull;
    final reducirCuota =
        scenarios.where((s) => s.strategy == AbonoStrategy.reducirCuota).firstOrNull;

    final items = <_StrategyItem>[];

    if (reducirPlazo != null) {
      final saved = reducirPlazo.interestSaved;
      items.add(_StrategyItem(
        icon: Icons.rocket_launch_outlined,
        title: 'Reducir el plazo',
        tagline: 'Terminas antes · mayor ahorro en intereses',
        statLine: saved > 0
            ? 'Terminas ${formatDate(reducirPlazo.payoffDate)} · Ahorras ${formatCOP(saved)}'
            : 'Terminas ${formatDate(reducirPlazo.payoffDate)}',
        statColor: accent,
        description:
            'El abono va directo al capital. Sigues pagando la misma cuota mensual pero el préstamo termina antes. '
            'Es la opción que más intereses te ahorra a largo plazo.',
        steps: const [
          'Contacta tu banco o entidad financiera (presencial, app o línea de atención)',
          'Solicita un "abono extraordinario a capital con reducción de plazo"',
          'Pide confirmación escrita de la nueva fecha de terminación del crédito',
        ],
        recommended: true,
      ));
    }

    if (reducirCuota != null) {
      final saved = reducirCuota.interestSaved;
      items.add(_StrategyItem(
        icon: Icons.compress_outlined,
        title: 'Reducir la cuota mensual',
        tagline: 'Pagas menos cada mes · más alivio en tu flujo de caja',
        statLine:
            'Nueva cuota: ${formatCOP(reducirCuota.quota)}${saved > 0 ? ' · Ahorras ${formatCOP(saved)}' : ''}',
        statColor: kredit.textPrimary,
        description:
            'El abono reduce el capital y tu cuota mensual baja. Útil si necesitas liberar presupuesto mensual. '
            'Ahorras menos en intereses que con reducción de plazo.',
        steps: const [
          'Contacta tu banco o entidad financiera',
          'Solicita un "abono extraordinario a capital con reducción de cuota"',
          'Verifica y guarda el comprobante con el nuevo valor de la cuota',
        ],
        recommended: false,
      ));
    }

    items.add(_StrategyItem(
      icon: Icons.schedule_send_outlined,
      title: 'Cuota anticipada',
      tagline: 'Paga la próxima cuota ahora · tranquilidad garantizada',
      statLine: baseline.installmentsSaved > 0
          ? '~${baseline.installmentsSaved} cuota${baseline.installmentsSaved == 1 ? '' : 's'} adelantada${baseline.installmentsSaved == 1 ? '' : 's'}'
          : 'Próxima cuota cubierta',
      statColor: kredit.textPrimary,
      description:
          'En lugar de abonar a capital, pagas la cuota del próximo período por adelantado. '
          'No cambia tu cuota futura ni tu plazo, pero te da la tranquilidad de tener el siguiente pago asegurado.',
      steps: const [
        'Realiza el pago como lo harías normalmente (PSE, transferencia o ventanilla)',
        'Guarda el comprobante de pago',
        'Verifica en el portal de tu entidad que el pago quedó registrado correctamente',
      ],
      recommended: false,
    ));

    items.add(_StrategyItem(
      icon: Icons.checklist_outlined,
      title: 'Solo registrar en Krezium',
      tagline: 'Mantén tu historial actualizado · sin cambios en el crédito',
      statLine: 'Interés restante: ${formatCOP(baseline.totalInterestRemaining)}',
      statColor: kredit.textTertiary,
      description:
          'Registra el abono en Krezium para mantener tu historial al día, sin instruir ningún cambio en el esquema de pagos del crédito.',
      steps: const [
        'Confirma que ya realizaste el abono con tu entidad financiera',
        'Toca "Registrar" para actualizar Krezium',
      ],
      recommended: false,
    ));

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final kredit = widget.kredit;
    final accent = widget.accent;
    final items = _buildItems();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estrategia de abono',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: AppTextSize.heading,
            color: kredit.textPrimary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Elige cómo aplicar este abono. Son sugerencias — tu entidad financiera tiene la última palabra.',
          style: TextStyle(fontSize: AppTextSize.body, color: kredit.textSecondary),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: kredit.borderCard),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) Divider(height: 1, color: kredit.borderCard),
                _StrategyAccordionTile(
                  item: items[i],
                  isSelected: _selectedIdx == i,
                  isFirst: i == 0,
                  isLast: i == items.length - 1,
                  onTap: () => setState(
                      () => _selectedIdx = _selectedIdx == i ? null : i),
                  kredit: kredit,
                  accent: accent,
                ),
              ],
            ],
          ),
        ),
        if (_selectedIdx != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.registering
                  ? null
                  : () async {
                      final items = _buildItems();
                      final sel = _selectedIdx;
                      if (sel == null) return;
                      final confirmed = await showAppConfirmSheet(
                        context,
                        title: 'Confirmar registro',
                        message:
                            'Vas a registrar un abono con la estrategia '
                            '"${items[sel].title}". Recuerda contactar a tu '
                            'entidad financiera para aplicarla. ¿Continuar?',
                        confirmLabel: 'Registrar',
                        isDanger: false,
                        icon: Icons.check_circle_outline,
                      );
                      if (confirmed == true && context.mounted) {
                        widget.onRegister?.call();
                      }
                    },
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                widget.registering
                    ? 'Registrando...'
                    : 'Registrar abono con esta estrategia',
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kredit.bgCard,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: kredit.borderCard),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    size: AppIconSize.small, color: kredit.textTertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Las estrategias son sugerencias orientativas basadas en los datos registrados. '
                    'Pueden existir otras variables que esta app no contempla. '
                    'Consulta siempre con tu entidad financiera antes de actuar.',
                    style: TextStyle(
                        fontSize: AppTextSize.caption,
                        fontStyle: FontStyle.italic,
                        color: kredit.textTertiary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StrategyItem {
  final IconData icon;
  final String title;
  final String tagline;
  final String statLine;
  final Color statColor;
  final String description;
  final List<String> steps;
  final bool recommended;

  const _StrategyItem({
    required this.icon,
    required this.title,
    required this.tagline,
    required this.statLine,
    required this.statColor,
    required this.description,
    required this.steps,
    required this.recommended,
  });
}

class _StrategyAccordionTile extends StatelessWidget {
  final _StrategyItem item;
  final bool isSelected;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;
  final AppThemeColors kredit;
  final Color accent;

  const _StrategyAccordionTile({
    required this.item,
    required this.isSelected,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
    required this.kredit,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.vertical(
      top: isFirst ? Radius.circular(AppRadius.card - 1) : Radius.zero,
      bottom:
          isLast && !isSelected ? Radius.circular(AppRadius.card - 1) : Radius.zero,
    );

    return ClipRRect(
      borderRadius: borderRadius,
      child: Material(
        color: isSelected ? accent.withValues(alpha: 0.06) : kredit.bgCard,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accent.withValues(alpha: 0.12)
                            : kredit.bgCard,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? accent : kredit.borderCard,
                        ),
                      ),
                      child: Icon(
                        item.icon,
                        size: 18,
                        color: isSelected ? accent : kredit.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: AppTextSize.body,
                                    color: isSelected ? accent : kredit.textPrimary,
                                  ),
                                ),
                              ),
                              if (item.recommended) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: kredit.success.withValues(alpha: 0.13),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Recomendado',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: kredit.success,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.tagline,
                            style: TextStyle(
                              fontSize: AppTextSize.caption,
                              color: kredit.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isSelected
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: AppIconSize.small,
                      color: kredit.textTertiary,
                    ),
                  ],
                ),
              ),
              if (isSelected) ...[
                Divider(height: 1, color: kredit.borderCard),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.statLine,
                          style: TextStyle(
                            fontSize: AppTextSize.body,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: AppTextSize.body,
                          color: kredit.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Cómo hacerlo',
                        style: TextStyle(
                          fontSize: AppTextSize.body,
                          fontWeight: FontWeight.w700,
                          color: kredit.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (var i = 0; i < item.steps.length; i++) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              margin: const EdgeInsets.only(top: 1),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: accent,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.steps[i],
                                style: TextStyle(
                                  fontSize: AppTextSize.body,
                                  color: kredit.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (i < item.steps.length - 1) const SizedBox(height: 6),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentResultCard extends StatelessWidget {
  final _PaymentResult result;
  final AppThemeColors kredit;
  final Color accent;
  const _PaymentResultCard(
      {required this.result, required this.kredit, required this.accent});

  IconData _impactIcon() {
    if (result.newBalance == 0) return Icons.celebration_outlined;
    if (result.interestSaving > 0) return Icons.savings_outlined;
    if (result.quotasSkipped > 0) return Icons.fast_forward_outlined;
    if (result.isCard && result.monthsToPayoff > 0) return Icons.schedule_outlined;
    return Icons.check_circle_outline;
  }

  Color _impactColor(Color savingsColor, Color accentC) {
    if (result.newBalance == 0 || result.interestSaving > 0) return savingsColor;
    return accentC;
  }

  String _impactLabel() {
    if (result.newBalance == 0) {
      return '¡Con este abono saldarías por completo este crédito!';
    }
    if (!result.isCard) {
      if (result.interestSaving > 0) {
        final extra = result.quotasSkipped > 0
            ? ' · ~${result.quotasSkipped} cuota${result.quotasSkipped == 1 ? '' : 's'} adelantadas'
            : '';
        return 'Ahorras ${formatCOP(result.interestSaving)} en intereses$extra';
      }
      if (result.quotasSkipped > 0) {
        return '~${result.quotasSkipped} cuota${result.quotasSkipped == 1 ? '' : 's'} adelantadas';
      }
      return 'Abono aplicado sobre el saldo';
    } else {
      if (result.monthsToPayoff == 0) return '¡Tarjeta saldada con este pago!';
      final cupo = result.newAvailable != null
          ? ' · ${formatCOP(result.newAvailable!)} cupo disponible'
          : '';
      return '~${result.monthsToPayoff} mes${result.monthsToPayoff == 1 ? '' : 'es'} para saldar$cupo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaldado = result.newBalance == 0;
    final savingsColor = kredit.success;
    final accentC = accent;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kredit.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isSaldado ? savingsColor.withValues(alpha: 0.4) : kredit.borderCard,
          width: isSaldado ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabecera ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              children: [
                Icon(
                  isSaldado ? Icons.celebration_outlined : Icons.receipt_long_outlined,
                  size: AppIconSize.small,
                  color: isSaldado ? savingsColor : kredit.textTertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  'IMPACTO DEL ABONO',
                  style: TextStyle(
                    fontSize: AppTextSize.caption,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isSaldado ? savingsColor : kredit.textTertiary,
                  ),
                ),
                const Spacer(),
                if (isSaldado)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: savingsColor.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '¡Saldado!',
                      style: TextStyle(
                        fontSize: AppTextSize.caption,
                        fontWeight: FontWeight.w700,
                        color: savingsColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: kredit.borderCard),
          // ── Antes → Después ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ANTES',
                        style: TextStyle(
                          fontSize: AppTextSize.caption,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          color: kredit.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        formatCOP(result.currentBalance),
                        style: TextStyle(
                          fontSize: AppTextSize.heading,
                          fontWeight: FontWeight.w700,
                          color: kredit.textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: AppIconSize.small,
                      color: isSaldado ? savingsColor : accentC,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '−${formatCOP(result.extraPayment)}',
                      style: TextStyle(
                        fontSize: AppTextSize.caption,
                        fontWeight: FontWeight.w600,
                        color: isSaldado ? savingsColor : accentC,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'DESPUÉS',
                        style: TextStyle(
                          fontSize: AppTextSize.caption,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          color: kredit.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isSaldado ? '\$0' : formatCOP(result.newBalance),
                        style: TextStyle(
                          fontSize: AppTextSize.heading,
                          fontWeight: FontWeight.w800,
                          color: isSaldado ? savingsColor : kredit.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: kredit.borderCard),
          // ── Línea de impacto clave ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            child: Row(
              children: [
                Icon(
                  _impactIcon(),
                  size: AppIconSize.small,
                  color: _impactColor(savingsColor, accentC),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _impactLabel(),
                    style: TextStyle(
                      fontSize: AppTextSize.body,
                      fontWeight: FontWeight.w600,
                      color: _impactColor(savingsColor, accentC),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
  void initState() {
    super.initState();
    _extraCtrl.addListener(_autoSimulate);
  }

  @override
  void dispose() {
    _extraCtrl.removeListener(_autoSimulate);
    _extraCtrl.dispose();
    super.dispose();
  }

  void _autoSimulate() {
    final parsed = double.tryParse(CurrencyInputFormatter.unformat(_extraCtrl.text));
    if (parsed == null || parsed <= 0) {
      if (_result != null) setState(() => _result = null);
      return;
    }
    final active = widget.credits.where((c) {
      if (c is LoanCredit) return c.installments.any((i) => !i.paid);
      if (c is CardCredit) return c.currentBalance > 0;
      return false;
    }).toList();
    setState(() {
      _result = _computeFreedom(active, parsed, _isAvalanche);
    });
  }


  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        _BaselineCard(baseline: baseline, kredit: kredit, accent: accent),
        const SizedBox(height: 10),
        // ── Bloque de entrada ───────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          decoration: BoxDecoration(
            color: kredit.bgCard,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: kredit.borderCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CONFIGURAR PROYECCIÓN',
                style: TextStyle(
                  fontSize: AppTextSize.caption,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: kredit.textTertiary,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _extraCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: const [CurrencyInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Abono extra mensual (\$)',
                  prefixText: '\$ ',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (_) {},
              ),
              const SizedBox(height: 8),
              _QuickAmountRow(
                kredit: kredit,
                onPick: (amount) {
                  _extraCtrl.text = CurrencyInputFormatter.format(amount);
                },
              ),
              const SizedBox(height: 10),
              Text(
                'ESTRATEGIA DE PAGO',
                style: TextStyle(
                  fontSize: AppTextSize.caption,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: kredit.textTertiary,
                ),
              ),
              const SizedBox(height: 6),
              _StrategyToggle(
                isAvalanche: _isAvalanche,
                onChanged: (v) {
                  setState(() => _isAvalanche = v);
                  _autoSimulate();
                },
                kredit: kredit,
                accent: accent,
              ),
            ],
          ),
        ),
        if (_result != null) ...[
          const SizedBox(height: 14),
          _FreedomResultCard(result: _result!, kredit: kredit, accent: accent),
        ],
        const SizedBox(height: 10),
        _DisclaimerBanner(kredit: kredit),
      ],
    );
  }
}

class _BaselineCard extends StatelessWidget {
  final _FreedomResult baseline;
  final AppThemeColors kredit;
  final Color accent;
  const _BaselineCard(
      {required this.baseline, required this.kredit, required this.accent});

  @override
  Widget build(BuildContext context) {
    final totalMonthlyBase =
        baseline.rows.fold(0.0, (s, r) => r.monthlyBase > 0 ? s + r.monthlyBase : s);
    final totalBalance =
        baseline.rows.fold(0.0, (s, r) => s + _remainingBalanceOf(r.credit));
    final maxMonths = baseline.baseMonthsTotal;
    // Tasa promedio ponderada por saldo (solo créditos con tasa > 0)
    double weightedRate = 0;
    double rateWeight = 0;
    for (final r in baseline.rows) {
      final rate = _interestRateOf(r.credit);
      final bal = _remainingBalanceOf(r.credit);
      if (rate > 0 && bal > 0) {
        weightedRate += rate * bal;
        rateWeight += bal;
      }
    }
    final avgRate = rateWeight > 0 ? weightedRate / rateWeight : 0.0;
    final creditsCount = baseline.rows.length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kredit.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: kredit.borderCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabecera ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              children: [
                Icon(Icons.account_balance_outlined,
                    size: AppIconSize.small, color: kredit.textTertiary),
                const SizedBox(width: 8),
                Text(
                  'TU SITUACIÓN ACTUAL',
                  style: TextStyle(
                    fontSize: AppTextSize.caption,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: kredit.textTertiary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kredit.borderCard.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$creditsCount crédito${creditsCount == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: AppTextSize.caption,
                      fontWeight: FontWeight.w600,
                      color: kredit.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: kredit.borderCard),
          // ── Fila 1: Cuota total y Tasa ────────────────────────────────────
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CUOTA MENSUAL',
                          style: TextStyle(
                            fontSize: AppTextSize.caption,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                            color: kredit.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          totalMonthlyBase > 0 ? formatCOP(totalMonthlyBase) : '—',
                          style: TextStyle(
                            fontSize: AppTextSize.heading,
                            fontWeight: FontWeight.w700,
                            color: kredit.textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, color: kredit.borderCard),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TASA PROM.',
                          style: TextStyle(
                            fontSize: AppTextSize.caption,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                            color: kredit.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          avgRate > 0
                              ? '${avgRate.toStringAsFixed(2)}%'
                              : '—',
                          style: TextStyle(
                            fontSize: AppTextSize.heading,
                            fontWeight: FontWeight.w700,
                            color: avgRate > 30 ? Colors.redAccent : kredit.textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: kredit.borderCard),
          // ── Fila 2: Saldo y Tiempo restante ──────────────────────────────
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SALDO PENDIENTE',
                          style: TextStyle(
                            fontSize: AppTextSize.caption,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                            color: kredit.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          formatCOP(totalBalance),
                          style: TextStyle(
                            fontSize: AppTextSize.heading,
                            fontWeight: FontWeight.w700,
                            color: Colors.redAccent,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, color: kredit.borderCard),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TIEMPO RESTANTE',
                          style: TextStyle(
                            fontSize: AppTextSize.caption,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                            color: kredit.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _monthsLabel(maxMonths),
                          style: TextStyle(
                            fontSize: AppTextSize.heading,
                            fontWeight: FontWeight.w700,
                            color: kredit.textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: kredit.borderCard),
          // ── Línea de insight: fecha estimada ─────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            child: Row(
              children: [
                Icon(Icons.flag_outlined, size: AppIconSize.small, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sin deudas estimado para ${_monthsToDateStr(maxMonths)}',
                    style: TextStyle(
                      fontSize: AppTextSize.body,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FreedomResultCard extends StatelessWidget {
  final _FreedomResult result;
  final AppThemeColors kredit;
  final Color accent;
  const _FreedomResultCard(
      {required this.result, required this.kredit, required this.accent});

  @override
  Widget build(BuildContext context) {
    final first = result.rows.first;
    final monthsSaved = first.monthsSaved;
    // Meses con abono extra = newMonths del primer crédito (al que se aplica el extra)
    final newMonthsTotal = first.monthlyExtra > 0
        ? result.rows.map((r) => r.newMonths).reduce(math.max)
        : result.baseMonthsTotal;
    final freedomDate = _monthsToDateStr(newMonthsTotal);
    final cuotasRestantes = result.rows.fold(0, (s, r) {
      if (r.credit is LoanCredit) {
        return s + (r.credit as LoanCredit).installments.where((i) => !i.paid).length;
      }
      return s;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Card de proyección ────────────────────────────────────────────
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: kredit.bgCard,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: monthsSaved > 0
                  ? accent.withValues(alpha: 0.4)
                  : kredit.borderCard,
              width: monthsSaved > 0 ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Row(
                  children: [
                    Icon(Icons.rocket_launch_outlined,
                        size: AppIconSize.small,
                        color: monthsSaved > 0 ? accent : kredit.textTertiary),
                    const SizedBox(width: 8),
                    Text(
                      'PROYECCIÓN DE LIBERTAD',
                      style: TextStyle(
                        fontSize: AppTextSize.caption,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: monthsSaved > 0 ? accent : kredit.textTertiary,
                      ),
                    ),
                    if (monthsSaved > 0) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: kredit.success.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '−$monthsSaved mes${monthsSaved == 1 ? '' : 'es'}',
                          style: TextStyle(
                            fontSize: AppTextSize.caption,
                            fontWeight: FontWeight.w700,
                            color: kredit.success,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Divider(height: 1, color: kredit.borderCard),
              // Fecha de libertad prominente
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SIN DEUDAS EL',
                      style: TextStyle(
                        fontSize: AppTextSize.caption,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: kredit.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      freedomDate,
                      style: TextStyle(
                        fontSize: AppTextSize.emphasis,
                        fontWeight: FontWeight.w800,
                        color: accent,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: kredit.borderCard),
              // Stats secundarios
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TIEMPO TOTAL',
                              style: TextStyle(
                                fontSize: AppTextSize.caption,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                                color: kredit.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _monthsLabel(newMonthsTotal),
                              style: TextStyle(
                                fontSize: AppTextSize.body,
                                fontWeight: FontWeight.w700,
                                color: kredit.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (result.totalInterestSaved > 0) ...[
                      Container(width: 1, color: kredit.borderCard),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AHORRO TOTAL',
                                style: TextStyle(
                                  fontSize: AppTextSize.caption,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.4,
                                  color: kredit.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                formatCOP(result.totalInterestSaved),
                                style: TextStyle(
                                  fontSize: AppTextSize.body,
                                  fontWeight: FontWeight.w700,
                                  color: kredit.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else if (cuotasRestantes > 0) ...[
                      Container(width: 1, color: kredit.borderCard),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CUOTAS TOTALES',
                                style: TextStyle(
                                  fontSize: AppTextSize.caption,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.4,
                                  color: kredit.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '$cuotasRestantes pendientes',
                                style: TextStyle(
                                  fontSize: AppTextSize.body,
                                  fontWeight: FontWeight.w700,
                                  color: kredit.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (monthsSaved > 0) ...[
                Divider(height: 1, color: kredit.borderCard),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  child: Row(
                    children: [
                      Icon(Icons.savings_outlined,
                          size: AppIconSize.small, color: kredit.success),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$monthsSaved mes${monthsSaved == 1 ? '' : 'es'} antes libres con este abono extra mensual',
                          style: TextStyle(
                            fontSize: AppTextSize.body,
                            fontWeight: FontWeight.w600,
                            color: kredit.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                  decoration: BoxDecoration(
                    color: kredit.bgCard,
                    borderRadius: BorderRadius.circular(AppRadius.tile),
                    border: Border.all(color: kredit.borderCard),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          size: 14,
                          color: kredit.textTertiary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Con ese monto el impacto es marginal. Aumenta el abono extra para ver una diferencia mayor.',
                          style: TextStyle(
                            fontSize: AppTextSize.caption,
                            fontStyle: FontStyle.italic,
                            color: kredit.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Nota de estimación
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
          decoration: BoxDecoration(
            color: kredit.bgCard,
            borderRadius: BorderRadius.circular(AppRadius.tile),
            border: Border.all(color: kredit.borderCard),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 14, color: kredit.textTertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Proyección estimada. Sujeta a cambios según los pagos reales realizados.',
                  style: TextStyle(
                    fontSize: AppTextSize.caption,
                    fontStyle: FontStyle.italic,
                    color: kredit.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // ── Orden de pago ─────────────────────────────────────────────────
        Text(
          'Orden de pago recomendado',
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: AppTextSize.body,
              color: kredit.textPrimary),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: kredit.borderCard.withValues(alpha: 0.78)),
            borderRadius: BorderRadius.circular(AppRadius.card),
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
  final AppThemeColors kredit;
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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
                      fontSize: AppTextSize.caption,
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
                    fontSize: AppTextSize.body,
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
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(
                    '-$saved m',
                    style: TextStyle(
                      color: kredit.success,
                      fontWeight: FontWeight.w700,
                      fontSize: AppTextSize.caption,
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
                ? '${formatCOP(row.monthlyBase + row.monthlyExtra)}/mes · ${_monthsLabel(displayMonths)}'
                : '${formatCOP(row.monthlyBase)}/mes · ${_monthsLabel(displayMonths)}',
            style: TextStyle(
              fontSize: AppTextSize.body,
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
  final AppThemeColors kredit;
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
        borderRadius: BorderRadius.circular(AppRadius.card),
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
  final AppThemeColors kredit;
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
      left: isLeft ? Radius.circular(AppRadius.card - 1) : Radius.zero,
      right: isLeft ? Radius.zero : Radius.circular(AppRadius.card - 1),
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
                size: AppIconSize.small),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: AppTextSize.body,
                color: selected ? accent : kredit.textPrimary,
              ),
            ),
            Text(
              description,
              style: TextStyle(
                  fontSize: AppTextSize.caption, color: kredit.textTertiary),
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
            size: AppIconSize.small, color: AppColors.warning),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: AppTextSize.body,
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
  final AppThemeColors kredit;
  final IconData icon;
  final String text;
  const _InfoBanner(
      {required this.kredit, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
      decoration: BoxDecoration(
        color: kredit.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(color: kredit.borderCard),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kredit.textTertiary, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: AppTextSize.caption,
                fontStyle: FontStyle.italic,
                color: kredit.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  final AppThemeColors kredit;
  const _DisclaimerBanner({required this.kredit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
      decoration: BoxDecoration(
        color: kredit.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(color: kredit.borderCard),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 14, color: kredit.textTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Simulación aproximada con base en los datos registrados. '
              'Consulta con tu entidad financiera para información oficial.',
              style: TextStyle(
                fontSize: AppTextSize.caption,
                fontStyle: FontStyle.italic,
                color: kredit.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ── Botón guardar escenario ───────────────────────────────────────────────────

class _SaveScenarioButton extends StatefulWidget {
  final Future<void> Function(String nombre) onSave;
  const _SaveScenarioButton({required this.onSave});

  @override
  State<_SaveScenarioButton> createState() => _SaveScenarioButtonState();
}

class _SaveScenarioButtonState extends State<_SaveScenarioButton> {
  bool _saving = false;

  Future<void> _tap() async {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    final ctrl = TextEditingController();
    final nombre = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kredit.bgCard,
        title: Text('Guardar escenario', style: TextStyle(color: kredit.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nombre del escenario',
            hintStyle: TextStyle(color: kredit.textTertiary),
          ),
          style: TextStyle(color: kredit.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final t = ctrl.text.trim();
              if (t.isNotEmpty) Navigator.pop(ctx, t);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (nombre == null || !mounted) return;
    setState(() => _saving = true);
    await widget.onSave(nombre);
    if (mounted) setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escenario guardado')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _saving ? null : _tap,
      icon: _saving
          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.bookmark_add_outlined, size: 16),
      label: Text(_saving ? 'Guardando…' : 'Guardar escenario'),
    );
  }
}
