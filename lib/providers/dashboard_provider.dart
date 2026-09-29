import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/credit.dart';
import '../domain/credit_calculator.dart';
import '../domain/recommendations.dart';
import '../utils/credit_display_utils.dart';
import 'credits_provider.dart';

/// Pre-computed dashboard data — memoized by Riverpod and recomputed only
/// when `creditsProvider` emits a new value. Keeps all O(n) loops out of
/// build methods so the dashboard frame budget stays on layout/paint.
class DashboardData {
  final List<Credit> activeCredits;
  final double progressPct;
  final List<PendingPayment> upcoming;
  final PaymentWeekSummary weekSummary;
  final FinancialRecommendation recommendation;

  const DashboardData({
    required this.activeCredits,
    required this.progressPct,
    required this.upcoming,
    required this.weekSummary,
    required this.recommendation,
  });
}

final dashboardDataProvider = Provider<DashboardData?>((ref) {
  final credits = ref.watch(creditsProvider).valueOrNull;
  if (credits == null) return null;

  final activeCredits = credits.where(creditHasUnpaid).toList();
  final progressPct = getLoansProgressPercent(credits);
  final upcoming = buildPendingPayments(credits);
  final weekSummary = buildPaymentWeekSummary(upcoming);
  final recommendation = buildPrimaryRecommendation(credits);

  return DashboardData(
    activeCredits: activeCredits,
    progressPct: progressPct,
    upcoming: upcoming,
    weekSummary: weekSummary,
    recommendation: recommendation,
  );
});
