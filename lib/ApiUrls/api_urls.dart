
class ApiUrls {
  /// Backend origin, chosen at BUILD time.
  ///
  /// This used to be a hand-edited constant with the other environments
  /// commented out beneath it — so whichever line was uncommented when someone
  /// hit build is what shipped, and a local-testing URL in a release APK is a
  /// dead app on every device that isn't tethered to that machine.
  ///
  /// Production is the default: a plain `flutter build apk` is always safe.
  /// For local work pass the override:
  ///   flutter run --dart-define=API_ORIGIN=http://127.0.0.1:9050
  static const String _origin = String.fromEnvironment(
    'API_ORIGIN',
    defaultValue: 'https://movezybackend.onrender.com',
  );

  static String baseUrlApi = "$_origin/v1/api";

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
  // Coins — the backend has always implemented transfers and history; the app
  // showed "coming soon" over finished endpoints.
  static String coinsTransactionsUrl = "$baseUrlApi/coins/transactions";
  static String coinsConfigUrl = "$baseUrlApi/coins/config";
  static String coinsTransferToWalletUrl = "$baseUrlApi/coins/transfer-to-wallet";
  static String coinsBankTransferUrl = "$baseUrlApi/coins/bank-transfer";

  static String supportTicketsUrl = "$baseUrlApi/support/tickets";
  // Read a ticket thread and reply to it. The app could raise tickets but had no
  // way to read the answer, so every complaint was a one-way dead end.
  static String supportTicketDetailUrl(String ticketId) =>
      "$baseUrlApi/support/tickets/$ticketId";
  static String supportTicketReplyUrl(String ticketId) =>
      "$baseUrlApi/support/tickets/$ticketId/messages";
  static String supportTicketCloseUrl(String ticketId) =>
      "$baseUrlApi/support/tickets/$ticketId/close";
  static String supportFaqsUrl(String category) =>
      "$baseUrlApi/support/faqs?category=$category";
  /// Every active FAQ, ungrouped — the Help screen derives its categories
  /// from this so admin-created categories appear without an app release.
  static String supportAllFaqsUrl = "$baseUrlApi/support/faqs";
  static String supportFaqFeedbackUrl(String faqId) =>
      "$baseUrlApi/support/faqs/$faqId/feedback";

  // ─── CHAT ───
  // Real-time chat with the driver over Socket.io + REST history/upload.
  // Socket.io is attached to the same server (no /v1/api path).
  /// Socket.io origin — same host as the API, no /v1/api suffix.
  static String socketUrl = _origin;
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
  // Pay for a booking from the wallet balance (server debits + marks PAID).
  static String bookingWalletPayUrl(String bookingId) =>
      "$baseUrlApi/payments/booking/$bookingId/wallet";

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
  // Add an intermediate stop to a booking that is already under way. The server
  // re-routes and re-prices the trip, so this is the only way to change a live
  // booking's stops — the app previously had no route to it at all.
  static String bookingAddStopUrl(String bookingId) => "$baseUrlApi/bookings/$bookingId/stops";
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
