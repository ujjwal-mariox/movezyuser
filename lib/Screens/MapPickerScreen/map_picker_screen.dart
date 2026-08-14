import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Result returned when user confirms a location on the map.
class MapPickerResult {
  final String address;
  final double lat;
  final double lng;

  MapPickerResult({required this.address, required this.lat, required this.lng});
}

/// Full-screen map picker with search bar, pin-drop, and confirm button.
/// Uses OpenStreetMap tiles (free, no API key).
class MapPickerScreen extends StatefulWidget {
  final String title; // "Pick Pickup Location" or "Pick Drop Location"
  final LatLng? initialLocation;
  final String? initialAddress;

  const MapPickerScreen({
    super.key,
    this.title = 'Pick Location',
    this.initialLocation,
    this.initialAddress,
  });

  /// Which of the standard location icons the address field shows. Derived
  /// from the title rather than a new required parameter so the existing call
  /// sites (pickup, drop, stops, saved-address) keep working unchanged —
  /// anything that is not explicitly a pickup gets the drop/destination
  /// marker, which is also right for stops.
  bool get isPickup => title.toLowerCase().contains('pickup');

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late final MapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  LatLng _selectedLocation = const LatLng(28.6139, 77.2090); // Default Delhi
  String _selectedAddress = 'Move the map to select location';
  bool _isLoadingAddress = false;
  bool _isSearching = false;
  bool _showSearchResults = false;
  List<_SearchResult> _searchResults = [];
  Timer? _debounce;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation!;
    }
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _selectedAddress = widget.initialAddress!;
    }
    // If no initial location, try to get user's current location
    if (widget.initialLocation == null) {
      _goToCurrentLocation(animate: false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Reverse geocode center pin location
  Future<void> _reverseGeocode(LatLng pos) async {
    setState(() => _isLoadingAddress = true);
    try {
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final parts = [
          p.name,
          p.subLocality,
          p.locality,
          p.administrativeArea,
        ].where((s) => s != null && s.isNotEmpty).toList();
        setState(() {
          _selectedAddress = parts.join(', ');
          _selectedLocation = pos;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedAddress = '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
          _selectedLocation = pos;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  /// Search places using Nominatim (OSM free geocoding API)
  Future<void> _searchPlaces(String query) async {
    if (query.trim().length < 3) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?'
        'q=${Uri.encodeComponent(query)}'
        '&format=json&addressdetails=1&limit=5'
        '&countrycodes=in',
      );
      final res = await http.get(url, headers: {
        'User-Agent': 'MovezyApp/1.0',
        'Accept-Language': 'en',
      });

      if (res.statusCode == 200 && mounted) {
        final List data = json.decode(res.body);
        setState(() {
          _searchResults = data.map((item) {
            return _SearchResult(
              displayName: item['display_name'] ?? '',
              lat: double.tryParse(item['lat']?.toString() ?? '') ?? 0,
              lng: double.tryParse(item['lon']?.toString() ?? '') ?? 0,
            );
          }).toList();
          _showSearchResults = _searchResults.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  /// Go to user's current GPS location
  Future<void> _goToCurrentLocation({bool animate = true}) async {
    setState(() => _isLocating = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      final newPos = LatLng(pos.latitude, pos.longitude);
      if (mounted) {
        if (animate) {
          _mapController.move(newPos, 16.0);
        } else {
          _selectedLocation = newPos;
        }
        _reverseGeocode(newPos);
      }
    } catch (e) {
      debugPrint('Location error: $e');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchPlaces(query);
    });
  }

  void _selectSearchResult(_SearchResult result) {
    final pos = LatLng(result.lat, result.lng);
    _mapController.move(pos, 16.0);
    setState(() {
      _selectedLocation = pos;
      _selectedAddress = result.displayName;
      _showSearchResults = false;
      _searchController.text = '';
    });
    _searchFocus.unfocus();
  }

  /// Placeholder/transient labels that must never escape as a real address.
  static const _placeholderAddresses = {
    'Move the map to select location',
    'Loading...',
    'Address not found',
    '',
  };

  bool get _addressResolved =>
      !_placeholderAddresses.contains(_selectedAddress.trim());

  void _confirmLocation() {
    // This used to return _selectedAddress unconditionally. When reverse
    // geocoding hadn't finished (or failed), the UI placeholder itself was
    // returned and persisted as the booking's address — which is why real
    // bookings carry a drop address of "Move the map to select location".
    // Coordinates are always known here, so they're the honest fallback.
    final address = _addressResolved
        ? _selectedAddress
        : '${_selectedLocation.latitude.toStringAsFixed(5)}, '
            '${_selectedLocation.longitude.toStringAsFixed(5)}';

    Navigator.pop(
      context,
      MapPickerResult(
        address: address,
        lat: _selectedLocation.latitude,
        lng: _selectedLocation.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The device's real bottom system inset (gesture bar / 3-button nav). The
    // confirm card below used to end in a hardcoded 28px guess, so on any phone
    // whose inset is larger the "Confirm Location" button sat under the system
    // UI and could not be tapped.
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ─── MAP ─────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 15.0,
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture && pos.center != null) {
                  setState(() {
                    _selectedLocation = pos.center!;
                    _selectedAddress = 'Loading...';
                    _isLoadingAddress = true;
                  });
                }
              },
              onMapEvent: (event) {
                // Reverse geocode on map move end
                if (event is MapEventMoveEnd) {
                  _reverseGeocode(_selectedLocation);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.movezy_user_app',
                maxZoom: 19,
              ),
            ],
          ),

          // ─── CENTER PIN (always in the middle of the map) ───
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 36),
              child: Icon(
                Icons.location_on,
                size: 48,
                color: HexColor("#FF6200"),
              ),
            ),
          ),

          // ─── SHADOW under pin ───
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 10,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // ─── TOP BAR: Back + Search ──────────────────
          SafeArea(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, size: 22),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Search for area, street name...',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ),
                      if (_isSearching)
                        const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else if (_searchController.text.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                              _showSearchResults = false;
                            });
                          },
                          icon: const Icon(Icons.close, size: 20),
                        ),
                    ],
                  ),
                ),

                // ─── SEARCH RESULTS DROPDOWN ───
                if (_showSearchResults)
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                    constraints: const BoxConstraints(maxHeight: 250),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: Colors.grey[200]),
                      itemBuilder: (context, index) {
                        final r = _searchResults[index];
                        return ListTile(
                          dense: true,
                          leading: Icon(Icons.location_on_outlined,
                              color: HexColor("#FF6200"), size: 20),
                          title: Text(
                            r.displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                          onTap: () => _selectSearchResult(r),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // ─── MY LOCATION FAB ─────────────────────────
          Positioned(
            right: 16,
            // Shifts by the same inset as the card below it, so it keeps the
            // clearance it was designed with instead of being swallowed by the
            // card once that card grows.
            bottom: 200 + bottomInset,
            child: FloatingActionButton.small(
              heroTag: 'myLocation',
              backgroundColor: Colors.white,
              onPressed: _isLocating ? null : () => _goToCurrentLocation(),
              child: _isLocating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.my_location, color: HexColor("#FF6200"), size: 22),
            ),
          ),

          // ─── BOTTOM CARD: Address + Confirm ──────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              // 28 is the gap the design asks for; the device's bottom inset is
              // ADDED to it (never hardcoded) so the Confirm button clears the
              // gesture bar / nav buttons on every device.
              padding: EdgeInsets.fromLTRB(20, 18, 20, 28 + bottomInset),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Same pair as every other address field: the pickup pin
                      // while choosing a pickup, the drop marker while choosing
                      // a drop. This was a one-off orange Material pin found
                      // nowhere else in the flow.
                      Image.asset(
                        widget.isPickup
                            ? "assets/pic_up_location.png"
                            : "assets/drop_up_location.png",
                        width: 22,
                        height: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _isLoadingAddress
                            ? Row(
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: HexColor("#FF6200"),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Getting address...',
                                      style: GoogleFonts.poppins(
                                          fontSize: 13, color: Colors.grey)),
                                ],
                              )
                            : Text(
                                _selectedAddress,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoadingAddress ? null : _confirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HexColor("#FF6200"),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Confirm Location',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
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

class _SearchResult {
  final String displayName;
  final double lat;
  final double lng;

  _SearchResult({
    required this.displayName,
    required this.lat,
    required this.lng,
  });
}
