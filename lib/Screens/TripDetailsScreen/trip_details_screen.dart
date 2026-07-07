import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/CommonWidgets/booking_terms_sheet.dart';
import 'package:movezy_user_app/CommonWidgets/order_status_timeline.dart';
import 'package:movezy_user_app/Screens/CancelRideScreen/cancel_ride_screen.dart';
import 'package:movezy_user_app/Screens/ChatScreen/chat_screen.dart';
import 'package:movezy_user_app/Screens/HelpSupportScreen/help_support_screen.dart';
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
  bool showCancelDialog = false;
  bool _loading = true;
  bool _cancelling = false;
  String? _cancelReasonId;
  Timer? _pollTimer;

  // Booking data from API
  String _bookingNumber = '';
  String _status = '';
  String _driverName = '';
  String _vehicleName = '';
  String _vehicleNumber = '';
  String _pickupAddress = '';
  String _pickupContact = '';
  String _dropAddress = '';
  String _dropContact = '';
  String _paymentMethod = 'CASH';
  double _finalFare = 0;
  int _etaMinutes = 0;
  String _otp = '';
  int _coinsEarned = 0;
  bool _downloadingInvoice = false;

  // Fare breakdown components (from booking priceDetails)
  double _baseFare = 0;
  double _distanceFare = 0;
  double _addonsTotal = 0;
  double _taxAmount = 0;
  double _discountAmount = 0;

  // Delay communication
  DateTime? _assignedAt;
  DateTime? _pickedAt;
  int _originalEtaMinutes = 0;

  @override
  void initState() {
    super.initState();
    _fetchBooking();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
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
        _vehicleName =
            vehicleType is Map ? (vehicleType['name'] ?? 'Vehicle') : 'Vehicle';
        _vehicleNumber = booking['vehicleNumber'] ?? '';
        _pickupAddress = pickup['address'] ?? 'Pickup';
        _pickupContact = pickup['contactPhone'] ?? '';
        _dropAddress = drop['address'] ?? 'Drop';
        _dropContact = drop['contactPhone'] ?? '';
        _paymentMethod = booking['paymentMethod'] ?? 'CASH';
        _finalFare =
            (booking['finalFare'] ?? booking['fare'] ?? 0).toDouble();

        // Fare breakdown — tolerate different backend shapes.
        final price = (booking['priceDetails'] is Map)
            ? booking['priceDetails'] as Map
            : (booking['fareBreakup'] is Map ? booking['fareBreakup'] as Map : booking);
        double num2(dynamic v) => (v ?? 0).toDouble();
        _baseFare = num2(price['baseFare'] ?? price['base']);
        _distanceFare = num2(price['distanceCharge'] ??
            price['distanceFare'] ?? price['distance']);
        _addonsTotal = num2(price['addonCharges'] ??
            price['addonsTotal'] ?? price['addons']);
        _taxAmount = num2(price['gst'] ?? price['taxAmount'] ?? price['tax']);
        _discountAmount = num2(price['discount'] ?? price['discountAmount']);

        _etaMinutes =
            (booking['estimatedArrivalTime'] ?? data['eta'] ?? 0).toInt();
        _otp = booking['otp'] ?? '';
        _coinsEarned = (booking['coinsEarned'] ?? 0).toInt();

        // Delay communication data
        if (booking['assignedAt'] != null) {
          _assignedAt = DateTime.tryParse(booking['assignedAt'].toString());
        }
        if (booking['pickedAt'] != null) {
          _pickedAt = DateTime.tryParse(booking['pickedAt'].toString());
        }
        _originalEtaMinutes = (booking['durationMin'] ?? _etaMinutes).toInt();

        _loading = false;
      });
    } catch (e) {
      debugPrint('TripDetails fetch error: $e');
      if (mounted && _loading) setState(() => _loading = false);
    }
  }

  // ── Delay Communication Banner ──
  Widget _buildDelayBanner() {
    // Calculate if there's a significant delay
    int delayMinutes = 0;
    String delayMessage = '';

    final now = DateTime.now();

    if (_status == 'ASSIGNED' && _assignedAt != null && _etaMinutes > 0) {
      // Driver assigned — check if past expected arrival
      final expectedArrival = _assignedAt!.add(Duration(minutes: _etaMinutes));
      if (now.isAfter(expectedArrival)) {
        delayMinutes = now.difference(expectedArrival).inMinutes;
        delayMessage = 'Your driver is running ~$delayMinutes min late. We apologize for the inconvenience.';
      }
    } else if ((_status == 'PICKED' || _status == 'IN_PROGRESS') && _pickedAt != null && _originalEtaMinutes > 0) {
      // En route to drop — check if past expected delivery
      final expectedDelivery = _pickedAt!.add(Duration(minutes: _originalEtaMinutes));
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

  String get _statusLabel {
    switch (_status) {
      case 'ASSIGNED':
        return 'Driver on the way to\npickup';
      case 'DRIVER_ARRIVED':
        return 'Driver has arrived at\npickup point';
      case 'PICKED':
        return 'Goods picked up,\non the way';
      case 'IN_PROGRESS':
        return 'Delivery in progress';
      case 'COMPLETED':
        return 'Delivery completed';
      default:
        return 'Finding driver...';
    }
  }

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

  bool get _canCancel =>
      ['SEARCHING', 'ASSIGNED', 'DRIVER_ARRIVED'].contains(_status);

  Future<void> _performCancel() async {
    if (_cancelling) return;
    setState(() => _cancelling = true);
    try {
      await BookingService.cancelBooking(widget.bookingId,
          cancellationReasonId: _cancelReasonId);
      _pollTimer?.cancel();
      if (mounted) {
        replaceRoute(context, const RideCanceledSuccessScreen());
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cancelling = false;
          showCancelDialog = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Cancel failed: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Show a fare breakdown bottom sheet built from the booking's price details.
  void _showFareBreakup() {
    // Any components we couldn't parse are folded into "Other charges" so the
    // rows always add up to the amount actually payable.
    final knownSum = _baseFare +
        _distanceFare +
        _addonsTotal +
        _taxAmount -
        _discountAmount;
    final other = (_finalFare - knownSum);

    Widget row(String label, String value, {Color? color, bool bold = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: bold ? 15 : 13,
                      color: color ?? Colors.black87,
                      fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
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
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.only(left: 16),
                                width: 40,
                                height: 35,
                                alignment: Alignment.center,
                                child: const Icon(Icons.arrow_back_ios,
                                    color: Colors.white),
                              ),
                            ),
                            Text(
                              "Trip #$_bookingNumber",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
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
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: HexColor("#FF6200")
                                          .withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(15),
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 7),
                                        Image.asset(
                                            "assets/stopwatch.png",
                                            width: 27),
                                        const SizedBox(width: 7),
                                        Column(
                                          children: [
                                            Text(
                                              _etaMinutes > 0
                                                  ? "$_etaMinutes"
                                                  : "--",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  color:
                                                      AppColors.appColor,
                                                  fontSize: 16,
                                                  fontWeight:
                                                      FontWeight.bold),
                                            ),
                                            Text(
                                              "mins",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  color:
                                                      AppColors.appColor,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  fontSize: 14),
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
                              const Spacer(),
                              SizedBox(
                                width: MediaQuery.of(context).size.width *
                                    0.31,
                                height:
                                    MediaQuery.of(context).size.width *
                                        0.31,
                                child: Image.asset(
                                    "assets/route_icon.png",
                                    fit: BoxFit.fill),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ── Order Status Timeline ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OrderStatusTimeline(currentStatus: _status),
                ),

                // ── Delay Communication Banner ──
                _buildDelayBanner(),

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
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset('assets/bike_image.png',
                                width: 50),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text("ID #$_bookingNumber",
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight:
                                                  FontWeight.w700)),
                                      const Spacer(),
                                      if (_otp.isNotEmpty)
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4),
                                          decoration: BoxDecoration(
                                            color: HexColor("#A2BF49"),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text("OTP: $_otp",
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  fontSize: 12)),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text("$_vehicleName  •",
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.black54)),
                                      Text("  $_driverName",
                                          style: TextStyle(
                                              fontSize: 11,
                                              color:
                                                  HexColor("#5680E2"),
                                              fontWeight:
                                                  FontWeight.bold)),
                                    ],
                                  ),
                                  if (_vehicleNumber.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(_vehicleNumber,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color:
                                                Colors.grey.shade600)),
                                  ],
                                ],
                              ),
                            ),
                            // Chat with the assigned driver (real-time socket chat).
                            if (_driverName.isNotEmpty &&
                                _driverName != 'Driver')
                              InkWell(
                                onTap: () {
                                  pushTo(
                                    context,
                                    ChatScreen(
                                      bookingId: widget.bookingId,
                                      driverName: _driverName,
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: HexColor("#A2BF49"),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.chat_bubble_outline,
                                      color: Colors.white, size: 20),
                                ),
                              ),
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
                                          title: "Pickup",
                                          phone: _pickupContact,
                                          address: _pickupAddress,
                                          isFirst: true,
                                        ),
                                        const SizedBox(height: 18),
                                        _locationTile(
                                          title: "Drop",
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

                // ── Contact Support ──
                InkWell(
                  onTap: () => pushTo(context, const HelpSupportScreen()),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Facing issue in this order?",
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Image.asset("assets/headphones.png",
                                width: 30),
                            const SizedBox(width: 10),
                            Text("Contact Support",
                                style: TextStyle(
                                    color: HexColor("#13B09E"),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                            const Spacer(),
                            const Icon(Icons.arrow_forward_ios,
                                size: 14, color: Colors.grey),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Order Help section ──
                _orderHelpSection(context),

                const SizedBox(height: 20),

                // ── Cancel button ──
                if (_canCancel)
                  InkWell(
                    onTap: () async {
                      var res = await pushTo(
                          context,
                          CancelRideScreen(
                              bookingId: widget.bookingId));
                      if (res == 'cancelled' && mounted) {
                        _pollTimer?.cancel();
                        replaceRoute(context,
                            const RideCanceledSuccessScreen());
                      } else if (res is Map &&
                          res['reasonId'] != null) {
                        setState(() {
                          _cancelReasonId = res['reasonId'];
                          showCancelDialog = true;
                        });
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(
                          left: 20, right: 20),
                      height: 50,
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: HexColor('#D81D0C'), width: 1),
                      ),
                      child: Center(
                        child: Text("Cancel Booking",
                            style: TextStyle(
                                color: HexColor('#D81D0C'),
                                fontWeight: FontWeight.w500,
                                fontSize: 14)),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),

          // ── Cancel confirmation dialog overlay ──
          if (showCancelDialog)
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                  color: HexColor("#414141").withOpacity(0.8)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: HexColor("#EE3E35")),
                            borderRadius:
                                BorderRadius.circular(100),
                          ),
                          height: 55,
                          width: 55,
                          child: Icon(Icons.close_outlined,
                              size: 35,
                              color: HexColor("#EE3E35")),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                            "Wait! Driver is almost there.",
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 7),
                        const Text(
                          "Are you sure you still want to cancel\nyour Movezy delivery?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: 280,
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(
                                      () => showCancelDialog = false),
                                  child: Container(
                                    height: 45,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color:
                                              HexColor("#079837")),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                        child: Text("No, Continue",
                                            style: TextStyle(
                                                color: HexColor(
                                                    "#079837"),
                                                fontWeight:
                                                    FontWeight.w500,
                                                fontSize: 12))),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  onTap: _cancelling
                                      ? null
                                      : _performCancel,
                                  child: Container(
                                    padding: const EdgeInsets.only(
                                        left: 8, right: 8),
                                    height: 45,
                                    decoration: BoxDecoration(
                                      color: HexColor("#EE3E35"),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: _cancelling
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child:
                                                  CircularProgressIndicator(
                                                      color:
                                                          Colors.white,
                                                      strokeWidth: 2))
                                          : const Text(
                                              "Yes, Cancel Ride",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight:
                                                      FontWeight.w500,
                                                  fontSize: 12)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 13),
                      ],
                    ),
                  ),
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
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 10,
            blurRadius: 20,
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
              Image.asset("assets/credit_card.png", width: 40),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_paymentLabel,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const Text("Payment Method",
                      style: TextStyle(fontSize: 12)),
                ],
              ),
              const Spacer(),
              Column(
                children: [
                  Text("₹${_finalFare.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                  InkWell(
                    onTap: _showFareBreakup,
                    child: const Text("View Breakup",
                        style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                            fontSize: 12)),
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
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Image.asset("assets/rupee_coins.png", height: 30),
                  const SizedBox(width: 10),
                  Text(
                      "You'll receive $_coinsEarned coins on this order!",
                      style: const TextStyle(
                          color: Colors.black, fontSize: 11)),
                  const Expanded(child: SizedBox()),
                  const Icon(Icons.arrow_forward_ios_sharp, size: 15),
                ],
              ),
            ),
          const SizedBox(height: 10),
        ],
      ),
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
                children: [
                  Text("$title ",
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  if (phone.isNotEmpty)
                    Text(phone,
                        style: TextStyle(
                            color: HexColor("#334A4C"), fontSize: 12)),
                ],
              ),
              const SizedBox(height: 4),
              Text(address,
                  style: TextStyle(
                      color: HexColor("#334A4C"), fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  /// Porter-style "Order help" section with Contact us, Cancel order, Terms
  Widget _orderHelpSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text(
              "Order help",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Contact us
          _helpItem(
            icon: Icons.headset_mic,
            iconColor: Colors.grey.shade700,
            title: "Contact us",
            subtitle: "Call support or email us",
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            onTap: () => pushTo(context, const HelpSupportScreen()),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // Cancel order
          if (_canCancel)
            _helpItem(
              icon: Icons.cancel_outlined,
              iconColor: Colors.red,
              title: "Cancel order ?",
              subtitle: "Your partner is usually assigned within 10 minutes of booking",
              trailing: Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              onTap: () async {
                var res = await pushTo(
                    context, CancelRideScreen(bookingId: widget.bookingId));
                if (res == 'cancelled' && mounted) {
                  _pollTimer?.cancel();
                  replaceRoute(context, const RideCanceledSuccessScreen());
                }
              },
            ),
          if (_canCancel)
            const Divider(height: 1, indent: 16, endIndent: 16),
          // Terms and conditions
          _helpItem(
            icon: Icons.description_outlined,
            iconColor: Colors.grey.shade700,
            title: "Terms and conditions",
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            onTap: () {
              showBookingTermsSheet(context, vehicleName: _vehicleName);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _helpItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
