import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/Screens/HomeScreen/Model/booking_data.dart';
import 'package:movezy_user_app/Screens/HomeScreen/Model/home_page_model.dart';
import 'package:movezy_user_app/Screens/LoadAssistScreen/load_assist_screen.dart';
import 'package:movezy_user_app/Services/booking_service.dart';
import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';

/// Vehicle selection screen with smart recommendations.
/// Calls the backend to get fare estimates for ALL vehicle types
/// and displays them sorted with the best match marked as "Recommended".
class VehicleSelectionScreen extends StatefulWidget {
  final BookingData bookingData;

  const VehicleSelectionScreen({super.key, required this.bookingData});

  @override
  State<VehicleSelectionScreen> createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
  List<VehicleOption> _options = [];
  bool _isLoading = true;
  String? _error;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _fetchVehicleOptions();
  }

  Future<void> _fetchVehicleOptions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      debugPrint('[VehicleSelection] Fetching options. goodsTypeId=${widget.bookingData.goodsTypeId}, serviceType=${widget.bookingData.serviceType}');
      debugPrint('[VehicleSelection] allVehicles count=${widget.bookingData.allVehicles.length}');
      for (final v in widget.bookingData.allVehicles) {
        debugPrint('[VehicleSelection]   allVehicle: id=${v.id} name=${v.name}');
      }

      final options = await BookingService.getVehicleOptions(
        pickup: {
          'lat': widget.bookingData.pickupLat ?? 28.6139,
          'lng': widget.bookingData.pickupLng ?? 77.2090,
        },
        drop: {
          'lat': widget.bookingData.dropLat ?? 28.5355,
          'lng': widget.bookingData.dropLng ?? 77.3910,
        },
        serviceType: widget.bookingData.serviceType,
        goodsTypeId: widget.bookingData.goodsTypeId,
      );

      debugPrint('[VehicleSelection] API returned ${options.length} options');
      for (final o in options) {
        debugPrint('[VehicleSelection]   option: id=${o.vehicleTypeId} name=${o.name} fare=${o.estimatedFare} recommended=${o.isRecommended}');
      }

      if (mounted) {
        setState(() {
          _options = options;
          _isLoading = false;
          // Auto-select the recommended one
          final recIdx = options.indexWhere((o) => o.isRecommended);
          if (recIdx >= 0) _selectedIndex = recIdx;
        });
      }
    } catch (e) {
      debugPrint('[VehicleSelection] API error: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        // Fallback: use static vehicle list from bookingData
        _useFallbackVehicles();
      }
    }
  }

  /// Fallback when API call fails — use the vehicle list already in bookingData
  void _useFallbackVehicles() {
    final vehicles = widget.bookingData.allVehicles;
    if (vehicles.isEmpty) return;

    final fallback = vehicles.map((v) => VehicleOption(
      vehicleTypeId: v.id,
      name: v.name,
      description: v.description,
      image: v.image,
      icon: v.icon,
      maxWeightKg: v.maxWeightKg,
      lengthFt: v.lengthFt,
      breadthFt: v.breadthFt,
      heightFt: v.heightFt,
      baseFare: v.baseFare,
      estimatedFare: v.baseFare,
      distanceKm: 0,
      estimatedDuration: 0,
      allowIntraCity: v.allowIntraCity,
      allowInterCity: v.allowInterCity,
      sortOrder: v.sortOrder,
      isRecommended: false,
    )).toList();

    // Mark first as recommended
    if (fallback.isNotEmpty) {
      fallback[0] = VehicleOption(
        vehicleTypeId: fallback[0].vehicleTypeId,
        name: fallback[0].name,
        description: fallback[0].description,
        image: fallback[0].image,
        icon: fallback[0].icon,
        maxWeightKg: fallback[0].maxWeightKg,
        lengthFt: fallback[0].lengthFt,
        breadthFt: fallback[0].breadthFt,
        heightFt: fallback[0].heightFt,
        baseFare: fallback[0].baseFare,
        estimatedFare: fallback[0].estimatedFare,
        distanceKm: fallback[0].distanceKm,
        estimatedDuration: fallback[0].estimatedDuration,
        allowIntraCity: fallback[0].allowIntraCity,
        allowInterCity: fallback[0].allowInterCity,
        sortOrder: fallback[0].sortOrder,
        isRecommended: true,
      );
    }

    setState(() {
      _options = fallback;
      _error = null;
      _selectedIndex = 0;
    });
  }

  /// Convert selected VehicleOption back to HomeVehicleType for downstream screens
  HomeVehicleType _toHomeVehicleType(VehicleOption opt) {
    return HomeVehicleType(
      id: opt.vehicleTypeId,
      name: opt.name,
      description: opt.description,
      maxWeightKg: opt.maxWeightKg,
      baseFare: opt.baseFare,
      perKmRate: 0,
      perMinuteRate: 0,
      image: opt.image,
      icon: opt.icon,
      sortOrder: opt.sortOrder,
      allowIntraCity: opt.allowIntraCity,
      allowInterCity: opt.allowInterCity,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Separate recommended from others
    final recommended = _options.where((o) => o.isRecommended).toList();
    final others = _options.where((o) => !o.isRecommended).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // App bar
          commonAppBar(
            height: 105,
            context: context,
            child: Container(
              padding: const EdgeInsets.only(top: 50),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.only(left: 16),
                      width: 40, height: 35,
                      alignment: Alignment.center,
                      child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text("Select Vehicle", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                  const Spacer(),
                ],
              ),
            ),
          ),

          // Location header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            color: HexColor("#E7F7F5"),
            child: Column(
              children: [
                // Pickup → Drop display
                Row(
                  children: [
                    // Pickup/Drop indicators
                    Column(
                      children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.appColor, width: 1.5),
                          ),
                          child: Icon(Icons.location_on, color: AppColors.appColor, size: 16),
                        ),
                        Container(width: 1.5, height: 24, color: Colors.grey.shade400),
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green, width: 1.5),
                          ),
                          child: const Icon(Icons.flag, color: Colors.green, size: 16),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Address text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.bookingData.pickupAddress ?? 'Pickup',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.bookingData.dropAddress ?? 'Drop',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Vehicle list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _options.isEmpty
                    ? _buildError()
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        children: [
                          // Distance & duration info
                          if (_options.isNotEmpty && _options.first.distanceKm > 0) ...[
                            Row(
                              children: [
                                Icon(Icons.route, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  "${_options.first.distanceKm.toStringAsFixed(1)} km",
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  _options.first.durationLabel,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Recommended
                          if (recommended.isNotEmpty) ...[
                            const Text("Recommended", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
                            const SizedBox(height: 10),
                            ...recommended.map((opt) {
                              final idx = _options.indexOf(opt);
                              return _buildVehicleCard(opt, idx, isRecommended: true);
                            }),
                          ],

                          // Others
                          if (others.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            const Text("Others", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
                            const SizedBox(height: 10),
                            ...others.map((opt) {
                              final idx = _options.indexOf(opt);
                              return _buildVehicleCard(opt, idx);
                            }),
                          ],
                        ],
                      ),
          ),

          // Bottom button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedIndex != null ? AppColors.appColor : Colors.grey.shade400,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _selectedIndex != null
                    ? () {
                        final selected = _options[_selectedIndex!];
                        final vehicle = _toHomeVehicleType(selected);
                        final updatedData = widget.bookingData.copyWith(selectedVehicle: vehicle);
                        pushTo(context, LoadAssistScreen(bookingData: updatedData));
                      }
                    : null,
                child: Text(
                  _selectedIndex != null ? "Next" : "Select a vehicle",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text("Failed to load vehicles", style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _fetchVehicleOptions,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.appColor),
            child: const Text("Retry", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(VehicleOption option, int index, {bool isRecommended = false}) {
    final isSelected = _selectedIndex == index;
    final hasEstimatedFare = option.estimatedFare > 0;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.appColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.appColor.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            // Vehicle image
            _vehicleImage(option),
            const SizedBox(width: 14),

            // Vehicle info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        option.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 6),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "${option.capacityLabel}${option.dimensionsLabel.isNotEmpty ? ' • ${option.dimensionsLabel}' : ''}. ${option.durationLabel.isNotEmpty && option.estimatedDuration > 0 ? option.durationLabel : (option.allowIntraCity && option.allowInterCity ? 'City & Outstation' : option.allowIntraCity ? 'Within City' : 'Outstation')}",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "₹ ${hasEstimatedFare ? option.estimatedFare.toInt() : option.baseFare.toInt()}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                if (hasEstimatedFare && option.estimatedDuration > 0)
                  Text(
                    option.durationLabel,
                    style: TextStyle(fontSize: 11, color: AppColors.appColor, fontWeight: FontWeight.w500),
                  )
                else
                  Text(
                    "base fare",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _vehicleImage(VehicleOption option) {
    final imageUrl = option.image ?? option.icon;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        ApiUrls.imageProxyUrl(imageUrl),
        width: 60, height: 45,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Icon(Icons.local_shipping, size: 40, color: AppColors.appColor),
      );
    }
    return Icon(Icons.local_shipping, size: 40, color: AppColors.appColor);
  }
}
