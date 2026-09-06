import 'dart:math' as math;

/// Periodicity/expression of a card's interest rate, as entered by the
/// user. Different lenders quote their rates differently (E.A., E.M.,
/// simple monthly); Kredit lets the user say which one applies and
/// normalizes internally to an effective daily rate so the calculation
/// engine never needs to know where the rate came from.
class InterestRateType {
  /// Effective annual rate (E.A.), compounded annually. Historical
  /// default/only behavior before this type existed — kept as the default
  /// so existing credits keep computing exactly as before.
  static const effectiveAnnual = 'effectiveAnnual';

  /// Effective monthly rate (E.M.), compounded monthly.
  static const effectiveMonthly = 'effectiveMonthly';

  /// Simple ("nominal") monthly rate, not compounded — plain rate/30 per
  /// day.
  static const nominalMonthly = 'nominalMonthly';

  static const values = [effectiveAnnual, effectiveMonthly, nominalMonthly];

  static bool isValid(String? value) => values.contains(value);
}

/// Converts [rate] (expressed as a percentage, e.g. `24.5` for 24.5%) from
/// [rateType] into an equivalent effective daily rate (as a decimal
/// fraction, e.g. `0.00058`), so `card_calculator.dart` can always apply
/// simple daily interest regardless of how the lender expresses its rate.
///
/// Formulas:
/// - effectiveAnnual  -> daily: (1 + r)^(1/365) - 1
/// - effectiveMonthly -> daily: (1 + r)^(1/30)  - 1
/// - nominalMonthly   -> daily: r / 30 (no compounding)
///
/// where `r = rate / 100`. Unknown/null [rateType] falls back to
/// [InterestRateType.effectiveAnnual] to preserve legacy behavior.
double dailyRateFrom(double rate, String? rateType) {
  if (rate == 0) return 0.0;
  final r = rate / 100;
  switch (rateType) {
    case InterestRateType.effectiveMonthly:
      return math.pow(1 + r, 1 / 30) - 1;
    case InterestRateType.nominalMonthly:
      return r / 30;
    case InterestRateType.effectiveAnnual:
    default:
      return math.pow(1 + r, 1 / 365) - 1;
  }
}

/// Soft, non-blocking warning for when [rate] (a percentage, e.g. `24` for
/// 24%) looks like it was typed for the wrong periodicity given the
/// selected [rateType]. Returns `null` when the value looks plausible.
///
/// This never blocks saving — it only flags values that are clearly
/// implausible for the chosen periodicity, so a real (if unusual) rate the
/// user insists on is never rejected.
///
/// Thresholds (Colombian consumer-credit context):
///
/// Source for the upper bound: the "tasa de usura" for consumer/ordinary
/// credit in Colombia is set monthly by the Superintendencia Financiera de
/// Colombia as 1.5x the Interés Bancario Corriente (IBC), and through
/// 2025-2026 it has moved roughly in the 27%-29.66% E.A. range. Any rate
/// meaningfully above that ceiling is effectively illegal for a regulated
/// lender, so it is far more likely a data-entry mistake (a monthly rate
/// typed into the annual field, a stray digit, double compounding, etc.)
/// than a genuine rare case. We give a margin of a few points above the
/// real ceiling (~30%) to avoid false positives for edge cases like
/// microcredit, which can have a distinct/higher usury ceiling, landing at
/// 35% E.A. as the warning threshold. If the Superfinanciera's published
/// usury rate moves significantly from this range in the future, update
/// this threshold (and this comment) to match.
///
/// - Monthly rates (effectiveMonthly / nominalMonthly): real-world monthly
///   rates for cards/loans in Colombia sit roughly in the 1.5%-4% range.
///   Anything above 5% monthly is far more plausible as an annual rate
///   typed into the monthly field (e.g. "24" meaning 24% E.A.), so we warn
///   above that threshold. Note 5% monthly, compounded, is already ~79.6%
///   E.A. — well past the usury ceiling — so this threshold independently
///   covers the "monthly rate that implies an illegal annual rate" case
///   too.
/// - Annual rates (effectiveAnnual): typical E.A. in Colombia runs
///   ~15%-45% (usury ceiling ~27%-29.66% E.A. for consumer/ordinary
///   credit as of 2025-2026, see above). Below 5% E.A. is suspiciously low
///   (more likely a monthly rate was typed here, or a placeholder value
///   was left behind), and above 35% E.A. is far enough past the real
///   usury ceiling to almost certainly be a data-entry mistake (e.g. a
///   monthly rate typed as annual, a monthly rate compounded twice, or a
///   stray digit) rather than a legitimate rare case.
String? rateInconsistencyWarning(double rate, String? rateType) {
  if (rate <= 0) return null;
  switch (rateType) {
    case InterestRateType.effectiveMonthly:
      if (rate > 5) {
        return 'Una tasa efectiva mensual del ${_fmt(rate)}% equivale a una tasa efectiva '
            'anual considerablemente superior. ¿Seguro que la tasa está expresada '
            'mensualmente?';
      }
      return null;
    case InterestRateType.nominalMonthly:
      if (rate > 5) {
        return 'Una tasa mensual del ${_fmt(rate)}% es inusualmente alta. ¿Seguro que la '
            'tasa está expresada mensualmente y no anualmente?';
      }
      return null;
    case InterestRateType.effectiveAnnual:
    default:
      if (rate > 35) {
        return 'Una tasa efectiva anual del ${_fmt(rate)}% es extremadamente alta (por encima '
            'de la tasa de usura vigente en Colombia). Verifica que no hayas ingresado una '
            'tasa mensual por error.';
      }
      if (rate < 5) {
        return 'Una tasa efectiva anual del ${_fmt(rate)}% es inusualmente baja. Verifica que '
            'esté expresada como anual y no como mensual.';
      }
      return null;
  }
}

/// Converts [rate] (as expressed by [rateType]) into an equivalent
/// effective rate per installment period, given a loan's [frequency]
/// ('weekly' | 'biweekly' | 'monthly' — the same string literals as
/// `CreditFrequency` in `credit.dart`, referenced here as raw strings to
/// avoid a circular import). Reuses [dailyRateFrom] as the common basis and
/// compounds it across the number of days in one period, so a loan's French
/// amortization and a card's daily accrual always agree on how E.A./E.M./
/// nominal rates are interpreted.
double periodicRateFrom(double rate, String? rateType, String frequency) {
  final daily = dailyRateFrom(rate, rateType);
  if (daily == 0) return 0.0;
  final days = switch (frequency) {
    'weekly' => 7,
    'biweekly' => 14,
    _ => 30, // monthly and any unknown/default frequency
  };
  return math.pow(1 + daily, days) - 1;
}

String _fmt(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
