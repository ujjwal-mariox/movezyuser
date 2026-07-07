import 'package:flutter/material.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/Screens/BookingConfirmation/booking_confirmation_screen.dart';
import 'package:hexcolor/hexcolor.dart';


class RoutesWidget extends StatefulWidget {
  const RoutesWidget({super.key});

  @override
  State<RoutesWidget> createState() => _RoutesWidgetState();
}

class _RoutesWidgetState extends State<RoutesWidget> {
  static const Color outerBlue = Color(0xFF1F5F9A); // deep blue frame
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFF3F6F7);
  static const Color priceGreen = Color(0xFF2E8B57);
  static const Color priceBlue = Color(0xFF2E67B3);
  static const Color tagBg = Color(0xFFFFF6E6);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: Column(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: outerBlue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(0),
                  bottomRight: Radius.circular(0),
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 6),
                children: const [
                  SizedBox(height: 6),
                  RouteCard(
                    icons: ['assets/car_icon.png', 'assets/metro_train_icon.png', 'assets/bike_icon.png'],
                    title: 'Cab + Metro + Bike',
                    tags: ['Eco', 'Affordable'],
                    price: '₹ 940',
                    priceColor: priceGreen,
                    pickupMinutes: 2,
                    dropMinutes: 32,
                    saveTime: 'Save Time 15Mins',
                  ),
                  SizedBox(height: 14),
                  RouteCard(
                    icons: ['assets/car_icon.png', 'assets/metro_train_icon.png', 'assets/bike_icon.png'],
                    title: 'Auto + Metro + Bike',
                    tags: ['Eco', 'Affordable'],
                    price: '₹ 840',
                    priceColor: priceBlue,
                    pickupMinutes: 2,
                    dropMinutes: 32,
                    saveTime: 'Save Time 10Mins',
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RouteCard extends StatelessWidget {
  final List<String> icons;
  final String title;
  final List<String> tags;
  final String price;
  final Color priceColor;
  final int pickupMinutes;
  final int dropMinutes;
  final String saveTime;

  const RouteCard({
    super.key,
    required this.icons,
    required this.title,
    required this.tags,
    required this.price,
    required this.priceColor,
    required this.pickupMinutes,
    required this.dropMinutes,
    required this.saveTime,
  });

  @override
  Widget build(BuildContext context) {
    // Card uses white background and subtle shadow
    return InkWell(
      onTap: (){
        pushTo(context, BookingConfirmationScreen());
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 6,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row with circular icons
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      for (var img in icons) _smallCircleIcon(img),
                      const Spacer(),
                      // right-side small badges if needed or empty space
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  // small tags row
                  Row(
                    children: tags.map((t) => _smallTag(t)).toList(),
                  ),

                  SizedBox(height: 4,),

                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Row(
                      children: [
                        // Price
                        Text(
                          price,
                          style: TextStyle(
                            color: priceColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // vertical divider
                        Container(height: 28, width: 1, color: Colors.grey.shade300),
                        const SizedBox(width: 12),
                        // Pickup
                        Expanded(
                          child: Row(
                            children: [
                               Text('Pickup :', style: TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 3),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 16, color: Colors.black),
                                  const SizedBox(width: 4),
                                  Text('$pickupMinutes mins', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                                ],
                              )
                            ],
                          ),
                        ),

                        Container(height: 28, width: 1, color: Colors.grey.shade300),

                        SizedBox(width: 16,),

                        // Drop
                        Row(
                          children: [
                            const Text('Drop :', style: TextStyle(fontSize: 10, color: Colors.black , fontWeight: FontWeight.w600)),
                            const SizedBox(width: 3),
                            const Icon(Icons.access_time, size: 16, color: Colors.black),
                            const SizedBox(width: 4),
                            Text('$dropMinutes mins', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Save time badge on top-right (overlapping)
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  saveTime,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallCircleIcon(String assetPath) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: HexColor("#015EA3"), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            // If you don't have an asset, replace Image.asset with Icon(Icons.directions_car)
          ),
        ),
      ),
    );
  }

  Widget _smallTag(String text) {
    final bool isFirst = text.toLowerCase() == 'eco';
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isFirst ? const Color(0xFFEFF8FF) : const Color(0xFFFFF6E6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
           Icon(Icons.circle, size: 6, color: isFirst ? HexColor('#015EA3') : HexColor('#FEA72E')),
          SizedBox(width: 3,),
          Text(
            text,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}