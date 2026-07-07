import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/Screens/ProfileScreen/Model/user_profile_response.dart';
import 'package:movezy_user_app/Utils/CustomToast/custome_toast.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';
import 'package:http/http.dart' as http;

class ProfileApiService {
  static const String _tag = 'ProfileApiService';
  static const int _timeoutSeconds = 30;

  /// Get authorization headers with token
  Map<String, String> _getHeaders() {
    final token = Prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Fetch user profile data
  Future<UserProfileResponse?> getUserProfile({
    required BuildContext context,
  }) async {
    try {
      debugPrint('$_tag - Fetching user profile');

      final response = await http
          .get(
            Uri.parse(ApiUrls.userProfileUrl),
            headers: _getHeaders(),
          )
          .timeout(
            Duration(seconds: _timeoutSeconds),
            onTimeout: () {
              throw TimeoutException('Request timeout');
            },
          );

      debugPrint('$_tag - Response status: ${response.statusCode}');
      debugPrint('$_tag - Response body: ${response.body}');

      if (response.statusCode == 200) {
        final profileData = userProfileResponseFromJson(response.body);
        if (context.mounted) {
          final message = profileData.message ?? 'Profile fetched successfully';
          showCustomToast(context, message);
        }
        return profileData;
      } else {
        if (context.mounted) {
          _handleError(response.body, context);
        }
        return null;
      }
    } catch (e) {
      debugPrint('$_tag - Error: $e');
      if (context.mounted) {
        showCustomToast(context, 'Error fetching profile data');
      }
      return null;
    }
  }

  /// Handle error responses and show toast
  void _handleError(String responseBody, BuildContext context) {
    try {
      final responseData = json.decode(responseBody) as Map<String, dynamic>;
      final message = responseData['message'] as String? ?? 'Failed to fetch profile';
      if (context.mounted) {
        showCustomToast(context, message);
      }
    } catch (e) {
      debugPrint('$_tag - Error parsing: $e');
      if (context.mounted) {
        showCustomToast(context, 'Failed to fetch profile');
      }
    }
  }
}