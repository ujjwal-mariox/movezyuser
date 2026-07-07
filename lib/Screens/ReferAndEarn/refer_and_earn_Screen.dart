import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:share_plus/share_plus.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/CommonWidgets/button_widget.dart';
import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';
import 'package:movezy_user_app/Services/referral_service.dart';

class ReferAndEarnScreen extends StatefulWidget {
  const ReferAndEarnScreen({super.key});

  @override
  State<ReferAndEarnScreen> createState() => _ReferAndEarnScreenState();
}

class _ReferAndEarnScreenState extends State<ReferAndEarnScreen> {
  bool _isLoading = true;
  String _referralCode = '';
  int _referralCount = 0;
  double _totalEarnings = 0;
  double _referrerReward = 100;
  double _refereeReward = 50;
  List<ReferralUser> _recentReferrals = [];
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
          _referralCount = data.referralCount;
          _totalEarnings = data.totalEarnings;
          _referrerReward = data.referrerRewardAmount;
          _refereeReward = data.refereeRewardAmount;
          _recentReferrals = data.recentReferrals;
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

  void _copyReferralCode() {
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

  void _shareReferralCode() {
    if (_referralCode.isEmpty) return;
    // ignore: deprecated_member_use
    Share.share(
      'Hey! Use my Movezy referral code *$_referralCode* and get ₹${_refereeReward.toInt()} in your wallet on signup! Download Movezy now.',
      subject: 'Movezy Referral',
    );
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
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.only(left: 16),
                        width: 40,
                        height: 35,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
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
                              Text(
                                _errorMessage!,
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadReferralData,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.appColor,
                                ),
                                child: const Text('Retry',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
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
              const SizedBox(height: 30),
              Center(
                child: Container(
                  margin: const EdgeInsets.only(left: 30, right: 30),
                  child: Text(
                    "Invite your friends &\nEarn upto ₹${_referrerReward.toInt()}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Image.asset(
                "assets/mobile_icon.png",
                height: 180,
                fit: BoxFit.cover,
              ),

              // ─── Stats Card ───
              Container(
                width: 300,
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.appColor,
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Spacer(),
                    Column(
                      children: [
                        Text(
                          "${_referralCount.toString().padLeft(2, '0')}\nReferrals",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(height: 40, width: 2, color: Colors.white),
                    const Spacer(),
                    Column(
                      children: [
                        Text(
                          "₹${_totalEarnings.toInt()}\nEarnings",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ─── Bottom Section ───
              Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(32),
                      topLeft: Radius.circular(32),
                    ),
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
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Step 1
                      _buildStep(
                        "1",
                        "Share your referral code with friends",
                        "They sign up and apply your code to their account",
                      ),
                      const SizedBox(height: 20),

                      // Step 2
                      _buildStep(
                        "2",
                        "Your friend gets ₹${_refereeReward.toInt()} in their wallet",
                        "Instantly credited when they apply your code",
                      ),
                      const SizedBox(height: 20),

                      // Step 3
                      _buildStep(
                        "3",
                        "You earn ₹${_referrerReward.toInt()} when they complete a trip",
                        "Credited to your wallet after their first booking",
                      ),

                      const SizedBox(height: 20),

                      // ─── Referral Code Box ───
                      GestureDetector(
                        onTap: _copyReferralCode,
                        child: Container(
                          height: 50,
                          margin: const EdgeInsets.only(left: 20, right: 20),
                          decoration: BoxDecoration(
                            color: HexColor("#FF6200").withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 10),
                              Text(
                                "Referral Code: $_referralCode",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Image.asset("assets/copy.png",
                                  width: 27, height: 27),
                              const SizedBox(width: 8),
                              const Text(
                                "Copy",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // ─── Share Button ───
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 160,
                            height: 45,
                            child: ButtonWidget(
                              text: "Share Code",
                              borderRadius: BorderRadius.circular(10),
                              backgroundColor: AppColors.appColor,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              onTap: _shareReferralCode,
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

  Widget _buildStep(String number, String title, String subtitle) {
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
              child: Text(
                number,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
