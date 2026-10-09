import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../data/models/credit.dart';
import '../domain/date_utils.dart';
import 'credits_provider.dart';
import 'database_provider.dart';

class DebtDataPoint {
  final DateTime date;
  final double projected;
  final double? real;

  const DebtDataPoint({required this.date, required this.projected, this.real});
}

final debtHistoryProvider =
    FutureProvider.family<List<DebtDataPoint>, int>((ref, months) async {
  final credits = ref.watch(creditsProvider).value ?? [];
  if (credits.isEmpty) return [];
  final db = ref.read(databaseProvider);
  return _buildHistory(credits, db, months);
});

Future<List<DebtDataPoint>> _buildHistory(
  List<Credit> credits,
  AppDatabase db,
  int months,
) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Collect all PagosRealizados keyed by creditId → list
  final Map<String, List<dynamic>> allPagos = {};
  for (final c in credits) {
    if (c is LoanCredit) {
      allPagos[c.id] = await db.loadPagosRealizados(c.id);
    }
  }

  final points = <DebtDataPoint>[];
  for (var i = months; i >= 0; i--) {
    final date = DateTime(now.year, now.month - i, 1);
    final monthEnd = DateTime(date.year, date.month + 1, 0); // last day

    double projected = 0;
    double real = 0;
    bool hasRealData = false;

    for (final credit in credits) {
      if (credit is LoanCredit) {
        // Projected: installments that are unpaid and due after this month-end
        // (i.e. remaining balance as of month-end)
        double creditProjected = 0;
        for (final inst in credit.installments) {
          final due = DateTime.tryParse(inst.dueDate);
          if (due == null) continue;
          final dueNorm = DateTime(due.year, due.month, due.day);
          if (!inst.paid && dueNorm.isAfter(monthEnd)) {
            creditProjected += inst.principal + inst.interest;
          }
        }
        projected += creditProjected;

        // Real: check if we have pago data for this period
        final pagos = allPagos[credit.id] ?? [];
        bool monthHasData = pagos.any((p) {
          try {
            final pd = parseDateStr(p.fecha);
            return pd.year == date.year && pd.month == date.month;
          } catch (_) {
            return false;
          }
        });
        if (monthHasData) {
          hasRealData = true;
          // Real remaining = total amount - sum of real payments up to month-end
          double totalRealPaid = 0;
          for (final p in pagos) {
            try {
              final pd = parseDateStr(p.fecha);
              final pdNorm = DateTime(pd.year, pd.month, pd.day);
              if (!pdNorm.isAfter(monthEnd)) totalRealPaid += p.monto;
            } catch (_) {}
          }
          real += (credit.totalAmount - totalRealPaid).clamp(0, credit.totalAmount);
        } else {
          real += creditProjected;
        }
      } else if (credit is CardCredit) {
        // Cards: only current balance (no historical data available)
        projected += credit.currentBalance;
        real += credit.currentBalance;
      }
    }

    points.add(DebtDataPoint(
      date: date,
      projected: projected,
      real: hasRealData ? real : null,
    ));
  }

  return points;
}
