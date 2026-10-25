package com.isdose.nada

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews

class NadaWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        updateAll(context)
    }

    companion object {
        private const val PREFS = "nada_widget"

        fun saveAndUpdate(
            context: Context,
            time: String,
            sessions: Int,
            theme: String
        ) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putString("time", time)
                .putInt("sessions", sessions)
                .putString("theme", theme)
                .apply()
            updateAll(context)
        }

        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, NadaWidgetProvider::class.java)
            val ids = manager.getAppWidgetIds(component)
            for (id in ids) {
                updateWidget(context, manager, id)
            }
        }

        private fun updateWidget(
            context: Context,
            manager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val time = prefs.getString("time", "0 min") ?: "0 min"
            val sessions = prefs.getInt("sessions", 0)
            val light = prefs.getString("theme", "dark") == "light"

            val views = RemoteViews(context.packageName, R.layout.nada_widget)
            views.setTextViewText(R.id.widget_time, time)
            views.setTextViewText(
                R.id.widget_sessions,
                when (sessions) {
                    0 -> "0 sesiones"
                    1 -> "1 sesión"
                    else -> "$sessions sesiones"
                }
            )
            views.setInt(
                R.id.widget_root,
                "setBackgroundResource",
                if (light) R.drawable.widget_bg_light else R.drawable.widget_bg_dark
            )

            val primary = if (light) Color.BLACK else Color.rgb(242, 239, 230)
            val secondary = if (light) Color.rgb(74, 69, 61) else Color.rgb(166, 160, 150)
            views.setTextColor(R.id.widget_wordmark, if (light) Color.BLACK else primary)
            views.setTextColor(R.id.widget_phrase, secondary)
            views.setTextColor(R.id.widget_time, primary)
            views.setTextColor(R.id.widget_sessions, secondary)

            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            manager.updateAppWidget(appWidgetId, views)
        }
    }
}
