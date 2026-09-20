package com.setupsworks.aiexpensetracker

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetLaunchIntent

/**
 * Home-screen widget showing this month's budget progress. Tapping opens the
 * app on the Budgets tab.
 */
class BudgetWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = HomeWidgetPlugin.getData(context)
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.budget_widget).apply {
                val headline = prefs.getString("budgetHeadline", "Set a budget in the app") ?: "—"
                val remaining = prefs.getString("budgetRemainingLabel", "") ?: ""
                val percent = (prefs.getString("budgetPercent", "0") ?: "0").toIntOrNull() ?: 0
                setTextViewText(R.id.widget_budget_headline, headline)
                setTextViewText(R.id.widget_budget_remaining, remaining)
                setProgressBar(R.id.widget_budget_progress, 100, percent.coerceIn(0, 100), false)

                val openApp = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    android.net.Uri.parse("aiexpense://budgets")
                )
                setOnClickPendingIntent(R.id.widget_root, openApp)
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
