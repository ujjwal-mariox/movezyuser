import 'package:flutter/material.dart';
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
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

      // Require real coordinates. These defaulted to fixed Delhi/Noida coords,
      // so with unresolved addresses every vehicle's price/ETA below was quoted
      // for a ~20 km Delhi→Noida trip the user never asked for.
      final pLat = widget.bookingData.pickupLat;
      final pLng = widget.bookingData.pickupLng;
      final dLat = widget.bookingData.dropLat;
      final dLng = widget.bookingData.dropLng;
      if (pLat == null || pLng == null || dLat == null || dLng == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error =
                "We couldn't pin your pickup or drop location. Go back and choose it on the map.";
          });
        }
        return;
      }

      final options = await BookingService.getVehicleOptions(
        pickup: {'lat': pLat, 'lng': pLng},
        drop: {'lat': dLat, 'lng': dLng},
        // Same stops Review Booking prices with, so the figure on the card is
        // the figure the customer ends up paying.
        stops: widget.bookingData.stops,
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
          // Show the error and let them retry, rather than falling back to a
          // list priced at each vehicle's base fare. That fallback quoted ₹149
          // for a trip that bills ₹2,887 — it ignores distance entirely — and
          // badged whichever vehicle happened to be first as "Recommended",
          // a recommendation nothing had computed.
          _error = "We couldn't load vehicle prices. Check your connection and try again.";
          _isLoading = false;
        });
      }
    }
  }



  /// Convert selected VehicleOption back to HomeVehicleType for downstream screens
  HomeVehicleType _toHomeVehicleType(VehicleOption opt) {
    return HomeVehicleType(
      id: opt.vehicleTypeId,
      name: opt.name,
      description: opt.description,
      maxWeightKg: opt.maxWeightKg,
      // Dimensions too — dropping them meant LoadAssist's "Load space" line
      // (gated on lengthFt > 0) could never render on this path.
      lengthFt: opt.lengthFt,
      breadthFt: opt.breadthFt,
      heightFt: opt.heightFt,
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
          // ─── Orange location header (per the design) ───
          _locationHeader(),

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
                          // The design has no distance/duration strip here —
                          // each row carries its own "Kg. mins" subtitle.

                          // Recommended
                          if (recommended.isNotEmpty) ...[
                            Text("Recommended",
                                style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade600)),
                            const SizedBox(height: 12),
                            ...recommended.map((opt) {
                              final idx = _options.indexOf(opt);
                              return _buildVehicleCard(opt, idx, isRecommended: true);
                            }),
                          ],

                          // Others — flat rows separated by hairlines, not cards
                          if (others.isNotEmpty) ...[
                            const SizedBox(height: 22),
                            Text("Others",
                                style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade600)),
                            const SizedBox(height: 4),
                            ...others.asMap().entries.map((e) {
                              final opt = e.value;
                              final idx = _options.indexOf(opt);
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildVehicleCard(opt, idx),
                                  if (e.key != others.length - 1)
                                    const Divider(
                                        height: 1,
                                        thickness: 1.5,
                                        color: Color(0xFFFCEBE0)),
                                ],
                              );
                            }),
                          ],
                        ],
                      ),
          ),

          // Bottom button
          Padding(
            // 24 is the design's gap; the device's real bottom inset (gesture
            // bar / nav buttons) is added to it so the "Next / Select a
            // vehicle" button is never underneath the system UI.
            padding: EdgeInsets.fromLTRB(
                16, 0, 16, 24 + MediaQuery.of(context).padding.bottom),
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

  /// Orange header: "Add Location to Proceed" + pickup/drop + ADD STOP.
  ///
  /// Editing happens on the address screen, so the fields and ADD STOP pop back
  /// there rather than duplicating that editor — stops are already modelled
  /// (BookingData.stops) and are sent on create, so this isn't a dead control.
  Widget _locationHeader() {
    final stops = widget.bookingData.stops;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 14,
          left: 16,
          right: 16,
          bottom: 18),
      decoration: BoxDecoration(
        color: AppColors.appColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.arrow_back_ios,
                      color: Colors.white, size: 18),
                ),
              ),
              Expanded(
                child: Text(
                  'Add Location to Proceed',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _addressRow(
            icon: Icons.my_location,
            iconColor: const Color(0xFF12B39A),
            text: widget.bookingData.pickupAddress ?? 'Pickup location',
            trailing: Icon(Icons.gps_fixed,
                size: 20, color: AppColors.appColor),
          ),
          _dashedConnector(),
          // Any intermediate stops sit between pickup and drop, in order.
          for (final s in stops) ...[
            _addressRow(
              icon: Icons.adjust,
              iconColor: const Color(0xFF12B39A),
              text: (s['address'] ?? 'Stop').toString(),
            ),
            _dashedConnector(),
          ],
          _addressRow(
            icon: Icons.place_outlined,
            iconColor: const Color(0xFF12B39A),
            text: widget.bookingData.dropAddress ?? 'Drop location',
          ),
          const SizedBox(height: 12),
          Center(
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('ADD STOP',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressRow({
    required IconData icon,
    required Color iconColor,
    required String text,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 10),
          // Expanded so a long address ellipsizes instead of overflowing the
          // header — as a bare Row child it would take unbounded width.
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF3D3D3D)),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The dotted link between pickup, stops and drop.
  Widget _dashedConnector() {
    return Padding(
      padding: const EdgeInsets.only(left: 22),
      child: Column(
        children: List.generate(
          3,
          (_) => Container(
            width: 2,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 1.5),
            color: Colors.white,
          ),
        ),
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

    // The Recommended entry keeps its card shape, but the orange border and
    // peach fill mean "selected" and nothing else. They used to be tied to
    // isRecommended too, so once the user tapped another vehicle two rows
    // looked selected at once and the recommended one could never visually
    // deselect.
    final boxed = isRecommended || isSelected;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: EdgeInsets.only(bottom: boxed ? 12 : 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF9F5) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: AppColors.appColor, width: 1.5)
              : isRecommended
                  // Soft outline: still reads as a card, clearly not selected.
                  ? Border.all(color: const Color(0xFFF3DACB), width: 1.2)
                  : null,
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
                      // Expanded: as a bare Row child this got unbounded width, so a
                      // long server-driven vehicle name could never ellipsize.
                      Expanded(
                        child: Text(
                          option.name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 6),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Design reads "50 Kg. 15 mins" — capacity in grey, the ETA
                  // in orange, on one line.
                  RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: TextStyle(
                          fontSize: 12.5, color: Colors.grey.shade600),
                      children: [
                        TextSpan(text: option.capacityLabel),
                        if (option.durationLabel.isNotEmpty &&
                            option.estimatedDuration > 0) ...[
                          const TextSpan(text: '. '),
                          TextSpan(
                            text: option.durationLabel,
                            style: TextStyle(
                                color: AppColors.appColor,
                                fontWeight: FontWeight.w600),
                          ),
                        ] else ...[
                          TextSpan(
                            text:
                                '. ${option.allowIntraCity && option.allowInterCity ? 'City & Outstation' : option.allowIntraCity ? 'Within City' : 'Outstation'}',
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            // Price only — the design puts the ETA in the subtitle, not here.
            Text(
              "₹ ${hasEstimatedFare ? option.estimatedFare.toInt() : option.baseFare.toInt()}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
