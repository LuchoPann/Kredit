/// A manual extra payment ("abono extra") registered against a loan/cupo
/// credit, reducing debt outside the normal fixed-installment schedule.
/// Mirrors the UX idea (not the code) of MyExpenses' manual transaction
/// entry — see lib/domain/loan_calculator.dart#applyLoanAbono for the logic
/// that produces one of these.
library;

import 'installment.dart';

class LoanAbono {
  /// "YYYY-MM-DD"
  final String date;

  /// Amount actually applied to the loan. Never exceeds the loan's total
  /// pending balance at the time the abono was registered — if the
  /// requested amount ([requestedAmount]) was larger, it was capped here so
  /// the loan settles at exactly $0 instead of silently discarding the
  /// surplus (see applyLoanAbono in loan_calculator.dart).
  final double amount;

  final String note;

  /// How many full installments this abono was able to advance/pay off.
  /// Informational only — not recalculated after the fact.
  final int installmentsSkipped;

  /// The amount the user originally asked to apply, before any capping to
  /// the loan's outstanding balance. Equal to [amount] unless the abono
  /// fully settled the loan with money left over. Defaults to [amount] for
  /// abonos that predate this field (no cap ever happened for them).
  final double requestedAmount;

  /// The loan's `quotaAmount` immediately before this abono was applied —
  /// only set for the reamortization path (not the "capped/settled the
  /// whole loan" path, where the quota is irrelevant since every remaining
  /// installment was marked paid). `null` for abonos that predate this
  /// field, or for the settle-the-whole-loan case.
  ///
  /// [AbonoStrategy.reducirCuota] always changes `loan.quotaAmount` to a
  /// lower value; [AbonoStrategy.reducirPlazo] normally leaves it untouched
  /// but may internally fall back to `reducirCuota` (see
  /// `applyLoanAbono`'s doc comment), so this is recorded unconditionally
  /// whenever a reamortization happens, to be safe.
  final double? previousQuotaAmount;

  /// Snapshot of every unpaid installment exactly as it was immediately
  /// before this abono reamortized (and, for [AbonoStrategy.reducirPlazo],
  /// possibly dropped) them — lets [reverseLoanAbono] restore the schedule
  /// precisely instead of only approximating it. `null` for abonos that
  /// predate this field, or for the settle-the-whole-loan case (where
  /// [reverseLoanAbono] already has an exact, simpler undo).
  final List<Installment>? previousInstallmentsSnapshot;

  const LoanAbono({
    required this.date,
    required this.amount,
    this.note = '',
    this.installmentsSkipped = 0,
    double? requestedAmount,
    this.previousQuotaAmount,
    this.previousInstallmentsSnapshot,
  }) : requestedAmount = requestedAmount ?? amount;

  /// True if the requested amount exceeded the loan's pending balance and
  /// had to be capped — i.e. the loan was fully settled by this abono with
  /// money left over.
  bool get wasCapped => requestedAmount > amount;

  Map<String, dynamic> toJson() => {
        'date': date,
        'amount': amount,
        'note': note,
        'installmentsSkipped': installmentsSkipped,
        'requestedAmount': requestedAmount,
        'previousQuotaAmount': previousQuotaAmount,
        'previousInstallmentsSnapshot':
            previousInstallmentsSnapshot?.map((i) => i.toJson()).toList(),
      };

  factory LoanAbono.fromJson(Map<String, dynamic> json) => LoanAbono(
        date: json['date'] as String,
        amount: (json['amount'] as num).toDouble(),
        note: json['note'] as String? ?? '',
        installmentsSkipped: (json['installmentsSkipped'] as num?)?.toInt() ?? 0,
        requestedAmount: (json['requestedAmount'] as num?)?.toDouble(),
        previousQuotaAmount: (json['previousQuotaAmount'] as num?)?.toDouble(),
        previousInstallmentsSnapshot: (json['previousInstallmentsSnapshot']
                as List<dynamic>?)
            ?.map((e) => Installment.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
