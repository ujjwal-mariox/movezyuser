import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';
import 'package:movezy_user_app/Services/referral_service.dart';

/// Refer & Earn.
///
/// Rebuilt so the code, the share options and the WhatsApp shortcut all sit in
/// ONE view. The previous layout stacked a full-bleed background image, a
/// 180px phone illustration and 30px gaps inside a fixed
/// `SizedBox(height: screenHeight)` — the actions were pushed off-screen and
/// the fixed height broke in landscape. The hero is now a compact card and
/// everything the customer has to act on is above the fold.
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

  /// The one message every channel sends, so the code and the link never drift
  /// apart between the share sheet and WhatsApp.
  String get _shareMessage {
    final buffer = StringBuffer()
      ..write('Hey! Use my Movezy referral code $_referralCode when you sign up '
          'and get ₹${_refereeReward.toInt()} in your Movezy wallet.');
    if (_referralLink.isNotEmpty) {
      buffer.write('\n\nDownload Movezy: $_referralLink');
    }
    return buffer.toString();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.appColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copy(String value, String label) {
    if (value.isEmpty) return;
    Clipboard.setData(ClipboardData(text: value));
    _toast('$label copied!');
  }

  void _shareEverywhere() {
    if (_referralCode.isEmpty) return;
    // ignore: deprecated_member_use
    Share.share(_shareMessage, subject: 'Movezy Referral');
  }

  /// WhatsApp gets its own button because it is how most referrals actually
  /// travel. Falls back to the normal share sheet when WhatsApp isn't
  /// installed, rather than failing silently.
  Future<void> _shareOnWhatsApp() async {
    if (_referralCode.isEmpty) return;
    final uri = Uri.parse(
        'https://wa.me/?text=${Uri.encodeComponent(_shareMessage)}');
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) _shareEverywhere();
    } catch (e) {
      debugPrint('WhatsApp share failed: $e');
      _shareEverywhere();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Column(
        children: [
          commonAppBar(
            height: 100,
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
                      child:
                          const Icon(Icons.arrow_back_ios, color: Colors.white),
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
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _errorView()
                    : _content(),
          ),
        ],
      ),
    );
  }

  Widget _errorView() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!,
                style: const TextStyle(fontSize: 15, color: Colors.grey)),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _loadReferralData,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.appColor),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

  Widget _content() {
    return RefreshIndicator(
      onRefresh: _loadReferralData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          _heroCard(),
          const SizedBox(height: 12),
          _statsRow(),
          const SizedBox(height: 12),
          _shareCard(),
          const SizedBox(height: 12),
          _howItWorks(),
        ],
      ),
    );
  }

  /// Compact hero. The illustration is capped at a fraction of the viewport so
  /// it shrinks on short screens instead of shoving the actions off the page.
  Widget _heroCard() {
    final art = (MediaQuery.of(context).size.height * 0.13).clamp(70.0, 110.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.appColor, AppColors.appColor.withOpacity(0.82)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Invite friends,\nearn rewards',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      height: 1.25,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Get ₹${_referrerReward.toInt()} for every friend who completes '
                  'their first trip.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.92),
                      fontSize: 12,
                      height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Image.asset("assets/mobile_icon.png",
              height: art, fit: BoxFit.contain),
        ],
      ),
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        Expanded(child: _statTile('${_referralCount.toString().padLeft(2, '0')}', 'Referrals')),
        const SizedBox(width: 12),
        Expanded(child: _statTile('₹${_totalEarnings.toInt()}', 'Earned')),
      ],
    );
  }

  Widget _statTile(String value, String label) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppColors.appColor)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
          ],
        ),
      );

  /// Code, link and every share channel in one card — the client's "one view".
  Widget _shareCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your referral code',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _copy(_referralCode, 'Code'),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.appColor.withOpacity(0.09),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.appColor.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _referralCode.isEmpty ? '—' : _referralCode,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.6),
                    ),
                  ),
                  Icon(Icons.copy_rounded, size: 17, color: AppColors.appColor),
                  const SizedBox(width: 5),
                  Text('Copy',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.appColor)),
                ],
              ),
            ),
          ),

          // The link only renders when the admin has configured one. A
          // placeholder URL here would be a dead link in every shared message.
          if (_referralLink.isNotEmpty) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _copy(_referralLink, 'Link'),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded, size: 17, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _referralLink,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('Copy',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  label: 'WhatsApp',
                  icon: Icons.chat_rounded,
                  color: const Color(0xFF25D366),
                  onTap: _shareOnWhatsApp,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton(
                  label: 'Share',
                  icon: Icons.share_rounded,
                  color: AppColors.appColor,
                  onTap: _shareEverywhere,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 17),
            const SizedBox(width: 7),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _howItWorks() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How it works',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _step('1', 'Share your code',
              'Send it to friends over WhatsApp or anywhere else.'),
          _step('2', 'They get ₹${_refereeReward.toInt()}',
              'Credited to their wallet when they apply your code.'),
          _step('3', 'You get ₹${_referrerReward.toInt()}',
              'Credited after they complete their first booking.',
              last: true),
        ],
      ),
    );
  }

  Widget _step(String number, String title, String subtitle,
      {bool last = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 21,
            width: 21,
            decoration: BoxDecoration(
                color: AppColors.appColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(number,
                style: const TextStyle(color: Colors.white, fontSize: 11.5)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 1),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11.5, color: Colors.grey, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
