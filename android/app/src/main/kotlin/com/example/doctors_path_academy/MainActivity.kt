package com.example.doctors_path_academy

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.telephony.TelephonyManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlin.system.exitProcess

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.doctors_path_academy/security"

    override fun onCreate(savedInstanceState: Bundle?) {
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        super.onCreate(savedInstanceState)

        if (isEmulatorHardwareCheck()) {
            finish()
            exitProcess(0)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isDeveloperModeEnabled" -> result.success(isDeveloperModeEnabled())
                "isUsbDebuggingEnabled" -> result.success(isUsbDebuggingEnabled())
                "isEmulator" -> result.success(isEmulatorHardwareCheck())
                "isEgyptianSimPresent" -> result.success(isEgyptianSimPresent())
                "getBatteryStatus" -> result.success(getBatteryStatus()) // New method for battery monitoring
                else -> result.notImplemented()
            }
        }
    }

    private fun isDeveloperModeEnabled(): Boolean {
        return Settings.Global.getInt(this.contentResolver, Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0) != 0
    }

    private fun isUsbDebuggingEnabled(): Boolean {
        return Settings.Global.getInt(this.contentResolver, Settings.Global.ADB_ENABLED, 0) != 0
    }
    
    // Returns a map containing battery level and charging status.
    private fun getBatteryStatus(): Map<String, Any> {
        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        val isCharging = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            batteryManager.isCharging
        } else {
            val intent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            val status = intent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
            status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL
        }
        return mapOf("level" to batteryLevel, "isCharging" to isCharging)
    }

    private fun isEmulatorByBattery(): Boolean {
        val status = getBatteryStatus()
        val level = status["level"] as? Int
        val isCharging = status["isCharging"] as? Boolean
        return level == 100 && isCharging == true
    }

    private fun isEgyptianSimPresent(): Boolean {
        val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        if (telephonyManager.simState != TelephonyManager.SIM_STATE_READY) {
            return false
        }
        val networkOperatorName = telephonyManager.networkOperatorName.lowercase()
        val egyptianCarriers = listOf("we", "orange", "etisalat", "vodafone")
        return egyptianCarriers.any { networkOperatorName.contains(it) }
    }

    private fun isEmulatorHardwareCheck(): Boolean {
        return (isEmulatorByBattery()
                || Build.FINGERPRINT.startsWith("generic")
                || Build.FINGERPRINT.startsWith("unknown")
                || Build.MODEL.contains("google_sdk")
                || Build.MODEL.contains("Emulator")
                || Build.MODEL.contains("Android SDK built for x86")
                || Build.MANUFACTURER.contains("Genymotion")
                || (Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic"))
                || "google_sdk" == Build.PRODUCT
                || Build.HARDWARE.contains("goldfish")
                || Build.HARDWARE.contains("ranchu")
                || Build.HARDWARE.contains("vbox86")
                || checkPipes() 
                || checkQEmuDrivers())
    }

    private fun checkPipes(): Boolean {
        val pipes = arrayOf("/dev/socket/qemud", "/dev/qemu_pipe")
        for (pipe in pipes) {
            if (File(pipe).exists()) return true
        }
        return false
    }

    private fun checkQEmuDrivers(): Boolean {
        val drivers = arrayOf("/system/lib/kernel/goldfish.ko", "/system/lib64/kernel/goldfish.ko")
        for (driver in drivers) {
            if (File(driver).exists()) return true
        }
        return false
    }
}
