package com.sdx.biyuya.widget.data

import android.content.Context
import com.sdx.biyuya.widget.model.WidgetCategory

/**
 * Local cache for widget categories.
 * Stores categories in SharedPreferences so the widget can
 * display them without network calls.
 *
 * Categories are synced FROM Flutter (which reads from Supabase)
 * TO this cache. The widget only reads from here.
 */
object CategoryCache {

    // Flutter shared_preferences writes to FlutterSharedPreferences.xml
    // with flutter. prefix on all keys.
    private const val PREFS_NAME = "FlutterSharedPreferences"
    private const val KEY_CATEGORIES = "flutter.widget_categories"

    private fun getPrefs(context: Context) =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    /**
     * Returns cached categories, or empty list if none cached.
     */
    fun getCategories(context: Context): List<WidgetCategory> {
        val json = getPrefs(context).getString(KEY_CATEGORIES, null) ?: return emptyList()
        return WidgetCategory.listFromJson(json)
    }

    /**
     * Overwrites the category cache with new data.
     * Called by Flutter when categories are loaded/updated.
     */
    fun saveCategories(context: Context, categories: List<WidgetCategory>) {
        getPrefs(context)
            .edit()
            .putString(KEY_CATEGORIES, WidgetCategory.listToJson(categories))
            .apply()
    }

    /**
     * Clears the cache. Useful on logout.
     */
    fun clear(context: Context) {
        getPrefs(context).edit().remove(KEY_CATEGORIES).apply()
    }
}
