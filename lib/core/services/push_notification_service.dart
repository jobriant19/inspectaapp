import 'notification_service.dart';

/// Wrapper ringan — mendelegasikan ke NotificationService yang sudah ada.
/// Dipakai oleh notification_screen.dart dan admin_news_screen.dart
/// untuk trigger notifikasi lokal dari Supabase Realtime.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  /// Init dipanggil dari main.dart — cukup forward ke NotificationService
  Future<void> init() async {
    // NotificationService.initialize() sudah dipanggil di main.dart
    // Tidak perlu inisialisasi ulang
  }

  /// Tampilkan notifikasi lokal — forward ke NotificationService
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String payload = '',
  }) async {
    await NotificationService.instance.showNotification(
      title: title,
      body: body,
      payload: payload.isNotEmpty ? payload : null,
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }
}