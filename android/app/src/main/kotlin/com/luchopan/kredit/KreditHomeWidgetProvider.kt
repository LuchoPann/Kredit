package com.luchopan.kredit

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/// Home screen widget showing total debt, % paid, and next upcoming
/// payment — matched to the tono/acento the user picked in Cuenta >
/// Personalización.
///
/// Data is written by `lib/services/home_widget_service.dart` via the
/// `home_widget` plugin's `HomeWidget.saveWidgetData` (backed by
/// SharedPreferences) and this class simply reads it back out on each
/// `onUpdate` cycle and paints it into `res/layout/kredit_widget_layout.xml`.
/// Tapping anywhere on the widget opens `MainActivity`.
class KreditHomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.kredit_widget_layout).apply {
                // Tono de fondo — mismas 3 variantes que Cuenta >
                // Personalización > Variante de Tema Oscuro
                // (pure/cool/warm en app_theme.dart), elegido con
                // setBackgroundResource en vez de un color fijo para
                // conservar las esquinas redondeadas del drawable.
                val bgResId = when (widgetData.getString("bg_tone", "pure")) {
                    "cool" -> R.drawable.kredit_widget_background_cool
                    "warm" -> R.drawable.kredit_widget_background_warm
                    else -> R.drawable.kredit_widget_background_pure
                }
                setInt(R.id.widget_root, "setBackgroundResource", bgResId)

                // Color de acento del usuario (7 opciones en Cuenta) —
                // aplicado a los elementos que actúan como "cifra
                // protagonista", igual que en el resto de la app.
                val accentColor = try {
                    Color.parseColor(widgetData.getString("accent_color", "#FFFFFF") ?: "#FFFFFF")
                } catch (_: IllegalArgumentException) {
                    Color.WHITE
                }
                setTextColor(R.id.widget_total_debt_value, accentColor)
                setTextColor(R.id.widget_next_payment_amount, accentColor)

                val totalDebt = widgetData.getString("total_debt", null) ?: "$0"
                setTextViewText(R.id.widget_total_debt_value, totalDebt)

                // % pagado — solo tiene sentido con préstamos de cuotas
                // fijas; se oculta la fila entera cuando no aplica (p. ej.
                // solo hay tarjetas, o el usuario desactivó ver montos).
                val progressPercent = widgetData.getInt("progress_percent", -1)
                if (progressPercent in 0..100) {
                    setViewVisibility(R.id.widget_progress_group, View.VISIBLE)
                    setProgressBar(R.id.widget_progress_bar, 100, progressPercent, false)
                    setTextViewText(R.id.widget_progress_label, "$progressPercent% pagado")
                } else {
                    setViewVisibility(R.id.widget_progress_group, View.GONE)
                }

                val nextName = widgetData.getString("next_payment_name", null)
                    ?: "Sin pagos pendientes"
                val nextAmount = widgetData.getString("next_payment_amount", "") ?: ""
                val nextDate = widgetData.getString("next_payment_date", "") ?: ""
                setTextViewText(R.id.widget_next_payment_name, nextName)
                setTextViewText(R.id.widget_next_payment_amount, nextAmount)
                setTextViewText(R.id.widget_next_payment_date, nextDate)

                // Todo el widget es clicable y abre la app — antes no
                // tenía ningún PendingIntent asociado.
                val openAppIntent = context.packageManager
                    .getLaunchIntentForPackage(context.packageName)
                    ?.apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    openAppIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
