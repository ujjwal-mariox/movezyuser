import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';

// ─── MODELS ───

class GoodsType {
  final String id;
  final String name;
  final String code;
  final String category;
  final String icon;
  final String description;
  final List<String> allowedVehicleTypeIds;
  final bool isActive;
  final int sortOrder;

  GoodsType({
    required this.id,
    required this.name,
    required this.code,
    required this.category,
    required this.icon,
    required this.description,
    required this.allowedVehicleTypeIds,
    required this.isActive,
    required this.sortOrder,
  });

  factory GoodsType.fromJson(Map<String, dynamic> json) {
    List<String> vtIds = [];
    if (json['allowedVehicleTypes'] != null) {
      for (var vt in json['allowedVehicleTypes']) {
        if (vt is String) {
          vtIds.add(vt);
        } else if (vt is Map) {
          vtIds.add(vt['_id'] ?? '');
        }
      }
    }
    return GoodsType(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      category: json['category'] ?? 'PERSONAL',
      icon: json['icon'] ?? '📦',
      description: json['description'] ?? '',
      allowedVehicleTypeIds: vtIds,
      isActive: json['isActive'] ?? true,
      sortOrder: json['sortOrder'] ?? 0,
    );
  }
}

class AddonService {
  final String id;
  final String name;
  final String code;
  final String description;
  final String icon;
  final String priceType; // FIXED, PER_FLOOR, PER_KG
  final double price;
  final bool isActive;
  final int sortOrder;

  /// Admin targeting: empty = offered for every goods category.
  final List<String> applicableGoodsCategories;

  /// Admin auto-apply: preselect this add-on when the fare qualifies. The
  /// customer still sees the charge on the review page and can untick it —
  /// nothing is added silently.
  final bool autoApply;
  final double autoApplyMinFare;

  AddonService({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.icon,
    required this.priceType,
    required this.price,
    required this.isActive,
    required this.sortOrder,
    this.applicableGoodsCategories = const [],
    this.autoApply = false,
    this.autoApplyMinFare = 0,
  });

