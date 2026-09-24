package com.sdx.biyuya.widget

import android.content.Context

/** Persistencia de la configuración por instancia de widget (appWidgetId). */
class WidgetConfigPrefs(context: Context) {
    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun showCategories(appWidgetId: Int): Boolean =
        prefs.getBoolean("show_categories_$appWidgetId", true)

    fun count(appWidgetId: Int): Int =
        prefs.getInt("count_$appWidgetId", DEFAULT_COUNT).coerceIn(1, MAX_COUNT)

    fun save(appWidgetId: Int, showCategories: Boolean, count: Int) {
        prefs.edit()
            .putBoolean("show_categories_$appWidgetId", showCategories)
            .putInt("count_$appWidgetId", count.coerceIn(1, MAX_COUNT))
            .apply()
    }

    fun clear(appWidgetIds: IntArray) {
        val editor = prefs.edit()
        appWidgetIds.forEach { id ->
            editor.remove("show_categories_$id").remove("count_$id")
        }
        editor.apply()
    }

    companion object {
        private const val PREFS_NAME = "widget_config"
        const val DEFAULT_COUNT = 4
        const val MAX_COUNT = 4 // keep in sync with kFeaturedCategoryCount
    }
}