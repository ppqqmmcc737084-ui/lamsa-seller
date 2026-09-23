import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/onesignal_keys.dart';

class NotificationService {
// ...
  static const String _appId = OneSignalKeys.appId;
  static const String _apiKey = OneSignalKeys.apiKey;
  Future<void> sendToCustomer(String customerId, String message) async {
    try {
      await http.post(
        Uri.parse('https://api.onesignal.com/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $_apiKey',
        },
        body: jsonEncode({
          'app_id': _appId,
          'include_aliases': {
            'external_id': [customerId]
          },
          'target_channel': 'push',
          'contents': {'en': message, 'ar': message},
          'headings': {'en': 'لمسة', 'ar': 'لمسة'},
        }),
      );
    } catch (e) {
      // ما نوقف باقي العملية لو فشل الإشعار، بس نطبع الخطأ
      // ignore: avoid_print
      print('فشل إرسال الإشعار: $e');
    }
  }
}