  factory AddonService.fromJson(Map<String, dynamic> json) {
    return AddonService(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '🔧',
      priceType: json['priceType'] ?? 'FIXED',
      price: (json['price'] ?? 0).toDouble(),
      isActive: json['isActive'] ?? true,
      sortOrder: json['sortOrder'] ?? 0,
      applicableGoodsCategories: (json['applicableGoodsCategories'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      autoApply: json['autoApply'] == true,
      autoApplyMinFare: (json['autoApplyMinFare'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ProhibitedItem {
  final String id;
  final String name;
  final String icon;
  final String image;
  final String bgColor;
  final String description;
  final int sortOrder;

  ProhibitedItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.image,
    required this.bgColor,
    required this.description,
    required this.sortOrder,
  });

  factory ProhibitedItem.fromJson(Map<String, dynamic> json) {
    return ProhibitedItem(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
      image: json['image'] ?? '',
      bgColor: json['bgColor'] ?? '#FFF3E0',
      description: json['description'] ?? '',
      sortOrder: json['sortOrder'] ?? 0,
    );
  }
}

class VehicleOption {
  final String vehicleTypeId;
  final String name;
  final String? description;
  final String? image;
  final String? icon;
  final double maxWeightKg;
  final double lengthFt;
  final double breadthFt;
  final double heightFt;
  final double baseFare;
  final double estimatedFare;
  final double distanceKm;
  final int estimatedDuration;
  final bool allowIntraCity;
  final bool allowInterCity;
  final int sortOrder;
  final bool isRecommended;
  final double score;

  /// Strikethrough pricing from the server's admin-managed discount campaigns.
  /// Null when no discount applies; the ORIGINAL price stays in estimatedFare,
  /// so a build that predates these fields simply shows the undiscounted fare
  /// and the bill (which applies the same discount server-side) comes in
  /// lower, never higher.
  final double? discountedFare;
  final double? discountPercent;

  VehicleOption({
    required this.vehicleTypeId,
    required this.name,
    this.description,
    this.image,
    this.icon,
    required this.maxWeightKg,
    this.lengthFt = 0,
    this.breadthFt = 0,
    this.heightFt = 0,
    required this.baseFare,
    required this.estimatedFare,
    required this.distanceKm,
    required this.estimatedDuration,
    this.allowIntraCity = true,
    this.allowInterCity = false,
    this.sortOrder = 0,
    this.isRecommended = false,
    this.score = 0,
    this.discountedFare,
    this.discountPercent,
  });

  factory VehicleOption.fromJson(Map<String, dynamic> json) {
    final vt = json['vehicleType'] ?? {};
    return VehicleOption(
      vehicleTypeId: vt['_id'] ?? '',
      name: vt['name'] ?? '',
      description: vt['description'],
      image: vt['image'],
      icon: vt['icon'],
      maxWeightKg: (vt['maxWeightKg'] ?? 0).toDouble(),
      lengthFt: (vt['lengthFt'] ?? 0).toDouble(),
      breadthFt: (vt['breadthFt'] ?? 0).toDouble(),
      heightFt: (vt['heightFt'] ?? 0).toDouble(),
      baseFare: (vt['baseFare'] ?? 0).toDouble(),
      estimatedFare: (json['fare'] ?? 0).toDouble(),
      distanceKm: (json['distanceKm'] ?? 0).toDouble(),
      estimatedDuration: (json['estimatedDuration'] ?? 0).toInt(),
      allowIntraCity: vt['allowIntraCity'] ?? true,
      allowInterCity: vt['allowInterCity'] ?? false,
      sortOrder: vt['sortOrder'] ?? 0,
      isRecommended: json['isRecommended'] ?? false,
      score: (json['score'] ?? 0).toDouble(),
      discountedFare: (json['discountedFare'] as num?)?.toDouble(),
      discountPercent: (json['discountPercent'] as num?)?.toDouble(),
    );
  }

  String get capacityLabel {
    if (maxWeightKg >= 1000) {
      return "${(maxWeightKg / 1000).toStringAsFixed(1)} Ton";
    }
    return "${maxWeightKg.toInt()} Kg";
  }

  String get dimensionsLabel {
    if (lengthFt > 0 && breadthFt > 0 && heightFt > 0) {
      return "${lengthFt.toStringAsFixed(0)}×${breadthFt.toStringAsFixed(0)}×${heightFt.toStringAsFixed(0)} ft";
    }
    return '';
  }

  String get durationLabel {
    if (estimatedDuration >= 60) {
      final hours = estimatedDuration ~/ 60;
      final mins = estimatedDuration % 60;
      return mins > 0 ? "$hours hr $mins mins" : "$hours hr";
    }
    return "$estimatedDuration mins";
  }
}

class FareEstimate {
  final double baseFare;
  final double distanceCharge;
  final double timeCharge;
  final double surgeCharge;
  final double addonCharges;
  final double stopCharges;
  final double loadingUnloadingCharge;
  final double tollCharges;
  final double gst;
  final double totalFare;
  final double discount;
  final double finalFare;
  final double distanceKm;
  final double durationMin;

  /// Real free-loading terms from FareConfig — the same values the server bills
  /// from. The app used to hardcode these (and contradicted itself: "50 mins"
  /// and "65 mins" on one screen, "60 minutes" in the terms) while the server
  /// actually bills after ~10 minutes.
  final int freeWaitingMinutes;
  final double waitingChargePerMin;

  /// Coins this trip earns, from the same service that credits them. The app
  /// used to derive `fare / 100` itself and promised half the real rate.
  final int coinsToEarn;

  FareEstimate({
    required this.baseFare,
    required this.distanceCharge,
    required this.timeCharge,
    required this.surgeCharge,
    required this.addonCharges,
    required this.stopCharges,
    required this.loadingUnloadingCharge,
    required this.tollCharges,
    required this.gst,
    required this.totalFare,
    required this.discount,
    required this.finalFare,
    required this.distanceKm,
    required this.durationMin,
    this.freeWaitingMinutes = 0,
    this.waitingChargePerMin = 0,
    this.coinsToEarn = 0,
  });

  factory FareEstimate.fromJson(Map<String, dynamic> json) {
    final fare = json['fareBreakdown'] ?? json;
    // The estimate applies the promo AFTER building fareBreakdown, so its
    // totalDiscount is present-but-0 there and the real figure is the
    // top-level promoDiscount. `??` doesn't fall through on 0, so prefer
    // whichever is non-zero — or View Breakup never shows the discount row.
    final breakdownDiscount =
        (fare['totalDiscount'] ?? fare['discount'] ?? 0).toDouble();
    final topLevelDiscount = (json['promoDiscount'] ?? 0).toDouble();
    return FareEstimate(
      baseFare: (fare['baseFare'] ?? 0).toDouble(),
      distanceCharge: (fare['distanceCharge'] ?? 0).toDouble(),
      timeCharge: (fare['timeCharge'] ?? 0).toDouble(),
      surgeCharge: (fare['surgeCharge'] ?? 0).toDouble(),
      addonCharges: (fare['addonCharges'] ?? 0).toDouble(),
      stopCharges: (fare['stopCharges'] ?? 0).toDouble(),
      loadingUnloadingCharge: (fare['loadingUnloadingCharge'] ?? 0).toDouble(),
      tollCharges: (fare['tollCharges'] ?? 0).toDouble(),
      gst: (fare['gstAmount'] ?? fare['gst'] ?? json['gst'] ?? 0).toDouble(),
      totalFare: (fare['subtotal'] ?? fare['totalFare'] ?? json['totalFare'] ?? 0).toDouble(),
      discount:
          breakdownDiscount > 0 ? breakdownDiscount : topLevelDiscount,
      finalFare: (json['finalAmount'] ?? json['finalFare'] ?? fare['finalFare'] ?? 0).toDouble(),
      distanceKm: (json['distanceKm'] ?? fare['distanceKm'] ?? 0).toDouble(),
      durationMin: (json['durationMin'] ?? fare['durationMin'] ?? 0).toDouble(),
      freeWaitingMinutes:
          (fare['freeWaitingMinutes'] ?? json['freeWaitingMinutes'] ?? 0)
              .toInt(),
      coinsToEarn: (json['coinsToEarn'] as num?)?.toInt() ?? 0,
      waitingChargePerMin:
          (fare['waitingChargePerMin'] ?? json['waitingChargePerMin'] ?? 0)
              .toDouble(),
    );
  }
}

class PromoOffer {
  final String id;
  final String code;
  final String description;
  final String discountType;
  final double discountValue;
  final double? maxDiscount;
  final double minOrderValue;
  final String validFrom;
  final String validTo;

  PromoOffer({
    required this.id,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.maxDiscount,
    required this.minOrderValue,
    required this.validFrom,
    required this.validTo,
  });

  factory PromoOffer.fromJson(Map<String, dynamic> json) {
    return PromoOffer(
      id: json['_id'] ?? json['id'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      discountType: json['discountType'] ?? 'PERCENTAGE',
      discountValue: (json['discountValue'] ?? 0).toDouble(),
      maxDiscount: json['maxDiscount'] != null ? (json['maxDiscount']).toDouble() : null,
      minOrderValue: (json['minOrderValue'] ?? 0).toDouble(),
      validFrom: json['validFrom'] ?? json['startDate'] ?? '',
      validTo: json['validTo'] ?? json['expiresAt'] ?? json['endDate'] ?? '',
    );
  }

  String get displayText {
    if (discountType == 'PERCENTAGE') {
      final maxStr = maxDiscount != null ? ' (max ₹${maxDiscount!.toInt()})' : '';
      return '${discountValue.toInt()}% OFF$maxStr';
    }
    return '₹${discountValue.toInt()} OFF';
  }
}

// ─── SERVICE ───

class BookingService {
  static Map<String, String> _headers() {
    final token = Prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Fetch delivery categories (goods types) from backend
  static Future<List<GoodsType>> getGoodsTypes() async {
    final headers = _headers();
    final url = ApiUrls.goodsTypesUrl;
    final res = await http.get(
      Uri.parse(url),
      headers: headers,
    ).timeout(const Duration(seconds: 30));
    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      final rawData = body['data'];
      final list = rawData is List
          ? rawData
          : (rawData?['goodsTypes'] ?? body['goodsTypes'] ?? []);
      return (list as List).map((e) => GoodsType.fromJson(e)).toList();
    }
    throw Exception('Failed to load categories: ${res.statusCode}');
  }

  /// Fetch add-on services from backend
  static Future<List<AddonService>> getAddonServices() async {
    final url = ApiUrls.addonServicesUrl;
    final res = await http.get(
      Uri.parse(url),
      headers: _headers(),
    ).timeout(const Duration(seconds: 30));
    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      final rawData = body['data'];
      final list = rawData is List
          ? rawData
          : (rawData?['addonServices'] ?? body['addonServices'] ?? []);
      return (list as List).map((e) => AddonService.fromJson(e)).toList();
    }
    throw Exception('Failed to load add-ons: ${res.statusCode}');
  }

  /// Fetch prohibited items from backend
  static Future<List<ProhibitedItem>> getProhibitedItems() async {
    final url = ApiUrls.prohibitedItemsUrl;
    final res = await http.get(
      Uri.parse(url),
      headers: _headers(),
    ).timeout(const Duration(seconds: 30));
    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      final rawData = body['data'];
      final list = rawData is List
          ? rawData
          : (rawData?['items'] ?? body['items'] ?? []);
      return (list as List).map((e) => ProhibitedItem.fromJson(e)).toList();
    }
    throw Exception('Failed to load prohibited items: ${res.statusCode}');
  }

  /// Get vehicle options with fare estimates and recommendations
  static Future<List<VehicleOption>> getVehicleOptions({
    required Map<String, dynamic> pickup,
    required Map<String, dynamic> drop,
    String? serviceType,
    String? goodsTypeId,
    /// Intermediate stops. Without these the prices on this screen leave out
    /// both the detour distance and the per-stop charge, so the fare jumps on
    /// the next screen.
    List<Map<String, dynamic>>? stops,
  }) async {
    final body = {
      'pickup': pickup,
      'drop': drop,
      if (stops != null && stops.isNotEmpty) 'stops': stops,
      if (serviceType != null) 'serviceType': serviceType,
      if (goodsTypeId != null) 'goodsTypeId': goodsTypeId,
    };

    final res = await http.post(
      Uri.parse(ApiUrls.vehicleOptionsUrl),
      headers: _headers(),
      body: json.encode(body),
    ).timeout(const Duration(seconds: 30));

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final list = data['data'] as List? ?? [];
      return list.map((item) => VehicleOption.fromJson(item)).toList();
    }
    throw Exception('Failed to get vehicle options: ${res.statusCode}');
  }

  /// Get fare estimate from backend
  static Future<FareEstimate> getFareEstimate({
    required Map<String, dynamic> pickup,
    required Map<String, dynamic> drop,
    required String vehicleTypeId,
    String? serviceType,
    List<Map<String, dynamic>>? addons,
    String? promoCode,
    List<Map<String, dynamic>>? stops,
    // Floors are sent as data, never as a price. The server prices PER_FLOOR
    // add-ons from these and ignores any charge the client tries to send.
    int? pickupFloor,
    int? dropFloor,
    bool? isLiftAvailable,
    /// Declared load in kg. PER_KG add-ons are priced from this; without it the
    /// server can only bill a single flat unit.
    int? goodsWeight,
  }) async {
    final body = {
      'pickup': pickup,
      'drop': drop,
      if (goodsWeight != null && goodsWeight > 0) 'goodsWeight': goodsWeight,
      'vehicleTypeId': vehicleTypeId,
      'serviceType': serviceType ?? 'WITHIN_CITY',
      if (addons != null && addons.isNotEmpty) 'addons': addons,
      if (promoCode != null) 'promoCode': promoCode,
      if (stops != null && stops.isNotEmpty) 'stops': stops,
      'loadingUnloading': {
        'pickupFloor': pickupFloor ?? 0,
        'dropFloor': dropFloor ?? 0,
        'isLiftAvailable': isLiftAvailable ?? false,
      },
    };

    final res = await http.post(
      Uri.parse(ApiUrls.fareEstimateUrl),
      headers: _headers(),
      body: json.encode(body),
    ).timeout(const Duration(seconds: 30));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return FareEstimate.fromJson(data['data'] ?? data);
    }
    throw Exception('Failed to get fare estimate: ${res.statusCode}');
  }

  /// Create a booking
  static Future<Map<String, dynamic>> createBooking({
    required Map<String, dynamic> pickup,
    required Map<String, dynamic> drop,
    required String vehicleTypeId,
    required String goodsType,
    required String paymentMethod,
    // The backend prices the trip from these, so they must be the real quoted
    // metrics. Required rather than defaulted: a fallback here silently books
    // (and charges for) a trip nobody took.
    required double distanceKm,
    required double durationMin,
    List<Map<String, dynamic>>? addons,
    String? promoCode,
    String? goodsDescription,
    String? serviceType,
    List<Map<String, dynamic>>? stops,
    // Consignee (who receives the parcel). Optional — when a phone is given the
    // backend SMSs them at pickup, since they aren't an app user.
    String? receiverName,
    String? receiverPhone,
    // Scheduled pickup. When set, the backend creates the booking as DRAFT and
    // the scheduled-dispatch job sends it to drivers near the pickup time.
    String? scheduledDate,
    String? scheduledTimeSlotId,
    // Declared floors — the server prices PER_FLOOR add-ons from these. Must
    // match what was quoted, or the customer is charged a different figure to
    // the one they agreed to.
    int? pickupFloor,
    int? dropFloor,
    bool? isLiftAvailable,
    /// Must match the weight the quote was priced on.
    int? goodsWeight,
    /// Number of packages declared on the quantity steppers. Stored by the
    /// backend and shown to the driver, but nothing ever sent it.
    int? goodsQuantity,
  }) async {
    final body = {
      'pickupLocation': { 'lat': pickup['lat'], 'lng': pickup['lng'] },
      'pickupAddress': pickup['address'] ?? 'Pickup Location',
      'dropLocation': { 'lat': drop['lat'], 'lng': drop['lng'] },
      'dropAddress': drop['address'] ?? 'Drop Location',
      'vehicleTypeId': vehicleTypeId,
      'goodsType': goodsType,
      'paymentMethod': paymentMethod,
      'distanceKm': distanceKm,
      'durationMin': durationMin,
      'loadingUnloading': {
        'pickupFloor': pickupFloor ?? 0,
        'dropFloor': dropFloor ?? 0,
        'isLiftAvailable': isLiftAvailable ?? false,
      },
      if (goodsWeight != null && goodsWeight > 0) 'goodsWeight': goodsWeight,
      if (goodsQuantity != null && goodsQuantity > 0)
        'goodsQuantity': goodsQuantity,
      if (serviceType != null) 'serviceType': serviceType,
      if (addons != null && addons.isNotEmpty) 'addons': addons,
      if (promoCode != null) 'promoCode': promoCode,
      if (goodsDescription != null) 'goodsDescription': goodsDescription,
      if (stops != null && stops.isNotEmpty) 'stops': stops,
      if (receiverName != null && receiverName.trim().isNotEmpty)
        'receiverName': receiverName.trim(),
      if (receiverPhone != null && receiverPhone.trim().isNotEmpty)
        'receiverPhone': receiverPhone.trim(),
      if (scheduledDate != null) 'scheduledDate': scheduledDate,
      if (scheduledTimeSlotId != null)
        'scheduledTimeSlotId': scheduledTimeSlotId,
    };

    final res = await http.post(
      Uri.parse(ApiUrls.createBookingUrl),
      headers: _headers(),
      body: json.encode(body),
    ).timeout(const Duration(seconds: 30));
    final data = json.decode(res.body);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return data;
    }
    throw Exception(data['message'] ?? 'Failed to create booking');
  }

  /// Get available promo codes
  static Future<List<PromoOffer>> getAvailablePromos() async {
    final res = await http.get(
      Uri.parse(ApiUrls.availablePromosUrl),
      headers: _headers(),
    ).timeout(const Duration(seconds: 30));
    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      final rawData = body['data'];
      final list = rawData is List
          ? rawData
          : (rawData?['promos'] ?? body['promos'] ?? []);
      return (list as List).map((e) => PromoOffer.fromJson(e)).toList();
    }
    return []; // Don't crash if promos fail
  }

