import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:http/http.dart' as http;
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
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
        }
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
    _faqs = [
      {'question': 'How do I create an account on the app?', 'answer': 'To create an account, open the app and tap on \'Sign Up\'. Fill in your details such as name, email, and password, then tap \'Create Account\'. You will receive a verification email.'},
      {'question': 'Can I book a ride without creating an account?', 'answer': 'No, you need to create an account before booking a ride. This ensures your trip details, payments, and support requests are linked securely to your profile.'},
      {'question': 'How do I reset my password if I forget it?', 'answer': 'On the login screen, tap on \'Forgot Password\'. Enter your registered email address and follow the link sent to your inbox to set a new password.'},
      {'question': 'How do I update my profile information?', 'answer': 'Go to your Profile section from the main menu, then tap \'Edit Profile\'. You can update your name, email, phone number, and profile picture from there.'},
    ];
    _clients = [
      {'name': 'Amazon', 'logoUrl': 'amazon_logo'},
      {'name': 'Samsung', 'logoUrl': 'samsung_logo'},
      {'name': 'ShopMart', 'logoUrl': 'shop_mart_logo'},
    ];
  }

  // ─── Submit enterprise inquiry ───
  Future<void> _submitInquiry() async {
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
          'message': 'User expressed interest via enterprise page',
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
      bottomNavigationBar: Container(
        height: 90,
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          children: [
            const Divider(height: 0.5, color: Colors.grey),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _isSubmitting ? null : _submitInquiry,
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
                          Center(
                            child: Text(
                              _ctaSubtext.contains('\n')
                                  ? _ctaSubtext.split('\n').last
                                  : "No Additional Charges!",
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
