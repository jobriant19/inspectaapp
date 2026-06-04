import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final plugin = FlutterLocalNotificationsPlugin();

  const androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await plugin.initialize(initSettings);

  final androidDetails = AndroidNotificationDetails(
    'inspecta_channel',
    'Inspecta Notifications',
    channelDescription: 'Notifikasi dari aplikasi Inspecta',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    sound: const RawResourceAndroidNotificationSound('notification_sound'),
    enableVibration: true,
    // Large icon di kiri (menggantikan icon app default Flutter)
    largeIcon: const DrawableResourceAndroidBitmap('logo_notif'),
  );

  await plugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    message.notification?.title ?? 'Inspecta',
    message.notification?.body ?? '',
    NotificationDetails(android: androidDetails),
  );
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  bool _initialized = false;

  static const String _channelId = 'inspecta_channel';
  static const String _channelName = 'Inspecta Notifications';

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Notifikasi dari aplikasi Inspecta',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      enableVibration: true,
    );

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(channel);

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showNotification(
        title: message.notification?.title ?? 'Inspecta',
        body: message.notification?.body ?? '',
        payload: message.data['route'],
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification opened: ${message.data}');
    });

    _fcm.onTokenRefresh.listen(_onTokenRefresh);
  }

  Future<void> saveFcmTokenAfterLogin() async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('⚠️ User belum login, skip save FCM token');
        return;
      }

      String? token;
      if (Platform.isIOS) {
        final apns = await _fcm.getAPNSToken();
        if (apns == null) {
          debugPrint('⚠️ APNS token belum siap');
          return;
        }
        token = await _fcm.getToken();
      } else {
        token = await _fcm.getToken();
      }

      if (token == null) {
        debugPrint('⚠️ FCM token null');
        return;
      }

      await client
          .from('User')
          .update({'fcm_token': token}).eq('id_user', userId);

      debugPrint('✅ FCM token saved: $token');
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  void _onTokenRefresh(String token) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      await Supabase.instance.client
          .from('User')
          .update({'fcm_token': token}).eq('id_user', userId);
      debugPrint('✅ FCM token refreshed: $token');
    } catch (e) {
      debugPrint('❌ Error refreshing FCM token: $e');
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Notifikasi dari aplikasi Inspecta',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
      // Hapus 'icon' agar small icon pakai meta-data FCM (monochrome ic_launcher)
      // Large icon di kiri menampilkan logo berwarna Inspecta
      largeIcon: const DrawableResourceAndroidBitmap('logo_notif'),
      styleInformation: BigTextStyleInformation(body),
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_sound.mp3',
    );

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  Future<String?> getToken() async {
    return await _fcm.getToken();
  }
}