package com.setupsworks.aiexpensetracker

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetLaunchIntent

/**
 * Home-screen widget showing today's and this month's spending. Tapping the
 * card opens the app; tapping "Add" opens the app on the add-expense flow.
 */
class ExpenseWidgetProvider : android.appwidget.AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = HomeWidgetPlugin.getData(context)
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.expense_widget).apply {
                val today = prefs.getString("today", "—") ?: "—"
                val month = prefs.getString("month", "Spent —") ?: "Spent —"
                val income = prefs.getString("income", "Income —") ?: "Income —"
                val currency = prefs.getString("currency", "₹") ?: "₹"
                setTextViewText(R.id.widget_today_value, today)
                setTextViewText(R.id.widget_month_value, month)
                setTextViewText(R.id.widget_income_value, income)
                setTextViewText(R.id.widget_currency, currency)

                // Tint the Add button to match the app's accent color.
                val accentHex = prefs.getString("accent", "#FF7C6BFF") ?: "#FF7C6BFF"
                try {
                    val accent = android.graphics.Color.parseColor(accentHex)
                    setInt(R.id.widget_add, "setBackgroundColor", accent)
                } catch (_: Exception) { }

                // Open app on tap
                val openApp = HomeWidgetLaunchIntent.getActivity(
                    context, MainActivity::class.java
                )
                setOnClickPendingIntent(R.id.widget_root, openApp)

                // Open add-expense via deep link
                val addIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    android.net.Uri.parse("aiexpense://add")
                )
                setOnClickPendingIntent(R.id.widget_add, addIntent)
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
