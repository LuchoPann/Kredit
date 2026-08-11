import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/credit.dart';
import '../domain/card_calculator.dart';
import '../domain/credit_calculator.dart';
import '../domain/date_utils.dart';

/// Shared display helpers for dashboard_screen.dart and
/// credits_list_screen.dart. Kept out of lib/domain (business-logic layer
/// owned by another agent) since these are purely UI-formatting concerns.

final _copFormat = NumberFormat.currency(
  locale: 'es_CO',
  symbol: '\$',
  decimalDigits: 0,
);

/// Formats an amount as Colombian pesos, e.g. "$1.234.567".
String formatCOP(double amount) => _copFormat.format(amount);

/// Parses a "#rrggbb" hex string (as stored in Credit.color or
/// BankInfo.accentColor) into a Color. Falls back to white.
Color parseHexColor(String? hex) {
  if (hex == null || hex.isEmpty) return Colors.white;
  var value = hex.replaceFirst('#', '');
  if (value.length == 6) value = 'FF$value';
  return Color(int.parse(value, radix: 16));
}

/// Next relevant due date for a credit: earliest unpaid installment for
/// loans, current cycle's payment due date for cards. Null if a loan has no
/// unpaid installments left.
DateTime? getNextDueDate(Credit credit) {
  if (credit is LoanCredit) {
    final unpaid = credit.installments.where((i) => !i.paid).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    if (unpaid.isEmpty) return null;
    return parseDateStr(unpaid.first.dueDate);
  }
  if (credit is CardCredit) {
    return getCardCycleDates(credit).dueDate;
  }
  return null;
}

/// Formats a due-date relative to today in Spanish, matching the tone of
/// getInstallmentStatus labels ("Hoy", "En Xd", "Vencido (Xd)").
String formatRelativeDate(DateTime date) {
  final dateStr = toDateStr(date);
  final days = getDaysDifference(dateStr);
  if (days == 0) return 'Hoy';
  if (days < 0) return 'Vencido hace ${days.abs()}d';
  if (days == 1) return 'Mañana';
  if (days <= 30) return 'En $days días';
  return formatDate(dateStr);
}

/// Percent paid, used for the dashboard progress ring. Per credit_calculator
/// notes, only loan/cupo credits factor into amortization progress (cards
/// are revolving balances, not amortization schedules).
double getLoansProgressPercent(List<Credit> credits) {
  final loans = credits.whereType<LoanCredit>().toList();
  if (loans.isEmpty) return 0;
  var totalQuota = 0.0;
  var totalPaid = 0.0;
  for (final l in loans) {
    for (final inst in l.installments) {
      totalQuota += inst.principal + inst.interest;
      if (inst.paid) totalPaid += inst.principal + inst.interest;
    }
  }
  if (totalQuota <= 0) return 0;
  return (totalPaid / totalQuota).clamp(0, 1) * 100;
}

/// Sublabel shown under a credit's name in list rows: next installment due
/// date for loans, payment due date for cards.
String creditSublabel(Credit credit) {
  final next = getNextDueDate(credit);
  if (credit is LoanCredit) {
    if (next == null) return 'Pagado en su totalidad';
    return 'Próxima cuota: ${formatDate(toDateStr(next))}';
  }
  if (credit is CardCredit) {
    if (next == null) return '';
    return 'Fecha límite: ${formatDate(toDateStr(next))}';
  }
  return '';
}

/// Label for the credit type badge ("Tarjeta" / "Préstamo").
String creditTypeLabel(Credit credit) => credit.isCard ? 'Tarjeta' : 'Préstamo';

/// Remaining-debt formatted string, thin wrapper for readability at call
/// sites.
String creditRemainingLabel(Credit credit) =>
    formatCOP(getCreditRemainingBalance(credit));

/// Sum of everything due within the next [withinDays] days (default 7),
/// across all credits: unpaid loan installments whose `dueDate` falls in the
/// window, plus card balances whose current cycle due date falls in the
/// window. Presentation-only aggregate for the dashboard "Por pagar" metric
/// — does not mutate or read anything outside lib/domain's public getters.
double getDueSoonTotal(List<Credit> credits, {int withinDays = 7}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final horizon = today.add(Duration(days: withinDays));
  var total = 0.0;
  for (final c in credits) {
    if (c is LoanCredit) {
      for (final inst in c.installments) {
        if (inst.paid) continue;
        final due = parseDateStr(inst.dueDate);
        if (!due.isAfter(horizon)) total += inst.amount;
      }
    } else if (c is CardCredit && c.currentBalance > 0) {
      final due = getCardCycleDates(c).dueDate;
      final dueDay = DateTime(due.year, due.month, due.day);
      if (!dueDay.isAfter(horizon)) total += c.currentBalance;
    }
  }
  return total;
}
