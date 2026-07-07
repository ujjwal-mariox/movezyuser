import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:movezy_user_app/Services/booking_service.dart';

/// Porter-style prohibited / restricted items bottom sheet.
///
/// Fetches items from the backend API (admin-managed).
/// Falls back to a default list if the API call fails.
/// Usage:
/// ```dart
/// showProhibitedItemsSheet(context);
/// ```
void showProhibitedItemsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ProhibitedItemsSheet(),
  );
}

class _ProhibitedItemsSheet extends StatefulWidget {
  const _ProhibitedItemsSheet();

  @override
  State<_ProhibitedItemsSheet> createState() => _ProhibitedItemsSheetState();
}

class _ProhibitedItemsSheetState extends State<_ProhibitedItemsSheet> {
  List<ProhibitedItem> _items = [];
  bool _loading = true;

  // Hardcoded fallback in case API fails or returns empty
  static final _fallbackItems = [
    ProhibitedItem(id: '1', name: 'King / Queen Sized cot', icon: '🛏️', image: '', bgColor: '#FFF3E0', description: '', sortOrder: 0),
    ProhibitedItem(id: '2', name: 'Big Wardrobe / Almirah', icon: '🚪', image: '', bgColor: '#E3F2FD', description: '', sortOrder: 1),
    ProhibitedItem(id: '3', name: 'Objects sized over 5.5ft', icon: '📏', image: '', bgColor: '#FCE4EC', description: '', sortOrder: 2),
    ProhibitedItem(id: '4', name: '5 seater sofa', icon: '🛋️', image: '', bgColor: '#E8F5E9', description: '', sortOrder: 3),
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final items = await BookingService.getProhibitedItems();
      if (mounted) {
        setState(() {
          _items = items.isNotEmpty ? items : _fallbackItems;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _items = _fallbackItems;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "Prohibited items",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 24),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Items bigger than the vehicle or CANNOT be lifted by 1 person are prohibited",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Prohibited items grid
          _loading
              ? const Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      Color bgColor;
                      try {
                        bgColor = HexColor(item.bgColor);
                      } catch (_) {
                        bgColor = const Color(0xFFFFF3E0);
                      }
                      return _ProhibitedItemCard(
                        name: item.name,
                        icon: item.icon,
                        imageUrl: item.image,
                        color: bgColor,
                      );
                    },
                  ),
                ),
          const SizedBox(height: 16),

          // Additional rules
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: HexColor("#FFF8E1"),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: HexColor("#F57F17"), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      "Important Notes",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _bulletPoint("Goods heavier than 25 kg or that which CANNOT be lifted by 1 person CANNOT be moved."),
                const SizedBox(height: 4),
                _bulletPoint("Hazardous materials, flammable goods, and illegal items are strictly prohibited."),
                const SizedBox(height: 4),
                _bulletPoint("Fragile items must be properly packed. Movezy is not responsible for damage to unpacked items."),
                const SizedBox(height: 4),
                _bulletPoint("Max total weight: 500 Kg per vehicle."),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Confirm button
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: HexColor("#FF7A30"),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "I Understand",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("• ", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 12, height: 1.3)),
        ),
      ],
    );
  }
}

class _ProhibitedItemCard extends StatelessWidget {
  final String name;
  final String icon;
  final String imageUrl;
  final Color color;

  const _ProhibitedItemCard({
    required this.name,
    required this.icon,
    required this.imageUrl,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              if (imageUrl.isNotEmpty)
                Image.network(
                  imageUrl,
                  height: 42,
                  width: 42,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Text(
                    icon.isNotEmpty ? icon : '🚫',
                    style: const TextStyle(fontSize: 36),
                  ),
                )
              else
                Text(
                  icon.isNotEmpty ? icon : '🚫',
                  style: const TextStyle(fontSize: 36),
                ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
