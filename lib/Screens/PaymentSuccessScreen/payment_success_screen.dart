import 'package:flutter/material.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/CommonWidgets/button_widget.dart';
import 'package:movezy_user_app/Screens/RideFindingScreen/ride_finding_screen.dart';
import 'package:hexcolor/hexcolor.dart';


class PaymentSuccessScreen extends StatefulWidget {
  const PaymentSuccessScreen({super.key});

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {

  @override
  Widget build(BuildContext context) {
    // Use fixed width card relative to device width
    final double width = MediaQuery.of(context).size.width;
    final double cardWidth = width * 0.90;
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: Container(
        margin: EdgeInsets.only(bottom: 10),
        height: 75,
        padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 12),
        child: ButtonWidget(
          height: 50,
          text: "Done",onTap: (){
          pushTo(context, RideFindingScreen(bookingId: '', bookingNumber: '',));
        },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Stack(
          children: [
            // Top-left and top-right circular icons
            Positioned(
              left: 16,
              top: 12,
              child: Container(
                  height: 40,
                  width: 40,
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    border: Border.all(color: HexColor('#EDEDED'), width: 1.5),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Icon(Icons.close, size: 22,)),
            ),


            Positioned(
              right: 22,
              top: 20,
              child: Container(
                height: 40,
                width: 40,
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  border: Border.all(color: HexColor('#EDEDED'), width: 1.5),
                  borderRadius: BorderRadius.circular(100),
                ),
                  child: Image.asset("assets/down_load_icon.png", width: 30,height: 30,)),
            ),

            // Main content centered vertically
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Card with scalloped bottom and overlay badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Card body
                      Container(
                        width: cardWidth,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(6, 36, 6, 18),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 4),
                              const Text(
                                'Payment Success!',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF222222),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Your payment has been successfully done.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w400
                                ),
                              ),
                              const SizedBox(height: 15),
                              // thin divider
                              Container(
                                margin: EdgeInsets.only(left: 20, right: 20),
                                  child: Divider(color: HexColor('#E8EAED'), thickness: 1)),
                              const SizedBox(height: 10),

                              // Total payment
                              const Text(
                                'Total Payment',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '₹ 145',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 18),

                              // 2x2 info boxes
                              InfoGrid(
                                items: const [
                                  InfoItem(title: 'Ref Number', value: '000085752257'),
                                  InfoItem(title: 'Payment Time', value: '25 Feb 2023, 13:22'),
                                  InfoItem(title: 'Payment Method', value: 'Bank Transfer'),
                                  InfoItem(title: 'Sender Name', value: 'Antonio Roberto'),
                                ],
                              ),

                              const SizedBox(height: 17),
                              // Get PDF receipt row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset("assets/down_load_icon.png", width: 30,height: 30,),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Get PDF Receipt',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.w400,
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 14),
                            ],
                          ),
                        ),
                      ),



                      Positioned(
                        bottom: -35,
                        left: 0, right: 0,
                        child: SizedBox(
                          width: cardWidth,
                          height: 50,
                          child: Image.asset("assets/multiple_circles.png")
                        ),
                      ),

                      // Overlapping green check badge
                      Positioned(
                        top: -25,
                        left: (cardWidth / 2) - 22,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFF54B26E),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular icon used top-left and top-right
class CircleIcon extends StatelessWidget {
  final IconData icon;
  const CircleIcon({super.key, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shape: const CircleBorder(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(icon, size: 20, color: Colors.grey[800]),
      ),
    );
  }
}

/// The scalloped card using custom clipper
class ScallopedCard extends StatelessWidget {
  final double width;
  final Widget child;
  const ScallopedCard({super.key, required this.width, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      // Add rounded corners and shadow
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipPath(
        clipper: ScallopClipper(),
        child: Container(
          color: Colors.white,
          child: child,
        ),
      ),
    );
  }
}

/// Creates scalloped bottom edge by subtracting circles
class ScallopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const double radius = 10;
    final int circles = (size.width / (radius * 2)).floor();
    final Path path = Path();

    // rounded rect for top and sides
    path.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(18)));

    // now subtract bottom circles by reversing: build from top then cut semicircles
    final Path cut = Path();
    for (int i = 0; i < circles; i++) {
      final double cx = radius + i * radius * 2;
      cut.addOval(Rect.fromCircle(center: Offset(cx, size.height), radius: radius));
    }

    // Combine: path - cut (achieve scallop)
    // Flutter's Path doesn't support boolean subtraction directly; to emulate scallop
    // we'll construct a path that goes along the top/side rounded rect and then follows semicircles along the bottom.
    final Path scalloped = Path();
    // top-left corner arc start
    scalloped.moveTo(0, 18);
    scalloped.quadraticBezierTo(0, 0, 18, 0);
    scalloped.lineTo(size.width - 18, 0);
    scalloped.quadraticBezierTo(size.width, 0, size.width, 18);
    scalloped.lineTo(size.width, size.height - radius); // go down right side
    // now along bottom produce semicircles from right to left
    for (int i = circles - 1; i >= 0; i--) {
      final double cx = radius + i * radius * 2;
      // arc from (cx + radius, size.height) to (cx - radius, size.height) clockwise
      scalloped.arcTo(Rect.fromCircle(center: Offset(cx, size.height), radius: radius), 0, 3.14159, false);
    }
    scalloped.lineTo(0, size.height - radius);
    scalloped.lineTo(0, 18);
    scalloped.close();

    return scalloped;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Grid showing 4 info boxes
class InfoGrid extends StatelessWidget {
  final List<InfoItem> items;
  const InfoGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((it) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width * 0.90 - 22 * 2 - 12) / 2,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(it.title, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                const SizedBox(height: 8),
                Text(it.value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class InfoItem {
  final String title;
  final String value;
  const InfoItem({required this.title, required this.value});
}
