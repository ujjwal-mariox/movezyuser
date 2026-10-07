import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';

/// Calls the other party through the platform caller ID.
/// If bridging fails, numbers stay hidden and chat remains available.
class MaskedCallService {
  MaskedCallService._();

  static void _snack(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  static Future<void> callDriver(BuildContext context, String bookingId) async {
    if (bookingId.isEmpty) return;
    try {
      final res = await http
          .post(
            Uri.parse(ApiUrls.bookingCallUrl(bookingId)),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${Prefs.getString('token')}',
            },
          )
          .timeout(const Duration(seconds: 20));
      if (!context.mounted) return;
      final body = jsonDecode(res.body);
      final data = body is Map ? (body['data'] ?? {}) : {};
      final mode = (data is Map ? data['mode'] : null)?.toString() ?? '';
      final accepted =
          res.statusCode == 200 &&
          body is Map &&
          body['success'] != false &&
          data is Map &&
          (data['callId']?.toString().isNotEmpty ?? false);
      final message =
          (data is Map ? data['message'] : null)?.toString() ??
          (body is Map ? body['message']?.toString() : null) ??
          '';

      switch (mode) {
        case 'BRIDGE':
          if (!accepted) {
            _snack(context, 'The call could not be started. Please use chat.');
            return;
          }
          _snack(
            context,
            message.isNotEmpty
                ? message
                : "You'll receive a call in a moment — answer to be connected.",
          );
          return;
        default:
          _snack(
            context,
            mode == 'UNAVAILABLE' && message.isNotEmpty
                ? message
                : 'Calling is unavailable right now. Please use chat.',
          );
      }
    } catch (_) {
      if (!context.mounted) return;
      _snack(context, 'Could not place the call. Please try chat.');
    }
  }
}
