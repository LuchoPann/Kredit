import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kredit/data/models/credit.dart';
import 'package:kredit/data/models/installment.dart';
import 'package:kredit/data/models/loan_abono.dart';
import 'package:kredit/domain/date_utils.dart';
import 'package:kredit/domain/interest_rate.dart';
import 'package:kredit/domain/loan_calculator.dart';

/// Standard PMT (cuota francesa) formula, used as an independent oracle to
/// validate `buildLoanInstallments`'s quota-vs-interest math in at least one
/// case: `PMT = P * r / (1 - (1+r)^-n)`.
double _pmt(double principal, double periodRate, int n) {
  if (periodRate == 0) return principal / n;
  return principal * periodRate / (1 - math.pow(1 + periodRate, -n));
}

void main() {
  group('buildLoanInstallments (French amortization)', () {
    test('interest decreases and principal increases across installments', () {
      final periodRate = periodicRateFrom(24, InterestRateType.effectiveAnnual, CreditFrequency.monthly);
      final quota = _pmt(1000, periodRate, 12);

      final installments = buildLoanInstallments(
        totalAmount: 1000,
        totalInstallments: 12,
        quotaAmount: quota,
        frequency: CreditFrequency.monthly,
        startDate: '2026-01-15',
        interestRate: 24,
        interestRateType: InterestRateType.effectiveAnnual,
      );

      expect(installments, hasLength(12));
      for (var i = 1; i < installments.length; i++) {
        expect(installments[i].interest, lessThan(installments[i - 1].interest));
        expect(installments[i].principal, greaterThan(installments[i - 1].principal));
      }
    });

    test('quota computed via PMT formula amortizes the loan to exactly \$0', () {
      const principal = 5000000.0;
      const n = 24;
      final periodRate = periodicRateFrom(28, InterestRateType.effectiveAnnual, CreditFrequency.monthly);
      final quota = _pmt(principal, periodRate, n);

      final installments = buildLoanInstallments(
        totalAmount: principal,
        totalInstallments: n,
        quotaAmount: quota,
        frequency: CreditFrequency.monthly,
        startDate: '2026-01-15',
        interestRate: 28,
        interestRateType: InterestRateType.effectiveAnnual,
      );

      // First installment's interest should match balance*periodRate exactly.
      expect(installments[0].interest, closeTo(principal * periodRate, 1e-6));

      // Sum of all principal portions must equal the original loan amount
      // (allowing for the final settling installment absorbing rounding).
      final totalPrincipal = installments.fold(0.0, (s, i) => s + i.principal);
      expect(totalPrincipal, closeTo(principal, 1e-6));

      // Every installment before the PMT-derived quota should be very close
      // to the flat quota (French amortization is a fixed payment).
      for (final inst in installments.take(n - 1)) {
        expect(inst.principal + inst.interest, closeTo(quota, 1e-6));
      }
    });

    test('interestRate == 0 falls back to zero-interest behavior', () {
      final installments = buildLoanInstallments(
        totalAmount: 1200,
        totalInstallments: 4,
        quotaAmount: 300,
        frequency: CreditFrequency.weekly,
        startDate: '2026-01-01',
      );
      for (final inst in installments) {
        expect(inst.interest, 0);
        expect(inst.principal, 300);
      }
    });

    test('last installment settles the loan exactly at \$0, absorbing rounding', () {
      final periodRate = periodicRateFrom(35, InterestRateType.effectiveAnnual, CreditFrequency.monthly);
      final quota = _pmt(1000, periodRate, 6);
      final installments = buildLoanInstallments(
        totalAmount: 1000,
        totalInstallments: 6,
        quotaAmount: quota,
        frequency: CreditFrequency.monthly,
        startDate: '2026-01-01',
        interestRate: 35,
        interestRateType: InterestRateType.effectiveAnnual,
      );

      final totalPrincipal = installments.fold(0.0, (s, i) => s + i.principal);
      expect(totalPrincipal, closeTo(1000, 1e-6));
    });

    test('quota insufficient to cover interest caps principal at 0 without crashing', () {
      // A tiny quota relative to a large rate/balance means interest alone
      // exceeds the quota for the early installments.
      final installments = buildLoanInstallments(
        totalAmount: 1000000,
        totalInstallments: 3,
        quotaAmount: 1000, // far too small to cover interest at 60% E.A.
        frequency: CreditFrequency.monthly,
        startDate: '2026-01-01',
        interestRate: 60,
        interestRateType: InterestRateType.effectiveAnnual,
      );

      expect(installments, hasLength(3));
      expect(installments[0].principal, 0);
      expect(installments[0].principal, greaterThanOrEqualTo(0));
      // Last installment still settles to whatever balance remains, no crash.
      expect(installments.last.principal, greaterThanOrEqualTo(0));
    });

    test('splits principal/interest evenly when rate is 0 and computes correct due dates', () {
      final installments = buildLoanInstallments(
        totalAmount: 1200,
        totalInstallments: 4,
        quotaAmount: 300,
        frequency: CreditFrequency.monthly,
        startDate: '2026-01-15',
      );

      expect(installments, hasLength(4));
      for (final inst in installments) {
        expect(inst.interest, 0);
        expect(inst.principal, 300);
        expect(inst.amount, 300);
        expect(inst.paid, isFalse);
        expect(inst.interestWaived, isFalse);
      }
      expect(installments[0].dueDate, '2026-01-15');
      expect(installments[1].dueDate, '2026-02-15');
      expect(installments[2].dueDate, '2026-03-15');
      expect(installments[3].dueDate, '2026-04-15');
    });

    test('weekly frequency steps by 7 days', () {
      final installments = buildLoanInstallments(
        totalAmount: 400,
        totalInstallments: 3,
        quotaAmount: 150,
        frequency: CreditFrequency.weekly,
        startDate: '2026-01-01',
      );
      expect(installments[0].dueDate, '2026-01-01');
      expect(installments[1].dueDate, '2026-01-08');
      expect(installments[2].dueDate, '2026-01-15');
    });

    test('biweekly frequency steps by 14 days', () {
      final installments = buildLoanInstallments(
        totalAmount: 400,
        totalInstallments: 3,
        quotaAmount: 150,
        frequency: CreditFrequency.biweekly,
        startDate: '2026-01-01',
      );
      expect(installments[0].dueDate, '2026-01-01');
      expect(installments[1].dueDate, '2026-01-15');
      expect(installments[2].dueDate, '2026-01-29');
    });

    test('monthly frequency starting on the 31st rolls over short months (JS Date.setMonth parity)', () {
      final installments = buildLoanInstallments(
        totalAmount: 300,
        totalInstallments: 3,
        quotaAmount: 100,
        frequency: CreditFrequency.monthly,
        startDate: '2026-01-31',
      );
      expect(installments[0].dueDate, '2026-01-31');
      // Feb has 28 days in 2026 (not a leap year) -> day 31 overflows to Mar 3
      expect(installments[1].dueDate, '2026-03-03');
      expect(installments[2].dueDate, '2026-03-31');
    });
  });

  group('applyInstallmentPayment', () {
    test('paying early waives the interest portion', () {
      final inst = buildLoanInstallments(
        totalAmount: 1000,
        totalInstallments: 4,
        quotaAmount: 300,
        frequency: CreditFrequency.monthly,
        startDate: toDateStr(DateTime.now().add(const Duration(days: 30))),
        interestRate: 24,
      )[0];

      applyInstallmentPayment(inst, true);

      expect(inst.paid, isTrue);
      expect(inst.interestWaived, isTrue);
      expect(inst.amount, closeTo(inst.principal, 1e-9));
      expect(inst.paymentDate, isNotNull);
    });

    test('paying on/after the due date does NOT waive interest', () {
      final inst = buildLoanInstallments(
        totalAmount: 1000,
        totalInstallments: 4,
        quotaAmount: 300,
        frequency: CreditFrequency.monthly,
        startDate: toDateStr(DateTime.now().subtract(const Duration(days: 5))),
        interestRate: 24,
      )[0];
      final originalAmount = inst.amount;

      applyInstallmentPayment(inst, true);

      expect(inst.paid, isTrue);
      expect(inst.interestWaived, isFalse);
      expect(inst.amount, originalAmount);
    });

    test('unmarking a waived installment restores principal+interest', () {
      final inst = buildLoanInstallments(
        totalAmount: 1000,
        totalInstallments: 4,
        quotaAmount: 300,
        frequency: CreditFrequency.monthly,
        startDate: toDateStr(DateTime.now().add(const Duration(days: 30))),
        interestRate: 24,
      )[0];

      applyInstallmentPayment(inst, true);
      expect(inst.interestWaived, isTrue);

      applyInstallmentPayment(inst, false);
      expect(inst.paid, isFalse);
      expect(inst.interestWaived, isFalse);
      expect(inst.amount, closeTo(inst.principal + inst.interest, 1e-9));
      expect(inst.paymentDate, isNull);
    });

    test('zero-interest installment paid early is not marked as waived', () {
      final inst = buildLoanInstallments(
        totalAmount: 1200,
        totalInstallments: 4,
        quotaAmount: 300,
        frequency: CreditFrequency.monthly,
        startDate: toDateStr(DateTime.now().add(const Duration(days: 30))),
      )[0];

      applyInstallmentPayment(inst, true);
      expect(inst.interestWaived, isFalse);
      expect(inst.amount, 300);
    });

    test('early payment waives a bigger interest amount on an early installment than a late one', () {
      final periodRate = periodicRateFrom(30, InterestRateType.effectiveAnnual, CreditFrequency.monthly);
      final quota = _pmt(1000, periodRate, 12);
      final installments = buildLoanInstallments(
        totalAmount: 1000,
        totalInstallments: 12,
        quotaAmount: quota,
        frequency: CreditFrequency.monthly,
        startDate: toDateStr(DateTime.now().add(const Duration(days: 400))),
        interestRate: 30,
        interestRateType: InterestRateType.effectiveAnnual,
      );

      final early = installments[0];
      final late = installments[10];
      final earlyInterest = early.interest;
      final lateInterest = late.interest;
      expect(earlyInterest, greaterThan(lateInterest));

      applyInstallmentPayment(early, true);
      applyInstallmentPayment(late, true);

      expect(early.interestWaived, isTrue);
      expect(late.interestWaived, isTrue);
      // The waived amounts (principal+interest -> principal) differ by the
      // difference between the two installments' real interest, confirming
      // the waiver now reflects true decreasing French interest rather than
      // a flat linear split.
      expect(early.amount, closeTo(early.principal, 1e-9));
      expect(late.amount, closeTo(late.principal, 1e-9));
      expect(earlyInterest, isNot(closeTo(lateInterest, 1e-6)));
    });
  });

  group('getLoanRemainingBalance', () {
    test('sums only unpaid installment amounts', () {
      final credit = LoanCredit(
        id: 'c1',
        name: 'Test',
        lender: 'Lender',
        totalAmount: 1000,
        quotaAmount: 300,
        totalInstallments: 4,
        frequency: CreditFrequency.monthly,
        startDate: '2026-01-01',
        installments: buildLoanInstallments(
          totalAmount: 1000,
          totalInstallments: 4,
          quotaAmount: 300,
          frequency: CreditFrequency.monthly,
          startDate: '2026-01-01',
        ),
      );
      applyInstallmentPayment(credit.installments[0], true);
      applyInstallmentPayment(credit.installments[1], true);

      // Rate 0 -> principal 300/300/300, and the final installment settles
      // the last $100 of balance exactly (1000 - 300*3 = 100).
      final remaining = getLoanRemainingBalance(credit);
      expect(remaining, closeTo(400, 1e-9));
    });
  });

  group('reprorateUnpaidInstallments', () {
    LoanCredit buildLoan() {
      return LoanCredit(
        id: 'c1',
        name: 'Test',
        lender: 'Lender',
        totalAmount: 1000,
        quotaAmount: 300,
        totalInstallments: 4,
        frequency: CreditFrequency.monthly,
        startDate: '2026-01-01',
        installments: buildLoanInstallments(
          totalAmount: 1000,
          totalInstallments: 4,
          quotaAmount: 300,
          frequency: CreditFrequency.monthly,
          startDate: '2026-01-01',
        ),
      );
    }

    test('no-op when nothing actually changes', () {
      final credit = buildLoan();
      final before = credit.installments.map((i) => i.toJson()).toList();
      reprorateUnpaidInstallments(credit, newQuota: credit.quotaAmount);
      final after = credit.installments.map((i) => i.toJson()).toList();
      expect(after, before);
    });

    test('changing the interest rate re-derives only unpaid installments with French amortization', () {
      final credit = buildLoan();
      applyInstallmentPayment(credit.installments[0], true);
      final paidSnapshot = credit.installments[0].toJson();

      reprorateUnpaidInstallments(credit, newInterestRate: 30, newInterestRateType: InterestRateType.effectiveAnnual);

      expect(credit.installments[0].toJson(), paidSnapshot); // untouched
      expect(credit.interestRate, 30);
      final unpaid = credit.installments.skip(1).toList();
      for (final inst in unpaid) {
        expect(inst.interest, greaterThanOrEqualTo(0));
      }
      // Interest should now be decreasing (French) rather than flat.
      expect(unpaid[0].interest, greaterThan(unpaid[1].interest));
      // Last installment settles the remaining principal to $0.
      final totalPrincipalFromUnpaid = unpaid.fold(0.0, (s, i) => s + i.principal);
      final remainingPrincipal = credit.totalAmount - credit.installments[0].principal;
      expect(totalPrincipalFromUnpaid, closeTo(remainingPrincipal, 1e-6));
    });

    test('changing total amount reflows the remaining unpaid principal', () {
      final credit = buildLoan();
      applyInstallmentPayment(credit.installments[0], true);
      reprorateUnpaidInstallments(credit, newTotalAmount: 1500);

      expect(credit.totalAmount, 1500);
      final unpaid = credit.installments.skip(1).toList();
      final totalPrincipalFromUnpaid = unpaid.fold(0.0, (s, i) => s + i.principal);
      final remainingPrincipal = 1500 - credit.installments[0].principal;
      expect(totalPrincipalFromUnpaid, closeTo(remainingPrincipal, 1e-6));
    });
  });

  group('recomputeLoanInstallments', () {
    test('preserves paid status/paymentDate/interestWaived while updating amounts', () {
      final credit = LoanCredit(
        id: 'c1',
        name: 'Test',
        lender: 'Lender',
        totalAmount: 1000,
        quotaAmount: 300,
        totalInstallments: 4,
        frequency: CreditFrequency.monthly,
        startDate: '2026-01-01',
        // Simulate a loan built by the OLD linear engine: flat interest.
        installments: [
          for (var i = 1; i <= 4; i++)
            Installment(number: i, dueDate: '2026-0${i.toString().padLeft(2, '0')}-01', amount: 300, principal: 250, interest: 50),
        ],
      );
      applyInstallmentPayment(credit.installments[0], true);
      final oldPaymentDate = credit.installments[0].paymentDate;

      final recomputed = recomputeLoanInstallments(credit);

      expect(recomputed, hasLength(4));
      expect(recomputed[0].paid, isTrue);
      expect(recomputed[0].paymentDate, oldPaymentDate);
      expect(recomputed[1].paid, isFalse);

      // Idempotent: recomputing again on already-French installments
      // reproduces identical numbers.
      final again = recomputeLoanInstallments(credit..installments = recomputed);
      for (var i = 0; i < recomputed.length; i++) {
        expect(again[i].principal, closeTo(recomputed[i].principal, 1e-9));
        expect(again[i].interest, closeTo(recomputed[i].interest, 1e-9));
      }
    });
  });

  group('applyLoanAbono', () {
    LoanCredit buildLoan({String? startDate}) {
      final start = startDate ?? toDateStr(DateTime.now().add(const Duration(days: 30)));
      return LoanCredit(
        id: 'c1',
        name: 'Test',
        lender: 'Lender',
        totalAmount: 1000,
        quotaAmount: 300,
        totalInstallments: 4,
        frequency: CreditFrequency.monthly,
        startDate: start,
        installments: buildLoanInstallments(
          totalAmount: 1000,
          totalInstallments: 4,
          quotaAmount: 300,
          frequency: CreditFrequency.monthly,
          startDate: start,
        ),
      );
    }

    test('reducirCuota: same installment count, each future cuota gets cheaper', () {
      final credit = buildLoan(); // rate 0: totalAmount 1000, 4 x 300, no abono yet
      final abono = applyLoanAbono(credit, 200, strategy: AbonoStrategy.reducirCuota);

      // installmentsSkipped is 0 for reducirCuota: no installments dropped.
      expect(abono.installmentsSkipped, 0);
      expect(abono.amount, 200);
      expect(credit.installments, hasLength(4));
      for (final inst in credit.installments) {
        expect(inst.paid, isFalse);
      }
      // New remaining principal = 1000 - 200 = 800, spread over the same 4
      // installments (rate 0 -> quota = principal / count).
      expect(credit.quotaAmount, closeTo(200, 1e-9));
      for (final inst in credit.installments) {
        expect(inst.principal, closeTo(200, 1e-9));
        expect(inst.amount, closeTo(200, 1e-9));
      }
      expect(getLoanRemainingBalance(credit), closeTo(800, 1e-9));
    });

    test('reducirPlazo: same fixed quota, fewer installments, total lands at \$0 exact', () {
      final credit = buildLoan(); // rate 0: 1000 total, 4 x 300 quota
      final abono = applyLoanAbono(credit, 400, strategy: AbonoStrategy.reducirPlazo);

      // New remaining principal = 1000 - 400 = 600, at a fixed 300 quota
      // (rate 0) that takes exactly 2 installments -> 2 dropped.
      expect(abono.installmentsSkipped, 2);
      expect(credit.installments, hasLength(2));
      expect(credit.quotaAmount, closeTo(300, 1e-9)); // unchanged
      expect(getLoanRemainingBalance(credit), closeTo(600, 1e-9));
      // Last installment settles exactly to $0 residual.
      final total = credit.installments.fold(0.0, (s, i) => s + i.principal);
      expect(total, closeTo(600, 1e-9));
    });

    test('reducirPlazo falls back to reducirCuota when the fixed quota cannot '
        'cover even the first period of interest', () {
      final start = toDateStr(DateTime.now().add(const Duration(days: 30)));
      // Quota (50) well below the first period's interest at a high rate,
      // guaranteeing negative amortization if term were held fixed.
      final credit = LoanCredit(
        id: 'c2',
        name: 'Test',
        lender: 'Lender',
        totalAmount: 1000,
        quotaAmount: 50,
        totalInstallments: 4,
        frequency: CreditFrequency.monthly,
        startDate: start,
        interestRate: 90, // deliberately extreme E.A. to force the fallback
        installments: buildLoanInstallments(
          totalAmount: 1000,
          totalInstallments: 4,
          quotaAmount: 50,
          frequency: CreditFrequency.monthly,
          startDate: start,
          interestRate: 90,
        ),
      );

      final abono = applyLoanAbono(credit, 200, strategy: AbonoStrategy.reducirPlazo);

      // Fell back to reducirCuota: same installment count, nothing dropped.
      expect(abono.installmentsSkipped, 0);
      expect(credit.installments, hasLength(4));
      // Principal (not amount, which also carries interest) reflects the
      // new lower balance the reducirCuota fallback reamortized against.
      final totalPrincipal =
          credit.installments.fold(0.0, (s, i) => s + i.principal);
      expect(totalPrincipal, closeTo(800, 1e-6));
    });

    test('abono exactly equal to total pending debt settles loan at \$0, no error', () {
      final credit = buildLoan();
      final totalDebt = getLoanRemainingBalance(credit); // 1000 (rate 0)
      final abono = applyLoanAbono(credit, totalDebt);

      expect(abono.installmentsSkipped, 4);
      expect(abono.amount, closeTo(totalDebt, 1e-9));
      expect(abono.requestedAmount, closeTo(totalDebt, 1e-9));
      expect(abono.wasCapped, isFalse);
      for (final inst in credit.installments) {
        expect(inst.paid, isTrue);
      }
      expect(getLoanRemainingBalance(credit), closeTo(0, 1e-9));
    });

    test('abono greater than all remaining debt pays off everything, caps applied amount '
        '(does not silently discard the surplus)', () {
      final credit = buildLoan();
      final totalDebt = getLoanRemainingBalance(credit); // 1000 (rate 0)
      final abono = applyLoanAbono(credit, 5000);

      expect(abono.installmentsSkipped, 4);
      // The amount actually applied is capped to the real outstanding debt,
      // never the full requested amount — the surplus is not silently lost,
      // it's reflected by amount < requestedAmount / wasCapped.
      expect(abono.amount, closeTo(totalDebt, 1e-9));
      expect(abono.requestedAmount, 5000);
      expect(abono.wasCapped, isTrue);
      for (final inst in credit.installments) {
        expect(inst.paid, isTrue);
      }
      expect(getLoanRemainingBalance(credit), closeTo(0, 1e-9));
    });

    test('amount <= 0 throws ArgumentError', () {
      final credit = buildLoan();
      expect(() => applyLoanAbono(credit, 0), throwsArgumentError);
      expect(() => applyLoanAbono(credit, -10), throwsArgumentError);
    });

    test('no pending installments throws ArgumentError', () {
      final credit = buildLoan();
      markAllInstallments(credit);
      expect(() => applyLoanAbono(credit, 100), throwsArgumentError);
    });

    test('sets scheduleManuallyAdjusted = true (reducirCuota)', () {
      final credit = buildLoan();
      expect(credit.scheduleManuallyAdjusted, isFalse);
      applyLoanAbono(credit, 200, strategy: AbonoStrategy.reducirCuota);
      expect(credit.scheduleManuallyAdjusted, isTrue);
    });

    test('sets scheduleManuallyAdjusted = true (reducirPlazo)', () {
      final credit = buildLoan();
      expect(credit.scheduleManuallyAdjusted, isFalse);
      applyLoanAbono(credit, 400, strategy: AbonoStrategy.reducirPlazo);
      expect(credit.scheduleManuallyAdjusted, isTrue);
    });

    test('sets scheduleManuallyAdjusted = true when abono settles the whole loan', () {
      final credit = buildLoan();
      final totalDebt = getLoanRemainingBalance(credit);
      expect(credit.scheduleManuallyAdjusted, isFalse);
      applyLoanAbono(credit, totalDebt);
      expect(credit.scheduleManuallyAdjusted, isTrue);
    });

    test('records previousQuotaAmount and previousInstallmentsSnapshot for the '
        'reamortization path (reducirCuota)', () {
      final credit = buildLoan(); // quotaAmount 300 before the abono
      final abono = applyLoanAbono(credit, 200, strategy: AbonoStrategy.reducirCuota);

      expect(abono.previousQuotaAmount, closeTo(300, 1e-9));
      expect(abono.previousInstallmentsSnapshot, hasLength(4));
      for (final inst in abono.previousInstallmentsSnapshot!.take(3)) {
        expect(inst.principal, closeTo(300, 1e-6)); // quota 300, rate 0
      }
    });

    test('does not record previousQuotaAmount/snapshot when the abono settles the '
        'whole loan', () {
      final credit = buildLoan();
      final totalDebt = getLoanRemainingBalance(credit);
      final abono = applyLoanAbono(credit, totalDebt);

      expect(abono.previousQuotaAmount, isNull);
      expect(abono.previousInstallmentsSnapshot, isNull);
    });
  });

  group('reverseLoanAbono', () {
    LoanCredit buildLoan({String? startDate}) {
      final start = startDate ?? toDateStr(DateTime.now().add(const Duration(days: 30)));
      return LoanCredit(
        id: 'c1',
        name: 'Test',
        lender: 'Lender',
        totalAmount: 1000,
        quotaAmount: 300,
        totalInstallments: 4,
        frequency: CreditFrequency.monthly,
        startDate: start,
        installments: buildLoanInstallments(
          totalAmount: 1000,
          totalInstallments: 4,
          quotaAmount: 300,
          frequency: CreditFrequency.monthly,
          startDate: start,
        ),
      );
    }

    test('deleting an abono applied with reducirCuota restores the original '
        'quotaAmount (regression test for the bug where the lowered cuota was '
        'never reverted)', () {
      final credit = buildLoan();
      expect(credit.quotaAmount, 300);

      final abono = applyLoanAbono(credit, 200, strategy: AbonoStrategy.reducirCuota);
      // The abono did lower the quota — sanity check the setup actually
      // exercises the bug scenario.
      expect(credit.quotaAmount, closeTo(200, 1e-9));

      reverseLoanAbono(credit, abono);

      expect(credit.quotaAmount, closeTo(300, 1e-9));
      expect(credit.installments, hasLength(4));
      for (final inst in credit.installments.take(3)) {
        expect(inst.principal, closeTo(300, 1e-6));
        expect(inst.paid, isFalse);
      }
      expect(getLoanRemainingBalance(credit), closeTo(1000, 1e-6));
    });

    test('deleting an abono applied with reducirPlazo restores the dropped '
        'installments and the original schedule', () {
      final credit = buildLoan();
      final abono = applyLoanAbono(credit, 400, strategy: AbonoStrategy.reducirPlazo);
      expect(credit.installments, hasLength(2)); // 2 dropped

      reverseLoanAbono(credit, abono);

      expect(credit.installments, hasLength(4));
      expect(credit.quotaAmount, closeTo(300, 1e-9));
      for (final inst in credit.installments.take(3)) {
        expect(inst.paid, isFalse);
        expect(inst.principal, closeTo(300, 1e-6));
      }
      expect(getLoanRemainingBalance(credit), closeTo(1000, 1e-6));
    });

    test('reversing an abono that fully settled the loan (wasCapped) unmarks '
        'every installment, unaffected by the quota/snapshot fix', () {
      final credit = buildLoan();
      final totalDebt = getLoanRemainingBalance(credit);
      final abono = applyLoanAbono(credit, 5000); // capped surplus
      expect(credit.installments.every((i) => i.paid), isTrue);

      reverseLoanAbono(credit, abono);

      expect(credit.installments.every((i) => !i.paid), isTrue);
      expect(getLoanRemainingBalance(credit), closeTo(totalDebt, 1e-9));
    });

    test('falls back to the old best-effort undo for abonos persisted before '
        'the previousQuotaAmount/snapshot fields existed', () {
      final credit = buildLoan();
      applyLoanAbono(credit, 200, strategy: AbonoStrategy.reducirCuota);
      // Simulate a legacy-persisted abono (no snapshot/previousQuotaAmount),
      // e.g. loaded from a database row written before this fix.
      final legacyAbono = const LoanAbono(
        date: '2024-01-01',
        amount: 200,
        installmentsSkipped: 0,
      );

      // Should not throw, and should leave the quota as-is (no info to
      // restore it) rather than crash.
      expect(() => reverseLoanAbono(credit, legacyAbono), returnsNormally);
    });
  });

  group('registerInstallmentActualPayment — last-installment shortfall bug fix', () {
    test('paying less than calculated on the LAST pending installment appends a new '
        'installment carrying the shortfall, instead of losing it silently', () {
      final start = toDateStr(DateTime.now().add(const Duration(days: 30)));
      final credit = LoanCredit(
        id: 'c1',
        name: 'Test',
        lender: 'Lender',
        totalAmount: 300,
        quotaAmount: 300,
        totalInstallments: 1,
        frequency: CreditFrequency.monthly,
        startDate: start,
        installments: buildLoanInstallments(
          totalAmount: 300,
          totalInstallments: 1,
          quotaAmount: 300,
          frequency: CreditFrequency.monthly,
          startDate: start,
        ),
      );

      registerInstallmentActualPayment(credit, credit.installments[0], 250);

      expect(credit.installments[0].paid, isTrue);
      // A new installment was appended holding the $50 shortfall, still
      // pending — the loan is NOT fully settled at $0.
      expect(credit.installments, hasLength(2));
      final extra = credit.installments[1];
      expect(extra.number, 2);
      expect(extra.paid, isFalse);
      expect(extra.principal, closeTo(50, 1e-9));
      expect(extra.interest, 0);
      expect(extra.amount, closeTo(50, 1e-9));
      expect(getLoanRemainingBalance(credit), closeTo(50, 1e-9));
    });

    test('paying more than calculated on the last installment discards the surplus '
        '(no negative installment created)', () {
      final start = toDateStr(DateTime.now().add(const Duration(days: 30)));
      final credit = LoanCredit(
        id: 'c1',
        name: 'Test',
        lender: 'Lender',
        totalAmount: 300,
        quotaAmount: 300,
        totalInstallments: 1,
        frequency: CreditFrequency.monthly,
        startDate: start,
        installments: buildLoanInstallments(
          totalAmount: 300,
          totalInstallments: 1,
          quotaAmount: 300,
          frequency: CreditFrequency.monthly,
          startDate: start,
        ),
      );

      registerInstallmentActualPayment(credit, credit.installments[0], 350);

      expect(credit.installments, hasLength(1));
      expect(credit.installments[0].paid, isTrue);
      expect(getLoanRemainingBalance(credit), closeTo(0, 1e-9));
    });

    test('sets scheduleManuallyAdjusted = true when diff != 0', () {
      final start = toDateStr(DateTime.now().add(const Duration(days: 30)));
      final credit = LoanCredit(
        id: 'c1',
        name: 'Test',
        lender: 'Lender',
        totalAmount: 300,
        quotaAmount: 300,
        totalInstallments: 1,
        frequency: CreditFrequency.monthly,
        startDate: start,
        installments: buildLoanInstallments(
          totalAmount: 300,
          totalInstallments: 1,
          quotaAmount: 300,
          frequency: CreditFrequency.monthly,
          startDate: start,
        ),
      );

      expect(credit.scheduleManuallyAdjusted, isFalse);
      registerInstallmentActualPayment(credit, credit.installments[0], 250);
      expect(credit.scheduleManuallyAdjusted, isTrue);
    });

    test('does NOT set scheduleManuallyAdjusted when diff == 0', () {
      final start = toDateStr(DateTime.now().add(const Duration(days: 30)));
      final credit = LoanCredit(
        id: 'c1',
        name: 'Test',
        lender: 'Lender',
        totalAmount: 300,
        quotaAmount: 300,
        totalInstallments: 1,
        frequency: CreditFrequency.monthly,
        startDate: start,
        installments: buildLoanInstallments(
          totalAmount: 300,
          totalInstallments: 1,
          quotaAmount: 300,
          frequency: CreditFrequency.monthly,
          startDate: start,
        ),
      );

      final calculated = credit.installments[0].amount;
      expect(credit.scheduleManuallyAdjusted, isFalse);
      registerInstallmentActualPayment(credit, credit.installments[0], calculated);
      expect(credit.scheduleManuallyAdjusted, isFalse);
    });
  });

  group('estimateMoraInterest', () {
    LoanCredit buildLoan({required String dueDate, double interestRate = 24}) {
      return LoanCredit(
        id: 'c1',
        name: 'Test',
        lender: 'Lender',
        totalAmount: 1000,
        quotaAmount: 300,
        totalInstallments: 1,
        frequency: CreditFrequency.monthly,
        startDate: dueDate,
        interestRate: interestRate,
        installments: [
          Installment(
            number: 1,
            dueDate: dueDate,
            amount: 300,
            principal: 300,
            interest: 0,
          ),
        ],
      );
    }

    test('not-yet-due installment returns 0', () {
      final due = toDateStr(DateTime.now().add(const Duration(days: 10)));
      final credit = buildLoan(dueDate: due);
      expect(estimateMoraInterest(credit, credit.installments[0]), 0);
    });

    test('already-paid installment returns 0 even if overdue', () {
      final due = toDateStr(DateTime.now().subtract(const Duration(days: 10)));
      final credit = buildLoan(dueDate: due);
      credit.installments[0].paid = true;
      expect(estimateMoraInterest(credit, credit.installments[0]), 0);
    });

    test('overdue installment computes simple daily mora interest, capped at the '
        'usury ceiling', () {
      final now = DateTime.now();
      final due = toDateStr(now.subtract(const Duration(days: 13)));
      final credit = buildLoan(dueDate: due, interestRate: 24);
      final inst = credit.installments[0];

      final mora = estimateMoraInterest(credit, inst, asOf: now, moraRateMultiplier: 1.5);

      final ordinaryDaily = dailyRateFrom(24, InterestRateType.effectiveAnnual);
      final usuryDaily = dailyRateFrom(35, InterestRateType.effectiveAnnual);
      final expectedDaily = math.min(ordinaryDaily * 1.5, usuryDaily);
      final expected = inst.amount * expectedDaily * 13;

      expect(mora, closeTo(expected, 1e-6));
      expect(mora, greaterThan(0));
    });

    test('extreme ordinary rate gets capped at the usury ceiling instead of '
        'compounding unrealistically', () {
      final now = DateTime.now();
      final due = toDateStr(now.subtract(const Duration(days: 5)));
      final credit = buildLoan(dueDate: due, interestRate: 90);
      final inst = credit.installments[0];

      final mora = estimateMoraInterest(credit, inst, asOf: now);

      final usuryDaily = dailyRateFrom(35, InterestRateType.effectiveAnnual);
      final cappedExpected = inst.amount * usuryDaily * 5;

      expect(mora, closeTo(cappedExpected, 1e-6));
    });
  });
}
