import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

// Handler untuk pesan background (harus top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.instance.initialize();
  await NotificationService.instance.showNotification(
    title: message.notification?.title ?? 'Inspecta',
    body: message.notification?.body ?? '',
  );
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  bool _initialized = false;

  // Channel ID & Name
  static const String _channelId = 'inspecta_channel';
  static const String _channelName = 'Inspecta Notifications';

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // 1. Minta izin notifikasi
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // 2. Setup channel Android dengan sound kustom
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Notifikasi dari aplikasi Inspecta',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      // 'notification_sound' = nama file di res/raw/ TANPA ekstensi
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. Inisialisasi flutter_local_notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle tap notifikasi di sini jika perlu navigasi
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    // 4. Handle notifikasi saat app foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showNotification(
        title: message.notification?.title ?? 'Inspecta',
        body: message.notification?.body ?? '',
        payload: message.data['route'],
      );
    });

    // 5. Handle tap notifikasi saat app background (tapi tidak terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification opened: ${message.data}');
    });
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Notifikasi dari aplikasi Inspecta',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(body),
    );

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  // Panggil ini untuk mendapatkan FCM Token (untuk server push)
  Future<String?> getToken() async {
    return await _fcm.getToken();
  }
}