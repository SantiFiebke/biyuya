package com.sdx.biyuya.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.net.Uri
import android.os.Build
import android.util.Log
import android.widget.RemoteViews
import com.sdx.biyuya.R
import org.json.JSONArray
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class ExpenseWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            try {
                renderWidget(context, appWidgetManager, appWidgetId)
            } catch (e: Exception) {
                Log.e("ExpenseWidget", "Error", e)
            }
        }
    }

    // Midnight consistency: DATE_CHANGED / TIME_SET / TIMEZONE_CHANGED force a re-render
    // so the stale daily total resets to 0 (loadDailyTotal returns 0 when date != today).
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED -> refreshAll(context)
        }
    }

    // Drop per-instance config when the widget is removed from the launcher.
    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        WidgetConfigPrefs(context).clear(appWidgetIds)
    }

    companion object {

        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_FEATURED_CATEGORIES = "flutter.widget_featured_categories"
        private const val MAX_CHIPS = 4 // keep in sync with kFeaturedCategoryCount

        private data class FeaturedCategory(
            val id: Int,
            val name: String,
            val color: String,
            val icon: Int
        )

        @Volatile
        private var materialTypeface: Typeface? = null

        @Volatile
        private var materialTypefaceLoaded = false

        fun refreshAll(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val ids = appWidgetManager.getAppWidgetIds(
                ComponentName(context, ExpenseWidget::class.java)
            )
            for (id in ids) {
                try {
                    renderWidget(context, appWidgetManager, id)
                } catch (e: Exception) {
                    Log.e("ExpenseWidget", "refreshAll error", e)
                }
            }
        }

        private fun renderWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_expense)

            // Load today's total from SharedPreferences
            val total = loadDailyTotal(context)
            val formatted = formatCurrency(total)
            views.setTextViewText(R.id.widget_amount, formatted)

            // Featured category chips (per-instance config: show/hide + count 1..4)
            views.removeAllViews(R.id.widget_category_row)
            val config = WidgetConfigPrefs(context)
            val chipLimit = if (config.showCategories(appWidgetId)) {
                minOf(MAX_CHIPS, config.count(appWidgetId))
            } else {
                0
            }
            loadFeaturedCategories(context, chipLimit).forEachIndexed { index, category ->
                val chip = RemoteViews(context.packageName, R.layout.widget_category_chip)
                val iconSizePx = (24 * context.resources.displayMetrics.density).toInt()
                chip.setImageViewBitmap(
                    R.id.widget_category_icon,
                    renderIconBitmap(context, category, iconSizePx)
                )

                val color = parseColor(category.color)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    chip.setColorStateList(
                        R.id.widget_category_chip,
                        "setBackgroundTintList",
                        ColorStateList.valueOf(color)
                    )
                } else {
                    // ponytail: pre-API31 fallback drops the rounded shape; only path available
                    chip.setInt(R.id.widget_category_chip, "setBackgroundColor", color)
                }

                chip.setContentDescription(R.id.widget_category_chip, category.name)

                val chipIntent = Intent(Intent.ACTION_VIEW).apply {
                    data = Uri.parse("biyuya://expense/new?categoryId=${category.id}")
                    setClassName(context.packageName, "com.sdx.biyuya.DeepLinkHandlerActivity")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val chipPi = PendingIntent.getActivity(
                    context, index, chipIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                chip.setOnClickPendingIntent(R.id.widget_category_chip, chipPi)

                views.addView(R.id.widget_category_row, chip)
            }

            // Add button → open expense form (no category)
            val addIntent = Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse("biyuya://expense/new")
                setClassName(context.packageName, "com.sdx.biyuya.DeepLinkHandlerActivity")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val addPi = PendingIntent.getActivity(
                context, 100, addIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_add_button, addPi)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun loadFeaturedCategories(context: Context, limit: Int): List<FeaturedCategory> {
            return try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val raw = prefs.getString(KEY_FEATURED_CATEGORIES, null) ?: return emptyList()
                val array = JSONArray(raw)
                (0 until minOf(array.length(), limit)).mapNotNull { i ->
                    val obj = array.optJSONObject(i) ?: return@mapNotNull null
                    val id = obj.optInt("id", -1)
                    if (id <= 0) return@mapNotNull null
                    FeaturedCategory(
                        id = id,
                        name = obj.optString("name", ""),
                        color = obj.optString("color", ""),
                        icon = obj.optInt("icon", 0)
                    )
                }
            } catch (e: Exception) {
                Log.e("ExpenseWidget", "featured categories parse error", e)
                emptyList()
            }
        }

        /// MaterialIcons is bundled under assets/flutter_assets/fonts. Cache it so we
        /// don't re-read the OTF on every render; a failed read stays null.
        private fun materialIconsTypeface(context: Context): Typeface? {
            if (!materialTypefaceLoaded) {
                materialTypeface = try {
                    Typeface.createFromAsset(
                        context.assets,
                        "flutter_assets/fonts/MaterialIcons-Regular.otf"
                    )
                } catch (e: Exception) {
                    Log.e("ExpenseWidget", "MaterialIcons typeface load failed", e)
                    null
                }
                materialTypefaceLoaded = true
            }
            return materialTypeface
        }

        /// RemoteViews can't setTypeface on a TextView, so draw the icon glyph into a
        /// Bitmap and let the ImageView show it. Falls back to the name's initial.
        private fun renderIconBitmap(
            context: Context,
            category: FeaturedCategory,
            sizePx: Int
        ): Bitmap {
            val size = sizePx.coerceAtLeast(1)
            val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.WHITE
                textAlign = Paint.Align.CENTER
            }

            val typeface = if (category.icon > 0) materialIconsTypeface(context) else null
            val text: String
            if (typeface != null) {
                paint.typeface = typeface
                paint.textSize = size * 0.62f
                text = String(Character.toChars(category.icon))
            } else {
                paint.typeface = Typeface.DEFAULT_BOLD
                paint.textSize = size * 0.5f
                text = category.name.trim().take(1).uppercase(Locale.getDefault())
            }

            val metrics = paint.fontMetrics
            val y = size / 2f - (metrics.ascent + metrics.descent) / 2f
            canvas.drawText(text, size / 2f, y, paint)
            return bitmap
        }

        private fun parseColor(hex: String): Int {
            return try {
                Color.parseColor(hex)
            } catch (e: Exception) {
                Color.GRAY
            }
        }

        private fun loadDailyTotal(context: Context): Double {
            return try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val storedDate = prefs.getString("flutter.widget_daily_date", null)
                // API 24-safe: java.time.LocalDate requires API 26.
                val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())

                if (storedDate == today) {
                    prefs.getString("flutter.widget_daily_total", null)?.toDoubleOrNull() ?: 0.0
                } else {
                    0.0
                }
            } catch (e: Exception) {
                0.0
            }
        }

        private fun formatCurrency(amount: Double): String {
            // forLanguageTag avoids the deprecated Locale(String, String)
            // constructor while keeping the es-AR currency format.
            val format = NumberFormat.getCurrencyInstance(Locale.forLanguageTag("es-AR"))
            return format.format(amount)
        }
    }
}
