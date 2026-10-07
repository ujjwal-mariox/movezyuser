import 'package:movezy_user_app/Screens/HomeScreen/Model/booking_data.dart';
import 'package:movezy_user_app/Services/booking_service.dart';
import 'package:movezy_user_app/Services/vehicle_availability.dart';

Future<VehicleOptionsResult> fetchBookingVehicleOptions(
  BookingData data, {
  bool eligibilityOnly = false,
}) {
  if (!validBookingCoordinates(data.pickupLat, data.pickupLng) ||
      !validBookingCoordinates(data.dropLat, data.dropLng)) {
    throw const VehicleOptionsException(
      'INVALID_LOCATIONS',
      'Choose both pickup and drop locations on the map.',
      retryable: false,
    );
  }
  if (data.stops.any((s) => !validBookingCoordinates(s['lat'], s['lng']))) {
    throw const VehicleOptionsException(
      'INVALID_LOCATIONS',
      'Choose every stop on the map, or remove the incomplete stop.',
      retryable: false,
    );
  }
  return BookingService.getVehicleOptionsResult(
    pickup: {
      'lat': data.pickupLat,
      'lng': data.pickupLng,
      if (data.pickupCity != null) 'city': data.pickupCity,
    },
    drop: {'lat': data.dropLat, 'lng': data.dropLng},
    stops: data.stops,
    serviceType: data.serviceType,
    goodsTypeId: data.goodsTypeId,
    preferredVehicleTypeId: data.selectedVehicle?.id,
    eligibilityOnly: eligibilityOnly,
  );
}
