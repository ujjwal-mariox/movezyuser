import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/Utils/CustomToast/custome_toast.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';
import 'package:http/http.dart' as http;

class UpdateProfileApiService {
  static const String _tag = 'UpdateProfileApiService';
  static const int _timeoutSeconds = 30;

  /// Get authorization headers with token
  Map<String, String> _getHeaders({bool isMultipart = false}) {
    final token = Prefs.getString('token');
    return {
      'Authorization': 'Bearer $token',
      if (!isMultipart) 'Content-Type': 'application/json',
    };
  }

  /// Build request parameters, excluding null/empty values
  Map<String, String> _buildParams({
    required String fullName,
    String? email,
    String? gender,
    String? dob,
  }) {
    return {
      'fullName': fullName,
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (gender != null && gender.trim().isNotEmpty) 'gender': gender.trim(),
      if (dob != null && dob.trim().isNotEmpty) 'dob': dob.trim(),
    };
  }

  /// Handle API response and show appropriate toast message
  bool _handleResponse(http.Response response, BuildContext context) {
    try {
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        final message = responseData['message'] as String? ?? 'Profile updated successfully';
        if (context.mounted) {
          showCustomToast(context, message);
        }
        return true;
      } else {
        _handleError(response.body, context);
        return false;
      }
    } catch (e) {
      debugPrint('$_tag - Response parsing error: $e');
      if (context.mounted) {
        showCustomToast(context, 'Failed to update profile');
      }
      return false;
    }
  }

  /// Handle error responses and show toast
  void _handleError(String responseBody, BuildContext context) {
    try {
      final responseData = json.decode(responseBody) as Map<String, dynamic>;
      final message = responseData['message'] as String? ?? 'Failed to update profile';
      if (context.mounted) {
        showCustomToast(context, message);
      }
    } catch (e) {
      debugPrint('$_tag - Error parsing: $e');
      if (context.mounted) {
        showCustomToast(context, 'Failed to update profile');
      }
    }
  }

  /// Update user profile with optional image
  Future<bool> updateUserProfile({
    required BuildContext context,
    required String fullName,
    String? email,
    String? gender,
    String? dob,
    File? profileImage,
  }) async {
    try {
      // Validate required field
      if (fullName.trim().isEmpty) {
        if (context.mounted) {
          showCustomToast(context, 'Full name is required');
        }
        return false;
      }

      final url = Uri.parse('${ApiUrls.baseUrlApi}/user/profile');

      if (profileImage != null) {
        return await _updateWithImage(
          context: context,
          url: url,
          fullName: fullName,
          email: email,
          gender: gender,
          dob: dob,
          profileImage: profileImage,
        );
      } else {
        return await _updateWithoutImage(
          context: context,
          url: url,
          fullName: fullName,
          email: email,
          gender: gender,
          dob: dob,
        );
      }
    } catch (e) {
      debugPrint('$_tag - Exception: $e');
      if (context.mounted) {
        showCustomToast(context, 'Error updating profile');
      }
      return false;
    }
  }

  /// Update profile with image using multipart request
  Future<bool> _updateWithImage({
    required BuildContext context,
    required Uri url,
    required String fullName,
    String? email,
    String? gender,
    String? dob,
    required File profileImage,
  }) async {
    try {
      // Validate image file exists
      if (!await profileImage.exists()) {
        if (context.mounted) {
          showCustomToast(context, 'Image file not found');
        }
        return false;
      }

      final request = http.MultipartRequest('PUT', url)
        ..headers.addAll(_getHeaders(isMultipart: true));

      // Add fields
      final params = _buildParams(
        fullName: fullName,
        email: email,
        gender: gender,
        dob: dob,
      );

      request.fields.addAll(params);

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'profileImage',
          profileImage.path,
        ),
      );

      debugPrint('$_tag - Sending multipart request to: $url');

      final streamedResponse = await request.send().timeout(
        Duration(seconds: _timeoutSeconds),
        onTimeout: () {
          throw TimeoutException('Request timeout');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('$_tag - Response status: ${response.statusCode}');
      debugPrint('$_tag - Response body: ${response.body}');

      if (context.mounted) {
        return _handleResponse(response, context);
      }
      return false;
    } catch (e) {
      debugPrint('$_tag - Multipart error: $e');
      if (context.mounted) {
        showCustomToast(context, 'Error updating profile');
      }
      return false;
    }
  }

  /// Update profile without image using JSON request
  Future<bool> _updateWithoutImage({
    required BuildContext context,
    required Uri url,
    required String fullName,
    String? email,
    String? gender,
    String? dob,
  }) async {
    try {
      final params = _buildParams(
        fullName: fullName,
        email: email,
        gender: gender,
        dob: dob,
      );

      debugPrint('$_tag - Sending JSON request to: $url');
      debugPrint('$_tag - Request body: $params');

      final response = await http
          .put(
            url,
            body: json.encode(params),
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

      if (context.mounted) {
        return _handleResponse(response, context);
      }
      return false;
    } catch (e) {
      debugPrint('$_tag - JSON request error: $e');
      if (context.mounted) {
        showCustomToast(context, 'Error updating profile');
      }
      return false;
    }
  }
}