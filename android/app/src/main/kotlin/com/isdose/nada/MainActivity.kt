package com.isdose.nada

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nada/widget")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "update" -> {
                        val time = call.argument<String>("time") ?: "0 min"
                        val sessions = call.argument<Int>("sessions") ?: 0
                        val theme = call.argument<String>("theme") ?: "dark"
                        NadaWidgetProvider.saveAndUpdate(this, time, sessions, theme)
                        result.success(null)
                    }

                    "pin" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val manager = AppWidgetManager.getInstance(this)
                            val provider = ComponentName(this, NadaWidgetProvider::class.java)
                            if (manager.isRequestPinAppWidgetSupported) {
                                result.success(
                                    manager.requestPinAppWidget(provider, null, null)
                                )
                            } else {
                                result.success(false)
                            }
                        } else {
                            result.success(false)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
