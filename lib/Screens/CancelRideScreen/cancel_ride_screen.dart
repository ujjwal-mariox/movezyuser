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
    _loadPreview();
  }

  /// The real refund consequence for this booking's CURRENT stage.
  Map<String, dynamic>? _preview;

  Future<void> _loadPreview() async {
    final p = await BookingService.cancellationPreview(widget.bookingId);
    if (mounted) setState(() => _preview = p);
  }

  /// Warning banner shown above the reasons. Says nothing about amounts unless
  /// the server told us what they are — the percentages are admin-configurable,
  /// so the app must not assert its own.
  Widget _refundNotice() {
    final p = _preview;
    if (p == null) return const SizedBox.shrink();

    final bool afterPickup = p['afterPickup'] == true;
    final bool wasPaid = p['wasPaid'] == true;
    final num pct = (p['refundPercentage'] as num?) ?? 0;
    final num amount = (p['refundAmount'] as num?) ?? 0;

    String msg;
    if (!wasPaid) {
      msg = afterPickup
          ? 'Your goods are already with the driver. No payment has been taken for this booking.'
          : 'No payment has been taken for this booking.';
    } else if (pct <= 0) {
      msg = afterPickup
          ? 'Your goods have already been picked up. Cancelling now is not refundable.'
          : 'Cancelling now is not refundable.';
    } else if (amount > 0) {
      msg = 'You will be refunded ₹${amount.toStringAsFixed(0)} (${pct.toStringAsFixed(0)}% of the fare).';
    } else {
      msg = 'A refund of ${pct.toStringAsFixed(0)}% applies to this cancellation.';
    }

    final bool warn = wasPaid && pct <= 0;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: warn ? const Color(0xFFFDECEA) : const Color(0xFFFFF6F0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: warn ? const Color(0xFFE02D3C) : const Color(0xFFFFDEC9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(warn ? Icons.warning_amber_rounded : Icons.info_outline,
              size: 18,
              color: warn ? const Color(0xFFE02D3C) : const Color(0xFFFF6200)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg,
                style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: warn
                        ? const Color(0xFF8C1D18)
                        : const Color(0xFF3D3D3D))),
          ),
        ],
      ),
    );
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
      // Indexing blindly threw a RangeError when the reasons list came back
      // empty, which the catch below reported as "Failed to cancel" — leaving
      // the customer with no way out of the booking. Cancelling must not
      // depend on a reason being available.
      final selectedReason =
          (_selectedIndex >= 0 && _selectedIndex < _reasons.length)
              ? _reasons[_selectedIndex]
              : null;
      final result = await BookingService.cancelBooking(
        widget.bookingId,
        cancellationReasonId:
            (selectedReason != null && selectedReason.id.isNotEmpty)
                ? selectedReason.id
                : null,
      );
      if (mounted) {
        // Hand the real outcome back so the success screen can state it.
      Navigator.pop(context, result['data'] ?? result);
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
                        // What cancelling now actually costs — shown BEFORE the
                        // customer picks a reason. Cancel used to be offered
                        // after pickup with no hint that the refund is nil.
                        Transform.translate(
                          offset: const Offset(-20, 0),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: _refundNotice(),
                          ),
                        ),
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
