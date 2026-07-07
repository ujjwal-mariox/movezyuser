import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart' show HexColor;
import 'package:http/http.dart' as http;
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';


class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  List<dynamic> _recentOrders = [];
  bool _loadingOrders = true;
  String? _selectedCategory;
  String? _selectedQuestion;
  bool _feedbackSubmitted = false;

  // ─── Issue Categories ───
  static const List<Map<String, dynamic>> _issueCategories = [
    {'id': 'driver_late', 'icon': Icons.schedule, 'label': 'Driver Late', 'color': Color(0xFFFF9800)},
    {'id': 'payment', 'icon': Icons.payment, 'label': 'Payment Issue', 'color': Color(0xFF4CAF50)},
    {'id': 'account', 'icon': Icons.person_outline, 'label': 'Account Issue', 'color': Color(0xFF2196F3)},
    {'id': 'cancellation', 'icon': Icons.cancel_outlined, 'label': 'Cancellation', 'color': Color(0xFFF44336)},
    {'id': 'damaged', 'icon': Icons.broken_image_outlined, 'label': 'Damaged Goods', 'color': Color(0xFF9C27B0)},
    {'id': 'other', 'icon': Icons.help_outline, 'label': 'Other', 'color': Color(0xFF607D8B)},
  ];

  // ─── FAQ per category ───
  static const Map<String, List<Map<String, String>>> _categoryFaqs = {
    'driver_late': [
      {'q': 'My driver hasn\'t arrived yet', 'a': 'If the driver is delayed beyond the estimated time, you can track their live location. If the delay exceeds 10 minutes, you may cancel without charge. We sincerely apologize for the inconvenience.'},
      {'q': 'Driver is not moving', 'a': 'The driver may be stuck in traffic. Please wait 5 minutes. If there\'s no movement, contact the driver directly through the app or raise a ticket for reassignment.'},
      {'q': 'Will I be charged extra for delays?', 'a': 'No, you will not be charged extra due to driver delays. The fare is based on the original estimate at the time of booking.'},
    ],
    'payment': [
      {'q': 'I was charged incorrectly', 'a': 'If you see an incorrect charge, please check the fare breakdown in your trip details. If there\'s still a discrepancy, raise a ticket and we\'ll investigate and refund within 3-5 business days.'},
      {'q': 'My refund hasn\'t been processed', 'a': 'Refunds typically take 5-7 business days. If it\'s been longer, please check with your bank. You can also track refund status in the Wallet section.'},
      {'q': 'Payment failed but amount deducted', 'a': 'If your payment failed but the amount was deducted, it will be auto-refunded within 24-48 hours. If not, please share the transaction ID via a support ticket.'},
    ],
    'account': [
      {'q': 'I can\'t log into my account', 'a': 'Try logging in with your registered phone number and verify the OTP. If you\'re still having trouble, try clearing the app cache or reinstalling the app.'},
      {'q': 'How to update my phone number?', 'a': 'Go to Profile → Edit Profile to update your phone number. You\'ll need to verify the new number with an OTP.'},
      {'q': 'How to delete my account?', 'a': 'To delete your account, go to Profile → Help & Support and raise a ticket with subject "Account Deletion". We\'ll process it within 48 hours.'},
    ],
    'cancellation': [
      {'q': 'Why was I charged a cancellation fee?', 'a': 'A cancellation fee applies when a driver has already been assigned and is en route. This compensates the driver for their time and fuel.'},
      {'q': 'How to cancel my booking?', 'a': 'Go to your active booking → Tap "Cancel". If a driver hasn\'t been assigned yet, cancellation is free. After assignment, a small fee may apply.'},
      {'q': 'Can I get a refund after cancellation?', 'a': 'If you paid in advance, the refund (minus any cancellation fee) will be credited to your wallet or original payment method within 3-5 business days.'},
    ],
    'damaged': [
      {'q': 'My goods were damaged during delivery', 'a': 'We\'re sorry to hear that. Please raise a ticket with photos of the damaged goods and your order ID. Our team will investigate and process compensation within 5-7 business days.'},
      {'q': 'How is compensation calculated?', 'a': 'Compensation is based on the declared value of goods at the time of booking and the extent of damage. Insured deliveries receive full declared value coverage.'},
    ],
    'other': [
      {'q': 'How to contact the driver?', 'a': 'You can call or message the driver directly from the active booking screen. Tap the phone icon next to the driver\'s name.'},
      {'q': 'How to share my ride details?', 'a': 'On the tracking screen, tap the "Share" button to send live tracking details to anyone via WhatsApp, SMS, or other apps.'},
      {'q': 'App is crashing or not working', 'a': 'Try clearing the app cache, updating to the latest version, or reinstalling. If the issue persists, please raise a support ticket with your device details.'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _fetchRecentOrders();
  }

  Future<void> _fetchRecentOrders() async {
    try {
      final token = Prefs.getString('token');
      if (token.isEmpty) {
        if (mounted) setState(() => _loadingOrders = false);
        return;
      }
      final response = await http.get(
        Uri.parse('${ApiUrls.userBookingsUrl}?page=1&limit=3'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'];
        final List bookings = data['bookings'] ?? [];
        if (mounted) setState(() { _recentOrders = bookings; _loadingOrders = false; });
      } else {
        if (mounted) setState(() => _loadingOrders = false);
      }
    } catch (e) {
      debugPrint('Help support fetch orders error: $e');
      if (mounted) setState(() => _loadingOrders = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HexColor("#FFEDE2"),
      body: SingleChildScrollView(
        child: Column(
          children: [

            commonAppBar(
                height : 105,
                context : context,
                child: Container(
                  padding: const EdgeInsets.only(top: 50),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: (){
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: EdgeInsets.only(left: 16),
                          width: 40,
                          height: 35,
                          alignment: Alignment.center,
                          child: Icon(Icons.arrow_back_ios, color: Colors.white,),
                        ),
                      ),

                      SizedBox(width: 5,),

                      Text(
                        "Help & Support",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Spacer(),
                    ],
                  ),
                )
            ),


            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "How can we help you?",
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Please get in touch and we will be happy to help you.",
                          style: TextStyle(fontSize: 13, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 115,
                    child: Image(
                      image: AssetImage("assets/help_icon.png"),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 5),

            // ─── RECENT ORDERS (real data) ───
            _buildRecentOrdersSection(),

            const SizedBox(height: 20),

            // ─── ISSUE CATEGORIES ───
            _buildIssueCategoriesSection(),

            // ─── FAQ for selected category ───
            if (_selectedCategory != null) ...[
              const SizedBox(height: 20),
              _buildCategoryFaqSection(),
            ],

            // ─── Answer display with auto-resolution ───
            if (_selectedQuestion != null) ...[
              const SizedBox(height: 16),
              _buildAnswerSection(),
            ],

            // ─── Tap-based Feedback ───
            if (_selectedQuestion != null) ...[
              const SizedBox(height: 20),
              _buildTapFeedback(),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ─── RECENT ORDERS ───
  Widget _buildRecentOrdersSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Need help with recent orders?", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          if (_loadingOrders)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2)))
          else if (_recentOrders.isEmpty)
            Container(
              width: double.infinity, padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: const Text("No recent orders", style: TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
            )
          else
            ..._recentOrders.map((order) => _buildOrderCard(order)),
        ],
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final bookingNumber = order['bookingNumber'] ?? 'N/A';
    final bookingId = order['_id']?.toString();
    final status = order['status'] ?? 'UNKNOWN';
    final vehicleName = order['vehicleTypeId']?['name'] ?? 'Vehicle';
    final pickupAddr = order['pickup']?['address'] ?? '';
    final dropAddr = order['drop']?['address'] ?? '';

    Color statusColor = Colors.grey;
    if (status == 'COMPLETED') {
      statusColor = Colors.green;
    } else if (status == 'CANCELLED') statusColor = Colors.red;
    else if (status == 'ACTIVE' || status == 'DRIVER_ASSIGNED') statusColor = Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text("#$bookingNumber", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(vehicleName, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          if (pickupAddr.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green)),
              const SizedBox(width: 6),
              Expanded(child: Text(pickupAddr, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
          ],
          if (dropAddr.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red)),
              const SizedBox(width: 6),
              Expanded(child: Text(dropAddr, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () => _showReportDialog(bookingId: bookingId, bookingNumber: bookingNumber),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(border: Border.all(color: HexColor("#EE6A2C")), borderRadius: BorderRadius.circular(8)),
                child: Text("Report Issue", style: TextStyle(color: HexColor("#EE6A2C"), fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── ISSUE CATEGORIES ───
  Widget _buildIssueCategoriesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("What do you need help with?", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, childAspectRatio: 1.1, mainAxisSpacing: 10, crossAxisSpacing: 10,
            ),
            itemCount: _issueCategories.length,
            itemBuilder: (context, index) {
              final cat = _issueCategories[index];
              final isSelected = _selectedCategory == cat['id'];
              return InkWell(
                onTap: () => setState(() { _selectedCategory = cat['id']; _selectedQuestion = null; _feedbackSubmitted = false; }),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(14),
                    border: isSelected ? Border.all(color: AppColors.appColor, width: 2) : null,
                    boxShadow: isSelected ? [BoxShadow(color: AppColors.appColor.withOpacity(0.15), blurRadius: 8)] : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: (cat['color'] as Color).withOpacity(0.12), shape: BoxShape.circle),
                        child: Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(cat['label'] as String, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── FAQ FOR SELECTED CATEGORY ───
  Widget _buildCategoryFaqSection() {
    final faqs = _categoryFaqs[_selectedCategory] ?? [];
    final catLabel = _issueCategories.firstWhere((c) => c['id'] == _selectedCategory)['label'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Common questions — $catLabel", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...faqs.map((faq) {
            final isSelected = _selectedQuestion == faq['q'];
            return InkWell(
              onTap: () => setState(() { _selectedQuestion = faq['q']; _feedbackSubmitted = false; }),
              child: Container(
                width: double.infinity, margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFF3EC) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected ? Border.all(color: AppColors.appColor) : null,
                ),
                child: Row(children: [
                  Expanded(child: Text(faq['q']!, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500))),
                  Icon(isSelected ? Icons.keyboard_arrow_down : Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── ANSWER WITH AUTO-RESOLUTION GUIDANCE ───
  Widget _buildAnswerSection() {
    final faqs = _categoryFaqs[_selectedCategory] ?? [];
    final faq = faqs.firstWhere((f) => f['q'] == _selectedQuestion, orElse: () => {'q': '', 'a': ''});
    if (faq['a']?.isEmpty ?? true) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.lightbulb_outline, color: Colors.green.shade600, size: 20),
              const SizedBox(width: 8),
              const Text("Resolution", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.green)),
            ]),
            const SizedBox(height: 10),
            Text(faq['a']!, style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF444444))),
          ],
        ),
      ),
    );
  }

  // ─── TAP-BASED FEEDBACK ───
  Widget _buildTapFeedback() {
    if (_feedbackSubmitted) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: double.infinity, padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text("Thank you for your feedback!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          const Text("Was this helpful?", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _feedbackButton('👍', 'Yes', Colors.green),
            const SizedBox(width: 16),
            _feedbackButton('👎', 'No', Colors.red),
            const SizedBox(width: 16),
            _feedbackButton('💬', 'Need More Help', AppColors.appColor),
          ]),
        ]),
      ),
    );
  }

  /// Create a real support ticket from the selected category/question
  /// (previously "Need More Help" only showed a snackbar, saved nothing).
  Future<bool> _raiseTicket({
    String? messageOverride,
    String? subjectOverride,
    String? bookingId,
  }) async {
    final category = _selectedCategory ?? 'other';
    final subject = subjectOverride?.trim().isNotEmpty == true
        ? subjectOverride!.trim()
        : (_selectedQuestion ?? 'Need help with $category');
    // When the user typed a description (via "Report Issue"), send that as the
    // ticket body; otherwise fall back to the subject.
    final messageBody = messageOverride?.trim().isNotEmpty == true
        ? messageOverride!.trim()
        : subject;
    try {
      final token = Prefs.token;
      final res = await http.post(
        Uri.parse(ApiUrls.supportTicketsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'category': category,
          'subject': subject,
          'message': messageBody,
          if (bookingId != null && bookingId.isNotEmpty) 'bookingId': bookingId,
        }),
      ).timeout(const Duration(seconds: 15));
      final resBody = json.decode(res.body);
      final ok = (res.statusCode == 200 || res.statusCode == 201) &&
          resBody['success'] == true;
      if (!mounted) return ok;
      setState(() => _feedbackSubmitted = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Ticket created. A support agent will contact you shortly.'
            : 'Could not create ticket. Please try again.'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ));
      return ok;
    } catch (_) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not create ticket. Please try again.'),
        backgroundColor: Colors.red,
      ));
      return false;
    }
  }

  /// Opens a dialog letting the user describe an issue with a specific booking,
  /// then files a real support ticket (POST /support/tickets → visible to admin
  /// under Support Tickets). Previously the "Report Issue" button only flipped
  /// an internal category and did nothing the user could see.
  Future<void> _showReportDialog({String? bookingId, String? bookingNumber}) async {
    final controller = TextEditingController();
    bool submitting = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            bookingNumber != null && bookingNumber != 'N/A'
                ? 'Report Issue · #$bookingNumber'
                : 'Report Issue',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Describe what went wrong. Our support team will review it.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'e.g. Driver took a wrong route and overcharged me',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      final text = controller.text.trim();
                      if (text.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                          content: Text('Please describe the issue first.'),
                        ));
                        return;
                      }
                      setInner(() => submitting = true);
                      final ok = await _raiseTicket(
                        messageOverride: text,
                        subjectOverride: bookingNumber != null &&
                                bookingNumber != 'N/A'
                            ? 'Issue with booking #$bookingNumber'
                            : 'Reported issue',
                        bookingId: bookingId,
                      );
                      if (ctx.mounted && ok) Navigator.pop(ctx);
                      if (!ok) setInner(() => submitting = false);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: HexColor("#EE6A2C"),
                foregroundColor: Colors.white,
              ),
              child: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feedbackButton(String emoji, String label, Color color) {
    return InkWell(
      onTap: () {
        if (label == 'Need More Help') {
          _raiseTicket();
          return;
        }
        setState(() => _feedbackSubmitted = true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Thanks for your feedback!'),
          backgroundColor: Colors.green,
        ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }
}