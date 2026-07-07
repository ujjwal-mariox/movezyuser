import 'dart:async';
import 'package:flutter/material.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/CommonWidgets/button_widget.dart';
import 'package:movezy_user_app/Screens/CancelRideScreen/cancel_ride_screen.dart';
import 'package:movezy_user_app/Screens/TripDetailsScreen/trip_details_screen.dart';
import 'package:movezy_user_app/Screens/DashboardScreen/dashboard_screen.dart';
import 'package:movezy_user_app/Services/booking_service.dart';
import 'package:hexcolor/hexcolor.dart';

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
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
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

      final status = booking['status'] ?? '';

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
    final result = await pushTo(context, CancelRideScreen(bookingId: widget.bookingId));
    if (result == 'cancelled' && mounted) {
      _cancelled = true;
      _pollTimer?.cancel();
      replaceRoute(context, DashboardScreen());
    }
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
                      onTap: () => Navigator.pop(context),
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
                // Map placeholder
                Positioned.fill(
                  child: Image.asset("assets/ride_finding_image.png", fit: BoxFit.cover),
                ),

                // Status overlay
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
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
                                color: HexColor("#FF6200").withOpacity(
                                    0.5 + _pulseController.value * 0.5),
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
                  ),
                ),

                // Cancel button
                Positioned(
                  bottom: 20,
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
}
