import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/Screens/LoginScreen/Model/login_response.dart';
import 'package:movezy_user_app/Screens/OtpScreen/otp_screen.dart';
import 'package:movezy_user_app/Utils/CustomToast/custome_toast.dart';
import 'package:http/http.dart' as http;


class LoginApiService {
  Future<LoginResponse> loginApi(BuildContext context, String mobileNumber) async {

    var params = {
      "countryCode": "+91",
      "mobileNumber": mobileNumber
    };

    var response = await http.post(Uri.parse(ApiUrls.loginUrl),
      body: json.encode(params),
        headers: {
          'Content-Type': 'application/json',
        }
    );

    print("login params $params");
    print("login response ${response.body}");

    var dataT = loginResponseFromJson(response.body);

    if(response.statusCode == 200)
    {
      pushTo(context, OtpScreen(mobileNumber: mobileNumber, token: dataT.data?.txnId.toString() ?? "",));
    }
    else
    {
      showCustomToast(context, dataT.data?.txnId.toString() ?? "",);
    }

    return loginResponseFromJson(response.body);
  }
}