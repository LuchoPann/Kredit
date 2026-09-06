import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../data/models/credit.dart';
import '../data/models/loan_abono.dart';
import '../domain/card_calculator.dart';
import '../domain/credit_calculator.dart';
import '../domain/date_utils.dart';
import '../domain/loan_calculator.dart';
import 'database_provider.dart';

/// True for the two seeded first-run demo credits (app.js ~L950/~L1177:
/// `credit.id === "demo-1" || credit.id === "demo-2"`), used to show the
/// "Ejemplo" badge on those cards.
bool isDemoCredit(String creditId) => creditId == 'demo-1' || creditId == 'demo-2';

/// Equivalent to app.js's global `state.credits` + loadState/saveState, but
/// reactive: any mutation persists to Drift and updates all listeners.
class CreditsNotifier extends AsyncNotifier<List<Credit>> {
  AppDatabase get _db => ref.read(databaseProvider);

  @override
  Future<List<Credit>> build() async {
    var credits = await _db.loadAllCredits();

    // First-run demo data (app.js loadState ~L48-86): if the user has no
    // credits at all yet, seed the two example credits so the app isn't
    // empty on first open. Seeding lives here (provider layer) rather than
    // in AppDatabase itself so AppDatabase's own tests keep starting from a
    // clean slate.
    if (credits.isEmpty) {
      for (final demo in _buildDemoCredits()) {
        await _db.upsertCredit(demo);
      }
      credits = await _db.loadAllCredits();
    }

    // accrueAllCards (app.js loadState ~L89): apply pending interest/fee
    // cycles for every card credit on load, persisting any that changed.
    //
    // Loan credits get an analogous always-run treatment: every load
    // recomputes their installment schedule with the real French
    // amortization engine (see recomputeLoanInstallments), persisting only
    // when the numbers actually changed. This is what migrates loans built
    // by the old linear-interest engine without any stored "migrated" flag
    // — see recomputeLoanInstallments's doc comment for why that's safe.
    for (final c in credits) {
      if (c is CardCredit) {
        final before = c.currentBalance;
        final beforeMovements = c.movements.length;
        accrueCardCredit(c);
        if (c.currentBalance != before || c.movements.length != beforeMovements) {
          await _db.upsertCredit(c);
        }
      } else if (c is LoanCredit) {
        final before = jsonEncode(c.installments.map((i) => i.toJson()).toList());
        c.installments = recomputeLoanInstallments(c);
        final after = jsonEncode(c.installments.map((i) => i.toJson()).toList());
        if (before != after) {
          await _db.upsertCredit(c);
        }
      }
    }
    return credits;
  }

  Future<void> _reload() async {
    state = AsyncData(await _db.loadAllCredits());
  }

  Future<void> addCredit(Credit credit) async {
    await _db.upsertCredit(credit);
    await _reload();
  }

  Future<void> updateCredit(Credit credit) async {
    await _db.upsertCredit(credit);
    await _reload();
  }

  Future<void> deleteCredit(String creditId) async {
    await _db.deleteCredit(creditId);
    await _reload();
  }

  Future<void> toggleInstallmentPaid(String creditId, int installmentNumber) async {
    final credits = state.value ?? [];
    final credit = credits.whereType<LoanCredit>().where((c) => c.id == creditId).firstOrNull;
    if (credit == null) return;
    final inst = credit.installments.firstWhere((i) => i.number == installmentNumber);
    applyInstallmentPayment(inst, !inst.paid);
    await _db.upsertCredit(credit);
    await _reload();
  }

  /// Registers that [installmentNumber] was actually paid for
  /// [actualAmount], which may differ from the app's calculated amount
  /// (bank rounding/fees/policies) — see registerInstallmentActualPayment.
  /// The difference is folded into the next unpaid installment's principal
  /// (estimate, same mechanism as an abono).
  Future<void> registerInstallmentPayment(
    String creditId,
    int installmentNumber,
    double actualAmount,
  ) async {
    final credits = state.value ?? [];
    final credit = credits.whereType<LoanCredit>().where((c) => c.id == creditId).firstOrNull;
    if (credit == null) return;
    final inst = credit.installments.firstWhere((i) => i.number == installmentNumber);
    registerInstallmentActualPayment(credit, inst, actualAmount);
    await _db.upsertCredit(credit);
    await _reload();
  }

  Future<void> markAllInstallmentsPaid(String creditId) async {
    final credits = state.value ?? [];
    final credit = credits.whereType<LoanCredit>().where((c) => c.id == creditId).firstOrNull;
    if (credit == null) return;
    markAllInstallments(credit);
    await _db.upsertCredit(credit);
    await _reload();
  }

  Future<void> registerMovement(String creditId, String type, double amount, String note) async {
    final credits = state.value ?? [];
    final credit = credits.whereType<CardCredit>().where((c) => c.id == creditId).firstOrNull;
    if (credit == null) return;
    registerCardMovement(credit, type, amount, note);
    await _db.upsertCredit(credit);
    await _reload();
  }

