package com.bogste.tripup

import android.app.ActivityManager
import android.content.Context
import android.graphics.Color
import android.os.Build
import android.os.Process
import android.os.SystemClock
import android.view.View
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    /**
     * Edge to edge, like on iOS: the app draws under the see-through status and navigation bars, and keeps its own
     * controls out of them (MediaQuery.padding). From Android 10 Flutter does this itself (SystemUiMode.edgeToEdge, its
     * default for this target SDK); on Android 8 and 9 (the Huawei Y7 runs 8.1) it doesn't, so it's done here, again
     * after every resume, where Flutter puts back its own default. Below 8 the navigation bar stays opaque (see
     * res/values-v26/styles.xml).
     */
    override fun onPostResume() {
        super.onPostResume()
        if (Build.VERSION.SDK_INT in Build.VERSION_CODES.O until Build.VERSION_CODES.Q) {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = window.decorView.systemUiVisibility or
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
            window.navigationBarColor = Color.TRANSPARENT
            // Flutter reads the bars' insets as they first arrive, before the window has its height, and takes the
            // navigation bar for a keyboard (its guess is "over 18% of the height"): ask again once laid out, so the
            // bar comes through as padding (MediaQuery.padding.bottom)
            window.decorView.post { window.decorView.requestApplyInsets() }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The startup timings (lib/startup_timings.dart): when the process started, which phone, which renderer
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tripup/startup").setMethodCallHandler { call, result ->
            when (call.method) {
                "info" -> {
                    val memory = ActivityManager.MemoryInfo()
                    (getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager).getMemoryInfo(memory)
                    val screen = resources.displayMetrics
                    result.success(
                        mapOf(
                            "sinceProcessStart" to (SystemClock.elapsedRealtime() - Process.getStartElapsedRealtime()),
                            "device" to "${Build.MANUFACTURER} ${Build.MODEL}",
                            "android" to "${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})",
                            "cores" to Runtime.getRuntime().availableProcessors(),
                            "ramMb" to memory.totalMem / (1024 * 1024),
                            "screen" to "${screen.widthPixels}×${screen.heightPixels} @${screen.density}x",
                        ),
                    )
                }
                "renderer" -> result.success(renderer())
                else -> result.notImplemented()
            }
        }
    }

    /** The renderer Flutter picked, from the line it logs when it starts; without that line it's Skia. */
    private fun renderer(): String =
        try {
            val log = Runtime.getRuntime().exec(arrayOf("logcat", "-d", "-v", "raw", "--pid=${Process.myPid()}"))
            val line = log.inputStream.bufferedReader().useLines { lines -> lines.lastOrNull { it.contains("rendering backend") } }
            line?.substringAfter("Using the ")?.trimEnd('.') ?: "Skia (no Impeller line in the log)"
        } catch (e: Exception) {
            "unknown (${e.javaClass.simpleName})"
        }
}
