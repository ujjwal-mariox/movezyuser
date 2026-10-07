import 'package:flutter/material.dart';
import 'package:movezy_user_app/Screens/HomeScreen/Model/booking_data.dart';
import 'package:movezy_user_app/Services/vehicle_availability.dart';

enum TripRecoveryAction {
  changeLocations,
  chooseVehicle,
  outstation,
  withinCity,
  retry,
}

String tripRecoveryLabel(TripRecoveryAction action) => switch (action) {
  TripRecoveryAction.changeLocations => 'Change locations',
  TripRecoveryAction.chooseVehicle => 'Choose another vehicle',
  TripRecoveryAction.outstation => 'Switch to Outstation',
  TripRecoveryAction.withinCity => 'Switch to Within City',
  TripRecoveryAction.retry => 'Try again',
};

BookingData applyTripRecovery(BookingData data, TripRecoveryAction action) =>
    data.copyWith(
      clearSelectedVehicle:
          action != TripRecoveryAction.retry &&
          action != TripRecoveryAction.changeLocations,
      clearFareEstimate: true,
      serviceType: action == TripRecoveryAction.outstation
          ? 'OUTSTATION'
          : action == TripRecoveryAction.withinCity
          ? 'WITHIN_CITY'
          : data.serviceType,
    );

List<TripRecoveryAction> tripRecoveryActions(
  VehicleAvailability availability,
  String? serviceType,
) => [
  TripRecoveryAction.changeLocations,
  if (availability.availableCount > 0 && availability.preferredUnavailable)
    TripRecoveryAction.chooseVehicle,
  if (serviceType != 'OUTSTATION' &&
      availability.outstationAvailableCount > 0 &&
      !availability.pricesUnavailable)
    TripRecoveryAction.outstation,
  if (serviceType == 'OUTSTATION' &&
      availability.withinCityAvailableCount > 0 &&
      !availability.pricesUnavailable)
    TripRecoveryAction.withinCity,
  if (availability.code != 'DISTANCE_LIMIT' &&
      availability.preferredCode != 'DISTANCE_LIMIT' &&
      availability.preferredCode != 'OUTSTATION_TWO_WHEELER')
    TripRecoveryAction.retry,
];

/// Shared by the location preflight and the price screen, including compact phones.
class VehicleAvailabilityNotice extends StatelessWidget {
  final VehicleAvailability availability;
  final String? serviceType;
  final ValueChanged<TripRecoveryAction> onAction;
  const VehicleAvailabilityNotice({
    super.key,
    required this.availability,
    this.serviceType,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          availability.title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        Text(availability.explanation),
        if (availability.approximate) ...[
          const SizedBox(height: 8),
          const Text(
            'Distance is approximate while road routing is unavailable. It will be checked again before booking.',
          ),
        ],
        if (serviceType != 'OUTSTATION' &&
            availability.outstationAvailableCount > 0 &&
            !availability.pricesUnavailable) ...[
          const SizedBox(height: 8),
          const Text(
            'Outstation requires a larger vehicle. Two-wheelers are not available for Outstation trips.',
          ),
        ],
        const SizedBox(height: 10),
        for (final action in tripRecoveryActions(availability, serviceType))
          TextButton(
            onPressed: () => onAction(action),
            child: Text(tripRecoveryLabel(action)),
          ),
      ],
    ),
  );
}

Future<TripRecoveryAction?> showVehicleAvailabilityNotice(
  BuildContext context,
  VehicleAvailability availability,
  String? serviceType,
) => showDialog<TripRecoveryAction>(
  context: context,
  builder: (context) => AlertDialog(
    scrollable: true,
    content: VehicleAvailabilityNotice(
      availability: availability,
      serviceType: serviceType,
      onAction: (action) => Navigator.pop(context, action),
    ),
  ),
);
