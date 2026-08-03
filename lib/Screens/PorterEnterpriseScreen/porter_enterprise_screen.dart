import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:http/http.dart' as http;
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';

/// Renamed from PorterEnterpriseScreen → MovezyEnterpriseScreen.
/// Keeping the old class name as a typedef for backward compatibility.
class PorterEnterpriseScreen extends StatefulWidget {
  const PorterEnterpriseScreen({super.key});
  @override
  State<PorterEnterpriseScreen> createState() => _PorterEnterpriseScreenState();
}

class _PorterEnterpriseScreenState extends State<PorterEnterpriseScreen>
    with SingleTickerProviderStateMixin {
  // ── Dynamic data ──
  bool _isLoading = true;
  String _heroTitle = "Upgrade to Movezy Enterprise\nfor Business Logistics";
  String _heroSubtitle = "All these features at No Additional Charges!";
  String _ctaText = "Get in touch!";
  String _ctaSubtext = "All these features at No Additional Charges!";
  List<Map<String, dynamic>> _features = [];
  List<Map<String, dynamic>> _faqs = [];
  List<Map<String, dynamic>> _clients = [];

  // ── Auto-scroll for clients ──
  late ScrollController _clientScrollController;
  late AnimationController _scrollAnimController;

  // ── Inquiry state ──
  bool _isSubmitting = false;

  // ── Icon asset mapping ──
  static const Map<String, String> _iconMap = {
    'gst_invoice': 'assets/gst_invoice.png',
    'one_account': 'assets/one_account.png',
    'flexible_payments': 'assets/flexible_payments.png',
  };

  // ── Logo asset mapping ──
  static const Map<String, String> _logoMap = {
    'amazon_logo': 'assets/amazon_logo.png',
    'samsung_logo': 'assets/Samsung_logo.png',
    'shop_mart_logo': 'assets/shop_mart_logo.png',
  };

  @override
  void initState() {
    super.initState();
    _clientScrollController = ScrollController();
    _scrollAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..addListener(() {
        if (_clientScrollController.hasClients) {
          final maxScroll =
              _clientScrollController.position.maxScrollExtent;
          _clientScrollController
              .jumpTo(_scrollAnimController.value * maxScroll);
        }
      });
    _scrollAnimController.repeat();
    _fetchContent();
  }

  @override
  void dispose() {
    _scrollAnimController.dispose();
    _clientScrollController.dispose();
    super.dispose();
  }

  // ─── Fetch enterprise page content from backend ───
  Future<void> _fetchContent() async {
    try {
      final url = Uri.parse('${ApiUrls.baseUrlApi}/enterprise/content');
      final res = await http.get(url, headers: {
        'Content-Type': 'application/json',
      });
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'];
          setState(() {
            _heroTitle = data['heroTitle'] ?? _heroTitle;
            _heroSubtitle = data['heroSubtitle'] ?? _heroSubtitle;
            _ctaText = data['ctaText'] ?? _ctaText;
            _ctaSubtext = data['ctaSubtext'] ?? _ctaSubtext;

            if (data['features'] is List) {
              _features = (data['features'] as List)
                  .where((f) => f['isActive'] == true)
                  .map<Map<String, dynamic>>((f) => Map<String, dynamic>.from(f))
                  .toList()
                ..sort((a, b) =>
                    (a['sortOrder'] ?? 0).compareTo(b['sortOrder'] ?? 0));
            }

            if (data['faqs'] is List) {
              _faqs = (data['faqs'] as List)
                  .where((f) => f['isActive'] == true)
                  .map<Map<String, dynamic>>((f) => Map<String, dynamic>.from(f))
                  .toList()
                ..sort((a, b) =>
                    (a['sortOrder'] ?? 0).compareTo(b['sortOrder'] ?? 0));
            }

            if (data['clients'] is List) {
              _clients = (data['clients'] as List)
                  .where((c) => c['isActive'] == true)
                  .map<Map<String, dynamic>>((c) => Map<String, dynamic>.from(c))
                  .toList()
                ..sort((a, b) =>
                    (a['sortOrder'] ?? 0).compareTo(b['sortOrder'] ?? 0));
            }
          });
        } else {
          // 200 but no usable payload.
          _setDefaultContent();
        }
      } else {
        // package:http does NOT throw on 4xx/5xx, so this never reached the
        // catch below — a non-200 left the page with no Key Features and no
        // FAQ at all, rendering blank rather than falling back.
        debugPrint('Enterprise content HTTP ${res.statusCode}');
        _setDefaultContent();
      }
    } catch (e) {
      debugPrint('Failed to load enterprise content: $e');
      // Fallback to hardcoded defaults
      _setDefaultContent();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setDefaultContent() {
    _features = [
      {'icon': 'gst_invoice', 'title': 'Monthly GST Invoices', 'description': 'Get a single monthly invoice and detailed report for all trips'},
      {'icon': 'one_account', 'title': 'One Account, Multi Users', 'description': 'Manage all users under a single account – no petty-cash claims'},
      {'icon': 'flexible_payments', 'title': 'Flexible Payments', 'description': 'Instant recharge with credit card, netbanking, UPI, and more'},
    ];
    // FAQs describe how this app ACTUALLY works. The previous defaults talked
    // about email/password sign-up, verification emails and "Forgot Password" —
    // none of which exist here (login is mobile + OTP only).
    _faqs = [
      {'question': 'How do I create an account?', 'answer': 'Enter your mobile number on the login screen and verify the OTP we text you. Your account is created automatically — there is no password to remember.'},
      {'question': 'Can I book without creating an account?', 'answer': 'No. Verifying your number lets us link your trips, payments and support requests to you, and lets the driver reach you at pickup.'},
      {'question': 'How do I get a GST invoice for my trips?', 'answer': 'Add your GSTIN under Profile → GST Details. Once it is saved, your business name and GSTIN appear on the invoice for every completed booking.'},
      {'question': 'How do I update my profile information?', 'answer': 'Open Profile and tap Edit Profile to update your name, email and photo. Your mobile number is your login and stays fixed.'},
    ];
    // NO default client list. This used to claim Amazon, Samsung and ShopMart as
    // customers whenever the API returned nothing — a false claim about real
    // companies, shown to every user. The clients strip hides itself when empty.
    _clients = [];
  }

  /// The "Get in touch" form from the design: Company Name, Name, Mobile,
  /// Email, then Confirm.
  ///
  /// Tapping the CTA used to fire an inquiry immediately with a canned message
  /// and no company details, so every lead reached sales as
  /// `companyName: ""` — unusable. Name/mobile/email are prefilled from the
  /// profile but stay editable, because the account holder often isn't the
  /// person who handles the enterprise relationship.
  void _showGetInTouchSheet() {
    final companyCtrl = TextEditingController();
    final nameCtrl = TextEditingController(text: Prefs.getString('fullName'));
    final phoneCtrl =
        TextEditingController(text: Prefs.getString('mobile_number'));
    final emailCtrl = TextEditingController(text: Prefs.getString('email'));
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        // Lift above the keyboard, or the fields sit under it.
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SafeArea(
          child: StatefulBuilder(
            builder: (ctx, setSheet) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Get in touch',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold)),
                        InkWell(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _sheetField(companyCtrl, 'Company Name',
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Company name is required'
                            : null),
                    _sheetField(nameCtrl, 'Name',
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Name is required'
                            : null),
                    _sheetField(phoneCtrl, 'Mobile number',
                        keyboard: TextInputType.phone,
                        validator: (v) =>
                            (v == null || v.trim().length < 10)
                                ? 'Enter a valid mobile number'
                                : null),
                    _sheetField(emailCtrl, 'Email Address',
                        keyboard: TextInputType.emailAddress,
                        validator: (v) {
                          final s = (v ?? '').trim();
                          if (s.isEmpty) return 'Email is required';
                          if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(s)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        }),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.appColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                if (!formKey.currentState!.validate()) return;
                                Navigator.pop(ctx);
                                _submitInquiry(
                                  companyName: companyCtrl.text,
                                  name: nameCtrl.text,
                                  phone: phoneCtrl.text,
                                  email: emailCtrl.text,
                                );
                              },
                        child: const Text('Confirm',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetField(TextEditingController c, String label,
      {TextInputType? keyboard, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  // ─── Submit enterprise inquiry ───
  Future<void> _submitInquiry({
    required String companyName,
    required String name,
    required String phone,
    required String email,
  }) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final token = Prefs.getString('token');
      final url = Uri.parse('${ApiUrls.baseUrlApi}/enterprise/inquiry');
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'source': 'GET_IN_TOUCH',
          'companyName': companyName,
          'name': name,
          'phone': phone,
          'email': email,
        }),
      );

      final body = jsonDecode(res.body);
      if (mounted) {
        if (res.statusCode == 201 && body['success'] == true) {
          _showAcknowledgmentPopup();
        } else {
          _showErrorSnackbar(body['message'] ?? 'Failed to submit inquiry');
        }
      }
    } catch (e) {
      debugPrint('Inquiry error: $e');
      if (mounted) {
        _showErrorSnackbar('Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showAcknowledgmentPopup() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: HexColor("#FF6200").withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded,
                    size: 56, color: HexColor("#FF6200")),
              ),
              const SizedBox(height: 20),
              const Text(
                "Thank You!",
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Your interest has been recorded.\nOur team will contact you shortly\nto discuss your business needs.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HexColor("#FF6200"),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Got it!",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // ─── Resolve an icon key to an asset path ───
  String _resolveIcon(String? key) {
    if (key == null || key.isEmpty) return 'assets/gst_invoice.png';
    if (_iconMap.containsKey(key)) return _iconMap[key]!;
    if (key.startsWith('http')) return key; // network URL (not used for now)
    return 'assets/$key.png';
  }

  // ─── Resolve a logo key to an asset path ───
  String _resolveLogo(String? key) {
    if (key == null || key.isEmpty) return 'assets/amazon_logo.png';
    if (_logoMap.containsKey(key)) return _logoMap[key]!;
    if (key.startsWith('http')) return key;
    return 'assets/$key.png';
  }

  @override
  Widget build(BuildContext context) {
    final questionStyle = const TextStyle(
      fontSize: 13,
      color: Colors.white,
      fontWeight: FontWeight.w500,
    );
    final answerStyle = const TextStyle(
      fontSize: 11,
      color: Colors.white,
      height: 1.5,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      // The bar is a fixed 90px tall with nothing reserved for the system bar,
      // so on gesture-navigation devices the gesture bar covered the bottom of
      // the "Get in touch" button and ate the tap. SafeArea adds the device's
      // real bottom inset below the bar.
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 90,
          decoration: const BoxDecoration(color: Colors.white),
          child: Column(
            children: [
              const Divider(height: 0.5, color: Colors.grey),
              const SizedBox(height: 20),
              GestureDetector(
                // Opens the designed form instead of firing a blank lead.
                onTap: _isSubmitting ? null : _showGetInTouchSheet,
                child: Container(
                  margin: const EdgeInsets.only(left: 20, right: 20),
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: _isSubmitting
                        ? HexColor("#FF6200").withOpacity(0.6)
                        : HexColor("#FF6200"),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            _ctaText,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? Container(
              color: HexColor("#0B1326"),
              child: const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
            )
          : SingleChildScrollView(
              child: Container(
                color: HexColor("#0B1326"),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── App Bar ──
                    commonAppBar(
                      height: 105,
                      context: context,
                      child: Container(
                        padding: const EdgeInsets.only(top: 50),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.only(left: 16),
                                width: 40,
                                height: 35,
                                alignment: Alignment.center,
                                child: const Icon(Icons.arrow_back_ios,
                                    color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              "Movezy Enterprise",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),

                    // ── Hero Banner ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 25, horizontal: 20),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset("assets/porter_enterprise_logo.png",
                              height: 170, fit: BoxFit.cover),
                          const SizedBox(height: 25),
                          Text(
                            _heroTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),

                    // ── White content card ──
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 15),

                          // ── OUR CLIENTS ──
                          if (_clients.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Text("OUR CLIENTS",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 90,
                              child: ListView.builder(
                                controller: _clientScrollController,
                                scrollDirection: Axis.horizontal,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: _clients.length * 3,
                                itemBuilder: (context, index) {
                                  final client =
                                      _clients[index % _clients.length];
                                  return Container(
                                    margin: const EdgeInsets.only(right: 14),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                    ),
                                    child: SizedBox(
                                      height: 72,
                                      width: 72,
                                      child: Image.asset(
                                        _resolveLogo(client['logoUrl']),
                                        errorBuilder: (_, _, _) =>
                                            const Icon(Icons.business,
                                                size: 40,
                                                color: Colors.grey),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],

                          // ── KEY FEATURES ──
                          if (_features.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Text("KEY FEATURES",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 5),
                            ..._features.map((f) => _featureCard(
                                  icon: _resolveIcon(f['icon']),
                                  title: f['title'] ?? '',
                                  subtitle: f['description'] ?? '',
                                )),
                          ],

                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              _ctaSubtext.split('\n').first,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          // Only render a second line when the copy actually
                          // has one. The default subtext is a single line
                          // ending "...at No Additional Charges!", so the old
                          // hardcoded fallback printed that phrase again
                          // directly underneath itself.
                          if (_ctaSubtext.contains('\n'))
                          Center(
                            child: Text(
                              _ctaSubtext.split('\n').last,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),

                    const SizedBox(height: 1),

                    // ── FAQ ──
                    if (_faqs.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text("FAQ",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 20),
                            ..._faqs.map((faq) => _buildFaqItem(
                                  question: faq['question'] ?? '',
                                  answer: faq['answer'] ?? '',
                                  qStyle: questionStyle,
                                  aStyle: answerStyle,
                                )),
                          ],
                        ),
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}

// ── Feature card widget ──
Widget _featureCard(
    {required String icon, required String title, required String subtitle}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    padding: const EdgeInsets.all(1),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.grey.shade300),
      gradient: LinearGradient(
          colors: [HexColor("#FF6200"), HexColor("#0A3AD8")]),
    ),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13.5), color: Colors.white),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 70,
            width: 60,
            child: Image.asset(
              icon,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.star, size: 40, color: Colors.orange),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w400)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// ── FAQ item widget ──
Widget _buildFaqItem({
  required String question,
  required String answer,
  required TextStyle qStyle,
  required TextStyle aStyle,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 6),
    decoration: BoxDecoration(
      color: HexColor("#FF6200"),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        title: Text(question, style: qStyle),
        childrenPadding:
            const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        children: [Text(answer, style: aStyle)],
      ),
    ),
  );
}
