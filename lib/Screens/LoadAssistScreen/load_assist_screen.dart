import 'package:flutter/material.dart';
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/CommonWidgets/prohibited_items_sheet.dart';
import 'package:movezy_user_app/Screens/HomeScreen/Model/booking_data.dart';
import 'package:movezy_user_app/Screens/ReviewBookingScreen/review_booking_screen.dart';
import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';

/// Porter-style Load Assist screen.
///
/// Shown between VehicleSelection → ReviewBooking for vehicles
/// that support loading/unloading services.
/// Collects: goods type (Business/Personal), weight range, and shows prohibited items.
class LoadAssistScreen extends StatefulWidget {
  final BookingData bookingData;

  const LoadAssistScreen({super.key, required this.bookingData});

  @override
  State<LoadAssistScreen> createState() => _LoadAssistScreenState();
}

class _LoadAssistScreenState extends State<LoadAssistScreen> {
  // Prefilled from the goods-type screen's category in initState. Hard
  // defaulting to Business silently flipped PERSONAL bookings to BUSINESS
  // whenever the user didn't touch the radio.
  late String _goodsType;
  String _weightRange = 'below_250'; // 'below_250' or 'above_250'

  final List<Map<String, String>> _goodsOptions = [
    {'label': 'Business or Commercial goods', 'icon': '📦'},
    {'label': 'Personal / Household goods', 'icon': '🏠'},
  ];

  @override
  void initState() {
    super.initState();
    // Mirror the category the goods-type screen already established — only an
    // explicit tap here should change it. _proceed writes it back, which is a
    // no-op unless the user actually switched the radio.
    _goodsType = widget.bookingData.goodsTypeCategory == 'PERSONAL'
        ? 'Personal / Household goods'
        : 'Business or Commercial goods';
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.bookingData.selectedVehicle;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
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
                      width: 40,
                      height: 35,
                      alignment: Alignment.center,
                      child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    "Load Assist",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Select type of goods
                    const Text(
                      "Select type of goods",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ..._goodsOptions.map((opt) => _goodsTypeTile(opt)),
                    const SizedBox(height: 24),

                    // Total weight section
                    const Divider(),
                    const SizedBox(height: 14),
                    const Text(
                      "Total weight",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Weight selection
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Total weight of goods",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _weightOption('below_250', 'Below 250kg'),
                              const SizedBox(width: 16),
                              _weightOption('above_250', 'Above 250kg'),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Vehicle info card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                // Vehicle image
                                Container(
                                  width: 80,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  // Vehicles carry `image`; `icon` is usually
                                  // empty, so this always fell back to the
                                  // auto-rickshaw asset for every vehicle.
                                  child: Builder(builder: (_) {
                                    final art = (vehicle?.image?.isNotEmpty == true)
                                        ? vehicle!.image!
                                        : (vehicle?.icon ?? '');
                                    return art.startsWith('http')
                                        ? Image.network(
                                            ApiUrls.imageProxyUrl(art),
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, _, _) => Image.asset(
                                                'assets/auto.png',
                                                fit: BoxFit.contain),
                                          )
                                        : Image.asset('assets/auto.png',
                                            fit: BoxFit.contain);
                                  }),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  // Real specs for the SELECTED vehicle. These
                                  // were hardcoded ("1 Partner" from an
                                  // if/else with identical branches, "Load up
                                  // to full truck", "Max weight per item 25Kg",
                                  // and a max weight taken from the weight
                                  // picker) — so a bike and a truck advertised
                                  // identical, invented capacities.
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (vehicle?.description?.isNotEmpty == true) ...[
                                        Text(
                                          "• ${vehicle!.description}",
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                      if ((vehicle?.maxWeightKg ?? 0) > 0) ...[
                                        Text(
                                          "• Max total weight ${vehicle!.maxWeightKg.toInt()}Kg",
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                      if ((vehicle?.lengthFt ?? 0) > 0)
                                        Text(
                                          "• Load space ${vehicle!.lengthFt.toStringAsFixed(1)} x ${vehicle.breadthFt.toStringAsFixed(1)} x ${vehicle.heightFt.toStringAsFixed(1)} ft",
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Prohibited items section
                    InkWell(
                      onTap: () => showProhibitedItemsSheet(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 22),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                "View prohibited items",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.red.shade400),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),

          // Bottom button. The SafeArea already supplies the bottom inset (so
          // no MediaQuery padding is added here — that would double it and open
          // a dead gap), but top:false stops it ALSO re-applying the still
          // unconsumed status-bar inset as a phantom gap above the button.
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.appColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _proceed,
                  child: const Text(
                    "Confirm & book",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _goodsTypeTile(Map<String, String> opt) {
    final isSelected = _goodsType == opt['label'];
    return InkWell(
      onTap: () => setState(() => _goodsType = opt['label']!),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.appColor.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.appColor : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(opt['icon']!, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                opt['label']!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.appColor : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.appColor, size: 22)
            else
              Icon(Icons.radio_button_off, color: Colors.grey.shade400, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _weightOption(String value, String label) {
    final selected = _weightRange == value;
    return InkWell(
      onTap: () => setState(() => _weightRange = value),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.appColor : Colors.grey.shade400,
                width: 2,
              ),
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.appColor,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  void _proceed() {
    // Update booking data with goods info and go to review
    final updatedData = widget.bookingData.copyWith(
      // The band is a real declared value, not just prose: Review derives the
      // billed weight from its quantity steppers, and the two used to be able
      // to contradict each other with nothing reconciling them.
      goodsWeight: _weightRange == 'above_250' ? 250 : 0,
      goodsDescription: '$_goodsType | Weight: ${_weightRange == 'above_250' ? 'Above 250kg' : 'Below 250kg'}',
      goodsTypeCategory: _goodsType.contains('Business') ? 'BUSINESS' : 'PERSONAL',
    );

    pushTo(context, ReviewBookingScreen(bookingData: updatedData));
  }
}
