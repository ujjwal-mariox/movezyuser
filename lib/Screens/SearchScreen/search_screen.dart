import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movezy_user_app/CommonWidgets/location_icon.dart';
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
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:movezy_user_app/Services/routing_service.dart';
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

  /// Intermediate stops between pickup and drop ("+ ADD STOP" in the design).
  /// The backend has always modelled booking.stops and charged per stop; the
  /// app simply had no way to add one.
  final List<_Stop> _stops = [];
  static const int _maxStops = 3;
  bool _locatingPickup = false;

  /// "Recent places" from the design: the PLACES this customer has been to,
  /// not the orders they placed. Derived from booking history because that is
  /// the only record of where they have actually been — a booking's pickup,
  /// drop and stops each carry an address plus real coordinates.
  List<_RecentPlace> _recentPlaces = [];

  /// Place keys the customer has cleared. Keyed by rounded coordinates rather
  /// than booking id: the same place reached through two different bookings is
  /// one entry in this list, so clearing it must clear both.
  static const String _dismissedRecentKey = 'dismissed_recent_places';
  bool _loadingRecent = true;

  /// Where the customer is now, used for the distance shown on the right of
  /// each row. Null until located — the distance is then omitted rather than
  /// guessed, since a wrong distance is worse than none.
  double? _hereLat, _hereLng;

  /// Road geometry for the route preview under the address fields. The design
  /// shows the trip drawn on a map as stops are added, so the customer can see
  /// the detour a stop causes before committing to it.
  List<LatLng> _previewRoute = const [];
  final MapController _previewMapController = MapController();

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
    _fetchRecentPlaces();
    _refreshPreviewRoute();
  }

  /// Remember what was cleared, so it stays cleared.
  ///
  /// These places are derived from real booking history and there is no
  /// endpoint to hide a booking (and deleting one would be wrong), so the
  /// dismissal is remembered locally — "Clear All" used to empty the list in
  /// memory only, and every entry came straight back on the next visit.
  Future<void> _clearRecentPlaces() async {
    final dismissed = Prefs.getStringList(_dismissedRecentKey).toSet()
      ..addAll(_recentPlaces.map((p) => p.key));
    await Prefs.setStringList(_dismissedRecentKey, dismissed.toList());
    if (mounted) setState(() => _recentPlaces.clear());
  }

  /// Build "Recent places" from booking history.
  ///
  /// A booking records where the customer actually went — pickup, drop and any
  /// intermediate stops — each with an address AND coordinates. Those are the
  /// places. The previous version listed BOOKINGS instead ("Tata Ace • #MZ0007"),
  /// which is a different thing and is what the design's Recent places section
  /// replaced. More bookings are pulled than rows shown because several
  /// bookings commonly share a place, and duplicates collapse into one entry.
  Future<void> _fetchRecentPlaces() async {
    try {
      final token = Prefs.getString('token');
      if (token.isEmpty) {
        if (mounted) setState(() => _loadingRecent = false);
        return;
      }
      final response = await http.get(
        Uri.parse('${ApiUrls.userBookingsUrl}?page=1&limit=15'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode != 200) {
        if (mounted) setState(() => _loadingRecent = false);
        return;
      }

      final json = jsonDecode(response.body);
      final List bookings = json['data']?['bookings'] ?? [];
      final dismissed = Prefs.getStringList(_dismissedRecentKey).toSet();

      // Newest first, de-duplicated by rounded coordinates: ~4 decimal places
      // is roughly 11 m, close enough that two pins that far apart are the
      // same doorway.
      final seen = <String>{};
      final places = <_RecentPlace>[];
      for (final b in bookings) {
        for (final raw in [b['pickup'], b['drop'], ...?(b['stops'] as List?)]) {
          final place = _RecentPlace.fromLocation(raw);
          if (place == null) continue;
          if (dismissed.contains(place.key)) continue;
          if (!seen.add(place.key)) continue;
          places.add(place);
        }
      }

      if (mounted) {
        setState(() {
          _recentPlaces = places.take(5).toList();
          _loadingRecent = false;
        });
      }
      _resolveDistances();
    } catch (e) {
      debugPrint('Fetch recent places error: $e');
      if (mounted) setState(() => _loadingRecent = false);
    }
  }

  /// Fill in the distance shown on each row, once we know where the user is.
  /// Best-effort: if permission is denied or the fix fails, the rows simply
  /// render without a distance.
  Future<void> _resolveDistances() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        // Low accuracy is plenty for a "2.7km" label and returns fast; the
        // time limit stops a poor fix from leaving the rows blank forever.
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      );
      if (!mounted) return;
      setState(() {
        _hereLat = pos.latitude;
        _hereLng = pos.longitude;
      });
    } catch (e) {
      debugPrint('Recent places distance lookup skipped: $e');
    }
  }

  /// True once there is a route worth drawing — used to swap the address
  /// pickers for the map preview.
  bool get _hasRoutePreview => _routeWaypoints.length >= 2;

  /// Every point of the trip, in the order it is travelled: pickup, each stop
  /// that has coordinates, then drop. Used for both the map markers and the
  /// route geometry.
  List<LatLng> get _routeWaypoints => [
        if (_pickupLat != null && _pickupLng != null)
          LatLng(_pickupLat!, _pickupLng!),
        for (final st in _stops)
          if (st.hasCoords) LatLng(st.lat!, st.lng!),
        if (_dropLat != null && _dropLng != null) LatLng(_dropLat!, _dropLng!),
      ];

  /// Redraw the preview whenever the trip changes — a stop added, removed, or
  /// given a location. Falls back to straight segments when routing is
  /// unavailable, so the map is never blank while points exist.
  Future<void> _refreshPreviewRoute() async {
    final pts = _routeWaypoints;
    if (pts.length < 2) {
      if (mounted) setState(() => _previewRoute = const []);
      return;
    }
    final drawn = <LatLng>[];
    for (var i = 0; i < pts.length - 1; i++) {
      drawn.addAll(await RoutingService.route(pts[i], pts[i + 1]));
    }
    if (!mounted) return;
    setState(() => _previewRoute = drawn.length >= 2 ? drawn : pts);
    _fitPreviewToRoute();
  }

  /// Frame the whole trip. Without this the map stays on its initial centre and
  /// a stop added far away simply falls outside the visible area.
  void _fitPreviewToRoute() {
    final pts = _previewRoute.isNotEmpty ? _previewRoute : _routeWaypoints;
    if (pts.length < 2) return;
    try {
      _previewMapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(pts),
          padding: const EdgeInsets.all(36),
        ),
      );
    } catch (_) {
      // The controller is not attached until the map is laid out; the next
      // refresh after layout will frame it.
    }
  }

  /// Straight-line km from the user to a place, or null when we cannot say.
  double? _distanceKmTo(_RecentPlace p) {
    if (_hereLat == null || _hereLng == null) return null;
    const d = Distance();
    return d.as(
          LengthUnit.Meter,
          LatLng(_hereLat!, _hereLng!),
          LatLng(p.lat, p.lng),
        ) /
        1000.0;
  }


  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    for (final s in _stops) {
      s.controller.dispose();
    }
    super.dispose();
  }

  void _addStop() {
    if (_stops.length >= _maxStops) return;
    setState(() => _stops.add(_Stop()));
  }

  void _removeStop(int index) {
    setState(() {
      _stops[index].controller.dispose();
      _stops.removeAt(index);
    });
    // The route shortens as soon as the stop is gone.
    _refreshPreviewRoute();
  }

  /// Pick a stop's location on the map. A stop is only usable with real
  /// coordinates, so this always goes through the picker.
  Future<void> _pickStopLocation(int index) async {
    final stop = _stops[index];
    final result = await Navigator.push<MapPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          title: 'Pick Stop ${index + 1}',
          initialLocation:
              stop.lat != null ? LatLng(stop.lat!, stop.lng!) : null,
          initialAddress: stop.controller.text,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      stop.controller.text = result.address;
      stop.lat = result.lat;
      stop.lng = result.lng;
    });
    _refreshPreviewRoute();
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
      _refreshPreviewRoute();
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
    _refreshPreviewRoute();
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
        _refreshPreviewRoute();
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
  /// One numbered stop row: badge, address (tap to pick on map), remove.
  /// The design's route preview: the trip drawn on a map directly under the
  /// address fields, so a stop's detour is visible before the customer
  /// commits. Nothing is shown until there are at least two points to join —
  /// an empty map would just be a grey rectangle.
  Widget _routePreviewMap() {
    final pts = _routeWaypoints;
    if (pts.length < 2) return const SizedBox.shrink();

    final line = _previewRoute.isNotEmpty ? _previewRoute : pts;
    final pickup = pts.first;
    final last = pts.last;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 260,
          child: FlutterMap(
            mapController: _previewMapController,
            options: MapOptions(
              initialCenter: pickup,
              initialZoom: 11,
              // A preview, not a map screen: taps belong to the fields above,
              // and a scrollable map inside a scrollable page fights the page.
              interactionOptions:
                  const InteractionOptions(flags: InteractiveFlag.none),
              onMapReady: _fitPreviewToRoute,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.movezy_user_app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: line,
                    strokeWidth: 4,
                    color: HexColor('#2D5BE3'),
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Pickup — the green pin the design puts at the origin.
                  Marker(
                    point: pickup,
                    width: 34,
                    height: 42,
                    alignment: Alignment.topCenter,
                    child: Icon(Icons.location_on,
                        size: 34, color: HexColor('#22A447')),
                  ),
                  // Each intermediate stop carries its number, matching the
                  // numbered badge on its field above.
                  for (var i = 1; i < pts.length - 1; i++)
                    Marker(
                      point: pts[i],
                      width: 30,
                      height: 38,
                      alignment: Alignment.topCenter,
                      child: _numberedPin('$i'),
                    ),
                  // Final drop.
                  if (pts.length > 1)
                    Marker(
                      point: last,
                      width: 30,
                      height: 38,
                      alignment: Alignment.topCenter,
                      child: _numberedPin('${pts.length - 1}'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Red teardrop with a white number, as the design draws each stop.
  Widget _numberedPin(String label) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Icon(Icons.location_on, size: 34, color: HexColor('#E23B32')),
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _stopRow(int index) {
    final stop = _stops[index];
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          const SizedBox(width: 15),
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            // Orange tile, white numeral — the design's numbered badge. It
            // was inverted (white tile, orange numeral), which read as a
            // disabled field rather than an ordered stop.
            decoration: BoxDecoration(
              color: HexColor('#E85D18'),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _pickStopLocation(index),
              child: Container(
                height: 45,
                margin: const EdgeInsets.only(left: 10, right: 15),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        stop.controller.text.isEmpty
                            ? 'Where is your Stop ${index + 1}?'
                            : stop.controller.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: stop.controller.text.isEmpty
                              ? Colors.grey
                              : Colors.black,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _removeStop(index),
                      child: const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(Icons.close, size: 18, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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

    // A stop without coordinates can't be routed or priced — make the user
    // finish it rather than silently dropping it from the trip.
    final incomplete = _stops.indexWhere(
        (s) => s.controller.text.trim().isNotEmpty && !s.hasCoords);
    if (incomplete != -1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Pick Stop ${incomplete + 1} on the map so we can route to it.")),
        );
      }
      return;
    }

    final data = (widget.bookingData ?? BookingData()).copyWith(
      pickupAddress: pickup,
      dropAddress: drop,
      pickupLat: _pickupLat,
      pickupLng: _pickupLng,
      dropLat: _dropLat,
      dropLng: _dropLng,
      stops: _stops.where((s) => s.hasCoords).map((s) => s.toJson()).toList(),
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
          // The page scrolls; the Search button below stays pinned.
          //
          // Making the header content-sized (so it grows with each stop) only
          // moved the overflow up a level: this root Column never scrolled, so
          // the growth pushed the page past the viewport instead of clipping
          // inside the header. It overflowed a 320x568 screen by ~103px with
          // ZERO stops, and a 360x640 by ~158px with three — the stops feature
          // was unusable on any sub-800dp-tall device.
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
          Container(
              // Sizes to its content. This was a hard-coded 285px that predates
              // the stops feature: each stop row adds ~55px, so adding even one
              // overflowed the header and clipped the stop rows and the ADD STOP
              // button — on the very first tap of the feature. The design shows
              // the header growing with each stop.
              width: MediaQuery.of(context).size.width,
              decoration:  BoxDecoration(
                color: AppColors.appColor,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(25), bottomRight: Radius.circular(25))
              ),
              child: Container(
                padding: const EdgeInsets.only(top: 50, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row
                    Row(
                      children: [
                        SizedBox(width: 5,),
                        // Expanded: as a bare Row child this inner Row got
                        // unbounded width, so the title laid out at its intrinsic
                        // width and could never ellipsize. Bounding it here is
                        // what lets the Expanded below have space to divide.
                        Expanded(
                          child: Row(
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
                              // Expanded + ellipsis: the back arrow is a fixed 40px,
                              // so the title takes the rest instead of its intrinsic
                              // width. At default scale it fits (~195px of ~275px) and
                              // looks unchanged; at a 1.5x+ text scale it used to run
                              // off a 320dp screen.
                              Expanded(
                                child: Text(
                                  "Add Location to Proceed",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                          child: const LocationIcon.pickup(),
                        ),

                        Expanded(child: Container(
                            margin: EdgeInsets.only(left: 10, right: 15),
                            padding: const EdgeInsets.only(left: 15, right: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            // readOnly + onTap instead of AbsorbPointer. The
                            // AbsorbPointer wrapped the whole TextField —
                            // suffixIcon included — so the GPS crosshair could
                            // never be tapped: the hit was swallowed and fell
                            // through to the map picker, leaving
                            // _useCurrentLocation() unreachable dead code.
                            child: TextField(
                                controller: _pickupController,
                                readOnly: true,
                                onTap: () => _openMapPicker(isPickup: true),
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
                        )
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
                          child: const LocationIcon.drop(),
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

                    // ── Stops between pickup and drop ──
                    ..._stops.asMap().entries.map((e) => _stopRow(e.key)),

                    if (_stops.length < _maxStops)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Center(
                          child: InkWell(
                            onTap: _addStop,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.add_circle,
                                      color: Colors.white, size: 18),
                                  SizedBox(width: 7),
                                  Text(
                                    "ADD STOP",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                  ],
                ),
              )
          ),

          // Route preview — the design shows the trip on a map as stops
          // are added.
          _routePreviewMap(),

          SizedBox(height: 20,),

          // Saved Addresses and Recent places are the ways to START a trip.
          // Once pickup and drop are set the route preview above replaces
          // them, as in the design — keeping pickers on screen below a drawn
          // route is just noise the customer has to scroll past.
          if (!_hasRoutePreview) ...[
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


            // ─── RECENT PLACES (real data) ───
            // The design's section: places the customer has been to, with the
            // distance from where they are now. It replaced a "Recent
            // Deliveries" list that showed ORDERS ("Tata Ace • #MZ0007") — a
            // different thing, and not what the design asks for.
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Text(
                    "Recent places",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (_recentPlaces.isNotEmpty)
                    InkWell(
                      onTap: _clearRecentPlaces,
                      child: Text(
                        "Clear All",
                        style: TextStyle(
                          color: HexColor('#F4BE05'),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (_loadingRecent)
              Container(
                color: Colors.white,
                height: 80,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_recentPlaces.isEmpty)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Text(
                  "Places you travel to will appear here.",
                  style: TextStyle(color: HexColor("#777777"), fontSize: 13),
                ),
              )
            else
              Container(
                color: Colors.white,
                child: Column(
                  children: _recentPlaces.map((place) {
                    final km = _distanceKmTo(place);
                    return InkWell(
                      onTap: () {
                        // Fill the drop field, WITH coordinates. A tap that set
                        // only the text left the downstream screens to guess the
                        // coordinates, which priced a route the customer had not
                        // chosen.
                        setState(() {
                          _dropController.text = [place.name, place.address]
                              .where((e) => e.isNotEmpty)
                              .join(', ');
                          _dropLat = place.lat;
                          _dropLng = place.lng;
                        });
                        _refreshPreviewRoute();
                      },
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.access_time,
                                size: 22,
                                color: HexColor("#9E9E9E"),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    place.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (place.address.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      place.address,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: HexColor("#9E9E9E"),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Distance is omitted entirely when the user's
                            // position is unknown — a made-up number here would
                            // be indistinguishable from a real one.
                            if (km != null) ...[
                              const SizedBox(width: 12),
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  km < 10
                                      ? "${km.toStringAsFixed(1)}km"
                                      : "${km.round()}km",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

          ],
          // NOTE: a hardcoded "Popular in your area" list (Railway Station /
          // Airport Terminal / City Bus Stand / Industrial Area) used to live
          // here. It is not in the design — which has Saved Addresses + Recent
          // places — and it was actively harmful: tapping an entry only set the
          // drop TEXT with no coordinates, and the downstream screens then
          // substituted fixed Delhi/Noida coords, so the user saw fares for a
          // route that wasn't theirs and could book to the wrong place.
          // The Spacer that was here is gone: a Spacer inside a
          // SingleChildScrollView's Column asserts on unbounded height, and it
          // clamped to 0 and absorbed nothing once space went negative anyway.
                ],
              ),
            ),
          ),

          // Search / Proceed button — outside the scroll view so it stays
          // reachable no matter how tall the content gets.
          Container(
            width: double.infinity,
            // Vertical 12 is the design's gap; the device's real bottom inset
            // (gesture bar / nav buttons) is added to the bottom only, so the
            // Search button is never partly underneath the system UI.
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
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
                    "search vehicle",
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

/// An intermediate stop between pickup and drop.
///
/// Only usable once it has real coordinates — an address string alone can't be
/// routed or priced, and inventing coordinates is exactly what caused the old
/// "fares for a Delhi route you never asked for" bug.
/// One entry in the design's "Recent places" list.
///
/// A booking location has an `address` and coordinates but NO name field, so
/// the title is taken from the leading segment of the address — for
/// "Sector 62 Office, Noida, UP" that yields "Sector 62 Office", which is what
/// a person calls the place. When the address has no comma there is nothing to
/// split, so the whole string becomes the title and the subtitle is dropped
/// rather than repeating it.
class _RecentPlace {
  final String name;
  final String address;
  final double lat;
  final double lng;

  const _RecentPlace({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
  });

  /// Identity for de-duplication and for remembering a dismissal. ~4 decimal
  /// places is about 11 m — two pins closer than that are the same doorway,
  /// and the same place reached via different bookings must collapse to one.
  String get key => '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';

  /// Null when the location is unusable — no address, or no coordinates. A row
  /// without coordinates could not be tapped to fill a field (the downstream
  /// screens need lat/lng to price the trip) and could not show a distance, so
  /// it is dropped instead of rendered as a dead entry.
  static _RecentPlace? fromLocation(dynamic raw) {
    if (raw is! Map) return null;
    final address = (raw['address'] ?? '').toString().trim();
    final lat = (raw['lat'] as num?)?.toDouble();
    final lng = (raw['lng'] as num?)?.toDouble();
    if (address.isEmpty || lat == null || lng == null) return null;

    final parts = address.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final name = parts.isNotEmpty ? parts.first : address;
    final rest = parts.length > 1 ? parts.sublist(1).join(', ') : '';

    return _RecentPlace(name: name, address: rest, lat: lat, lng: lng);
  }
}

class _Stop {
  final TextEditingController controller = TextEditingController();
  double? lat;
  double? lng;

  bool get hasCoords => lat != null && lng != null;

  /// Shape the backend expects for booking.stops.
  Map<String, dynamic> toJson() => {
        'address': controller.text.trim(),
        'lat': lat,
        'lng': lng,
      };
}