  /// Registers an "abono extra" on a loan credit, applying it against the
  /// unpaid schedule (see applyLoanAbono) and persisting both the updated
  /// installments and the new abono history entry. Returns the created
  /// [LoanAbono] so the caller can show a result summary.
  Future<LoanAbono> registerLoanAbono(String creditId, double amount, {String note = ''}) async {
    final credits = state.value ?? [];
    final credit = credits.whereType<LoanCredit>().where((c) => c.id == creditId).firstOrNull;
    if (credit == null) {
      throw ArgumentError('Crédito no encontrado: $creditId');
    }
    final abono = applyLoanAbono(credit, amount, note: note);
    credit.abonos.add(abono);
    await _db.upsertCredit(credit);
    await _reload();
    return abono;
  }

  /// Deletes a single card movement (charge/payment/interest/fee) and
  /// reverses its effect on the card's current balance, for correcting a
  /// mis-registered movement. [movementIndex] is the index into
  /// `credit.movements` (not the reversed/most-recent-first order some UIs
  /// display it in).
  Future<void> deleteMovement(String creditId, int movementIndex) async {
    final credits = state.value ?? [];
    final credit = credits.whereType<CardCredit>().where((c) => c.id == creditId).firstOrNull;
    if (credit == null) return;
    deleteCardMovement(credit, movementIndex);
    await _db.upsertCredit(credit);
    await _reload();
  }

  /// Deletes a registered "abono extra" from a loan credit, best-effort
  /// reversing its effect on the installment schedule (see
  /// [reverseLoanAbono]), for correcting a mis-registered abono.
  Future<void> deleteLoanAbono(String creditId, LoanAbono abono) async {
    final credits = state.value ?? [];
    final credit = credits.whereType<LoanCredit>().where((c) => c.id == creditId).firstOrNull;
    if (credit == null) return;
    reverseLoanAbono(credit, abono);
    credit.abonos.remove(abono);
    await _db.upsertCredit(credit);
    await _reload();
  }

  Future<void> replaceAll(List<Credit> newCredits) async {
    await _db.replaceAllCredits(newCredits);
    await _reload();
  }

  Future<void> clearAll() async {
    await _db.clearAllData();
    await _reload();
  }
}

/// Port of app.js's inline demo-data literal (loadState ~L48-86), built with
/// `buildLoanInstallments` + `applyInstallmentPayment` (both already handle
/// the principal/interest split and early-payment interest-waiving that
/// generateDemoInstallments (~L114-138) approximated with a flat `amount`).
/// The first 2 installments of each are marked paid, matching
/// `generateDemoInstallments(total, amount, frequency, startOffsetDays, 2)`.
List<Credit> _buildDemoCredits() {
  final carStart = toDateStr(DateTime.now().subtract(const Duration(days: 60)));
  final car = LoanCredit(
    id: 'demo-1',
    name: 'Préstamo de Coche',
    lender: 'Banco Santander',
    color: '#ffffff',
    location: 'Concesionario AutoMix',
    card: 'Cuenta Débito Santander',
    notes:
        'Débito automático los 5 de cada mes. Cuenta corriente terminada en 4321.',
    totalAmount: 12000,
    quotaAmount: 500,
    totalInstallments: 24,
    frequency: CreditFrequency.monthly,
    startDate: carStart,
    interestRate: 4.5,
    installments: buildLoanInstallments(
      totalAmount: 12000,
      totalInstallments: 24,
      quotaAmount: 500,
      frequency: CreditFrequency.monthly,
      startDate: carStart,
    ),
  );
  for (final inst in car.installments.take(2)) {
    applyInstallmentPayment(inst, true);
  }

  final laptopStart = toDateStr(DateTime.now().subtract(const Duration(days: 28)));
  final laptop = LoanCredit(
    id: 'demo-2',
    name: 'Compra de Laptop',
    lender: 'Tienda Tech',
    color: '#c084fc',
    location: 'Tienda Tech Outlet',
    card: 'Tarjeta Visa BBVA',
    notes: 'Pago quincenal manual por transferencia.',
    totalAmount: 1200,
    quotaAmount: 200,
    totalInstallments: 6,
    frequency: CreditFrequency.biweekly,
    startDate: laptopStart,
    interestRate: 0,
    installments: buildLoanInstallments(
      totalAmount: 1200,
      totalInstallments: 6,
      quotaAmount: 200,
      frequency: CreditFrequency.biweekly,
      startDate: laptopStart,
    ),
  );
  for (final inst in laptop.installments.take(2)) {
    applyInstallmentPayment(inst, true);
  }

  return [car, laptop];
}

final creditsProvider = AsyncNotifierProvider<CreditsNotifier, List<Credit>>(
  CreditsNotifier.new,
);

/// Derived: total pending debt across all credits (dashboard header).
final totalUnpaidProvider = Provider<double>((ref) {
  final credits = ref.watch(creditsProvider).value ?? [];
  return credits.fold(0.0, (sum, c) => sum + getCreditRemainingBalance(c));
});
