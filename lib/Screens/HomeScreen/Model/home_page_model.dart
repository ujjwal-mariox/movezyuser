class HomeVehicleType {
  final String id;
  final String name;
  final String? description;
  final double maxWeightKg;
  final double lengthFt;
  final double breadthFt;
  final double heightFt;
  final double baseFare;
  final double perKmRate;
  final double perMinuteRate;
  final String? image;
  final String? icon;
  final int sortOrder;
  final bool allowIntraCity;
  final bool allowInterCity;
  final double minRangeKm;
  final double maxRangeKm;

  HomeVehicleType({
    required this.id,
    required this.name,
    this.description,
    required this.maxWeightKg,
    this.lengthFt = 0,
    this.breadthFt = 0,
    this.heightFt = 0,
    required this.baseFare,
    required this.perKmRate,
    required this.perMinuteRate,
    this.image,
    this.icon,
    this.sortOrder = 0,
    this.allowIntraCity = true,
    this.allowInterCity = false,
    this.minRangeKm = 1,
    this.maxRangeKm = 100,
  });

  factory HomeVehicleType.fromJson(Map<String, dynamic> json) {
    return HomeVehicleType(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      maxWeightKg: (json['maxWeightKg'] ?? 0).toDouble(),
      lengthFt: (json['lengthFt'] ?? 0).toDouble(),
      breadthFt: (json['breadthFt'] ?? 0).toDouble(),
      heightFt: (json['heightFt'] ?? 0).toDouble(),
      baseFare: (json['baseFare'] ?? 0).toDouble(),
      perKmRate: (json['perKmRate'] ?? 0).toDouble(),
      perMinuteRate: (json['perMinuteRate'] ?? 0).toDouble(),
      image: json['image'],
      icon: json['icon'],
      sortOrder: json['sortOrder'] ?? 0,
      allowIntraCity: json['allowIntraCity'] ?? true,
      allowInterCity: json['allowInterCity'] ?? false,
      minRangeKm: (json['minRangeKm'] ?? 1).toDouble(),
      maxRangeKm: (json['maxRangeKm'] ?? 100).toDouble(),
    );
  }

  /// Formatted capacity string e.g. "10kg, 2 Feet" or "1.2 Ton, 7 Feet"
  String get capacityLabel {
    if (maxWeightKg >= 1000) {
      final tons = (maxWeightKg / 1000).toStringAsFixed(1);
      return "$tons Ton";
    }
    return "${maxWeightKg.toInt()}kg";
  }
}

class PromoBanner {
  final String code;
  final String description;
  final String discountType;
  final double discountValue;
  final double? maxDiscount;
  final double minOrderValue;

  PromoBanner({
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.maxDiscount,
    required this.minOrderValue,
  });

  factory PromoBanner.fromJson(Map<String, dynamic> json) {
    return PromoBanner(
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      discountType: json['discountType'] ?? 'FIXED',
      discountValue: (json['discountValue'] ?? 0).toDouble(),
      maxDiscount: json['maxDiscount']?.toDouble(),
      minOrderValue: (json['minOrderValue'] ?? 0).toDouble(),
    );
  }

  /// e.g. "Flat 20% Off" or "Flat ₹50 Off"
  String get offerText {
    if (discountType == 'PERCENTAGE') {
      return "Flat ${discountValue.toInt()}% Off";
    }
    return "Flat ₹${discountValue.toInt()} Off";
  }
}

class HomePageData {
  final List<HomeVehicleType> vehicleTypes;
  final List<PromoBanner> promoBanners;

  HomePageData({
    required this.vehicleTypes,
    required this.promoBanners,
  });

  factory HomePageData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return HomePageData(
      vehicleTypes: (data['vehicleTypes'] as List? ?? [])
          .map((v) => HomeVehicleType.fromJson(v))
          .toList(),
      promoBanners: (data['promoBanners'] as List? ?? [])
          .map((p) => PromoBanner.fromJson(p))
          .toList(),
    );
  }
}
