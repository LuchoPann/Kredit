import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../data/models/commercial_quota.dart';
import '../data/models/card_movement.dart';
import '../data/models/credit.dart';
import '../data/models/loan_abono.dart';
import '../domain/card_calculator.dart';
import '../domain/credit_calculator.dart';
import '../domain/loan_calculator.dart';
import 'commercial_quotas_provider.dart';
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

    // Show data immediately — don't block the first frame with CPU-intensive
    // accrual and amortization recomputation. _accrueAndRecompute runs those
    // in the background, yielding to the event loop between each credit so
    // animations keep firing, and updates state only if anything changed.
    _accrueAndRecompute(credits);
    return credits;
  }

  // Fast field-by-field installment comparison — avoids the previous
  // jsonEncode × 2 pattern that serialized every installment to a string
  // twice per credit just to detect equality.
  static bool _installmentsEqual(
      List<dynamic> before, List<dynamic> after) {
    if (before.length != after.length) return false;
    for (var i = 0; i < before.length; i++) {
      final a = before[i], b = after[i];
      if (a.number != b.number ||
          a.principal != b.principal ||
          a.interest != b.interest ||
          a.paid != b.paid ||
          a.paymentDate != b.paymentDate ||
          a.interestWaived != b.interestWaived) { return false; }
    }
    return true;
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
  //
  // Runs after the first frame (called from build() without await) so the
  // UI thread is never blocked. Yields between each credit so animation
  // ticks fire throughout. Updates state only if something actually changed.
  Future<void> _accrueAndRecompute(List<Credit> credits) async {
    bool anyChanged = false;
    for (final c in credits) {
      // Yield to the event loop before processing each credit so that
      // animation callbacks (e.g. the circular indicator) can run between
      // credits and the UI never appears frozen.
      await Future<void>.delayed(Duration.zero);
      bool changed = false;
      if (c is CardCredit) {
        final before = c.currentBalance;
        final beforeMovements = c.movements.length;
        accrueCardCredit(c);
        changed = c.currentBalance != before || c.movements.length != beforeMovements;
      } else if (c is LoanCredit && !c.scheduleManuallyAdjusted) {
        // Skip the recompute once the loan's schedule has diverged from
        // what its base fields alone would reproduce — persisted via the
        // `scheduleManuallyAdjusted` flag, set by applyLoanAbono's
        // reamortization (see AbonoStrategy) and by
        // registerInstallmentActualPayment's principal adjustment (whenever
        // the real payment differed from the calculated one). Running the
        // recompute after either would silently discard that adjustment and
        // regenerate the original schedule from scratch on every app
        // launch — this flag is the actual persisted signal, not a
        // heuristic based on `abonos.isEmpty` or installment count (which
        // was tried first and found insufficient: it missed the
        // registerInstallmentActualPayment case entirely).
        final newInstallments = recomputeLoanInstallments(c);
        changed = !_installmentsEqual(c.installments, newInstallments);
        if (changed) { c.installments = newInstallments; }
      }
      if (changed) {
        await _db.upsertCredit(c);
        anyChanged = true;
      }
    }
    // Only trigger a re-render when data actually changed (card accrual or
    // loan schedule migration). Most launches with up-to-date data skip this.
    if (anyChanged) {
      // Guard against the provider being disposed while we were processing.
      try {
        state = AsyncData(await _db.loadAllCredits());
      } catch (_) {
        // Provider disposed; no-op.
      }
    }
  }

  /// A purchase can't stay marked "no sé la tasa" once a real rate is
  /// entered — this must never leave both signals visible at once.
  void _clearInterestUnknownIfRateKnown(Credit credit) {
    if (credit is LoanCredit && credit.interestRate > 0) {
      credit.interestUnknown = false;
    }
  }

  // Recarga completa desde DB — solo para operaciones que reemplazan o borran
  // datos que ya no existen en el estado en memoria (deleteCredit, replaceAll,
  // clearAll). Para mutaciones en memoria usa _notifyInPlace().
  Future<void> _reload() async {
    state = AsyncData(await _db.loadAllCredits());
  }

  // Notifica a Riverpod que la lista cambió sin releer la DB. Funciona porque
  // todas las mutaciones modifican el objeto Credit en el lugar ANTES de
  // llamar aquí — crear una nueva List con los mismos objetos ya mutados es
  // suficiente para que Riverpod propague el cambio a los widgets.
  void _notifyInPlace() {
    final current = state.value;
    if (current != null) state = AsyncData(List<Credit>.from(current));
  }

  Future<void> addCredit(Credit credit) async {
    _clearInterestUnknownIfRateKnown(credit);
    await _db.upsertCredit(credit);
    // Agrega el crédito nuevo al estado en memoria sin releer toda la DB.
    final current = List<Credit>.from(state.value ?? [])..add(credit);
    state = AsyncData(current);
  }

  Future<void> updateCredit(Credit credit) async {
    _clearInterestUnknownIfRateKnown(credit);
    await _db.upsertCredit(credit);
    _notifyInPlace();
  }

  Future<void> deleteCredit(String creditId) async {
    await _db.deleteCredit(creditId);
    // Necesita releer: el objeto ya no existe en memoria de forma confiable.
    await _reload();
  }

  Future<void> toggleInstallmentPaid(String creditId, int installmentNumber) async {
    final credits = state.value ?? [];
    final credit = credits.whereType<LoanCredit>().where((c) => c.id == creditId).firstOrNull;
    if (credit == null) return;
    final inst = credit.installments.firstWhere((i) => i.number == installmentNumber);
    applyInstallmentPayment(inst, !inst.paid);
    await _db.upsertCredit(credit);
    _notifyInPlace();
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
    _notifyInPlace();
  }

  Future<void> markAllInstallmentsPaid(String creditId) async {
    final credits = state.value ?? [];
    final credit = credits.whereType<LoanCredit>().where((c) => c.id == creditId).firstOrNull;
    if (credit == null) return;
    markAllInstallments(credit);
    await _db.upsertCredit(credit);
    _notifyInPlace();
  }

  Future<void> registerMovement(
    String creditId,
    String type,
    double amount,
    String note, {
    String? categoria,
    int? chargeInstallments,
  }) async {
    final credits = state.value ?? [];
    final credit = credits.whereType<CardCredit>().where((c) => c.id == creditId).firstOrNull;
    if (credit == null) return;
    registerCardMovement(credit, type, amount, note: note, categoria: categoria, chargeInstallments: chargeInstallments);
    await _db.upsertCredit(credit);
    _notifyInPlace();
  }

  Future<void> registerAdvance(
    String creditId, {
    required double amount,
    required String date,
    int? installments,
    double? interestRate,
    String? interestRateType,
    double? commission,
    String? firstPaymentDate,
    String? destination,
    String note = '',
  }) async {
    final credits = state.value ?? [];
    final credit = credits.whereType<CardCredit>().where((c) => c.id == creditId).firstOrNull;
    if (credit == null) return;
    final movement = CardMovement(
      date: date,
      type: CardMovementType.advance,
      amount: amount.abs(),
      note: note,
      advanceInstallments: installments,
      advanceInterestRate: interestRate,
      advanceInterestRateType: interestRateType,
      advanceCommission: commission,
      advanceFirstPaymentDate: firstPaymentDate,
      advanceDestination: destination,
    );
    credit.currentBalance = credit.currentBalance + amount.abs();
    credit.movements.add(movement);
    await _db.upsertCredit(credit);
    _notifyInPlace();
  }

  /// Registers an "abono extra" on a loan credit, applying it against the
  /// unpaid schedule (see applyLoanAbono) and persisting both the updated
  /// installments and the new abono history entry. Returns the created
  /// [LoanAbono] so the caller can show a result summary.
  Future<LoanAbono> registerLoanAbono(
    String creditId,
    double amount, {
    String note = '',
    AbonoStrategy strategy = AbonoStrategy.reducirCuota,
  }) async {
    final credits = state.value ?? [];
    final credit = credits.whereType<LoanCredit>().where((c) => c.id == creditId).firstOrNull;
    if (credit == null) {
      throw ArgumentError('Crédito no encontrado: $creditId');
    }
    final abono = applyLoanAbono(credit, amount, note: note, strategy: strategy);
    credit.abonos.add(abono);
    await _db.upsertCredit(credit);
    _notifyInPlace();
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
    _notifyInPlace();
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
    _notifyInPlace();
  }

  /// Replaces both credits and commercial quotas atomically (backup
  /// restore) — [newQuotas] defaults to empty for callers restoring a
  /// pre-cupo-comercial backup. Also refreshes commercialQuotasProvider,
  /// since its own state would otherwise go stale after this DB-level swap.
  Future<void> replaceAll(
    List<Credit> newCredits, {
    List<CommercialQuota> newQuotas = const [],
  }) async {
    await _db.replaceAllData(newCredits, newQuotas);
    await _reload();
    ref.invalidate(commercialQuotasProvider);
  }

  Future<void> clearAll() async {
    await _db.clearAllData();
    await _reload();
    ref.invalidate(commercialQuotasProvider);
  }
}


final creditsProvider = AsyncNotifierProvider<CreditsNotifier, List<Credit>>(
  CreditsNotifier.new,
);

/// Derived: total pending debt across all credits (dashboard header).
final totalUnpaidProvider = Provider<double>((ref) {
  final credits = ref.watch(creditsProvider).value ?? [];
  return credits.fold(0.0, (sum, c) => sum + getCreditRemainingBalance(c));
});

/// Derived: total number of credits (used by dashboard to avoid full rebuilds).
final totalCreditsCountProvider = Provider<int>((ref) {
  return ref.watch(creditsProvider).value?.length ?? 0;
});
