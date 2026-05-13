package com.example.expense_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.service.notification.NotificationListenerService
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(
        context: Context,
        intent: Intent
    ) {
        Log.d("BootReceiver",
            "📡 Received: ${intent.action}")

        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.miui.intent.action.HIDDEN_APPS_CONFIG_CHANGED",
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_PACKAGE_REPLACED -> {
                try {
                    // Request rebind NotificationListenerService
                    val componentName =
                        android.content.ComponentName(
                            context,
                            AppNotificationListenerService
                                ::class.java
                        )
                    NotificationListenerService
                        .requestRebind(componentName)
                    Log.d("BootReceiver",
                        "✅ Requested service rebind")
                } catch (e: Exception) {
                    Log.e("BootReceiver",
                        "❌ Rebind failed: $e")
                }
            }
        }
    }
}