import 'dart:math' as math;

import '../data/models/credit.dart';
import 'interest_rate.dart';

enum AttackStrategy { minimums, snowball, avalanche }

class MonthlySnapshot {
  final DateTime month;
  final double totalDebt;
  final double totalPayment;
  final String? attackedCreditName; // nombre del crédito que recibió el extra

  const MonthlySnapshot({
    required this.month,
    required this.totalDebt,
    required this.totalPayment,
    this.attackedCreditName,
  });
}

class AttackPlanResult {
  final List<MonthlySnapshot> months;
  final DateTime freedomDate;
  final double totalInterest;
  final double totalPaid;
  final double savingsVsMinimums; // positivo = ahorro; 0 para minimums

  const AttackPlanResult({
    required this.months,
    required this.freedomDate,
    required this.totalInterest,
    required this.totalPaid,
    required this.savingsVsMinimums,
  });
}

// Internal mutable state for each credit during the simulation.
class _SimCredit {
  final String id;
  final String name;
  double balance;
  final double monthlyRate; // effective monthly rate as fraction
  final double minimumPayment;

  _SimCredit({
    required this.id,
    required this.name,
    required this.balance,
    required this.monthlyRate,
    required this.minimumPayment,
  });
}

double _effectiveMonthlyRate(double rate, String? rateType) {
  if (rate == 0) return 0;
  final daily = dailyRateFrom(rate, rateType);
  return math.pow(1 + daily, 30).toDouble() - 1;
}

List<_SimCredit> _buildSimCredits(List<Credit> credits) {
  final result = <_SimCredit>[];
  for (final c in credits) {
    if (c is LoanCredit) {
      final unpaid = c.installments.where((i) => !i.paid).toList();
      if (unpaid.isEmpty) continue;
      final balance =
          unpaid.fold<double>(0, (s, i) => s + i.principal + i.interest);
      if (balance <= 0) continue;
      final monthlyRate =
          _effectiveMonthlyRate(c.interestRate, c.interestRateType);
      // Minimum payment = next installment amount
      final minPayment = unpaid.first.amount;
      result.add(_SimCredit(
        id: c.id,
        name: c.name,
        balance: balance,
        monthlyRate: monthlyRate,
        minimumPayment: minPayment,
      ));
    } else if (c is CardCredit) {
      if (c.currentBalance <= 0) continue;
      final monthlyRate =
          _effectiveMonthlyRate(c.interestRate, c.interestRateType);
      // Minimum = 10% of balance (Colombian standard for credit cards)
      final minPayment = c.currentBalance * 0.10;
      result.add(_SimCredit(
        id: c.id,
        name: c.name,
        balance: c.currentBalance,
        monthlyRate: monthlyRate,
        minimumPayment: minPayment,
      ));
    }
  }
  return result;
}

AttackPlanResult simulateAttackPlan(
  List<Credit> credits,
  AttackStrategy strategy, {
  double extraMonthlyPayment = 0,
  int maxMonths = 360,
  AttackPlanResult? minimumsResult, // provided to compute savings
}) {
  final simCredits = _buildSimCredits(credits);
  if (simCredits.isEmpty) {
    final now = DateTime.now();
    return AttackPlanResult(
      months: [],
      freedomDate: now,
      totalInterest: 0,
      totalPaid: 0,
      savingsVsMinimums: 0,
    );
  }

  final snapshots = <MonthlySnapshot>[];
  double totalInterest = 0;
  double totalPaid = 0;
  double rollingExtra = extraMonthlyPayment;

  DateTime currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

  for (int m = 0; m < maxMonths; m++) {
    final active = simCredits.where((c) => c.balance > 0).toList();
    if (active.isEmpty) break;

    // Apply monthly interest to all active credits
    for (final c in active) {
      final interest = c.balance * c.monthlyRate;
      c.balance += interest;
      totalInterest += interest;
    }

    // Sort active for prioritization
    _SimCredit? target;
    if (strategy == AttackStrategy.avalanche) {
      // Highest interest rate first
      final sorted = active.toList()
        ..sort((a, b) => b.monthlyRate.compareTo(a.monthlyRate));
      target = sorted.first;
    } else if (strategy == AttackStrategy.snowball) {
      // Lowest balance first
      final sorted = active.toList()
        ..sort((a, b) => a.balance.compareTo(b.balance));
      target = sorted.first;
    }
    // minimums: no target — no extra applied

    double monthTotal = 0;

    // Pay minimums on all active credits
    for (final c in active) {
      final pay = math.min(c.balance, c.minimumPayment);
      c.balance = math.max(0, c.balance - pay);
      monthTotal += pay;
      totalPaid += pay;
    }

    // Apply extra to target credit (not minimums-only strategy)
    String? attackedName;
    if (target != null && target.balance > 0) {
      final extra = math.min(rollingExtra, target.balance);
      target.balance = math.max(0, target.balance - extra);
      monthTotal += extra;
      totalPaid += extra;
      attackedName = target.name;
    }

    // Snowball effect: when a credit is fully paid, its minimum joins the extra
    for (final c in simCredits) {
      if (c.balance <= 0.01 && c.minimumPayment > 0) {
        // Was just paid off — add its minimum to rolling extra (once)
        if (!_paidOff.contains(c.id)) {
          _paidOff.add(c.id);
          rollingExtra += c.minimumPayment;
          c.balance = 0;
        }
      }
    }

    final totalDebt =
        simCredits.fold<double>(0, (s, c) => s + math.max(0, c.balance));

    snapshots.add(MonthlySnapshot(
      month: currentMonth,
      totalDebt: totalDebt,
      totalPayment: monthTotal,
      attackedCreditName: attackedName,
    ));

    currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);

    if (totalDebt <= 0.01) break;
  }

  final freedomDate = snapshots.isNotEmpty
      ? snapshots.last.month
      : DateTime.now();

  final savings = minimumsResult != null
      ? (minimumsResult.totalPaid - totalPaid)
      : 0.0;

  return AttackPlanResult(
    months: snapshots,
    freedomDate: freedomDate,
    totalInterest: totalInterest,
    totalPaid: totalPaid,
    savingsVsMinimums: savings,
  );
}

// Tracks which credits have already had their minimum rolled into the extra.
// Reset before each simulation run.
final Set<String> _paidOff = {};

/// Run all three strategies and return their results with savings computed.
Map<AttackStrategy, AttackPlanResult> simulateAllStrategies(
  List<Credit> credits, {
  double extraMonthlyPayment = 0,
}) {
  _paidOff.clear();
  final minimums = simulateAttackPlan(credits, AttackStrategy.minimums,
      extraMonthlyPayment: 0);

  _paidOff.clear();
  final snowball = simulateAttackPlan(
    credits,
    AttackStrategy.snowball,
    extraMonthlyPayment: extraMonthlyPayment,
    minimumsResult: minimums,
  );

  _paidOff.clear();
  final avalanche = simulateAttackPlan(
    credits,
    AttackStrategy.avalanche,
    extraMonthlyPayment: extraMonthlyPayment,
    minimumsResult: minimums,
  );

  return {
    AttackStrategy.minimums: minimums,
    AttackStrategy.snowball: snowball,
    AttackStrategy.avalanche: avalanche,
  };
}
