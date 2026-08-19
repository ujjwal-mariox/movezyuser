import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:http/http.dart' as http;
import 'package:movezy_user_app/CommonWidgets/location_icon.dart';
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/CommonWidgets/prohibited_items_sheet.dart';
import 'package:movezy_user_app/CommonWidgets/booking_terms_sheet.dart';
import 'package:movezy_user_app/Screens/DashboardScreen/dashboard_screen.dart';
import 'package:movezy_user_app/Screens/RideFindingScreen/ride_finding_screen.dart';
import 'package:movezy_user_app/Screens/HomeScreen/Model/booking_data.dart';
import 'package:movezy_user_app/Screens/VehicleSelectionScreen/vehicle_selection_screen.dart';
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

  // Declared floors for PER_FLOOR add-ons. The design shows pickup/drop floor
  // pickers driving the loading service fare; without them the app advertised
  // "₹50/floor" and the server could only ever bill a single flat unit.
  int _pickupFloor = 0;
  int _dropFloor = 0;
  bool _isLiftAvailable = false;

  // ─── "Select Service" progressive flow (per the design) ───
  //
  // Loading is priced PER PARTNER now, not per floor, so floors/lift are
  // declared context rather than multipliers. Each answer reveals the next
  // question, exactly as the design steps through it.

  /// Add-on code of the chosen service: LDUNLD | LDING | UNLD. Null = unasked.
  String? _serviceCode;

  /// null = not answered yet; the design only reveals lift/floor after "No".
  bool? _pickupGround;
  bool? _pickupLift;
  bool? _dropGround;
  bool? _dropLift;

  /// BUSINESS | PERSONAL
  String? _goodsNature;
  /// CARTON | OTHER
  String? _goodsSubType;

  /// Quantity steppers, by weight band.
  int _qtySmall = 0; // 1-10 Kg
  int _qtyLarge = 0; // 10-25 Kg

  /// Declared load derived from the quantity bands — midpoint of each band, so
  /// the partner count the server computes tracks what the customer picked.
  int get _declaredKg => (_qtySmall * 5) + (_qtyLarge * 18);

  /// Partner count mirrors the server rule purely to show the figure; the
  /// server recomputes it and is the authority.
  ///
  /// Read off `_goodsWeightKg` — the weight actually posted — and bounded the
  /// way `resolveGoodsWeight` bounds it (MAX_GOODS_KG = 10000, so at most 100
  /// partners). It used to clamp itself to 50, so a very heavy declared load
  /// showed half the partners the server would bill for.
  int get _partnerCount {
    final kg = _goodsWeightKg <= 0
        ? 0
        : (_goodsWeightKg > 10000 ? 10000 : _goodsWeightKg);
    return kg <= 0 ? 1 : (kg / 100).ceil();
  }

  bool get _serviceChosen => _serviceCode != null;

  /// Floors are only "answered" once ground-floor is No AND a floor is picked.
  bool get _pickupAnswered =>
      _pickupGround == true || (_pickupGround == false && _pickupFloor > 0);
  bool get _dropAnswered =>
      _dropGround == true || (_dropGround == false && _dropFloor > 0);

  /// What Proceed actually needs. Add-ons are OPTIONAL and must never block a
  /// booking (client decision) — the old gate required the loading service,
  /// floors, goods type and quantity for EVERY booking, so a customer who
  /// wanted no help at all could not book without answering questions about a
  /// service they weren't buying. The Load Assist answers are required only
  /// once a loading add-on is selected, because partner count and the
  /// per-floor charge are priced from them.
  bool get _loadAssistComplete =>
      _pickupAnswered &&
      _dropAnswered &&
      _goodsNature != null &&
      _goodsSubType != null &&
      (_qtySmall + _qtyLarge) > 0;

  bool get _serviceFlowComplete =>
      _pickupTimeAnswered && (!_serviceChosen || _loadAssistComplete);

  /// A future date means nothing without a slot: the booking is created from
  /// the slot's `scheduledAt`, so picking "Tomorrow" and leaving the slot
  /// unset used to book a pickup for right now. Today needs no slot — that IS
  /// "pick up now".
  bool get _pickupTimeAnswered =>
      DateUtils.isSameDay(_selectedDate, DateTime.now()) ||
      _selectedSlot != null;

  /// Loading services now live IN the add-on list (client decision: one place
  /// to pick services, all optional). They stay mutually exclusive with each
  /// other — picking one clears the other two — via the special-cased toggle in
  /// _addonDesignCard, and selecting any of them reveals the Load Assist
  /// section below.
  static const _loadingCodes = {'LDUNLD', 'LDING', 'UNLD'};

  /// Loading first, so the section leads with the service that has follow-up
  /// questions; the extras (Packing, Insurance, Receiving Copy) follow.
  List<AddonService> get _extraAddons {
    final loading =
        _addons.where((a) => _loadingCodes.contains(a.code)).toList();
    final rest =
        _addons.where((a) => !_loadingCodes.contains(a.code)).toList();
    return [...loading, ...rest];
  }

  // Declared load for PER_KG add-ons. Same problem the floors had: the card
  // advertised "₹25/kg" while nothing ever asked how heavy the load was, so
  // the server could only bill one flat unit.
  int _goodsWeightKg = 0;

  /// The goods category shown on the card. Held here rather than read straight
  /// off widget.bookingData, because "Change" has to be able to update it —
  /// it used to write the chosen name into the *description* field and leave
  /// the displayed category untouched, so the control appeared to do nothing.
  String? _goodsCategory;

  /// Which half of Review Booking is showing.
  ///
  /// The design is two sequential pages: CONFIGURE (service, floors, goods,
  /// pickup time) then REVIEW (offers, fare, add-ons, GST, goods summary).
  /// They are two steps of ONE widget rather than two routes on purpose — every
  /// fare recalculation, promo validation and payment handler below reads this
  /// screen's state, and splitting it across routes would mean migrating all of
  /// that. Back on step 1 returns to step 0 instead of leaving the flow.
  /// 0 = the review page. 1 = the Load Assist page, opened the moment a
  /// loading add-on is selected (client's flow: the add-on opts you into a
  /// dedicated page with the service, floors, goods, quantity and pickup time
  /// — the approved mock). It is a page over the same State, not a pushed
  /// route, so every section keeps calling setState/_refreshFare directly.
  int _step = 0;

  // Selections
  final Set<String> _selectedAddonIds = {};
  // Only the CODE is kept. The saving is never cached from /promos/validate:
  // that figure is priced against the fare at the moment of validation and
  // goes stale on the next re-quote, so the applied-promo card used to
  // contradict the Fare Summary's "Offer / Coupon" row on the same screen.
  // Everything that shows a discount reads _fare.discount instead.
  String? _appliedPromoCode;
  String _paymentMethod = 'CASH'; // CASH, WALLET, ONLINE
  final TextEditingController _promoController = TextEditingController();
  final TextEditingController _goodsDescController = TextEditingController();

  // ── Scheduled pickup ("Select pickup time" in the design) ──
  // null slot = pick up now. Choosing a slot creates the booking as DRAFT and
  // the scheduled-dispatch job sends it to drivers near the pickup time.
  DateTime _selectedDate = DateTime.now();
  List<TimeSlotOption> _slots = [];
  TimeSlotOption? _selectedSlot;
  bool _loadingSlots = false;
  bool _showAllSlots = false;
  // Consignee (who receives the parcel at the drop). Optional: when a phone is
  // given, the backend SMSs them at pickup — they have no app account.
  final TextEditingController _receiverNameController = TextEditingController();
  final TextEditingController _receiverPhoneController = TextEditingController();

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

  @override
  void initState() {
    super.initState();
    _goodsCategory = widget.bookingData.goodsCategory;
    // The goods type chosen on its own screen already answers
    // Business-vs-Personal (every GoodsType carries a category), so prefill
    // the "Select type of goods" block instead of asking again from scratch.
    // The block's Change still lets them re-answer here.
    // "Above 250kg" on LoadAssist used to survive only as text in the goods
    // description while Review's steppers started at zero — the customer
    // declared a heavy load and the fare was quoted for none. Seed the large
    // band so the two screens agree; the customer can still adjust it.
    final declaredKg = widget.bookingData.goodsWeight ?? 0;
    if (declaredKg >= 250 && _qtySmall == 0 && _qtyLarge == 0) {
      _qtyLarge = (declaredKg / 18).ceil();
      _goodsWeightKg = _declaredKg;
    }

    final presetNature = widget.bookingData.goodsTypeCategory;
    if (presetNature == 'BUSINESS' || presetNature == 'PERSONAL') {
      _goodsNature = presetNature;
    }
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _loadData();
    _fetchUserGst();
    _loadSlots();
  }

  @override
  void dispose() {
    _razorpay.clear();
    _promoController.dispose();
    _goodsDescController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
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
          final loaded = results[0] as List<AddonService>;
          // Admin targeting: an add-on scoped to specific goods categories is
          // only offered where it applies (empty scope = everywhere).
          final myCategory = widget.bookingData.goodsTypeCategory;
          _addons = loaded.where((a) {
            if (a.applicableGoodsCategories.isEmpty) return true;
            if (myCategory == null) return true;
            return a.applicableGoodsCategories.contains(myCategory);
          }).toList();
          _promos = results[1] as List<PromoOffer>;
          _walletBalance = results[2] as double;
          _fare = results[3] as FareEstimate?;
          _loading = false;
        });
        _autoApplyBestPromo();
        _preselectAutoApplyAddons();
      }
    } catch (e) {
      print('=== _loadData FATAL ERROR: $e ===');
      if (mounted) {
        // Each section carries its own error/retry state; nothing reads a
        // screen-level error, so just stop the spinner.
        setState(() => _loading = false);
      }
    }
  }

  Future<FareEstimate?> _fetchFareEstimate() async {
    final vehicle = widget.bookingData.selectedVehicle;
    if (vehicle == null) {
      _fareError = 'No vehicle selected. Go back and pick a vehicle.';
      return null;
    }

    // Require REAL coordinates. These used to fall back to fixed Delhi/Noida
    // coords "for demo", so a booking with unresolved addresses quoted the fare
    // for a ~20 km route in Delhi that had nothing to do with the user's trip —
    // and they could then book it. Fail loudly instead of inventing a location.
    if (widget.bookingData.pickupLat == null ||
        widget.bookingData.pickupLng == null) {
      _fareError = "We couldn't pin your pickup location. Go back and pick it on the map.";
      return null;
    }
    if (widget.bookingData.dropLat == null ||
        widget.bookingData.dropLng == null) {
      _fareError = "We couldn't pin your drop location. Go back and pick it on the map.";
      return null;
    }

    final pickup = {
      'address': widget.bookingData.pickupAddress ?? 'Pickup Location',
      'lat': widget.bookingData.pickupLat,
      'lng': widget.bookingData.pickupLng,
    };
    final drop = {
      'address': widget.bookingData.dropAddress ?? 'Drop Location',
      'lat': widget.bookingData.dropLat,
      'lng': widget.bookingData.dropLng,
    };

    try {
      final fare = await BookingService.getFareEstimate(
        pickup: pickup,
        drop: drop,
        // Stops are priced per stop server-side; without this the quote here
        // was lower than what the booking would actually cost.
        stops: widget.bookingData.stops,
        vehicleTypeId: vehicle.id,
        serviceType: widget.bookingData.serviceType,
        addons: _selectedAddonIds.map((id) => {'addonServiceId': id}).toList(),
        promoCode: _appliedPromoCode,
        pickupFloor: _pickupFloor,
        dropFloor: _dropFloor,
        isLiftAvailable: _isLiftAvailable,
        goodsWeight: _goodsWeightKg,
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

  // Monotonic guard: only the LAST requested quote may land. Without it a
  // slow older response could overwrite the fare for a newer selection.
  int _fareRequestSeq = 0;

  /// Sequence number of the quote currently held in [_fare]. While it trails
  /// [_fareRequestSeq] a re-quote is in flight and [_fare] is the previous
  /// server figure — so anything that would otherwise announce "no discount"
  /// can wait instead of announcing it about the wrong quote.
  int _fareSettledSeq = 0;

  bool get _fareQuoting => _fareSettledSeq != _fareRequestSeq;

  Future<void> _refreshFare() async {
    // Deliberately no setState here: several callers invoke this from inside
    // their own setState closure. The counter is read during the next build.
    final seq = ++_fareRequestSeq;
    final fare = await _fetchFareEstimate();
    if (mounted && seq == _fareRequestSeq) {
      setState(() {
        _fare = fare;
        _fareSettledSeq = seq;
      });
    }
  }

  /// Pick the best eligible promo (highest discount) and apply it silently.
  /// Eligibility: fare >= minOrderValue. No-op if already applied or no promos.
  /// Admin-configured auto-apply (e.g. insurance on high-value orders):
  /// PRESELECTS the add-on so its charge is visible on this page before any
  /// payment. The customer can untick it — nothing is ever added silently,
  /// and loading-service add-ons are excluded because they open the Load
  /// Assist flow and must stay an explicit choice.
  void _preselectAutoApplyAddons() {
    final fareNow = _fare?.finalFare ?? 0;
    if (fareNow <= 0) return;
    var changed = false;
    for (final a in _addons) {
      if (!a.autoApply) continue;
      if (_loadingCodes.contains(a.code)) continue;
      if (fareNow < a.autoApplyMinFare) continue;
      if (_selectedAddonIds.contains(a.id)) continue;
      _selectedAddonIds.add(a.id);
      changed = true;
    }
    if (changed && mounted) setState(() {});
  }

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
      // Vehicle/service context matters: without it a promo restricted to
      // other vehicle types "validates" here and is then silently dropped by
      // the estimate and the booking — an applied promo that never applies.
      final result = await BookingService.validatePromo(
        code,
        fare,
        vehicleTypeId: widget.bookingData.selectedVehicle?.id,
        serviceType: widget.bookingData.serviceType,
      );
      if (result['success'] == true) {
        setState(() => _appliedPromoCode = code);
        // The saving is whatever the re-quote below comes back with. Quoting
        // it here from the validate response would put a number on screen
        // that the very next request can change.
        _refreshFare();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Promo $code applied'), backgroundColor: Colors.green),
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
      _promoController.clear();
    });
    _refreshFare();
  }

  Future<void> _onBookPressed() async {
    final vehicle = widget.bookingData.selectedVehicle;
    if (vehicle == null || _fare == null) return;

    // A booking already exists with its payment awaiting verification —
    // creating another would double-book (and possibly double-charge).
    if (_pendingPayBookingId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Your previous payment is still being verified. Use Retry on the notice, or contact support.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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

    if (_paymentMethod == 'WALLET') {
      // WALLET with sufficient balance → create booking, then actually DEBIT the
      // wallet. The old flow only created the booking and never charged the
      // wallet, so the ride was effectively free.
      _createBookingAndPayWallet();
      return;
    }

    // CASH → create booking (settled at delivery)
    _createBooking();
  }

  /// Create the booking and pay for it from the wallet. Only navigate on a
  /// successful debit; otherwise surface the reason and leave nothing stranded.
  Future<void> _createBookingAndPayWallet() async {
    if (_bookingInProgress) return;
    setState(() => _bookingInProgress = true);

    final ids = await _createBookingReturningIds();
    if (ids == null) return; // error already surfaced, state reset below
    if (!mounted) return;

    final (ok, message) = await BookingService.payWithWallet(ids.$1);
    if (!mounted) return;

    if (ok) {
      _navigateToRideFinding(ids.$1, ids.$2);
    } else {
      // The booking is already live (and dispatched). An unpaid WALLET booking
      // must not stay in SEARCHING — cancel it so a driver can't accept it and
      // a retry can't create a duplicate.
      BookingService.cancelBooking(ids.$1)
          .catchError((_) => <String, dynamic>{});
      setState(() => _bookingInProgress = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.isNotEmpty ? message : 'Wallet payment failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
      // Track the booking BEFORE the order call: it is already created (and
      // dispatched to drivers), so if anything below throws the catch must be
      // able to find and cancel it — not leave it ringing phones unpaid.
      _pendingPayBookingId = bookingId;
      _pendingPayBookingNumber = ids.$2;

      final order = await BookingService.createPaymentOrder(bookingId);
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
      // The booking was created (and dispatched) before payment setup broke —
      // cancel it, same as _onPaymentError, so no driver runs an unpaid trip
      // and a retry can't stack a duplicate on top of it.
      if (_pendingPayBookingId != null) {
        final strandedId = _pendingPayBookingId!;
        _pendingPayBookingId = null;
        BookingService.cancelBooking(strandedId)
            .catchError((_) => <String, dynamic>{});
      }
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

      // Never invent trip metrics. The backend prices from these, so booking
      // without a quote would charge the customer for a fabricated trip.
      final fare = _fare;
      if (fare == null) {
        if (mounted) {
          // Free the button — this branch used to leave it spinning forever.
          setState(() => _bookingInProgress = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fare not available yet. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }

      // Never invent a location. These defaulted to fixed Delhi/Noida coords, so
      // a booking with unresolved addresses was dispatched to the wrong place
      // entirely — a driver would be sent ~1000 km from the customer.
      final pLat = widget.bookingData.pickupLat;
      final pLng = widget.bookingData.pickupLng;
      final dLat = widget.bookingData.dropLat;
      final dLng = widget.bookingData.dropLng;
      if (pLat == null || pLng == null || dLat == null || dLng == null) {
        if (mounted) {
          setState(() => _bookingInProgress = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  "We couldn't pin your pickup or drop location. Go back and choose it on the map."),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }

      final pickup = {
        'address': widget.bookingData.pickupAddress ?? 'Pickup Location',
        'lat': pLat,
        'lng': pLng,
      };
      final drop = {
        'address': widget.bookingData.dropAddress ?? 'Drop Location',
        'lat': dLat,
        'lng': dLng,
      };

      final result = await BookingService.createBooking(
        pickup: pickup,
        drop: drop,
        // Persist the stops the customer added so the driver is routed via them.
        stops: widget.bookingData.stops,
        // A chosen slot makes this a scheduled booking (backend creates it as
        // DRAFT; scheduled-dispatch releases it to drivers near the time).
        // No slot = pick up now, which is the default.
        scheduledDate: _selectedSlot?.scheduledAt?.toIso8601String(),
        scheduledTimeSlotId: _selectedSlot?.id,
        vehicleTypeId: vehicle.id,
        // The review screen's Business/Personal answer wins — it used to be
        // collected and then silently discarded in favour of the earlier
        // screen's value, so changing it here changed nothing.
        goodsType: _goodsNature ?? widget.bookingData.goodsTypeCategory ?? 'PERSONAL',
        paymentMethod: _paymentMethod,
        distanceKm: fare.distanceKm,
        durationMin: fare.durationMin,
        // Must be the same floors/weight the quote above was priced on.
        pickupFloor: _pickupFloor,
        dropFloor: _dropFloor,
        isLiftAvailable: _isLiftAvailable,
        goodsWeight: _goodsWeightKg,
        // Package count the customer declared on the quantity steppers. The
        // backend has always accepted and stored this; nothing ever sent it,
        // so the driver arrived not knowing how many items to expect.
        goodsQuantity: _qtySmall + _qtyLarge,
        serviceType: widget.bookingData.serviceType,
        addons: _selectedAddonIds.map((id) => {'addonServiceId': id}).toList(),
        promoCode: _appliedPromoCode,
        goodsDescription: _goodsDescController.text.isNotEmpty
            ? _goodsDescController.text
            : widget.bookingData.goodsDescription,
        receiverName: _receiverNameController.text,
        receiverPhone: _receiverPhoneController.text,
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
        // Now create booking AND debit the wallet (the recharge just topped it
        // up; without this the booking would still never be charged).
        _createBookingAndPayWallet();
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
      _verifyPendingPayment(
        orderId: _pendingPayOrderId ?? response.orderId ?? '',
        paymentId: response.paymentId ?? '',
        signature: response.signature ?? '',
      );
    }
  }

  /// Verify the pending online payment server-side; navigate on success.
  ///
  /// On failure the booking id is KEPT: money may already have left the
  /// customer's account, so we offer a Retry instead of dropping the booking —
  /// and while it is pending, _onBookPressed refuses to create another one.
  Future<void> _verifyPendingPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final bookingId = _pendingPayBookingId;
    try {
      final verified = await BookingService.verifyBookingPayment(
        bookingId: bookingId ?? '',
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
      );
      if (!verified) {
        throw Exception('Payment could not be verified');
      }
      _pendingPayBookingId = null;
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
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _verifyPendingPayment(
                orderId: orderId,
                paymentId: paymentId,
                signature: signature,
              ),
            ),
          ),
        );
      }
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    final wasRecharge = _isWalletRecharge;
    _isWalletRecharge = false;

    // Free the Book button (it was left spinning forever before).
    if (mounted) setState(() => _bookingInProgress = false);

    // An online booking is created and dispatched BEFORE payment. If payment
    // fails or is cancelled, cancel that booking so a driver can't run an unpaid
    // trip and it isn't left stranded in SEARCHING. (Recharge failures have no
    // booking to clean up.)
    if (!wasRecharge && _pendingPayBookingId != null) {
      final strandedId = _pendingPayBookingId!;
      _pendingPayBookingId = null;
      // Fire-and-forget; a failed cleanup shouldn't block the error toast.
      BookingService.cancelBooking(strandedId)
          .catchError((_) => <String, dynamic>{});
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message ?? "Please try again."}'),
          backgroundColor: Colors.red,
        ),
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
    // A scheduled booking is created as DRAFT and only dispatched near the
    // slot time — the "finding drivers" screen would spin forever over a
    // search that isn't happening. Confirm the schedule instead.
    if (_selectedSlot != null) {
      _showScheduledConfirmation(bookingNumber);
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => RideFindingScreen(bookingId: bookingId, bookingNumber: bookingNumber),
      ),
      (route) => false,
    );
  }

  /// "Pickup scheduled" confirmation for a DRAFT (slot) booking, then home.
  void _showScheduledConfirmation(String bookingNumber) {
    final slotLabel = _selectedSlot?.label ?? '';
    final dateLabel = DateFormat('EEE, d MMM').format(_selectedDate);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.event_available, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Pickup scheduled',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        content: Text(
          'Booking #$bookingNumber is scheduled for $dateLabel at $slotLabel. '
          "We'll assign a driver near the pickup time — track it from Booking History.",
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.appColor),
            onPressed: () {
              Navigator.pop(ctx);
              replaceRoute(context, const DashboardScreen());
            },
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.bookingData.selectedVehicle;
    final vehicleName = vehicle?.name ?? '3 Wheeler';
    final baseFare = vehicle?.baseFare ?? 0;

    return PopScope(
      // Step 1 -> step 0 on system back, so a hardware/gesture back doesn't
      // drop the customer out of the flow and lose everything they configured.
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step == 1) setState(() => _step = 0);
      },
      child: Scaffold(
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
                            onTap: () => _step == 1
                                ? setState(() => _step = 0)
                                : Navigator.pop(context),
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
                      children: _step == 0
                          ? _reviewStep(vehicleName, baseFare)
                          : _loadAssistStep(vehicleName, baseFare),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  /// STEP 0 — configure: what service, which floors, what goods, what time.
  /// ONE page, in the client's order: what it costs and where it goes FIRST,
  /// then the optional add-ons, then (only if a loading add-on was picked) the
  /// Load Assist questions, then schedule and the rest. This replaced a
  /// two-step flow whose first screen demanded the loading service, floors,
  /// goods and quantity before the customer had even seen the address or the
  /// price.
  List<Widget> _reviewStep(String vehicleName, double baseFare) => [
        _vehicleCard(vehicleName, _fare?.finalFare ?? baseFare),
        const SizedBox(height: 12),

        // Address up front, inline — it used to live only behind the "View
        // Address Details" sheet, so the one thing every customer checks
        // before paying needed an extra tap to see.
        _addressCard(),
        const SizedBox(height: 20),

        _sectionTitle('Fare Summary'),
        const SizedBox(height: 10),
        _fareSummaryCard(),
        const SizedBox(height: 20),

        _sectionTitle('Offers and Discounts'),
        const SizedBox(height: 9),
        _promoSection(),
        const SizedBox(height: 20),

        // ALL add-ons, loading services included and listed first. Selecting a
        // loading add-on reveals Load Assist directly beneath.
        if (_extraAddons.isNotEmpty) ...[
          _addonDropdownSection(),
          const SizedBox(height: 12),
        ],

        if (_serviceChosen) ...[
          _loadAssistSummaryCard(),
          const SizedBox(height: 20),
        ],

        _buildScheduleSection(),
        const SizedBox(height: 20),

        _sectionTitle('GST Details'),
        _gstCard(context),
        const SizedBox(height: 20),

        _sectionTitle('Goods Description'),
        const SizedBox(height: 10),
        _goodsSummaryCard(),
        const SizedBox(height: 20),

        _sectionTitle('Read before Booking'),
        const SizedBox(height: 10),
        _readBeforeCard(),
        const SizedBox(height: 100),
      ];

  /// The Load Assist page — the approved mock: chosen service with Change,
  /// pickup/drop floor details, type of goods, quantity, and pickup time, with
  /// the same sticky bar (service-fare strip + Proceed) underneath. Proceed
  /// returns to the review page with everything applied.
  List<Widget> _loadAssistStep(String vehicleName, double baseFare) => [
        _vehicleCard(vehicleName, _fare?.finalFare ?? baseFare),
        const SizedBox(height: 12),
        _loadAssistSection(),
        const SizedBox(height: 16),
        _buildScheduleSection(),
        const SizedBox(height: 100),
      ];

  /// Compact recap of the Load Assist answers on the review page, with Edit
  /// reopening the page. Without this, a customer who came back to review had
  /// no way into the page again short of toggling the add-on off and on.
  Widget _loadAssistSummaryCard() {
    final packages = _qtySmall + _qtyLarge;
    final bits = <String>[
      if (_pickupAnswered && _dropAnswered)
        _pickupGround == true && _dropGround == true
            ? 'Ground floor both ends'
            : 'Floors set',
      if (_goodsSubType != null)
        _goodsSubType == 'CARTON' ? 'Cartons' : 'Other goods',
      if (packages > 0) '$packages package${packages == 1 ? '' : 's'}',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _boxDecoration(),
      child: Row(
        children: [
          Image.asset('assets/delivery_person.png', width: 26, height: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_serviceLabel(_serviceCode!),
                    style: GoogleFonts.poppins(
                        fontSize: 13.5, fontWeight: FontWeight.w600)),
                if (bits.isNotEmpty)
                  Text(bits.join('  ·  '),
                      style: GoogleFonts.poppins(
                          fontSize: 11.5, color: Colors.grey.shade600)),
                if (!_loadAssistComplete)
                  Text('Details needed before booking',
                      style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFE23B32))),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _step = 1),
            child: Text('Edit',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1668E3))),
          ),
        ],
      ),
    );
  }

  /// Compact inline pickup/drop card. Rows, not a sheet: the client asked for
  /// address and price to be visible before any add-on decision.
  Widget _addressCard() {
    final pickup = widget.bookingData.pickupAddress ?? 'Pickup Location';
    final drop = widget.bookingData.dropAddress ?? 'Drop Location';
    final stops = widget.bookingData.stops;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: LocationIcon.pickup(size: AppIconSize.md),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(pickup,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 13, height: 1.35)),
              ),
            ],
          ),
          if (stops.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 21, top: 4),
              child: Text(
                '+ ${stops.length} stop${stops.length == 1 ? '' : 's'}',
                style: GoogleFonts.poppins(
                    fontSize: 11.5, color: Colors.grey.shade600),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: LocationIcon.drop(size: AppIconSize.md),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(drop,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 13, height: 1.35)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Read-only recap of what step 0 collected, with a Change link back to the
  /// goods sheet. Weight and package count are the customer's own declared
  /// figures — there is no declared-value field, so none is shown.
  Widget _goodsSummaryCard() {
    final packages = _qtySmall + _qtyLarge;
    final bits = <String>[
      if (_declaredKg > 0) '$_declaredKg Kg',
      if (packages > 0) '$packages Package${packages == 1 ? '' : 's'}',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _goodsCategory?.isNotEmpty == true
                      ? _goodsCategory!
                      : 'General Goods',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              GestureDetector(
                onTap: _showGoodsTypeSheet,
                child: Text('Change',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1668E3))),
              ),
            ],
          ),
          if (bits.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(bits.join('  ·  '),
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey.shade600)),
          ],
          const SizedBox(height: 10),
          _restrictedStrip(),
        ],
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
                        // Expanded (replacing Text + Spacer): the name was a bare
                        // Row child, so it got unbounded width and laid out at its
                        // intrinsic width — the Spacer then had no free space to
                        // give and a long server-driven name like 'Tata Ace Gold
                        // Closed Body' overflowed instead of ellipsizing. Expanded
                        // bounds it and still pushes the fare to the right edge.
                        Expanded(
                          child: Text(vehicleName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        if (_fare != null)
                          _serviceFlowComplete
                              // `durationMin` is the quote's estimate for the
                              // whole pickup → drop run (road distance at a
                              // city speed) — the same figure the time charge
                              // is priced on. It says nothing about how long
                              // until a driver reaches you, yet this read
                              // "~N mins away", word for word the Home
                              // screen's driver-arrival ETA.
                              ? Text.rich(
                                  TextSpan(children: [
                                    TextSpan(
                                        text: 'Trip time ',
                                        style: GoogleFonts.poppins(
                                            fontSize: 13.5,
                                            color: Colors.black87)),
                                    TextSpan(
                                        text:
                                            '~${_fare!.durationMin.toInt()} mins',
                                        style: GoogleFonts.poppins(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                            color: HexColor('#FF6200'))),
                                  ]),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                        '₹${(_fare!.baseFare + _fare!.distanceCharge + _fare!.timeCharge + _fare!.surgeCharge).round()}',
                                        style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700)),
                                    Text('Vehicle fare',
                                        style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: Colors.grey.shade500)),
                                  ],
                                ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _showAddressDetailsSheet,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                              _serviceFlowComplete
                                  ? 'View Address Details'
                                  : 'View Booking Details',
                              style: TextStyle(
                                  color: Colors.blue.shade700, fontSize: 13)),
                          if (!_serviceFlowComplete)
                            Icon(Icons.keyboard_arrow_down,
                                size: 18, color: Colors.blue.shade700),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Expanded, so the sentence is width-bounded and wraps. As a
              // plain Row child the chip got unbounded constraints and laid the
              // text out on one line at its intrinsic width — it could never
              // wrap or ellipsize, so it overflowed to the right.
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.orange.shade50,
                    border: Border.all(color: HexColor('#FFDEC9'), width: 1),
                    gradient: LinearGradient(colors: [HexColor("#FFF6F0"), HexColor("#FFFFFF")]),
                  ),
                  // Real value from FareConfig — this said "Free 50 mins" while
                  // the server bills after ~10, and the fare summary below it
                  // claimed 65. Hidden entirely if the server didn't tell us.
                  child: Text(
                    !_serviceFlowComplete
                        ? (_selectedSlot != null
                            ? 'Pickup at ${_selectedSlot!.label}'
                            // "in 30 mins" is only true for today. On a future
                            // date with no slot chosen it described a pickup
                            // that was never going to happen.
                            : !_pickupTimeAnswered
                                ? 'Choose a slot for ${DateFormat('EEE, d MMM').format(_selectedDate)}'
                                // Not "in 30 mins": nothing produces a pickup
                                // ETA. `estimatedPickupTime` exists on the
                                // Booking model but is never assigned, and no
                                // config carries a pickup window — so the 30
                                // was invented. Today with no slot simply means
                                // "as soon as a driver accepts".
                                : 'Pickup as soon as a driver accepts')
                        : (_fare?.freeWaitingMinutes ?? 0) > 0
                            ? 'Free ${_fare!.freeWaitingMinutes} mins of loading-unloading time included.'
                            : 'Free loading-unloading time included.',
                    style: GoogleFonts.poppins(
                        fontSize: !_serviceFlowComplete ? 12 : 9,
                        color: HexColor("#FF6200")),
                  ),
                ),
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
      // The saving comes from the CURRENT server quote — the same
      // `_fare.discount` the Fare Summary's "Offer / Coupon" row prints, in
      // the same format. This used to be the validate-time figure, which never
      // changed again, so after any re-quote (add-ons, floors, weight, stops,
      // a different date) the card and the summary disagreed on the same page.
      final quote = _fare;
      final saving = quote?.discount ?? 0;
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
                  // A re-quote is out: the saving for THIS selection isn't
                  // known yet, and "you save ₹0" would be wrong in the common
                  // case where the promo is about to be priced in.
                  if (_fareQuoting)
                    Text('Updating your saving…',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey.shade600))
                  // No quote at all — the Fare Summary below is already
                  // showing the failure and a Retry, so say nothing here.
                  else if (quote == null)
                    const SizedBox.shrink()
                  else if (saving > 0)
                    Text('You save ${_money(saving)}',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.green.shade700))
                  else
                    // The code is applied but the server's quote for this
                    // selection carries no discount. Saying so beats silently
                    // implying a saving that isn't in the total below.
                    Text('No discount on this fare',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey.shade700)),
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

    // Collapsed row per the design — the field and the offers list moved into
    // the "Select / Enter Promo Code" sheet.
    return GestureDetector(
      onTap: _showPromoSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: HexColor("#E9E9E9")),
          gradient:
              LinearGradient(colors: [HexColor("#FEFEF6"), HexColor("#FDF6AB")]),
        ),
        child: Row(
          children: [
            Image.asset("assets/discount.png", width: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Select a promo code',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 13.5, color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(width: 8),
            Text('View Offers/Apply',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: HexColor("#E8452C"),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  /// "Select / Enter Promo Code" sheet — manual entry plus the browsable
  /// offers list, both backed by /promos/validate and /promos/available.
  void _showPromoSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollCtrl) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Select / Enter Promo Code',
                          style: GoogleFonts.poppins(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetCtx),
                      icon: const Icon(Icons.close),
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
              // Manual code entry
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.only(left: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE4E4E4)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promoController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'Enter Promo Code',
                            hintStyle: GoogleFonts.poppins(
                                fontSize: 14, color: Colors.grey.shade500),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(sheetCtx);
                            _applyPromo(_promoController.text.trim());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.appColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 26, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Apply',
                              style: GoogleFonts.poppins(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text('Available Offers',
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _promos.isEmpty
                    ? Center(
                        child: Text('No offers available right now.',
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: Colors.grey.shade600)),
                      )
                    : ListView.separated(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: _promos.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, i) =>
                            _offerCard(_promos[i], sheetCtx),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _offerCard(PromoOffer p, BuildContext sheetCtx) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.description.isEmpty ? p.displayText : p.description,
            style: GoogleFonts.poppins(fontSize: 14, height: 1.35),
          ),
          if (p.minOrderValue > 0) ...[
            const SizedBox(height: 6),
            Text('On orders above ${p.minOrderValue.toInt()}/-',
                style: GoogleFonts.poppins(
                    fontSize: 12.5, color: Colors.grey.shade600)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFE8B84B)),
                ),
                child: Text(p.code,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _promoController.text = p.code;
                  _applyPromo(p.code);
                },
                child: Text('Apply',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.appColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _loadSlots() async {
    setState(() => _loadingSlots = true);
    final slots = await BookingService.getTimeSlots(date: _selectedDate);
    if (!mounted) return;
    setState(() {
      _slots = slots;
      _loadingSlots = false;
      // Slot ids are shared across dates (one TimeSlot doc per time of day)
      // but scheduledAt is resolved per requested date — so re-point the
      // selection at the freshly fetched object. Keeping the old one meant a
      // slot picked on one date silently kept the previous date's instant,
      // and the booking was scheduled for the wrong day.
      if (_selectedSlot != null) {
        final match =
            slots.where((s) => s.id == _selectedSlot!.id).toList();
        _selectedSlot = match.isEmpty ? null : match.first;
      }
    });
  }

  /// "Select pickup time" — date strip + slot chips, per the design.
  ///
  /// Scheduling was fully modelled server-side (isScheduled/scheduledAt, the
  /// TimeSlot collection, a dispatch job) but had no UI, so no customer could
  /// ever create a scheduled booking.
  Widget _buildScheduleSection() {
    final days = List.generate(7, (i) => DateTime.now().add(Duration(days: i)));
    final visibleSlots = _showAllSlots ? _slots : _slots.take(5).toList();

    // The date tiles hold two text lines + 16px of padding — about 55px at
    // text scale 1.0, so the old fixed 62px strip overflowed the moment the
    // system font was any larger ("BOTTOM OVERFLOWED" stripes on every tile).
    // Scale the strip with the device's text scale instead.
    final ts = MediaQuery.textScalerOf(context).scale(14) / 14.0;
    final stripHeight = (62.0 * ts).clamp(62.0, 96.0);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10, bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 14),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text("Select pickup time",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              DateFormat('MMM yyyy').format(_selectedDate).toUpperCase(),
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 10),

          // Date strip
          SizedBox(
            height: stripHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: days.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final d = days[i];
                final selected = DateUtils.isSameDay(d, _selectedDate);
                final label = i == 0
                    ? 'Today'
                    : (i == 1 ? 'Tomorrow' : DateFormat('EEE').format(d));
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = d;
                      _showAllSlots = false;
                      // Changing the day invalidates the slot picked for the
                      // previous one; _loadSlots re-points it if the same slot
                      // exists on the new date.
                      if (!DateUtils.isSameDay(d, DateTime.now())) {
                        _showAllSlots = true;
                      }
                    });
                    _loadSlots();
                  },
                  child: Container(
                    width: 74,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? HexColor("#FF6200").withValues(alpha: 0.08)
                          : Colors.white,
                      border: Border.all(
                        color:
                            selected ? HexColor("#FF6200") : HexColor("#E1E6EF"),
                        width: selected ? 1.4 : 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(label,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? HexColor("#FF6200")
                                  : Colors.black87,
                            )),
                        const SizedBox(height: 2),
                        Text('${d.day}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? HexColor("#FF6200")
                                  : Colors.black87,
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // Slot chips — "in 30 mins" (book now) first, then real slots.
          if (_loadingSlots)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Booking now is the default — no slot selected.
                  _slotChip(
                    label: 'in 30 MINS',
                    selected: _selectedSlot == null,
                    onTap: () => setState(() => _selectedSlot = null),
                  ),
                  ...visibleSlots.map((s) => _slotChip(
                        label: s.label,
                        selected: _selectedSlot?.id == s.id,
                        onTap: () => setState(() => _selectedSlot = s),
                      )),
                ],
              ),
            ),

          if (!_loadingSlots && _slots.length > 5)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 10),
              child: InkWell(
                onTap: () => setState(() => _showAllSlots = !_showAllSlots),
                child: Text(
                  _showAllSlots ? 'Show fewer slots' : 'View all Slots',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: HexColor("#2A5CD0"),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),

          if (!_loadingSlots && _slots.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: Text(
                'No pickup slots left for this day — choose another date, or book now.',
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _slotChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:
              selected ? HexColor("#FF6200").withValues(alpha: 0.08) : Colors.white,
          border: Border.all(
            color: selected ? HexColor("#FF6200") : HexColor("#E1E6EF"),
            width: selected ? 1.4 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? HexColor("#FF6200") : Colors.black87,
          ),
        ),
      ),
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
      child: Builder(builder: (_) {
        // The design's condensed summary. Every figure is the server's own and
        // each row now says a different thing:
        //   Trip Fare  — the quote's subtotal plus its GST, before any offer.
        //   Offer / Coupon — the discount the server applied to THIS quote.
        //   Amount Payable — the server's finalFare, printed verbatim.
        //
        // It used to print that one payable total three times over: "Net Fare"
        // (floored), "Amount Payable (rounded)" (two decimals — so the row
        // labelled rounded was the only one carrying paise) and again in the
        // sticky bar at whole rupees. The derived rows are gone; one figure,
        // one row, and _money() formats every amount on this screen the same
        // way. The full itemisation lives behind View Breakup.
        final trip = (_fare!.totalFare + _fare!.gst);
        // Server-confirmed discount ONLY. Falling back to the validate-time
        // figure made this row subtract a discount that "Amount Payable"
        // (the server's finalFare) did not include.
        final disc = _fare!.discount;
        return Column(
          children: [
            _fareRow('Trip Fare (incl. Toll & GST)', _money(trip)),
            if (disc > 0) ...[
              const SizedBox(height: 8),
              Image.asset("assets/dotted_line.png", height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Offer / Coupon',
                      style: GoogleFonts.poppins(fontSize: 13)),
                  const SizedBox(width: 2),
                  const Icon(Icons.error_outline,
                      size: 14, color: Colors.redAccent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 4),
                        ],
                      ),
                      child: Text(
                        'Use your discount coupons and avail the great deals.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 8.5, color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('-${_money(disc)}',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87)),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Image.asset("assets/dotted_line.png", height: 1),
            const SizedBox(height: 8),
            _fareRow('Amount Payable', _money(_fare!.finalFare), bold: true),
          ],
        );
      }),
    );
  }

  /// Itemised fare, straight from the server's quote. Rows that don't apply to
  /// this trip are omitted rather than shown as ₹0.
  void _showFareBreakup() {
    final fare = _fare;
    if (fare == null) return;

    final rows = <Widget>[
      _fareRow('Base fare', '₹${fare.baseFare.toStringAsFixed(2)}'),
      _fareRow('Distance (${fare.distanceKm.toStringAsFixed(1)} km)',
          '₹${fare.distanceCharge.toStringAsFixed(2)}'),
      _fareRow('Time (${fare.durationMin.toStringAsFixed(0)} min)',
          '₹${fare.timeCharge.toStringAsFixed(2)}'),
      if (fare.surgeCharge > 0)
        _fareRow('Surge', '₹${fare.surgeCharge.toStringAsFixed(2)}'),
      if (fare.stopCharges > 0)
        _fareRow('Extra stops', '₹${fare.stopCharges.toStringAsFixed(2)}'),
      if (fare.addonCharges > 0)
        _fareRow('Add-on services', '₹${fare.addonCharges.toStringAsFixed(2)}'),
      if (fare.loadingUnloadingCharge > 0)
        _fareRow('Loading & unloading',
            '₹${fare.loadingUnloadingCharge.toStringAsFixed(2)}'),
      if (fare.tollCharges > 0)
        _fareRow('Tolls', '₹${fare.tollCharges.toStringAsFixed(2)}'),
      if (fare.gst > 0) _fareRow('GST', '₹${fare.gst.toStringAsFixed(2)}'),
      if (fare.discount > 0)
        _fareRow('Discount', '-₹${fare.discount.toStringAsFixed(2)}',
            color: Colors.green),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      // Needed so the sheet may exceed the default half-screen cap; without it
      // a long breakup (stops + add-ons + tolls + GST + discount) overflowed
      // and clipped the Total — the one line the customer opened this to see.
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.8,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Fare Breakup',
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 14),
                // Only the line items scroll. The Total below stays pinned, so
                // it can never be pushed off the bottom.
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final r in rows) ...[r, const SizedBox(height: 8)],
                      ],
                    ),
                  ),
                ),
                const Divider(height: 20),
                // Same label and same format as the Fare Summary's payable
                // row, because it is the same server figure.
                _fareRow('Amount Payable', _money(fare.finalFare), bold: true),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Waiting is free for the first ${fare.freeWaitingMinutes} minutes, '
                    'then ₹${fare.waitingChargePerMin.toStringAsFixed(0)}/min.',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Pickup/drop floor pickers, shown only when a per-floor add-on is selected.
  /// Changing a floor re-quotes, so the number on screen is always the number
  /// the server will bill.
  // ══════════ "Select Service" flow (design images 2–6) ══════════

  static const _services = [
    ['LDUNLD', 'Loading & unloading'],
    ['UNLD', 'Unloading only'],
    ['LDING', 'Loading only'],
  ];

  String _serviceLabel(String code) =>
      _services.firstWhere((s) => s[0] == code, orElse: () => ['', ''])[1];

  /// Section shell: white block, grey gap above, title, then content.
  Widget _svcBlock(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Same scale as _sectionTitle — these headed their cards at 18/w700
          // while every other section on the page titles at 14/w600.
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _svcRadioRow({
    IconData? icon,
    String? asset,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // The design uses illustrated icons, which ship as assets. A
            // Material glyph is the fallback for rows that have no artwork.
            if (asset != null)
              Image.asset(asset, width: 26, height: 26)
            else
              Icon(icon ?? Icons.circle_outlined,
                  color: AppColors.appColor, size: 22),
            const SizedBox(width: 14),
            // Expanded so long labels wrap rather than overflow the row.
            Expanded(
              child: Text(label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 13.5, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(width: 8),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: selected ? AppColors.appColor : Colors.black54,
                    width: 2),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.appColor),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  /// Collapsed "<icon> <label>   Change" header shown once a step is answered.
  Widget _svcChosenRow(IconData icon, String label, VoidCallback onChange,
      {String? asset}) {
    return Column(
      children: [
        Row(
          children: [
            // Same artwork as the unselected row, so choosing an option does
            // not swap the design's icon for a generic glyph.
            if (asset != null)
              Image.asset(asset, width: 26, height: 26)
            else
              Icon(icon, color: AppColors.appColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 13.5, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onChange,
              child: Text('Change',
                  style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1668E3))),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _DashedLine(),
      ],
    );
  }

  /// Yes / No pill pair. `value` null = neither chosen yet.
  Widget _yesNo({
    required String question,
    required bool? value,
    required ValueChanged<bool> onChanged,
  }) {
    Widget pill(String text, bool isYes) {
      final active = value == isYes;
      return GestureDetector(
        onTap: () => onChanged(isYes),
        child: Container(
          // 64, not 74: two 74px pills plus gaps left too little room for the
          // question, so "Pickup on ground floor?" wrapped onto a second line
          // and crowded the controls. The design keeps it on one line.
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: active ? AppColors.appColor : const Color(0xFFE0E0E0),
                width: 1.5),
          ),
          child: Text(text,
              style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.appColor : Colors.grey.shade400)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(question,
                // One line, shrinking a touch on narrow phones rather than
                // wrapping and pushing the pills out of alignment.
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 12.5, color: const Color(0xFF3D3D3D))),
          ),
          const SizedBox(width: 8),
          pill('Yes', true),
          const SizedBox(width: 8),
          pill('No', false),
        ],
      ),
    );
  }

  /// "Select floor" dropdown, shown only after ground-floor = No.
  Widget _floorDropdown({
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: value > 0 ? value : null,
          hint: Text('Select floor',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey.shade600)),
          icon: const Icon(Icons.keyboard_arrow_down, size: 26),
          padding: const EdgeInsets.symmetric(vertical: 12),
          items: [
            for (int i = 1; i <= 20; i++)
              DropdownMenuItem(
                value: i,
                child: Text(
                    i == 1
                        ? '1st Floor'
                        : i == 2
                            ? '2nd Floor'
                            : i == 3
                                ? '3rd Floor'
                                : '${i}th Floor',
                    style: GoogleFonts.poppins(fontSize: 13)),
              ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  /// Quantity card with a − N + stepper, per weight band.
  Widget _qtyCard({
    required String band,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),
              child: Text(band,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 12.5, fontWeight: FontWeight.w600)),
            ),
            // The design's hand-truck illustration, which already shipped as an
            // asset but was never referenced — the card drew a generic Material
            // box glyph instead.
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Image.asset('assets/quantity_icon.png',
                  height: 46, fit: BoxFit.contain),
            ),
            const Divider(height: 1, color: Color(0xFFEDEDED)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _qtyBtn('−', () {
                  if (value > 0) onChanged(value - 1);
                }),
                Text('$value',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                _qtyBtn('+', () => onChanged(value + 1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(String glyph, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Text(glyph,
            style: GoogleFonts.poppins(
                fontSize: 20, fontWeight: FontWeight.w600)),
      ),
    );
  }

  /// The whole Select Service → floors → goods → quantity flow.
  ///
  /// Sits on a grey backdrop so each white block reads as its own card, the way
  /// the design separates Select Service / type of goods / pickup time. Without
  /// it the blocks were white-on-white and ran together.
  Widget _loadAssistSection() {
    return Container(
      color: const Color(0xFFF1F1F1),
      child: Column(
      children: [
        const SizedBox(height: 10),
        // The service itself is chosen in Add-On Services now; this block only
        // collects what that service needs to be priced and staffed — floors,
        // goods and quantity — so it appears exactly when a loading add-on is
        // selected and never blocks a booking without one.
        _svcBlock('Select Service', [
          ...[
            _svcChosenRow(
              Icons.engineering_outlined,
              _serviceLabel(_serviceCode!),
              () => setState(() {
                _serviceCode = null;
                _syncServiceAddon();
                // No service — nothing left to configure here; back to review
                // where the add-on list is.
                _step = 0;
              }),
              asset: 'assets/delivery_person.png',
            ),
            const SizedBox(height: 14),
            Text('Pickup details',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            _yesNo(
              question: 'Pickup on ground floor?',
              value: _pickupGround,
              onChanged: (v) {
                setState(() {
                  _pickupGround = v;
                  if (v) {
                    _pickupFloor = 0;
                    _pickupLift = null;
                  }
                  _syncLift();
                });
                // Floors price PER_FLOOR add-ons server-side — re-quote so the
                // total on screen is the total the booking will bill.
                _refreshFare();
              },
            ),
            if (_pickupGround == false) ...[
              _yesNo(
                question: 'Lift available?',
                value: _pickupLift,
                onChanged: (v) => setState(() {
                  _pickupLift = v;
                  _syncLift();
                }),
              ),
              _floorDropdown(
                value: _pickupFloor,
                onChanged: (v) {
                  setState(() => _pickupFloor = v);
                  _refreshFare();
                },
              ),
            ],
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFE8E8E8)),
            const SizedBox(height: 14),
            Text('Drop details',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            _yesNo(
              question: 'Drop on ground floor?',
              value: _dropGround,
              onChanged: (v) {
                setState(() {
                  _dropGround = v;
                  if (v) {
                    _dropFloor = 0;
                    _dropLift = null;
                  }
                  _syncLift();
                });
                // Same as pickup: floors change the bill, so re-quote.
                _refreshFare();
              },
            ),
            if (_dropGround == false) ...[
              _yesNo(
                question: 'Lift available?',
                value: _dropLift,
                onChanged: (v) => setState(() {
                  _dropLift = v;
                  _syncLift();
                }),
              ),
              _floorDropdown(
                value: _dropFloor,
                onChanged: (v) {
                  setState(() => _dropFloor = v);
                  _refreshFare();
                },
              ),
            ],
          ],
        ]),
        const SizedBox(height: 10),
        _svcBlock('Select type of goods', [
          if (_goodsNature == null) ...[
            // The design's illustrated icons — an orange briefcase for
            // business, the delivery figure for personal. These were generic
            // Material glyphs (business_center / home), which is what made the
            // block look unlike the mock.
            _svcRadioRow(
              asset: 'assets/business_icon.png',
              label: 'Business or Commercial goods',
              selected: false,
              onTap: () => setState(() => _goodsNature = 'BUSINESS'),
            ),
            _svcRadioRow(
              asset: 'assets/delivery_person.png',
              label: 'Personal or Household goods',
              selected: false,
              onTap: () => setState(() => _goodsNature = 'PERSONAL'),
            ),
          ] else ...[
            _svcChosenRow(
              _goodsNature == 'BUSINESS'
                  ? Icons.business_center_outlined
                  : Icons.home_outlined,
              // Carry the specific category picked earlier (Electronics,
              // Furniture…) into the label, so this block and the goods-type
              // screen visibly describe the same choice.
              _goodsCategory != null && _goodsCategory!.isNotEmpty
                  ? '${_goodsNature == 'BUSINESS' ? 'Business' : 'Personal'} · $_goodsCategory'
                  : _goodsNature == 'BUSINESS'
                      ? 'Business or Commercial goods'
                      : 'Personal or Household goods',
              // Change reopens the goods-type sheet — the real source of the
              // choice — rather than a disconnected radio re-ask.
              _goodsCategory != null && _goodsCategory!.isNotEmpty
                  ? _showGoodsTypeSheet
                  : () => setState(() {
                        _goodsNature = null;
                        _goodsSubType = null;
                      }),
              asset: _goodsNature == 'BUSINESS'
                  ? 'assets/business_icon.png'
                  : 'assets/delivery_person.png',
            ),
            const SizedBox(height: 6),
            if (_goodsSubType == null) ...[
              _svcSubTypeRow('Carton Box | Bag | Container | Bundle | Rolls',
                  'CARTON'),
              _svcSubTypeRow('Other goods', 'OTHER'),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _goodsSubType == 'CARTON'
                          ? 'Carton Box | Bag | Container | Bundle | Rolls'
                          : 'Other goods',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _goodsSubType = null),
                    child: Text('Change',
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1668E3))),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Quantity',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _qtyCard(
                    band: '1-10Kg',
                    value: _qtySmall,
                    onChanged: (v) =>
                        setState(() { _qtySmall = v; _syncDeclaredWeight(); }),
                  ),
                  const SizedBox(width: 12),
                  _qtyCard(
                    band: '10-25Kg',
                    value: _qtyLarge,
                    onChanged: (v) =>
                        setState(() { _qtyLarge = v; _syncDeclaredWeight(); }),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Goods description + consignee. These lived in a widget that was
              // never mounted, so neither could ever be filled in — receiver
              // SMS silently never fired even though createBooking sends both.
              TextField(
                controller: _goodsDescController,
                decoration: _svcFieldDecoration('Describe your goods (optional)'),
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text('Receiver details (optional)',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text("We'll text them when the parcel is on its way",
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _receiverNameController,
                      decoration: _svcFieldDecoration("Receiver's name"),
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _receiverPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _svcFieldDecoration('Phone'),
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ],
          const SizedBox(height: 16),
          _restrictedStrip(),
        ]),
        const SizedBox(height: 10),
      ],
      ),
    );
  }

  /// "Do not send restricted items — View List >" (design's yellow bar).
  Widget _restrictedStrip() {
    return InkWell(
      onTap: () => showProhibitedItemsSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF9C3),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            // The design's restricted-items artwork — a parcel with a red X —
            // ships as an asset. This drew a bare 📦 emoji, which renders in
            // whatever the device's emoji font is and carries none of the
            // "not allowed" meaning the strip is warning about.
            Image.asset('assets/not_available.png', width: 18, height: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Do not send restricted items',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 12.5, color: Colors.black87)),
            ),
            Text('View List ',
                style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1668E3))),
            const Icon(Icons.chevron_right,
                size: 16, color: Color(0xFF1668E3)),
          ],
        ),
      ),
    );
  }

  /// Shared decoration for the goods/receiver inputs in the goods block.
  InputDecoration _svcFieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
    );
  }

  Widget _svcSubTypeRow(String label, String code) {
    return InkWell(
      onTap: () => setState(() => _goodsSubType = code),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black54, width: 2),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  /// Keep the chosen service in the add-on selection so the server prices it.
  void _syncServiceAddon() {
    final codes = {'LDUNLD', 'LDING', 'UNLD'};
    for (final a in _addons) {
      if (codes.contains(a.code)) _selectedAddonIds.remove(a.id);
    }
    if (_serviceCode != null) {
      final match = _addons.where((a) => a.code == _serviceCode);
      if (match.isNotEmpty) {
        _selectedAddonIds.add(match.first.id);
      } else {
        // No such add-on in the catalog. Proceeding would LOOK booked but
        // never bill or record the service — and no partners would show up.
        // Deselect and say so instead of silently shipping a free promise.
        final label = _serviceLabel(_serviceCode!);
        _serviceCode = null;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "'$label' isn't available right now — try another service."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
    _refreshFare();
  }

  /// Lift counts for the job only when EVERY non-ground leg has one — the
  /// partner plans for the worst leg, so a single liftless floor means stairs.
  /// (The answers used to be collected and never mapped to what was sent.)
  void _syncLift() {
    final legs = <bool>[
      if (_pickupGround == false) _pickupLift == true,
      if (_dropGround == false) _dropLift == true,
    ];
    _isLiftAvailable = legs.isNotEmpty && legs.every((hasLift) => hasLift);
  }

  /// What the backend will bill for the chosen loading service.
  ///
  /// This multiplied the catalog price by the partner count unconditionally,
  /// which is only what the server does for a FIXED add-on. The real rule is
  /// `resolveAddonsForFare` (booking.controller.ts) feeding `calculateFare`
  /// (fare.service.ts), and it branches on the add-on's priceType:
  ///   FIXED (and any type not listed) → price × quantity, and quantity is the
  ///                                     partner count for the loading codes
  ///   PER_FLOOR                       → price × max(1, pickupFloor + dropFloor)
  ///   PER_KG                          → price × max(1, declared kg)
  ///   PERCENTAGE                      → tripValue × price / 100, where
  ///                                     tripValue = base + distance + time +
  ///                                     surge from the same quote
  ///
  /// Returns null when the figure cannot be derived from what we hold — a
  /// PERCENTAGE service before any quote has landed — so the strip hides
  /// rather than showing a number the bill would not match.
  double? get _selectedServiceAddonPrice {
    final code = _serviceCode;
    if (code == null) return null;
    for (final a in _addons) {
      if (a.code != code) continue;
      switch (a.priceType) {
        case 'PERCENTAGE':
          final quote = _fare;
          if (quote == null) return null;
          final tripValue = quote.baseFare +
              quote.distanceCharge +
              quote.timeCharge +
              quote.surgeCharge;
          return tripValue * a.price / 100;
        case 'PER_FLOOR':
          // The server floors/clamps what we send and never bills zero units.
          final floors = _pickupFloor + _dropFloor;
          return a.price * (floors < 1 ? 1 : floors);
        case 'PER_KG':
          // Mirrors the weight actually posted (_goodsWeightKg), not the
          // derived _declaredKg, since that is what the server prices on.
          return a.price * (_goodsWeightKg < 1 ? 1 : _goodsWeightKg);
        default:
          return a.price * _partnerCount;
      }
    }
    return null;
  }

  /// Quantity drives the declared weight, which drives the partner count the
  /// server bills on.
  void _syncDeclaredWeight() {
    _goodsWeightKg = _declaredKg;
    _refreshFare();
  }

  /// The design's "Service fare … / N Partner to load & unload" strip, shown
  /// above the footer. The amount is [_selectedServiceAddonPrice], i.e. the
  /// backend's own pricing rule for the chosen service.
  Widget _serviceFareStrip() {
    // Only the loading service's own line, not `_fare.addonCharges` — that
    // total also carries per-stop charges, Packing and Insurance, so adding
    // insurance used to inflate the "partners to load" price.
    final charge = _selectedServiceAddonPrice;
    if (!_serviceChosen || charge == null || charge <= 0) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF6F1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // The design's own artwork for this strip, and the exact asset the
          // Select Service screen already draws beside its identical
          // "Service fare … / N Partner to load & unload" copy. A generic
          // Material shipping glyph stood in for it here.
          Image.asset('assets/service_fare_icon.png', height: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Service fare: ${_money(charge)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 13.5, fontWeight: FontWeight.w700)),
                Text(
                  '$_partnerCount Partner${_partnerCount > 1 ? 's' : ''} to '
                  '${_serviceCode == 'LDING' ? 'load' : _serviceCode == 'UNLD' ? 'unload' : 'load & unload'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// One money format for the whole screen. The server quotes to the paisa
  /// (fareBreakdown is rounded to 2 dp), so the same amount used to appear as
  /// ₹1234, ₹1234.00 and a floored ₹1233 depending on which widget drew it.
  String _money(double v) => '₹${v.toStringAsFixed(2)}';

  Widget _fareRow(String title, String amount, {bool bold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Expanded: as a bare Row child the label got unbounded width, so an
        // interpolated title like 'Distance Charge (1234.5 km)' laid out at its
        // intrinsic width on one line and could never ellipsize. The amount
        // stays unflexed — it is short and must never be the thing that clips.
        Expanded(
          child: Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
        ),
        const SizedBox(width: 8),
        Text(amount, style: GoogleFonts.poppins(fontSize: 12, fontWeight: bold ? FontWeight.w600 : FontWeight.w400, color: color)),
      ],
    );
  }

  Widget _addonDropdownSection() {
    // Stacked cards with a +ADD toggle per the design — replaces the old
    // collapsible dropdown. Lists ONLY the extras; the loading services are
    // chosen in Select Service above.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Add-On Services'),
        const SizedBox(height: 10),
        for (final a in _extraAddons) ...[
          _addonDesignCard(a),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  /// Artwork for an add-on row.
  ///
  /// The card used to render `addon.icon` as raw TEXT, so it could only ever
  /// show an emoji — and the backend stores emoji ("🧾", "🧑‍🏭") or, for
  /// Loading/Unloading only, an empty string. The design shows illustrated
  /// icons, which already ship in assets/, so a code-keyed local fallback
  /// supplies them. A real image URL from the backend still wins, so uploading
  /// proper artwork through the admin panel takes over without a code change.
  Widget _addonIcon(AddonService addon) {
    final icon = addon.icon;

    if (icon.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          ApiUrls.imageProxyUrl(icon),
          width: 40,
          height: 40,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _addonAssetIcon(addon),
        ),
      );
    }
    if (icon.startsWith('assets/')) {
      return Image.asset(icon, width: 40, height: 40, fit: BoxFit.contain);
    }
    return _addonAssetIcon(addon);
  }

  /// The design's illustration for a known add-on, keyed by the addon CODE
  /// rather than its name — an admin can rename "Loading & unloading" without
  /// silently losing its icon. Anything unrecognised keeps the backend's emoji,
  /// and only falls back to a clipboard when there is nothing at all.
  Widget _addonAssetIcon(AddonService addon) {
    const byCode = <String, String>{
      'LDUNLD': 'assets/delivery_man.png',
      'LDING': 'assets/delivery_man.png',
      'UNLD': 'assets/delivery_man.png',
      'RECVCOPY': 'assets/copy.png',
      'PACKING': 'assets/boxes.png',
    };
    final asset = byCode[addon.code.toUpperCase()];
    if (asset != null) {
      return Image.asset(asset, width: 40, height: 40, fit: BoxFit.contain);
    }
    return Text(addon.icon.isNotEmpty ? addon.icon : '📋',
        style: const TextStyle(fontSize: 26));
  }

  Widget _addonDesignCard(AddonService addon) {
    final selected = _selectedAddonIds.contains(addon.id);
    final priceLabel = addon.priceType == 'PERCENTAGE'
        ? '${addon.price % 1 == 0 ? addon.price.toInt() : addon.price}% of trip value'
        : addon.price <= 0
            ? 'FREE'
            : 'Starts ₹${addon.price.toInt()}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 3,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: _addonIcon(addon)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(addon.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 14.5, fontWeight: FontWeight.w600)),
                if (addon.description.isNotEmpty)
                  Text(addon.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 11.5, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(priceLabel,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF16A34A))),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              setState(() {
                if (_loadingCodes.contains(addon.code)) {
                  // The three loading services are one choice, not a stack:
                  // route through _serviceCode + _syncServiceAddon so exactly
                  // one is ever selected. Opting IN opens the Load Assist
                  // page (the approved mock) to collect what the service
                  // needs; opting out just clears it.
                  _serviceCode = selected ? null : addon.code;
                  _syncServiceAddon();
                  if (_serviceCode != null) _step = 1;
                } else if (selected) {
                  _selectedAddonIds.remove(addon.id);
                } else {
                  _selectedAddonIds.add(addon.id);
                }
              });
              _refreshFare();
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? HexColor('#FF6200') : Colors.white,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: HexColor('#FF6200')),
              ),
              child: Text(selected ? 'ADDED' : '+ ADD',
                  style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color:
                          selected ? Colors.white : HexColor('#FF6200'))),
            ),
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
          // Real terms from FareConfig. These were hardcoded as "65 mins" and
          // "₹3.0/min" — contradicting the "Free 50 mins" chip on this same
          // screen, and both wrong: the server bills after ~10 mins at ₹2/min.
          // Pre-booking checklist (client spec): preparation pointers the
          // customer can act on, ahead of the fare terms.
          const Text(
            "• Ensure goods are packed properly before the driver arrives.",
            style: TextStyle(fontSize: 11),
          ),
          const SizedBox(height: 6),
          const Text(
            "• Be present at the pickup location, or share the contact of someone who will be.",
            style: TextStyle(fontSize: 11),
          ),
          const SizedBox(height: 6),
          const Text(
            "• Keep your phone reachable — the driver may call for directions.",
            style: TextStyle(fontSize: 11),
          ),
          const SizedBox(height: 6),
          if ((_fare?.freeWaitingMinutes ?? 0) > 0) ...[
            Text(
              "• Fare includes ${_fare!.freeWaitingMinutes} mins free loading/unloading time.",
              style: const TextStyle(fontSize: 11),
            ),
            const SizedBox(height: 6),
          ],
          if ((_fare?.waitingChargePerMin ?? 0) > 0) ...[
            Text(
              "• ₹${_fare!.waitingChargePerMin.toStringAsFixed(_fare!.waitingChargePerMin % 1 == 0 ? 0 : 2)}/min for additional loading/unloading time.",
              style: const TextStyle(fontSize: 11),
            ),
            const SizedBox(height: 6),
          ],
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

  // ─── Sticky bottom bar: Payment + Fare + Book button ───
  Widget _stickyBottomBar(String vehicleName) {
    final totalAmount = _fare?.finalFare ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // "Service fare: ₹288 / N Partner to load & unload" — sits directly
            // above the terms strip, as in the design.
            _serviceFareStrip(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
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
                      // The design puts one wallet illustration beside "Choose
                      // Payment Method" whatever the method is — the method
                      // itself is named in the label directly below — and
                      // ships it as an asset (the Select Service screen draws
                      // the same one under the same copy). This picked between
                      // three generic Material glyphs instead.
                      Image.asset('assets/credit_card.png',
                          width: 30, height: 30),
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
                    // Same figure, same format as the Fare Summary above and
                    // the breakup sheet behind View Breakup — this rounded to
                    // whole rupees while the summary showed paise, so the two
                    // totals on one screen could differ by up to ₹1.
                    Text(_money(totalAmount), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: _showFareBreakup,
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
                  // The design greys the CTA until the screen is ready.
                  disabledBackgroundColor: const Color(0xFFC9C9C9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                // Gate on real readiness, not just on the in-flight flag.
                // _onBookPressed returns early when _fare is null, so with a
                // failed fare this button rendered full orange and tappable and
                // then silently did nothing — the customer taps Book and the
                // app just sits there with no explanation.
                // Also gated on the Select Service flow being answered, which
                // is why the design shows Proceed greyed in the early states
                // and orange only once service, floors, goods and quantity
                // have all been filled in.
                // Step 0's Proceed advances to the review page; only step 1
                // actually creates the booking and takes payment.
                // On the Load Assist page, Proceed validates and returns to
                // review (the same _serviceFlowComplete gate covers it: with a
                // service chosen it requires the Load Assist answers + pickup
                // time). Only the review page's Proceed actually books.
                onPressed:
                    (_bookingInProgress || _fare == null || !_serviceFlowComplete)
                        ? null
                        : (_step == 1
                            ? () => setState(() => _step = 0)
                            : _onBookPressed),
                child: _bookingInProgress
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        // The design's label is "Proceed".
                        "Proceed",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white),
                      ),
              ),
            ),
                ],
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
    final stops = widget.bookingData.stops;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      // Addresses are user-entered and unbounded — a long one overflowed this
      // sheet, which had neither a scroll view nor room to grow past the
      // default half-screen cap. Same bug as View Breakup had; its siblings
      // were never checked.
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Padding(
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
            // Stops sit between pickup and drop, in visiting order — the fare
            // includes their per-stop charge, so the sheet must show them.
            for (final s in stops)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.orange.shade700, width: 2),
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
                        Text('Stop', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text((s['address'] ?? 'Stop').toString(), style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 3, overflow: TextOverflow.ellipsis),
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
          ),
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
      // The payment list grows with the methods offered and had no scroll and
      // no SafeArea, so the last tile sat under the gesture bar and the sheet
      // overflowed on short screens — with no way to reach the option.
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.8,
          ),
          child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
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
          ),
          ),
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
          currentCategory: _goodsCategory,
          onSelected: (GoodsType goods) {
            Navigator.pop(ctx);
            // Update the category the card shows AND the id the booking is
            // created with. This used to overwrite the goods *description* the
            // customer had typed and leave the category unchanged — so "Change"
            // destroyed their input and appeared to do nothing, while the
            // booking still carried the original goods type.
            setState(() {
              _goodsCategory = goods.name;
              widget.bookingData.goodsTypeId = goods.id;
              widget.bookingData.goodsCategory = goods.name;
              widget.bookingData.goodsTypeCategory = goods.category;
              // Keep the "Select type of goods" block in step — its
              // Business/Personal answer is this category's own.
              if (goods.category == 'BUSINESS' ||
                  goods.category == 'PERSONAL') {
                _goodsNature = goods.category;
              }
            });
            // If the new goods type restricts vehicles and excludes the one
            // already selected, the booking would pair goods with a vehicle
            // that can't carry them — send the user back to pick a valid one
            // (same rule DeliveryCategoryScreen applies).
            final vehicleId = widget.bookingData.selectedVehicle?.id;
            if (vehicleId != null &&
                goods.allowedVehicleTypeIds.isNotEmpty &&
                !goods.allowedVehicleTypeIds.contains(vehicleId)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${goods.name} needs a different vehicle — pick one that can carry it.'),
                  backgroundColor: Colors.orange,
                ),
              );
              pushTo(context,
                  VehicleSelectionScreen(bookingData: widget.bookingData));
            }
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
            // Expanded, so the Column is width-bounded and the caption below can
            // wrap. Without it the Row handed this child unbounded width, the
            // caption laid out on one line at its intrinsic width, and the card
            // overflowed to the right — worse at larger system font scales. The
            // `width: screenWidth - 110` magic number that used to be here left
            // ~8dp of slack and absorbed nothing.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text('Have a GST Number?',
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      Text('Add GSTIN', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: HexColor("#3268E4"))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Text('Get invoices with GSTIN for Input Tax Credit', style: GoogleFonts.poppins(fontSize: 9.3, color: Colors.black87)),
                  ),
                ],
              ),
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
                // Scrolls, so the content slides under the keyboard instead of
                // overflowing. isScrollControlled gives the sheet full height,
                // but the viewInsets padding above deflates it by the keyboard
                // the moment a field is focused — and this sheet exists purely
                // to type a GSTIN, so the keyboard is always up. Same shape as
                // _showFareBreakup; this one never got it.
                child: SingleChildScrollView(
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

  /// Reports the whole chosen GoodsType, not just its name. It used to hand
  /// back a bare name — so the caller had no id to send, and the backend
  /// silently fell back to "PERSONAL" no matter what the customer picked.
  final void Function(GoodsType goods) onSelected;

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
                                  cat.icon.startsWith('http')
                                      ? Image.network(
                                          ApiUrls.imageProxyUrl(cat.icon),
                                          width: 26,
                                          height: 26,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, _, _) =>
                                              const Text('📦',
                                                  style: TextStyle(
                                                      fontSize: 22)),
                                        )
                                      : Text(
                                          cat.icon.isNotEmpty
                                              ? cat.icon
                                              : '📦',
                                          style:
                                              const TextStyle(fontSize: 22)),
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
                      // Report the selected GoodsType itself so the caller has
                      // its id, not just its label.
                      onPressed: () {
                        final picked = _categories
                            .where((c) => c.name == _selectedName)
                            .firstOrNull;
                        if (picked != null) widget.onSelected(picked);
                      },
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

/// Thin dashed rule used under a collapsed "… Change" header, matching the
/// dotted separator in the design.
class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        const dash = 5.0, gap = 4.0;
        final count = (c.maxWidth / (dash + gap)).floor().clamp(0, 400);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => Container(
              width: dash,
              height: 1.2,
              color: const Color(0xFFD9D9D9),
            ),
          ),
        );
      },
    );
  }
}
