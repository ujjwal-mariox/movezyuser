import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:movezy_user_app/Services/wallet_service.dart';

class WalletBalanceWidget extends StatefulWidget {
  const WalletBalanceWidget({super.key});

  @override
  State<WalletBalanceWidget> createState() => _WalletBalanceWidgetState();
}

class _WalletBalanceWidgetState extends State<WalletBalanceWidget> {
  double _balance = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await WalletService.getWallet();
      if (mounted) setState(() { _balance = data.balance; _loaded = true; });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: HexColor("#A2BF49"),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.wallet, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            _loaded ? "₹${_balance.toInt()}" : "...",
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Legacy function for backward compat – still works but shows static value.
/// Prefer using WalletBalanceWidget() instead.
Widget walletWidget(BuildContext context) {
  return const WalletBalanceWidget();
}