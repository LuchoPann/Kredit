import 'package:flutter_test/flutter_test.dart';
import 'package:krezium/data/models/credit.dart';
import 'package:krezium/data/models/installment.dart';
import 'package:krezium/domain/debt_attack_simulator.dart';
import 'package:krezium/domain/interest_rate.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Synthetic LoanCredit with [n] equal unpaid installments of [minPayment]
/// each, giving a total balance ≈ n * minPayment in the simulator.
LoanCredit _loan({
  required String id,
  required double interestRateEA,
  required double minPayment,
  int n = 60,
}) {
  return LoanCredit(
    id: id,
    name: id,
    lender: 'Bank',
    totalAmount: n * minPayment,
    quotaAmount: minPayment,
    totalInstallments: n,
    frequency: CreditFrequency.monthly,
    startDate: '2024-01-01',
    interestRate: interestRateEA,
    interestRateType: InterestRateType.effectiveAnnual,
    installments: List.generate(
      n,
      (i) => Installment(
        number: i + 1,
        dueDate: '2026-01-01',
        amount: minPayment,
        principal: minPayment * 0.7,
        interest: minPayment * 0.3,
        paid: false,
      ),
    ),
  );
}

/// CardCredit with a fixed balance and effective-annual rate.
CardCredit _card({
  required String id,
  required double balance,
  required double interestRateEA,
}) =>
    CardCredit(
      id: id,
      name: id,
      lender: 'Bank',
      currentBalance: balance,
      interestRate: interestRateEA,
      interestRateType: InterestRateType.effectiveAnnual,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUp(() => paidOffTracker.clear());

  group('recommendStrategy', () {
    test('single credit — returns valid recommendation without crash', () {
      final credits = [_card(id: 'solo', balance: 1000000, interestRateEA: 28)];
      paidOffTracker.clear();
      final rec = recommendStrategy(credits, extraMonthlyPayment: 200000);
      expect(AttackStrategy.values, contains(rec.recommended));
      expect(rec.headline, isNotEmpty);
      expect(rec.reasoning, isNotEmpty);
    });

    test('empty credits — no crash, returns valid recommendation', () {
      paidOffTracker.clear();
      final rec = recommendStrategy([], extraMonthlyPayment: 0);
      expect(AttackStrategy.values, contains(rec.recommended));
    });

    test('very different rates → Avalanche recommended', () {
      // A: $2.01M at 36% EA (2.57%/month), min $30K. B: $1.5M at 3% EA (0.25%/month), min $30K.
      // Extra: $100K.
      // Snowball attacks B first (smaller balance). B takes ~12 months to pay off.
      // During those 12 months A gets only $30K min while A accrues ~$51K interest/month → grows.
      // Avalanche attacks A from month 1 with $130K/month → pays A off in ~20 months.
      // monthsDiff ≈ 5 months (≥3) → avalancheWins = true.
      // MAD of monthly rates ≈ 1.16pp (>0.5) → snowballWins = false.
      final credits = [
        _loan(id: 'expensive', interestRateEA: 36, minPayment: 30000, n: 67),
        _loan(id: 'cheap', interestRateEA: 3, minPayment: 30000, n: 50),
      ];
      paidOffTracker.clear();
      final rec = recommendStrategy(credits, extraMonthlyPayment: 100000);
      expect(rec.recommended, AttackStrategy.avalanche,
          reason: 'Rate MAD is high (1.16pp) and monthsDiff ≥ 3; Avalanche wins');
    });

    test('nearly equal rates with tiny debt → Snowball recommended (quick first win)', () {
      // Both loans at ~18% EA (similar rates, MAD < 0.5pp).
      // Card B is tiny ($300K, min $100K) → paid off in ≤3 months.
      // firstWinMonths ≤ 3 AND MAD < 0.5pp → Snowball wins.
      final credits = [
        _loan(id: 'big', interestRateEA: 18, minPayment: 200000, n: 30),
        _loan(id: 'tiny', interestRateEA: 17.5, minPayment: 100000, n: 3),
      ];
      paidOffTracker.clear();
      final rec = recommendStrategy(credits, extraMonthlyPayment: 300000);
      expect(rec.recommended, AttackStrategy.snowball,
          reason: 'Rates nearly equal (MAD < 0.5pp); tiny debt gives a first win in ≤3 months');
    });

    test('savingsNote is non-null when Avalanche is recommended and saves over 100K COP', () {
      final credits = [
        _loan(id: 'highrate', interestRateEA: 36, minPayment: 30000, n: 67),
        _loan(id: 'lowrate', interestRateEA: 3, minPayment: 30000, n: 50),
      ];
      paidOffTracker.clear();
      final rec = recommendStrategy(credits, extraMonthlyPayment: 100000);
      if (rec.recommended == AttackStrategy.avalanche) {
        expect(rec.savingsNote, isNotNull,
            reason: 'savingsNote should be set when Avalanche saves more than 100K COP vs Snowball');
      }
    });

    test('motivationNote is non-null when Snowball is recommended with quick first win', () {
      final credits = [
        _loan(id: 'main', interestRateEA: 18, minPayment: 200000, n: 25),
        _loan(id: 'small', interestRateEA: 17.8, minPayment: 100000, n: 2),
      ];
      paidOffTracker.clear();
      final rec = recommendStrategy(credits, extraMonthlyPayment: 300000);
      if (rec.recommended == AttackStrategy.snowball) {
        expect(rec.motivationNote, isNotNull,
            reason: 'motivationNote should be set when Snowball wins and first credit pays off ≤6 months');
      }
    });

    test('extra payment of 0 still produces a recommendation without crash', () {
      final credits = [
        _card(id: 'a', balance: 2000000, interestRateEA: 24),
        _card(id: 'b', balance: 3000000, interestRateEA: 12),
      ];
      paidOffTracker.clear();
      final rec = recommendStrategy(credits, extraMonthlyPayment: 0);
      expect(AttackStrategy.values, contains(rec.recommended));
    });

    test('paidOffTracker reset — same inputs produce same result on repeated calls', () {
      final credits = [
        _card(id: 'x', balance: 1000000, interestRateEA: 20),
        _card(id: 'y', balance: 500000, interestRateEA: 19),
      ];

      paidOffTracker.clear();
      final rec1 = recommendStrategy(credits, extraMonthlyPayment: 200000);
      paidOffTracker.clear();
      final rec2 = recommendStrategy(credits, extraMonthlyPayment: 200000);

      expect(rec1.recommended, rec2.recommended,
          reason: 'Same inputs with cleared tracker must produce identical recommendation');
    });
  });
}
