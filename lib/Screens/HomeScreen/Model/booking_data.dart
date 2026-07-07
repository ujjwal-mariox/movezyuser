import 'package:movezy_user_app/Screens/HomeScreen/Model/home_page_model.dart';
import 'package:movezy_user_app/Services/booking_service.dart';

/// Data object passed through the booking flow.
/// Accumulates data at each step so downstream screens know what was selected.
class BookingData {
  /// The vehicle selected on the home screen (null if user entered via pickup bar)
  final HomeVehicleType? selectedVehicle;

  /// "WITHIN_CITY" or "OUTSTATION" (null if service sheet was skipped)
  final String? serviceType;

  /// Pickup address text
  String? pickupAddress;

  /// Drop address text
  String? dropAddress;

  /// Pickup coordinates
  double? pickupLat;
  double? pickupLng;

  /// Drop coordinates
  double? dropLat;
  double? dropLng;

  /// Goods category (e.g. "Boxes /Parcels", "Furniture")
  String? goodsCategory;

  /// Goods type ID from the backend
  String? goodsTypeId;

  /// Goods type category enum from backend: "PERSONAL" or "BUSINESS"
  String? goodsTypeCategory;

  /// All available vehicles (for the vehicle selection screen)
  final List<HomeVehicleType> allVehicles;

  /// Selected add-on service IDs
  List<String> selectedAddonIds;

  /// Applied promo code
  String? promoCode;

  /// Promo discount amount
  double promoDiscount;

  /// Fare estimate from backend
  FareEstimate? fareEstimate;

  /// Payment method: WALLET, CARD, UPI, CASH, etc.
  String paymentMethod;

  /// Goods description
  String? goodsDescription;

  BookingData({
    this.selectedVehicle,
    this.serviceType,
    this.pickupAddress,
    this.dropAddress,
    this.pickupLat,
    this.pickupLng,
    this.dropLat,
    this.dropLng,
    this.goodsCategory,
    this.goodsTypeId,
    this.goodsTypeCategory,
    this.allVehicles = const [],
    this.selectedAddonIds = const [],
    this.promoCode,
    this.promoDiscount = 0,
    this.fareEstimate,
    this.paymentMethod = 'CASH',
    this.goodsDescription,
  });

  /// Whether a vehicle has already been chosen (via home screen tap)
  bool get hasVehicle => selectedVehicle != null;

  /// Create a copy with updated fields
  BookingData copyWith({
    HomeVehicleType? selectedVehicle,
    String? serviceType,
    String? pickupAddress,
    String? dropAddress,
    double? pickupLat,
    double? pickupLng,
    double? dropLat,
    double? dropLng,
    String? goodsCategory,
    String? goodsTypeId,
    String? goodsTypeCategory,
    List<HomeVehicleType>? allVehicles,
    List<String>? selectedAddonIds,
    String? promoCode,
    double? promoDiscount,
    FareEstimate? fareEstimate,
    String? paymentMethod,
    String? goodsDescription,
  }) {
    return BookingData(
      selectedVehicle: selectedVehicle ?? this.selectedVehicle,
      serviceType: serviceType ?? this.serviceType,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropAddress: dropAddress ?? this.dropAddress,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropLat: dropLat ?? this.dropLat,
      dropLng: dropLng ?? this.dropLng,
      goodsCategory: goodsCategory ?? this.goodsCategory,
      goodsTypeId: goodsTypeId ?? this.goodsTypeId,
      goodsTypeCategory: goodsTypeCategory ?? this.goodsTypeCategory,
      allVehicles: allVehicles ?? this.allVehicles,
      selectedAddonIds: selectedAddonIds ?? this.selectedAddonIds,
      promoCode: promoCode ?? this.promoCode,
      promoDiscount: promoDiscount ?? this.promoDiscount,
      fareEstimate: fareEstimate ?? this.fareEstimate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      goodsDescription: goodsDescription ?? this.goodsDescription,
    );
  }
}
