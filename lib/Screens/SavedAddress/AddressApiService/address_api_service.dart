import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Models/address_model.dart';
import '../../../ApiUrls/api_urls.dart';
import '../../../Utils/PrefsManager/prefs_manager.dart';
import '../../../Utils/CustomToast/custome_toast.dart';

class AddressApiService {
  // Create new address
  static Future<AddressResponse?> createAddress({
    required String fullName,
    required String mobileNumber,
    required String houseNo,
    required String area,
    required String city,
    required String state,
    required String country,
    required int pinCode,
    required String addressType,
    required double latitude,
    required double longitude,
    required BuildContext context,
  }) async {
    try {
      final token = Prefs.getString('token');
      print('📍 CREATE: Token = $token');
      if (token.isEmpty) {
        if (context.mounted) {
          showCustomToast(context, 'Please login to continue');
        }
        return null;
      }

      final url = '${ApiUrls.baseUrlApi}/user/address';
      
      // Sanitize all string inputs
      final sanitizedFullName = _sanitizeInput(fullName);
      final sanitizedMobile = _sanitizeInput(mobileNumber);
      final sanitizedHouseNo = _sanitizeInput(houseNo);
      final sanitizedArea = _sanitizeInput(area);
      final sanitizedCity = _sanitizeInput(city);
      final sanitizedState = _sanitizeInput(state);
      final sanitizedCountry = _sanitizeInput(country);
      
      final body = jsonEncode({
        'fullName': sanitizedFullName,
        'mobileNumber': sanitizedMobile,
        'houseNo': sanitizedHouseNo,
        'area': sanitizedArea,
        'city': sanitizedCity,
        'state': sanitizedState,
        'country': sanitizedCountry,
        'pinCode': pinCode,
        'addressType': addressType,
        'latitude': latitude,
        'longitude': longitude,
      });
      
      print('📍 CREATE: URL = $url');
      print('📍 CREATE: Body = $body');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print('📍 CREATE: Status Code = ${response.statusCode}');
      print('📍 CREATE: Response = ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (context.mounted) {
          showCustomToast(context, 'Address added successfully');
        }
        return AddressResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 401) {
        if (context.mounted) {
          showCustomToast(context, 'Session expired. Please login again');
        }
        return null;
      } else {
        if (context.mounted) {
          final error = jsonDecode(response.body);
          showCustomToast(context, error['message'] ?? 'Failed to create address');
        }
        return null;
      }
    } catch (e) {
      print('📍 CREATE: Exception = $e');
      if (context.mounted) {
        showCustomToast(context, 'Error: ${e.toString()}');
      }
      return null;
    }
  }

  // Get all addresses with pagination
  static Future<AddressListResponse?> getAddresses({
    required int page,
    required int limit,
    required BuildContext context,
  }) async {
    try {
      final token = Prefs.getString('token');
      print('📍 DEBUG: Token = $token');
      if (token.isEmpty) {
        if (context.mounted) {
          showCustomToast(context, 'Please login to continue');
        }
        return null;
      }

      final url = '${ApiUrls.baseUrlApi}/user/address?page=$page&limit=$limit';
      print('📍 DEBUG: Fetching addresses from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📍 DEBUG: Status Code: ${response.statusCode}');
      print('📍 DEBUG: Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('📍 DEBUG: Parsed JSON: $jsonResponse');
        final result = AddressListResponse.fromJson(jsonResponse);
        print('📍 DEBUG: Addresses count: ${result.addresses.length}');
        return result;
      } else if (response.statusCode == 401) {
        if (context.mounted) {
          showCustomToast(context, 'Session expired. Please login again');
        }
        return null;
      } else {
        print('📍 DEBUG: Error response: ${response.statusCode}');
        if (context.mounted) {
          showCustomToast(context, 'Failed to load addresses (${response.statusCode})');
        }
        return null;
      }
    } catch (e) {
      print('📍 DEBUG: Exception: $e');
      if (context.mounted) {
        showCustomToast(context, 'Error: ${e.toString()}');
      }
      return null;
    }
  }

  // Update existing address
  static Future<AddressResponse?> updateAddress({
    required String addressId,
    required String houseNo,
    required String area,
    required String city,
    required String state,
    required int pinCode,
    required BuildContext context,
  }) async {
    try {
      final token = Prefs.getString('token');
      if (token.isEmpty) {
        if (context.mounted) {
          showCustomToast(context, 'Please login to continue');
        }
        return null;
      }

      // Sanitize all string inputs
      final sanitizedHouseNo = _sanitizeInput(houseNo);
      final sanitizedArea = _sanitizeInput(area);
      final sanitizedCity = _sanitizeInput(city);
      final sanitizedState = _sanitizeInput(state);

      final response = await http.put(
        Uri.parse('${ApiUrls.baseUrlApi}/user/address/$addressId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'houseNo': sanitizedHouseNo,
          'area': sanitizedArea,
          'city': sanitizedCity,
          'state': sanitizedState,
          'pinCode': pinCode,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (context.mounted) {
          showCustomToast(context, 'Address updated successfully');
        }
        return AddressResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 401) {
        if (context.mounted) {
          showCustomToast(context, 'Session expired. Please login again');
        }
        return null;
      } else {
        if (context.mounted) {
          final error = jsonDecode(response.body);
          showCustomToast(context, error['message'] ?? 'Failed to update address');
        }
        return null;
      }
    } catch (e) {
      if (context.mounted) {
        showCustomToast(context, 'Error: ${e.toString()}');
      }
      return null;
    }
  }

  // Delete address
  static Future<bool> deleteAddress({
    required String addressId,
    required BuildContext context,
  }) async {
    try {
      final token = Prefs.getString('token');
      if (token.isEmpty) {
        if (context.mounted) {
          showCustomToast(context, 'Please login to continue');
        }
        return false;
      }

      final response = await http.delete(
        Uri.parse('${ApiUrls.baseUrlApi}/user/address/$addressId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        if (context.mounted) {
          showCustomToast(context, 'Address deleted successfully');
        }
        return true;
      } else if (response.statusCode == 401) {
        if (context.mounted) {
          showCustomToast(context, 'Session expired. Please login again');
        }
        return false;
      } else {
        if (context.mounted) {
          final error = jsonDecode(response.body);
          showCustomToast(context, error['message'] ?? 'Failed to delete address');
        }
        return false;
      }
    } catch (e) {
      if (context.mounted) {
        showCustomToast(context, 'Error: ${e.toString()}');
      }
      return false;
    }
  }

  // Get all addresses without pagination
  static Future<List<AddressModel>> getAllAddresses({
    required BuildContext context,
  }) async {
    try {
      final token = Prefs.getString('token');
      if (token.isEmpty) {
        return [];
      }

      final response = await http.get(
        Uri.parse('${ApiUrls.baseUrlApi}/user/address?limit=1000'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final listResponse = AddressListResponse.fromJson(jsonResponse);
        return listResponse.addresses;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Sanitize string input: trim, remove extra spaces
  static String _sanitizeInput(String input) {
    if (input.isEmpty) return '';
    // Trim leading/trailing whitespace
    String sanitized = input.trim();
    // Remove multiple consecutive spaces
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');
    // Remove special characters except common address characters
    sanitized = sanitized.replaceAll(RegExp(r'[^\w\s,.\-/()&]'), '');
    return sanitized;
  }
}
