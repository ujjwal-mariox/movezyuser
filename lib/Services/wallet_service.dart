import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movezy_user_app/ApiUrls/api_urls.dart';

class WalletData {
  final double balance;
  final List<WalletTransaction> transactions;

  WalletData({required this.balance, required this.transactions});

  factory WalletData.fromJson(Map<String, dynamic> json) {
    final txnList = (json['transactions'] as List? ?? [])
        .map((t) => WalletTransaction.fromJson(t))
        .toList();
    return WalletData(
      balance: (json['balance'] ?? 0).toDouble(),
      transactions: txnList,
    );
  }
}

class WalletTransaction {
  final String id;
  final double amount;
  final String type; // CREDIT or DEBIT
  final String? referenceId;
  final String? description;
  final double balanceBefore;
  final double balanceAfter;
  final String status;
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    this.referenceId,
    this.description,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.status,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['_id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] ?? 'CREDIT',
      referenceId: json['referenceId'],
      description: json['description'],
      balanceBefore: (json['balanceBefore'] ?? 0).toDouble(),
      balanceAfter: (json['balanceAfter'] ?? 0).toDouble(),
      status: json['status'] ?? 'COMPLETED',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class RechargeOrder {
  final String orderId;
  final double amount;
  final String currency;

  RechargeOrder({
    required this.orderId,
    required this.amount,
    required this.currency,
  });

  factory RechargeOrder.fromJson(Map<String, dynamic> json) {
    return RechargeOrder(
      orderId: json['orderId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'INR',
    );
  }
}

class WalletService {
  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Get wallet balance + recent transactions
  static Future<WalletData> getWallet() async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse(ApiUrls.walletUrl),
      headers: headers,
    );

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw Exception('Server error (${response.statusCode}). Please try again later.');
    }

    late final Map<String, dynamic> body;
    try {
      body = json.decode(response.body);
    } catch (_) {
      throw Exception('Invalid response from server');
    }

    if (response.statusCode == 200) {
      // Backend uses response middleware: { rCode, rMsg, rData }
      final data = body['rData'] ?? body['data'] ?? body;
      return WalletData.fromJson(data);
    }
    throw Exception(body['rMsg'] ?? body['message'] ?? 'Failed to load wallet');
  }

  /// Get paginated transaction history
  static Future<WalletData> getTransactions({int page = 1, int limit = 20}) async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse('${ApiUrls.walletTransactionsUrl}?page=$page&limit=$limit'),
      headers: headers,
    );

    final body = json.decode(response.body);
    if (response.statusCode == 200) {
      final data = body['rData'] ?? body['data'] ?? body;
      return WalletData.fromJson(data);
    }
    throw Exception(body['rMsg'] ?? body['message'] ?? 'Failed to load transactions');
  }

  /// Create a Razorpay order for wallet recharge
  static Future<RechargeOrder> createRechargeOrder(double amount) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse(ApiUrls.walletRechargeOrderUrl),
      headers: headers,
      body: json.encode({'amount': amount}),
    );

    // Guard against non-JSON (HTML) responses from proxy/server errors
    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw Exception('Server error (${response.statusCode}). Please try again later.');
    }

    late final Map<String, dynamic> body;
    try {
      body = json.decode(response.body);
    } catch (_) {
      throw Exception('Invalid response from server (${response.statusCode})');
    }

    if (response.statusCode == 200 && body['success'] == true) {
      return RechargeOrder.fromJson(body['data']);
    }
    throw Exception(body['message'] ?? 'Failed to create recharge order');
  }

  /// Verify a Razorpay payment for wallet recharge
  static Future<bool> verifyRecharge({
    required String orderId,
    required String paymentId,
    required String signature,
    required double amount,
  }) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse(ApiUrls.walletRechargeVerifyUrl),
      headers: headers,
      body: json.encode({
        'orderId': orderId,
        'paymentId': paymentId,
        'signature': signature,
        'amount': amount,
      }),
    );

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) return false;

    try {
      final body = json.decode(response.body);
      return response.statusCode == 200 && body['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
