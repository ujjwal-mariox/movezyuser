import 'dart:async';
import 'package:flutter/material.dart';
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/CommonWidgets/button_widget.dart';
import 'package:movezy_user_app/CommonWidgets/cancel_booking_dialog.dart';
import 'package:movezy_user_app/Screens/CancelRideScreen/cancel_ride_screen.dart';
import 'package:movezy_user_app/Screens/TripDetailsScreen/trip_details_screen.dart';
import 'package:movezy_user_app/Screens/DashboardScreen/dashboard_screen.dart';
import 'package:movezy_user_app/Screens/RideCanceledSuccessScreen/ride_canceled_success_screen.dart';
import 'package:movezy_user_app/Services/booking_service.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class RideFindingScreen extends StatefulWidget {
  final String bookingId;
  final String bookingNumber;

  const RideFindingScreen({
    super.key,
    required this.bookingId,
    required this.bookingNumber,
  });

  @override
  State<RideFindingScreen> createState() => _RideFindingScreenState();
}

class _RideFindingScreenState extends State<RideFindingScreen>
    with SingleTickerProviderStateMixin {
  Timer? _pollTimer;
  bool _cancelled = false;
  String _statusText = 'Finding nearby drivers...';

  /// Status from the last /track poll. The cancel dialog's stage copy must
  /// state the stage we actually observed — '' before the first poll lands
  /// maps to the dialog's generic headline rather than an assumed stage.
  String _lastKnownStatus = '';
  late AnimationController _pulseController;

  // The real pickup, read off the booking we're already polling. This screen
  // used to fill the map area with a static PNG of four taxis and a baked-in
  // ETA — none of it real, while we were genuinely still searching.
  LatLng? _pickup;

  // ── Surfacing the "nobody took it" outcome ──
  //
  // Dispatch has two ways of giving up and NEITHER changes the booking status,
  // so polling /track alone can only ever report SEARCHING — which is why this
  // screen spun forever:
  //
  //  1. Drivers were rung and all 30s windows expired with no fresh driver left
  //     to try. booking-dispatch.service then emits `booking:no_drivers` to the
  //     customer's socket room and cleans up Redis. Nothing else is recorded.
  //  2. No eligible driver existed at all (the radius expansion from 5km to
  //     15km found nobody). dispatchBookingToDrivers returns early — no retry
  //     is scheduled and no event is ever emitted.
  //
  // So we listen for the event (case 1) AND fall back to our own elapsed-time
  // measurement (case 2). The booking itself stays discoverable in drivers'
  // available list either way (DISCOVERABLE_BOOKING_STATUSES includes
  // SEARCHING), so waiting on is a genuine option, not just stalling.
  IO.Socket? _socket;

  /// Verbatim message from the server's `booking:no_drivers`. Null until/unless
  /// the server actually says so — we never put words in its mouth.
  String? _serverNoDriversMessage;

  /// When the current wait began. Reset when the customer chooses to wait on,
  /// so it drives the notice cadence — NOT the elapsed time we quote.
  DateTime _waitingSince = DateTime.now();

  /// When the search genuinely started: the booking's own createdAt once the
  /// track call supplies it, else when this screen opened. Never reset, because
  /// "Keep waiting" restarting the count made the card understate the wait —
  /// it claimed 2 minutes on a search that had already run 4+.
  DateTime? _bookingCreatedAt;
  final DateTime _screenOpenedAt = DateTime.now();

  /// How long to wait before telling the customer nothing has happened yet.
  /// Dispatch's own driver-response window is 30s, so two minutes without an
  /// assignment means every ring that was going to happen already has.
  static const Duration _quietSearchNotice = Duration(minutes: 2);

  Timer? _noticeTimer;
  bool _noticeVisible = false;

  bool get _noticeDue =>
      _serverNoDriversMessage != null ||
      DateTime.now().difference(_waitingSince) >= _quietSearchNotice;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _startPolling();
    _connectSocket();
    _noticeTimer =
        Timer.periodic(const Duration(seconds: 10), (_) => _refreshNotice());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _noticeTimer?.cancel();
    _socket?.dispose();
    _socket = null;
    _pulseController.dispose();
    super.dispose();
  }

  /// The dispatch outcome only ever reaches the customer over the socket.
  /// Any authenticated socket is auto-joined to `user:<id>` server-side, so
  /// connecting with the token is all that's needed to receive it.
  void _connectSocket() {
    _socket = IO.io(
      ApiUrls.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': Prefs.token})
          // socket_io_client caches one socket per URL; other screens open
          // their own, so keep this connection independent of theirs.
          .enableForceNew()
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.on('booking:no_drivers', (data) {
      if (data is! Map) return;
      // The room is per-user, not per-booking, so make sure it's ours.
      if ((data['bookingId'] ?? '').toString() != widget.bookingId) return;
      if (!mounted) return;
      final msg = (data['message'] ?? '').toString().trim();
      setState(() {
        _serverNoDriversMessage =
            msg.isNotEmpty ? msg : 'No drivers are available right now.';
      });
      _refreshNotice();
    });
  }

  void _refreshNotice() {
    if (!mounted) return;
    final due = _noticeDue;
    if (due != _noticeVisible) setState(() => _noticeVisible = due);
  }

  /// Dismiss the notice and keep searching. The booking is still listed for
  /// nearby drivers, so this is a real option — nothing is re-requested here
  /// because the backend exposes no re-dispatch endpoint.
  void _keepWaiting() {
    setState(() {
      _serverNoDriversMessage = null;
      _waitingSince = DateTime.now();
      _noticeVisible = false;
    });
  }

  void _startPolling() {
    // Poll every 5 seconds for booking status updates
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkBookingStatus());
    // Also check immediately
    _checkBookingStatus();
  }

  Future<void> _checkBookingStatus() async {
    if (_cancelled || !mounted) return;
    try {
      final data = await BookingService.trackBooking(widget.bookingId);
      final booking = data['booking'];
      if (booking == null || !mounted) return;

      // Centre the map on where the driver is actually being sought.
      final lat = (booking['pickup']?['lat'] as num?)?.toDouble();
      final lng = (booking['pickup']?['lng'] as num?)?.toDouble();
      if (lat != null && lng != null && _pickup == null) {
        setState(() => _pickup = LatLng(lat, lng));
      }

      // True origin of the search, so the elapsed figure survives both
      // "Keep waiting" and a re-entry into this screen.
      if (_bookingCreatedAt == null && booking['createdAt'] != null) {
        final parsed = DateTime.tryParse('${booking['createdAt']}');
        if (parsed != null) _bookingCreatedAt = parsed.toLocal();
      }

      final status = (booking['status'] ?? '').toString();
      _lastKnownStatus = status;

      if (status == 'CANCELLED') {
        _cancelled = true;
        _pollTimer?.cancel();
        replaceRoute(context, DashboardScreen());
        return;
      }

      // Driver assigned or beyond → navigate to trip details
      if (['ASSIGNED', 'DRIVER_ARRIVED', 'PICKED', 'IN_PROGRESS'].contains(status)) {
        _cancelled = true; // Prevent further polls
        _pollTimer?.cancel();
        replaceRoute(
          context,
          TripDetailsScreen(bookingId: widget.bookingId),
        );
        return;
      }

      // Still searching
      if (mounted) {
        setState(() {
          _statusText = 'Finding nearby drivers...';
        });
      }
    } catch (e) {
      debugPrint('Polling error: $e');
    }
  }

  Future<void> _cancelBooking() async {
    // Pause polling while the confirm dialog / cancel screen is up. Otherwise
    // a poll landing mid-flow sees CANCELLED (or ASSIGNED) and
    // pushAndRemoveUntil's another screen over everything — tearing down the
    // dialog and throwing away the refund confirmation the customer is owed.
    _pollTimer?.cancel();

    final confirmed = await showCancelBookingConfirmDialog(
      context,
      bookingStatus: _lastKnownStatus,
      bookingId: widget.bookingId,
    );
    if (!mounted) return;
    if (!confirmed) {
      _startPolling(); // Changed their mind — carry on searching.
      return;
    }

    final result =
        await pushTo(context, CancelRideScreen(bookingId: widget.bookingId));
    if (!mounted) return;

    // CancelRideScreen pops the cancel API's payload (wasPaid, refundAmount,
    // …). This used to compare it against the string 'cancelled', which it has
    // not returned since the refund work landed — so the branch was dead and a
    // customer who cancelled here sat on the spinner until the next poll
    // happened to notice.
    if (result is Map) {
      _cancelled = true;
      replaceRoute(
        context,
        RideCanceledSuccessScreen(
          cancelResult: Map<String, dynamic>.from(result),
        ),
      );
      return;
    }

    // Backed out without cancelling — carry on searching.
    _startPolling();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          commonAppBar(
              height: 110,
              context: context,
              child: Container(
                padding: const EdgeInsets.only(top: 50),
                child: Row(
                  children: [
                    const SizedBox(width: 5),
                    InkWell(
                      onTap: () => safeBack(context),
                      child: Container(
                        padding: const EdgeInsets.only(left: 16),
                        width: 40,
                        height: 35,
                        alignment: Alignment.center,
                        child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      ),
                    ),
                    Text(
                      "Trip #${widget.bookingNumber}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )),
          Expanded(
            child: Stack(
              children: [
                // Real map of the pickup we're searching around. Until the
                // first poll lands we show plain neutral ground rather than a
                // picture of drivers who don't exist.
                Positioned.fill(
                  child: _pickup == null
                      ? Container(color: const Color(0xFFE8EAED))
                      : FlutterMap(
                          options: MapOptions(
                            initialCenter: _pickup!,
                            initialZoom: 15,
                            // Purely informational while we search.
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName:
                                  'com.example.movezy_user_app',
                            ),
                            // Pulsing search radius around the real pickup.
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, _) => CircleLayer(
                                circles: [
                                  CircleMarker(
                                    point: _pickup!,
                                    radius: 60 + _pulseController.value * 40,
                                    color: HexColor("#FF6200")
                                        .withOpacity(0.12),
                                    borderColor: HexColor("#FF6200")
                                        .withOpacity(0.45),
                                    borderStrokeWidth: 1.5,
                                  ),
                                ],
                              ),
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _pickup!,
                                  width: 40,
                                  height: 40,
                                  child: Icon(Icons.location_on,
                                      color: HexColor("#FF6200"), size: 40),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),

                // Status overlay — the live search, or the outcome once the
                // search has stopped producing anything.
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: _noticeVisible ? _noDriverCard() : _searchingCard(),
                ),

                // Cancel button
                Positioned(
                  // 20 is the design's gap; the device's real bottom inset
                  // (gesture bar / nav buttons) is added so the button isn't
                  // partly underneath the system UI.
                  bottom: 20 + MediaQuery.of(context).padding.bottom,
                  left: 20,
                  right: 20,
                  child: SizedBox(
                    height: 50,
                    width: MediaQuery.of(context).size.width - 40,
                    child: ButtonWidget(
                      backgroundColor: HexColor("FFFFFF"),
                      height: 50,
                      border: Border.all(color: HexColor('#CFCECE'), width: 1.5),
                      textStyle: TextStyle(color: HexColor("000000"), fontSize: 14),
                      text: "Cancel Booking",
                      onTap: _cancelBooking,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  Widget _searchingCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: _cardDecoration,
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: HexColor("#FF6200")
                      .withOpacity(0.5 + _pulseController.value * 0.5),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Booking #${widget.bookingNumber}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: HexColor("#FF6200"),
            ),
          ),
        ],
      ),
    );
  }

  /// What the customer sees once the search has stopped going anywhere.
  ///
  /// The headline is the server's own sentence when the server gave us one;
  /// otherwise it states only what we can measure ourselves — how long we have
  /// been waiting — rather than asserting a dispatch result we were never told.
  Widget _noDriverCard() {
    final serverMessage = _serverNoDriversMessage;
    final waitedMinutes = DateTime.now()
        .difference(_bookingCreatedAt ?? _screenOpenedAt)
        .inMinutes;
    final headline = serverMessage ??
        'No driver has accepted yet — we have been searching for '
            '$waitedMinutes ${waitedMinutes == 1 ? 'minute' : 'minutes'}.';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 20, color: HexColor("#FF6200")),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      // True of a SEARCHING booking: it stays in the drivers'
                      // available list, so someone coming online can still take
                      // it. Cancelling lets them rebook — a different vehicle
                      // type is matched against a different pool of drivers.
                      'Your booking is still listed for drivers nearby, so you '
                      'can keep waiting. Or cancel it and book again.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Booking #${widget.bookingNumber}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _keepWaiting,
              child: Text(
                'Keep waiting',
                style: TextStyle(
                  color: HexColor("#FF6200"),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
