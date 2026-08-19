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
import 'package:movezy_user_app/CommonWidgets/location_icon.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:intl/intl.dart';
import 'package:movezy_user_app/Screens/SearchScreen/search_screen.dart';
import 'package:movezy_user_app/Screens/BookingHistory/booking_history.dart';
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

  // Header vehicle ticker (per the Figma export: the strip holds every
  // vehicle side by side and slides through them — 2 Wheeler, 3 Wheeler, …).
  int _headerVehicleIndex = 0;
  Timer? _headerVehicleTimer;
  bool _showGstCard = true;
  bool _hasGst = false;

  // User location
  LatLng _userLocation = const LatLng(28.6139, 77.2090); // Default: Delhi
  String _userAddress = 'Pick up from your location';
  bool _locationLoaded = false;
  bool _mapReady = false;

  // Dummy nearby vehicles for Uber-like effect
  List<_DummyVehicle> _nearbyVehicles = [];

  // Recent orders for the home History section
  List<BookingItem> _recentOrders = [];

  // Wallet balance
  double _walletBalance = 0;

  // ─── Delivery animation ───
  late AnimationController _deliveryAnimController;
  late Animation<double> _deliverySlide;

  // Trust ribbon removed to match the design. Its AnimationController drove a
  // setState loop that rebuilt the whole home tree every few seconds, so the
  // controller and badge list are gone too rather than left spinning unseen.

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

    // Defer ALL heavy work until after the first frame paints
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAll();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _promoTimer?.cancel();
    _headerVehicleTimer?.cancel();
    _deliveryAnimController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  /// Slide the header through the vehicle catalog, one every few seconds —
  /// the design's strip holds every vehicle side by side and animates through
  /// them. Safe to call multiple times; resets any existing timer.
  void _startHeaderVehicleRotation() {
    _headerVehicleTimer?.cancel();
    if (_vehicleTypes.length < 2) return; // nothing to rotate
    _headerVehicleTimer =
        Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (!mounted) return;
      setState(() {
        _headerVehicleIndex =
            (_headerVehicleIndex + 1) % _vehicleTypes.length;
      });
    });
  }

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
    _startHeaderVehicleRotation();
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
    _startHeaderVehicleRotation();
    // Non-blocking: the History section fills in when it arrives.
    _loadRecentOrders();
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
                        // Trust ribbon ("24/7 Support" rotator) removed — the
                        // design has no such strip between the header vehicle
                        // info and the pickup box.
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
    // Rotating ticker: _headerVehicleIndex advances on a timer, and the
    // AnimatedSwitcher slides each vehicle's entry in from the right, matching
    // the design's side-by-side strip. Falls back gracefully to a static row
    // when the catalog has 0 or 1 vehicles.
    final firstVehicle = _vehicleTypes.isNotEmpty
        ? _vehicleTypes[_headerVehicleIndex % _vehicleTypes.length]
        : null;

    // No catalog, nothing to say. This used to fall back to a "2 Wheeler"
    // starting at ₹50 — a vehicle and a price the server never sent, shown
    // exactly like real ones, on the very screen where the fare promise is
    // made. While the load is in flight the strip just holds its height so
    // the header doesn't jump; if the catalog failed it collapses and the
    // grid below carries the real error and retry (_buildVehicleLoadError).
    if (firstVehicle == null) {
      return SizedBox(height: _isLoading ? 47 : 0);
    }

    final vehicleName = firstVehicle.name;
    final baseFare = firstVehicle.baseFare.toInt();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.25, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: _headerVehicleRow(
        key: ValueKey(_headerVehicleIndex),
        vehicle: firstVehicle,
        vehicleName: vehicleName,
        baseFare: baseFare,
      ),
    );
  }

  /// One entry of the header ticker. The vehicle is non-null by construction —
  /// [_buildHeaderVehicleInfo] returns early when the catalog is empty, so
  /// there is no path here that has to invent a name or a fare.
  Widget _headerVehicleRow({
    required Key key,
    required HomeVehicleType vehicle,
    required String vehicleName,
    required int baseFare,
  }) {
    final firstVehicle = vehicle;
    final etaMins = _nearestDriverEta();
    return Row(
      key: key,
      children: [
        // Flexible: as a bare Row child this Column got unbounded width, so the
        // server-driven vehicle name laid out at full intrinsic width and could
        // never ellipsize — a long catalog name ran off the header.
        Flexible(
          child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vehicleName, textAlign: TextAlign.start,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600, letterSpacing: -0.36)),
            // The design reads "AVAILABLE" here. It used to be hardcoded, which
            // claimed availability with zero drivers online — so it's now driven
            // by the real nearby-driver list this screen already loads. With no
            // driver nearby we fall back to the capacity, which is always true.
            if (_nearbyVehicles.isNotEmpty)
              const Text("AVAILABLE",
                textAlign: TextAlign.start,
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w400, letterSpacing: 0.2))
            else if (firstVehicle.maxWeightKg > 0)
              Text("Up to ${firstVehicle.maxWeightKg.toInt()} kg",
                textAlign: TextAlign.start,
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
          ),
        ),
        SizedBox(width: 5),
        firstVehicle.image != null && firstVehicle.image!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  ApiUrls.imageProxyUrl(firstVehicle.image!),
                  width: 61, height: 47, cacheWidth: 122, cacheHeight: 94, fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Image.asset("assets/delivery_scooter.png", width: 45),
                ),
              )
            : Image.asset("assets/delivery_scooter.png", width: 45),
        const SizedBox(width: 8),
        Flexible(
          // Design reads "15 mins away | Starting from ₹50". The ETA used to be
          // the literal string "15 mins" with nothing behind it. It's now
          // computed from the CLOSEST REAL nearby driver, and simply omitted
          // when no driver is around — so it is never an invented number.
          // The fare is dropped the same way when the catalog carries no
          // baseFare for this vehicle, rather than advertising "from ₹0".
          child: Text(
            [
              if (etaMins != null) "$etaMins mins away",
              if (baseFare > 0) "Starting from ₹$baseFare",
            ].join("  |  "),
            style: TextStyle(color: Colors.white, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }


  /// Rough pickup ETA in minutes from the nearest online driver, or null when
  /// none is nearby.
  ///
  /// Straight-line distance at a nominal city speed — deliberately coarse, and
  /// only ever shown when a real driver exists to measure against. A precise
  /// figure would need a routing call and a chosen pickup point, neither of
  /// which this screen has.
  int? _nearestDriverEta() {
    if (_nearbyVehicles.isEmpty) return null;
    double? nearestMetres;
    for (final v in _nearbyVehicles) {
      final d = Geolocator.distanceBetween(
        _userLocation.latitude,
        _userLocation.longitude,
        v.position.latitude,
        v.position.longitude,
      );
      if (nearestMetres == null || d < nearestMetres) nearestMetres = d;
    }
    if (nearestMetres == null) return null;
    const cityKmph = 18.0; // conservative urban average
    final mins = (nearestMetres / 1000) / cityKmph * 60;
    return mins.ceil().clamp(1, 60);
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
            // The design's pickup pin, same as the search screen's field —
            // this bar used a starred-location glyph nothing else in the app
            // uses, which is exactly the inconsistency the client flagged.
            const LocationIcon.pickup(),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Pick up from",
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.appColor)),
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
          // Hugs the tiles: the cream panel is only a backdrop for the grid, so
          // it takes the design's 26pt side margins and just enough top/bottom
          // to breathe rather than the deep inset it had.
          padding: const EdgeInsets.only(left: 26, right: 26, top: 12, bottom: 14),
          decoration: BoxDecoration(
            color: HexColor("#FFF1E8"),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
          child: _isLoading
              ? Center(child: Padding(padding: const EdgeInsets.all(40), child: CircularProgressIndicator(color: AppColors.appColor)))
              : _vehicleTypes.isEmpty
                  ? _buildVehicleLoadError()
                  : GridView.builder(
                      // Per the design: 154×130pt tiles, 15pt gutters, inside
                      // 26pt margins on a 375pt frame — slightly WIDER than
                      // tall. This drew 0.78 (much taller than wide), which
                      // squeezed the art into a narrow column.
                      // Overflow is handled in the tile itself: the art is
                      // Expanded, so a narrow screen or a large font scale
                      // shrinks the image rather than bursting the cell.
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.18, mainAxisSpacing: 15, crossAxisSpacing: 15),
                      itemCount: _vehicleTypes.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      // Both of these matter. A vertical ScrollView with no
                      // controller is `primary`, and a primary view with null
                      // padding adopts the ambient MediaQuery padding as its
                      // own — here the status bar (36) plus, because the
                      // Scaffold sets extendBody with a 107pt bottom nav, a
                      // ~130pt bottom inset. That padded the cream panel out to
                      // 512pt for a grid needing 346, which no padding value on
                      // the Container could undo.
                      primary: false,
                      padding: EdgeInsets.zero,
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
              const SizedBox(height: 22),
              // ─── SERVICE HIGHLIGHTS (Secure Shipment / Multiple Drop) ───
              _buildServiceHighlights(),
              SizedBox(height: 20),
              // ─── NEARBY VEHICLES MAP ("Delivery chahiye?") ───
              _buildNearbyMap(),
              const SizedBox(height: 22),
              // ─── RECENT ORDERS ───
              _buildHistorySection(),
              const SizedBox(height: 80), // bottom nav space
            ],
          ),
        ),
      ],
    );
  }

  /// Both service cards start a booking — that's where insurance and extra
  /// stops are actually chosen, so they lead somewhere real rather than being
  /// decorative tiles.
  void _onServiceCardTap() => _navigateAndRefresh(
        SearchScreen(bookingData: BookingData(allVehicles: _vehicleTypes)),
      );

  /// Recent orders for the home "History" section.
  Future<void> _loadRecentOrders() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiUrls.userBookingsUrl}?page=1&limit=3'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Prefs.getString('token')}',
        },
      ).timeout(const Duration(seconds: 20));
      if (!mounted || res.statusCode != 200) return;
      final body = jsonDecode(res.body);
      final raw = (body['data'] is Map)
          ? (body['data']['bookings'] ?? body['data']['data'] ?? [])
          : [];
      if (raw is! List) return;
      setState(() {
        _recentOrders = raw
            .whereType<Map>()
            .map((b) => BookingItem.fromJson(Map<String, dynamic>.from(b)))
            .toList();
      });
    } catch (e) {
      // Non-fatal: the section simply doesn't render.
      debugPrint('[Home] Recent orders error: $e');
    }
  }

  Widget _buildHistorySection() {
    if (_recentOrders.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('History',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.appColor)),
              const Spacer(),
              InkWell(
                onTap: () => pushTo(context, const BookingHistory()),
                child: const Text('View all',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final o in _recentOrders) ...[
            _historyCard(o),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _historyCard(BookingItem o) {
    final completed = o.status.toUpperCase() == 'COMPLETED';
    final cancelled = o.status.toUpperCase() == 'CANCELLED';
    final tone = completed
        ? const Color(0xFF4EBF66)
        : cancelled
            ? const Color(0xFFC4213A)
            : AppColors.appColor;
    final label = o.status.isEmpty
        ? '—'
        : '${o.status[0].toUpperCase()}${o.status.substring(1).toLowerCase()}';

    return InkWell(
      onTap: () => pushTo(context, const BookingHistory()),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDCE8E9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o.bookingNumber.isEmpty
                            ? 'ORD'
                            : 'ORD#${o.bookingNumber}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      if ((o.dropContact ?? '').isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text('Recipient: ${o.dropContact}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    // Solid badge with white text, per the design's
                    // "Completed" chip (#4EBF66, radius 3).
                    color: completed ? tone : tone.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: completed ? Colors.white : tone)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined,
                    size: 15, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${o.pickupAddress} → ${o.dropAddress}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              DateFormat('dd MMMM yyyy, h:mma').format(o.createdAt),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  /// "Add Location to Proceed" + the two service cards from the design.
  ///
  /// Both point at capabilities that genuinely exist: Secure Shipment is the
  /// live INSURANCE add-on, and Multiple Drop is the booking `stops[]` support.
  /// Tapping either starts a booking, which is where both are actually applied.
  Widget _buildServiceHighlights() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Location to Proceed',
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _serviceCard(
            icon: Icons.verified_user_outlined,
            title: 'Secure Shipment',
            subtitle:
                'Comprehensive coverage against loss, theft, or damage.',
          ),
          const SizedBox(height: 12),
          _serviceCard(
            icon: Icons.alt_route,
            title: 'Single-Point Multiple Drop',
            subtitle:
                'One pickup, multiple drop-offs in a single journey.',
          ),
        ],
      ),
    );
  }

  Widget _serviceCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return InkWell(
      onTap: _onServiceCardTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0xFFE8E8E8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.appColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 22, color: AppColors.appColor),
            ),
            const SizedBox(width: 12),
            // Expanded so the copy wraps instead of overflowing — as a bare Row
            // child it would get unbounded width and never wrap.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_outward, size: 18, color: AppColors.appColor),
          ],
        ),
      ),
    );
  }

  // ─── MAP SECTION (lazy-loaded, only renders when location is ready) ───
  /// "Delivery chahiye? / Movezy kar dega aaj" card, per the design.
  ///
  /// The map on the right stays the LIVE one with real nearby-driver markers
  /// rather than a flat picture — same artwork role in the layout, but it
  /// actually reflects who is around.
  Widget _buildNearbyMap() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () => _navigateAndRefresh(
          SearchScreen(bookingData: BookingData(allVehicles: _vehicleTypes)),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFECECEC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              // Expanded so the headline wraps instead of overflowing next to
              // the fixed-width map.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 10, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Delivery chahiye?',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black),
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black),
                          children: [
                            TextSpan(
                                text: 'Movezy ',
                                style: TextStyle(color: AppColors.appColor)),
                            const TextSpan(text: 'kar dega aaj'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(9),
                  bottomRight: Radius.circular(9),
                ),
                child: SizedBox(
                  width: 191,
                  height: 107,
                  child: _mapReady ? _buildMapWidget() : _buildMapPlaceholder(),
                ),
              ),
            ],
          ),
        ),
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
      // Compact: this sits in the 150x120 slot of the "Delivery chahiye?" card,
      // so the label is short and padded rather than a full-width sentence.
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.appColor),
              ),
              const SizedBox(height: 8),
              Text(
                "Finding vehicles…",
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], fontSize: 11.5),
              ),
            ],
          ),
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

  /// Shown when the vehicle list can't be loaded.
  ///
  /// This used to render four hardcoded vehicles ("Tempu", "Large Truck"...)
  /// as though they were the real catalog. None of them carry a vehicleTypeId,
  /// so tapping one could not price or book anything — and they don't even
  /// match the live catalog, which is 2 Wheeler / 3 wheeler / Scooter. An
  /// honest failure the customer can retry beats a menu of vehicles that
  /// don't exist.
  Widget _buildVehicleLoadError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.local_shipping_outlined,
              size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            "Couldn't load vehicles",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            "Check your connection and try again.",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text("Retry"),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.appColor,
              side: BorderSide(color: AppColors.appColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicVehicleBox(HomeVehicleType vehicle) {
    return InkWell(
      onTap: () => _onVehicleTapped(vehicle),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The art takes whatever height the two labels leave — a bit over
            // half the tile, as the design has it. Expanded rather than a fixed
            // 84px so the image shrinks on a narrow screen or at a large font
            // scale instead of overflowing the cell.
            Expanded(
              child: vehicle.image != null && vehicle.image!.isNotEmpty
                  ? Image.network(
                      ApiUrls.imageProxyUrl(vehicle.image!),
                      width: double.infinity,
                      // Only cacheHeight: passing both dimensions decodes to
                      // exactly that box and can distort the art's aspect.
                      cacheHeight: 220,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.appColor));
                      },
                      errorBuilder: (_, _, _) => FittedBox(fit: BoxFit.contain, child: Icon(Icons.local_shipping, size: 70, color: AppColors.appColor)),
                    )
                  : FittedBox(fit: BoxFit.contain, child: Icon(Icons.local_shipping, size: 70, color: AppColors.appColor)),
            ),
            const SizedBox(height: 8),
            Text(vehicle.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            // "10kg, 2 Feet" as the design has it, when the catalog carries the
            // dimension. Most vehicle types here don't, so fall back to the
            // price rather than print "0 Feet".
            Text(
              vehicle.dimensionsLabel.isNotEmpty
                  ? "${vehicle.capacityLabel}, ${vehicle.dimensionsLabel}"
                  : "${vehicle.capacityLabel}, Starting ₹${vehicle.baseFare.toInt()}",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
                        // Flexible: as a bare Row child the server-driven code
                        // got unbounded width, so a long code could never
                        // ellipsize and pushed the row past the card.
                        Flexible(
                          child: Text(promo.code,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                  color: Colors.orange,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Counter + page dashes, per the design ("1\3" over three small
              // bars with the active one orange).
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                      "${_currentPromoIndex + 1}/${_promoBanners.length}",
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < _promoBanners.length; i++)
                        Container(
                          width: 8,
                          height: 3,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: i == _currentPromoIndex
                                ? HexColor("#FF6200")
                                : Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // No real promos → show nothing.
    // This used to fall back to a hardcoded "Flat 20% Off Second Order / Use
    // Code: MOVEZY1" card. No such promo exists server-side, so anyone who
    // typed it got "Invalid promo code" — an advert for a discount we don't
    // honour. Better an empty space than a broken promise.
    return const SizedBox.shrink();
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
            // Expanded, replacing a bare Text + Spacer: the Spacer left the
            // label unbounded, so icon + label + both buttons already didn't
            // fit on a narrow screen. Expanded claims the same free space the
            // Spacer did — buttons still sit right — but lets the label shrink.
            Expanded(
              child: Text("Have a\nGST Number?",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.bold)),
            ),
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
                  // Flexible: a bare Text in this Row had unbounded width, so at
                  // a large font scale the title collided with the close button
                  // instead of ellipsizing.
                  Flexible(
                    child: Text("Choose your service",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                  ),
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