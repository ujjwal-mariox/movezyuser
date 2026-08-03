import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/Services/wallet_service.dart';
import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';


class WalletRechargeApp extends StatefulWidget {
  const WalletRechargeApp({super.key});

  @override
  State<WalletRechargeApp> createState() => _WalletRechargeAppState();
}

class _WalletRechargeAppState extends State<WalletRechargeApp> {
  int selectedAmount = 500;

  /// Null until a fetch actually succeeds. A failed fetch used to leave this at
  /// 0 and render "₹ 0", which is indistinguishable from an empty wallet.
  double? _balance;

  /// A wallet request is in flight — guards against stacking refreshes.
  bool _fetching = false;

  /// The last wallet request failed.
  bool _loadFailed = false;

  bool _paying = false;
  List<WalletTransaction> _transactions = [];

  /// Whether this screen is the shown child of the dashboard's IndexedStack.
  /// See [didChangeDependencies].
  bool _visible = false;

  late Razorpay _razorpay;
  double _pendingAmount = 0;

  final List<Map<String, dynamic>> rechargeOptions = [
    {"amount": 100},
    {"amount": 200},
    {"amount": 500, "popular": true},
    {"amount": 1000},
    {"amount": 2000},
    {"amount": 5000},
  ];

  bool _razorpayReady = false;

