import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../data/models/credit.dart';
import '../domain/credit_calculator.dart';
import '../domain/upcoming_payment.dart';
import '../utils/credit_display_utils.dart';

/// Android App Widget name registered in
/// `android/app/src/main/kotlin/.../KreditHomeWidgetProvider.kt` and
/// `AndroidManifest.xml`.
const _androidWidgetName = 'KreditHomeWidgetProvider';

/// Pushes the current total debt, % paid and next upcoming payment into the
/// SharedPreferences-backed storage that `home_widget` shares with the
/// native Android home screen widget, then asks Android to redraw it.
///
/// Mirrors `totalUnpaidProvider` (credits_provider.dart), the
/// upcoming-payment scan from dashboard_screen.dart's `_buildUpcomingItems`
/// (via `findNextUpcomingPayment`), and `getLoansProgressPercent` (used for
/// the dashboard's own progress ring), without touching those restricted
/// files.
///
/// The Android home/lock screen shows this widget WITHOUT requiring the
/// app's PIN/biometric unlock, so real amounts must never be written unless
/// the user has explicitly opted in via `widgetPrivacyProvider`
/// (`showAmountsInWidget`, default `false`). When [showAmounts] is `false`
/// the widget still updates — it just gets generic, amount-free text and
/// hides the % pagado row entirely (a percentage alone doesn't leak much,
/// but it's still derived from real balances, so it follows the same
/// privacy switch as the rest of the figures).
Future<void> updateHomeWidget(
  List<Credit> credits, {
  required bool showAmounts,
  Color accentColor = const Color(0xFFFFFFFF),
  String bgTone = 'pure',
}) async {
  await HomeWidget.saveWidgetData<String>(
    'accent_color',
    '#${accentColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
  );
  await HomeWidget.saveWidgetData<String>('bg_tone', bgTone);

  if (showAmounts) {
    final totalDebt = credits.fold<double>(
      0.0,
      (sum, c) => sum + getCreditRemainingBalance(c),
    );
    await HomeWidget.saveWidgetData<String>('total_debt', formatCOP(totalDebt));

    final progressPct = getLoansProgressPercent(credits);
    await HomeWidget.saveWidgetData<int>(
      'progress_percent',
      credits.whereType<LoanCredit>().isEmpty ? -1 : progressPct.round(),
    );

    final next = findNextUpcomingPayment(credits);
    if (next != null) {
      await HomeWidget.saveWidgetData<String>('next_payment_name', next.credit.name);
      await HomeWidget.saveWidgetData<String>('next_payment_amount', formatCOP(next.amount));
      await HomeWidget.saveWidgetData<String>(
        'next_payment_date',
        formatRelativeDate(next.dueDate),
      );
    } else {
      await HomeWidget.saveWidgetData<String>('next_payment_name', 'Sin pagos pendientes');
      await HomeWidget.saveWidgetData<String>('next_payment_amount', '');
      await HomeWidget.saveWidgetData<String>('next_payment_date', '');
    }
  } else {
    final activeCount = credits.length;
    await HomeWidget.saveWidgetData<String>(
      'total_debt',
      activeCount == 0
          ? 'Sin créditos activos'
          : '$activeCount crédito${activeCount == 1 ? '' : 's'} activo${activeCount == 1 ? '' : 's'}',
    );
    await HomeWidget.saveWidgetData<int>('progress_percent', -1);

    final next = findNextUpcomingPayment(credits);
    await HomeWidget.saveWidgetData<String>(
      'next_payment_name',
      next != null ? 'Tienes pagos pendientes' : 'Sin pagos pendientes',
    );
    await HomeWidget.saveWidgetData<String>('next_payment_amount', '');
    await HomeWidget.saveWidgetData<String>('next_payment_date', '');
  }

  await HomeWidget.updateWidget(
    name: _androidWidgetName,
    androidName: _androidWidgetName,
  );
}
