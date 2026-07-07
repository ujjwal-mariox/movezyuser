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

  static const _steps = [
    _StepData('CONFIRMED', 'Order confirmed', Icons.check_circle),
    _StepData('ASSIGNED', 'Partner assigned', Icons.person_pin),
    _StepData('DRIVER_ARRIVED', 'On the way to pickup', Icons.local_shipping),
    _StepData('PICKED', 'In-transit', Icons.moving),
    _StepData('COMPLETED', 'Delivered', Icons.done_all),
  ];

  int get _currentIndex {
    // Map backend status to step index
    switch (currentStatus) {
      case 'SEARCHING':
        return 0; // Confirmed but searching
      case 'CONFIRMED':
        return 0;
      case 'ASSIGNED':
        return 1;
      case 'DRIVER_ARRIVED':
        return 2;
      case 'PICKED':
      case 'IN_PROGRESS':
        return 3;
      case 'COMPLETED':
        return 4;
      case 'CANCELLED':
        return -1;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentStatus == 'CANCELLED') {
      return _cancelledWidget();
    }

    final idx = _currentIndex;
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
          for (int i = 0; i < _steps.length; i++) ...[
            _buildStep(i, idx),
            if (i < _steps.length - 1) _buildConnector(i, idx),
          ],
        ],
      ),
    );
  }

  Widget _buildStep(int stepIndex, int activeIndex) {
    final step = _steps[stepIndex];
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
        if (stepIndex == 0 && activeIndex == 0 && _steps.length > 2)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "+${_steps.length - 2}",
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
              "Order has been cancelled",
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

class _StepData {
  final String status;
  final String label;
  final IconData icon;
  const _StepData(this.status, this.label, this.icon);
}
