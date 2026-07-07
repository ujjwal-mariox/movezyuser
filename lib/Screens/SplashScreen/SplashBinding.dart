

import 'package:get/get.dart';
import 'package:movezy_user_app/Screens/SplashScreen/Controller.dart';


class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SplashController());
  }
}