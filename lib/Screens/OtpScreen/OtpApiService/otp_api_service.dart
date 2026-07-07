import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/Screens/LocationPermissionScreen/location_permission_screen.dart';
import 'package:movezy_user_app/Screens/LoginScreen/Model/login_response.dart';
import 'package:movezy_user_app/Screens/OtpScreen/Model/otp_response.dart';
import 'package:movezy_user_app/Utils/CustomToast/custome_toast.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';
import 'package:http/http.dart' as http;


class OtpApiService {
  Future<bool> otpVerifyApi({required BuildContext context, required String otp, required String mobileNumber, required String token}) async {
    try {
      var params = {
        "txnId": token,
        "otp": otp
      };

      var response = await http.post(
          Uri.parse(ApiUrls.otpUrlVerify),
          body: json.encode(params),
          headers: {
            'Content-Type': 'application/json',
          }
      ).timeout(const Duration(seconds: 30));

      var dataT = otpResponseFromJson(response.body);

      if (response.statusCode == 200) {
        // Save user data
        await Prefs.setBool('check_log_in', true);
        await Prefs.setString('mobile_number', mobileNumber);

        // Save token from response
        if (dataT.data != null && dataT.data!.token != null) {
          await Prefs.setString('token', dataT.data!.token!);
          if (dataT.data!.userId != null) {
            await Prefs.setString('userId', dataT.data!.userId!);
          }
        }

        Prefs.loadData();
        replaceRoute(context, LocationPermissionScreen());
      } else {
        showCustomToast(context, dataT.message.toString());
      }

      return response.statusCode == 200;
    } catch (e) {
      showCustomToast(context, "Network error. Please try again.");
      return false;
    }
  }

  Future<LoginResponse?> resendOtp(BuildContext context, String mobileNumber) async {
    try {
      var params = {
        "mobileNumber": mobileNumber
      };

      var response = await http.put(
          Uri.parse('${ApiUrls.baseUrlApi}/auth/resendOtp'),
          body: json.encode(params),
          headers: {
            'Content-Type': 'application/json',
          }
      ).timeout(const Duration(seconds: 30));

      return loginResponseFromJson(response.body);
    } catch (e) {
      showCustomToast(context, "Network error. Please try again.");
      return null;
    }
  }
}