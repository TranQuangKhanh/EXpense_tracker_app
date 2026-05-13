package com.example.expense_tracker

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
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
        const val CHANNEL =
            "com.example.expense_tracker/notification"
        const val NOTIF_CHANNEL_ID =
            "notification_listener_channel"
        const val NOTIF_ID = 1001
        var flutterEngine: FlutterEngine? = null

        private val processedKeys =
            mutableMapOf<String, Long>()
        private const val DEDUP_WINDOW_MS = 10_000L

        val BANK_PACKAGES = listOf(
            "com.mservice.momotransfer",
            "com.mservice.omni",
            "com.mservice",
            "vn.momo.client",
            "vn.momo",
            "com.momo",
            "com.VCB",
            "com.vcb",
            "com.vcb.digibank",
            "com.vietcombank",
            "com.bidv.smartbanking",
            "com.bidv",
            "com.techcombank.mb.app",
            "com.techcombank",
            "com.mbmobile",
            "com.mb.mbanking",
            "com.vietinbank.ipay",
            "com.vietinbank",
            "com.agribank",
            "com.tpb.mb.gprs",
            "com.tpb",
            "com.acb.mobile",
            "com.acb",
            "com.sacombank",
            "com.vpbank",
            "vn.shb.saha.mbanking",
            "vn.shb.mobile",
            "com.shb",
            "vn.com.vng.zalopay",
            "vn.com.zalopay",
            "com.zing.zalopay",
            "com.zalopay",
            "com.vnpay",
            "vn.vnpay",
            "vn.com.vnpay",
            "com.vnpay.wallet",
            "com.vnpay.hdbank",
            "vnpay.smartacccount",
            "com.shopee.vn",
            "com.grabtaxi.passenger",
            "com.viettelpay",
            "vn.viettel.money",
        )

        val MERCHANT_CATEGORIES = linkedMapOf(
            "grabfood" to "food",
            "shopeefood" to "food",
            "baemin" to "food",
            "grabbike" to "transport",
            "grabcar" to "transport",
            "grab" to "transport",
            "shopee" to "shopping",
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
            "lazada" to "shopping",
            "tiki" to "shopping",
            "sendo" to "shopping",
            "winmart" to "shopping",
            "coopmart" to "shopping",
            "aeon" to "shopping",
            "netflix" to "entertainment",
            "spotify" to "entertainment",
            "cgv" to "entertainment",
            "lotte cinema" to "entertainment",
            "galaxy cinema" to "entertainment",
            "steam" to "entertainment",
            "pharmacity" to "health",
            "long chau" to "health",
            "an khang" to "health",
            "guardian" to "health",
            "benh vien" to "health",
            "nha thuoc" to "health",
            "evn" to "bills",
            "dien luc" to "bills",
            "vnpt" to "bills",
            "viettel" to "bills",
            "mobifone" to "bills",
            "fpt" to "bills",
            "internet" to "bills",
            "hoc phi" to "education",
            "duolingo" to "education",
            "coursera" to "education",
            "luong" to "salary",
            "salary" to "salary",
            "thuong" to "bonus",
            "bonus" to "bonus",
        )

        const val CURRENCY_PATTERN =
            """(?:vnd|vn\u0111|vnđ|vn\u20ab|\u0111ồng|đồng|dong|\u20ab\b|\u20ab(?=\s|,|\.)|\u0111\b|\u0111(?=\s|,|\.)|đ\b|đ(?=\s|,|\.)|\bd\b)"""
    }

    private val db = FirebaseFirestore.getInstance()
    private val auth = FirebaseAuth.getInstance()

    private fun getUserId(): String? {
        return try {
            val prefs = applicationContext
                .getSharedPreferences(
                    "FlutterSharedPreferences",
                    Context.MODE_PRIVATE
                )
            val fromPrefs =
                prefs.getString("flutter.userId", null)
            if (fromPrefs != null) {
                Log.d(TAG,
                    "✅ userId from prefs: $fromPrefs")
                return fromPrefs
            }
            val fromAuth = auth.currentUser?.uid
            if (fromAuth != null) {
                Log.d(TAG,
                    "✅ userId from auth: $fromAuth")
                return fromAuth
            }
            Log.e(TAG, "❌ No userId found")
            null
        } catch (e: Exception) {
            Log.e(TAG, "❌ getUserId error: $e")
            auth.currentUser?.uid
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForegroundCompat()
        Log.d(TAG, "✅ Service created")
    }

    private fun startForegroundCompat() {
        val notification =
            NotificationCompat.Builder(
                this, NOTIF_CHANNEL_ID)
                .setContentTitle(
                    "Đang theo dõi giao dịch")
                .setContentText(
                    "Tự động ghi nhận giao dịch ngân hàng")
                .setSmallIcon(
                    android.R.drawable.ic_dialog_info)
                .setPriority(
                    NotificationCompat.PRIORITY_LOW)
                .setSilent(true)
                .setOngoing(true)
                .build()

        if (Build.VERSION.SDK_INT >=
            Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIF_ID, notification,
                android.content.pm.ServiceInfo
                    .FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            )
        } else {
            startForeground(NOTIF_ID, notification)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >=
            Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIF_CHANNEL_ID,
                "Notification Listener",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description =
                    "Theo dõi giao dịch ngân hàng"
                setShowBadge(false)
            }
            getSystemService(
                NotificationManager::class.java)
                .createNotificationChannel(channel)
        }
    }

    override fun onNotificationPosted(
        sbn: StatusBarNotification?
    ) {
        super.onNotificationPosted(sbn)
        sbn ?: return

        val packageName = sbn.packageName ?: return
        val isBank = BANK_PACKAGES.any {
            packageName.lowercase()
                .contains(it.lowercase())
        }
        if (!isBank) return

        val extras = sbn.notification?.extras ?: return
        val title =
            extras.getString("android.title") ?: ""
        val body = extras
            .getCharSequence("android.text")
            ?.toString() ?: ""
        val bigText = extras
            .getCharSequence("android.bigText")
            ?.toString() ?: ""
        val fullBody =
            if (bigText.isNotEmpty()) bigText else body

        val dedupKey =
            buildDedupKey(packageName, title, fullBody)
        val now = System.currentTimeMillis()
        val lastProcessed = processedKeys[dedupKey]

        if (lastProcessed != null &&
            (now - lastProcessed) < DEDUP_WINDOW_MS) {
            Log.d(TAG,
                "⏭️ Skip duplicate: $dedupKey")
            return
        }

        processedKeys[dedupKey] = now
        cleanOldKeys(now)

        Log.d(TAG,
            "📱 $packageName | $title | $fullBody")

        saveDirectlyToFirestore(
            packageName, title, fullBody)
        tryNotifyFlutter(packageName, title, fullBody)
    }

    private fun buildDedupKey(
        packageName: String,
        title: String,
        body: String
    ): String {
        val content =
            "${packageName}_${title}_${body.take(200)}"
        return content.hashCode().toString()
    }

    private fun cleanOldKeys(now: Long) {
        val expireTime = 60_000L
        processedKeys.entries
            .filter { (now - it.value) > expireTime }
            .map { it.key }
            .forEach { processedKeys.remove(it) }
    }

    private fun saveDirectlyToFirestore(
        packageName: String,
        title: String,
        body: String
    ) {
        val userId = getUserId()
        if (userId == null) {
            Log.e(TAG, "❌ No userId — skip save")
            return
        }

        val bankName = getBankName(packageName)
        val rawText = "$title $body"
        val normalizedText = rawText
            .replace('\u00A0', ' ')
            .replace('\u202F', ' ')
            .replace('\u2009', ' ')
            .replace('\u2007', ' ')
            .lowercase()

        val amount =
            parseAmount(normalizedText, packageName)
        if (amount == null || amount <= 0) {
            Log.e(TAG,
                "❌ Parse amount failed: $rawText")
            saveDebugLog(
                userId, packageName, title,
                body, false, null, null
            )
            return
        }

        val type =
            detectType(normalizedText, packageName)
        val categoryId =
            suggestCategory(normalizedText, type)

        Log.d(TAG, "✅ $amount $type $categoryId")
        saveDebugLog(
            userId, packageName, title,
            body, true, amount, type
        )

        val contentHash =
            "${userId}_${amount.toLong()}_${type}_$bankName"

        db.collection("expenses").add(
            hashMapOf(
                "title" to "$bankName - " +
                    if (type == "income")
                        "Tiền vào" else "Tiền ra",
                "amount" to amount,
                "type" to type,
                "categoryId" to categoryId,
                "date" to FieldValue.serverTimestamp(),
                "userId" to userId,
                "source" to "auto",
                "isAuto" to true,
                "status" to "pending",
                "bankName" to bankName,
                "originalText" to rawText,
                "contentHash" to contentHash,
                "createdMs" to
                    System.currentTimeMillis(),
            )
        ).addOnSuccessListener {
            Log.d(TAG, "✅ Saved: $amount $type")
        }.addOnFailureListener { e ->
            Log.e(TAG,
                "❌ Firestore error: ${e.message}")
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
                "timestamp" to
                    FieldValue.serverTimestamp(),
                "userId" to userId,
                "source" to "native_kotlin"
            )
        )
    }

    private fun parseAmount(
        text: String,
        packageName: String
    ): Double? {
        val isMbBank = packageName.lowercase().let {
            it.contains("mbmobile") ||
                it.contains("mb.mbanking")
        }
        if (isMbBank) {
            val mbRegex = Regex(
                """gd:\s*([+\-]?\s*\d{1,3}(?:[.,]\d{3})*)(?:vnd|vnđ)""",
                RegexOption.IGNORE_CASE
            )
            mbRegex.find(text)?.let { match ->
                val raw = match.groupValues[1]
                    .replace(Regex("[+\\-\\s]"), "")
                    .replace(".", "")
                    .replace(",", "")
                val amount = raw.toDoubleOrNull()
                if (amount != null && amount >= 1000)
                    return amount
            }
        }

        // Tách trước "số dư" để parse đúng
        // Bỏ qua "số dư" trong 40 ký tự đầu
        // (là "Số dư TK VCB xxx")
        var transactionText = text
        val dotIdx = text.indexOf(".")
        if (dotIdx > 10) {
            val afterDot = text.substring(dotIdx)
            val soduAfterDot = listOf(
                "số dư", "so du", "sd:", "|sd:",
                "balance"
            ).mapNotNull {
                val i = afterDot.indexOf(it)
                if (i >= 0) i else null
            }.minOrNull()
            if (soduAfterDot != null) {
                transactionText =
                    text.substring(
                        0, dotIdx + soduAfterDot)
            }
        }

        if (transactionText == text) {
            val soduKeywords = listOf(
                "|sd:", "số dư cuối", "so du cuoi",
                "số dư", "so du", "sd:", "balance",
            )
            outer@ for (keyword in soduKeywords) {
                var searchFrom = 40
                while (true) {
                    val idx = text.indexOf(
                        keyword, searchFrom)
                    if (idx < 0) break
                    transactionText =
                        text.substring(0, idx)
                    break@outer
                }
            }
        }

        val regex = Regex(
            """[+\-]?\s*(\d{1,3}(?:[.,]\d{3})*|\d+)\s*$CURRENCY_PATTERN""",
            setOf(RegexOption.IGNORE_CASE)
        )

        // Ưu tiên số có dấu +
        for (match in
            regex.findAll(transactionText)) {
            if (match.value.trimStart()
                    .startsWith("+")) {
                val raw = match.groupValues[1]
                    .replace(".", "")
                    .replace(",", "")
                val amount = raw.toDoubleOrNull()
                if (amount != null && amount >= 1000)
                    return amount
            }
        }

        // Số đầu tiên trong phần giao dịch
        for (match in
            regex.findAll(transactionText)) {
            val raw = match.groupValues[1]
                .replace(".", "").replace(",", "")
            val amount = raw.toDoubleOrNull()
            if (amount != null && amount >= 1000)
                return amount
        }

        // Fallback toàn text
        var minAmount: Double? = null
        for (match in regex.findAll(text)) {
            val raw = match.groupValues[1]
                .replace(".", "").replace(",", "")
            val amount = raw.toDoubleOrNull()
            if (amount != null && amount >= 1000) {
                if (minAmount == null ||
                    amount < minAmount)
                    minAmount = amount
            }
        }
        return minAmount
    }

    private fun detectType(
        text: String,
        packageName: String
    ): String {
        // ── Tách phần giao dịch ──────────────────
        // Cách 1: tìm "số dư" SAU dấu chấm đầu tiên
        // VCB: "...+18,000 VND lúc ... Số dư 1,843,044"
        //                              ↑ cắt tại đây
        var textForType = text

        val dotIdx = text.indexOf(".")
        if (dotIdx > 10) {
            val afterDot = text.substring(dotIdx)
            val soduAfterDot = listOf(
                "số dư", "so du", "sd:",
                "|sd:", "balance"
            ).mapNotNull {
                val i = afterDot.indexOf(it)
                if (i >= 0) i else null
            }.minOrNull()

            if (soduAfterDot != null) {
                textForType = text.substring(
                    0, dotIdx + soduAfterDot)
            }
        }

        // Cách 2 (fallback): tìm "số dư" từ ký tự 40
        // Bỏ qua "Số dư TK VCB xxx" trong header
        if (textForType == text) {
            val soduKeywords = listOf(
                "|sd:", "số dư cuối", "so du cuoi",
                "số dư", "so du", "sd:", "balance",
            )
            outer@ for (keyword in soduKeywords) {
                var searchFrom = 40
                while (true) {
                    val idx = text.indexOf(
                        keyword, searchFrom)
                    if (idx < 0) break
                    textForType =
                        text.substring(0, idx)
                    break@outer
                }
            }
        }

        Log.d(TAG,
            "🔍 detectType textForType: $textForType")

        // MB Bank
        val isMbBank = packageName.lowercase().let {
            it.contains("mbmobile") ||
                it.contains("mb.mbanking")
        }
        if (isMbBank) {
            if (Regex("""gd:\s*\+""",
                    RegexOption.IGNORE_CASE)
                    .containsMatchIn(textForType))
                return "income"
            if (Regex("""gd:\s*-""",
                    RegexOption.IGNORE_CASE)
                    .containsMatchIn(textForType))
                return "expense"
        }

        // MoMo
        val isMomo = packageName.lowercase().let {
            it.contains("mservice") ||
                it.contains("momo")
        }
        if (isMomo) {
            if (listOf(
                    "nhận tiền", "nhan tien",
                    "tiền về", "tien ve",
                    "về ví", "ve vi",
                    "nhận được", "nhan duoc",
                ).any { textForType.contains(it) })
                return "income"
            if (listOf(
                    "thanh toán", "thanh toan",
                    "chuyển tiền", "chuyen tien",
                    "rút tiền", "rut tien",
                    "mua hàng", "mua hang",
                ).any { textForType.contains(it) })
                return "expense"
        }

        // ShopeePay
        val isShopeePay = packageName.lowercase()
            .contains("shopee")
        if (isShopeePay) {
            if (listOf(
                    "nhận tiền thành công",
                    "nhan tien thanh cong",
                    "tiền về", "tien ve",
                    "hoàn tiền", "hoan tien",
                ).any { textForType.contains(it) })
                return "income"
            if (listOf(
                    "thanh toán", "thanh toan",
                    "chuyển tiền", "chuyen tien",
                    "rút tiền", "rut tien",
                ).any { textForType.contains(it) })
                return "expense"
        }

        // ZaloPay
        val isZaloPay = packageName.lowercase().let {
            it.contains("zalopay") ||
                it.contains("vng.zalo")
        }
        if (isZaloPay) {
            if (listOf(
                    "nhận tiền", "nhan tien",
                    "nhận qua", "nhan qua",
                    "tiền về", "tien ve",
                ).any { textForType.contains(it) })
                return "income"
            if (listOf(
                    "thanh toán", "thanh toan",
                    "chuyển tiền", "chuyen tien",
                    "rút tiền", "rut tien",
                ).any { textForType.contains(it) })
                return "expense"
        }

        // SHB
        val isShb = packageName.lowercase()
            .contains("shb")
        if (isShb) {
            if (Regex(
                """phát sinh\s*\+|phat sinh\s*\+""")
                    .containsMatchIn(textForType))
                return "income"
            if (Regex(
                """phát sinh\s*-|phat sinh\s*-""")
                    .containsMatchIn(textForType))
                return "expense"
        }

        // VNPay
        val isVnpay = packageName.lowercase()
            .contains("vnpay")
        if (isVnpay) {
            if (Regex(""":\s*\+\s*\d""")
                    .containsMatchIn(textForType))
                return "income"
            if (listOf(
                    "cashin", "nạp tiền", "nap tien")
                    .any { textForType.contains(it) })
                return "income"
            if (Regex(""":\s*-\s*\d""")
                    .containsMatchIn(textForType))
                return "expense"
            if (listOf(
                    "cashout", "thanh toán",
                    "thanh toan")
                    .any { textForType.contains(it) })
                return "expense"
        }

        // ── VCB & ngân hàng khác ─────────────────
        // Check dấu +/- trước VND
        // trong phần TRƯỚC "số dư cuối"
        val signedVndRegex = Regex(
            """([+\-])\s*(\d{1,3}(?:[.,]\d{3})*)\s*(?:vnd|vnđ|vn\u0111)""",
            RegexOption.IGNORE_CASE
        )
        signedVndRegex.find(textForType)?.let {
            Log.d(TAG,
                "🔍 signed: ${it.groupValues[1]}")
            return if (it.groupValues[1] == "+")
                "income" else "expense"
        }

        // Keywords chung
        val incomeKeywords = listOf(
            "nhận", "nhan", "cộng", "cong",
            "tiền về", "tien ve",
            "về ví", "ve vi",
            "vào ví", "vao vi",
            "vào tài khoản", "vao tai khoan",
            "received", "credit", "cashin",
            "hoàn tiền", "hoan tien",
        )
        val expenseKeywords = listOf(
            "thanh toán", "thanh toan",
            "trừ", "tru",
            "chuyển đi", "chuyen di",
            "rút", "rut",
            "debit", "payment",
            "chi tiêu", "chi tieu",
            "cashout",
        )

        if (incomeKeywords.any
                { textForType.contains(it) })
            return "income"
        if (expenseKeywords.any
                { textForType.contains(it) })
            return "expense"

        return "expense"
    }

    private fun suggestCategory(
        text: String,
        type: String
    ): String {
        for ((keyword, categoryId) in
            MERCHANT_CATEGORIES) {
            if (text.contains(keyword))
                return categoryId
        }
        return if (type == "income")
            "other_income" else "other_expense"
    }

    private fun getBankName(
        packageName: String
    ): String {
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
            "vn.shb" to "SHB",
            "com.shb" to "SHB",
            "vn.com.vng.zalopay" to "ZaloPay",
            "vn.com.zalopay" to "ZaloPay",
            "com.zing.zalopay" to "ZaloPay",
            "com.vnpay" to "VNPay",
            "vn.vnpay" to "VNPay",
            "vnpay.smartacccount" to "VNPay",
            "com.shopee" to "ShopeePay",
            "com.grabtaxi" to "GrabPay",
            "com.viettelpay" to "ViettelPay",
            "vn.viettel" to "ViettelMoney",
        )
        for ((pkg, name) in bankNames) {
            if (packageName.lowercase()
                    .contains(pkg.lowercase()))
                return name
        }
        return "Ngân hàng"
    }

    private fun tryNotifyFlutter(
        packageName: String,
        title: String,
        body: String
    ) {
        val engine = flutterEngine
            ?: FlutterEngineCache.getInstance()
                .get("notification_engine")
            ?: return
        try {
            MethodChannel(
                engine.dartExecutor.binaryMessenger,
                CHANNEL
            ).invokeMethod(
                "onNotification",
                mapOf(
                    "packageName" to packageName,
                    "title" to title,
                    "body" to body
                )
            )
        } catch (e: Exception) {
            Log.d(TAG,
                "ℹ️ Flutter unavailable: ${e.message}")
        }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "✅ Listener connected")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        if (Build.VERSION.SDK_INT >=
            Build.VERSION_CODES.N) {
            requestRebind(
                android.content.ComponentName(
                    this,
                    AppNotificationListenerService
                        ::class.java
                )
            )
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "⚠️ Service destroyed")
    }
}