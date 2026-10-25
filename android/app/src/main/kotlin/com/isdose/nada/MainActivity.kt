package com.isdose.nada

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.media.AudioAttributes
import android.media.SoundPool
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var soundPool: SoundPool? = null
    private var chimeId = 0
    private var chimeReady = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        setupSound()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nada/sound")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "play" -> {
                        val pool = soundPool
                        if (pool != null && chimeReady) {
                            pool.play(chimeId, 0.78f, 0.78f, 1, 0, 1f)
                            Log.d("nada", "chime played")
                            result.success(true)
                        } else {
                            Log.d("nada", "chime not ready")
                            result.success(false)
                        }
                    }

                    else -> result.notImplemented()
                }
            }

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

    private fun setupSound() {
        if (soundPool != null) return
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val pool = SoundPool.Builder()
            .setMaxStreams(1)
            .setAudioAttributes(attributes)
            .build()
        pool.setOnLoadCompleteListener { _, sampleId, status ->
            if (status == 0) {
                chimeId = sampleId
                chimeReady = true
                Log.d("nada", "chime loaded")
            } else {
                Log.w("nada", "chime load failed: $status")
            }
        }
        chimeId = pool.load(this, R.raw.nada_chime, 1)
        soundPool = pool
    }

    override fun onDestroy() {
        soundPool?.release()
        soundPool = null
        super.onDestroy()
    }
}
