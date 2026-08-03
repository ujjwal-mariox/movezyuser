import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/Screens/LoginScreen/Model/login_response.dart';
import 'package:movezy_user_app/Screens/OtpScreen/otp_screen.dart';
import 'package:movezy_user_app/Utils/CustomToast/custome_toast.dart';
import 'package:http/http.dart' as http;


class LoginApiService {
  /// [whatsappOptIn] is the login screen's WhatsApp-updates checkbox. It used
  /// to live only in widget state, so the customer's consent — opt-in or
  /// opt-out — was never recorded anywhere.
  Future<LoginResponse> loginApi(BuildContext context, String mobileNumber,
      {bool whatsappOptIn = false}) async {
    try {
      var params = {
        "countryCode": "+91",
        "mobileNumber": mobileNumber,
        "whatsappOptIn": whatsappOptIn
      };

      var response = await http.post(Uri.parse(ApiUrls.loginUrl),
        body: json.encode(params),
          headers: {
            'Content-Type': 'application/json',
          }
      ).timeout(const Duration(seconds: 30));

      print("login URL: ${ApiUrls.loginUrl}");
      print("login params $params");
      print("login status: ${response.statusCode}");
      print("login response ${response.body}");

      var dataT = loginResponseFromJson(response.body);

      if(response.statusCode == 200)
      {
        pushTo(context, OtpScreen(mobileNumber: mobileNumber, token: dataT.data?.txnId.toString() ?? "",));
      }
      else
      {
        showCustomToast(context, dataT.message?.toString() ?? "Login failed. Please try again.");
      }

      return dataT;
    } catch (e) {
      showCustomToast(context, "Network error. Please try again.");
      rethrow;
    }
  }
}