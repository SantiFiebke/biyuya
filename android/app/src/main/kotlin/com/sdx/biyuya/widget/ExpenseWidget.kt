package com.sdx.biyuya.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import android.widget.RemoteViews
import com.sdx.biyuya.R
import java.text.NumberFormat
import java.util.Locale

class ExpenseWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            try {
                renderWidget(context, appWidgetManager, appWidgetId)
            } catch (e: Exception) {
                Log.e("ExpenseWidget", "Error", e)
            }
        }
    }

    companion object {

        fun refreshAll(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val ids = appWidgetManager.getAppWidgetIds(
                ComponentName(context, ExpenseWidget::class.java)
            )
            for (id in ids) {
                try {
                    renderWidget(context, appWidgetManager, id)
                } catch (e: Exception) {
                    Log.e("ExpenseWidget", "refreshAll error", e)
                }
            }
        }

        private fun renderWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_expense)

            // Load today's total from SharedPreferences
            val total = loadDailyTotal(context)
            val formatted = formatCurrency(total)
            views.setTextViewText(R.id.widget_amount, formatted)

            // Button click → open app
            val intent = Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse("biyuya://expense/new")
                setClassName(context.packageName, "com.sdx.biyuya.DeepLinkHandlerActivity")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pi = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_add_button, pi)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun loadDailyTotal(context: Context): Double {
            return try {
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val storedDate = prefs.getString("flutter.widget_daily_date", null)
                val today = java.time.LocalDate.now().toString()

                if (storedDate == today) {
                    prefs.getString("flutter.widget_daily_total", null)?.toDoubleOrNull() ?: 0.0
                } else {
                    0.0
                }
            } catch (e: Exception) {
                0.0
            }
        }

        private fun formatCurrency(amount: Double): String {
            val format = NumberFormat.getCurrencyInstance(Locale("es", "AR"))
            return format.format(amount)
        }
    }
}
