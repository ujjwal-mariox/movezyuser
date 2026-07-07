import 'package:flutter/material.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/Screens/HomeScreen/Model/booking_data.dart';
import 'package:movezy_user_app/Screens/ReviewBookingScreen/review_booking_screen.dart';
import 'package:movezy_user_app/Screens/VehicleSelectionScreen/vehicle_selection_screen.dart';
import 'package:movezy_user_app/Services/booking_service.dart';

class DeliveryCategoryScreen extends StatefulWidget {
  final BookingData bookingData;

  const DeliveryCategoryScreen({super.key, required this.bookingData});

  @override
  State<DeliveryCategoryScreen> createState() => _DeliveryCategoryScreenState();
}

class _DeliveryCategoryScreenState extends State<DeliveryCategoryScreen> {
  List<GoodsType> _categories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await BookingService.getGoodsTypes();
      if (mounted) {
        setState(() {
          _categories = cats;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _onCategorySelected(BuildContext context, GoodsType category) {
    final updatedData = widget.bookingData.copyWith(
      goodsCategory: category.name,
      goodsTypeId: category.id,
      goodsTypeCategory: category.category,
    );

    // If category restricts vehicle types, filter allVehicles
    List<dynamic> filteredVehicles = updatedData.allVehicles;
    if (category.allowedVehicleTypeIds.isNotEmpty) {
      filteredVehicles = updatedData.allVehicles
          .where((v) => category.allowedVehicleTypeIds.contains(v.id))
          .toList();
    }

    final dataWithFilteredVehicles = updatedData.copyWith(
      allVehicles: filteredVehicles.cast(),
    );

    if (dataWithFilteredVehicles.hasVehicle) {
      // Check if selected vehicle is allowed for this category
      if (category.allowedVehicleTypeIds.isNotEmpty &&
          !category.allowedVehicleTypeIds.contains(dataWithFilteredVehicles.selectedVehicle!.id)) {
        // Vehicle not allowed for this category → go to vehicle selection
        pushTo(context, VehicleSelectionScreen(bookingData: dataWithFilteredVehicles));
      } else {
        // Vehicle is fine → go to review
        pushTo(context, ReviewBookingScreen(bookingData: dataWithFilteredVehicles));
      }
    } else {
      // No vehicle selected → pick one
      pushTo(context, VehicleSelectionScreen(bookingData: dataWithFilteredVehicles));
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonText = widget.bookingData.hasVehicle
        ? "Proceed With ${widget.bookingData.selectedVehicle!.name}"
        : "Select Vehicle";

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
                    "What are you delivering today?",
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
          const SizedBox(height: 15),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A30)))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 12),
                            Text('Failed to load categories', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                setState(() { _loading = true; _error = null; });
                                _loadCategories();
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          return _CategoryTile(
                            icon: cat.icon,
                            title: cat.name,
                            subtitle: cat.description,
                            onTap: () => _onCategorySelected(context, cat),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  // Proceed without specific category
                  final fallback = GoodsType(
                    id: '',
                    name: 'General Goods',
                    code: 'GENERAL',
                    category: 'PERSONAL',
                    icon: '📦',
                    description: 'General goods',
                    allowedVehicleTypeIds: [],
                    isActive: true,
                    sortOrder: 0,
                  );
                  _onCategorySelected(context, fallback);
                },
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if icon is an emoji or asset path or URL
    Widget iconWidget;
    if (icon.startsWith('http')) {
      iconWidget = Image.network(icon, width: 45, height: 45, errorBuilder: (_, _, _) => const Text('📦', style: TextStyle(fontSize: 30)));
    } else if (icon.startsWith('assets/')) {
      iconWidget = Image.asset(icon, width: 45, height: 45, errorBuilder: (_, _, _) => const Text('📦', style: TextStyle(fontSize: 30)));
    } else {
      // Treat as emoji
      iconWidget = Text(icon.isNotEmpty ? icon : '📦', style: const TextStyle(fontSize: 30));
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            SizedBox(width: 45, height: 45, child: Center(child: iconWidget)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
