package com.setupsworks.aiexpensetracker

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent

/**
 * Minimal one-tap widget: opens straight into the add-expense flow. No data
 * to display, so it never needs a [HomeWidgetPlugin] refresh.
 */
class QuickAddWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.quick_add_widget).apply {
                val addIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    android.net.Uri.parse("aiexpense://add")
                )
                setOnClickPendingIntent(R.id.widget_root, addIntent)
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
