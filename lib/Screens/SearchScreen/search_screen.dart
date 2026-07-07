import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:movezy_user_app/Screens/DeliveryCategoryScreen/delivery_category_screen.dart';
import 'package:movezy_user_app/Screens/HomeScreen/Model/booking_data.dart';
import 'package:movezy_user_app/Screens/MapPickerScreen/map_picker_screen.dart';
import 'package:movezy_user_app/Screens/SavedAddress/saved_address.dart';
import 'package:movezy_user_app/Screens/SavedAddress/Models/address_model.dart';
import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class SearchScreen extends StatefulWidget {
  /// Optional booking data — contains selected vehicle + service type
  /// if user came from a vehicle card tap. Null if user tapped the pickup bar.
  final BookingData? bookingData;

  const SearchScreen({super.key, this.bookingData});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropController = TextEditingController();

  double? _pickupLat, _pickupLng;
  double? _dropLat, _dropLng;
  bool _locatingPickup = false;

  List<dynamic> _recentDeliveries = [];
  bool _loadingRecent = true;

  // Popular landmarks / areas (static for now, can be API-driven later)
  static const List<Map<String, String>> _popularPlaces = [
    {'name': 'Railway Station', 'area': 'Central hub • frequently used'},
    {'name': 'Airport Terminal', 'area': 'Domestic & International'},
    {'name': 'City Bus Stand', 'area': 'Main bus terminal'},
    {'name': 'Industrial Area', 'area': 'Warehouses & factories'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.bookingData?.pickupAddress != null) {
      _pickupController.text = widget.bookingData!.pickupAddress!;
      _pickupLat = widget.bookingData!.pickupLat;
      _pickupLng = widget.bookingData!.pickupLng;
    }
    if (widget.bookingData?.dropAddress != null) {
      _dropController.text = widget.bookingData!.dropAddress!;
      _dropLat = widget.bookingData!.dropLat;
      _dropLng = widget.bookingData!.dropLng;
    }
    _fetchRecentDeliveries();
  }

  Future<void> _fetchRecentDeliveries() async {
    try {
      final token = Prefs.getString('token');
      if (token.isEmpty) {
        if (mounted) setState(() => _loadingRecent = false);
        return;
      }
      final response = await http.get(
        Uri.parse('${ApiUrls.userBookingsUrl}?page=1&limit=3'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List bookings = json['data']?['bookings'] ?? [];
        if (mounted) setState(() { _recentDeliveries = bookings; _loadingRecent = false; });
      } else {
        if (mounted) setState(() => _loadingRecent = false);
      }
    } catch (e) {
      debugPrint('Fetch recent deliveries error: $e');
      if (mounted) setState(() => _loadingRecent = false);
    }
  }

  /// One-tap reorder: pre-fill pickup & drop from a past booking
  void _reorderBooking(dynamic order) {
    final pickup = order['pickup'];
    final drop = order['drop'];
    if (pickup != null) {
      setState(() {
        _pickupController.text = pickup['address'] ?? '';
        _pickupLat = (pickup['lat'] as num?)?.toDouble();
        _pickupLng = (pickup['lng'] as num?)?.toDouble();
      });
    }
    if (drop != null) {
      setState(() {
        _dropController.text = drop['address'] ?? '';
        _dropLat = (drop['lat'] as num?)?.toDouble();
        _dropLng = (drop['lng'] as num?)?.toDouble();
      });
    }
    // Auto-proceed
    _proceedToCategory();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    super.dispose();
  }

  /// Open map picker for pickup or drop
  Future<void> _openMapPicker({required bool isPickup}) async {
    final result = await Navigator.push<MapPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          title: isPickup ? 'Pick Pickup Location' : 'Pick Drop Location',
          initialLocation: isPickup
              ? (_pickupLat != null ? LatLng(_pickupLat!, _pickupLng!) : null)
              : (_dropLat != null ? LatLng(_dropLat!, _dropLng!) : null),
          initialAddress: isPickup
              ? _pickupController.text
              : _dropController.text,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (isPickup) {
          _pickupController.text = result.address;
          _pickupLat = result.lat;
          _pickupLng = result.lng;
        } else {
          _dropController.text = result.address;
          _dropLat = result.lat;
          _dropLng = result.lng;
        }
      });
    }
  }

  /// Open the saved-address picker, then ask whether the chosen address should
  /// fill the pickup or drop field, and populate it (address + coordinates).
  Future<void> _pickFromSavedAddresses() async {
    final selected = await Navigator.push<AddressModel>(
      context,
      MaterialPageRoute(
        builder: (_) => const SavedAddressScreen(selectionMode: true),
      ),
    );
    if (selected == null || !mounted) return;

    // Ask which field this address is for.
    final useForPickup = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text('Use this address as',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.my_location, color: AppColors.appColor),
              title: const Text('Pickup location'),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              leading: Icon(Icons.location_on, color: AppColors.appColor),
              title: const Text('Drop location'),
              onTap: () => Navigator.pop(context, false),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (useForPickup == null || !mounted) return;

    final label = _formatSavedAddress(selected);
    setState(() {
      if (useForPickup) {
        _pickupController.text = label;
        _pickupLat = selected.latitude;
        _pickupLng = selected.longitude;
      } else {
        _dropController.text = label;
        _dropLat = selected.latitude;
        _dropLng = selected.longitude;
      }
    });
  }

  String _formatSavedAddress(AddressModel a) {
    final parts = [a.houseNo, a.area, a.city]
        .where((p) => p.trim().isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  /// Use GPS to get current location as pickup
  Future<void> _useCurrentLocation() async {
    setState(() => _locatingPickup = true);
    try {
      // Check permissions
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      // Reverse geocode to get address text
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      String address = 'Current Location';
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [p.name, p.subLocality, p.locality, p.administrativeArea].where((s) => s != null && s.isNotEmpty);
        address = parts.join(', ');
      }

      if (mounted) {
        setState(() {
          _pickupController.text = address;
          _pickupLat = pos.latitude;
          _pickupLng = pos.longitude;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _locatingPickup = false);
    }
  }

  /// Geocode an address text to coordinates
  Future<bool> _geocodeAddresses() async {
    final pickup = _pickupController.text.trim();
    final drop = _dropController.text.trim();

    // Only geocode if we don't already have coordinates
    if (_pickupLat == null || _pickupLng == null) {
      try {
        final locations = await locationFromAddress(pickup);
        if (locations.isNotEmpty) {
          _pickupLat = locations.first.latitude;
          _pickupLng = locations.first.longitude;
        }
      } catch (_) {
        // Geocoding failed — set null, fallback will be used
        debugPrint('Pickup geocoding failed for: $pickup');
      }
    }

    if (_dropLat == null || _dropLng == null) {
      try {
        final locations = await locationFromAddress(drop);
        if (locations.isNotEmpty) {
          _dropLat = locations.first.latitude;
          _dropLng = locations.first.longitude;
        }
      } catch (_) {
        debugPrint('Drop geocoding failed for: $drop');
      }
    }

    return true;
  }

  /// Navigate to delivery category with current addresses
  Future<void> _proceedToCategory() async {
    final pickup = _pickupController.text.trim();
    final drop = _dropController.text.trim();

    if (pickup.isEmpty || drop.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both pickup and drop locations")),
      );
      return;
    }

    // Try to geocode addresses if we don't have coords
    await _geocodeAddresses();

    final data = (widget.bookingData ?? BookingData()).copyWith(
      pickupAddress: pickup,
      dropAddress: drop,
      pickupLat: _pickupLat,
      pickupLng: _pickupLng,
      dropLat: _dropLat,
      dropLng: _dropLng,
    );

    if (mounted) pushTo(context, DeliveryCategoryScreen(bookingData: data));
  }

  @override
  Widget build(BuildContext context) {

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark,
      )
    );

    return Scaffold(
      backgroundColor: HexColor("#E7F7F5"),
      body: Column(
        children: [
          Container(
              height : 285,
              width: MediaQuery.of(context).size.width,
              decoration:  BoxDecoration(
                color: AppColors.appColor,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(25), bottomRight: Radius.circular(25))
              ),
              child: Container(
                padding: const EdgeInsets.only(top: 50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row
                    Row(
                      children: [
                        SizedBox(width: 5,),
                        Row(
                          children: [
                            InkWell(
                              onTap: (){
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: EdgeInsets.only(left: 16),
                                width: 40,
                                height: 35,
                                alignment: Alignment.center,
                                child: Icon(Icons.arrow_back_ios, color: Colors.white,),
                              ),
                            ),
                            Text(
                              "Add Location to Proceed",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                      ],
                    ),

                    const SizedBox(height: 20),

                    // Pickup field
                    Row(
                      children: [
                        SizedBox(width: 20,),
                        Container(
                          height: 45,
                          width: 45,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.all(6),
                          child: Image.asset("assets/pic_up_location.png", height: 20,width: 20,),
                        ),

                        Expanded(child: GestureDetector(
                          onTap: () => _openMapPicker(isPickup: true),
                          child: Container(
                            margin: EdgeInsets.only(left: 10, right: 15),
                            padding: const EdgeInsets.only(left: 15, right: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: AbsorbPointer(
                              child: TextField(
                                controller: _pickupController,
                                decoration: InputDecoration(
                                  suffixIcon: GestureDetector(
                                    onTap: _useCurrentLocation,
                                    child: Container(
                                      padding: EdgeInsets.all(10),
                                      child: _locatingPickup
                                          ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.appColor))
                                          : Image.asset("assets/current_location.png", height: 20, width: 20)),
                                  ),
                                    hintText: "Pickup From",
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(
                                        fontSize: 15,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w400
                                    )
                                ),
                              ),
                            ),
                          ),
                        ),)
                      ],
                    ),

                    const SizedBox(height: 15),

                    // Drop field
                    Row(
                      children: [
                        SizedBox(width: 20,),
                        Container(
                          height: 45,
                          width: 45,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.all(6),
                          child: Image.asset("assets/drop_up_location.png", height: 20,width: 20,),
                        ),

                        Expanded(child: GestureDetector(
                          onTap: () => _openMapPicker(isPickup: false),
                          child: Container(
                            margin: EdgeInsets.only(left: 10, right: 15),
                            padding: const EdgeInsets.only(left: 15, right: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: AbsorbPointer(
                              child: TextField(
                                controller: _dropController,
                                decoration: InputDecoration(
                                    suffixIcon: GestureDetector(
                                      onTap: () => _openMapPicker(isPickup: false),
                                      child: Container(
                                        padding: EdgeInsets.all(10),
                                        child: Icon(Icons.map, color: AppColors.appColor, size: 22),
                                      ),
                                    ),
                                    hintText: "Drop At",
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(
                                        fontSize: 15,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w400
                                    )
                                ),
                              ),
                            ),
                          ),
                        ),)
                      ],
                    ),

                  ],
                ),
              )
          ),

          SizedBox(height: 20,),

          InkWell(
            onTap: _pickFromSavedAddresses,
            child: Container(
              color: Colors.white,
              height: 60,
              child: Row(
                children: [

                  SizedBox(width: 20,),

                  SizedBox(
                    height: 25,
                      width: 25,
                      child: Image.asset("assets/heart_icon.png")
                  ),

                  SizedBox(width: 10,),

                  Text("Saved Addresses ",style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500),),

                  Expanded(child: Container(width: 0,)),

                  Icon(Icons.arrow_forward_ios, size: 16,),

                  SizedBox(width: 20,)
                ],
              ),
            ),
          ),

          SizedBox(height: 20,),


          // ─── RECENT DELIVERIES (real data) ───
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.history, size: 18, color: AppColors.appColor),
                const SizedBox(width: 8),
                Text("Recent Deliveries", style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600)),
                const Spacer(),
                if (_recentDeliveries.isNotEmpty)
                  InkWell(
                    onTap: () => setState(() => _recentDeliveries.clear()),
                    child: Text("Clear All", style: TextStyle(color: HexColor('#F4BE05'), fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),

          if (_loadingRecent)
            Container(
              color: Colors.white, height: 80,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_recentDeliveries.isEmpty)
            Container(
              color: Colors.white, padding: const EdgeInsets.all(20),
              child: const Center(child: Text("No recent deliveries", style: TextStyle(color: Colors.grey, fontSize: 13))),
            )
          else
            Container(
              color: Colors.white,
              child: Column(
                children: _recentDeliveries.map((order) {
                  final dropAddr = order['drop']?['address'] ?? 'Unknown';
                  final pickupAddr = order['pickup']?['address'] ?? '';
                  final vehicleName = order['vehicleType']?['name'] ?? '';
                  final bookingNum = order['bookingNumber'] ?? '';
                  return Column(
                    children: [
                      InkWell(
                        onTap: () {
                          // Fill drop field from this delivery
                          final drop = order['drop'];
                          if (drop != null) {
                            setState(() {
                              _dropController.text = drop['address'] ?? '';
                              _dropLat = (drop['lat'] as num?)?.toDouble();
                              _dropLng = (drop['lng'] as num?)?.toDouble();
                            });
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: const Color(0xFFFFF3EC), borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.local_shipping_outlined, color: AppColors.appColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dropAddr,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '$vehicleName • #$bookingNum',
                                      style: TextStyle(fontSize: 11, color: HexColor("#777777")),
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _reorderBooking(order),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.appColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(Icons.replay, size: 14, color: AppColors.appColor),
                                    const SizedBox(width: 4),
                                    Text('Reorder', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.appColor)),
                                  ]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(height: 1, color: Colors.grey.shade200, indent: 68),
                    ],
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 12),

          // ─── POPULAR IN YOUR AREA ───
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.trending_up, size: 18, color: Colors.orange),
                const SizedBox(width: 8),
                Text("Popular in your area", style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),

          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 4),
                itemCount: _popularPlaces.length,
                itemBuilder: (context, index) {
                  final place = _popularPlaces[index];
                  return Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _dropController.text = place['name']!;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.place_outlined, color: Colors.orange, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(place['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 3),
                                    Text(place['area']!, style: TextStyle(fontSize: 11, color: HexColor("#777777"))),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
                            ],
                          ),
                        ),
                      ),
                      Divider(height: 1, color: Colors.grey.shade200, indent: 68),
                    ],
                  );
                },
              ),
            ),
          ),

          // Search / Proceed button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.white,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.appColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: _proceedToCategory,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Search",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}
