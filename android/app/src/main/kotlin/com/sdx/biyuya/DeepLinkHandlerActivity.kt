package com.sdx.biyuya

import android.app.Activity
import android.content.Intent
import android.os.Bundle

class DeepLinkHandlerActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val incoming = intent ?: run {
            finish()
            return
        }

        val mainIntent = Intent(this, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = incoming.data
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        startActivity(mainIntent)
        finish()
    }
}
