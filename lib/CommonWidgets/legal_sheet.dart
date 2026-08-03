import 'package:flutter/material.dart';

/// Terms & Privacy, in one place.
///
/// This text lived as private consts inside ProfileScreen, so the identical
/// "Terms of use" / "Privacy Policy" links on the login and OTP screens had
/// nothing to open — they were styled link-blue but carried no recognizer, and
/// tapping them did nothing at all. A user is asked to agree to these before
/// they can sign in, so they have to be readable at that point.
class LegalText {
  static const String terms = '''
1. By using Movezy, you agree to our terms of service.
2. All deliveries are subject to availability and verification.
3. Cancellation charges may apply after a driver has been assigned.
4. Users must ensure goods are packed properly before pickup.
5. Restricted or prohibited items are not allowed for delivery.
6. Movezy is not responsible for items not declared at the time of booking.
7. Payment must be completed before or upon delivery as per the selected method.
8. Movezy reserves the right to modify pricing and terms at any time.
''';

  static const String privacy = '''
1. We collect your name, phone, email, and location to provide delivery services.
2. Your data is encrypted and stored securely.
3. We do not sell your personal information to third parties.
4. Location data is used only to facilitate pickups and deliveries.
5. Payment information is processed through secure payment gateways.
6. You can request account deletion by contacting support.
7. We may use anonymized data for analytics and service improvement.
8. Push notifications are used for order updates and promotions.
''';
}

void showLegalSheet(BuildContext context, String title, String content) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
              InkWell(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Text(content,
                  style: const TextStyle(
                      fontSize: 14, height: 1.6, color: Color(0xFF444444))),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}
