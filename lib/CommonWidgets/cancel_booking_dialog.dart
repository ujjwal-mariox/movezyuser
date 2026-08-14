import 'package:flutter/material.dart';
import 'package:movezy_user_app/Services/booking_service.dart';

// The app's cancel-red (booking history's Cancel action / CANCELLED badge) and
// positive-green ("Completed", delivery-done tick). AppColors.greenColor is the
// olive brand accent and is never used for affirmative actions, so it would
// look off next to the rest of the cancel flow.
const Color _kRed = Color(0xFFEE3E35);
const Color _kGreen = Color(0xFF25AA59);

/// The one place the stage copy lives. Every entry into the cancel flow shows
/// this before CancelRideScreen, so the wording can't drift between callers.
String _headlineForStatus(String status) {
  switch (status) {
    case 'ASSIGNED':
      return 'Wait! Driver is almost there.';
    case 'DRIVER_ARRIVED':
      return 'Driver has arrived at pickup.';
    case 'PICKED':
    case 'IN_PROGRESS':
      return 'Your goods are already on the way.';
    // DRAFT/SEARCHING — and any status we haven't observed yet — get the
    // generic headline rather than a stage claim we can't back.
    default:
      return 'Cancel this booking?';
  }
}

/// Stage-aware "are you sure" gate shown IN FRONT of the cancel flow.
///
/// Returns true only when the customer taps "Yes, Cancel Ride"; dismissing the
/// dialog any other way (No, barrier tap, back) means "keep the booking".
/// [bookingStatus] is the caller's own model of the booking (each screen
/// already has one); [bookingId] lets the dialog ask the server what a
/// cancellation would refund right now.
Future<bool> showCancelBookingConfirmDialog(
  BuildContext context, {
  required String bookingStatus,
  required String bookingId,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => _CancelBookingConfirmDialog(
      headline: _headlineForStatus(bookingStatus),
      bookingId: bookingId,
    ),
  );
  return confirmed == true;
}

class _CancelBookingConfirmDialog extends StatefulWidget {
  final String headline;
  final String bookingId;

  const _CancelBookingConfirmDialog({
    required this.headline,
    required this.bookingId,
  });

  @override
  State<_CancelBookingConfirmDialog> createState() =>
      _CancelBookingConfirmDialogState();
}

class _CancelBookingConfirmDialogState
    extends State<_CancelBookingConfirmDialog> {
  /// Server-stated refund consequence. Null until (and unless) the preview
  /// call answers — refund percentages are admin-configurable, so the dialog
  /// never asserts a figure of its own. The dialog opens immediately and this
  /// line simply appears if real data lands in time.
  String? _refundLine;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    final p = await BookingService.cancellationPreview(widget.bookingId);
    if (!mounted || p == null) return;
    setState(() => _refundLine = _refundLineFrom(p));
  }

  /// Same decision tree (and sentences) as CancelRideScreen's refund banner,
  /// so the dialog can't promise one consequence and the next screen another.
  String _refundLineFrom(Map<String, dynamic> p) {
    final bool wasPaid = p['wasPaid'] == true;
    final num pct = (p['refundPercentage'] as num?) ?? 0;
    final num amount = (p['refundAmount'] as num?) ?? 0;

    if (!wasPaid) return 'No payment has been taken for this booking.';
    if (pct <= 0) return 'Cancelling now is not refundable.';
    if (amount > 0) {
      return 'You will be refunded ₹${amount.toStringAsFixed(0)} '
          '(${pct.toStringAsFixed(0)}% of the fare).';
    }
    return 'A refund of ${pct.toStringAsFixed(0)}% applies to this cancellation.';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      // Material 3 otherwise tints the "white" card with the theme colour.
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _kRed, width: 2.5),
              ),
              child: const Icon(Icons.close, color: _kRed, size: 32),
            ),
            const SizedBox(height: 18),
            Text(
              widget.headline,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Are you sure you still want to cancel your Movezy delivery?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: Colors.grey.shade600,
              ),
            ),
            if (_refundLine != null) ...[
              const SizedBox(height: 8),
              Text(
                _refundLine!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.35,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: _kGreen, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      // scaleDown, not wrap: two-line labels clip in a 46px
                      // button on narrow screens.
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'No, Continue',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kGreen,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kRed,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Yes, Cancel Ride',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
