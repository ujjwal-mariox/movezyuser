import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart' show HexColor;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/CommonWidgets/booking_terms_sheet.dart';
import 'package:movezy_user_app/CommonWidgets/order_status_timeline.dart';
import 'package:movezy_user_app/Screens/HelpSupportScreen/help_support_screen.dart';
import 'package:movezy_user_app/Services/booking_service.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';

class BookingDetailsScreen extends StatefulWidget {
  final String bookingId;
  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  Map<String, dynamic>? _booking;
  bool _isLoading = true;
  String? _error;

  bool _reporting = false;

  @override
  void initState() {
    super.initState();
    _fetchBookingDetails();
  }

  /// Raise a real support ticket for this booking (was a "coming soon" snackbar).
  Future<void> _reportIssue() async {
    if (_reporting) return;
    setState(() => _reporting = true);
    final bookingNumber = _booking?['bookingNumber'] ?? widget.bookingId;
    try {
      final res = await http.post(
        Uri.parse(ApiUrls.supportTicketsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Prefs.token}',
        },
        body: json.encode({
          'category': 'booking',
          'subject': 'Issue with booking $bookingNumber',
          'message': 'Customer reported an issue with booking $bookingNumber.',
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
    } finally {
      if (mounted) setState(() => _reporting = false);
    }
  }

  Future<void> _fetchBookingDetails() async {
    try {
      final result = await BookingService.getBookingById(widget.bookingId);
      if (mounted) {
        setState(() {
          _booking = result['data'] ?? result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'COMPLETED': return 'Completed';
      case 'CANCELLED': return 'Cancelled';
      case 'SEARCHING': return 'Searching';
      case 'ASSIGNED': return 'Assigned';
      case 'DRIVER_ARRIVED': return 'Driver Arrived';
      case 'PICKED': return 'Picked Up';
      case 'IN_PROGRESS': return 'In Progress';
      default: return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'COMPLETED': return HexColor("#25AA59");
      case 'CANCELLED': return Colors.red;
      case 'SEARCHING': return Colors.orange;
      default: return HexColor("#5680E2");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HexColor("#FFFAF6"),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _booking == null
                  ? const Center(child: Text('Booking not found'))
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final b = _booking!;
    final status = b['status'] ?? 'SEARCHING';
    final bookingNumber = b['bookingNumber'] ?? '';
    final pickup = b['pickup'] ?? {};
    final drop = b['drop'] ?? {};

    // Vehicle info
    final vt = b['vehicleTypeId'];
    String vehicleName = '---';
    String? vehicleIcon;
    if (vt is Map) {
      vehicleName = vt['name'] ?? '---';
      vehicleIcon = vt['icon'];
    }

    // Driver info
    final driver = b['driverId'];
    String driverName = '---';
    if (driver is Map) {
      driverName = driver['fullName'] ?? driver['name'] ?? '---';
    }

    // Fare info
    final finalFare = (b['finalFare'] ?? b['fare'] ?? 0).toDouble();
    final baseFare = (b['baseFare'] ?? 0).toDouble();
    final discount = (b['discount'] ?? 0).toDouble();

    return SingleChildScrollView(
      child: Column(
        children: [
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
                  const Text("Details", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                  const Spacer(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Booking Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle icon
                    if (vehicleIcon != null)
                      Image.network(
                        ApiUrls.imageProxyUrl(vehicleIcon),
                        width: 50, height: 40, fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(Icons.local_shipping, size: 40),
                      )
                    else
                      Image.asset('assets/bike_image.png', width: 50),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text("ID #$bookingNumber", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                              const Spacer(),
                              Text(
                                _statusLabel(status),
                                style: TextStyle(color: _statusColor(status), fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text("$vehicleName  •", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              Text("  $driverName", style: TextStyle(fontSize: 12, color: HexColor("#5680E2"), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // Location Steps
                Container(
                  width: MediaQuery.of(context).size.width - 40,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: HexColor("#FFFAF6").withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 30,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 10),
                            Container(
                              height: 13, width: 13,
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), color: HexColor("#25AA59")),
                            ),
                            const SizedBox(height: 1),
                            Image.asset('assets/small_dotted_line.png', width: 1, height: 70, fit: BoxFit.cover),
                            const SizedBox(height: 1),
                            Image.asset('assets/clip_path.png', width: 18, height: 18, fit: BoxFit.cover),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            _locationTile(
                              title: pickup['contactName'] ?? 'Pickup',
                              phone: pickup['contactPhone'] ?? '',
                              address: pickup['address'] ?? '---',
                              isFirst: true,
                            ),
                            const SizedBox(height: 18),
                            _locationTile(
                              title: drop['contactName'] ?? 'Drop',
                              phone: drop['contactPhone'] ?? '',
                              address: drop['address'] ?? '---',
                              isFirst: false,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _reporting ? null : _reportIssue,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: HexColor("#EE6A2C"), width: 1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(_reporting ? "Reporting..." : "Report Issue", style: TextStyle(color: HexColor("#EE6A2C"), fontWeight: FontWeight.w500, fontSize: 13)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          try {
                            final invoice = await BookingService.getInvoice(widget.bookingId);
                            final data = invoice['data'] is Map ? invoice['data'] : invoice;
                            final pdfUrl = data['pdfUrl']?.toString();
                            final invNo = data['invoiceNumber'] ?? bookingNumber;
                            if (!mounted) return;
                            if (pdfUrl != null && pdfUrl.isNotEmpty) {
                              // A generated PDF exists — open it in the browser/viewer.
                              final uri = Uri.parse(pdfUrl);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                                return;
                              }
                            }
                            // No PDF file generated yet — show the invoice number honestly.
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
                        },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: HexColor("#2A5CD0"), width: 1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text("Download Invoice", style: TextStyle(color: HexColor("#2A5CD0"), fontWeight: FontWeight.w500, fontSize: 13)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Order Status Timeline
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: OrderStatusTimeline(currentStatus: status),
          ),

          const SizedBox(height: 20),

          _fareSummaryCard(finalFare, baseFare, discount),

          const SizedBox(height: 20),

          // Order Help Section
          _orderHelpSection(context, status),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _fareSummaryCard(double finalFare, double baseFare, double discount) {
    final netFare = finalFare + discount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 5),
          const Text("Ride Summary", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _boxDecoration(),
            child: Column(
              children: [
                _fareRow('Trip Fare (incl. Toll)', '₹${netFare.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                Image.asset("assets/dotted_line.png", height: 1),
                const SizedBox(height: 8),
                _fareRow('Net Fare', '₹${finalFare.toStringAsFixed(0)}'),
                const SizedBox(height: 8),
                Image.asset("assets/dotted_line.png", height: 1),
                const SizedBox(height: 8),
                _fareRow('Offer / Coupon', discount > 0 ? '-₹${discount.toStringAsFixed(0)}' : '₹0'),
                const SizedBox(height: 8),
                Image.asset("assets/dotted_line.png", height: 1),
                const SizedBox(height: 8),
                _fareRow('Amount Payable (rounded)', '₹${finalFare.toStringAsFixed(2)}', bold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _fareRow(String title, String amount, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          amount,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          ),
        )
      ],
    );
  }

  /// Location tile widget
  Widget _locationTile({
    required String title,
    required String phone,
    required String address,
    required bool isFirst,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text("$title ",
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),

                  Text(phone,
                      style: TextStyle(color: HexColor("#334A4C"), fontSize: 12)
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(address, style:  TextStyle(color: HexColor("#334A4C"), fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  /// Porter-style "Order help" section
  Widget _orderHelpSection(BuildContext context, String status) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text(
              "Order help",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          // Contact us
          _helpItem(
            icon: Icons.headset_mic,
            iconColor: Colors.grey.shade700,
            title: "Contact us",
            subtitle: "Raise a support ticket",
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
              );
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // Terms and conditions
          _helpItem(
            icon: Icons.description_outlined,
            iconColor: Colors.grey.shade700,
            title: "Terms and conditions",
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            onTap: () => showBookingTermsSheet(context),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _helpItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}