  @override
  void initState() {
    super.initState();
    _initRazorpay();
    // The balance load is driven by didChangeDependencies, not initState — see
    // the note there.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This screen is one of the dashboard's IndexedStack children, so it is
    // built once and then stays mounted: initState ran a single time per app
    // launch and the balance went stale the moment money moved on any other
    // surface. IndexedStack wraps each child in a Visibility, and
    // Visibility.of() both reports whether this subtree is the shown one and
    // registers a dependency on it — so this runs again every time the Wallet
    // tab is opened. Where there is no Visibility ancestor (the screen is also
    // pushed as a route from Home/FAQ/Notification settings) it reports true,
    // which gives a pushed instance its initial load.
    final visible = Visibility.of(context);
    if (visible && !_visible) {
      // Run it after this frame so the in-flight setState never lands in the
      // middle of a build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadWallet();
      });
    }
    _visible = visible;
  }

  void _initRazorpay() {
    try {
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
      _razorpayReady = true;
    } catch (e) {
      debugPrint('Razorpay init failed: $e');
      _razorpayReady = false;
    }
  }

  @override
  void dispose() {
    if (_razorpayReady) _razorpay.clear();
    super.dispose();
  }

  Future<void> _loadWallet() async {
    if (_fetching) return;
    setState(() {
      _fetching = true;
      _loadFailed = false;
    });
    try {
      final data = await WalletService.getWallet();
      if (!mounted) return;
      setState(() {
        _balance = data.balance;
        _transactions = data.transactions;
      });
    } catch (_) {
      if (!mounted) return;
      // _balance is deliberately left alone: a previously loaded figure is
      // still the last thing the server told us, and null keeps the
      // "couldn't load" state up instead of inventing a zero.
      setState(() => _loadFailed = true);
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  Future<void> _startPayment() async {
    if (!_razorpayReady) {
      _showSnack('Payment gateway not ready. Please restart the app.');
      return;
    }
    setState(() => _paying = true);
    try {
      final order = await WalletService.createRechargeOrder(selectedAmount.toDouble());
      _pendingAmount = selectedAmount.toDouble();

      var options = {
        'key': ApiUrls.razorpayKeyId,
        'amount': (selectedAmount * 100), // paise
        'order_id': order.orderId,
        'name': 'Movezy',
        'description': 'Wallet Recharge ₹$selectedAmount',
        'prefill': {'contact': '', 'email': ''},
        'theme': {'color': '#4CAD73'},
      };

      _razorpay.open(options);
    } catch (e) {
      setState(() => _paying = false);
      _showSnack('Failed to create order: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _paying = true);
    try {
      final verified = await WalletService.verifyRecharge(
        orderId: response.orderId ?? '',
        paymentId: response.paymentId ?? '',
        signature: response.signature ?? '',
        amount: _pendingAmount,
      );

      if (verified) {
        _showSnack('₹${_pendingAmount.toInt()} added to wallet!');
        _loadWallet();
      } else {
        _showSnack('Payment verification failed');
      }
    } catch (e) {
      _showSnack('Verification error: $e');
    }
    if (mounted) setState(() => _paying = false);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _paying = false);
    _showSnack('Payment failed: ${response.message ?? "Unknown error"}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showSnack('External Wallet: ${response.walletName}');
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    // GST is handled server-side; display the recharge amount directly
    int totalAmount = selectedAmount;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark,
     )
    );

    return Scaffold(
      backgroundColor: AppColors.appColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 55,),
                Row(
                  children: [
                    SizedBox(width: 16,),

                    Text(
                      "Recharge Wallet",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),


                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Text("Available Balance",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400)
                      ),
                      SizedBox(height: 5),
                      _balanceLine(),
                    ],
                  ),
                ),

                // Recharge Amount Section
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topRight: Radius.circular(26), topLeft: Radius.circular(26))
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Recharge Amount",
                          style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      GridView.builder(
                        padding: EdgeInsets.only(top: 5),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: rechargeOptions.length,
                        itemBuilder: (context, index) {
                          final option = rechargeOptions[index];
                          bool isSelected = option['amount'] == selectedAmount;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedAmount = option['amount'];
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: isSelected ? Colors.amber : HexColor("#D9D9D9"),
                                    width: 2),
                                gradient: isSelected ? LinearGradient(colors: [
                                  HexColor("#FFFCDA"),
                                  HexColor("#FFFFFF"),
                                  HexColor("#FFFAC6"),
                                ]) : null,
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text("₹ ${option['amount']}",
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Payment Details
                      const Text("Payment Details",
                          style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 10),

                      Container(
                        width: double.infinity,
                        padding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: HexColor('#FDEF88')),
                          color: Colors.white,
                        ),
                        child: Column(
                          children: [
                            paymentRow("Recharge Amount", "₹ $selectedAmount"),
                            Container(
                              child: Image.asset("assets/yellow_dotted_line.png"),
                            ),
                            paymentRow("Total Amount", "₹ $totalAmount",
                                bold: true),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Pay Now Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _paying ? null : _startPayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.appColor,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _paying
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text("Pay Now",
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Transaction history
                      if (_transactions.isNotEmpty) ...[
                        Text("Recent Transactions",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        ..._transactions.take(5).map((txn) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: HexColor('#E9E9E9')),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: txn.type == 'CREDIT'
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  txn.type == 'CREDIT'
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: txn.type == 'CREDIT'
                                      ? Colors.green
                                      : Colors.red,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      txn.description ?? txn.type,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      "${txn.createdAt.day}/${txn.createdAt.month}/${txn.createdAt.year}",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "${txn.type == 'CREDIT' ? '+' : '-'}₹${txn.amount.toInt()}",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: txn.type == 'CREDIT'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],

                      const SizedBox(height: 100),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The balance figure. A fetch that never landed says so and offers a retry
  /// rather than rendering a real-looking ₹ 0.
  Widget _balanceLine() {
    final balance = _balance;

    if (balance == null) {
      if (_loadFailed) {
        return Column(
          children: [
            const Text("Balance unavailable",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            _retryButton(),
          ],
        );
      }
      // Nothing loaded yet and nothing has failed — a fetch is in flight or is
      // about to be.
      return const SizedBox(
        height: 26,
        width: 26,
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      );
    }

    return Column(
      children: [
        Text("₹ ${balance.toInt()}",
            style: const TextStyle(
                color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        if (_loadFailed) ...[
          const Text("Couldn't refresh — this is the last known balance",
              style: TextStyle(color: Colors.white70, fontSize: 11)),
          _retryButton(),
        ],
      ],
    );
  }

  Widget _retryButton() {
    return TextButton.icon(
      onPressed: _fetching ? null : _loadWallet,
      icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
      label: const Text("Retry",
          style: TextStyle(color: Colors.white, fontSize: 13)),
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget paymentRow(String title, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: bold ? FontWeight.bold : FontWeight.bold)),
        ],
      ),
    );
  }
}
