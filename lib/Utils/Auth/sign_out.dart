import 'package:flutter/material.dart';
import 'package:movezy_user_app/Screens/LoginScreen/login_screen.dart';
import 'package:movezy_user_app/Services/push_notification_service.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';

/// Clears the session on this phone and returns to login. Shared by the
/// profile's Logout and by account deletion, so both sign out the same way.
Future<void> signOut(BuildContext context) async {
  // Stop this phone receiving the account's pushes after sign-out.
  await PushNotificationService.instance.unregisterDevice();
  await Prefs.setBool('check_log_in', false);
  await Prefs.setString('mobile_number', "");
  await Prefs.setString('token', "");
  await Prefs.setString('userId', "");
  await Prefs.load();
  Prefs.loadData();

  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => LoginScreen()),
    (Route<dynamic> route) => false,
  );
}