  /// Validate a promo code. Backend expects `amount` (not orderAmount) and
  /// optionally vehicleTypeId/serviceType for eligibility checks.
  static Future<Map<String, dynamic>> validatePromo(
    String code,
    double orderAmount, {
    String? vehicleTypeId,
    String? serviceType,
  }) async {
    final res = await http.post(
      Uri.parse(ApiUrls.validatePromoUrl),
      headers: _headers(),
      body: json.encode({
        'code': code,
        'amount': orderAmount,
        if (vehicleTypeId != null) 'vehicleTypeId': vehicleTypeId,
        if (serviceType != null) 'serviceType': serviceType,
      }),
    ).timeout(const Duration(seconds: 30));
    return json.decode(res.body);
  }

  /// Get booking detail by ID
  static Future<Map<String, dynamic>> getBookingById(String bookingId) async {
    final res = await http.get(
      Uri.parse(ApiUrls.bookingDetailUrl(bookingId)),
      headers: _headers(),
    ).timeout(const Duration(seconds: 30));
    final data = json.decode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['data'];
    }
    throw Exception(data['message'] ?? 'Failed to fetch booking');
  }

  /// Create a Razorpay order for an online booking payment.
  /// Returns { orderId, amount, currency, bookingNumber }.
  static Future<Map<String, dynamic>> createPaymentOrder(String bookingId) async {
    final res = await http.post(
      Uri.parse(ApiUrls.bookingPaymentOrderUrl(bookingId)),
      headers: _headers(),
    ).timeout(const Duration(seconds: 30));
    final data = json.decode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to create payment order');
  }

  /// Pickup time slots available on [date] (defaults to today).
  ///
  /// The backend filters out slots that are already past (or inside the minimum
  /// notice window) and refuses dates beyond the advance-booking limit, so an
  /// empty list genuinely means "nothing bookable that day".
  static Future<List<TimeSlotOption>> getTimeSlots({DateTime? date}) async {
    final q = date != null
        ? '?date=${date.toIso8601String().split('T').first}'
        : '';
    try {
      final res = await http
          .get(Uri.parse('${ApiUrls.timeSlotsUrl}$q'), headers: _headers())
          .timeout(const Duration(seconds: 20));
      final data = json.decode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        final list = (data['data'] as List?) ?? [];
        return list
            .map((e) => TimeSlotOption.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {
      // Scheduling is optional — a failure here must not block booking now.
    }
    return [];
  }

  /// Pay for a booking from the wallet balance. The backend debits the wallet
  /// and marks the booking PAID; returns (ok, message). Nothing is charged
  /// unless this succeeds — the booking must not be treated as paid otherwise.
  static Future<(bool, String)> payWithWallet(String bookingId) async {
    try {
      final res = await http.post(
        Uri.parse(ApiUrls.bookingWalletPayUrl(bookingId)),
        headers: _headers(),
      ).timeout(const Duration(seconds: 30));
      final data = json.decode(res.body);
      final ok = res.statusCode == 200 && data['success'] == true;
      return (ok, (data['message'] ?? '').toString());
    } catch (e) {
      return (false, 'Wallet payment failed: $e');
    }
  }

  /// Verify an online booking payment server-side (HMAC signature check).
  /// Returns true only if the backend confirms the payment.
  static Future<bool> verifyBookingPayment({
    required String bookingId,
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final res = await http.post(
      Uri.parse(ApiUrls.bookingPaymentVerifyUrl(bookingId)),
      headers: _headers(),
      body: json.encode({
        'orderId': orderId,
        'paymentId': paymentId,
        'signature': signature,
      }),
    ).timeout(const Duration(seconds: 30));
    final data = json.decode(res.body);
    return res.statusCode == 200 && data['success'] == true;
  }

  /// Track booking (polls for status, driver location, ETA)
  static Future<Map<String, dynamic>> trackBooking(String bookingId) async {
    final res = await http.get(
      Uri.parse(ApiUrls.bookingTrackUrl(bookingId)),
      headers: _headers(),
    ).timeout(const Duration(seconds: 15));
    final data = json.decode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['data'];
    }
    throw Exception(data['message'] ?? 'Failed to track booking');
  }

  /// Cancel a booking
  /// What cancelling right now would refund, WITHOUT cancelling.
  ///
  /// The refund percentages are admin-configurable and stage-dependent, so the
  /// app must ask rather than state a number of its own. Returns null when the
  /// preview can't be loaded — callers then warn generically instead of
  /// inventing a figure.
  static Future<Map<String, dynamic>?> cancellationPreview(String bookingId) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiUrls.baseUrlApi}/bookings/$bookingId/cancellation-preview'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      final data = json.decode(res.body);
      if (data is Map && data['success'] == true && data['data'] is Map) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> cancelBooking(String bookingId, {String? cancellationReasonId}) async {
    final body = <String, dynamic>{};
    if (cancellationReasonId != null) {
      body['cancellationReasonId'] = cancellationReasonId;
    }
    final res = await http.post(
      Uri.parse(ApiUrls.bookingCancelUrl(bookingId)),
      headers: _headers(),
      body: json.encode(body),
    ).timeout(const Duration(seconds: 30));
    final data = json.decode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    }
    throw Exception(data['message'] ?? 'Failed to cancel booking');
  }

  /// Add an intermediate stop to a booking that is already under way.
  ///
  /// The server re-routes pickup → stops → drop, re-prices the trip and returns
  /// the delta, so no price is ever sent from here. Returns the `data` object:
  /// { stops, distanceKm, durationMin, previousFare, finalFare, fareDifference,
  ///   payableNow, message }. Throws with the backend's own sentence so the
  ///   caller can show a rejection verbatim rather than paraphrasing it.
  static Future<Map<String, dynamic>> addBookingStop(
    String bookingId, {
    required String address,
    required double lat,
    required double lng,
    String? contactName,
    String? contactPhone,
  }) async {
    final res = await http.post(
      Uri.parse(ApiUrls.bookingAddStopUrl(bookingId)),
      headers: _headers(),
      body: json.encode({
        'address': address,
        'lat': lat,
        'lng': lng,
        if (contactName != null && contactName.trim().isNotEmpty)
          'contactName': contactName.trim(),
        if (contactPhone != null && contactPhone.trim().isNotEmpty)
          'contactPhone': contactPhone.trim(),
      }),
    ).timeout(const Duration(seconds: 30));
    final data = json.decode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    }
    throw Exception(data['message'] ?? 'Failed to add stop');
  }

  /// Get cancellation reasons from backend
  static Future<List<CancellationReason>> getCancellationReasons() async {
    final res = await http.get(
      Uri.parse(ApiUrls.cancellationReasonsUrl),
      headers: _headers(),
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      final rawData = body['data'];
      final list = rawData is List ? rawData : [];
      return list.map((e) => CancellationReason.fromJson(e)).toList();
    }
    return [];
  }

  /// Get booking invoice
  static Future<Map<String, dynamic>> getInvoice(String bookingId) async {
    final res = await http.get(
      Uri.parse(ApiUrls.bookingInvoiceUrl(bookingId)),
      headers: _headers(),
    ).timeout(const Duration(seconds: 30));
    final data = json.decode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['data'];
    }
    throw Exception(data['message'] ?? 'Failed to fetch invoice');
  }

  /// Rate a booking
  static Future<void> rateBooking(String bookingId, {
    required int rating,
    String? review,
    List<String>? feedback,
    String? comment,
  }) async {
    final body = <String, dynamic>{'rating': rating};
    if (review != null) body['review'] = review;
    if (feedback != null && feedback.isNotEmpty) body['feedback'] = feedback;
    if (comment != null && comment.isNotEmpty) body['comment'] = comment;
    final res = await http.post(
      Uri.parse(ApiUrls.bookingRateUrl(bookingId)),
      headers: _headers(),
      body: json.encode(body),
    ).timeout(const Duration(seconds: 30));
    final data = json.decode(res.body);
    if (res.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to submit rating');
    }
  }
}

