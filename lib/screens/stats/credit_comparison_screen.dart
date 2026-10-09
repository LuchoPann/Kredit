import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/credit.dart';
import '../../domain/card_calculator.dart';
import '../../domain/credit_calculator.dart';
import '../../domain/date_utils.dart';
import '../../domain/interest_rate.dart';
import '../../providers/credits_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/credit_display_utils.dart';

class CreditComparisonScreen extends ConsumerStatefulWidget {
  const CreditComparisonScreen({super.key});

  @override
  ConsumerState<CreditComparisonScreen> createState() =>
      _CreditComparisonScreenState();
}

class _CreditComparisonScreenState
    extends ConsumerState<CreditComparisonScreen> {
  Credit? _creditA;
  Credit? _creditB;

  @override
  Widget build(BuildContext context) {
    final credits = ref.watch(creditsProvider).value ?? [];
    final active = credits.where((c) => creditHasUnpaid(c)).toList();
    final kredit = Theme.of(context).extension<AppThemeColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Comparar créditos')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.card),
        children: [
          _PickerRow(
            label: 'Crédito A',
            credits: active,
            selected: _creditA,
            excluded: _creditB,
            accentColor: kredit.success,
            onChanged: (c) => setState(() => _creditA = c),
          ),
          const SizedBox(height: 12),
          _PickerRow(
            label: 'Crédito B',
            credits: active,
            selected: _creditB,
            excluded: _creditA,
            accentColor: Theme.of(context).colorScheme.primary,
            onChanged: (c) => setState(() => _creditB = c),
          ),
          if (_creditA != null && _creditB != null) ...[
            const SizedBox(height: 24),
            _VerdictCard(creditA: _creditA!, creditB: _creditB!),
            const SizedBox(height: 16),
            _ComparisonTable(creditA: _creditA!, creditB: _creditB!),
          ] else ...[
            const SizedBox(height: 48),
            Center(
              child: Text(
                'Selecciona dos créditos para comparar',
                style: TextStyle(
                  color: kredit.textTertiary,
                  fontSize: AppTextSize.body,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Metrics helpers ──────────────────────────────────────────────────────────

double _monthlyRate(Credit c) {
  if (c is LoanCredit) {
    return periodicRateFrom(c.interestRate, c.interestRateType, 'monthly');
  }
  if (c is CardCredit) {
    return periodicRateFrom(c.interestRate, c.interestRateType, 'monthly');
  }
  return 0;
}

double _remainingDebt(Credit c) => getCreditRemainingBalance(c);

double _totalRemainingInterest(Credit c) {
  if (c is LoanCredit) {
    return c.installments
        .where((i) => !i.paid)
        .fold(0.0, (s, i) => s + i.interest);
  }
  if (c is CardCredit) {
    final r = _monthlyRate(c);
    if (r <= 0 || c.currentBalance <= 0) return 0;
    // Estimate: assume minimum 10% payment each month
    final minPayPct = 0.10;
    double bal = c.currentBalance;
    double totalInterest = 0;
    for (int i = 0; i < 360 && bal > 0; i++) {
      final interest = bal * r;
      totalInterest += interest;
      final payment = (bal * minPayPct).clamp(10000, double.infinity);
      bal = bal + interest - payment;
      if (bal < 1000) bal = 0;
    }
    return totalInterest;
  }
  return 0;
}

int _estimatedMonthsRemaining(Credit c) {
  if (c is LoanCredit) {
    return c.installments.where((i) => !i.paid).length;
  }
  if (c is CardCredit) {
    final r = _monthlyRate(c);
    if (r <= 0 || c.currentBalance <= 0) return 0;
    double bal = c.currentBalance;
    int months = 0;
    for (; months < 360 && bal > 0; months++) {
      final interest = bal * r;
      final payment = (bal * 0.10).clamp(10000, double.infinity);
      bal = bal + interest - payment;
      if (bal < 1000) bal = 0;
    }
    return months;
  }
  return 0;
}

double _minimumPayment(Credit c) {
  if (c is LoanCredit) {
    final next = c.installments.firstWhere((i) => !i.paid,
        orElse: () => c.installments.last);
    return next.amount;
  }
  if (c is CardCredit) {
    return (c.currentBalance * 0.10).clamp(10000, double.infinity);
  }
  return 0;
}

String? _nextDueDate(Credit c) {
  if (c is LoanCredit) {
    final unpaid = c.installments.where((i) => !i.paid).toList();
    if (unpaid.isEmpty) return null;
    return unpaid.first.dueDate;
  }
  if (c is CardCredit) {
    final dates = getCardCycleDates(c);
    return toDateStr(dates.dueDate);
  }
  return null;
}

// ── Verdict ──────────────────────────────────────────────────────────────────

class _VerdictCard extends StatelessWidget {
  final Credit creditA;
  final Credit creditB;

  const _VerdictCard({required this.creditA, required this.creditB});

  ({Credit priority, String reason}) _computeVerdict() {
    final rateA = _monthlyRate(creditA);
    final rateB = _monthlyRate(creditB);
    final debtA = _remainingDebt(creditA);
    final debtB = _remainingDebt(creditB);
    final dueA = _nextDueDate(creditA);
    final dueB = _nextDueDate(creditB);

    // 1. Tasa significativamente mayor
    if ((rateA - rateB).abs() > 0.005) {
      if (rateA > rateB) {
        return (
          priority: creditA,
          reason:
              'Tiene la tasa más alta (${(rateA * 100).toStringAsFixed(2)}% vs '
                  '${(rateB * 100).toStringAsFixed(2)}% mensual). '
                  'Cada mes que esperas, este crédito genera más intereses.',
        );
      } else {
        return (
          priority: creditB,
          reason:
              'Tiene la tasa más alta (${(rateB * 100).toStringAsFixed(2)}% vs '
                  '${(rateA * 100).toStringAsFixed(2)}% mensual). '
                  'Cada mes que esperas, este crédito genera más intereses.',
        );
      }
    }

    // 2. Tasas similares — elegir el que vence antes
    if (dueA != null && dueB != null) {
      final dateA = parseDateStr(dueA);
      final dateB = parseDateStr(dueB);
      if (dateA.isBefore(dateB)) {
        return (
          priority: creditA,
          reason: 'Vence antes (${formatDate(dueA)}). '
              'Pagarlo primero evita mora y libera flujo.',
        );
      } else if (dateB.isBefore(dateA)) {
        return (
          priority: creditB,
          reason: 'Vence antes (${formatDate(dueB)}). '
              'Pagarlo primero evita mora y libera flujo.',
        );
      }
    }

    // 3. Tasas iguales y misma fecha — menor deuda (victoria psicológica más rápida)
    if (debtA < debtB) {
      return (
        priority: creditA,
        reason: 'Deuda más pequeña (${formatCOP(debtA)} vs ${formatCOP(debtB)}). '
            'Tasas similares — pagarlo primero libera flujo de caja antes.',
      );
    } else {
      return (
        priority: creditB,
        reason: 'Deuda más pequeña (${formatCOP(debtB)} vs ${formatCOP(debtA)}). '
            'Tasas similares — pagarlo primero libera flujo de caja antes.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    final verdict = _computeVerdict();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kredit.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: kredit.success.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: kredit.success, size: 18),
              const SizedBox(width: 6),
              Text(
                'Paga primero: ${verdict.priority.name}',
                style: TextStyle(
                  color: kredit.success,
                  fontWeight: FontWeight.w700,
                  fontSize: AppTextSize.heading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            verdict.reason,
            style: TextStyle(
              color: kredit.textSecondary,
              fontSize: AppTextSize.body,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Comparison table ──────────────────────────────────────────────────────────

class _ComparisonTable extends StatelessWidget {
  final Credit creditA;
  final Credit creditB;

  const _ComparisonTable({required this.creditA, required this.creditB});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;

    final rows = [
      _RowData(
        label: 'Deuda restante',
        valueA: formatCOP(_remainingDebt(creditA)),
        valueB: formatCOP(_remainingDebt(creditB)),
        lowerIsBetter: true,
        numA: _remainingDebt(creditA),
        numB: _remainingDebt(creditB),
      ),
      _RowData(
        label: 'Tasa mensual',
        valueA: '${(_monthlyRate(creditA) * 100).toStringAsFixed(2)}%',
        valueB: '${(_monthlyRate(creditB) * 100).toStringAsFixed(2)}%',
        lowerIsBetter: true,
        numA: _monthlyRate(creditA),
        numB: _monthlyRate(creditB),
      ),
      _RowData(
        label: 'Próximo vencimiento',
        valueA: _nextDueDate(creditA) != null
            ? formatDate(_nextDueDate(creditA)!)
            : '—',
        valueB: _nextDueDate(creditB) != null
            ? formatDate(_nextDueDate(creditB)!)
            : '—',
        lowerIsBetter: true,
        numA: _nextDueDate(creditA) != null
            ? parseDateStr(_nextDueDate(creditA)!).millisecondsSinceEpoch.toDouble()
            : double.infinity,
        numB: _nextDueDate(creditB) != null
            ? parseDateStr(_nextDueDate(creditB)!).millisecondsSinceEpoch.toDouble()
            : double.infinity,
      ),
      _RowData(
        label: 'Pago mínimo',
        valueA: formatCOP(_minimumPayment(creditA)),
        valueB: formatCOP(_minimumPayment(creditB)),
        lowerIsBetter: true,
        numA: _minimumPayment(creditA),
        numB: _minimumPayment(creditB),
      ),
      _RowData(
        label: 'Interés restante estimado',
        valueA: formatCOP(_totalRemainingInterest(creditA)),
        valueB: formatCOP(_totalRemainingInterest(creditB)),
        lowerIsBetter: true,
        numA: _totalRemainingInterest(creditA),
        numB: _totalRemainingInterest(creditB),
      ),
      _RowData(
        label: 'Meses restantes estimados',
        valueA: '${_estimatedMonthsRemaining(creditA)}',
        valueB: '${_estimatedMonthsRemaining(creditB)}',
        lowerIsBetter: true,
        numA: _estimatedMonthsRemaining(creditA).toDouble(),
        numB: _estimatedMonthsRemaining(creditB).toDouble(),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: kredit.borderCard),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: kredit.borderCard.withValues(alpha: 0.5),
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.card)),
            ),
            child: Row(
              children: [
                const Expanded(flex: 2, child: SizedBox()),
                Expanded(
                  flex: 3,
                  child: Text(
                    creditA.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kredit.success,
                      fontWeight: FontWeight.w700,
                      fontSize: AppTextSize.body,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    creditB.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: AppTextSize.body,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Rows
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(height: 1, color: kredit.borderCard),
            _TableRow(data: rows[i]),
          ],
        ],
      ),
    );
  }
}

class _RowData {
  final String label;
  final String valueA;
  final String valueB;
  final bool lowerIsBetter;
  final double numA;
  final double numB;

  const _RowData({
    required this.label,
    required this.valueA,
    required this.valueB,
    required this.lowerIsBetter,
    required this.numA,
    required this.numB,
  });

  bool get aWins => lowerIsBetter ? numA < numB : numA > numB;
  bool get bWins => lowerIsBetter ? numB < numA : numB > numA;
  bool get tied => (numA - numB).abs() < 0.001;
}

class _TableRow extends StatelessWidget {
  final _RowData data;

  const _TableRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    final winColor = kredit.success;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              data.label,
              style: TextStyle(
                color: kredit.textTertiary,
                fontSize: AppTextSize.caption,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              data.valueA,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: data.tied
                    ? kredit.textSecondary
                    : data.aWins
                        ? winColor
                        : kredit.textSecondary,
                fontWeight:
                    data.aWins && !data.tied ? FontWeight.w700 : FontWeight.w400,
                fontSize: AppTextSize.body,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              data.valueB,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: data.tied
                    ? kredit.textSecondary
                    : data.bWins
                        ? winColor
                        : kredit.textSecondary,
                fontWeight:
                    data.bWins && !data.tied ? FontWeight.w700 : FontWeight.w400,
                fontSize: AppTextSize.body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Picker ────────────────────────────────────────────────────────────────────

class _PickerRow extends StatelessWidget {
  final String label;
  final List<Credit> credits;
  final Credit? selected;
  final Credit? excluded;
  final Color accentColor;
  final ValueChanged<Credit?> onChanged;

  const _PickerRow({
    required this.label,
    required this.credits,
    required this.selected,
    required this.excluded,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    final available = credits.where((c) => c != excluded).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(
            color: selected != null
                ? accentColor.withValues(alpha: 0.4)
                : kredit.borderCard),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Credit>(
          value: selected,
          hint: Text(
            label,
            style: TextStyle(color: kredit.textTertiary),
          ),
          isExpanded: true,
          dropdownColor: Theme.of(context).scaffoldBackgroundColor,
          items: available
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(
                      c.name,
                      style: TextStyle(color: kredit.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
