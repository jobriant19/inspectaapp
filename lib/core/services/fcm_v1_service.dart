import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FcmV1Service {
  FcmV1Service._();
  static final FcmV1Service instance = FcmV1Service._();

  /// Kirim push notification ke satu FCM token
  Future<bool> sendToToken({
    required String fcmToken,
    required String title,
    required String body,
    String? route,
    Map<String, String>? extraData,
  }) async {
    try {
      final Map<String, String> data = {
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        if (route != null) 'route': route,
        ...?extraData,
      };

      final response = await Supabase.instance.client.functions.invoke(
        'send-fcm-v1',
        body: {
          'token': fcmToken,
          'title': title,
          'body': body,
          'data': data,
        },
      );

      if (response.status == 200) {
        debugPrint('✅ FCM sent successfully');
        return true;
      } else {
        debugPrint('❌ FCM error ${response.status}: ${response.data}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ sendToToken error: $e');
      return false;
    }
  }

  /// Kirim push notification ke banyak token sekaligus
  Future<void> sendToMultipleTokens({
    required List<String> fcmTokens,
    required String title,
    required String body,
    String? route,
    Map<String, String>? extraData,
  }) async {
    if (fcmTokens.isEmpty) return;

    int successCount = 0;
    int failCount = 0;

    for (final token in fcmTokens) {
      final sent = await sendToToken(
        fcmToken: token,
        title: title,
        body: body,
        route: route,
        extraData: extraData,
      );
      if (sent) {
        successCount++;
      } else {
        failCount++;
      }
    }

    debugPrint(
      '📊 FCM batch: $successCount sent, $failCount failed / ${fcmTokens.length} total',
    );
  }
}