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
Future<void> updateHomeWidget(List<Credit> credits) async {
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

  await HomeWidget.updateWidget(
    name: _androidWidgetName,
    androidName: _androidWidgetName,
  );
}
