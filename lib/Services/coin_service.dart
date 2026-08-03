import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';

/// One row of coin history.
class CoinTransaction {
  final String id;
  final String type; // EARNED | REDEEMED | EXPIRED | TRANSFERRED
  final int coins;
  final String description;
  final DateTime? createdAt;
  final DateTime? expiryDate;

  CoinTransaction({
    required this.id,
    required this.type,
    required this.coins,
    required this.description,
    this.createdAt,
    this.expiryDate,
  });

  /// EARNED adds coins; everything else takes them away.
  bool get isCredit => type.toUpperCase() == 'EARNED';

  factory CoinTransaction.fromJson(Map<String, dynamic> j) => CoinTransaction(
        id: (j['_id'] ?? '').toString(),
        type: (j['type'] ?? '').toString(),
        coins: (j['coins'] ?? j['amount'] ?? 0) is num
            ? (j['coins'] ?? j['amount'] ?? 0).toInt()
            : 0,
        description: (j['description'] ?? '').toString(),
        createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString()),
        expiryDate: DateTime.tryParse((j['expiryDate'] ?? '').toString()),
      );
}

/// Coin history and transfers.
///
/// All of this existed server-side while the app showed "coming soon" over it.
/// Minimums and rates are enforced by the backend — mirrored here only to give
/// immediate feedback, never as the source of truth.
/// Coin economics served by the backend, so displayed rates can't drift from
/// what the ledger actually applies.
class CoinConfig {
  final num earnRatePer100;
  final num rupeeRate;
  final num bankRate;
  final int expiryDays;

  const CoinConfig({
    required this.earnRatePer100,
    required this.rupeeRate,
    required this.bankRate,
    required this.expiryDays,
  });

  /// No baked-in defaults.
  ///
  /// These rates are admin-configurable, so a constant here is a guess quoted
  /// to the customer as fact — "1 Coin = ₹1" was being shown from this file
  /// even when the config call failed. Callers must handle null and show
  /// nothing rather than a number nobody set.
  factory CoinConfig.fromJson(Map<String, dynamic> j) => CoinConfig(
        earnRatePer100: (j['earnRatePer100'] as num?) ?? 0,
        rupeeRate: (j['rupeeRate'] as num?) ?? 0,
        bankRate: (j['bankRate'] as num?) ?? 0,
        expiryDays: ((j['expiryDays'] as num?) ?? 0).toInt(),
      );

  /// True when the server actually supplied the rates.
  bool get isComplete =>
      earnRatePer100 > 0 && rupeeRate > 0 && bankRate > 0 && expiryDays > 0;

  /// Trim a trailing ".0" so 1.0 reads as "1" but 0.9 stays "0.9".
  static String money(num v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

class CoinService {
  /// Backend rejects below these; keep in step with coin.controller.
  static const int minWalletTransfer = 100;
  static const int minBankTransfer = 500;

  /// Live coin economics. Returns null on failure so the caller can fall back.
  static Future<CoinConfig?> fetchConfig() async {
    try {
      final res = await http
          .get(Uri.parse(ApiUrls.coinsConfigUrl), headers: _headers())
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body);
      final data = body is Map ? body['data'] : null;
      if (data is! Map) return null;
      return CoinConfig.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      return null;
    }
  }

  static Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Prefs.getString('token')}',
      };

  static bool _ok(http.Response r, dynamic body) =>
      (r.statusCode == 200 || r.statusCode == 201) &&
      (body is Map && body['success'] == true);

  static Future<List<CoinTransaction>> getTransactions() async {
    final res = await http
        .get(Uri.parse('${ApiUrls.coinsTransactionsUrl}?page=1&limit=50'),
            headers: _headers())
        .timeout(const Duration(seconds: 20));
    final body = jsonDecode(res.body);
    if (!_ok(res, body)) {
      throw Exception(
          (body is Map ? body['message'] : null) ?? 'Failed to load coin history');
    }
    final list = (body['data']?['transactions'] as List?) ?? [];
    return list
        .map((e) => CoinTransaction.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Convert coins to Movezy Credits (wallet). Returns (ok, message, credited).
  static Future<(bool, String, double)> transferToWallet(int coins) async {
    try {
      final res = await http
          .post(Uri.parse(ApiUrls.coinsTransferToWalletUrl),
              headers: _headers(), body: jsonEncode({'coins': coins}))
          .timeout(const Duration(seconds: 25));
      final body = jsonDecode(res.body);
      final ok = _ok(res, body);
      final data = (body is Map) ? body['data'] : null;
      final credited = (data is Map) ? data['amountCredited'] : null;
      final message = (body is Map) ? (body['message'] ?? '') : '';
      return (
        ok,
        message.toString(),
        credited is num ? credited.toDouble() : 0.0,
      );
    } catch (e) {
      return (false, 'Transfer failed: $e', 0.0);
    }
  }

  /// Request a payout of coins to a bank account. Returns (ok, message).
  static Future<(bool, String)> bankTransfer({
    required int coins,
    required String accountName,
    required String accountNumber,
    required String ifsc,
  }) async {
    try {
      final res = await http
          .post(Uri.parse(ApiUrls.coinsBankTransferUrl),
              headers: _headers(),
              body: jsonEncode({
                'coins': coins,
                'bankDetails': {
                  'accountName': accountName,
                  'accountNumber': accountNumber,
                  'ifsc': ifsc,
                },
              }))
          .timeout(const Duration(seconds: 25));
      final body = jsonDecode(res.body);
      return (
        _ok(res, body),
        ((body is Map ? body['message'] : null) ?? '').toString()
      );
    } catch (e) {
      return (false, 'Request failed: $e');
    }
  }
}
