import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/Screens/DashboardScreen/dashboard_Screen.dart';
import 'package:movezy_user_app/Services/booking_service.dart';
import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';

/// Delivery completion screen — shown when trip status becomes COMPLETED.
/// Allows user to rate driver + give feedback, then returns to home.
class DeliveryCompleteScreen extends StatefulWidget {
  final String bookingId;
  final String bookingNumber;
  final String driverName;
  final String vehicleName;
  final double fare;
  final int coinsEarned;

  const DeliveryCompleteScreen({
    super.key,
    required this.bookingId,
    required this.bookingNumber,
    this.driverName = 'Driver',
    this.vehicleName = 'Vehicle',
    this.fare = 0,
    this.coinsEarned = 0,
  });

  @override
  State<DeliveryCompleteScreen> createState() => _DeliveryCompleteScreenState();
}

class _DeliveryCompleteScreenState extends State<DeliveryCompleteScreen> {
  int _rating = 0;
  final Set<String> _selectedTags = {};
  final _commentController = TextEditingController();
  bool _submitting = false;

  final List<String> _feedbackTags = [
    'Professional driver',
    'On-time delivery',
    'Safe handling',
    'Good communication',
    'Clean vehicle',
    'Polite behaviour',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      _goHome();
      return;
    }

    setState(() => _submitting = true);
    try {
      await BookingService.rateBooking(
        widget.bookingId,
        rating: _rating,
        feedback: _selectedTags.toList(),
        comment: _commentController.text.trim(),
      );
    } catch (e) {
      debugPrint('Rating submit error: $e');
    }
    if (mounted) _goHome();
  }

  void _goHome() {
    replaceRoute(context, const DashboardScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
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
                      onTap: _goHome,
                      child: Container(
                        padding: const EdgeInsets.only(left: 16),
                        width: 40,
                        height: 35,
                        alignment: Alignment.center,
                        child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      "Delivery Complete",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Success icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: HexColor("#25AA59").withOpacity(0.1),
              ),
              child: Icon(
                Icons.check_circle,
                size: 70,
                color: HexColor("#25AA59"),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Delivery Completed!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              "Order #${widget.bookingNumber}",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            Text(
              "₹${widget.fare.toStringAsFixed(0)}",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.appColor,
              ),
            ),

            // Coins earned
            if (widget.coinsEarned > 0) ...[
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [HexColor("#FEFEF6"), HexColor("#FDF6AB")],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset("assets/rupee_coins.png", height: 24),
                    const SizedBox(width: 8),
                    Text(
                      "+${widget.coinsEarned} coins earned!",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),
            const Divider(height: 1),
            const SizedBox(height: 24),

            // Rate your delivery partner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Rate your delivery partner",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.driverName,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),

                  // Stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return GestureDetector(
                        onTap: () => setState(() => _rating = i + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            i < _rating ? Icons.star : Icons.star_border,
                            size: 42,
                            color: i < _rating
                                ? HexColor("#FFB800")
                                : Colors.grey.shade300,
                          ),
                        ),
                      );
                    }),
                  ),
                  if (_rating > 0) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        _rating >= 4
                            ? "Great!"
                            : _rating >= 3
                                ? "Good"
                                : "Could be better",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _rating >= 4
                              ? HexColor("#25AA59")
                              : _rating >= 3
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Feedback tags
                  if (_rating > 0) ...[
                    const Text(
                      "What went well?",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _feedbackTags.map((tag) {
                        final selected = _selectedTags.contains(tag);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (selected) {
                                _selectedTags.remove(tag);
                              } else {
                                _selectedTags.add(tag);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.appColor.withOpacity(0.1)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? AppColors.appColor
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    selected ? FontWeight.w600 : FontWeight.w400,
                                color: selected
                                    ? AppColors.appColor
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Comment
                    TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Any additional comments? (optional)',
                        hintStyle: TextStyle(
                            fontSize: 13, color: Colors.grey.shade400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.appColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _submitting ? null : _submitRating,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _rating > 0 ? "Submit Rating" : "Go to Home",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
              if (_rating > 0) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _goHome,
                  child: Text(
                    "Skip",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
