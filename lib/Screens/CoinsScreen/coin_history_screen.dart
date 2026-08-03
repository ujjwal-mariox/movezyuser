import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart';
import 'package:movezy_user_app/Services/coin_service.dart';

/// Coin transaction history.
///
/// `GET /coins/transactions` was implemented all along; the app showed
/// "Coin history is coming soon" over it.
class CoinHistoryScreen extends StatefulWidget {
  const CoinHistoryScreen({super.key});

  @override
  State<CoinHistoryScreen> createState() => _CoinHistoryScreenState();
}

class _CoinHistoryScreenState extends State<CoinHistoryScreen> {
  List<CoinTransaction> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await CoinService.getTransactions();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load your coin history. Pull down to retry.';
      });
    }
  }

  String _label(CoinTransaction t) {
    if (t.description.isNotEmpty) return t.description;
    switch (t.type.toUpperCase()) {
      case 'EARNED':
        return 'Coins earned';
      case 'REDEEMED':
        return 'Coins redeemed';
      case 'EXPIRED':
        return 'Coins expired';
      case 'TRANSFERRED':
        return 'Coins transferred';
      default:
        return t.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HexColor("#F5F7F9"),
      appBar: AppBar(
        backgroundColor: HexColor("#FF6200"),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Coin History',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_items.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 140),
                      Center(
                        child: Text(
                          _error ?? 'No coin activity yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final t = _items[i];
                      final credit = t.isCredit;
                      final expired = t.type.toUpperCase() == 'EXPIRED';
                      return Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: HexColor("#E1E6EF")),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (credit
                                        ? HexColor("#1B7F45")
                                        : (expired
                                            ? HexColor("#8B95A1")
                                            : HexColor("#C25A0C")))
                                    .withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                credit
                                    ? Icons.add
                                    : (expired
                                        ? Icons.hourglass_disabled
                                        : Icons.arrow_outward),
                                size: 16,
                                color: credit
                                    ? HexColor("#1B7F45")
                                    : (expired
                                        ? HexColor("#8B95A1")
                                        : HexColor("#C25A0C")),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_label(t),
                                      style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600)),
                                  if (t.createdAt != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('dd MMM yyyy, hh:mm a')
                                          .format(t.createdAt!.toLocal()),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600),
                                    ),
                                  ],
                                  // Coins expire 30 days after they're credited
                                  // — surface it so nobody loses them unaware.
                                  if (credit && t.expiryDate != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Expires ${DateFormat('dd MMM yyyy').format(t.expiryDate!.toLocal())}',
                                      style: TextStyle(
                                          fontSize: 10.5,
                                          color: HexColor("#C25A0C")),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // `coins` is the ledger's `amount` field, which is
                            // already signed — debitCoins() stores -amount and
                            // expiry stores -toExpire — so prefixing a second
                            // '-' rendered every debit as "--100". Print the
                            // magnitude and let the type supply the sign.
                            Text(
                              '${credit ? '+' : '-'}${t.coins.abs()}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: credit
                                    ? HexColor("#1B7F45")
                                    : HexColor("#C25A0C"),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )),
      ),
    );
  }
}
