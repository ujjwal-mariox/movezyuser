import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:http/http.dart' as http;
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/CommonWidgets/prohibited_items_sheet.dart';
import 'package:movezy_user_app/CommonWidgets/booking_terms_sheet.dart';
import 'package:movezy_user_app/Screens/RideFindingScreen/ride_finding_screen.dart';
import 'package:movezy_user_app/Screens/HomeScreen/Model/booking_data.dart';
import 'package:movezy_user_app/Services/booking_service.dart';
import 'package:movezy_user_app/Services/wallet_service.dart';
import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class ReviewBookingScreen extends StatefulWidget {
  final BookingData bookingData;

  const ReviewBookingScreen({super.key, required this.bookingData});

  @override
  State<ReviewBookingScreen> createState() => _ReviewBookingScreenState();
}

class _ReviewBookingScreenState extends State<ReviewBookingScreen> {
  // Data
  FareEstimate? _fare;
  String? _fareError; // set when the fare estimate fails, so we show retry not an infinite spinner
  bool _fareLoading = false;
  List<AddonService> _addons = [];
  List<PromoOffer> _promos = [];
  double _walletBalance = 0;
  bool _loading = true;
  bool _bookingInProgress = false;
  String? _error;

  // Selections
  final Set<String> _selectedAddonIds = {};
  bool _addonsExpanded = false;
  String? _appliedPromoCode;
  double _promoDiscount = 0;
  String _paymentMethod = 'CASH'; // CASH, WALLET, ONLINE
  final TextEditingController _promoController = TextEditingController();
  final TextEditingController _goodsDescController = TextEditingController();

  // Razorpay
  late Razorpay _razorpay;
  bool _isWalletRecharge = false;
  String? _pendingRechargeOrderId;
  double _pendingRechargeAmount = 0;
  // Online booking payment: booking is created first, then paid + verified.
  String? _pendingPayBookingId;
  String? _pendingPayBookingNumber;
  String? _pendingPayOrderId;

