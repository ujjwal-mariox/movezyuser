import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:latlong2/latlong.dart';
import 'package:movezy_user_app/Services/routing_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/Screens/TripDetailsScreen/live_tracking_map_screen.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/CommonWidgets/booking_terms_sheet.dart';
import 'package:movezy_user_app/CommonWidgets/order_status_timeline.dart';
import 'package:movezy_user_app/Screens/BookingDetailsScreen/booking_details_screen.dart';
import 'package:movezy_user_app/Screens/ChatScreen/chat_screen.dart';
import 'package:movezy_user_app/Screens/HelpSupportScreen/help_support_screen.dart';
import 'package:movezy_user_app/Screens/MapPickerScreen/map_picker_screen.dart';
import 'package:movezy_user_app/Screens/DeliveryCompleteScreen/delivery_complete_screen.dart';
import 'package:movezy_user_app/Screens/RideCanceledSuccessScreen/ride_canceled_success_screen.dart';
import 'package:movezy_user_app/Services/booking_service.dart';
import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class TripDetailsScreen extends StatefulWidget {
  final String bookingId;
  const TripDetailsScreen({super.key, required this.bookingId});
  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  bool _loading = true;
  // True while the add-stop request is in flight, so the row can't be tapped
  // twice — a duplicate stop would be re-priced and charged for.
  bool _addingStop = false;
  Timer? _pollTimer;

  // Booking data from API
  String _bookingNumber = '';
  String _status = '';
  String _driverName = '';
  /// The assigned driver's number, for the call button. trackBooking populates
  /// driverId with mobileNumber, but nothing on this screen ever read it, so
  /// the customer had no way to phone the driver.
  String _driverPhone = '';
  String _vehicleName = '';
  // The booked vehicle's real image. This card always drew a motorbike, so a
  // customer who booked a truck watched a bike come to collect it.
  String _vehicleImage = '';

  String _vehicleNumber = '';
  /// Road geometry pickup → drop for the mini map; empty until fetched.
  List<LatLng> _roadRoute = const [];
  String _pickupAddress = '';
  String _pickupContactName = '';
  String _dropContactName = '';
  String _pickupContact = '';
  String _dropAddress = '';

  /// Intermediate drops (address/lat/lng/contact + completedAt), in delivery
  /// order — refreshed by the 10s poll so ticks appear as the driver delivers.
  List<Map<String, dynamic>> _stops = [];
  String _dropContact = '';
  String _paymentMethod = 'CASH';
  double _finalFare = 0;

  /// Estimated duration of the WHOLE trip — pickup → stops → drop — in minutes,
  /// as routed and priced by the server (`booking.durationMin`).
  ///
  /// It is NOT how long until the driver reaches the pickup. `booking.
  /// estimatedArrivalTime` is declared in the schema but nothing in the backend
  /// ever writes it, so `/track`'s `eta` always falls through to `durationMin`.
  /// The header used to print this as a big "N mins" directly above "Driver on
  /// the way to pickup", which read as an arrival ETA the server never produced.
  int _tripDurationMin = 0;
  String _otp = '';
  String _deliveryOtp = '';
  int _coinsEarned = 0;
  bool _downloadingInvoice = false;

  // Fare breakdown components (from booking priceDetails)
  double _baseFare = 0;
  double _distanceFare = 0;
  double _addonsTotal = 0;
  double _taxAmount = 0;
  double _discountAmount = 0;

  // Waiting at pickup. The server measures driverArrivedAt → pickedAt when the
  // driver verifies the pickup OTP, bills the part past the free allowance, and
  // rolls it into subtotal/GST/finalFare (driver.controller verifyPickupOtp).
  // Both fields stay 0 until then. The fare simply grew mid-trip with nothing
  // on this screen naming the increase.
  double _waitingCharge = 0;
  int _waitingMinutes = 0;
  String _paymentStatus = '';

  // Delay communication. Only the drop leg has a real baseline to measure
  // against (pickedAt + the routed trip duration) — see _buildDelayBanner.
  DateTime? _pickedAt;

  // ── Live tracking ──
  // Route + driver position for the map. The screen used to show a static
  // route illustration, so the customer could never watch the driver move.
  LatLng? _pickupLatLng;
  LatLng? _dropLatLng;
  LatLng? _driverLatLng;
  String _driverId = '';
  IO.Socket? _socket;
  bool _trackingJoined = false;
  // Broadcast so the full-screen map can follow the driver off the same socket.
  final StreamController<LatLng> _driverPos = StreamController<LatLng>.broadcast();

  @override
  void initState() {
    super.initState();
    _fetchBooking();
    _startPolling();
    _connectTrackingSocket();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    if (_driverId.isNotEmpty) {
      _socket?.emit('booking:track:stop', {
        'bookingId': widget.bookingId,
        'driverId': _driverId,
      });
    }
    _socket?.dispose();
    _socket = null;
    _driverPos.close();
    super.dispose();
  }

  /// Subscribe to the driver's live location.
  ///
  /// The backend relays driver pings to `tracking:driver:<driverId>`, which a
  /// client joins by emitting `booking:track:start`. Nothing in either app ever
  /// emitted it, so the relay had no listeners and tracking was dead end-to-end.
  void _connectTrackingSocket() {
    _socket = IO.io(
      ApiUrls.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': Prefs.token})
          // forceNew: socket_io_client caches per URL and the chat screen opens
          // its own socket; without this they'd collide and tear each other down.
          .enableForceNew()
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      // Re-join on every (re)connect — room membership is lost on reconnect.
      _trackingJoined = false;
      _joinTrackingRoom();
    });

    _socket!.on('driver:location', (data) {
      if (data is! Map) return;
      final lat = data['lat'] ?? data['latitude'];
      final lng = data['lng'] ?? data['longitude'];
      if (lat is! num || lng is! num || !mounted) return;
      final pos = LatLng(lat.toDouble(), lng.toDouble());
      setState(() => _driverLatLng = pos);
      if (!_driverPos.isClosed) _driverPos.add(pos);
    });
  }

  /// Small live route preview. Taps through to the full-screen tracking map.
  ///
  /// Falls back to the illustration only when the booking genuinely has no
  /// coordinates — better an honest placeholder than a fake map.
  Widget _buildMiniMap() {
    final size = MediaQuery.of(context).size.width * 0.31;
    final pts = [_pickupLatLng, _dropLatLng, _driverLatLng]
        .whereType<LatLng>()
        .toList();

    if (pts.isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: Image.asset("assets/route_icon.png", fit: BoxFit.fill),
      );
    }

    return GestureDetector(
      onTap: _openFullMap,
      child: SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              // Non-interactive: the card is a preview; taps open the full map.
              FlutterMap(
                options: MapOptions(
                  initialCenter: _driverLatLng ?? _pickupLatLng ?? pts.first,
                  initialZoom: 12,
                  interactionOptions:
                      const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.movezy_user_app',
                  ),
                  if (_pickupLatLng != null && _dropLatLng != null)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          // Real road route once loaded; the straight line
                          // until then so the preview is never empty.
                          points: _roadRoute.isNotEmpty
                              ? _roadRoute
                              : [_pickupLatLng!, _dropLatLng!],
                          strokeWidth: 2,
                          color: HexColor("#FF6200"),
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      for (final p in pts)
                        Marker(
                          point: p,
                          width: 12,
                          height: 12,
                          child: Container(
                            decoration: BoxDecoration(
                              color: p == _driverLatLng
                                  ? HexColor("#FF6200")
                                  : (p == _pickupLatLng
                                      ? HexColor("#2E9E5B")
                                      : HexColor("#EE3E35")),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              // Affordance: make it obvious this opens something.
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.fullscreen,
                      size: 13, color: HexColor("#FF6200")),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFullMap() {
    pushTo(
      context,
      LiveTrackingMapScreen(
        pickup: _pickupLatLng,
        drop: _dropLatLng,
        driver: _driverLatLng,
        pickupAddress: _pickupAddress,
        dropAddress: _dropAddress,
        driverName: _driverName,
        statusLabel: _statusLabel,
        driverStream: _driverPos.stream,
      ),
    );
  }

  /// Coordinates arrive as num or numeric string depending on the endpoint.
  LatLng? _toLatLng(dynamic lat, dynamic lng) {
    double? d(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    final a = d(lat);
    final b = d(lng);
    if (a == null || b == null) return null;
    if (a == 0 && b == 0) return null; // unset coords, not a real location
    return LatLng(a, b);
  }

  /// Join once a driver is actually assigned (the room is keyed on driverId).
  void _joinTrackingRoom() {
    if (_trackingJoined || _driverId.isEmpty) return;
    final s = _socket;
    if (s == null || !s.connected) return;
    s.emit('booking:track:start', {
      'bookingId': widget.bookingId,
      'driverId': _driverId,
    });
    _trackingJoined = true;
  }

  void _startPolling() {
    _pollTimer =
        Timer.periodic(const Duration(seconds: 10), (_) => _fetchBooking());
  }

  Future<void> _fetchBooking() async {
    try {
      final data = await BookingService.trackBooking(widget.bookingId);
      final booking = data['booking'];
      if (booking == null || !mounted) return;

      final status = booking['status'] ?? '';

      if (status == 'COMPLETED' || status == 'CANCELLED') {
        _pollTimer?.cancel();
      }

      if (status == 'CANCELLED' && mounted) {
        replaceRoute(context, const RideCanceledSuccessScreen());
        return;
      }

      final pickup = booking['pickup'] ?? {};
      final drop = booking['drop'] ?? {};
      final driver = booking['driverId'];
      final vehicleType = booking['vehicleTypeId'];

      if (status == 'COMPLETED' && mounted) {
        replaceRoute(
          context,
          DeliveryCompleteScreen(
            bookingId: widget.bookingId,
            bookingNumber: booking['bookingNumber'] ?? '',
            driverName: driver is Map ? (driver['fullName'] ?? driver['name'] ?? 'Driver') : 'Driver',
            vehicleName: vehicleType is Map ? (vehicleType['name'] ?? 'Vehicle') : 'Vehicle',
            fare: (booking['finalFare'] ?? booking['fare'] ?? 0).toDouble(),
            coinsEarned: (booking['coinsEarned'] ?? 0).toInt(),
          ),
        );
        return;
      }

      setState(() {
        _bookingNumber = booking['bookingNumber'] ?? '';
        _status = status;
        _driverName =
            driver is Map ? (driver['fullName'] ?? driver['name'] ?? 'Driver') : 'Driver';
        _driverPhone = driver is Map
            ? (driver['mobileNumber'] ?? driver['phone'] ?? '').toString()
            : '';
        _vehicleName =
            vehicleType is Map ? (vehicleType['name'] ?? 'Vehicle') : 'Vehicle';
        _vehicleImage =
            vehicleType is Map ? (vehicleType['image'] ?? '') as String : '';
        _vehicleNumber = booking['vehicleNumber'] ?? '';
        _pickupAddress = pickup['address'] ?? 'Pickup';
        _pickupContact = pickup['contactPhone'] ?? '';
        _pickupContactName = pickup['contactName'] ?? '';
        _dropAddress = drop['address'] ?? 'Drop';
        _dropContact = drop['contactPhone'] ?? '';
        _dropContactName = drop['contactName'] ?? '';
        _stops = [
          if (booking['stops'] is List)
            for (final st in booking['stops'] as List)
              if (st is Map) Map<String, dynamic>.from(st),
        ];
        _paymentMethod = booking['paymentMethod'] ?? 'CASH';

        // Route coordinates for the live map.
        _pickupLatLng = _toLatLng(pickup['lat'], pickup['lng']);
        _dropLatLng = _toLatLng(drop['lat'], drop['lng']);
        _loadRoadRoute();
        _driverId = driver is Map ? (driver['_id'] ?? '').toString() : '';

        // Seed the driver marker from the REST payload so the map isn't empty
        // before the first socket ping arrives.
        final dl = data['driverLocation'];
        if (dl is Map) {
          final seeded = _toLatLng(
            dl['lat'] ?? dl['latitude'],
            dl['lng'] ?? dl['longitude'],
          );
          if (seeded != null) _driverLatLng = seeded;
        }
        _finalFare =
            (booking['finalFare'] ?? booking['fare'] ?? 0).toDouble();

        // Fare breakdown — tolerate different backend shapes. Note the fallback
        // is the booking itself, so every key below can hit a real booking field:
        // `addons` there is a LIST, and coercing it threw
        // "List<dynamic> has no instance method 'toDouble'", which aborted this
        // whole fetch (and with it the OTP). num2 therefore only accepts nums.
        final price = (booking['priceDetails'] is Map)
            ? booking['priceDetails'] as Map
            : (booking['fareBreakup'] is Map ? booking['fareBreakup'] as Map : booking);
        double num2(dynamic v) {
          if (v is num) return v.toDouble();
          if (v is String) return double.tryParse(v) ?? 0;
          return 0;
        }
        // Names below match booking.model: addonTotal (not addonCharges),
        // gstAmount (not gst), totalDiscount (not discount — that one is
        // deprecated and always 0, which is why GST/discount showed as zero).
        _baseFare = num2(price['baseFare'] ?? price['base']);
        _distanceFare = num2(price['distanceCharge'] ??
            price['distanceFare'] ?? price['distance']);
        _addonsTotal = num2(price['addonTotal'] ??
            price['addonCharges'] ?? price['addonsTotal']);
        _taxAmount = num2(
            price['gstAmount'] ?? price['gst'] ?? price['taxAmount'] ?? price['tax']);
        _discountAmount = num2(price['totalDiscount'] ??
            price['discount'] ?? price['discountAmount']);
        // waitingCharge / waitingMinutes live on the booking root; `price`
        // falls back to the booking itself, so try both rather than depending
        // on which shape we landed on.
        _waitingCharge =
            num2(price['waitingCharge'] ?? booking['waitingCharge']);
        _waitingMinutes =
            num2(price['waitingMinutes'] ?? booking['waitingMinutes']).round();
        _paymentStatus = (booking['paymentStatus'] ?? '').toString();

        // Read the routed trip duration by its own name rather than through
        // `eta`, which is ambiguous (estimatedArrivalTime || durationMin) and
        // in practice is always durationMin because nothing sets the former.
        _tripDurationMin = num2(booking['durationMin'] ?? data['eta']).round();
        _otp = booking['otp'] ?? '';
        _deliveryOtp = booking['deliveryOtp'] ?? '';
        _coinsEarned = (booking['coinsEarned'] ?? 0).toInt();

        // Delay communication data
        if (booking['pickedAt'] != null) {
          _pickedAt = DateTime.tryParse(booking['pickedAt'].toString());
        }

        _loading = false;
      });

      // The tracking room is keyed on driverId, which only exists once a driver
      // is assigned — so join here rather than on connect.
      _joinTrackingRoom();
    } catch (e) {
      debugPrint('TripDetails fetch error: $e');
      if (mounted && _loading) setState(() => _loading = false);
    }
  }

  // ── Delay Communication Banner ──
  /// The pickup OTP the customer reads out to the driver.
  ///
  /// Shown until pickup is verified — including while still SEARCHING, so the
  /// customer can note it before the driver arrives. Hidden from PICKED onward,
  /// where it has already been used. Deliberately prominent: it used to render
  /// as a small unlabelled pill beside the booking ID that customers missed.
  Widget _buildOtpCard() {
    const beforePickup = ['SEARCHING', 'ASSIGNED', 'DRIVER_ARRIVED'];
    if (_otp.isEmpty || !beforePickup.contains(_status)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HexColor("#A2BF49"), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: HexColor("#A2BF49").withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.lock_outline, size: 20, color: HexColor("#A2BF49")),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Share this OTP with your driver",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  "They'll enter it to start the pickup",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _otp,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
              color: HexColor("#A2BF49"),
            ),
          ),
        ],
      ),
    );
  }

  /// The delivery OTP the receiver reads out to the driver at the drop.
  /// Shown from pickup onward (before that the pickup OTP card has the stage),
  /// and hidden once the trip is completed. Bookings created before the field
  /// existed have none — nothing renders and completion is not gated for them.
  Widget _buildDeliveryOtpCard() {
    const inTransit = ['PICKED', 'IN_PROGRESS'];
    if (_deliveryOtp.isEmpty || !inTransit.contains(_status)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HexColor("#FF6200"), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: HexColor("#FF6200").withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Icon(Icons.inventory_2_outlined, size: 20, color: HexColor("#FF6200")),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Delivery OTP — share with the receiver",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  "The driver enters it at the drop to complete delivery",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _deliveryOtp,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
              color: HexColor("#FF6200"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDelayBanner() {
    // Calculate if there's a significant delay
    int delayMinutes = 0;
    String delayMessage = '';

    final now = DateTime.now();

    // Only the drop leg is measurable. There used to be an ASSIGNED branch that
    // treated `assignedAt + trip duration` as the expected pickup arrival and
    // reported the overrun as "Your driver is running ~N min late" — but the
    // trip duration says nothing about how long the driver takes to REACH the
    // pickup, so that figure was invented. The backend publishes no
    // driver-arrival estimate, so no honest pickup-delay number exists.
    if ((_status == 'PICKED' || _status == 'IN_PROGRESS') &&
        _pickedAt != null &&
        _tripDurationMin > 0) {
      // En route to drop — check if past expected delivery
      final expectedDelivery =
          _pickedAt!.add(Duration(minutes: _tripDurationMin));
      if (now.isAfter(expectedDelivery)) {
        delayMinutes = now.difference(expectedDelivery).inMinutes;
        delayMessage = 'Your delivery is running ~$delayMinutes min behind schedule. Hang tight!';
      }
    }

    if (delayMinutes < 5) return const SizedBox(height: 16);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule, color: Colors.orange.shade700, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delay Detected',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    delayMessage,
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade900, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fetch the real road geometry for the mini map. Runs once; failure just
  /// leaves the straight-line fallback in place.
  Future<void> _loadRoadRoute() async {
    final from = _pickupLatLng;
    final to = _dropLatLng;
    if (from == null || to == null || _roadRoute.isNotEmpty) return;
    // Through the stops in order — the trip visits them, so the drawn route
    // should too, not jump pickup→drop as if they didn't exist.
    final waypoints = <LatLng>[
      from,
      for (final st in _stops)
        if (st['lat'] is num &&
            st['lng'] is num &&
            (st['lat'] as num) != 0 &&
            (st['lng'] as num) != 0)
          LatLng((st['lat'] as num).toDouble(), (st['lng'] as num).toDouble()),
      to,
    ];
    final points = <LatLng>[];
    for (var i = 0; i < waypoints.length - 1; i++) {
      points.addAll(await RoutingService.route(waypoints[i], waypoints[i + 1]));
    }
    if (mounted && points.length > 2) setState(() => _roadRoute = points);
  }

  /// Headline in the ETA card.
  ///
  /// Still reads OrderStatusTimeline's status→words table even though this
  /// screen no longer draws the stepper (the design has none): BookingDetails
  /// does draw it, and when this screen kept its own copy of the wording the
  /// two once described DRIVER_ARRIVED with contradicting sentences.
  String get _statusLabel => OrderStatusTimeline.labelFor(_status);

  String get _paymentLabel {
    switch (_paymentMethod) {
      case 'WALLET':
        return 'Wallet';
      case 'ONLINE':
      case 'UPI':
      case 'CARD':
        return 'Online';
      default:
        return 'Cash';
    }
  }

  /// A real driver is on the job. While SEARCHING the payload has no driver and
  /// the name falls back to the literal "Driver", which is nobody to chat or
  /// talk to — so both contact buttons hang off this.
  bool get _hasDriver => _driverName.isNotEmpty && _driverName != 'Driver';

  /// The server only accepts a new stop once a driver is assigned and before
  /// the trip ends, and caps it at 3. Mirrored here so the control is hidden
  /// rather than shown and then rejected.
  bool get _canAddStop =>
      const ['ASSIGNED', 'DRIVER_ARRIVED', 'PICKED', 'IN_PROGRESS']
          .contains(_status) &&
      _stops.length < 3;

  /// Dial the assigned driver.
  Future<void> _callDriver() async {
    if (_driverPhone.isEmpty) return;
    try {
      // No canLaunchUrl gate: on Android 11+ it answers false unless the app
      // declares a `tel` <queries> intent, which would hide a dialer that
      // actually opens. launchUrl reports the real outcome instead.
      final opened = await launchUrl(Uri(scheme: 'tel', path: _driverPhone));
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open the dialer. Driver: $_driverPhone')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open the dialer. Driver: $_driverPhone')),
        );
      }
    }
  }

  /// Add an intermediate stop to the trip that is already running.
  ///
  /// The endpoint has no dry run, so the customer is warned that the fare will
  /// change before anything is committed, and is shown the actual difference
  /// the server came back with afterwards. No price is ever sent from here.
  Future<void> _addStop() async {
    if (_addingStop) return;

    // Reuse the app's existing picker — it already returns a resolved address
    // plus coordinates, and refuses to hand back its own placeholder text.
    // No initialLocation on purpose: that path centres on the customer and
    // reverse-geocodes it, so the address is real before they ever pan. Seeding
    // it with the drop would pre-fill the stop with the drop's own address.
    final picked = await Navigator.push<MapPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => const MapPickerScreen(title: 'Add Stop'),
      ),
    );
    if (picked == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add this stop?',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(picked.address,
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.35)),
            const SizedBox(height: 12),
            Text(
              'Your driver will detour through this stop, so the fare will '
              'change. Movezy calculates the new amount once the stop is '
              'added, and any difference is collected in cash at delivery.',
              style: TextStyle(
                  fontSize: 12.5, height: 1.45, color: Colors.grey.shade700),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey.shade700)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Add Stop',
                style: TextStyle(
                    color: AppColors.appColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _addingStop = true);
    try {
      final data = await BookingService.addBookingStop(
        widget.bookingId,
        address: picked.address,
        lat: picked.lat,
        lng: picked.lng,
      );
      if (!mounted) return;

      // The route now has an extra waypoint, so drop the cached geometry and
      // let the refresh below redraw it through the new stop.
      _roadRoute = const [];
      await _fetchBooking();
      if (!mounted) return;

      final diff = (data['fareDifference'] as num?)?.toDouble() ?? 0;
      final newFare = (data['finalFare'] as num?)?.toDouble() ?? 0;
      final payableNow = data['payableNow'] == true;
      final serverMessage = (data['message'] ?? '').toString().trim();

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Stop added',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Only state figures the server actually returned.
              if (diff != 0)
                Text(
                  diff > 0
                      ? 'Fare increased by ₹${diff.toStringAsFixed(0)}'
                      : 'Fare reduced by ₹${diff.abs().toStringAsFixed(0)}',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.appColor),
                ),
              if (newFare > 0) ...[
                const SizedBox(height: 4),
                Text('New total: ₹${newFare.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ],
              if (serverMessage.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(serverMessage,
                    style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: Colors.grey.shade700)),
              ] else if (payableNow) ...[
                const SizedBox(height: 10),
                Text('Please pay the difference in cash at delivery.',
                    style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: Colors.grey.shade700)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('OK',
                  style: TextStyle(
                      color: AppColors.appColor, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        // The backend explains exactly why it refused — repeat it verbatim
        // instead of guessing at a friendlier reason.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _addingStop = false);
    }
  }

  /// Whether the waiting charge is actually part of [_finalFare].
  ///
  /// The server records `waitingCharge` on the booking whenever the driver
  /// waited past the free allowance, but verifyPickupOtp only folds it into
  /// subtotal/GST/finalFare when the booking was not already PAID — a prepaid
  /// fare is left untouched. While a trip is still running, the only bookings
  /// already marked PAID are prepaid ones: a CASH booking is marked PAID by
  /// collectCashPayment, which requires status COMPLETED, and this screen has
  /// left for the delivery-complete screen by then. So billing it as a line
  /// item for a PAID booking would name money that was never added.
  bool get _waitingBilled => _waitingCharge > 0 && _paymentStatus != 'PAID';

  /// Show a fare breakdown bottom sheet built from the booking's price details.
  void _showFareBreakup() {
    // Any components we couldn't parse are folded into "Other charges" so the
    // rows always add up to the amount actually payable.
    final knownSum = _baseFare +
        _distanceFare +
        _addonsTotal +
        (_waitingBilled ? _waitingCharge : 0) +
        _taxAmount -
        _discountAmount;
    final other = (_finalFare - knownSum);

    Widget row(String label, String value,
            {Color? color, bool bold = false, String? note}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Expanded so a label carrying an explanatory note can wrap
              // instead of shoving the amount off the sheet.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: bold ? 15 : 13,
                            color: color ?? Colors.black87,
                            fontWeight:
                                bold ? FontWeight.w700 : FontWeight.w500)),
                    if (note != null) ...[
                      const SizedBox(height: 3),
                      Text(note,
                          style: TextStyle(
                              fontSize: 11,
                              height: 1.35,
                              color: Colors.grey.shade600)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(value,
                  style: TextStyle(
                      fontSize: bold ? 15 : 13,
                      color: color ?? Colors.black87,
                      fontWeight: bold ? FontWeight.w700 : FontWeight.w600)),
            ],
          ),
        );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text("Fare Breakup",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (_baseFare > 0) row("Base Fare", "₹${_baseFare.toStringAsFixed(0)}"),
            if (_distanceFare > 0)
              row("Distance Charge", "₹${_distanceFare.toStringAsFixed(0)}"),
            if (_addonsTotal > 0)
              row("Add-on Services", "₹${_addonsTotal.toStringAsFixed(0)}"),
            // Added to the fare at pickup, so it needs naming here — it used to
            // disappear into "Other Charges" with nothing to explain the jump.
            if (_waitingBilled)
              row(
                "Waiting Charge",
                "₹${_waitingCharge.toStringAsFixed(0)}",
                note: _waitingMinutes > 0
                    ? "Driver waited $_waitingMinutes min at pickup. Only the "
                        "time beyond the free waiting allowance is charged."
                    : null,
              ),
            if (other.abs() >= 1)
              row("Other Charges", "₹${other.toStringAsFixed(0)}"),
            if (_taxAmount > 0) row("GST & Taxes", "₹${_taxAmount.toStringAsFixed(0)}"),
            if (_discountAmount > 0)
              row("Discount", "-₹${_discountAmount.toStringAsFixed(0)}",
                  color: Colors.green),
            const Divider(height: 24),
            row("Total Fare", "₹${_finalFare.toStringAsFixed(2)}", bold: true),
            const SizedBox(height: 8),
            Text("Paid via $_paymentLabel",
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  /// Fetch and open the consignment note / invoice PDF for this booking.
  Future<void> _downloadConsignmentNote() async {
    if (_downloadingInvoice) return;
    setState(() => _downloadingInvoice = true);
    try {
      final invoice = await BookingService.getInvoice(widget.bookingId);
      final data = invoice['data'] is Map ? invoice['data'] : invoice;
      final pdfUrl = data['pdfUrl']?.toString();
      final invNo = data['invoiceNumber'] ?? _bookingNumber;
      if (!mounted) return;
      if (pdfUrl != null && pdfUrl.isNotEmpty) {
        final uri = Uri.parse(pdfUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Consignment note #$invNo generated. A downloadable copy isn\'t available yet.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Consignment note error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingInvoice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.appColor)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // ── Header with ETA ──
                commonAppBar(
                  height: 280,
                  context: context,
                  child: Container(
                    padding: const EdgeInsets.only(top: 50),
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const SizedBox(width: 5),
                            InkWell(
                              onTap: () => safeBack(context),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                margin: const EdgeInsets.only(left: 11),
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.25),
                                        blurRadius: 4),
                                  ],
                                ),
                                child: const Icon(Icons.arrow_back_ios_new,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Trip $_bookingNumber",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  height: 1.25),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () => Share.share(
                                  'Track my Movezy delivery: #$_bookingNumber'),
                              child: Image.asset("assets/share_icon.png",
                                  width: 25, height: 25),
                            ),
                            const SizedBox(width: 18),
                          ],
                        ),
                        const SizedBox(height: 15),
                        // ETA card
                        Container(
                          margin:
                              const EdgeInsets.only(left: 20, right: 20),
                          padding: const EdgeInsets.only(
                              left: 20, right: 10, top: 15, bottom: 15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              // Expanded: as a bare Row child this column got
                              // unbounded width, so the status label laid out at
                              // its intrinsic width and overflowed next to the
                              // map preview on narrow screens / large text.
                              // The Spacer it replaces is no longer needed —
                              // Expanded already pushes the map to the edge.
                              Expanded(
                                child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: HexColor("#FF6200")
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                    // min: the column above is width-bounded
                                    // now, so a default max-size Row would
                                    // stretch this pill to the full width.
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(width: 7),
                                        Image.asset(
                                            "assets/stopwatch.png",
                                            width: 27),
                                        const SizedBox(width: 7),
                                        // Labelled for what the number is: the
                                        // routed pickup→drop trip time. It was
                                        // a bare "N / mins" sitting directly
                                        // above "Driver on the way to pickup",
                                        // so customers read it as how long
                                        // until the driver reached them.
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              "Est. trip time",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  color:
                                                      AppColors.appColor,
                                                  fontSize: 10,
                                                  height: 1.2,
                                                  fontWeight:
                                                      FontWeight.w600),
                                            ),
                                            Text(
                                              _tripDurationMin > 0
                                                  ? "$_tripDurationMin"
                                                  : "--",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  color:
                                                      AppColors.appColor,
                                                  fontSize: 26,
                                                  height: 1.1,
                                                  fontWeight:
                                                      FontWeight.w600),
                                            ),
                                            Text(
                                              "mins",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  color:
                                                      AppColors.appColor,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  fontSize: 12),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 7),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(_statusLabel,
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15)),
                                ],
                                ),
                              ),
                              // Live route preview — tap for the full map. This
                              // was a static route illustration, so there was no
                              // way to see the actual route or the driver moving.
                              _buildMiniMap(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ── Delay Communication Banner ──
                _buildDelayBanner(),

                // ── Pickup OTP ──
                _buildOtpCard(),
                _buildDeliveryOtpCard(),

                const SizedBox(height: 16),

                // ── Driver info card ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              spreadRadius: 10,
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 64,
                              height: 48,
                              child: _vehicleImage.isNotEmpty
                                  ? Image.network(
                                      // Proxied like every other screen, or it
                                      // fails wherever the raw host is
                                      // unreachable (emulator setups).
                                      ApiUrls.imageProxyUrl(_vehicleImage),
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(
                                          Icons.local_shipping_outlined,
                                          size: 32,
                                          color: Colors.black54),
                                    )
                                  : const Icon(Icons.local_shipping_outlined,
                                      size: 32, color: Colors.black54),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  // Scale-down rather than ellipsis: the number
                                  // plate is the identifying detail on this card
                                  // and two 52px action buttons now share the
                                  // row, so on a narrow phone "UP-37-Y-0744"
                                  // would otherwise truncate to nonsense.
                                  SizedBox(
                                    height: 26,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        _vehicleNumber.isNotEmpty
                                            ? _vehicleNumber
                                            : "ID #$_bookingNumber",
                                        maxLines: 1,
                                        style: TextStyle(
                                            fontSize: 19,
                                            height: 1.25,
                                            fontWeight: FontWeight.w700,
                                            color: HexColor("#2A2A2A")),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  // Flexible + ellipsis: as bare Row children
                                  // both got unbounded width, so a long catalog
                                  // vehicle name next to a long driver name
                                  // could never shrink and ran off the card.
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(_vehicleName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 13,
                                                height: 1.4,
                                                color: Colors.grey.shade600)),
                                      ),
                                      if (_driverName.isNotEmpty) ...[
                                        Text(" • ",
                                            style: TextStyle(
                                                fontSize: 13,
                                                height: 1.4,
                                                color: Colors.grey.shade600)),
                                        Flexible(
                                          child: Text(_driverName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  height: 1.4,
                                                  color: HexColor("#3267E4"),
                                                  fontWeight:
                                                      FontWeight.w600)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Reach the driver. Chat was a green square tucked
                            // in the corner and there was no way to phone them
                            // at all — the customer's most common need once a
                            // driver is on the way.
                            if (_hasDriver) ...[
                              const SizedBox(width: 8),
                              _driverActionButton(
                                // Drew a generic Icons.chat_bubble_outline
                                // while the design's own chat-bubble export sat
                                // unused in assets/.
                                asset: "assets/message_icon.png",
                                label: 'Chat with driver',
                                onTap: () => pushTo(
                                  context,
                                  ChatScreen(
                                    bookingId: widget.bookingId,
                                    driverName: _driverName,
                                  ),
                                ),
                              ),
                              // No number on the booking means nothing to dial,
                              // so no button — a dead one is worse than none.
                              if (_driverPhone.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                _driverActionButton(
                                  // Same as chat: a generic Icons.call_outlined
                                  // stood in for the design's handset export.
                                  asset: "assets/call_icon.png",
                                  label: 'Call driver',
                                  onTap: _callDriver,
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Pickup / Drop card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              spreadRadius: 10,
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          children: [
                            SizedBox(
                              width:
                                  MediaQuery.of(context).size.width - 40,
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 30,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        const SizedBox(height: 10),
                                        Container(
                                          height: 13,
                                          width: 13,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(
                                                    100),
                                            color: HexColor("#25AA59"),
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Image.asset(
                                            'assets/small_dotted_line.png',
                                            width: 1,
                                            height: 70,
                                            fit: BoxFit.cover),
                                        const SizedBox(height: 1),
                                        Image.asset(
                                            'assets/clip_path.png',
                                            width: 18,
                                            height: 18,
                                            fit: BoxFit.cover),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        _locationTile(
                                          title: _pickupContactName.isNotEmpty
                                              ? _pickupContactName
                                              : "Pickup",
                                          phone: _pickupContact,
                                          address: _pickupAddress,
                                          isFirst: true,
                                        ),
                                        for (var i = 0;
                                            i < _stops.length;
                                            i++) ...[
                                          const SizedBox(height: 18),
                                          _stopTile(i),
                                        ],
                                        const SizedBox(height: 18),
                                        _locationTile(
                                          title: _dropContactName.isNotEmpty
                                              ? _dropContactName
                                              : "Drop",
                                          phone: _dropContact,
                                          address: _dropAddress,
                                          isFirst: false,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Live trip actions, under the addresses they act
                            // on. Adding a stop mid-trip had no entry point at
                            // all, even though the backend supports it.
                            _tripActionsRow(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),
                    ],
                  ),
                ),

                // ── Payment ──
                _paymentSection(context),

                const SizedBox(height: 20),

                // ── Consignment Note ──
                // Only for a completed trip: the invoice endpoint matches
                // status COMPLETED, so tapping this mid-trip always errored
                // with "Completed booking not found".
                if (_status == 'COMPLETED')
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 10,
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  margin: const EdgeInsets.only(left: 20, right: 20),
                  child: Row(
                    children: [
                      Image.asset("assets/credit.png", width: 30),
                      const SizedBox(width: 7),
                      const Text("Consignment Note",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      const Spacer(),
                      InkWell(
                        onTap: _downloadingInvoice ? null : _downloadConsignmentNote,
                        child: _downloadingInvoice
                            ? const SizedBox(
                                height: 16, width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text("Download",
                                style: TextStyle(
                                    color: HexColor("#2C67F2"),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Order Help section ──
                _orderHelpSection(context),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20),
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.only(left: 2, right: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 15),
              Image.asset("assets/credit_card.png", width: 38, height: 38),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_paymentLabel,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500)),
                  Text("Payment Method",
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w300,
                          color: Colors.black.withValues(alpha: 0.7))),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("₹${_finalFare.toStringAsFixed(2)}",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: HexColor("#2B3233"))),
                  InkWell(
                    onTap: _showFareBreakup,
                    child: Text("View Breakup",
                        style: TextStyle(
                            color: HexColor("#2C67F1"),
                            fontWeight: FontWeight.w300,
                            fontSize: 10)),
                  ),
                ],
              ),
              const SizedBox(width: 15),
            ],
          ),
          const SizedBox(height: 20),
          if (_coinsEarned > 0)
            Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  HexColor("#FEFEF6"),
                  HexColor("#FDF6AB"),
                ]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Image.asset("assets/rupee_coins.png", height: 30),
                  const SizedBox(width: 10),
                  // Expanded: as a bare Row child this line got unbounded width
                  // and could never wrap, so it overflowed on narrow screens.
                  // It takes over from the Expanded spacer that used to sit
                  // after it — two flex children would have split the space.
                  Expanded(
                    child: Text(
                        "You'll receive $_coinsEarned coins on this order!",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w300,
                            fontSize: 10)),
                  ),
                  const Icon(Icons.arrow_forward_ios_sharp, size: 15),
                ],
              ),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  /// Circular peach contact button on the driver card (chat / call).
  Widget _driverActionButton({
    required String asset,
    required String label,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      // Icon-only, so screen readers need the label spelled out.
      label: label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          // The exports carry their own peach fill (#FF6200 at 10% alpha), so
          // the flat HexColor("#FDEBDD") fill that used to sit behind the glyph
          // would now show through and double the tint — hence no colour here.
          // Their fill is a rounded square; the clip trims it to the circle the
          // design draws.
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: Image.asset(asset, width: 52, height: 52, fit: BoxFit.cover),
        ),
      ),
    );
  }

  /// Dashed rule above the trip actions. Flutter has no dashed border, so it's
  /// drawn as evenly spaced segments sized to whatever width the card gives.
  Widget _dashedDivider() {
    return LayoutBuilder(
      builder: (_, constraints) {
        const dash = 5.0;
        const gap = 4.0;
        final count = (constraints.maxWidth / (dash + gap)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count < 1 ? 1 : count,
            (_) => Container(
                width: dash, height: 1, color: Colors.grey.shade300),
          ),
        );
      },
    );
  }

  /// One half of the trip-actions row.
  Widget _tripAction({
    required Widget leading,
    required String label,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            leading,
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: AppColors.appColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "ADD STOP" + "View Details" under the addresses.
  ///
  /// ADD STOP only appears while the server would actually accept one — see
  /// [_canAddStop] — so the customer is never offered a button that comes back
  /// rejected. View Details is always available.
  Widget _tripActionsRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        children: [
          _dashedDivider(),
          const SizedBox(height: 6),
          Row(
            children: [
              if (_canAddStop) ...[
                Expanded(
                  child: _tripAction(
                    leading: _addingStop
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.appColor),
                          )
                        : Container(
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: AppColors.appColor,
                                shape: BoxShape.circle),
                            child: const Icon(Icons.add,
                                size: 14, color: Colors.white),
                          ),
                    label: "ADD STOP",
                    // null while in flight so the tap can't be repeated.
                    onTap: _addingStop ? null : _addStop,
                  ),
                ),
                Container(width: 1, height: 26, color: Colors.grey.shade300),
              ],
              Expanded(
                child: _tripAction(
                  // Was a generic Icons.list_alt_outlined; the design draws the
                  // hamburger that ships as assets/hembers.png and went unused.
                  leading: Image.asset("assets/hembers.png", width: 20),
                  label: "View Details",
                  onTap: () => pushTo(
                    context,
                    BookingDetailsScreen(bookingId: widget.bookingId),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// One intermediate drop: numbered while pending, green check once the
  /// driver marks it delivered (completedAt set by the server).
  Widget _stopTile(int index) {
    final st = _stops[index];
    final done = st['completedAt'] != null &&
        st['completedAt'].toString().isNotEmpty &&
        st['completedAt'].toString() != 'null';
    final address = (st['address'] ?? 'Stop ${index + 1}').toString();
    final contact = (st['contactName'] ?? '').toString();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: done ? const Color(0xFF25AA59) : const Color(0xFFF5F6F8),
            shape: BoxShape.circle,
            border: Border.all(
                color: done
                    ? const Color(0xFF25AA59)
                    : const Color(0xFFB9C0CC)),
          ),
          child: done
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Text('${index + 1}',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280))),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      contact.isNotEmpty ? contact : 'Stop ${index + 1}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (done)
                    const Text('Delivered',
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF25AA59))),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12.5, color: Colors.grey.shade600, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _locationTile({
    required String title,
    required String phone,
    required String address,
    required bool isFirst,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          height: 1.4,
                          color: HexColor("#334A4C")),
                    ),
                  ),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      phone,
                      style: TextStyle(
                          color: HexColor("#334A4C").withValues(alpha: 0.8),
                          fontSize: 12,
                          height: 1.33),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: TextStyle(
                    color: HexColor("#334A4C").withValues(alpha: 0.8),
                    fontSize: 12,
                    height: 1.33),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Support card. Deliberately no Cancel Booking button even though the mock
  /// still draws one — removed on explicit instruction. Cancelling stays
  /// reachable from BookingHistory's Cancel action and RideFindingScreen's
  /// Cancel Booking button, both of which open CancelRideScreen.
  Widget _orderHelpSection(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Facing issue in this order?",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => pushTo(context, const HelpSupportScreen()),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Was a generic Icons.headset_mic hand-tinted to approximate
                    // the design; assets/headphones.png is the real export.
                    Image.asset("assets/headphones.png",
                        width: 20, height: 20),
                    const SizedBox(width: 6),
                    Text(
                      "Contact Support",
                      style: TextStyle(
                          fontSize: 12, color: HexColor("#13B09E")),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Terms stay reachable as a quiet link rather than a list row.
        InkWell(
          onTap: () =>
              showBookingTermsSheet(context, vehicleName: _vehicleName),
          child: Text(
            "Terms and conditions",
            style: TextStyle(
                fontSize: 12,
                decoration: TextDecoration.underline,
                color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }
}
