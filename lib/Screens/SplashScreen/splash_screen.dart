import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/Screens/DashboardScreen/dashboard_screen.dart';
import 'package:movezy_user_app/Screens/LoginScreen/login_screen.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), () async {
      try {
        await Prefs.load();
        Prefs.loadData();
      } catch (e) {
        debugPrint('Prefs load error: $e');
      }

      if (!mounted) return;

      if (Prefs.check_log_in == true && Prefs.token.isNotEmpty) {
        replaceRoute(context, DashboardScreen());
      } else {
        replaceRoute(context, LoginScreen());
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark,
    ));

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white, // light green background
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top spacer for status bar
          const SizedBox(height: 120),

          // Center logo
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App logo
                  Image.asset(
                    "assets/app_icon.png", // <-- put your logo here
                    width: 220,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),


          Image.asset(
            "assets/building_image.png", // <-- put your logo here
            width: MediaQuery.of(context).size.width,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}
