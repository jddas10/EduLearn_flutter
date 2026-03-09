import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'screens/auth/api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("🔔 Background message: ${message.notification?.title}");
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel quizChannel = AndroidNotificationChannel(
  'edulearn_quiz_channel',
  'Quiz Notifications',
  description: 'Notifications for new quizzes from teachers',
  importance: Importance.high,
  playSound: true,
);

Future<void> _saveTokenIfLoggedIn(String token) async {
  try {
    final isLoggedIn = await SessionStore.isLoggedIn;
    if (isLoggedIn) {
      await NotificationApi.saveFcmToken(token);
      print("✅ FCM token saved to backend!");
    } else {
      print("⏭️ Not logged in — token will save on login");
    }
  } catch (e) {
    print("❌ FCM token save failed: $e");
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(quizChannel);

  const AndroidInitializationSettings androidSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
  InitializationSettings(android: androidSettings);

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      print("🔔 Notification tapped: ${response.payload}");
    },
  );

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  NotificationSettings settings =
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  print("🔐 Permission status: ${settings.authorizationStatus}");

  String? token = await FirebaseMessaging.instance.getToken();
  print("📱 FCM Token: $token");

  if (token != null) {
    await _saveTokenIfLoggedIn(token);
  }

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    print("🔄 FCM Token refreshed: $newToken");
    await _saveTokenIfLoggedIn(newToken);
  });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📩 Foreground message received: ${message.notification?.title}");
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            quizChannel.id,
            quizChannel.name,
            channelDescription: quizChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  });

  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      print("🚀 Launched from notification: ${message.notification?.title}");
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("📬 Opened from background notification: ${message.notification?.title}");
  });

  runApp(const EduLearnApp());
}