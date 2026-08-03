import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart' show HexColor;
import 'package:http/http.dart' as http;
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/Screens/HelpSupportScreen/support_tickets_screen.dart';
import 'package:movezy_user_app/Services/support_service.dart';
import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';
import 'package:url_launcher/url_launcher.dart';


class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  List<dynamic> _recentOrders = [];
  bool _loadingOrders = true;

  /// Why the recent orders could not be loaded. Null when the request
  /// succeeded — an empty [_recentOrders] then really does mean "no orders".
  String? _ordersError;

  /// False when retrying cannot possibly help (no session token).
  bool _ordersCanRetry = true;

  /// Support number from GET /v1/api/support-contact
  /// (`{ success, data: { supportPhone } }`, set by admin at
  /// /admin/config/support-contact). Empty means no number is configured, and
  /// the call control is then not rendered at all — there is no fallback.
  String _supportPhone = '';

  String? _selectedCategory;
  String? _selectedQuestion;

  /// The confirmation currently shown in place of the "Was this helpful?"
  /// block, or null while nothing has been submitted. This was a bare bool that
  /// always read "Thank you for your feedback!", which was the wrong sentence
  /// for a raised ticket and — worse — was set even when the ticket failed.
  String? _confirmation;

  // FAQs come from the server (seeded into the FAQ collection) rather than
  // being baked into the app, so an answer can be corrected without shipping a
  // release. Note there is no admin CRUD for FAQs yet — editing means touching
  // the DB, and getFAQs caches for an hour, so a change is not instant.
  // Cached per category for the life of the screen.
  final Map<String, List<Faq>> _faqCache = {};
  bool _loadingFaqs = false;
  String? _faqError;

  Future<void> _loadFaqs(String category) async {
    if (_faqCache.containsKey(category)) return;
    setState(() {
      _loadingFaqs = true;
      _faqError = null;
    });
    try {
      final faqs = await SupportService.getFaqs(category);
      if (!mounted) return;
      setState(() {
        _faqCache[category] = faqs;
        _loadingFaqs = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingFaqs = false;
        _faqError = 'Could not load help articles.';
      });
    }
  }

  // ─── Issue Categories ───
  static const List<Map<String, dynamic>> _issueCategories = [
    {'id': 'driver_late', 'icon': Icons.schedule, 'label': 'Driver Late', 'color': Color(0xFFFF9800)},
    {'id': 'payment', 'icon': Icons.payment, 'label': 'Payment Issue', 'color': Color(0xFF4CAF50)},
    {'id': 'account', 'icon': Icons.person_outline, 'label': 'Account Issue', 'color': Color(0xFF2196F3)},
    {'id': 'cancellation', 'icon': Icons.cancel_outlined, 'label': 'Cancellation', 'color': Color(0xFFF44336)},
    {'id': 'damaged', 'icon': Icons.broken_image_outlined, 'label': 'Damaged Goods', 'color': Color(0xFF9C27B0)},
    {'id': 'other', 'icon': Icons.help_outline, 'label': 'Other', 'color': Color(0xFF607D8B)},
  ];

  @override
  void initState() {
    super.initState();
    _fetchRecentOrders();
    _fetchSupportPhone();
  }

  /// Load the three most recent bookings.
  ///
  /// A failure used to be silently reported as "No recent orders", which hid
  /// the Report Issue button behind a sentence that was not true — exactly when
  /// something was wrong and the customer most needed it. Failure and emptiness
  /// are now distinct, and a failure offers Retry.
  Future<void> _fetchRecentOrders() async {
    if (mounted) {
      setState(() {
        _loadingOrders = true;
        _ordersError = null;
        _ordersCanRetry = true;
      });
    }
    try {
      final token = Prefs.getString('token');
      if (token.isEmpty) {
        // GET /bookings sits behind verifyUserToken (booking.routes.ts), so
        // without a token there is nothing to retry.
        if (mounted) {
          setState(() {
            _loadingOrders = false;
            _ordersCanRetry = false;
            _ordersError = 'Sign in to see your recent orders.';
          });
        }
        return;
      }
      final response = await http.get(
        Uri.parse('${ApiUrls.userBookingsUrl}?page=1&limit=3'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }

      // This endpoint answers {success, data:{bookings, pagination}}, and
      // {success:false, message} on failure (booking.controller
      // getUserBookings).
      final ok = response.statusCode == 200 &&
          decoded is Map &&
          decoded['success'] == true;
      if (!mounted) return;
      if (ok) {
        final data = decoded['data'];
        final List bookings =
            (data is Map ? data['bookings'] as List? : null) ?? [];
        setState(() {
          _recentOrders = bookings;
          _loadingOrders = false;
        });
      } else {
        final message = decoded is Map ? decoded['message'] : null;
        setState(() {
          _loadingOrders = false;
          _ordersError = (message is String && message.trim().isNotEmpty)
              ? message.trim()
              : "Couldn't load your recent orders.";
        });
      }
    } catch (e) {
      debugPrint('Help support fetch orders error: $e');
      if (mounted) {
        setState(() {
          _loadingOrders = false;
          _ordersError =
              "Couldn't load your recent orders. Check your connection and try again.";
        });
      }
    }
  }

  /// Load the support number the admin configured.
  ///
  /// Best-effort on purpose: if this fails, [_supportPhone] stays empty and the
  /// call control simply is not shown. There is no fallback number to fall back
  /// to, and inventing one would dial nobody.
  Future<void> _fetchSupportPhone() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiUrls.baseUrlApi}/support-contact'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return;
      final decoded = jsonDecode(response.body);
      final data = decoded is Map ? decoded['data'] : null;
      final phone = data is Map ? data['supportPhone'] : null;
      if (!mounted) return;
      setState(() => _supportPhone = phone is String ? phone.trim() : '');
    } catch (e) {
      debugPrint('Support contact fetch error: $e');
    }
  }

  /// Dial the configured support number.
  ///
  /// The admin may store it formatted (+91-98…, spaces, brackets), so strip
  /// everything a `tel:` URI cannot carry while still showing the configured
  /// string to the user.
  Future<void> _callSupport() async {
    final dialable = _supportPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (dialable.isEmpty) return;
    bool opened = false;
    try {
      opened = await launchUrl(Uri(scheme: 'tel', path: dialable));
    } catch (e) {
      debugPrint('Support dial error: $e');
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the dialer')),
      );
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

            // ─── CALL SUPPORT ───
            // Only rendered when the admin has configured a number.
            if (_supportPhone.isNotEmpty) ...[
              _buildCallSupportCard(),
              const SizedBox(height: 16),
            ],

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

  // ─── CALL SUPPORT ───
  Widget _buildCallSupportCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: _callSupport,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.call_outlined, size: 22, color: HexColor("#EE6A2C")),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Call support",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(_supportPhone,
                        style: const TextStyle(
                            fontSize: 11.5, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade500),
            ],
          ),
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
          // Read replies to tickets you've raised. Without this the app could
          // only ever CREATE tickets — customers had no way to see the answer.
          InkWell(
            onTap: () => pushTo(context, const SupportTicketsScreen()),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.forum_outlined, size: 22, color: HexColor("#EE6A2C")),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("My support tickets",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        SizedBox(height: 2),
                        Text("See replies from our team",
                            style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade500),
                ],
              ),
            ),
          ),
          const Text("Need help with recent orders?", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          if (_loadingOrders)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2)))
          else if (_ordersError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Text(_ordersError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.red)),
                  if (_ordersCanRetry) ...[
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: _fetchRecentOrders,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry'),
                    ),
                  ],
                ],
              ),
            )
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

    // The badge printed the raw database enum — customers saw "DRIVER_ARRIVED"
    // and "IN_PROGRESS". The colour test also checked for statuses the backend
    // never emits ('ACTIVE', 'DRIVER_ASSIGNED'), so every in-flight trip fell
    // through to grey.
    const statusLabels = {
      'DRAFT': 'Scheduled',
      'SEARCHING': 'Finding driver',
      'ASSIGNED': 'Driver assigned',
      'DRIVER_ARRIVED': 'Driver arrived',
      'PICKED': 'Picked up',
      'IN_PROGRESS': 'On the way',
      'COMPLETED': 'Completed',
      'CANCELLED': 'Cancelled',
    };
    final statusLabel = statusLabels[status] ??
        status.replaceAll('_', ' ').toLowerCase();

    Color statusColor = Colors.grey;
    if (status == 'COMPLETED') {
      statusColor = Colors.green;
    } else if (status == 'CANCELLED') {
      statusColor = Colors.red;
    } else if (['ASSIGNED', 'DRIVER_ARRIVED', 'PICKED', 'IN_PROGRESS', 'SEARCHING']
        .contains(status)) {
      statusColor = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            // Expanded (replacing the Spacer, which did the same job here): as a
            // bare Row child this got unbounded width, so a long booking number
            // could never ellipsize next to the status badge.
            Expanded(
              child: Text("#$bookingNumber",
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
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
            // childAspectRatio derives the cell height from its width, so on a
            // 320dp screen the cell is only ~81dp tall while the icon + label
            // need ~86dp once a two-word label wraps at a large text scale.
            // 0.9 makes the cell taller than its fixed content.
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, childAspectRatio: 0.9, mainAxisSpacing: 10, crossAxisSpacing: 10,
            ),
            itemCount: _issueCategories.length,
            itemBuilder: (context, index) {
              final cat = _issueCategories[index];
              final isSelected = _selectedCategory == cat['id'];
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategory = cat['id'];
                    _selectedQuestion = null;
                    _confirmation = null;
                  });
                  _loadFaqs(cat['id'] as String);
                },
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
    final faqs = _faqCache[_selectedCategory] ?? const <Faq>[];
    final catLabel = _issueCategories.firstWhere((c) => c['id'] == _selectedCategory)['label'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Common questions — $catLabel", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          if (_loadingFaqs)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_faqError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(_faqError!,
                        style: const TextStyle(fontSize: 13, color: Colors.red)),
                  ),
                  TextButton(
                    onPressed: () => _loadFaqs(_selectedCategory!),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (faqs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                "No help articles here yet — raise a ticket below and we'll help.",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
          ...faqs.map((faq) {
            final isSelected = _selectedQuestion == faq.question;
            return InkWell(
              onTap: () => setState(() { _selectedQuestion = faq.question; _confirmation = null; }),
              child: Container(
                width: double.infinity, margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFF3EC) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected ? Border.all(color: AppColors.appColor) : null,
                ),
                child: Row(children: [
                  Expanded(child: Text(faq.question, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500))),
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
    final faqs = _faqCache[_selectedCategory] ?? const <Faq>[];
    final faq = faqs.firstWhere((f) => f.question == _selectedQuestion,
        orElse: () => Faq(id: '', question: '', answer: ''));
    if (faq.answer.isEmpty) return const SizedBox.shrink();

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
            Text(faq.answer, style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF444444))),
          ],
        ),
      ),
    );
  }

  // ─── TAP-BASED FEEDBACK ───
  Widget _buildTapFeedback() {
    final confirmation = _confirmation;
    if (confirmation != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: double.infinity, padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            // Flexible: as a bare Row child this got unbounded width, so beside
            // the icon it overflowed a narrow card instead of wrapping.
            Flexible(
              child: Text(confirmation, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
            ),
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
            // Flexible: the three chips are sized by their labels, and as a bare
            // Row child this widest one had unbounded width, so at a large text
            // scale the trio outgrew the card. Loose fit keeps its natural width
            // whenever it fits and only clamps it when it would not.
            Flexible(
              child: _feedbackButton('💬', 'Need More Help', AppColors.appColor),
            ),
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

      dynamic decoded;
      try {
        decoded = json.decode(res.body);
      } catch (_) {
        decoded = null;
      }

      // POST /support/tickets answers {success, message, data} and
      // {success:false, message} on failure (support.controller createTicket).
      final ok = (res.statusCode == 200 || res.statusCode == 201) &&
          decoded is Map &&
          decoded['success'] == true;
      final serverMessage = decoded is Map ? decoded['message'] : null;
      if (!mounted) return ok;

      // Only confirm a ticket that exists. This used to flip unconditionally,
      // so a rejected request still turned the panel green and thanked the
      // customer — and hid the button that would have let them try again.
      if (ok) {
        setState(() => _confirmation =
            'Ticket raised — replies appear under "My support tickets".');
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Ticket created. A support agent will contact you shortly.'
            : (serverMessage is String && serverMessage.trim().isNotEmpty
                ? serverMessage.trim()
                : 'Could not create ticket. Please try again.')),
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
        // Actually record the vote. This used to thank the customer for
        // feedback that was posted nowhere and counted by nothing.
        final faqs = _faqCache[_selectedCategory] ?? const <Faq>[];
        final faq = faqs.firstWhere((f) => f.question == _selectedQuestion,
            orElse: () => Faq(id: '', question: '', answer: ''));
        if (faq.id.isNotEmpty) {
          // Fire-and-forget: they already have their answer, so a failed vote
          // must not interrupt them.
          SupportService.rateFaq(faq.id, label != 'No').catchError((e) {
            debugPrint('faq feedback failed: $e');
          });
        }
        setState(() => _confirmation = 'Thank you for your feedback!');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
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
          // maxLines/ellipsis: without them the label lays out at its intrinsic
          // width and overflows the chip once the caller bounds it.
          Text(label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}