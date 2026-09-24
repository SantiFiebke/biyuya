package com.sdx.biyuya

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.sdx.biyuya.widget.ExpenseWidget

class MainActivity : FlutterActivity() {
    private val CHANNEL = "biyuya/widget"

    // Deep links are handled in Dart via app_links. Returning the raw ACTION_VIEW
    // data URI here makes GoRouter treat it as the initial location (no routes)
    // and duplicates navigation with app_links.
    override fun getInitialRoute(): String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "refresh") {
                    ExpenseWidget.refreshAll(this)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
