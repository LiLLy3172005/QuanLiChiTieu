package vn.edu.vku.vku_expense_ocr

import android.content.Context
import android.os.BatteryManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Native Implementation: Android (Kotlin) theo đúng Slide 38 VKU Week 8
class MainActivity : FlutterActivity() {
    private val CHANNEL = "vn.edu.vku/device_info"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getBatteryLevel") {
                    val bm = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
                    val batteryLevel = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
                    result.success(batteryLevel)
                } else {
                    result.notImplemented()
                }
            }
    }
}
