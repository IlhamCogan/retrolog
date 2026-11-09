import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    if (kIsWeb) return; // Web tidak memerlukan pendaftaran local notification Android

    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidInit);

    // Versi 22.x wajib menggunakan named argument 'settings:'
    await _notifications.initialize(settings: initSettings);

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showDefaultSoundNotification({required String title, required String body}) async {
    if (kIsWeb) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'retrolog_default_channel',
      'Pengingat Servis (Default)',
      channelDescription: 'Notifikasi pengingat jadwal servis dengan nada sistem default',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    // Versi 22.x wajib menggunakan named parameters lengkap
    await _notifications.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> showCustomSoundNotification({required String title, required String body}) async {
    if (kIsWeb) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'retrolog_custom_channel',
      'Pengingat Servis (Custom Retro Sound)',
      channelDescription: 'Notifikasi pengingat jadwal servis dengan nada custom',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('retro_engine'),
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    // Versi 22.x wajib menggunakan named parameters lengkap
    await _notifications.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}