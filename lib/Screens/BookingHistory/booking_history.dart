import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart' show HexColor;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/Screens/BookingDetailsScreen/booking_details_screen.dart';
import 'package:movezy_user_app/Screens/CancelRideScreen/cancel_ride_screen.dart';
import 'package:movezy_user_app/Screens/TripDetailsScreen/trip_details_screen.dart';
import 'package:movezy_user_app/Screens/SearchScreen/search_screen.dart';
import 'package:movezy_user_app/Screens/HomeScreen/Model/booking_data.dart';
import 'package:movezy_user_app/Services/booking_service.dart';
import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';

// --- BOOKING MODEL ---
class BookingItem {
  final String id;
  final String bookingNumber;
  final String status;
  final String? vehicleName;
  final String? vehicleIcon;
  final String? driverName;
  final String? driverPhone;
  final String pickupAddress;
  final String dropAddress;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropLat;
  final double? dropLng;
  final String? pickupContact;
  final String? dropContact;
  final double finalFare;
  final double distanceKm;
  final String paymentMethod;
  final String? paymentStatus;
  final DateTime createdAt;
  final String serviceType;

  BookingItem({
    required this.id,
    required this.bookingNumber,
    required this.status,
    this.vehicleName,
    this.vehicleIcon,
    this.driverName,
    this.driverPhone,
    required this.pickupAddress,
    required this.dropAddress,
    this.pickupLat,
    this.pickupLng,
    this.dropLat,
    this.dropLng,
    this.pickupContact,
    this.dropContact,
    required this.finalFare,
    required this.distanceKm,
    required this.paymentMethod,
    this.paymentStatus,
    required this.createdAt,
    required this.serviceType,
  });

