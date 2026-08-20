import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';
import 'package:movezy_user_app/Services/referral_service.dart';

/// Refer & Earn — mirrored from the DRIVER app's page at the client's request
/// (hero artwork + headline + phone illustration + orange stats card, then the
/// white sheet with How-it-works, the code box, a prominent WhatsApp button
/// and an "Other Apps" fallback).
///
/// Two deliberate departures from a literal copy:
///  - The headline says what the CUSTOMER actually earns (₹referrerReward).
///    The driver page's headline sums both sides' rewards, which would
///    overstate this user's own earning.
///  - The referral link row renders only when the admin has configured a
///    download URL — a placeholder link would 404 for every friend.
class ReferAndEarnScreen extends StatefulWidget {
  const ReferAndEarnScreen({super.key});

  @override
  State<ReferAndEarnScreen> createState() => _ReferAndEarnScreenState();
}

class _ReferAndEarnScreenState extends State<ReferAndEarnScreen> {
  bool _isLoading = true;
  String _referralCode = '';
  String _referralLink = '';
  int _referralCount = 0;
  double _totalEarnings = 0;
  double _referrerReward = 100;
  double _refereeReward = 50;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  Future<void> _loadReferralData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await ReferralService.getReferralStats();
      if (mounted) {
        setState(() {
          _referralCode = data.referralCode;
          _referralLink = data.referralLink;
          _referralCount = data.referralCount;
          _totalEarnings = data.totalEarnings;
          _referrerReward = data.referrerRewardAmount;
          _refereeReward = data.refereeRewardAmount;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('ReferAndEarn - Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load referral data';
        });
      }
    }
  }

  /// One message for every channel, so the code and the link can never drift
  /// apart between WhatsApp and the generic share sheet.
  String get _shareMessage {
    final buffer = StringBuffer()
      ..write('Hey! Use my Movezy referral code $_referralCode when you sign '
          'up and get ₹${_refereeReward.toInt()} in your Movezy wallet.');
    if (_referralLink.isNotEmpty) {
      buffer.write('\n\nDownload Movezy: $_referralLink');
    }
    return buffer.toString();
  }

  void _copyCode() {
    if (_referralCode.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Referral code copied!'),
        backgroundColor: AppColors.appColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareCode() {
    if (_referralCode.isEmpty) return;
    // ignore: deprecated_member_use
    Share.share(_shareMessage, subject: 'Movezy Referral');
  }

  /// One-tap WhatsApp; falls back to the normal share sheet when WhatsApp
  /// isn't installed rather than failing silently.
  Future<void> _shareOnWhatsApp() async {
    if (_referralCode.isEmpty) return;
    final uri = Uri.parse(
        'whatsapp://send?text=${Uri.encodeComponent(_shareMessage)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
      final web = Uri.parse(
          'https://wa.me/?text=${Uri.encodeComponent(_shareMessage)}');
      if (await launchUrl(web, mode: LaunchMode.externalApplication)) return;
      _shareCode();
    } catch (e) {
      debugPrint('WhatsApp share failed: $e');
      _shareCode();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            commonAppBar(
              height: 110,
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
                    const Text(
                      "Refer & Earn",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 15),
                  ],
                ),
              ),
            ),
            _isLoading
                ? SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : _errorMessage != null
                    ? SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_errorMessage!,
                                  style: const TextStyle(
                                      fontSize: 15, color: Colors.grey)),
                              const SizedBox(height: 14),
                              ElevatedButton(
                                onPressed: _loadReferralData,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.appColor),
                                child: const Text('Retry',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _content(),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    // No fixed height: pinning the Stack to the screen height caps the column
    // below its own content on short devices — the driver page carries the
    // same note.
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            width: MediaQuery.of(context).size.width,
            child: Image.asset(
              "assets/refer_and_earn_r.png",
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              // Compact hero (client: banner reduced so the code box and the
              // WhatsApp button are reachable in one view). Was 30/18/180 —
              // that pushed the share actions below the fold on ~800pt phones.
              const SizedBox(height: 14),
              Center(
                child: Container(
                  margin: const EdgeInsets.only(left: 30, right: 30),
                  child: Text(
                    "Invite your friends &\nEarn upto ₹${_referrerReward.toInt()}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Image.asset(
                "assets/mobile_icon.png",
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 4),

              // Orange stats card — equal halves against the centre rule.
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.appColor,
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "${_referralCount.toString().padLeft(2, '0')}\nReferrals",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                            height: 1.35),
                      ),
                    ),
                    Container(height: 40, width: 1.5, color: Colors.white),
                    Expanded(
                      child: Text(
                        "₹${_totalEarnings.toStringAsFixed(0)}\nEarnings",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                            height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // White sheet
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topRight: Radius.circular(32),
                        topLeft: Radius.circular(32)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        margin: const EdgeInsets.only(left: 20, right: 20),
                        child: const Text(
                          "How it works?",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _howItWorksStep(
                        "1",
                        "Your friend gets ₹${_refereeReward.toInt()} in their wallet",
                        "When they sign up using your referral code",
                      ),
                      const SizedBox(height: 20),
                      _howItWorksStep(
                        "2",
                        "You earn ₹${_referrerReward.toInt()} in your wallet",
                        "Credited after their first completed booking",
                      ),
                      const SizedBox(height: 20),

                      // Referral code box
                      GestureDetector(
                        onTap: _copyCode,
                        child: Container(
                          height: 50,
                          margin: const EdgeInsets.only(left: 20, right: 20),
                          decoration: BoxDecoration(
                            color: HexColor("#FF6200").withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Referral Code: $_referralCode",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Image.asset("assets/copy.png",
                                  width: 27, height: 27),
                              const SizedBox(width: 8),
                              const Text(
                                "Copy",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 12),
                            ],
                          ),
                        ),
                      ),

                      // Download link — only when the admin configured one.
                      if (_referralLink.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: _referralLink));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Link copied!'),
                                backgroundColor: AppColors.appColor,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            height: 42,
                            margin:
                                const EdgeInsets.only(left: 20, right: 20),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F3F3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.link_rounded,
                                    size: 17, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _referralLink,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black87),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text('Copy',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 25),

                      // WhatsApp — full width with the same 20px margins as
                      // the code box (the driver page's fixed 280px width was
                      // the misalignment the client reported there).
                      GestureDetector(
                        onTap: _shareOnWhatsApp,
                        child: Container(
                          margin: const EdgeInsets.only(left: 20, right: 20),
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF25D366)
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat, color: Colors.white, size: 24),
                              SizedBox(width: 10),
                              Text(
                                "Share on WhatsApp",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Other share options
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: _shareCode,
                            child: Container(
                              width: 160,
                              height: 42,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: AppColors.appColor, width: 1.5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  "Other Apps",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.appColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _howItWorksStep(String number, String title, String subtitle) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Row(
        children: [
          const SizedBox(width: 20),
          Container(
            height: 22,
            width: 22,
            decoration: BoxDecoration(
              color: AppColors.appColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
                child: Text(number,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 12))),
          ),
          const SizedBox(width: 10),
          Container(
            alignment: Alignment.center,
            width: MediaQuery.of(context).size.width - 80,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
