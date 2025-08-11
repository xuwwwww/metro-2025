package com.example.metro

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews

class ArrivalWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.arrival_widget)

            // Read values saved by Flutter (SharedPreferences name is fixed)
            val sp = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val station = sp.getString("flutter.favorite_station_1", "最近站點")
            val dir1 = sp.getString("flutter.arrival_dir1", "往 A")
            val time1 = sp.getString("flutter.arrival_time1", "2分30秒")
            val dir2 = sp.getString("flutter.arrival_dir2", "往 B")
            val time2 = sp.getString("flutter.arrival_time2", "4分15秒")

            views.setTextViewText(R.id.widget_title, "$station 到站")
            views.setTextViewText(R.id.widget_line1, "$time1  $dir1")
            views.setTextViewText(R.id.widget_line2, "$time2  $dir2")

            // Tap widget → open app
            val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            val pIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                else PendingIntent.FLAG_UPDATE_CURRENT
            )
            views.setOnClickPendingIntent(R.id.widget_root, pIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}