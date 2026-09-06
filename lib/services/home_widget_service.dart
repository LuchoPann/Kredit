import 'package:home_widget/home_widget.dart';

import '../data/models/credit.dart';
import '../domain/credit_calculator.dart';
import '../domain/upcoming_payment.dart';
import '../utils/credit_display_utils.dart';

/// Android App Widget name registered in
/// `android/app/src/main/kotlin/com/kredit/kredit/KreditHomeWidgetProvider.kt`
/// and `AndroidManifest.xml`.
const _androidWidgetName = 'KreditHomeWidgetProvider';

/// Pushes the current total debt + next upcoming payment into the
/// SharedPreferences-backed storage that `home_widget` shares with the
/// native Android home screen widget, then asks Android to redraw it.
///
/// Mirrors `totalUnpaidProvider` (credits_provider.dart) and the
/// upcoming-payment scan from dashboard_screen.dart's `_buildUpcomingItems`
/// (via `findNextUpcomingPayment`), without touching either restricted file.
///
/// The Android home/lock screen shows this widget WITHOUT requiring the
/// app's PIN/biometric unlock, so real amounts must never be written unless
/// the user has explicitly opted in via `widgetPrivacyProvider`
/// (`showAmountsInWidget`, default `false`). When [showAmounts] is `false`
/// the widget still updates — it just gets generic, amount-free text
/// instead of the real balance/next-payment figures.
Future<void> updateHomeWidget(
  List<Credit> credits, {
  required bool showAmounts,
}) async {
  if (showAmounts) {
    final totalDebt = credits.fold<double>(
      0.0,
      (sum, c) => sum + getCreditRemainingBalance(c),
    );

    final next = findNextUpcomingPayment(credits);

    await HomeWidget.saveWidgetData<String>('total_debt', formatCOP(totalDebt));

    if (next != null) {
      final dateLabel =
          '${next.dueDate.day.toString().padLeft(2, '0')}/'
          '${next.dueDate.month.toString().padLeft(2, '0')}/'
          '${next.dueDate.year}';
      await HomeWidget.saveWidgetData<String>(
        'next_payment',
        '${next.credit.name} • ${formatCOP(next.amount)} • $dateLabel',
      );
    } else {
      await HomeWidget.saveWidgetData<String>('next_payment', 'Sin pagos pendientes');
    }
  } else {
    final activeCount = credits.length;
    await HomeWidget.saveWidgetData<String>(
      'total_debt',
      activeCount == 0
          ? 'Sin créditos activos'
          : '$activeCount crédito${activeCount == 1 ? '' : 's'} activo${activeCount == 1 ? '' : 's'}',
    );

    final next = findNextUpcomingPayment(credits);
    await HomeWidget.saveWidgetData<String>(
      'next_payment',
      next != null ? 'Tienes pagos pendientes' : 'Sin pagos pendientes',
    );
  }

  await HomeWidget.updateWidget(
    name: _androidWidgetName,
    androidName: _androidWidgetName,
  );
}
