package com.example.metro.widgets;

import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.widget.RemoteViews;

import com.example.metro.R;

public class ArrivalWidgetProvider extends AppWidgetProvider {
    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        for (int appWidgetId : appWidgetIds) {
            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.arrival_widget);
            // 初始文字（後續可透過廣播/WorkManager更新）
            views.setTextViewText(R.id.station_name, "台北車站");
            views.setTextViewText(R.id.time_dir1, "2分30秒 · 往 淡水");
            views.setTextViewText(R.id.time_dir2, "4分15秒 · 往 南港");
            appWidgetManager.updateAppWidget(appWidgetId, views);
        }
    }
}