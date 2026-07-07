import 'package:get/get.dart';
import 'package:movezy_user_app/Screens/SplashScreen/SplashBinding.dart';
import 'package:movezy_user_app/Screens/SplashScreen/splash_screen.dart';


class AppRoutes {
  static String initialRoute = '/initialRoute';

  static List<GetPage> pages = [
    GetPage(
      name: initialRoute,
      page: () =>  SplashScreen(),
      bindings: [
        SplashBinding(),
      ],
      transition: Transition.rightToLeft,
    ),
  ];
}
