import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';

/// Porter-style order status timeline stepper.
///
/// Usage:
/// ```dart
/// OrderStatusTimeline(currentStatus: 'ASSIGNED')
/// ```
class OrderStatusTimeline extends StatelessWidget {
  final String currentStatus;
  final String? scheduledPickupTime;

  const OrderStatusTimeline({
    super.key,
    required this.currentStatus,
    this.scheduledPickupTime,
  });

  /// The single status → words mapping for the app.
  ///
  /// Status keys are the values `booking.status` actually takes (booking.model
  /// enum: DRAFT, SEARCHING, ASSIGNED, DRIVER_ARRIVED, PICKED, IN_PROGRESS,
  /// COMPLETED, CANCELLED). The first step used to be keyed to "CONFIRMED",
  /// which is not one of them.
  ///
  /// Each stage carries ONE string, printed both as the step label here and as
  /// the status headline by [labelFor]. That is deliberate: the step keyed to
  /// DRIVER_ARRIVED used to read "On the way to pickup" while the headline on
  /// the same screen said the driver had arrived, and the step keyed to
  /// ASSIGNED read "Partner assigned" while the headline said they were on
  /// their way — the labels were shifted one stage off the status they mapped
  /// to. Sharing the string makes that class of disagreement impossible.
  static const List<OrderStage> stages = [
    OrderStage('SEARCHING', 'Finding a driver', Icons.search),
    OrderStage('ASSIGNED', 'Driver on the way to pickup', Icons.local_shipping),
    OrderStage('DRIVER_ARRIVED', 'Driver arrived at pickup', Icons.person_pin),
    OrderStage('PICKED', 'Goods picked up, in transit', Icons.moving),
    OrderStage('COMPLETED', 'Delivered', Icons.done_all),
  ];

  /// A cancelled booking has no stage — it left the flow.
  static const String cancelledLabel = 'Order has been cancelled';

  /// Index into [stages] for a backend status; -1 when cancelled.
  static int stepIndexFor(String status) {
    if (status == 'CANCELLED') return -1;
    // IN_PROGRESS shares the PICKED stage — the goods are aboard either way.
    final key = status == 'IN_PROGRESS' ? 'PICKED' : status;
    final i = stages.indexWhere((s) => s.status == key);
    // Anything unrecognised (DRAFT, or a status added later) sits at the start
    // rather than being given a stage it hasn't reached.
    return i < 0 ? 0 : i;
  }

  /// The one place a booking status is turned into words. Any screen printing a
  /// status headline alongside this widget must use it, so the headline and the
  /// highlighted step always say the same thing.
  static String labelFor(String status) {
    if (status == 'CANCELLED') return cancelledLabel;
    return stages[stepIndexFor(status)].label;
  }

  @override
  Widget build(BuildContext context) {
    if (currentStatus == 'CANCELLED') {
      return _cancelledWidget();
    }

    final idx = stepIndexFor(currentStatus);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (scheduledPickupTime != null && scheduledPickupTime!.isNotEmpty) ...[
            Text(
              "Order pickup by: $scheduledPickupTime",
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
          ],
          for (int i = 0; i < stages.length; i++) ...[
            _buildStep(i, idx),
            if (i < stages.length - 1) _buildConnector(i, idx),
          ],
        ],
      ),
    );
  }

  Widget _buildStep(int stepIndex, int activeIndex) {
    final step = stages[stepIndex];
    final isCompleted = stepIndex <= activeIndex;
    final isCurrent = stepIndex == activeIndex;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Circle indicator
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? HexColor("#25AA59") : Colors.grey.shade200,
            border: isCurrent
                ? Border.all(color: HexColor("#25AA59"), width: 2.5)
                : null,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Icon(step.icon, color: Colors.grey.shade400, size: 16),
          ),
        ),
        const SizedBox(width: 14),
        // Step label
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: isCompleted ? Colors.black87 : Colors.grey.shade500,
                ),
              ),
              if (isCurrent && stepIndex == 0)
                const SizedBox(height: 2),
            ],
          ),
        ),
        // "+N" badge for collapsed steps
        if (stepIndex == 0 && activeIndex == 0 && stages.length > 2)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "+${stages.length - 2}",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConnector(int stepIndex, int activeIndex) {
    final isCompleted = stepIndex < activeIndex;
    return Padding(
      padding: const EdgeInsets.only(left: 15),
      child: Container(
        width: 2,
        height: 28,
        decoration: BoxDecoration(
          color: isCompleted ? HexColor("#25AA59") : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _cancelledWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.cancel, color: Colors.red.shade400, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              cancelledLabel,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One stage of a booking's life, keyed by the backend status that puts the
/// booking in it. See [OrderStatusTimeline.stages].
class OrderStage {
  /// Value of `booking.status` this stage represents.
  final String status;

  /// The words for this stage — used for the stepper row AND for the status
  /// headline callers print elsewhere on the same screen.
  final String label;

  final IconData icon;
  const OrderStage(this.status, this.label, this.icon);
}
