package com.example.expense_tracker

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class AppNotificationListenerService : NotificationListenerService() {

    companion object {
        const val TAG = "NotificationListener"
        const val CHANNEL = "com.example.expense_tracker/notification"
        const val NOTIF_CHANNEL_ID = "notification_listener_channel"
        const val NOTIF_ID = 1001
        var flutterEngine: FlutterEngine? = null

        val BANK_PACKAGES = listOf(
            // MoMo — đầy đủ nhất
            "com.mservice.momotransfer",
            "com.mservice.omni",
            "com.mservice",
            "vn.momo.client",
            "vn.momo",
            "com.momo",
            // Vietcombank
            "com.VCB",
            "com.vcb",
            "com.vcb.digibank",
            "com.vietcombank",
            // BIDV
            "com.bidv.smartbanking",
            "com.bidv",
            // Techcombank
            "com.techcombank.mb.app",
            "com.techcombank",
            // MB Bank
            "com.mbmobile",
            "com.mb.mbanking",
            // Vietinbank
            "com.vietinbank.ipay",
            "com.vietinbank",
            // Agribank
            "com.agribank",
            // TPBank
            "com.tpb.mb.gprs",
            "com.tpbank",
            // ACB
            "com.acb.mobile",
            "com.acb",
            // Sacombank
            "com.sacombank",
            // VPBank
            "com.vpbank",
            // ZaloPay
            "vn.com.zalopay",
            "com.zing.zalopay",
            "com.zalopay",
            // VNPay
            "com.vnpay",
            // GrabPay
            "com.grabtaxi.passenger",
            // ShopeePay
            "com.shopee.vn",
            // ViettelPay
            "com.viettelpay",
            "vn.viettel.money",
        )

        val MERCHANT_CATEGORIES = linkedMapOf(
            // Grab — chi tiết trước chung sau
            "grabfood" to "food",
            "grabbike" to "transport",
            "grabcar" to "transport",
            "grab" to "transport",
            // Shopee — chi tiết trước
            "shopeefood" to "food",
            "shopee" to "shopping",
            // Ăn uống
            "baemin" to "food",
            "circle k" to "food",
            "ministop" to "food",
            "gs25" to "food",
            "kfc" to "food",
            "mcdonalds" to "food",
            "jollibee" to "food",
            "highlands" to "food",
            "phuc long" to "food",
            "the coffee house" to "food",
            "starbucks" to "food",
            "pizza" to "food",
            "com tam" to "food",
            "banh mi" to "food",
            "tra sua" to "food",
            "nha hang" to "food",
            "quan an" to "food",
            // Di chuyển
            "gojek" to "transport",
            "be " to "transport",
            "xanh sm" to "transport",
            "taxi" to "transport",
            "petrolimex" to "transport",
            "xang " to "transport",
            "parking" to "transport",
            "vietjet" to "transport",
            "bamboo" to "transport",
            "vietnam airlines" to "transport",
            // Mua sắm
            "lazada" to "shopping",
            "tiki" to "shopping",
            "sendo" to "shopping",
            "winmart" to "shopping",
            "coopmart" to "shopping",
            "aeon" to "shopping",
            // Giải trí
            "netflix" to "entertainment",
            "spotify" to "entertainment",
            "cgv" to "entertainment",
            "lotte cinema" to "entertainment",
            "galaxy cinema" to "entertainment",
            "steam" to "entertainment",
            // Sức khỏe
            "pharmacity" to "health",
            "long chau" to "health",
            "an khang" to "health",
            "guardian" to "health",
            "benh vien" to "health",
            "nha thuoc" to "health",
            // Hóa đơn
            "evn" to "bills",
            "dien luc" to "bills",
            "vnpt" to "bills",
            "viettel" to "bills",
            "mobifone" to "bills",
            "fpt" to "bills",
            "internet" to "bills",
            // Học tập
            "hoc phi" to "education",
            "duolingo" to "education",
            "coursera" to "education",
            // Thu nhập
            "luong" to "salary",
            "salary" to "salary",
            "thuong" to "bonus",
            "bonus" to "bonus",
        )
    }

    private val db = FirebaseFirestore.getInstance()
    private val auth = FirebaseAuth.getInstance()

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForegroundCompat()
        Log.d(TAG, "✅ Service created")
    }

    private fun startForegroundCompat() {
        val notification = NotificationCompat.Builder(this, NOTIF_CHANNEL_ID)
            .setContentTitle("Đang theo dõi giao dịch")
            .setContentText("Tự động ghi nhận giao dịch ngân hàng")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setSilent(true)
            .setOngoing(true)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIF_ID, notification,
                android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            )
        } else {
            startForeground(NOTIF_ID, notification)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIF_CHANNEL_ID, "Notification Listener",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Theo dõi giao dịch ngân hàng"
                setShowBadge(false)
            }
            getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        sbn ?: return

        val packageName = sbn.packageName ?: return
        val isBank = BANK_PACKAGES.any {
            packageName.lowercase().contains(it.lowercase())
        }
        if (!isBank) return

        val extras = sbn.notification?.extras ?: return
        val title = extras.getString("android.title") ?: ""
        val body = extras.getCharSequence("android.text")?.toString() ?: ""
        val bigText = extras.getCharSequence("android.bigText")?.toString() ?: ""
        val fullBody = if (bigText.isNotEmpty()) bigText else body

        Log.d(TAG, "📱 Package: $packageName")
        Log.d(TAG, "📱 Title: $title")
        Log.d(TAG, "📱 Body: $fullBody")

        saveDirectlyToFirestore(packageName, title, fullBody)
        tryNotifyFlutter(packageName, title, fullBody)
    }

    private fun saveDirectlyToFirestore(
        packageName: String,
        title: String,
        body: String
    ) {
        val userId = auth.currentUser?.uid
        if (userId == null) {
            Log.e(TAG, "❌ Không có userId")
            return
        }

        val text = "$title $body".lowercase()
        val bankName = getBankName(packageName)

        // Normalize unicode spaces trước khi parse
        val normalizedText = text
            .replace('\u00A0', ' ')
            .replace('\u202F', ' ')
            .replace('\u2009', ' ')

        val amount = parseAmount(normalizedText)
        if (amount == null || amount <= 0) {
            Log.e(TAG, "❌ Không parse được số tiền: $normalizedText")
            saveDebugLog(userId, packageName, title, body, false, null, null)
            return
        }

        val type = detectType(normalizedText)
        val categoryId = suggestCategory(normalizedText, type)

        Log.d(TAG, "✅ amount=$amount type=$type category=$categoryId")

        saveDebugLog(userId, packageName, title, body, true, amount, type)

        db.collection("expenses").add(
            hashMapOf(
                "title" to "$bankName - ${if (type == "income") "Tiền vào" else "Tiền ra"}",
                "amount" to amount,
                "type" to type,
                "categoryId" to categoryId,
                "date" to FieldValue.serverTimestamp(),
                "userId" to userId,
                "source" to "auto",
                "status" to "pending",
                "bankName" to bankName,
                "originalText" to "$title $body"
            )
        ).addOnSuccessListener {
            Log.d(TAG, "✅ Lưu thành công")
        }.addOnFailureListener { e ->
            Log.e(TAG, "❌ Lỗi: ${e.message}")
        }
    }

    private fun saveDebugLog(
        userId: String,
        packageName: String,
        title: String,
        body: String,
        parsedSuccess: Boolean,
        amount: Double?,
        type: String?
    ) {
        db.collection("debug_logs").add(
            hashMapOf(
                "packageName" to packageName,
                "title" to title,
                "body" to body,
                "isBank" to true,
                "bankName" to getBankName(packageName),
                "parsedSuccess" to parsedSuccess,
                "parsedAmount" to amount,
                "parsedType" to type,
                "timestamp" to FieldValue.serverTimestamp(),
                "userId" to userId,
                "source" to "native_kotlin"
            )
        )
    }

    private fun parseAmount(text: String): Double? {
        // Tách phần trước "số dư"
        val soduKeywords = listOf("số dư", "so du", "sd:", "balance", "so du tk")
        var transactionText = text
        for (keyword in soduKeywords) {
            val idx = text.indexOf(keyword)
            if (idx > 0) {
                transactionText = text.substring(0, idx)
                break
            }
        }

        // Regex bắt nhiều format:
        // "+10,000 VND" / "10.000 đ" / "50000đ" / "10.025 đ"
        val regex = Regex(
            """[+\-]?\s*(\d{1,3}(?:[.,]\d{3})*|\d+)\s*(?:vnd|vnđ|đồng|dong|đ\b|đ\s)""",
            RegexOption.IGNORE_CASE
        )

        // Ưu tiên số có dấu +/- trong phần transaction
        for (match in regex.findAll(transactionText)) {
            val fullMatch = match.value
            if (fullMatch.contains("+") || fullMatch.contains("-")) {
                val raw = match.groupValues[1]
                    .replace(".", "")
                    .replace(",", "")
                val amount = raw.toDoubleOrNull()
                if (amount != null && amount >= 1000) return amount
            }
        }

        // Lấy số đầu tiên trong phần transaction
        for (match in regex.findAll(transactionText)) {
            val raw = match.groupValues[1]
                .replace(".", "")
                .replace(",", "")
            val amount = raw.toDoubleOrNull()
            if (amount != null && amount >= 1000) return amount
        }

        // Fallback: số nhỏ nhất trong toàn text
        var minAmount: Double? = null
        for (match in regex.findAll(text)) {
            val raw = match.groupValues[1]
                .replace(".", "")
                .replace(",", "")
            val amount = raw.toDoubleOrNull()
            if (amount != null && amount >= 1000) {
                if (minAmount == null || amount < minAmount) {
                    minAmount = amount
                }
            }
        }
        return minAmount
    }

    private fun detectType(text: String): String {
        // Tách phần trước "số dư" trước khi detect
        val soduKeywords = listOf("số dư", "so du", "sd:", "balance", "so du tk")
        var transactionText = text
        for (keyword in soduKeywords) {
            val idx = text.indexOf(keyword)
            if (idx > 0) {
                transactionText = text.substring(0, idx)
                break
            }
        }

        val incomeKeywords = listOf(
            "+",
            "nhận", "nhan",
            "cộng", "cong",
            "tiền về", "tien ve",
            "về ví", "ve vi",
            "vào ví", "vao vi",
            "vào tài khoản", "vao tai khoan",
            "received", "credit",
            "nhan tien",
        )

        val expenseKeywords = listOf(
            "-",
            "thanh toán", "thanh toan",
            "trừ", "tru",
            "chuyển đi", "chuyen di",
            "rút", "rut",
            "debit", "payment",
            "chi tiêu", "chi tieu",
        )

        return when {
            incomeKeywords.any { transactionText.contains(it) } -> "income"
            expenseKeywords.any { transactionText.contains(it) } -> "expense"
            else -> "expense"
        }
    }

    private fun suggestCategory(text: String, type: String): String {
        for ((keyword, categoryId) in MERCHANT_CATEGORIES) {
            if (text.contains(keyword)) return categoryId
        }
        return if (type == "income") "other_income" else "other_expense"
    }

    private fun getBankName(packageName: String): String {
        val bankNames = linkedMapOf(
            "com.mservice" to "MoMo",
            "vn.momo" to "MoMo",
            "com.momo" to "MoMo",
            "com.VCB" to "Vietcombank",
            "com.vcb" to "Vietcombank",
            "com.bidv" to "BIDV",
            "com.techcombank" to "Techcombank",
            "com.mbmobile" to "MBBank",
            "com.mb.mbanking" to "MBBank",
            "com.vietinbank" to "Vietinbank",
            "com.agribank" to "Agribank",
            "com.tpb" to "TPBank",
            "com.acb" to "ACB",
            "com.sacombank" to "Sacombank",
            "com.vpbank" to "VPBank",
            "vn.com.zalopay" to "ZaloPay",
            "com.zing.zalopay" to "ZaloPay",
            "com.vnpay" to "VNPay",
            "com.grabtaxi" to "GrabPay",
            "com.shopee" to "ShopeePay",
            "com.viettelpay" to "ViettelPay",
            "vn.viettel" to "ViettelMoney",
        )
        for ((pkg, name) in bankNames) {
            if (packageName.lowercase().contains(pkg.lowercase())) return name
        }
        return "Ngân hàng"
    }

    private fun tryNotifyFlutter(packageName: String, title: String, body: String) {
        val engine = flutterEngine
            ?: FlutterEngineCache.getInstance().get("notification_engine")
            ?: return
        try {
            MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
                .invokeMethod(
                    "onNotification",
                    mapOf("packageName" to packageName, "title" to title, "body" to body)
                )
        } catch (e: Exception) {
            Log.d(TAG, "ℹ️ Flutter not available: ${e.message}")
        }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "✅ Listener connected")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            requestRebind(
                android.content.ComponentName(this, AppNotificationListenerService::class.java)
            )
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "⚠️ Service destroyed")
    }
}