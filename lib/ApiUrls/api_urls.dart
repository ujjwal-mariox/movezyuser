
class ApiUrls {
  // Physical device → local backend on this PC's LAN IP (phone on same WiFi)
  static String baseUrlApi = "http://192.168.1.34:9050/v1/api";
  // Production API endpoint - Movezy backend
  // static String baseUrlApi = "https://movize-backend.maidkart.in/v1/api";
  // Local development (Android emulator): 10.0.2.2 maps to host machine localhost
  // static String baseUrlApi = "http://10.0.2.2:9050/v1/api";

  static String loginUrl = "$baseUrlApi/auth/login";

  static String otpUrlVerify = "$baseUrlApi/auth/verifyOtp";

  static String userProfileUrl = "$baseUrlApi/user/profile";

  static String userAddressUrl = "$baseUrlApi/user/address";

  static String homeUrl = "$baseUrlApi/home";

  static String gstUrl = "$baseUrlApi/user/gst";

  // Real nearby online drivers for the home map (append ?lat=&lng=).
  static String nearbyDriversUrl = "$baseUrlApi/tracking/nearby-drivers";

  // ─── COINS ───
  static String coinsBalanceUrl = "$baseUrlApi/coins/balance";

  // ─── SUPPORT ───
  static String supportTicketsUrl = "$baseUrlApi/support/tickets";

  // ─── CHAT ───
  // Real-time chat with the driver over Socket.io + REST history/upload.
  // Socket.io is attached to the same server (no /v1/api path).
  static String socketUrl = "http://192.168.1.34:9050";
  static String chatHistoryUrl(String bookingId) => "$baseUrlApi/chat/$bookingId/history";
  static String chatUploadImageUrl(String bookingId) => "$baseUrlApi/chat/$bookingId/upload-image";

  // ─── WALLET & PAYMENTS ───
  static String walletUrl = "$baseUrlApi/wallet";
  static String walletTransactionsUrl = "$baseUrlApi/wallet/transactions";
  static String walletRechargeOrderUrl = "$baseUrlApi/payments/wallet/recharge";
  static String walletRechargeVerifyUrl = "$baseUrlApi/payments/wallet/verify";
  // Online booking payment (create Razorpay order + verify signature server-side)
  static String bookingPaymentOrderUrl(String bookingId) =>
      "$baseUrlApi/payments/booking/$bookingId/order";
  static String bookingPaymentVerifyUrl(String bookingId) =>
      "$baseUrlApi/payments/booking/$bookingId/verify";

  /// Razorpay key – load from environment or use test key as fallback
  /// For production, set RAZORPAY_KEY environment variable with live key
  static String razorpayKeyId = const String.fromEnvironment('RAZORPAY_KEY', defaultValue: 'rzp_test_SEYGtmd4CbElON');

  /// Proxies an external image URL through the backend so the emulator can load it.
  static String imageProxyUrl(String imageUrl) {
    return "$baseUrlApi/home/image-proxy?url=${Uri.encodeComponent(imageUrl)}";
  }

  // ─── BOOKING & CATEGORIES ───
  static String goodsTypesUrl = "$baseUrlApi/bookings/goods-types";
  static String addonServicesUrl = "$baseUrlApi/bookings/addons/list";
  static String vehicleOptionsUrl = "$baseUrlApi/bookings/vehicle-options";
  static String fareEstimateUrl = "$baseUrlApi/bookings/fare-estimate";
  static String createBookingUrl = "$baseUrlApi/bookings";
  static String userBookingsUrl = "$baseUrlApi/bookings";

  // ─── BOOKING ACTIONS ───
  static String bookingDetailUrl(String bookingId) => "$baseUrlApi/bookings/$bookingId";
  static String bookingTrackUrl(String bookingId) => "$baseUrlApi/bookings/$bookingId/track";
  static String bookingCancelUrl(String bookingId) => "$baseUrlApi/bookings/$bookingId/cancel";
  static String bookingInvoiceUrl(String bookingId) => "$baseUrlApi/bookings/$bookingId/invoice";
  static String bookingRateUrl(String bookingId) => "$baseUrlApi/bookings/$bookingId/rate";
  static String cancellationReasonsUrl = "$baseUrlApi/bookings/cancellation-reasons";
  static String prohibitedItemsUrl = "$baseUrlApi/bookings/prohibited-items";
  static String timeSlotsUrl = "$baseUrlApi/bookings/time-slots";

  // ─── PROMOS ───
  static String availablePromosUrl = "$baseUrlApi/promos/available";
  static String validatePromoUrl = "$baseUrlApi/promos/validate";

  // ─── ENTERPRISE ───
  static String enterpriseContentUrl = "$baseUrlApi/enterprise/content";
  static String enterpriseInquiryUrl = "$baseUrlApi/enterprise/inquiry";

  // ─── REFERRAL ───
  static String referralCodeUrl = "$baseUrlApi/user/referral";
  static String referralApplyUrl = "$baseUrlApi/user/referral/apply";
  static String referralStatsUrl = "$baseUrlApi/user/referral/stats";
}
