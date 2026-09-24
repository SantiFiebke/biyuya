package com.sdx.biyuya.widget

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.RadioGroup
import android.widget.Switch
import com.sdx.biyuya.R

/** Config por instancia del widget. Se abre al agregarlo (y al "Reconfigurar" en Android 9+). */
class WidgetConfigActivity : Activity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private lateinit var showSwitch: Switch
    private lateinit var countGroup: RadioGroup

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Si el usuario cancela/atrás, el widget no se agrega.
        setResult(RESULT_CANCELED)
        setContentView(R.layout.widget_config)

        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        showSwitch = findViewById(R.id.config_show_categories)
        countGroup = findViewById(R.id.config_count_group)

        val prefs = WidgetConfigPrefs(applicationContext)
        showSwitch.isChecked = prefs.showCategories(appWidgetId)
        checkCount(prefs.count(appWidgetId))
        applyCountEnabled(showSwitch.isChecked)
        showSwitch.setOnCheckedChangeListener { _, checked -> applyCountEnabled(checked) }

        findViewById<Button>(R.id.config_save).setOnClickListener {
            prefs.save(appWidgetId, showSwitch.isChecked, selectedCount())
            ExpenseWidget.refreshAll(this)
            setResult(
                RESULT_OK,
                Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId),
            )
            finish()
        }
    }

    private fun applyCountEnabled(enabled: Boolean) {
        for (i in 0 until countGroup.childCount) {
            countGroup.getChildAt(i).isEnabled = enabled
        }
    }

    private fun checkCount(count: Int) {
        val id = when (count) {
            1 -> R.id.config_count_1
            2 -> R.id.config_count_2
            3 -> R.id.config_count_3
            else -> R.id.config_count_4
        }
        countGroup.check(id)
    }

    private fun selectedCount(): Int = when (countGroup.checkedRadioButtonId) {
        R.id.config_count_1 -> 1
        R.id.config_count_2 -> 2
        R.id.config_count_3 -> 3
        else -> WidgetConfigPrefs.DEFAULT_COUNT
    }
}