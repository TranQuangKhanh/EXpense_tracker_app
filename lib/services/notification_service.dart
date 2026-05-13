import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static const _channel = MethodChannel(
      'com.example.expense_tracker/notification');

  static Future<void> initialize() async {
    // Flutter chỉ nhận notification để update UI
    // KHÔNG lưu Firestore — Kotlin service đã xử lý
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNotification') {
        try {
          final dynamic arguments = call.arguments;
          if (arguments is! Map) return;

          final Map<String, String> args =
              Map<String, String>.from(arguments);
          final packageName =
              args['packageName'] ?? '';
          final title = args['title'] ?? '';
          final body = args['body'] ?? '';

          debugPrint(
              '📩 Flutter nhận noti (chỉ log, không lưu): '
              '$packageName | $title');

          // KHÔNG gọi _saveToFirestore nữa
          // Kotlin service đã lưu rồi
        } catch (e) {
          debugPrint('❌ Lỗi xử lý thông báo: $e');
        }
      }
    });
  }

  static Future<bool> hasPermission() async {
    try {
      final result = await _channel
          .invokeMethod<bool>('hasPermission');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> openPermissionSettings() async {
    try {
      await _channel
          .invokeMethod('openPermissionSettings');
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
      await _channel
          .invokeMethod('openBatteryOptimization');
    } catch (e) {
      debugPrint('Error: $e');
    }
  }
}