/// Model for cancellation reasons from backend
class CancellationReason {
  final String id;
  final String reason;
  final int refundPercentage;
  final int sortOrder;

  CancellationReason({
    required this.id,
    required this.reason,
    required this.refundPercentage,
    required this.sortOrder,
  });

  factory CancellationReason.fromJson(Map<String, dynamic> json) {
    return CancellationReason(
      id: json['_id'] ?? json['id'] ?? '',
      reason: json['reason'] ?? json['text'] ?? '',
      refundPercentage: json['refundPercentage'] ?? 100,
      sortOrder: json['sortOrder'] ?? 0,
    );
  }
}

/// A bookable pickup slot, as returned by /bookings/time-slots.
class TimeSlotOption {
  final String id;
  final String label; // "2:00 PM"
  final String startTime; // "14:00"
  /// Absolute instant for this slot on the requested date — the backend
  /// resolves it so the client never has to reassemble "HH:mm" + a date.
  final DateTime? scheduledAt;

  TimeSlotOption({
    required this.id,
    required this.label,
    required this.startTime,
    this.scheduledAt,
  });

  factory TimeSlotOption.fromJson(Map<String, dynamic> j) => TimeSlotOption(
        id: (j['_id'] ?? '').toString(),
        label: (j['label'] ?? '').toString(),
        startTime: (j['startTime'] ?? '').toString(),
        scheduledAt: DateTime.tryParse((j['scheduledAt'] ?? '').toString()),
      );
}
