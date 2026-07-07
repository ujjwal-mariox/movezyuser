import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/Services/booking_service.dart';
import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';

class CancelRideScreen extends StatefulWidget {
  final String bookingId;

  const CancelRideScreen({super.key, required this.bookingId});

  @override
  State<CancelRideScreen> createState() => _CancelRideScreenState();
}

class _CancelRideScreenState extends State<CancelRideScreen> {
  List<CancellationReason> _reasons = [];
  bool _loading = true;
  bool _cancelling = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchReasons();
  }

  Future<void> _fetchReasons() async {
    try {
      final reasons = await BookingService.getCancellationReasons();
      if (mounted) {
        setState(() {
          _reasons = reasons;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load cancellation reasons: $e');
      // Fallback to hardcoded reasons if API fails
      if (mounted) {
        setState(() {
          _reasons = _fallbackReasons;
          _loading = false;
        });
      }
    }
  }

  List<CancellationReason> get _fallbackReasons => [
        CancellationReason(id: '', reason: 'Change in plans', refundPercentage: 100, sortOrder: 1),
        CancellationReason(id: '', reason: 'Waiting for long time', refundPercentage: 100, sortOrder: 2),
        CancellationReason(id: '', reason: 'Unable to contact driver', refundPercentage: 100, sortOrder: 3),
        CancellationReason(id: '', reason: 'Driver denied to go to destination', refundPercentage: 100, sortOrder: 4),
        CancellationReason(id: '', reason: 'Driver denied to come to pickup', refundPercentage: 100, sortOrder: 5),
        CancellationReason(id: '', reason: 'Wrong address shown', refundPercentage: 100, sortOrder: 6),
        CancellationReason(id: '', reason: 'The price is not reasonable', refundPercentage: 100, sortOrder: 7),
        CancellationReason(id: '', reason: 'Emergency situation', refundPercentage: 100, sortOrder: 8),
        CancellationReason(id: '', reason: 'Booking mistake', refundPercentage: 100, sortOrder: 9),
        CancellationReason(id: '', reason: 'Poor weather conditions', refundPercentage: 100, sortOrder: 10),
        CancellationReason(id: '', reason: 'Other', refundPercentage: 100, sortOrder: 11),
      ];

  Future<void> _cancelBooking() async {
    if (_cancelling) return;
    setState(() => _cancelling = true);

    try {
      final selectedReason = _reasons[_selectedIndex];
      await BookingService.cancelBooking(
        widget.bookingId,
        cancellationReasonId: selectedReason.id.isNotEmpty ? selectedReason.id : null,
      );
      if (mounted) {
        Navigator.pop(context, 'cancelled');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cancelling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Column(
        children: [
          commonAppBar(
            height: 100,
            context: context,
            child: Container(
              padding: const EdgeInsets.only(top: 45),
              child: Row(
                children: [
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
                  const Text(
                    "Cancel Ride",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: AppColors.appColor))
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Why are you cancelling?',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 18),
                        Expanded(
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: _reasons.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final reason = _reasons[index];
                              final selected = index == _selectedIndex;

                              return GestureDetector(
                                onTap: () => setState(() => _selectedIndex = index),
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 3, bottom: 3),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 17,
                                        height: 17,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: selected
                                                ? const Color(0xFF2F6FA8)
                                                : const Color(0xFF9AA3AD),
                                            width: 1,
                                          ),
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: selected
                                                  ? const Color(0xFF2F6FA8)
                                                  : Colors.transparent,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          reason.reason,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          // Bottom button
          Container(
            margin: const EdgeInsets.only(left: 20, right: 20, bottom: 5),
            padding: const EdgeInsets.fromLTRB(17, 8, 17, 20),
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _cancelling ? null : _cancelBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.appColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Center(
                  child: _cancelling
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Cancel Ride',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
