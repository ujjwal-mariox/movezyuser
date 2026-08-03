import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart';
import 'package:movezy_user_app/Services/coin_service.dart';

/// Convert coins into Movezy Credits or request a bank payout.
///
/// Credits are instant. A bank payout is a *request*: the coins are debited and
/// held, an operator pays the account by hand, and rejecting the request refunds
/// the coins — hence the different wording on the two buttons.
/// Pops `true` when coins actually moved, so the caller can refresh the balance.
class CoinTransferSheet extends StatefulWidget {
  final bool toBank;
  final String title;

  /// Rate copy from the caller. No longer rendered: the sheet reads the rate
  /// from GET /coins/config so a caller-side constant can't drift from what the
  /// ledger applies. Kept only so existing call sites still compile.
  final String rateLabel;

  final int minCoins;
  final int availableCoins;

  const CoinTransferSheet({
    super.key,
    required this.toBank,
    required this.title,
    required this.rateLabel,
    required this.minCoins,
    required this.availableCoins,
  });

  @override
  State<CoinTransferSheet> createState() => _CoinTransferSheetState();
}

class _CoinTransferSheetState extends State<CoinTransferSheet> {
  final _coins = TextEditingController();
  final _accountName = TextEditingController();
  final _accountNumber = TextEditingController();
  final _ifsc = TextEditingController();
  bool _sending = false;
  String? _error;

  /// Live coin economics from GET /coins/config, which serves the
  /// COIN_TO_RUPEE_RATE / COIN_TO_BANK_RATE AppConfig rows the ledger itself
  /// reads. Null while the call is in flight and null again if it failed — the
  /// rate is never guessed locally, so a stale constant can never be quoted.
  CoinConfig? _cfg;
  bool _loadingCfg = true;

  @override
  void initState() {
    super.initState();
    CoinService.fetchConfig().then((c) {
      if (!mounted) return;
      setState(() {
        _cfg = c;
        _loadingCfg = false;
      });
    });
  }

  /// Rupees per coin for this destination, or null while it is unknown.
  /// Preview only — the server does the real math and returns the credited
  /// amount.
  double? get _rate {
    final cfg = _cfg;
    if (cfg == null) return null;
    return (widget.toBank ? cfg.bankRate : cfg.rupeeRate).toDouble();
  }

  int get _enteredCoins => int.tryParse(_coins.text.trim()) ?? 0;

  @override
  void dispose() {
    _coins.dispose();
    _accountName.dispose();
    _accountNumber.dispose();
    _ifsc.dispose();
    super.dispose();
  }

  /// Client-side check purely for fast feedback — the backend enforces these.
  String? _validate() {
    final c = _enteredCoins;
    if (c <= 0) return 'Enter how many coins to transfer.';
    if (c < widget.minCoins) {
      return 'Minimum ${widget.minCoins} coins for this transfer.';
    }
    if (c > widget.availableCoins) {
      return 'You only have ${widget.availableCoins} coins.';
    }
    if (widget.toBank) {
      if (_accountName.text.trim().isEmpty) return 'Enter the account holder name.';
      if (_accountNumber.text.trim().length < 6) return 'Enter a valid account number.';
      if (_ifsc.text.trim().length < 6) return 'Enter a valid IFSC code.';
    }
    return null;
  }

  Future<void> _submit() async {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _error = null;
      _sending = true;
    });

    final coins = _enteredCoins;
    String message;
    bool ok;

    if (widget.toBank) {
      final r = await CoinService.bankTransfer(
        coins: coins,
        accountName: _accountName.text.trim(),
        accountNumber: _accountNumber.text.trim(),
        ifsc: _ifsc.text.trim().toUpperCase(),
      );
      ok = r.$1;
      message = r.$2.isNotEmpty
          ? r.$2
          : (ok ? 'Bank transfer requested.' : 'Could not request transfer.');
    } else {
      final r = await CoinService.transferToWallet(coins);
      ok = r.$1;
      message = r.$2.isNotEmpty
          ? r.$2
          : (ok ? 'Coins transferred.' : 'Could not transfer coins.');
      if (ok && r.$3 > 0) {
        message = 'Transferred $coins coins — ₹${r.$3.toStringAsFixed(2)} added to your credits.';
      }
    }

    if (!mounted) return;
    setState(() => _sending = false);

    if (ok) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: HexColor("#1B7F45")),
      );
    } else {
      setState(() => _error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rate = _rate;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(widget.title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: rate != null
                        ? Text('1 coin = ₹${CoinConfig.money(rate)}',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: HexColor("#FF6200")))
                        : Text(
                            _loadingCfg
                                ? 'Checking the current rate…'
                                : "Couldn't load the current rate — Movezy "
                                    'confirms the amount on transfer.',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                  ),
                  const SizedBox(width: 10),
                  Text('Available: ${widget.availableCoins} coins',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _coins,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Coins to transfer',
                  hintText: 'Minimum ${widget.minCoins}',
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),

              // No rate, no preview: quoting a figure we can't back with live
              // config would be inventing the number.
              if (_enteredCoins > 0 && rate != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.toBank
                      ? "You'll receive ${NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(_enteredCoins * rate)} in your bank"
                      : "You'll get ${NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(_enteredCoins * rate)} in Movezy Credits",
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: HexColor("#1B7F45")),
                ),
              ],

              if (widget.toBank) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: _accountName,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Account holder name',
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _accountNumber,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Account number',
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _ifsc,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'IFSC code',
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bank transfers are reviewed before payout.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!,
                    style: TextStyle(fontSize: 12.5, color: HexColor("#C4213A"))),
              ],

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _sending ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HexColor("#FF6200"),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _sending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(widget.toBank ? 'Request transfer' : 'Transfer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
