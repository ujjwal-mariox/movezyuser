import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';
import 'package:url_launcher/url_launcher.dart';

/// Calls the driver WITHOUT the app ever holding their number.
///
/// The server bridges the call through the platform's telephony number, so
/// both handsets only see Movezy's number. When bridging is not configured
/// the server may hand back a number to dial directly — the app never
/// decides that on its own.
class MaskedCallService {
  MaskedCallService._();

  static void _snack(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  static Future<void> callDriver(BuildContext context, String bookingId) async {
    if (bookingId.isEmpty) return;
    _snack(context, 'Connecting your call…');
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
      final body = jsonDecode(res.body);
      final data = body is Map ? (body['data'] ?? {}) : {};
      final mode = (data is Map ? data['mode'] : null)?.toString() ?? '';
      final message = (data is Map ? data['message'] : null)?.toString() ??
          (body is Map ? body['message']?.toString() : null) ??
          '';

      switch (mode) {
        case 'BRIDGE':
          _snack(context, message.isNotEmpty ? message : "You'll receive a call in a moment — answer to be connected.");
          return;
        case 'DIRECT':
          final number = (data is Map ? data['number'] : null)?.toString() ?? '';
          if (number.isEmpty) {
            _snack(context, 'Driver number unavailable');
            return;
          }
          final opened = await launchUrl(Uri(scheme: 'tel', path: number));
          if (!opened) _snack(context, 'Could not open the dialer');
          return;
        default:
          _snack(context, message.isNotEmpty ? message : 'Calling is unavailable right now. Please use chat.');
      }
    } catch (_) {
      _snack(context, 'Could not place the call. Please try chat.');
    }
  }
}
