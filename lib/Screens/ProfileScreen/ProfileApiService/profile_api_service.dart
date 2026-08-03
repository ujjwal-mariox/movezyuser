import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/Screens/ProfileScreen/Model/user_profile_response.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';
import 'package:http/http.dart' as http;

/// Raised when the profile could not be loaded.
///
/// [message] carries the server's own message whenever it sent one, so the
/// screen can show the real reason instead of a generic failure.
class ProfileApiException implements Exception {
  ProfileApiException(this.message);

  final String message;

  @override
  String toString() => 'ProfileApiException: $message';
}

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

  /// Fetch user profile data.
  ///
  /// Throws [ProfileApiException] on failure instead of returning null. The
  /// caller has to be able to tell "the request failed" apart from "it
  /// succeeded and this account simply has no name or email yet" — ProfileScreen
  /// renders placeholder text for the second case and must not render it for
  /// the first.
  ///
  /// It also no longer raises a toast of its own. Every successful fetch used to
  /// toast the response message, and GET /user/profile answers with the message
  /// key `success` (user.controller `getDetails` sets `req.msg = "success"`), so
  /// a bare "success" popped up each time this screen loaded. User-facing
  /// messaging belongs to the screen.
  Future<UserProfileResponse> getUserProfile() async {
    debugPrint('$_tag - Fetching user profile');

    final response = await _fetch();

    debugPrint('$_tag - Response status: ${response.statusCode}');

    // The backend envelope is { code, message, data }; ResponseMiddleware maps
    // the non-success codes onto 400/401/403/404, so a 200 is the only success.
    if (response.statusCode != 200) {
      throw ProfileApiException(_errorMessage(response.body));
    }

    try {
      return userProfileResponseFromJson(response.body);
    } catch (e) {
      debugPrint('$_tag - Parse error: $e');
      throw ProfileApiException("We couldn't read the profile the server sent.");
    }
  }

  /// The network call on its own, so a transport failure becomes a
  /// [ProfileApiException] with a message worth showing.
  Future<http.Response> _fetch() async {
    try {
      return await http
          .get(
            Uri.parse(ApiUrls.userProfileUrl),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: _timeoutSeconds));
    } on TimeoutException {
      throw ProfileApiException(
        'The server took too long to respond. Please try again.',
      );
    } catch (e) {
      debugPrint('$_tag - Network error: $e');
      throw ProfileApiException(
        'Could not reach the server. Check your connection and try again.',
      );
    }
  }

  /// Pull the server's message out of a `{ code, message, data }` error body.
  String _errorMessage(String responseBody) {
    try {
      final decoded = json.decode(responseBody);
      final message = decoded is Map ? decoded['message'] : null;
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    } catch (e) {
      debugPrint('$_tag - Error parsing: $e');
    }
    return 'Failed to fetch profile';
  }
}
