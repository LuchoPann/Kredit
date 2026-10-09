import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/credit.dart';
import '../domain/bank_detector.dart';
import '../domain/card_calculator.dart';
import '../domain/credit_calculator.dart';
import '../domain/date_utils.dart';
import '../domain/recommendations.dart';
import '../utils/credit_display_utils.dart';
import 'credits_provider.dart';

const _monthsEs = [
  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
];

/// Bucket key for a calendar month. Moved from stats_screen.dart to be
/// shareable between statsDataProvider and the chart widgets without
/// requiring the screen to own the computation.
class MonthKey implements Comparable<MonthKey> {
  final int year;
  final int month;
  const MonthKey(this.year, this.month);

  @override
  bool operator ==(Object other) =>
      other is MonthKey && other.year == year && other.month == month;

  @override
  int get hashCode => year * 12 + month;

  @override
  int compareTo(MonthKey other) => hashCode.compareTo(other.hashCode);

  String get label => '${_monthsEs[month - 1]}\n$year';
}

/// A lender's share of the total pending debt.
class LenderSlice {
  final String label;
  final double amount;
  final Color color;
  const LenderSlice({
    required this.label,
    required this.amount,
    required this.color,
  });
}

/// A loan credit's projected payoff date.
class PayoffEntry {
  final String name;
  final DateTime endDate;
  final int monthsFromNow;
  final int totalInstallments;
  final int paidInstallments;
  final double totalAmount;
  final double remainingAmount;

  const PayoffEntry({
    required this.name,
    required this.endDate,
    required this.monthsFromNow,
    required this.totalInstallments,
    required this.paidInstallments,
    required this.totalAmount,
    required this.remainingAmount,
  });

  double get paidFraction =>
      totalInstallments > 0 ? paidInstallments / totalInstallments : 0.0;
}

/// All derived stats for StatsScreen, computed once per [creditsProvider]
/// change instead of re-running every build() call.
class StatsData {
  final List<FinancialRecommendation> risks;
  final Map<MonthKey, double> monthlyProjection;
  final List<LenderSlice> distribution;
  final double totalOwed;
  final double totalLimit;
  final int activeCount;
  final double totalPaidHistorico;
  final double progressPct;
  final int abonoCount;
  final double abonoTotal;
  final int installmentsAdvanced;
  final List<PayoffEntry> payoffProjections;
  final String? monthlyDebtInsight;
  final String? lenderDistributionInsight;
  final String? bestPrepayment;

  const StatsData({
    required this.risks,
    required this.monthlyProjection,
    required this.distribution,
    required this.totalOwed,
    required this.totalLimit,
    required this.activeCount,
    required this.totalPaidHistorico,
    required this.progressPct,
    required this.abonoCount,
    required this.abonoTotal,
    required this.installmentsAdvanced,
    required this.payoffProjections,
    required this.monthlyDebtInsight,
    required this.lenderDistributionInsight,
    required this.bestPrepayment,
  });
}

