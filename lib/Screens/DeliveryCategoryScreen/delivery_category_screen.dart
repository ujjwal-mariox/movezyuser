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

    // ALWAYS through the pricing page (client decision). A vehicle chosen on
    // the home screen used to skip straight to Review, so the customer never
    // saw the recommended option or the other vehicles' prices; now the prior
    // choice arrives preselected on the pricing page instead.
    pushTo(context, VehicleSelectionScreen(bookingData: dataWithFilteredVehicles));
  }

  @override
  Widget build(BuildContext context) {
    // The design labels this simply "Next".
    const buttonText = "Next";

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
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
                    // One continuous white sheet with hairline dividers, per the
                    // design — not individually bordered cards.
                    : ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        child: Container(
                          color: Colors.white,
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: _categories.length,
                            separatorBuilder: (_, _) => const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFFCEBE0),
                            ),
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
                      ),
          ),
          Padding(
            // 16 all round is the design's gap; the device's real bottom inset
            // (gesture bar / nav buttons) is added to the bottom so "Next"
            // isn't sitting underneath the system UI.
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
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

/// The design's photographic thumbnail for a goods category, matched on the
/// category NAME.
///
/// The backend stores an `icon` per record, but several are emoji ("💊", "🥛",
/// "📦") and the app fell back to a 📦 glyph — so the design's artwork, which
/// already ships in assets/, never appeared. A record's real image URL still
/// wins; this only fills the gap.
///
/// Matched on keywords rather than exact names because the admin-managed
/// categories do not use the design's wording: the live data has "Parcel",
/// "Documents", "Food Items" and "Machinery Parts" where the design says
/// "Boxes /Parcels", "Office / Documents", "Groceries / Essentials" and
/// "Hardware / Tools".
///
/// NOTE: there is deliberately no entry for Hardware/Tools or Machinery Parts —
/// no such asset exists in the repo. Those keep the backend's own icon rather
/// than borrowing a picture of something else.
String? _designAssetForCategory(String name) {
  final n = name.toLowerCase();
  bool has(List<String> keys) => keys.any(n.contains);

  if (has(['box', 'parcel', 'carton', 'courier'])) return 'assets/boxes.png';
  if (has(['furnitur', 'chair', 'table'])) return 'assets/furniture.png';
  if (has(['grocer', 'essential', 'food', 'vegetable', 'fruit'])) {
    return 'assets/groceries.png';
  }
  if (has(['electronic', 'appliance', 'fridge', 'tv'])) {
    return 'assets/electronics.png';
  }
  if (has(['office', 'document', 'file', 'folder'])) return 'assets/office.png';
  if (has(['cloth', 'apparel', 'fashion', 'boutique'])) {
    return 'assets/clothing.png';
  }
  return null;
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
    // The design shows photo thumbnails; the backend `icon` may be a URL, an
    // asset path, or an emoji, so all three still render.
    const double thumb = 56;

    // The design's artwork for this category, when one exists. Used when the
    // record carries an emoji instead of an image, and when a real image URL
    // fails to load — previously both cases showed a bare 📦 glyph.
    final designAsset = _designAssetForCategory(title);
    Widget lastResort() => designAsset != null
        ? Image.asset(designAsset,
            width: thumb, height: thumb, fit: BoxFit.cover)
        : Center(
            child: Text(icon.isNotEmpty ? icon : '📦',
                style: const TextStyle(fontSize: 32)),
          );

    Widget iconWidget;
    if (icon.startsWith('http')) {
      iconWidget = Image.network(
        icon,
        width: thumb,
        height: thumb,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => lastResort(),
      );
    } else if (icon.startsWith('assets/')) {
      iconWidget = Image.asset(
        icon,
        width: thumb,
        height: thumb,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => lastResort(),
      );
    } else {
      // Emoji or empty — prefer the design artwork over the glyph.
      iconWidget = lastResort();
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(width: thumb, height: thumb, child: iconWidget),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 15, color: Colors.black87),
          ],
        ),
      ),
    );
  }
}