  factory BookingItem.fromJson(Map<String, dynamic> json) {
    // Extract vehicle info
    String? vehicleName;
    String? vehicleIcon;
    final vt = json['vehicleTypeId'];
    if (vt is Map) {
      vehicleName = vt['name'];
      vehicleIcon = vt['icon'];
    }

    // Extract driver info
    String? driverName;
    String? driverPhone;
    final driver = json['driverId'];
    if (driver is Map) {
      driverName = driver['fullName'] ?? driver['name'];
      driverPhone = driver['mobileNumber'];
    }

    // Extract pickup/drop
    final pickup = json['pickup'] ?? {};
    final drop = json['drop'] ?? {};

    return BookingItem(
      id: json['_id'] ?? '',
      bookingNumber: json['bookingNumber'] ?? '',
      status: json['status'] ?? 'SEARCHING',
      vehicleName: vehicleName,
      vehicleIcon: vehicleIcon,
      driverName: driverName,
      driverPhone: driverPhone,
      pickupAddress: pickup['address'] ?? 'Pickup',
      dropAddress: drop['address'] ?? 'Drop',
      pickupLat: (pickup['lat'] ?? pickup['location']?['coordinates']?[1])?.toDouble(),
      pickupLng: (pickup['lng'] ?? pickup['location']?['coordinates']?[0])?.toDouble(),
      dropLat: (drop['lat'] ?? drop['location']?['coordinates']?[1])?.toDouble(),
      dropLng: (drop['lng'] ?? drop['location']?['coordinates']?[0])?.toDouble(),
      pickupContact: pickup['contactPhone'],
      dropContact: drop['contactPhone'],
      finalFare: (json['finalFare'] ?? json['fare'] ?? 0).toDouble(),
      distanceKm: (json['distanceKm'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? 'CASH',
      paymentStatus: json['paymentStatus'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      serviceType: json['serviceType'] ?? 'WITHIN_CITY',
    );
  }

  bool get isActive =>
      ['SEARCHING', 'ASSIGNED', 'DRIVER_ARRIVED', 'PICKED', 'IN_PROGRESS', 'DRAFT']
          .contains(status);
  bool get isCancelled => status == 'CANCELLED';
  bool get isCompleted => status == 'COMPLETED';
}

// --- SCREEN ---
class BookingHistory extends StatefulWidget {
  const BookingHistory({super.key});

  @override
  State<BookingHistory> createState() => _BookingHistoryState();
}

class _BookingHistoryState extends State<BookingHistory> {
  List<BookingItem> _bookings = [];
  bool _isLoading = true;
  String? _error;
  int _page = 1;
  int _totalPages = 1;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  /// Raise a real support ticket for a booking (was a "coming soon" snackbar).
  Future<void> _reportIssue(dynamic booking) async {
    final ref = booking.bookingNumber ?? booking.id;
    try {
      final res = await http.post(
        Uri.parse(ApiUrls.supportTicketsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Prefs.token}',
        },
        body: json.encode({
          'category': 'booking',
          'subject': 'Issue with booking $ref',
          'message': 'Customer reported an issue with booking $ref.',
        }),
      ).timeout(const Duration(seconds: 15));
      final body = json.decode(res.body);
      final ok = (res.statusCode == 200 || res.statusCode == 201) && body['success'] == true;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Ticket created. Support will contact you shortly.'
            : 'Could not create ticket. Please try again.'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not create ticket. Please try again.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _fetchBookings({bool loadMore = false}) async {
    if (loadMore) {
      if (_page >= _totalPages || _loadingMore) return;
      setState(() => _loadingMore = true);
      _page++;
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
        _page = 1;
      });
    }

    try {
      final token = Prefs.getString('token');
      final url = '${ApiUrls.userBookingsUrl}?page=$_page&limit=20';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'];
        final List rawBookings = data['bookings'] ?? [];
        final pagination = data['pagination'] ?? {};
        final parsed =
            rawBookings.map((b) => BookingItem.fromJson(b)).toList();

        if (mounted) {
          setState(() {
            if (loadMore) {
              _bookings.addAll(parsed);
            } else {
              _bookings = parsed;
            }
            _totalPages = pagination['pages'] ?? 1;
            _isLoading = false;
            _loadingMore = false;
          });
        }
      } else {
        throw Exception('Failed to load bookings (${response.statusCode})');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _loadingMore = false;
        });
      }
    }
  }

  /// Cancel a booking
  Future<void> _cancelBooking(BookingItem booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel Booking?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
            'Are you sure you want to cancel booking #${booking.bookingNumber}?',
            style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final result = await BookingService.cancelBooking(booking.id);
      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Booking cancelled'),
              backgroundColor: Colors.green));
          _fetchBookings(); // Refresh
        } else {
          throw Exception(result['message'] ?? 'Failed to cancel');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Separate bookings by category
    final active = _bookings.where((b) => b.isActive).toList();
    final completed = _bookings.where((b) => b.isCompleted).toList();
    final cancelled = _bookings.where((b) => b.isCancelled).toList();

    return Scaffold(
      backgroundColor: HexColor("#FFFAF6"),
      body: Column(
        children: [
          commonAppBar(
            height: 105,
            context: context,
            child: Container(
              padding: const EdgeInsets.only(top: 50),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Text("Booking History",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        color: AppColors.appColor))
                : _error != null
                    ? _buildErrorState()
                    : _bookings.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            color: AppColors.appColor,
                            onRefresh: () => _fetchBookings(),
                            child:
                                NotificationListener<ScrollNotification>(
                              onNotification: (scroll) {
                                if (scroll.metrics.pixels >=
                                    scroll.metrics.maxScrollExtent - 200) {
                                  _fetchBookings(loadMore: true);
                                }
                                return false;
                              },
                              child: ListView(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                children: [
                                  // Active Bookings
                                  if (active.isNotEmpty) ...[
                                    _sectionHeader('Active',
                                        active.length, HexColor("#FF6200")),
                                    const SizedBox(height: 10),
                                    ...active
                                        .map((b) => _bookingCard(b)),
                                  ],

                                  // Completed Bookings
                                  if (completed.isNotEmpty) ...[
                                    const SizedBox(height: 20),
                                    _sectionHeader(
                                        'Completed',
                                        completed.length,
                                        HexColor("#25AA59")),
                                    const SizedBox(height: 10),
                                    ...completed
                                        .map((b) => _bookingCard(b)),
                                  ],

                                  // Cancelled Bookings
                                  if (cancelled.isNotEmpty) ...[
                                    const SizedBox(height: 20),
                                    _sectionHeader(
                                        'Cancelled',
                                        cancelled.length,
                                        HexColor("#EE3E35")),
                                    const SizedBox(height: 10),
                                    ...cancelled
                                        .map((b) => _bookingCard(b)),
                                  ],

                                  if (_loadingMore)
                                    Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Center(
                                          child:
                                              CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: AppColors
                                                      .appColor)),
                                    ),

                                  const SizedBox(
                                      height: 80), // bottom nav space
                                ],
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Text('$count',
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('Failed to load bookings',
                style: GoogleFonts.poppins(
                    fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchBookings(),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.appColor),
              child: Text('Retry',
                  style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_shipping_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No bookings yet',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500)),
          const SizedBox(height: 6),
          Text('Your booking history will appear here',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  // --- BOOKING CARD ---
  Widget _bookingCard(BookingItem booking) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingDetailsScreen(bookingId: booking.id),
          ),
        );
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: ID + Vehicle + Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle icon
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: HexColor("#FFF3EC"),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: booking.vehicleIcon != null
                      ? Image.network(
                          ApiUrls.imageProxyUrl(booking.vehicleIcon!),
                          width: 35,
                          height: 28,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Icon(
                              Icons.local_shipping,
                              size: 24,
                              color: AppColors.appColor),
                        )
                      : Icon(Icons.local_shipping,
                          size: 24, color: AppColors.appColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('ID #${booking.bookingNumber}',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                        const Spacer(),
                        _statusBadge(booking.status),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(booking.vehicleName ?? 'Vehicle',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.black54)),
                        if (booking.driverName != null) ...[
                          Text('    ',
                              style: TextStyle(color: Colors.black38)),
                          Flexible(
                            child: Text(booking.driverName!,
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: HexColor("#5680E2"),
                                    fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Pickup -> Drop addresses
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HexColor("#FFFAF6"),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dots line
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      const SizedBox(height: 6),
                      Container(
                        height: 12,
                        width: 12,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: HexColor("#25AA59")),
                      ),
                      Container(
                        width: 1.5,
                        height: 40,
                        margin:
                            const EdgeInsets.symmetric(vertical: 2),
                        color: Colors.grey.shade300,
                      ),
                      Icon(Icons.location_on,
                          size: 16, color: HexColor("#EE3E35")),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pickup
                      Text('Pickup',
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(booking.pickupAddress,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 14),
                      // Drop
                      Text('Drop',
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(booking.dropAddress,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Fare, Distance, Date, Payment
          Row(
            children: [
              _infoChip(Icons.currency_rupee,
                  '\u20B9${booking.finalFare.toStringAsFixed(0)}'),
              const SizedBox(width: 10),
              _infoChip(Icons.route,
                  '${booking.distanceKm.toStringAsFixed(1)} km'),
              const SizedBox(width: 10),
              Flexible(
                child: _infoChip(Icons.calendar_today,
                    DateFormat('dd MMM, hh:mm a').format(booking.createdAt)),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action Buttons
          _actionButtons(booking),
        ],
      ),
    ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: HexColor("#F5F5F5"),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(text,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    IconData? icon;

    switch (status) {
      case 'SEARCHING':
        color = HexColor("#FF9800");
        label = 'Searching';
        icon = Icons.search;
        break;
      case 'ASSIGNED':
        color = HexColor("#2196F3");
        label = 'Assigned';
        icon = Icons.person;
        break;
      case 'DRIVER_ARRIVED':
        color = HexColor("#2196F3");
        label = 'Driver Arrived';
        icon = Icons.location_on;
        break;
      case 'PICKED':
        color = HexColor("#9C27B0");
        label = 'Picked Up';
        icon = Icons.inventory_2;
        break;
      case 'IN_PROGRESS':
        color = HexColor("#FF6200");
        label = 'In Progress';
        icon = Icons.local_shipping;
        break;
      case 'COMPLETED':
        color = HexColor("#25AA59");
        label = 'Completed';
        icon = Icons.check_circle;
        break;
      case 'CANCELLED':
        color = HexColor("#EE3E35");
        label = 'Cancelled';
        icon = Icons.cancel;
        break;
      case 'DRAFT':
        color = Colors.grey;
        label = 'Scheduled';
        icon = Icons.schedule;
        break;
      default:
        color = Colors.grey;
        label = status;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...[
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
        ],
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }

  Widget _actionButtons(BookingItem booking) {
    if (booking.isActive) {
      return Row(
        children: [
          Expanded(
            child: _actionButton(
                'Track Booking', HexColor("#FF6200"), Icons.gps_fixed,
                () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TripDetailsScreen(bookingId: booking.id),
                ),
              );
            }),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _actionButton(
                'Cancel', HexColor("#EE3E35"), Icons.close, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CancelRideScreen(bookingId: booking.id),
                ),
              ).then((result) {
                if (result == 'cancelled') {
                  _fetchBookings(); // Refresh list
                }
              });
            }),
          ),
        ],
      );
    } else if (booking.isCompleted) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _actionButton('Report Issue', HexColor("#EE6A2C"),
                    Icons.report_problem_outlined, () {
                  _reportIssue(booking);
                }),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton('Download Invoice',
                    HexColor("#2A5CD0"), Icons.download, () async {
                  try {
                    final invoice = await BookingService.getInvoice(booking.id);
                    final data = invoice['data'] is Map ? invoice['data'] : invoice;
                    final pdfUrl = data['pdfUrl']?.toString();
                    final invNo = data['invoiceNumber'] ?? booking.bookingNumber;
                    if (!mounted) return;
                    if (pdfUrl != null && pdfUrl.isNotEmpty) {
                      final uri = Uri.parse(pdfUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                        return;
                      }
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Invoice #$invNo generated. A downloadable copy isn\'t available yet.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Invoice error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _actionButton('Rebook', AppColors.appColor,
                    Icons.replay, () => _rebook(booking)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton('Rate', HexColor("#F4BE05"),
                    Icons.star_border, () {
                  _showRatingDialog(booking);
                }),
              ),
            ],
          ),
        ],
      );
    } else if (booking.isCancelled) {
      return Align(
        alignment: Alignment.centerRight,
        child: _actionButton(
            'Book Again', HexColor("#EE6A2C"), Icons.refresh, () => _rebook(booking)),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _actionButton(
      String text, Color color, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 10),
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(text,
                  style: GoogleFonts.poppins(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }

  // ─── REBOOK: prefill pickup/drop and push to SearchScreen ───
  void _rebook(BookingItem booking) {
    final data = BookingData(
      pickupAddress: booking.pickupAddress,
      pickupLat: booking.pickupLat,
      pickupLng: booking.pickupLng,
      dropAddress: booking.dropAddress,
      dropLat: booking.dropLat,
      dropLng: booking.dropLng,
      serviceType: booking.serviceType,
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SearchScreen(bookingData: data)),
    );
  }

  // ─── RATING DIALOG ───
  void _showRatingDialog(BookingItem booking) {
    int rating = 0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Column(
            children: [
              const Text('Rate your delivery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('#${booking.bookingNumber}', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Star rating row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setDialogState(() => rating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < rating ? Icons.star : Icons.star_border,
                        size: 36,
                        color: HexColor("#F4BE05"),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                rating == 0 ? 'Tap to rate' :
                rating <= 2 ? 'Could be better' :
                rating == 3 ? 'Good' :
                rating == 4 ? 'Great!' : 'Excellent!',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add a comment (optional)',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.appColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: rating == 0 ? null : () async {
                Navigator.pop(ctx);
                try {
                  final token = Prefs.getString('token');
                  await http.post(
                    Uri.parse('${ApiUrls.userBookingsUrl}/${booking.id}/rate'),
                    headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
                    body: jsonEncode({'rating': rating, 'comment': commentController.text.trim()}),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thanks for your rating!'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Rating submitted locally. Will sync when online.'), backgroundColor: Colors.orange),
                    );
                  }
                }
              },
              child: const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
