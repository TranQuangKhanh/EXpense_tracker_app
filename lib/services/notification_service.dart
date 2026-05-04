import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'user_service.dart';
import 'notification_parser.dart';

class NotificationService {
  static const _channel = MethodChannel('com.example.expense_tracker/notification');

  static Future<void> initialize() async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNotification') {
        try {
          final dynamic arguments = call.arguments;
          if (arguments is! Map) return;

          final Map<String, String> args = Map<String, String>.from(arguments);
          final packageName = args['packageName'] ?? '';
          final title = args['title'] ?? '';
          final body = args['body'] ?? '';

          debugPrint("📩 Nhận thông báo: $packageName");

          await _saveLog(
            packageName: packageName,
            title: title,
            body: body,
          );

          final parsed = NotificationParser.parse(packageName, title, body);
          if (parsed != null) {
            await _saveToFirestore(parsed, '$title $body');
          }
        } catch (e) {
          debugPrint('❌ Lỗi xử lý thông báo: $e');
        }
      }
    });
  }

  // ← Test thủ công — gọi từ UI để kiểm tra Firestore hoạt động không
  static Future<void> testNotification() async {
    debugPrint('🧪 Bắt đầu test notification...');
    await _saveLog(
      packageName: 'com.mservice.momotransfer',
      title: 'Nhận tiền từ Test User',
      body: 'Số tiền 50.000 đ về ví MoMo. Vào Chat để xem.',
    );
    debugPrint('🧪 Đã lưu log test');
  }

  // ← Test parse luôn để xem có lưu vào expenses không
  static Future<void> testFullFlow() async {
    debugPrint('🧪 Test full flow...');
    const packageName = 'com.mservice.momotransfer';
    const title = 'Nhận tiền từ Test User';
    const body = 'Số tiền 50.000 đ về ví MoMo. Vào Chat để xem.';

    await _saveLog(
      packageName: packageName,
      title: title,
      body: body,
    );

    final parsed = NotificationParser.parse(packageName, title, body);
    if (parsed != null) {
      debugPrint('🧪 Parse thành công: ${parsed.amount}đ - ${parsed.type}');
      await _saveToFirestore(parsed, '$title $body');
    } else {
      debugPrint('🧪 Parse thất bại');
    }
  }

  static Future<void> _saveLog({
    required String packageName,
    required String title,
    required String body,
  }) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        debugPrint('❌ Không có userId khi lưu log');
        return;
      }

      final parsed = NotificationParser.parse(packageName, title, body);

      await FirebaseFirestore.instance.collection('debug_logs').add({
        'packageName': packageName,
        'title': title,
        'body': body,
        'isBank': NotificationParser.isFromBank(packageName),
        'bankName': NotificationParser.getBankName(packageName),
        'parsedSuccess': parsed != null,
        'parsedAmount': parsed?.amount,
        'parsedType': parsed?.type,
        'parsedCategory': parsed?.suggestedCategoryId,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': userId,
      });
      debugPrint('📝 Đã ghi log debug');
    } catch (e) {
      debugPrint('❌ Lỗi ghi log: $e');
    }
  }

  static Future<void> _saveToFirestore(
    ParsedTransaction parsed,
    String originalText,
  ) async {
    final userId = await UserService.getUserId();
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance.collection('expenses').add({
        'title': parsed.title,
        'amount': parsed.amount,
        'type': parsed.type,
        'categoryId': parsed.suggestedCategoryId,
        'date': FieldValue.serverTimestamp(),
        'userId': userId,
        'source': 'auto',
        'status': 'pending',
        'bankName': parsed.bankName,
        'originalText': originalText,
      });
      debugPrint('✅ Lưu giao dịch: ${parsed.amount}đ');
    } catch (e) {
      debugPrint('❌ Lỗi lưu Firestore: $e');
    }
  }

  static Future<bool> hasPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasPermission');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> openPermissionSettings() async {
    try {
      await _channel.invokeMethod('openPermissionSettings');
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  static Future<void> openAutoStart() async {
    try {
      await _channel.invokeMethod('openAutoStart');
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  static Future<void> openBatteryOptimization() async {
    try {
      await _channel.invokeMethod('openBatteryOptimization');
    } catch (e) {
      debugPrint('Error: $e');
    }
  }
}