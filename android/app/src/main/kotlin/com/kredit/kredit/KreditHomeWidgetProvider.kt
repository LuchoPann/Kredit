package com.kredit.kredit

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/// Home screen widget showing total debt + next upcoming payment.
///
/// Data is written by `lib/services/home_widget_service.dart` via the
/// `home_widget` plugin's `HomeWidget.saveWidgetData` (backed by
/// SharedPreferences) and this class simply reads it back out on each
/// `onUpdate` cycle and paints it into `res/layout/kredit_widget_layout.xml`.
class KreditHomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.kredit_widget_layout).apply {
                val totalDebt = widgetData.getString("total_debt", null) ?: "$0"
                val nextPayment = widgetData.getString("next_payment", null)
                    ?: "Sin pagos pendientes"
                setTextViewText(R.id.widget_total_debt_value, totalDebt)
                setTextViewText(R.id.widget_next_payment_value, nextPayment)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
