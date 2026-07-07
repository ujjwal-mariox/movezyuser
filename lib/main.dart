import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:movezy_user_app/Routes/app_routes.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';

/// Removes the stretchy / glow overscroll effect on every screen globally.
class _NoStretchScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child; // no glow, no stretch
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Prefs.load();
  Prefs.loadData();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      navigatorKey: Get.key,
      debugShowCheckedModeBanner: false,
      locale: Get.deviceLocale,
      title: 'Movezy',
      initialRoute: AppRoutes.initialRoute,
      getPages: AppRoutes.pages,
      scrollBehavior: _NoStretchScrollBehavior(),
    );
  }
}