  // GST
  String? _userGstin;
  String? _userGstBusinessName;
  final bool _gstLoading = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _loadData();
    _fetchUserGst();
  }

  @override
  void dispose() {
    _razorpay.clear();
    _promoController.dispose();
    _goodsDescController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      print('=== _loadData START ===');
      // Load addons, promos, wallet balance, and fare estimate in parallel
      final results = await Future.wait([
        BookingService.getAddonServices().then((addons) {
          print('Addons loaded: ${addons.length} items');
          for (var a in addons) {
            print('  Addon: ${a.name} (${a.price})');
          }
          return addons;
        }).catchError((e) {
          print('Addons load error: $e');
          return <AddonService>[];
        }),
        BookingService.getAvailablePromos().then((promos) {
          print('Promos loaded: ${promos.length} items');
          return promos;
        }).catchError((e) {
          print('Promos load error: $e');
          return <PromoOffer>[];
        }),
        WalletService.getWallet().then((w) {
          print('Wallet balance loaded: ${w.balance}');
          return w.balance;
        }).catchError((e) {
          print('Wallet load error: $e');
          return 0.0;
        }),
        _fetchFareEstimate().then((fare) {
          print('Fare loaded: ${fare?.totalFare ?? "null"}');
          return fare;
        }).catchError((e) {
          print('Fare load error: $e');
          return null;
        }),
      ]);

      print('=== _loadData RESULTS ===');
      print('Addons count: ${(results[0] as List).length}');
      print('Promos count: ${(results[1] as List).length}');
      print('Wallet: ${results[2]}');
      print('Fare: ${results[3]}');

      if (mounted) {
        setState(() {
          _addons = results[0] as List<AddonService>;
          _promos = results[1] as List<PromoOffer>;
          _walletBalance = results[2] as double;
          _fare = results[3] as FareEstimate?;
          _loading = false;
        });
        _autoApplyBestPromo();
      }
    } catch (e) {
      print('=== _loadData FATAL ERROR: $e ===');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<FareEstimate?> _fetchFareEstimate() async {
    final vehicle = widget.bookingData.selectedVehicle;
    if (vehicle == null) {
      _fareError = 'No vehicle selected. Go back and pick a vehicle.';
      return null;
    }

    // Use actual coordinates if available, else use dummy for demo
    final pickup = {
      'address': widget.bookingData.pickupAddress ?? 'Pickup Location',
      'lat': widget.bookingData.pickupLat ?? 28.6139,
      'lng': widget.bookingData.pickupLng ?? 77.2090,
    };
    final drop = {
      'address': widget.bookingData.dropAddress ?? 'Drop Location',
      'lat': widget.bookingData.dropLat ?? 28.5355,
      'lng': widget.bookingData.dropLng ?? 77.3910,
    };

    try {
      final fare = await BookingService.getFareEstimate(
        pickup: pickup,
        drop: drop,
        vehicleTypeId: vehicle.id,
        serviceType: widget.bookingData.serviceType,
        addons: _selectedAddonIds.map((id) => {'addonServiceId': id}).toList(),
        promoCode: _appliedPromoCode,
      );
      _fareError = null;
      return fare;
    } catch (e) {
      debugPrint('Fare estimate error: $e');
      _fareError = 'Could not calculate fare. Check your connection and retry.';
      return null;
    }
  }

  /// Retry just the fare estimate (shown when it failed).
  Future<void> _retryFare() async {
    setState(() {
      _fareLoading = true;
      _fareError = null;
    });
    final fare = await _fetchFareEstimate();
    if (!mounted) return;
    setState(() {
      _fare = fare;
      _fareLoading = false;
    });
    if (fare != null) _autoApplyBestPromo();
  }

  Future<void> _refreshFare() async {
    final fare = await _fetchFareEstimate();
    if (mounted) {
      setState(() => _fare = fare);
    }
  }

  void _toggleAddon(String addonId) {
    setState(() {
      if (_selectedAddonIds.contains(addonId)) {
        _selectedAddonIds.remove(addonId);
      } else {
        _selectedAddonIds.add(addonId);
      }
    });
    _refreshFare();
  }

  /// Pick the best eligible promo (highest discount) and apply it silently.
  /// Eligibility: fare >= minOrderValue. No-op if already applied or no promos.
  void _autoApplyBestPromo() {
    if (_appliedPromoCode != null || _promos.isEmpty) return;
    final fare = _fare?.finalFare ?? 0;
    if (fare <= 0) return;

    PromoOffer? best;
    double bestDiscount = 0;
    for (final p in _promos) {
      if (fare < p.minOrderValue) continue;
      double d = p.discountType == 'PERCENTAGE'
          ? fare * p.discountValue / 100
          : p.discountValue;
      if (p.maxDiscount != null && d > p.maxDiscount!) d = p.maxDiscount!;
      if (d > bestDiscount) {
        bestDiscount = d;
        best = p;
      }
    }
    if (best != null) {
      _applyPromo(best.code);
    }
  }

  Future<void> _applyPromo(String code) async {
    if (code.isEmpty) return;
    try {
      final fare = _fare?.finalFare ?? 0;
      final result = await BookingService.validatePromo(code, fare);
      if (result['success'] == true) {
        setState(() {
          _appliedPromoCode = code;
          _promoDiscount = (result['data']?['discount'] ?? result['discount'] ?? 0).toDouble();
        });
        _refreshFare();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Promo applied! You save ₹${_promoDiscount.toInt()}'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Invalid promo code'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to apply promo'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _removePromo() {
    setState(() {
      _appliedPromoCode = null;
      _promoDiscount = 0;
      _promoController.clear();
    });
    _refreshFare();
  }

  Future<void> _onBookPressed() async {
    final vehicle = widget.bookingData.selectedVehicle;
    if (vehicle == null || _fare == null) return;

    final totalAmount = _fare!.finalFare;

    if (_paymentMethod == 'WALLET' && _walletBalance < totalAmount) {
      // Show recharge option
      _showRechargeDialog(totalAmount - _walletBalance);
      return;
    }

    if (_paymentMethod == 'ONLINE') {
      // Create the booking first, then a server-side payment order, then pay
      // and VERIFY the signature server-side (the old flow paid with a bare
      // amount and never verified the payment with the backend).
      _payOnlineForBooking();
      return;
    }

    // CASH or WALLET with sufficient balance → create booking
    _createBooking();
  }

  /// Online payment: create booking → create Razorpay order → open checkout.
  /// Verification happens server-side in _onPaymentSuccess.
  Future<void> _payOnlineForBooking() async {
    if (_bookingInProgress) return;
    setState(() => _bookingInProgress = true);
    try {
      final ids = await _createBookingReturningIds();
      if (ids == null) return; // error already surfaced
      final bookingId = ids.$1;

      final order = await BookingService.createPaymentOrder(bookingId);
      _pendingPayBookingId = bookingId;
      _pendingPayBookingNumber = ids.$2;
      _pendingPayOrderId = order['orderId'] as String?;
      _isWalletRecharge = false;

      final options = {
        'key': ApiUrls.razorpayKeyId,
        'amount': ((order['amount'] as num) * 100).toInt(),
        'name': 'Movezy',
        'description': 'Booking Payment',
        'order_id': _pendingPayOrderId,
        'prefill': {'contact': '', 'email': ''},
        'theme': {'color': '#FF7A30'},
      };
      _razorpay.open(options);
    } catch (e) {
      if (mounted) {
        setState(() => _bookingInProgress = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment setup failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Creates the booking and returns (bookingId, bookingNumber), or null on
  /// error (a snackbar is shown and _bookingInProgress is reset). Does NOT
  /// navigate — callers decide what to do next (navigate, or pay-then-verify).
  Future<(String, String)?> _createBookingReturningIds() async {
    try {
      final vehicle = widget.bookingData.selectedVehicle!;
      final pickup = {
        'address': widget.bookingData.pickupAddress ?? 'Pickup Location',
        'lat': widget.bookingData.pickupLat ?? 28.6139,
        'lng': widget.bookingData.pickupLng ?? 77.2090,
      };
      final drop = {
        'address': widget.bookingData.dropAddress ?? 'Drop Location',
        'lat': widget.bookingData.dropLat ?? 28.5355,
        'lng': widget.bookingData.dropLng ?? 77.3910,
      };

      final result = await BookingService.createBooking(
        pickup: pickup,
        drop: drop,
        vehicleTypeId: vehicle.id,
        goodsType: widget.bookingData.goodsTypeCategory ?? 'PERSONAL',
        paymentMethod: _paymentMethod,
        distanceKm: _fare?.distanceKm,
        durationMin: _fare?.durationMin,
        serviceType: widget.bookingData.serviceType,
        addons: _selectedAddonIds.map((id) => {'addonServiceId': id}).toList(),
        promoCode: _appliedPromoCode,
        goodsDescription: _goodsDescController.text.isNotEmpty
            ? _goodsDescController.text
            : widget.bookingData.goodsDescription,
      );

      final bookingId = (result['data']?['_id'] ?? result['_id'] ?? '').toString();
      final bookingNumber = (result['data']?['bookingNumber'] ?? result['bookingNumber'] ?? '').toString();
      if (bookingId.isEmpty) throw Exception('Booking created without an id');
      return (bookingId, bookingNumber);
    } catch (e) {
      if (mounted) {
        setState(() => _bookingInProgress = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: $e'), backgroundColor: Colors.red),
        );
      }
      return null;
    }
  }

  Future<void> _createBooking() async {
    if (_bookingInProgress) return;
    setState(() => _bookingInProgress = true);

    final ids = await _createBookingReturningIds();
    if (ids != null && mounted) {
      _navigateToRideFinding(ids.$1, ids.$2);
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    if (_isWalletRecharge) {
      // This was a wallet recharge — verify, refresh wallet, then create booking
      try {
        await WalletService.verifyRecharge(
          orderId: _pendingRechargeOrderId ?? response.orderId ?? '',
          paymentId: response.paymentId ?? '',
          signature: response.signature ?? '',
          amount: _pendingRechargeAmount,
        );
        // Refresh wallet balance
        try {
          final w = await WalletService.getWallet();
          if (mounted) setState(() => _walletBalance = w.balance);
        } catch (_) {}
        // Now create booking with wallet payment
        _createBooking();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Recharge verification failed: $e'), backgroundColor: Colors.red),
          );
        }
      }
      _isWalletRecharge = false;
    } else {
      // Direct online payment for an already-created booking: VERIFY the
      // payment signature server-side before treating it as paid.
      final bookingId = _pendingPayBookingId;
      try {
        final verified = await BookingService.verifyBookingPayment(
          bookingId: bookingId ?? '',
          orderId: _pendingPayOrderId ?? response.orderId ?? '',
          paymentId: response.paymentId ?? '',
          signature: response.signature ?? '',
        );
        if (!verified) {
          throw Exception('Payment could not be verified');
        }
        if (mounted) {
          _navigateToRideFinding(bookingId ?? '', _pendingPayBookingNumber ?? '');
        }
      } catch (e) {
        if (mounted) {
          setState(() => _bookingInProgress = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment verification failed: $e. Contact support if money was deducted.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    _isWalletRecharge = false;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${response.message ?? "Please try again."}'), backgroundColor: Colors.red),
      );
    }
  }

  void _showRechargeDialog(double shortfall) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Insufficient Wallet Balance', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You need ₹${shortfall.toStringAsFixed(0)} more in your wallet.',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Text(
              'Current balance: ₹${_walletBalance.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _paymentMethod = 'ONLINE');
            },
            child: Text('Pay Online Instead', style: TextStyle(color: Colors.blue)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.appColor),
            onPressed: () {
              Navigator.pop(ctx);
              _rechargeAndPay(shortfall);
            },
            child: Text('Recharge ₹${shortfall.toStringAsFixed(0)}', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _rechargeAndPay(double amount) async {
    try {
      final order = await WalletService.createRechargeOrder(amount);
      // Set recharge mode — the existing _onPaymentSuccess handler will handle it
      _isWalletRecharge = true;
      _pendingRechargeOrderId = order.orderId;
      _pendingRechargeAmount = amount;

      var options = {
        'key': ApiUrls.razorpayKeyId,
        'amount': (amount * 100).toInt(),
        'name': 'Movezy Wallet',
        'description': 'Wallet Recharge',
        'order_id': order.orderId,
        'theme': {'color': '#FF7A30'},
      };
      _razorpay.open(options);
    } catch (e) {
      _isWalletRecharge = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recharge failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _navigateToRideFinding(String bookingId, String bookingNumber) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => RideFindingScreen(bookingId: bookingId, bookingNumber: bookingNumber),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.bookingData.selectedVehicle;
    final vehicleName = vehicle?.name ?? '3 Wheeler';
    final baseFare = vehicle?.baseFare ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _loading ? null : _stickyBottomBar(vehicleName),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.appColor))
          : SingleChildScrollView(
              child: Column(
                children: [
                  commonAppBar(
                    height: 105,
                    context: context,
                    child: Container(
                      padding: const EdgeInsets.only(top: 50),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.only(left: 16),
                              width: 40, height: 35,
                              alignment: Alignment.center,
                              child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text('Review Booking', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _vehicleCard(vehicleName, _fare?.finalFare ?? baseFare),
                        const SizedBox(height: 20),

                        // ── Add-On Services (collapsible dropdown) ──
                        if (_addons.isNotEmpty) ...[
                          _addonDropdownSection(),
                          const SizedBox(height: 20),
                        ],

                        // ── GST Details ──
                        _sectionTitle('GST Details'),
                        _gstCard(context),
                        const SizedBox(height: 20),

                        // ── Offers and Discounts ──
                        _sectionTitle('Offers and Discounts'),
                        const SizedBox(height: 9),
                        _promoSection(),
                        const SizedBox(height: 12),

                        // ── Coins banner ──
                        _coinsBanner(),
                        const SizedBox(height: 20),

                        // ── Fare Summary ──
                        _sectionTitle('Fare Summary'),
                        const SizedBox(height: 10),
                        _fareSummaryCard(),
                        const SizedBox(height: 20),

                        // ── Goods Description (with Change → goods type sheet) ──
                        _sectionTitle('Goods Description'),
                        _goodsCard(widget.bookingData.goodsCategory ?? 'General Goods'),
                        const SizedBox(height: 20),

                        // ── Read Before Booking ──
                        _sectionTitle('Read before Booking'),
                        const SizedBox(height: 10),
                        _readBeforeCard(),
                        const SizedBox(height: 20),

                        // ── Pre-Booking Checklist ──
                        _sectionTitle('Before you proceed'),
                        const SizedBox(height: 10),
                        _preBookingChecklist(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 2))],
    );
  }

  Widget _vehicleCard(String vehicleName, double fare) {
    final vehicle = widget.bookingData.selectedVehicle;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _boxDecoration(),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              vehicle?.image != null && vehicle!.image!.isNotEmpty
                  ? Image.network(ApiUrls.imageProxyUrl(vehicle.image!), height: 60, width: 60, fit: BoxFit.contain, errorBuilder: (_, _, _) => Image.asset('assets/auto.png', height: 60))
                  : Image.asset('assets/auto.png', height: 60),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(vehicleName, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text('₹${fare.toInt()}', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (_fare != null)
                      Text('${_fare!.distanceKm.toStringAsFixed(1)} km · ~${_fare!.durationMin.toInt()} min', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: _showAddressDetailsSheet,
                      child: Text('View Address Details', style: TextStyle(color: Colors.blue.shade700, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.orange.shade50,
                  border: Border.all(color: HexColor('#FFDEC9'), width: 1),
                  gradient: LinearGradient(colors: [HexColor("#FFF6F0"), HexColor("#FFFFFF")]),
                ),
                child: Text('Free 50 mins of loading-unloading time included.', style: GoogleFonts.poppins(fontSize: 9, color: HexColor("#FF6200"))),
              ),
              const SizedBox(width: 4),
              Icon(Icons.report_gmailerrorred, size: 25, color: HexColor('#FF6200')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600));
  }

  Widget _promoSection() {
    if (_appliedPromoCode != null) {
      // Show applied promo
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade300),
          color: Colors.green.shade50,
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_appliedPromoCode!, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('You save ₹${_promoDiscount.toInt()}', style: GoogleFonts.poppins(fontSize: 11, color: Colors.green.shade700)),
                ],
              ),
            ),
            GestureDetector(
              onTap: _removePromo,
              child: Text('Remove', style: GoogleFonts.poppins(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Promo input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: HexColor("#E9E9E9")),
            gradient: LinearGradient(colors: [HexColor("#FEFEF6"), HexColor("#FDF6AB")]),
          ),
          child: Row(
            children: [
              Image.asset("assets/discount.png", width: 30),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _promoController,
                  decoration: InputDecoration(
                    hintText: 'Enter promo code',
                    hintStyle: GoogleFonts.poppins(fontSize: 12),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: GoogleFonts.poppins(fontSize: 12),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              GestureDetector(
                onTap: () => _applyPromo(_promoController.text.trim()),
                child: Text('Apply', style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        // Available promo list
        if (_promos.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 65,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _promos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final p = _promos[i];
                return GestureDetector(
                  onTap: () {
                    _promoController.text = p.code;
                    _applyPromo(p.code);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade200),
                      color: Colors.orange.shade50,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(p.code, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.orange.shade800)),
                        Text(p.displayText, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade700)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _fareSummaryCard() {
    if (_fare == null) {
      // Failed → show the error + a Retry, instead of an infinite "Calculating…".
      if (_fareError != null && !_fareLoading) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: _boxDecoration(),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_fareError!,
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _retryFare,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                ),
              ),
            ],
          ),
        );
      }
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _boxDecoration(),
        child: Center(child: Text('Calculating fare...', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey))),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(),
      child: Column(
        children: [
          _fareRow('Base Fare', '₹${_fare!.baseFare.toStringAsFixed(0)}'),
          const SizedBox(height: 6),
          _fareRow('Distance Charge (${_fare!.distanceKm.toStringAsFixed(1)} km)', '₹${_fare!.distanceCharge.toStringAsFixed(0)}'),
          if (_fare!.timeCharge > 0) ...[const SizedBox(height: 6), _fareRow('Time Charge', '₹${_fare!.timeCharge.toStringAsFixed(0)}')],
          if (_fare!.surgeCharge > 0) ...[const SizedBox(height: 6), _fareRow('Surge Charge', '₹${_fare!.surgeCharge.toStringAsFixed(0)}')],
          if (_fare!.addonCharges > 0) ...[const SizedBox(height: 6), _fareRow('Add-on Services', '₹${_fare!.addonCharges.toStringAsFixed(0)}')],
          if (_fare!.tollCharges > 0) ...[const SizedBox(height: 6), _fareRow('Toll Charges', '₹${_fare!.tollCharges.toStringAsFixed(0)}')],
          const SizedBox(height: 8),
          Image.asset("assets/dotted_line.png", height: 1),
          const SizedBox(height: 8),
          _fareRow('Subtotal', '₹${_fare!.totalFare.toStringAsFixed(0)}'),
          if (_fare!.gst > 0) ...[const SizedBox(height: 6), _fareRow('GST', '₹${_fare!.gst.toStringAsFixed(0)}')],
          if (_fare!.discount > 0 || _promoDiscount > 0) ...[
            const SizedBox(height: 6),
            _fareRow('Discount', '-₹${(_fare!.discount > 0 ? _fare!.discount : _promoDiscount).toStringAsFixed(0)}', color: Colors.green),
          ],
          const SizedBox(height: 8),
          Image.asset("assets/dotted_line.png", height: 1),
          const SizedBox(height: 8),
          _fareRow('Amount Payable', '₹${_fare!.finalFare.toStringAsFixed(0)}', bold: true),
        ],
      ),
    );
  }

  Widget _fareRow(String title, String amount, {bool bold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 12, fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
        Text(amount, style: GoogleFonts.poppins(fontSize: 12, fontWeight: bold ? FontWeight.w600 : FontWeight.w400, color: color)),
      ],
    );
  }

  Widget _addonDropdownSection() {
    final selectedCount = _selectedAddonIds.length;
    // Calculate total addon cost
    double addonTotal = 0;
    for (final addon in _addons) {
      if (_selectedAddonIds.contains(addon.id)) {
        addonTotal += addon.price;
      }
    }

    return Container(
      decoration: _boxDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Dropdown header
          InkWell(
            onTap: () => setState(() => _addonsExpanded = !_addonsExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.home_repair_service_outlined, color: AppColors.appColor, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add-On Services', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                        if (selectedCount > 0)
                          Text('$selectedCount selected · ₹${addonTotal.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.appColor, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _addonsExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600, size: 24),
                  ),
                ],
              ),
            ),
          ),
          // Expandable addon list
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Divider(height: 1, color: Colors.grey.shade200),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    children: _addons.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _addonCard(a),
                    )).toList(),
                  ),
                ),
              ],
            ),
            crossFadeState: _addonsExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _addonCard(AddonService addon) {
    final selected = _selectedAddonIds.contains(addon.id);
    final priceLabel = addon.priceType == 'PER_FLOOR'
        ? '₹${addon.price.toInt()}/floor'
        : addon.priceType == 'PER_KG'
            ? '₹${addon.price.toInt()}/kg'
            : '₹${addon.price.toInt()}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? AppColors.appColor : Colors.grey.shade200, width: selected ? 1.5 : 1),
        color: selected ? AppColors.appColor.withOpacity(0.04) : Colors.white,
      ),
      child: Row(
        children: [
          // Icon / Image
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(addon.icon.isNotEmpty ? addon.icon : '📋', style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          // Name + description + price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(addon.name, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                if (addon.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(addon.description, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 4),
                Text(priceLabel, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // + ADD / ✓ ADDED button
          GestureDetector(
            onTap: () => _toggleAddon(addon.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? Colors.green : AppColors.appColor, width: 1.5),
                color: selected ? Colors.green.shade50 : Colors.white,
              ),
              child: Text(
                selected ? '✓ ADDED' : '+ ADD',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.green : AppColors.appColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentMethodSection() {
    final totalAmount = _fare?.finalFare ?? 0;
    final hasEnoughWallet = _walletBalance >= totalAmount;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose Payment Method', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          // Wallet option
          _paymentOptionTile(
            icon: Icons.account_balance_wallet,
            color: Colors.green,
            title: 'Wallet',
            subtitle: 'Balance: ₹${_walletBalance.toStringAsFixed(0)}${!hasEnoughWallet && _paymentMethod == 'WALLET' ? ' (Low balance)' : ''}',
            value: 'WALLET',
            trailing: !hasEnoughWallet
                ? GestureDetector(
                    onTap: () => _showRechargeDialog(totalAmount - _walletBalance),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.orange.shade50,
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Text('Add & Pay', style: GoogleFonts.poppins(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.w600)),
                    ),
                  )
                : null,
          ),

          // Online payment
          _paymentOptionTile(
            icon: Icons.credit_card,
            color: Colors.blue,
            title: 'Pay Online',
            subtitle: 'UPI / Card / Net Banking',
            value: 'ONLINE',
          ),

          // Cash
          _paymentOptionTile(
            icon: Icons.money,
            color: Colors.orange,
            title: 'Cash',
            subtitle: 'Pay after delivery',
            value: 'CASH',
          ),

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Total: ', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
              Text('₹${totalAmount.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentOptionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String value,
    Widget? trailing,
  }) {
    final selected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color : Colors.grey.shade300, width: selected ? 1.5 : 1),
          color: selected ? color.withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (trailing != null) trailing,
            const SizedBox(width: 8),
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? color : Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _goodsCard(String category) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(category, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
              GestureDetector(
                onTap: _showGoodsTypeSheet,
                child: Text("Change", style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _goodsDescController,
            decoration: InputDecoration(
              hintText: 'Describe your goods (optional)',
              hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: Colors.green),
              const SizedBox(width: 8),
              const Expanded(child: Text("Do not send restricted items", style: TextStyle(fontSize: 13))),
              InkWell(
                onTap: () => showProhibitedItemsSheet(context),
                child: Text("View List", style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _readBeforeCard() {
    return Container(
      padding: const EdgeInsets.only(left: 5, right: 5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• Fare includes 65 mins free loading/unloading time.", style: TextStyle(fontSize: 11)),
          const SizedBox(height: 6),
          const Text("• ₹3.0/min for additional loading/unloading time.", style: TextStyle(fontSize: 11)),
          const SizedBox(height: 6),
          const Text("• Additional charges may apply for tolls and parking.", style: TextStyle(fontSize: 11)),
          const SizedBox(height: 6),
          const Text("• Cancellation charges apply after driver is assigned.", style: TextStyle(fontSize: 11)),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => showBookingTermsSheet(
              context,
              vehicleName: widget.bookingData.selectedVehicle?.name,
            ),
            child: Text(
              "View full Terms & Conditions",
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _preBookingChecklist() {
    final items = [
      {'icon': Icons.inventory_2_outlined, 'text': 'Ensure your goods are packed properly before pickup'},
      {'icon': Icons.person_pin_circle_outlined, 'text': 'Be present at the pickup location when driver arrives'},
      {'icon': Icons.description_outlined, 'text': 'Keep a list/photo of items being shipped'},
      {'icon': Icons.block_outlined, 'text': 'Do not include restricted or prohibited items'},
      {'icon': Icons.phone_android_outlined, 'text': 'Keep your phone reachable for driver coordination'},
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE0C2)),
      ),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item['icon'] as IconData, size: 18, color: AppColors.appColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item['text'] as String,
                    style: const TextStyle(fontSize: 12, height: 1.3, color: Color(0xFF444444)),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _bookButton(String vehicleName) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.appColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: _bookingInProgress ? null : _onBookPressed,
        child: _bookingInProgress
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(
                "Book $vehicleName",
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white),
              ),
      ),
    );
  }

  // ─── Porter-style coins banner ───
  Widget _coinsBanner() {
    final fare = _fare?.finalFare ?? 0;
    // 1 coin per ₹100 spent (configurable)
    final coins = (fare / 100).floor();
    if (coins <= 0) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(colors: [HexColor('#4B0082'), HexColor('#7B2FBE')]),
      ),
      child: Row(
        children: [
          const Text('🪙', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "You'll get $coins coins on this order ✨",
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sticky bottom bar: Payment + Fare + Book button ───
  Widget _stickyBottomBar(String vehicleName) {
    final totalAmount = _fare?.finalFare ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Payment method selector row
            Row(
              children: [
                GestureDetector(
                  onTap: _showPaymentMethodSheet,
                  child: Row(
                    children: [
                      Icon(
                        _paymentMethod == 'CASH' ? Icons.money : _paymentMethod == 'WALLET' ? Icons.account_balance_wallet : Icons.credit_card,
                        color: AppColors.appColor, size: 22,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Choose Payment Method', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade600)),
                          Row(
                            children: [
                              Text(
                                _paymentMethod == 'CASH' ? 'Cash' : _paymentMethod == 'WALLET' ? 'Wallet' : 'Online',
                                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              const Icon(Icons.keyboard_arrow_down, size: 18),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${totalAmount.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () {
                        // Scroll to fare summary or show breakdown
                      },
                      child: Text('View Breakup', style: GoogleFonts.poppins(fontSize: 10, color: Colors.blue.shade700, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Book button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.appColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _bookingInProgress ? null : _onBookPressed,
                child: _bookingInProgress
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        "Book $vehicleName",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Address details bottom sheet ───
  void _showAddressDetailsSheet() {
    final pickup = widget.bookingData.pickupAddress ?? 'Pickup Location';
    final drop = widget.bookingData.dropAddress ?? 'Drop Location';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Address Details', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            // Pickup
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.green.shade700, width: 2),
                      ),
                    ),
                    Container(width: 2, height: 40, color: Colors.grey.shade300),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pickup', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(pickup, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 3, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            // Drop
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red.shade700, width: 2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Drop', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(drop, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 3, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Distance & time row
            if (_fare != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _addressInfoItem(Icons.route, '${_fare!.distanceKm.toStringAsFixed(1)} km', 'Distance'),
                    Container(width: 1, height: 30, color: Colors.grey.shade300),
                    _addressInfoItem(Icons.access_time, '~${_fare!.durationMin.toInt()} min', 'Est. Time'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _addressInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.appColor),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }

  // ─── Payment method bottom sheet ───
  void _showPaymentMethodSheet() {
    final totalAmount = _fare?.finalFare ?? 0;
    final hasEnoughWallet = _walletBalance >= totalAmount;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose Payment Method', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              _paymentSheetTile(Icons.money, Colors.orange, 'Cash', 'Pay after delivery', 'CASH', ctx),
              _paymentSheetTile(
                Icons.account_balance_wallet,
                Colors.green,
                'Wallet',
                'Balance: ₹${_walletBalance.toStringAsFixed(0)}${!hasEnoughWallet ? ' (Insufficient)' : ''}',
                'WALLET',
                ctx,
              ),
              _paymentSheetTile(Icons.credit_card, Colors.blue, 'Pay Online', 'UPI / Card / Net Banking', 'ONLINE', ctx),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _paymentSheetTile(IconData icon, Color color, String title, String subtitle, String value, BuildContext ctx) {
    final selected = _paymentMethod == value;
    return GestureDetector(
      onTap: () {
        setState(() => _paymentMethod = value);
        Navigator.pop(ctx);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : Colors.grey.shade300, width: selected ? 1.5 : 1),
          color: selected ? color.withOpacity(0.06) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? color : Colors.grey.shade400, size: 22),
          ],
        ),
      ),
    );
  }

  // ─── Goods type change bottom sheet (Porter-style) ───
  void _showGoodsTypeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _GoodsTypeSheet(
          currentCategory: widget.bookingData.goodsCategory,
          onSelected: (String name) {
            Navigator.pop(ctx);
            setState(() {
              _goodsDescController.text = name;
            });
          },
        );
      },
    );
  }

  Widget _gstCard(BuildContext context) {
    // If user has a saved GSTIN, show it with a green badge
    if (_userGstin != null && _userGstin!.isNotEmpty) {
      return Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(14),
        decoration: _boxDecoration().copyWith(
          border: Border.all(color: Colors.green.shade200, width: 1),
        ),
        child: Row(
          children: [
            Image.asset("assets/tax_icon.png", width: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Text('GSTIN Added', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(_userGstin!, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  if (_userGstBusinessName != null && _userGstBusinessName!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(_userGstBusinessName!, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                    child: Text('GST invoice will be generated for this booking',
                        style: GoogleFonts.poppins(fontSize: 9.5, color: Colors.green.shade700)),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _showGstSheet(context),
              child: Text('Edit', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: HexColor("#3268E4"))),
            ),
          ],
        ),
      );
    }

    // No GSTIN - show prompt to add
    return GestureDetector(
      onTap: () => _showGstSheet(context),
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.only(left: 10, right: 10, top: 16, bottom: 16),
        decoration: _boxDecoration(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset("assets/tax_icon.png", width: 40),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width - 110,
                  child: Row(
                    children: [
                      Text('Have a GST Number?', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('Add GSTIN', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: HexColor("#3268E4"))),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
                  child: Text('Get invoices with GSTIN for Input Tax Credit', style: GoogleFonts.poppins(fontSize: 9.3, color: Colors.black87)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Fetch user's saved GSTIN from backend
  Future<void> _fetchUserGst() async {
    try {
      final token = Prefs.getString('token');
      if (token.isEmpty) return;
      final response = await http.get(
        Uri.parse(ApiUrls.gstUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['data'] != null && json['data']['gstin'] != null) {
          if (mounted) {
            setState(() {
              _userGstin = json['data']['gstin'];
              _userGstBusinessName = json['data']['businessName'];
            });
          }
        }
      }
    } catch (e) {
      debugPrint('GST fetch error: $e');
    }
  }

  /// Submit GSTIN to backend
  Future<bool> _submitGstin(String gstin, {String? businessName}) async {
    try {
      final token = Prefs.getString('token');
      if (token.isEmpty) return false;
      final body = {'gstin': gstin};
      if (businessName != null && businessName.isNotEmpty) {
        body['businessName'] = businessName;
      }
      final response = await http.post(
        Uri.parse(ApiUrls.gstUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      debugPrint('GST submit error: $e');
    }
    return false;
  }

  /// Show bottom sheet for entering GSTIN
  void _showGstSheet(BuildContext context) {
    final gstinController = TextEditingController(text: _userGstin ?? '');
    final businessNameController = TextEditingController(text: _userGstBusinessName ?? '');
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [HexColor("#FDF6AB"), Colors.white, Colors.white],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Add GSTIN', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 6)],
                            ),
                            child: Icon(Icons.close, size: 20, color: HexColor("#FF6200")),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 80, width: 80,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: AppColors.appColor, width: 2),
                      ),
                      child: Image.asset('assets/gst.png', errorBuilder: (_, _, _) => Icon(Icons.receipt_long, size: 40, color: AppColors.appColor)),
                    ),
                    const SizedBox(height: 14),
                    Text('Get invoices with GSTIN for your bookings and claim Input Tax Credit',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade700)),
                    const SizedBox(height: 18),
                    // GSTIN field
                    TextField(
                      controller: gstinController,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 15,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]'))],
                      decoration: InputDecoration(
                        counterText: '',
                        labelText: 'GSTIN',
                        hintText: 'e.g. 29AABCU9603R1ZM',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      style: GoogleFonts.poppins(fontSize: 14, letterSpacing: 1),
                    ),
                    const SizedBox(height: 12),
                    // Business name field
                    TextField(
                      controller: businessNameController,
                      decoration: InputDecoration(
                        labelText: 'Business Name (optional)',
                        hintText: 'Your company name',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.appColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final gstin = gstinController.text.trim();
                                if (gstin.isEmpty || gstin.length < 15) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please enter a valid 15-digit GSTIN')));
                                  return;
                                }
                                setSheetState(() => isSubmitting = true);
                                final success = await _submitGstin(gstin, businessName: businessNameController.text.trim());
                                setSheetState(() => isSubmitting = false);
                                if (success) {
                                  Navigator.pop(context);
                                  setState(() {
                                    _userGstin = gstin.toUpperCase();
                                    _userGstBusinessName = businessNameController.text.trim();
                                  });
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                      const SnackBar(content: Text('GSTIN saved! Invoice will be generated with this GSTIN.'), backgroundColor: Colors.green));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Failed to save GSTIN'), backgroundColor: Colors.red));
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text('Save GSTIN', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Goods Type Selection Sheet (Porter-style) ───
class _GoodsTypeSheet extends StatefulWidget {
  final String? currentCategory;
  final void Function(String name) onSelected;

  const _GoodsTypeSheet({this.currentCategory, required this.onSelected});

  @override
  State<_GoodsTypeSheet> createState() => _GoodsTypeSheetState();
}

class _GoodsTypeSheetState extends State<_GoodsTypeSheet> {
  List<GoodsType> _categories = [];
  String? _selectedName;
  bool _loading = true;
  bool _showRestricted = false;

  final List<String> _restrictedItems = [
    'Narcotics / drugs',
    'Explosives & firearms',
    'Alcohol / liquor',
    'Live animals',
    'Human remains',
    'Currency / jewellery',
  ];

  @override
  void initState() {
    super.initState();
    _selectedName = widget.currentCategory;
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final cats = await BookingService.getGoodsTypes();
      if (mounted) setState(() { _categories = cats; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Select Goods Type', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, size: 24),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Restricted items banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('🚫', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Restricted Items', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                                Text('Narcotics drugs, explosives & more', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade700)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _showRestricted = !_showRestricted),
                            child: Row(
                              children: [
                                Text('See All', style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.w500)),
                                Icon(_showRestricted ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 18, color: Colors.blue.shade700),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_showRestricted) ...[
                        const SizedBox(height: 10),
                        ...(_restrictedItems.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(Icons.block, size: 14, color: Colors.red.shade400),
                              const SizedBox(width: 8),
                              Text(item, style: GoogleFonts.poppins(fontSize: 12, color: Colors.red.shade700)),
                            ],
                          ),
                        ))),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Categories list
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _categories.length,
                        itemBuilder: (ctx, i) {
                          final cat = _categories[i];
                          final isSelected = _selectedName == cat.name;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedName = cat.name),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
                                  width: isSelected ? 1.5 : 1,
                                ),
                                color: isSelected ? Colors.blue.shade50 : Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Text(cat.icon.isNotEmpty ? cat.icon : '📦', style: const TextStyle(fontSize: 22)),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(cat.name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                                  ),
                                  if (isSelected)
                                    Icon(Icons.edit, size: 18, color: Colors.blue.shade700),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Disclaimer + Confirm
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Disclaimer: Movezy shall bear limited liability whatsoever for loss, damage, deterioration, delay, or regulatory non-compliance arising from the transportation of the listed item.',
                  style: GoogleFonts.poppins(fontSize: 9.5, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.appColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _selectedName != null ? () => widget.onSelected(_selectedName!) : null,
                      child: Text('Confirm', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
