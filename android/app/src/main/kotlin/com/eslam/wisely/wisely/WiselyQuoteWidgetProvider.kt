package com.eslam.wisely.wisely

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject

class WiselyQuoteWidgetProvider : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      val views = RemoteViews(context.packageName, R.layout.wisely_quote_widget)
      val payload = widgetData.getString("widget_payload", null)
      val json = payload?.let { JSONObject(it) }
      val mood = json?.optString("mood", "happy") ?: "happy"
      val quote = json?.optString("text", "Open Selvator to load a quote.")
          ?: "Open Selvator to load a quote."
      val author = json?.optString("author", "Selvator")
          ?.takeIf { it.isNotBlank() }
          ?: "Selvator"
      val accent = resolveAccentColor(mood)

      views.setTextViewText(R.id.widget_brand, "Selvator")
      views.setTextViewText(R.id.widget_mood, formatMood(mood))
      views.setTextViewText(R.id.widget_quote, quote)
      views.setTextViewText(R.id.widget_author, "— $author")
      views.setTextViewText(R.id.widget_hint, "Tap to open")
      views.setTextColor(R.id.widget_mood, accent)
      views.setInt(R.id.widget_accent, "setBackgroundColor", accent)
      views.setOnClickPendingIntent(
          R.id.widget_root,
          HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
      )

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }

  private fun formatMood(mood: String): String {
    return mood.replace('_', ' ').replaceFirstChar { it.uppercase() }
  }

  private fun resolveAccentColor(mood: String): Int {
    return when (mood) {
      "happy" -> Color.parseColor("#F4A259")
      "calm" -> Color.parseColor("#5C8D89")
      "motivated" -> Color.parseColor("#DC6B19")
      "love" -> Color.parseColor("#CE6A85")
      "hopeful" -> Color.parseColor("#87A96B")
      "reflective" -> Color.parseColor("#6D597A")
      "confident" -> Color.parseColor("#F39B3D")
      "grateful" -> Color.parseColor("#E7C96E")
      "tired" -> Color.parseColor("#A7B3C7")
      "focused" -> Color.parseColor("#67C7C0")
      "anxious" -> Color.parseColor("#89C6CC")
      "stressed" -> Color.parseColor("#6FA6A7")
      "nostalgic" -> Color.parseColor("#D9B6A3")
      "sad" -> Color.parseColor("#8FA9C8")
      "lonely" -> Color.parseColor("#B39CCB")
      else -> Color.parseColor("#6C8D57")
    }
  }
}
