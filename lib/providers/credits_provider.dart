import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../data/models/credit.dart';
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
    for (final c in credits) {
      if (c is CardCredit) {
        final before = c.currentBalance;
        final beforeMovements = c.movements.length;
        accrueCardCredit(c);
        if (c.currentBalance != before || c.movements.length != beforeMovements) {
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
