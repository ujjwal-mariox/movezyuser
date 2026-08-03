import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:latlong2/latlong.dart';
import 'package:movezy_user_app/Services/routing_service.dart';

/// Full-screen live route map: pickup, drop, and the driver's live position.
///
/// The trip screen previously showed a static route illustration, so there was
/// nowhere in the app to actually watch the driver move. Positions are pushed in
/// from TripDetailsScreen, which owns the socket subscription — this screen just
/// renders whatever it is handed and re-centres when the driver moves.
class LiveTrackingMapScreen extends StatefulWidget {
  final LatLng? pickup;
  final LatLng? drop;
  final LatLng? driver;
  final String pickupAddress;
  final String dropAddress;
  final String driverName;
  final String statusLabel;

  /// Emits the driver's latest position as it arrives on the parent's socket.
  final Stream<LatLng>? driverStream;

  const LiveTrackingMapScreen({
    super.key,
    required this.pickup,
    required this.drop,
    this.driver,
    this.pickupAddress = '',
    this.dropAddress = '',
    this.driverName = '',
    this.statusLabel = '',
    this.driverStream,
  });

  @override
  State<LiveTrackingMapScreen> createState() => _LiveTrackingMapScreenState();
}

class _LiveTrackingMapScreenState extends State<LiveTrackingMapScreen> {
  /// Road geometry pickup → drop. Empty until it arrives; the straight line
  /// is drawn meanwhile so the map is never blank.
  List<LatLng> _roadRoute = const [];

  Future<void> _loadRoute() async {
    final from = widget.pickup;
    final to = widget.drop;
    if (from == null || to == null) return;
    final points = await RoutingService.route(from, to);
    if (mounted) setState(() => _roadRoute = points);
  }

  final MapController _map = MapController();
  LatLng? _driver;
  bool _follow = true;

  @override
  void initState() {
    super.initState();
    _loadRoute();
    _driver = widget.driver;
    widget.driverStream?.listen((pos) {
      if (!mounted) return;
      setState(() => _driver = pos);
      if (_follow) _map.move(pos, _map.camera.zoom);
    });
  }

  /// Frame everything we know about, so the user sees the whole route at once.
  LatLngBounds? get _bounds {
    final pts = [widget.pickup, widget.drop, _driver].whereType<LatLng>().toList();
    if (pts.length < 2) return null;
    var minLat = pts.first.latitude, maxLat = pts.first.latitude;
    var minLng = pts.first.longitude, maxLng = pts.first.longitude;
    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(
      LatLng(minLat - 0.01, minLng - 0.01),
      LatLng(maxLat + 0.01, maxLng + 0.01),
    );
  }

  LatLng get _center =>
      _driver ?? widget.pickup ?? widget.drop ?? const LatLng(28.6139, 77.2090);

  Marker _pin(LatLng at, IconData icon, Color color) => Marker(
        point: at,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );

  @override
  Widget build(BuildContext context) {
    // Real road geometry when it has arrived, else the two endpoints so the
    // map still shows the connection.
    final route = _roadRoute.isNotEmpty
        ? _roadRoute
        : [widget.pickup, widget.drop].whereType<LatLng>().toList();

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13,
              initialCameraFit: _bounds != null
                  ? CameraFit.bounds(bounds: _bounds!, padding: const EdgeInsets.all(60))
                  : null,
              // Any manual gesture means the user wants to look around — stop
              // yanking the camera back to the driver.
              onPositionChanged: (_, hasGesture) {
                if (hasGesture && _follow) setState(() => _follow = false);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.movezy_user_app',
              ),
              if (route.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: route,
                      strokeWidth: 3,
                      color: HexColor("#FF6200").withValues(alpha: 0.6),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (widget.pickup != null)
                    _pin(widget.pickup!, Icons.trip_origin, HexColor("#2E9E5B")),
                  if (widget.drop != null)
                    _pin(widget.drop!, Icons.location_on, HexColor("#EE3E35")),
                  if (_driver != null)
                    _pin(_driver!, Icons.local_shipping, HexColor("#FF6200")),
                ],
              ),
            ],
          ),

          // Back + status
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                      ),
                      child: const Icon(Icons.arrow_back, size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (widget.statusLabel.isNotEmpty)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 6)
                          ],
                        ),
                        child: Text(
                          widget.statusLabel.replaceAll('\n', ' '),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Re-centre — only offered once the user has panned away.
          if (!_follow && _driver != null)
            Positioned(
              right: 14,
              bottom: 130,
              child: FloatingActionButton.small(
                heroTag: 'recenter',
                backgroundColor: Colors.white,
                onPressed: () {
                  setState(() => _follow = true);
                  _map.move(_driver!, 15);
                },
                child: Icon(Icons.my_location, color: HexColor("#FF6200")),
              ),
            ),

          // Address card
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_driver == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        widget.driverName.isNotEmpty
                            ? "Waiting for ${widget.driverName}'s location…"
                            : "Driver location not available yet",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  _addressRow(
                      Icons.trip_origin, HexColor("#2E9E5B"), widget.pickupAddress),
                  const SizedBox(height: 8),
                  _addressRow(
                      Icons.location_on, HexColor("#EE3E35"), widget.dropAddress),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressRow(IconData icon, Color color, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text.isEmpty ? '—' : text,
              style: const TextStyle(fontSize: 12.5),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
}
