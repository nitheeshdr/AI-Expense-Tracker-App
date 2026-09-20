package com.setupsworks.aiexpensetracker

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetLaunchIntent

/**
 * Home-screen widget mirroring the app's blue "Net this month" hero card:
 * net income minus expense, plus the income/expense split.
 */
class NetWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = HomeWidgetPlugin.getData(context)
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.net_widget).apply {
                setTextViewText(R.id.widget_net_value, prefs.getString("netValue", "—") ?: "—")
                setTextViewText(R.id.widget_net_income, prefs.getString("netIncomeLabel", "Income —") ?: "Income —")
                setTextViewText(R.id.widget_net_expense, prefs.getString("netExpenseLabel", "Expense —") ?: "Expense —")

                val openApp = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_root, openApp)
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
