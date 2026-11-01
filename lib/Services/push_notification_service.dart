import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/Screens/TripDetailsScreen/trip_details_screen.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';

/// Push notifications (Firebase Cloud Messaging).
///
/// The backend already sends pushes for driver assigned / arrived, trip
/// completed, cancellations, refunds and SOS, but nothing arrived because the
/// app never registered the phone. This registers it, shows pushes while the
/// app is open (Android only displays them itself when the app is in the
/// background), and opens the booking when one is tapped.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  /// Must match the channelId the backend puts on every push.
  static const String _channelId = 'movezy_channel';
  static const String _channelName = 'Booking updates';
  static const String _channelDescription =
      'Driver, trip, payment and safety updates';
  static const Color _brandOrange = Color(0xFFFF6200);

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  // Classic FCM registration tokens: firebase_messaging 17 deprecates them in
  // favour of register()/onRegistered, which yield installation IDs for a
  // newer send model. The backend's firebase-admin sends to tokens, so the
  // token calls stay until the backend moves too.
  bool _ready = false;

  /// Call once before runApp. Never prompts the user.
  Future<void> init() async {
    // Firebase isn't configured for the web build (used for QA only).
    if (_ready || kIsWeb) return;
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('push: Firebase init failed: $e');
      return;
    }
    _ready = true;

    try {
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@drawable/ic_notification'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (resp) =>
            _openFromPayload(resp.payload),
      );
      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: _channelDescription,
              importance: Importance.high,
            ),
          );
    } catch (e) {
      debugPrint('push: local notifications init failed: $e');
    }

    // iOS shows foreground pushes itself; Android needs a local notification.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
    FirebaseMessaging.onMessage.listen(_showWhileOpen);
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _open(m.data));
    // ignore: deprecated_member_use
    FirebaseMessaging.instance.onTokenRefresh.listen(_uploadToken);

    // Tapped while the app was closed: Firebase-shown push, or one of our
    // local notifications.
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    final launch = await _local.getNotificationAppLaunchDetails();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (initial != null) {
        _open(initial.data);
      } else if (launch?.didNotificationLaunchApp == true) {
        _openFromPayload(launch?.notificationResponse?.payload);
      }
    });
  }

  /// Asks for notification permission (once; Android 13+ and iOS) and sends
  /// this phone's token to the server. Called from the home screen, so the
  /// prompt never stacks on the location prompt right after login.
  Future<void> registerDevice() async {
    if (!_ready || Prefs.getString('token').isEmpty) return;
    try {
      await FirebaseMessaging.instance.requestPermission();
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _uploadToken(token);
    } catch (e) {
      debugPrint('push: register failed: $e');
    }
  }

  /// On logout: retire this phone's token, so the next account signed in on
  /// the phone doesn't receive this customer's notifications.
  Future<void> unregisterDevice() async {
    if (!_ready) return;
    try {
      // ignore: deprecated_member_use
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }

  Future<void> _uploadToken(String fcmToken) async {
    final auth = Prefs.getString('token');
    if (auth.isEmpty) return;
    try {
      await http
          .put(
            Uri.parse(ApiUrls.fcmTokenUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $auth',
            },
            body: jsonEncode({'fcmToken': fcmToken}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('push: token upload failed: $e');
    }
  }

  void _showWhileOpen(RemoteMessage message) {
    final n = message.notification;
    if (n == null || !Platform.isAndroid) return;
    _local.show(
      id: (message.messageId ?? '${DateTime.now().microsecondsSinceEpoch}')
              .hashCode &
          0x7fffffff,
      title: n.title,
      body: n.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          color: _brandOrange,
          autoCancel: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _openFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      _open(Map<String, dynamic>.from(jsonDecode(payload) as Map));
    } catch (_) {}
  }

  /// Booking pushes carry a bookingId. The trip screen handles every status,
  /// including completed (receipt and rating) and cancelled, so all of them
  /// open there; anything else just opens the app.
  void _open(Map<String, dynamic> data) {
    final bookingId = data['bookingId']?.toString() ?? '';
    if (bookingId.isEmpty || Prefs.getString('token').isEmpty) return;
    Get.to(() => TripDetailsScreen(bookingId: bookingId));
  }
}
