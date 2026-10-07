class VehicleAvailability {
  final String code;
  final String? message;
  final double? distanceKm;
  final String distanceSource;
  final int availableCount;
  final int withinCityAvailableCount;
  final int outstationAvailableCount;
  final String? preferredCode;
  final String? preferredMessage;

  const VehicleAvailability({
    this.code = 'AVAILABLE',
    this.message,
    this.distanceKm,
    this.distanceSource = 'osrm',
    this.availableCount = 0,
    this.withinCityAvailableCount = 0,
    this.outstationAvailableCount = 0,
    this.preferredCode,
    this.preferredMessage,
  });

  factory VehicleAvailability.fromJson(Map<String, dynamic> json) {
    final preferred = json['preferredVehicle'] as Map?;
    return VehicleAvailability(
      code: json['code'] ?? 'NO_MATCHING_VEHICLES',
      message: json['message'],
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      distanceSource: json['distanceSource'] ?? 'osrm',
      availableCount: (json['availableCount'] as num?)?.toInt() ?? 0,
      withinCityAvailableCount:
          (json['withinCityAvailableCount'] as num?)?.toInt() ?? 0,
      outstationAvailableCount:
          (json['outstationAvailableCount'] as num?)?.toInt() ?? 0,
      preferredCode: preferred?['code'],
      preferredMessage: preferred?['message'],
    );
  }

  bool get preferredUnavailable =>
      preferredCode != null && preferredCode != 'AVAILABLE';
  bool get needsDecision => availableCount == 0 || preferredUnavailable;
  bool get pricesUnavailable => code == 'PRICES_UNAVAILABLE';
  bool get approximate =>
      distanceSource == 'straight' || distanceSource == 'mixed';

  String get explanation {
    final fallback =
        'No vehicles are available for these locations and service. Change locations or check again later.';
    if (preferredUnavailable && preferredMessage != null) {
      return availableCount == 0 &&
              message != null &&
              message != preferredMessage
          ? '$preferredMessage\n\n$message'
          : preferredMessage!;
    }
    return message ?? fallback;
  }

  String get title {
    if (pricesUnavailable || preferredCode == 'PRICE_UNAVAILABLE') {
      return 'Prices temporarily unavailable';
    }
    if (preferredCode == 'OUTSTATION_TWO_WHEELER') {
      return 'Choose an Outstation vehicle';
    }
    if (code == 'DISTANCE_LIMIT' || preferredCode == 'DISTANCE_LIMIT') {
      return 'Trip exceeds the vehicle distance limit';
    }
    return 'Vehicle unavailable for this trip';
  }
}

class VehicleOptionsException implements Exception {
  final String code;
  final String message;
  final bool retryable;
  const VehicleOptionsException(
    this.code,
    this.message, {
    this.retryable = true,
  });
  @override
  String toString() => message;
}

bool validBookingCoordinates(dynamic lat, dynamic lng) =>
    lat is num &&
    lng is num &&
    lat.isFinite &&
    lng.isFinite &&
    lat.abs() <= 90 &&
    lng.abs() <= 180 &&
    !(lat == 0 && lng == 0);
