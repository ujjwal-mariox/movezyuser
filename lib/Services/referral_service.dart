import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movezy_user_app/ApiUrls/api_urls.dart';

class ReferralData {
  final String referralCode;

  /// The shareable download link with the code appended, built server-side from
  /// the admin-configured store URL. Empty when the admin hasn't set one — the
  /// share sheet then goes out with the code alone rather than a dead link.
  final String referralLink;
  final int referralCount;
  final double totalEarnings;
  final double referrerRewardAmount;
  final double refereeRewardAmount;
  final List<ReferralUser> recentReferrals;

  ReferralData({
    required this.referralCode,
    this.referralLink = '',
    required this.referralCount,
    required this.totalEarnings,
    required this.referrerRewardAmount,
    required this.refereeRewardAmount,
    required this.recentReferrals,
  });

  factory ReferralData.fromJson(Map<String, dynamic> json) {
    final referralsList = (json['recentReferrals'] as List? ?? [])
        .map((r) => ReferralUser.fromJson(r))
        .toList();
    return ReferralData(
      referralCode: json['referralCode'] ?? '',
      referralLink: json['referralLink'] ?? '',
      referralCount: json['referralCount'] ?? 0,
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      referrerRewardAmount: (json['referrerRewardAmount'] ?? 100).toDouble(),
      refereeRewardAmount: (json['refereeRewardAmount'] ?? 50).toDouble(),
      recentReferrals: referralsList,
    );
  }
}

class ReferralUser {
  final String name;
  final String mobile;
  final DateTime joinedAt;

  ReferralUser({
    required this.name,
    required this.mobile,
    required this.joinedAt,
  });

  factory ReferralUser.fromJson(Map<String, dynamic> json) {
    return ReferralUser(
      name: json['name'] ?? 'New User',
      mobile: json['mobile'] ?? '',
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'])
          : DateTime.now(),
    );
  }
}

class ReferralApplyResult {
  final bool success;
  final String message;
  final String? referrerName;
  final double? rewardAmount;

  ReferralApplyResult({
    required this.success,
    required this.message,
    this.referrerName,
    this.rewardAmount,
  });
}

class ReferralService {
  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Get the user's referral code (auto-generates if doesn't exist)
  static Future<String> getReferralCode() async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse(ApiUrls.referralCodeUrl),
      headers: headers,
    );

    final body = json.decode(response.body);
    if (response.statusCode == 200) {
      final data = body['rData'] ?? body['data'] ?? body;
      return data['referralCode'] ?? '';
    }
    throw Exception(body['rMsg'] ?? body['message'] ?? 'Failed to get referral code');
  }

  /// Get full referral stats (code, count, earnings, recent referrals)
  static Future<ReferralData> getReferralStats() async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse(ApiUrls.referralStatsUrl),
      headers: headers,
    );

    final body = json.decode(response.body);
    if (response.statusCode == 200) {
      final data = body['rData'] ?? body['data'] ?? body;
      return ReferralData.fromJson(data);
    }
    throw Exception(body['rMsg'] ?? body['message'] ?? 'Failed to load referral stats');
  }

  /// Apply a referral code
  static Future<ReferralApplyResult> applyReferralCode(String code) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse(ApiUrls.referralApplyUrl),
      headers: headers,
      body: json.encode({'referralCode': code.toUpperCase()}),
    );

    final body = json.decode(response.body);
    final msg = body['rMsg'] ?? body['message'] ?? '';

    if (response.statusCode == 200 && (body['rCode'] ?? 1) == 1) {
      final data = body['rData'] ?? body['data'] ?? {};
      return ReferralApplyResult(
        success: true,
        message: 'Referral code applied! You earned ₹${data['rewardAmount'] ?? 50}',
        referrerName: data['referrerName'],
        rewardAmount: (data['rewardAmount'] ?? 50).toDouble(),
      );
    }

    // Map known error messages to user-friendly text
    String userMsg;
    switch (msg) {
      case 'referral_already_applied':
        userMsg = 'You have already applied a referral code';
        break;
      case 'cannot_use_own_referral':
        userMsg = 'You cannot use your own referral code';
        break;
      case 'invalid_referral_code':
        userMsg = 'Invalid referral code. Please check and try again';
        break;
      case 'referral_code_required':
        userMsg = 'Please enter a referral code';
        break;
      default:
        userMsg = msg.isNotEmpty ? msg : 'Failed to apply referral code';
    }

    return ReferralApplyResult(
      success: false,
      message: userMsg,
    );
  }
}