/// Computed provider for StatsScreen. Returns null while credits are loading.
/// Riverpod caches the result and only recomputes when [creditsProvider] changes.
final statsDataProvider = Provider<StatsData?>((ref) {
  final credits = ref.watch(creditsProvider).value;
  if (credits == null || credits.isEmpty) return null;

  final risks = buildRiskRecommendations(credits);
  final monthlyProjection = _computeMonthlyDebt(credits);
  final distribution = _computeDistributionByLender(credits);
  final payoffProjections = _computePayoffProjections(credits);

  double totalOwed = 0;
  double totalLimit = 0;
  int activeCount = 0;
  double totalPaidHistorico = 0;

  for (final c in credits) {
    if (c is LoanCredit) {
      final unpaid = c.installments
          .where((i) => !i.paid)
          .fold(0.0, (sum, i) => sum + i.amount);
      totalOwed += unpaid;
      if (unpaid > 0) activeCount++;
      totalPaidHistorico += c.installments
          .where((i) => i.paid)
          .fold(0.0, (s, i) => s + i.amount);
    } else if (c is CardCredit) {
      totalOwed += c.currentBalance;
      totalLimit += c.creditLimit;
      if (c.currentBalance > 0) activeCount++;
      totalPaidHistorico += c.movements
          .where((m) => m.type == 'payment')
          .fold(0.0, (s, m) => s + m.amount);
    }
  }

  int abonoCount = 0;
  double abonoTotal = 0;
  int installmentsAdvanced = 0;
  for (final c in credits) {
    if (c is! LoanCredit) continue;
    for (final abono in c.abonos) {
      abonoCount++;
      abonoTotal += abono.amount;
      installmentsAdvanced += abono.installmentsSkipped;
    }
  }

  return StatsData(
    risks: risks,
    monthlyProjection: monthlyProjection,
    distribution: distribution,
    totalOwed: totalOwed,
    totalLimit: totalLimit,
    activeCount: activeCount,
    totalPaidHistorico: totalPaidHistorico,
    progressPct: getLoansProgressPercent(credits),
    abonoCount: abonoCount,
    abonoTotal: abonoTotal,
    installmentsAdvanced: installmentsAdvanced,
    payoffProjections: payoffProjections,
    monthlyDebtInsight: _computeMonthlyDebtInsight(monthlyProjection),
    lenderDistributionInsight: _computeLenderDistributionInsight(distribution),
    bestPrepayment: buildBestPrepaymentRecommendation(credits)?.description,
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// Private computation functions (moved from stats_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────

/// Sums projected debt per month for the next [monthsAhead] months: loan
/// installments (unpaid, grouped by dueDate month) plus each card's current
/// balance placed in the month of its next due date.
Map<MonthKey, double> _computeMonthlyDebt(
  List<Credit> credits, {
  int monthsAhead = 6,
}) {
  final now = DateTime.now();
  final start = MonthKey(now.year, now.month);
  final months = <MonthKey>[];
  for (var i = 0; i < monthsAhead; i++) {
    final totalMonth0 = (start.month - 1) + i;
    final y = start.year + totalMonth0 ~/ 12;
    final m = totalMonth0 % 12 + 1;
    months.add(MonthKey(y, m));
  }
  final buckets = {for (final m in months) m: 0.0};

  for (final credit in credits) {
    if (credit is LoanCredit) {
      for (final inst in credit.installments) {
        if (inst.paid) continue;
        final due = parseDateStr(inst.dueDate);
        final key = MonthKey(due.year, due.month);
        if (buckets.containsKey(key)) {
          buckets[key] = buckets[key]! + inst.amount;
        }
      }
    } else if (credit is CardCredit) {
      if (credit.currentBalance <= 0) continue;
      final dates = getCardCycleDates(credit);
      final key = MonthKey(dates.dueDate.year, dates.dueDate.month);
      if (buckets.containsKey(key)) {
        buckets[key] = buckets[key]! + credit.currentBalance;
      }
    }
  }

  return {for (final m in months) m: buckets[m] ?? 0.0};
}

List<LenderSlice> _computeDistributionByLender(List<Credit> credits) {
  final byLender = <String, double>{};
  final colorByLender = <String, Color>{};

  for (final credit in credits) {
    final balance = getCreditRemainingBalance(credit);
    if (balance <= 0) continue;
    final bank = detectBank(
      lender: credit.lender,
      card: credit is LoanCredit ? credit.card : null,
    );
    final key = bank.shortLabel.isEmpty ? credit.lender : bank.shortLabel;
    byLender[key] = (byLender[key] ?? 0) + balance;
    colorByLender.putIfAbsent(key, () {
      final hex = bank.accentColor.replaceFirst('#', '');
      final full = hex.length == 6 ? 'FF$hex' : hex;
      return Color(int.parse(full, radix: 16));
    });
  }

  final entries = byLender.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return [
    for (final e in entries)
      LenderSlice(label: e.key, amount: e.value, color: colorByLender[e.key]!),
  ];
}

List<PayoffEntry> _computePayoffProjections(List<Credit> credits) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final entries = <PayoffEntry>[];

  for (final credit in credits) {
    if (credit is! LoanCredit) continue;
    final all = credit.installments;
    if (all.isEmpty) continue;
    final unpaid = all.where((i) => !i.paid).toList();
    if (unpaid.isEmpty) continue;
    final lastDue = unpaid
        .map((i) => parseDateStr(i.dueDate))
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final months = ((lastDue.difference(today).inDays) / 30).ceil();
    final totalAmt = all.fold(0.0, (s, i) => s + i.amount);
    final remainAmt = unpaid.fold(0.0, (s, i) => s + i.amount);
    entries.add(
      PayoffEntry(
        name: credit.name,
        endDate: lastDue,
        monthsFromNow: months < 0 ? 0 : months,
        totalInstallments: all.length,
        paidInstallments: all.length - unpaid.length,
        totalAmount: totalAmt,
        remainingAmount: remainAmt,
      ),
    );
  }

  entries.sort((a, b) => a.endDate.compareTo(b.endDate));
  return entries;
}

/// Fase 7 / Tarea 3 del roadmap ("Estadísticas explicativas"): una línea de
/// texto en español plano bajo cada gráfica que responde "¿qué significa
/// esto para mí?". Uses the already-computed [monthlyProjection] instead of
/// re-calling the projection function.
String? _computeMonthlyDebtInsight(Map<MonthKey, double> data) {
  if (data.isEmpty) return null;
  final entries = data.entries.toList();
  final total = entries.fold<double>(0, (s, e) => s + e.value);
  if (total <= 0) return null;
  final peak = entries.reduce((a, b) => b.value > a.value ? b : a);
  final monthLabel = peak.key.label.replaceAll('\n', ' ');
  final share = (peak.value / total * 100).round();
  return 'Tu mes más cargado es $monthLabel, con ${formatCOP(peak.value)} '
      '($share% de lo proyectado en los próximos 6 meses).';
}

String? _computeLenderDistributionInsight(List<LenderSlice> slices) {
  if (slices.isEmpty) return null;
  final total = slices.fold<double>(0, (s, e) => s + e.amount);
  if (total <= 0) return null;
  final top = slices.first;
  final share = (top.amount / total * 100).round();
  if (slices.length == 1) {
    return 'Toda tu deuda pendiente está concentrada en ${top.label}.';
  }
  return 'El $share% de tu deuda pendiente está concentrada en ${top.label}.';
}
