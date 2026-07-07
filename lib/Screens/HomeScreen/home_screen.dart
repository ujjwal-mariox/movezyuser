import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/Screens/SearchScreen/search_screen.dart';
import 'package:movezy_user_app/Screens/HelpSupportScreen/help_support_screen.dart';
import 'package:movezy_user_app/Screens/RechangeWalletApp/recharge_wallet_screen.dart';
import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/Screens/HomeScreen/Model/home_page_model.dart';
import 'package:movezy_user_app/Screens/HomeScreen/Model/booking_data.dart';
import 'package:movezy_user_app/Screens/HomeScreen/Service/home_api_service.dart';
import 'package:movezy_user_app/Services/wallet_service.dart';
import 'package:movezy_user_app/CommonWidgets/button_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  final HomeApiService _homeApiService = HomeApiService();
  MapController? _mapController;
  List<HomeVehicleType> _vehicleTypes = [];
  List<PromoBanner> _promoBanners = [];
  bool _isLoading = true;
  int _currentPromoIndex = 0;
  Timer? _promoTimer;
  bool _showGstCard = true;
  bool _hasGst = false;

  // User location
  LatLng _userLocation = const LatLng(28.6139, 77.2090); // Default: Delhi
  String _userAddress = 'Pick up from your location';
  bool _locationLoaded = false;
  bool _mapReady = false;

  // Dummy nearby vehicles for Uber-like effect
  List<_DummyVehicle> _nearbyVehicles = [];

  // Wallet balance
  double _walletBalance = 0;

  // ─── Delivery animation ───
  late AnimationController _deliveryAnimController;
  late Animation<double> _deliverySlide;

  // ─── Trust ribbon ───
  late AnimationController _ribbonController;
  final List<String> _trustBadges = [
    '✓ Verified Drivers',
    '🛡 Insured Deliveries',
    '📞 24/7 Support',
    '💰 Transparent Pricing',
    '📦 10,000+ Deliveries Completed',
  ];
  int _currentBadgeIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Delivery motion animation (subtle slide loop)
    _deliveryAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _deliverySlide = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _deliveryAnimController, curve: Curves.easeInOut),
    );

    // Trust ribbon rotation controller
    _ribbonController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (mounted) {
            setState(() {
              _currentBadgeIndex = (_currentBadgeIndex + 1) % _trustBadges.length;
            });
          }
          _ribbonController.reset();
          _ribbonController.forward();
        }
      });
    _ribbonController.forward();

    // Defer ALL heavy work until after the first frame paints
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAll();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _promoTimer?.cancel();
    _deliveryAnimController.dispose();
    _ribbonController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  /// Auto-advance the promo/offer carousel every 4 seconds.
  /// Safe to call multiple times — it resets any existing timer.
  void _startPromoRotation() {
    _promoTimer?.cancel();
    if (_promoBanners.length < 2) return; // nothing to rotate
    _promoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        _currentPromoIndex =
            (_currentPromoIndex + 1) % _promoBanners.length;
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh data when user returns to the app
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  /// Lightweight refresh — re-fetches home data without showing loading spinner
  Future<void> _refreshData() async {
    try {
      debugPrint('[Home] Refreshing home data...');
      final results = await Future.wait([
        _homeApiService.fetchHomePage(),
        _fetchWalletBalance(),
      ]);
      if (!mounted) return;
      final homeData = results[0] as HomePageData?;
      final walletBal = results[1] as double;
      setState(() {
        _walletBalance = walletBal;
        if (homeData != null) {
          _vehicleTypes = homeData.vehicleTypes;
          _promoBanners = homeData.promoBanners;
          debugPrint('[Home] Refresh complete: ${homeData.vehicleTypes.length} vehicles');
        }
      });
      _startPromoRotation();
    } catch (e) {
      debugPrint('[Home] Refresh error: $e');
    }
  }

  /// Navigate to a screen and refresh home data when user comes back
  Future<void> _navigateAndRefresh(Widget screen) async {
    await pushTo(context, screen);
    debugPrint('[Home] Returned from navigation, refreshing...');
    if (mounted) _refreshData();
  }

  /// Sequenced initialization: data first, then location
  Future<void> _initAll() async {
    // Step 1: Load data (API + GST) — show content ASAP
    await _initData();
    // Step 2: Get location AFTER data is loaded so UI isn't blank
    await _getUserLocation();
  }

  /// Load home data + GST status in parallel, single setState
  Future<void> _initData() async {
    final results = await Future.wait([
      _homeApiService.fetchHomePage(),
      _fetchGstStatus(),
      _fetchWalletBalance(),
    ]);

    if (!mounted) return;

    final homeData = results[0] as HomePageData?;
    final hasGst = results[1] as bool;
    final walletBal = results[2] as double;

    debugPrint('[Home] _initData complete — walletBal=$walletBal, vehicles=${homeData?.vehicleTypes.length}, hasGst=$hasGst');

    setState(() {
      _isLoading = false;
      _hasGst = hasGst;
      _showGstCard = !hasGst;
      _walletBalance = walletBal;
      if (homeData != null) {
        _vehicleTypes = homeData.vehicleTypes;
        _promoBanners = homeData.promoBanners;
      }
    });
    _startPromoRotation();
  }

  Future<void> _getUserLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        // Even without permission, show map with default location
        _finishLocationSetup(_userLocation, _userAddress);
        return;
      }

      // Use LOW accuracy first for a fast fix, avoids GPS lock delay
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );

      final newPos = LatLng(pos.latitude, pos.longitude);

      // Reverse geocode — wrapped in try/catch so it never blocks
      String address = _userAddress;
      try {
        final placemarks =
            await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [
            p.name,
            p.subLocality,
            p.locality,
            p.administrativeArea
          ].where((s) => s != null && s.isNotEmpty);
          address = parts.join(', ');
        }
      } catch (_) {}

      _finishLocationSetup(newPos, address);
    } catch (e) {
      debugPrint('Location error: $e');
      _finishLocationSetup(_userLocation, _userAddress);
    }
  }

  /// Single batched setState for location + markers + map
  void _finishLocationSetup(LatLng pos, String address) {
    if (!mounted) return;

    setState(() {
      _userLocation = pos;
      _userAddress = address;
      _locationLoaded = true;
      _mapReady = true;
    });

    // Move map after setState so the widget exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _mapController?.move(pos, 14.5);
      } catch (_) {}
    });

    // Load REAL nearby online drivers (was dummy vehicles). Non-blocking.
    _fetchNearbyVehicles(pos);
  }

  /// Fetch real online drivers near the user for the home map.
  /// Falls back to an empty list (no fake markers) if unavailable.
  Future<void> _fetchNearbyVehicles(LatLng center) async {
    try {
      final token = Prefs.getString('token');
      if (token.isEmpty) return;
      final uri = Uri.parse(
        '${ApiUrls.nearbyDriversUrl}?lat=${center.latitude}&lng=${center.longitude}',
      );
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode != 200) return;
      final json = jsonDecode(response.body);
      final List list = (json['data'] is List) ? json['data'] as List : [];

      final vehicles = <_DummyVehicle>[];
      for (final item in list) {
        final loc = item['location'];
        if (loc == null || loc['lat'] == null || loc['lng'] == null) continue;
        final driver = item['driver'];
        vehicles.add(_DummyVehicle(
          position: LatLng(
            (loc['lat'] as num).toDouble(),
            (loc['lng'] as num).toDouble(),
          ),
          name: (driver is Map && driver['name'] != null)
              ? driver['name'].toString()
              : 'Driver',
          // The API doesn't send a vehicle-type label; use a generic marker.
          icon: Icons.local_shipping,
        ));
      }

      if (!mounted) return;
      setState(() {
        _nearbyVehicles = vehicles;
      });
    } catch (_) {
      // Leave the map without vehicle markers rather than showing fake ones.
    }
  }

  /// Pure function — returns true if user has GST, no setState
  Future<bool> _fetchGstStatus() async {
    try {
      final token = Prefs.getString('token');
      if (token.isEmpty) return false;
      final response = await http.get(
        Uri.parse(ApiUrls.gstUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['data'] != null && json['data']['gstin'] != null) {
          return true;
        }
      }
    } catch (e) {
      debugPrint('GST check error: $e');
    }
    return false;
  }

  /// Fetch wallet balance — uses WalletService (same as wallet screen)
  Future<double> _fetchWalletBalance() async {
    try {
      debugPrint('[Home] Fetching wallet balance...');
      final walletData = await WalletService.getWallet();
      debugPrint('[Home] Wallet balance fetched: ${walletData.balance}');
      return walletData.balance;
    } catch (e) {
      debugPrint('[Home] Wallet balance error: $e');
      // Fallback: try direct HTTP call
      try {
        final token = Prefs.getString('token');
        debugPrint('[Home] Wallet fallback — token empty: ${token.isEmpty}');
        if (token.isEmpty) return 0;
        final response = await http.get(
          Uri.parse(ApiUrls.walletUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        debugPrint('[Home] Wallet fallback status: ${response.statusCode}');
        debugPrint('[Home] Wallet fallback body: ${response.body}');
        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final data = body['data'] ?? body['rData'] ?? body;
          return (data['balance'] ?? 0).toDouble();
        }
      } catch (e2) {
        debugPrint('[Home] Wallet fallback error: $e2');
      }
      return 0;
    }
  }

  /// Submit GSTIN to backend
  Future<bool> _submitGstin(String gstin, {String? businessName}) async {
    try {
      final token = Prefs.getString('token');
      if (token.isEmpty) return false;
      final body = {'gstin': gstin};
      if (businessName != null && businessName.isNotEmpty) {
        body['businessName'] = businessName;
      }
      final response = await http.post(
        Uri.parse(ApiUrls.gstUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('GST submit error: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('GST submit exception: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── ORANGE HEADER + DELIVERY ANIMATION + PICKUP BOX (overlapping) ───
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(20, 55, 20, 60),
                    decoration: BoxDecoration(color: Color(0xFFFF7A2A)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () => pushTo(context, const HelpSupportScreen()),
                              child: Container(
                                height: 35,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white, width: 0.3),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(width: 10),
                                    Image.asset("assets/headphones.png", width: 25, height: 25, color: Colors.white),
                                    SizedBox(width: 6),
                                    const Text("Help", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                                    SizedBox(width: 10),
                                  ],
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => pushTo(context, WalletRechargeApp()),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: Row(
                                  children: [
                                    Image.asset("assets/wallet_icon.png", width: 20, height: 20),
                                    SizedBox(width: 6),
                                    Text("₹${_walletBalance.toInt()}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: HexColor("#F46D17"))),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // ─── Subtle Delivery Motion Animation ───
                        AnimatedBuilder(
                          animation: _deliverySlide,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(_deliverySlide.value, 0),
                              child: child,
                            );
                          },
                          child: _buildHeaderVehicleInfo(),
                        ),
                        const SizedBox(height: 12),
                        // ─── Trust Ribbon ───
                        _buildTrustRibbon(),
                      ],
                    ),
                  ),
                  // ─── PICKUP BOX (overlapping) ───
                  Positioned(
                    bottom: -30,
                    left: 20,
                    right: 20,
                    child: buildPickupSection(),
                  ),
                ],
              ),

              const SizedBox(height: 40), // space for pickup box overlap

              // ─── VEHICLE GRID + PROMO + GST + MAP ───
              buildVehicleGrid(),
            ],
          ),
        ),
      ),
    );
  }

  /// Header bar showing first vehicle availability info
  Widget _buildHeaderVehicleInfo() {
    final firstVehicle = _vehicleTypes.isNotEmpty ? _vehicleTypes.first : null;
    final vehicleName = firstVehicle?.name ?? "2 Wheeler";
    final baseFare = firstVehicle?.baseFare.toInt() ?? 50;

    return Row(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vehicleName, textAlign: TextAlign.start,
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            Text("AVAILABLE", textAlign: TextAlign.start,
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
        SizedBox(width: 5),
        firstVehicle?.image != null && firstVehicle!.image!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  ApiUrls.imageProxyUrl(firstVehicle.image!),
                  width: 45, height: 35, cacheWidth: 90, cacheHeight: 70, fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Image.asset("assets/delivery_scooter.png", width: 45),
                ),
              )
            : Image.asset("assets/delivery_scooter.png", width: 45),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            "15 mins away  |  Starting from ₹$baseFare",
            style: TextStyle(color: Colors.white, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Rotating trust ribbon with animated fade
  Widget _buildTrustRibbon() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.3),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Row(
          key: ValueKey<int>(_currentBadgeIndex),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _trustBadges[_currentBadgeIndex],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 8),
            ...List.generate(
              _trustBadges.length,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _currentBadgeIndex
                      ? Colors.white
                      : Colors.white.withOpacity(0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── PICKUP BOX ───
  Widget buildPickupSection() {
    return InkWell(
      onTap: () {
        _navigateAndRefresh(SearchScreen(bookingData: BookingData(allVehicles: _vehicleTypes)));
      },
      child: Container(
        margin: EdgeInsets.only(left: 15, right: 15),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            Image.asset("assets/star_location.png", width: 25),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Pick up from", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  SizedBox(height: 8),
                  Text(_userAddress, style: TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── VEHICLE GRID (DYNAMIC) + PROMO + GST + MAP ───
  Widget buildVehicleGrid() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 25),
          decoration: BoxDecoration(
            color: HexColor("#FFEDE2"),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
          child: _isLoading
              ? Center(child: Padding(padding: const EdgeInsets.all(40), child: CircularProgressIndicator(color: AppColors.appColor)))
              : _vehicleTypes.isEmpty
                  ? _buildFallbackGrid()
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.1, mainAxisSpacing: 16, crossAxisSpacing: 16),
                      itemCount: _vehicleTypes.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) => _buildDynamicVehicleBox(_vehicleTypes[index]),
                    ),
        ),

        // ─── WHITE SECTION: Promo + GST + Map ───
        Container(
          padding: EdgeInsets.only(top: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topRight: Radius.circular(25), topLeft: Radius.circular(25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildOfferCard(),
              if (_showGstCard && !_hasGst) ...[
                SizedBox(height: 20),
                buildGSTCard(),
              ],
              SizedBox(height: 20),
              // ─── NEARBY VEHICLES MAP ───
              _buildNearbyMap(),
              const SizedBox(height: 80), // bottom nav space
            ],
          ),
        ),
      ],
    );
  }

  // ─── MAP SECTION (lazy-loaded, only renders when location is ready) ───
  Widget _buildNearbyMap() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Vehicles Near You", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 220,
              child: _mapReady ? _buildMapWidget() : _buildMapPlaceholder(),
            ),
          ),
        ],
      ),
    );
  }

  /// Placeholder shown while location is being fetched
  Widget _buildMapPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: HexColor("#FFF3EC"),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.appColor),
            ),
            const SizedBox(height: 10),
            Text("Finding vehicles near you...",
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      ),
    );
  }

  /// The actual map widget — only built once _mapReady is true
  Widget _buildMapWidget() {
    _mapController ??= MapController();
    return IgnorePointer(
      child: FlutterMap(
      mapController: _mapController!,
      options: MapOptions(
        initialCenter: _userLocation,
        initialZoom: 14.5,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.movezy_user_app',
          maxZoom: 19,
        ),
        MarkerLayer(
          markers: [
            // User location
            Marker(
              point: _userLocation,
              width: 28,
              height: 28,
              child: Container(
                decoration: BoxDecoration(
                  color: HexColor("#FF6200"),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6)],
                ),
                child: const Icon(Icons.person, size: 14, color: Colors.white),
              ),
            ),
            // Nearby vehicles
            ..._nearbyVehicles.map((v) => Marker(
                  point: v.position,
                  width: 40,
                  height: 40,
                  child: _VehicleMarker(vehicle: v),
                )),
          ],
        ),
      ],
      ),
    );
  }

  // ─── VEHICLE GRID HELPERS ───

  Widget _buildFallbackGrid() {
    return GridView.count(
      crossAxisCount: 2, childAspectRatio: 1.1, mainAxisSpacing: 16, crossAxisSpacing: 16,
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      children: [
        buildVehicleBox("2 Wheeler", "10kg, 2 Feet", "assets/2_wheeler.png"),
        buildVehicleBox("Tempu", "1.2 Ton, 7 Feet", "assets/tempu.png"),
        buildVehicleBox("Pickup", "1.2 Ton, 7 Feet", "assets/pick_up.png"),
        buildVehicleBox("Large Truck", "5 Ton, 14 Feet", "assets/large_truck.png"),
      ],
    );
  }

  Widget _buildDynamicVehicleBox(HomeVehicleType vehicle) {
    return InkWell(
      onTap: () => _onVehicleTapped(vehicle),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            vehicle.image != null && vehicle.image!.isNotEmpty
                ? Image.network(
                    ApiUrls.imageProxyUrl(vehicle.image!),
                    height: 55, cacheWidth: 150, cacheHeight: 110, fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return SizedBox(height: 55, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.appColor)));
                    },
                    errorBuilder: (_, _, _) => Icon(Icons.local_shipping, size: 45, color: AppColors.appColor),
                  )
                : Icon(Icons.local_shipping, size: 45, color: AppColors.appColor),
            const SizedBox(height: 10),
            Text(vehicle.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text("${vehicle.capacityLabel}, Starting ₹${vehicle.baseFare.toInt()}", style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget buildVehicleBox(String title, String subtitle, String icon) {
    return InkWell(
      onTap: () => _navigateAndRefresh(SearchScreen(bookingData: BookingData(allVehicles: _vehicleTypes))),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(icon, height: 55),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // ─── OFFER CARD ───
  Widget buildOfferCard() {
    if (_promoBanners.isNotEmpty) {
      final promo =
          _promoBanners[_currentPromoIndex % _promoBanners.length];
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: HexColor("#E9E9E9")),
            gradient: LinearGradient(
                colors: [HexColor("#FEFEF6"), HexColor("#FDF6AB")]),
          ),
          child: Row(
            children: [
              Image.asset("assets/gift_icon.png", width: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(promo.offerText,
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text("Use Code: ",
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        Text(promo.code,
                            style: GoogleFonts.poppins(
                                color: Colors.orange,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                  "${_currentPromoIndex + 1}/${_promoBanners.length}",
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    // Fallback
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: HexColor("#E9E9E9")),
          gradient: LinearGradient(
              colors: [HexColor("#FEFEF6"), HexColor("#FDF6AB")]),
        ),
        child: Row(
          children: [
            Image.asset("assets/gift_icon.png", width: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Flat 20% Off Second Order",
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text("Use Code: ",
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                      Text("MOVEZY1",
                          style: GoogleFonts.poppins(
                              color: Colors.orange,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            Text("1/1",
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ─── GST CARD ───
  Widget buildGSTCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Image.asset("assets/tax_icon.png", width: 32),
            const SizedBox(width: 10),
            Text("Have a\nGST Number?",
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.bold)),
            const Spacer(),
            _buildGstButton("Yes",
                onTap: () => _showGstSheet(context)),
            const SizedBox(width: 8),
            _buildGstButton("No",
                onTap: () => setState(() => _showGstCard = false)),
          ],
        ),
      ),
    );
  }

  Widget _buildGstButton(String text, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.appColor),
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
              colors: [HexColor("#FFF1E9"), Colors.white]),
        ),
        child: Text(text,
            style: GoogleFonts.poppins(
                color: AppColors.appColor,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ),
    );
  }

  void _showGstSheet(BuildContext context) {
    final gstinController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      HexColor("#FDF6AB"),
                      Colors.white,
                      Colors.white
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    blurRadius: 6)
                              ],
                            ),
                            child: Icon(Icons.close,
                                size: 20, color: HexColor("#FF6200")),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      height: 100,
                      width: 100,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                            color: AppColors.appColor, width: 2),
                      ),
                      child: Image.asset('assets/gst.png'),
                    ),
                    const SizedBox(height: 20),
                    Text("Add GSTIN",
                        style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Text(
                      "Get invoices with GSTIN for your future orders and claim Input Tax Credit",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        border: Border.all(color: HexColor("#B8B8B8")),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextFormField(
                        controller: gstinController,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 15,
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: 'GSTIN',
                          hintStyle: TextStyle(
                              color: HexColor("#B8B8B8"), fontSize: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ButtonWidget(
                      text: isSubmitting ? "Saving..." : "Got it",
                      margin:
                          const EdgeInsets.symmetric(horizontal: 15),
                      height: 55,
                      borderRadius: BorderRadius.circular(10),
                      backgroundColor: AppColors.appColor,
                      onTap: isSubmitting
                          ? null
                          : () async {
                              final gstin =
                                  gstinController.text.trim();
                              if (gstin.isEmpty) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                        content: Text(
                                            'Please enter your GSTIN')));
                                return;
                              }
                              setSheetState(
                                  () => isSubmitting = true);
                              final success =
                                  await _submitGstin(gstin);
                              setSheetState(
                                  () => isSubmitting = false);
                              if (success) {
                                Navigator.pop(context);
                                setState(() {
                                  _hasGst = true;
                                  _showGstCard = false;
                                });
                                ScaffoldMessenger.of(this.context)
                                    .showSnackBar(const SnackBar(
                                        content: Text(
                                            'GSTIN saved!'),
                                        backgroundColor:
                                            Colors.green));
                              } else {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                        content: Text(
                                            'Failed to save GSTIN'),
                                        backgroundColor:
                                            Colors.red));
                              }
                            },
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _onVehicleTapped(HomeVehicleType vehicle) {
    final data = BookingData(
      selectedVehicle: vehicle,
      allVehicles: _vehicleTypes,
    );

    if (vehicle.allowIntraCity && vehicle.allowInterCity) {
      _showServiceSheet(context, data);
    } else {
      final serviceType =
          vehicle.allowInterCity ? 'OUTSTATION' : 'WITHIN_CITY';
      _navigateAndRefresh(
          SearchScreen(
              bookingData: data.copyWith(serviceType: serviceType)));
    }
  }

  void _showServiceSheet(BuildContext context, BookingData data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [HexColor("#FDF6AB"), Colors.white],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Choose your service",
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  InkWell(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.grey.withOpacity(.3),
                              blurRadius: 6)
                        ],
                      ),
                      child: Icon(Icons.close,
                          size: 20, color: HexColor("#FF6200")),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _serviceBox(
                image: "assets/within_city.png",
                title: "Within City",
                onTap: () {
                  Navigator.pop(ctx);
                  _navigateAndRefresh(
                      SearchScreen(
                          bookingData: data.copyWith(
                              serviceType: 'WITHIN_CITY')));
                },
              ),
              const SizedBox(height: 16),
              _serviceBox(
                image: "assets/outside_city.png",
                title: "Outstation",
                onTap: () {
                  Navigator.pop(ctx);
                  _navigateAndRefresh(
                      SearchScreen(
                          bookingData: data.copyWith(
                              serviceType: 'OUTSTATION')));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void showServiceSheet(BuildContext context) {
    if (_vehicleTypes.isNotEmpty) {
      _onVehicleTapped(_vehicleTypes.first);
    } else {
      pushTo(context, SearchScreen(bookingData: BookingData()));
    }
  }

  Widget _serviceBox({
    required String image,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(.3)),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Image.asset(image, height: 54),
            Expanded(
              child: Text(title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── DUMMY VEHICLE MODEL ───
class _DummyVehicle {
  final LatLng position;
  final String name;
  final IconData icon;

  _DummyVehicle(
      {required this.position, required this.name, required this.icon});
}

// ─── VEHICLE MARKER WIDGET ───
class _VehicleMarker extends StatelessWidget {
  final _DummyVehicle vehicle;

  const _VehicleMarker({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Icon(vehicle.icon, size: 22, color: HexColor("#FF6200")),
    );
  }
}