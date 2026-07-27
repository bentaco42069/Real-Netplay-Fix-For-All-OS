package com.bentaco.flashmax

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * The home-screen widget. Shows a little flashlight icon; a tap toggles the
 * torch at maximum brightness and swaps the icon to reflect on/off.
 */
class FlashWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            render(context, appWidgetManager, id)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_TOGGLE) {
            TorchManager.get(context).toggleMax()
            updateAll(context)
        }
    }

    private fun render(context: Context, manager: AppWidgetManager, widgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.widget_flash)

        val on = TorchManager.get(context).isOn
        views.setImageViewResource(
            R.id.widget_icon,
            if (on) R.drawable.ic_flashlight_on else R.drawable.ic_flashlight_off
        )

        val toggleIntent = Intent(context, FlashWidgetProvider::class.java).apply {
            action = ACTION_TOGGLE
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        val pending = PendingIntent.getBroadcast(context, 0, toggleIntent, flags)
        views.setOnClickPendingIntent(R.id.widget_root, pending)

        manager.updateAppWidget(widgetId, views)
    }

    companion object {
        const val ACTION_TOGGLE = "com.bentaco.flashmax.TOGGLE"

        /** Re-render every placed instance of the widget. */
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, FlashWidgetProvider::class.java)
            )
            if (ids.isEmpty()) return
            val provider = FlashWidgetProvider()
            for (id in ids) {
                provider.render(context, manager, id)
            }
        }
    }
}
