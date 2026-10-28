import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';
import 'package:url_launcher/url_launcher.dart';

const _red = Color(0xFFDC2626);

/// The red "SOS" pill for the trip screen's orange header. Shown only while a
/// driver is on the booking (assigned → delivered).
class SosPill extends StatelessWidget {
  final String bookingId;
  const SosPill({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => showSosSheet(context, bookingId: bookingId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _red,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emergency, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text('SOS',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

/// SOS, two deliberate taps: this sheet, then "Send SOS alert" (live location
/// to the Movezy safety team's SOS dashboard) or "Call 112". The driver is not
/// told — if the driver is the threat, an alert would warn them.
Future<void> showSosSheet(BuildContext context, {required String bookingId}) async {
  HapticFeedback.mediumImpact();
  final choice = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const _SosConfirmSheet(),
  );
  if (!context.mounted) return;
  if (choice == 'send') {
    HapticFeedback.heavyImpact();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SosResultDialog(send: () => _sendSos(bookingId)),
    );
  } else if (choice == 'call') {
    await _call112();
  }
}

Future<void> _call112() async {
  final dialer = Uri(scheme: 'tel', path: '112');
  if (await canLaunchUrl(dialer)) await launchUrl(dialer);
}

/// True only when the server accepted the alert, so the result shown is real.
Future<bool> _sendSos(String bookingId) async {
  try {
    Position? position;
    try {
      // One overall limit: an emergency alert must never spin forever on a
      // permission check or GPS fix that does not answer.
      position = await () async {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        return Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );
      }()
          .timeout(const Duration(seconds: 12));
    } catch (_) {
      position = null;
    }
    if (position == null) {
      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (_) {}
    }
    // The server needs a real location; without one, don't claim it was sent.
    if (position == null) return false;

    final response = await http
        .post(
          Uri.parse(ApiUrls.sosTriggerUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${Prefs.getString('token')}',
          },
          body: jsonEncode({
            'location': {'lat': position.latitude, 'lng': position.longitude},
            'bookingId': bookingId,
          }),
        )
        .timeout(const Duration(seconds: 12));
    final body = jsonDecode(response.body);
    return (response.statusCode == 200 || response.statusCode == 201) &&
        (body['success'] == true || body['code'] == 1);
  } catch (e) {
    debugPrint('SOS failed: $e');
    return false;
  }
}

class _SosConfirmSheet extends StatelessWidget {
  const _SosConfirmSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.emergency, color: _red, size: 28),
                const SizedBox(width: 10),
                Text('Emergency SOS',
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Sending an alert shares your live location with the Movezy '
              'safety team straight away. If anyone is in danger, call 112.',
              style: GoogleFonts.poppins(
                  fontSize: 13, height: 1.45, color: Colors.black87),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, 'send'),
                icon: const Icon(Icons.campaign_outlined),
                label: Text('Send SOS alert',
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, 'call'),
                icon: const Icon(Icons.phone, color: _red),
                label: Text('Call 112',
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w700, color: _red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _red, width: 1.4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel',
                    style: GoogleFonts.poppins(color: Colors.black54)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Sending…", then the real outcome, always with a Call 112 button.
class _SosResultDialog extends StatefulWidget {
  final Future<bool> Function() send;
  const _SosResultDialog({required this.send});

  @override
  State<_SosResultDialog> createState() => _SosResultDialogState();
}

class _SosResultDialogState extends State<_SosResultDialog> {
  bool _loading = true;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    widget.send().then((ok) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _success = ok;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final message = _loading
        ? 'Sending emergency alert…'
        : _success
            ? 'Alert sent. The Movezy safety team has your live location and '
                'will contact you. If you are in danger, call 112 now.'
            : 'Could not send the alert (no network or location). Please call 112 directly.';
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.emergency, color: _red, size: 26),
          const SizedBox(width: 10),
          Text('Emergency alert',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17)),
        ],
      ),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: _red),
            )
          else
            Icon(_success ? Icons.check_circle : Icons.error_outline,
                color: _success ? Colors.green : _red, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: GoogleFonts.poppins(fontSize: 13, height: 1.45))),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: Text('Close', style: GoogleFonts.poppins(color: Colors.black54)),
        ),
        ElevatedButton.icon(
          onPressed: _call112,
          icon: const Icon(Icons.phone, size: 18),
          label: Text('Call 112', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
