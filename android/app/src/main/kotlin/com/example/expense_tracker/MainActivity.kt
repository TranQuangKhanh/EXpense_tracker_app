package com.example.expense_tracker

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.expense_tracker/notification"
    private val ENGINE_ID = "notification_engine"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
        initBackgroundEngine()
    }

    private fun initBackgroundEngine() {
        if (FlutterEngineCache.getInstance().get(ENGINE_ID) == null) {
            val backgroundEngine = FlutterEngine(this)
            backgroundEngine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
            )
            FlutterEngineCache.getInstance().put(ENGINE_ID, backgroundEngine)
            AppNotificationListenerService.flutterEngine = backgroundEngine
        } else {
            AppNotificationListenerService.flutterEngine =
                FlutterEngineCache.getInstance().get(ENGINE_ID)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Đảm bảo Service luôn lấy Engine từ Cache nếu có, tránh bị null khi thoát app
        val bgEngine = FlutterEngineCache.getInstance().get(ENGINE_ID)
        if (bgEngine != null) {
            AppNotificationListenerService.flutterEngine = bgEngine
        } else {
            AppNotificationListenerService.flutterEngine = flutterEngine
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasPermission" -> {
                    result.success(isNotificationListenerEnabled())
                }
                "openPermissionSettings" -> {
                    openNotificationSettings()
                    result.success(true)
                }
                "openAutoStart" -> {
                    openXiaomiAutoStart()
                    result.success(true)
                }
                "openBatteryOptimization" -> {
                    openBatteryOptimization()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isNotificationListenerEnabled(): Boolean {
        val flat = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners"
        )
        return flat?.contains(packageName) == true
    }

    private fun openNotificationSettings() {
        startActivity(
            Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")
        )
    }

    private fun openXiaomiAutoStart() {
        try {
            val intent = Intent().apply {
                component = android.content.ComponentName(
                    "com.miui.securitycenter",
                    "com.miui.permcenter.autostart.AutoStartManagementActivity"
                )
            }
            startActivity(intent)
        } catch (e: Exception) {
            try {
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:$packageName")
                }
                startActivity(intent)
            } catch (e2: Exception) {
                e2.printStackTrace()
            }
        }
    }

    private fun openBatteryOptimization() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val intent = Intent(
                    Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                ).apply {
                    data = Uri.parse("package:$packageName")
                }
                startActivity(intent)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "notification_listener_channel",
                "Notification Listener",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Theo dõi giao dịch ngân hàng"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
    }
}