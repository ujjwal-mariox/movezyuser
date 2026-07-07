import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/Screens/ChatScreen/chat_screen.dart';
import 'package:movezy_user_app/Screens/JourneyScreen/journey_screen.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:share_plus/share_plus.dart';

class BookingConfirmedScreen extends StatefulWidget {
  const BookingConfirmedScreen({super.key});

  @override
  State<BookingConfirmedScreen> createState() => _BookingConfirmedScreenState();
}

class _BookingConfirmedScreenState extends State<BookingConfirmedScreen> {

  @override
  void initState() {
    Future.delayed(Duration(seconds: 4), (){
      pushTo(context, JourneyScreen());
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark,
     )
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              commonAppBar(
                  height : 130,
                  context : context,
                  child: Container(
                    padding: const EdgeInsets.only(top: 47),
                    child: Row(
                      children: [
                        SizedBox(width: 5,),
                        Row(
                          children: [
                            InkWell(
                              onTap: (){
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: EdgeInsets.only(left: 16),
                                width: 40,
                                height: 35,
                                alignment: Alignment.center,
                                child: Icon(Icons.arrow_back_ios, color: Colors.white,),
                              ),
                            ),
                            Text(
                              "Journey",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
              ),

              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  "assets/ride_map_icon.png", // placeholder
                  height: MediaQuery.of(context).size.height * 0.35,
                  width: double.infinity,
                  fit: BoxFit.fill,
                ),
              ),
            ],
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                  color: HexColor("#015EA3"),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))
              ),
              padding: EdgeInsets.all(15),
              child: Container(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const CircleAvatar(
                                radius: 28,
                                backgroundImage: NetworkImage(
                                  "https://randomuser.me/api/portraits/men/41.jpg",
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: const [
                                        Text(
                                          "Shubham Singh ",
                                          style: TextStyle(
                                              fontSize: 15, fontWeight: FontWeight.bold),
                                        ),
                                        Icon(Icons.star,
                                            size: 16, color: Colors.orangeAccent),
                                        SizedBox(width: 4),
                                        Text("4.5",
                                            style: TextStyle(
                                                fontSize: 13, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "KA 04 AB 2303 · Red Bajaj Pulsar",
                                      style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6, horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: HexColor("#A2BF49"),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        "Your driver is arriving in 2 mins on Gate 2",
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),

                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _actionBtn('assets/call_icon.png', "Call", Colors.green, (){}),
                              _actionBtn("assets/chat_icon.png", "Chat", Colors.blue, (){
                                pushTo(context, const ChatScreen(bookingId: ''));
                              }),
                              _actionBtn("assets/share_ride_icon.png", "Share", Colors.black87, (){
                                Share.share("");
                              }),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),

                    SizedBox(height: 15,),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTimelineItem(
                            iconPath: 'assets/car_icon.png',
                            title: 'Pickup',
                            subtitle: '3 Min',
                            showLine: true,
                          ),
                          _buildTimelineItem(
                            iconPath: 'assets/metro_train_icon.png',
                            title: 'Chikka Banaswadi',
                            subtitle: 'Metro',
                            showLine: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),


          Positioned(
            top: 105,
              left: 1,
              right: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 45,
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text("OTP - 1515"),
                  ),
                ],
              ))

        ],
      ),
    );
  }

  Widget _actionBtn(String icon, String label, Color color, Function onTap) {
    return Expanded(
      child: InkWell(
        onTap: (){
          onTap();
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                  width: 16,
                  height: 14,
                  child: Image.asset(icon, width: 16, height: 16,fit: BoxFit.contain,
                  )
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required String iconPath,
    required String title,
    required String subtitle,
    required bool showLine,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column: icon + dotted line
        Column(
          children: [
            Image.asset(
              iconPath,
              width: 35,
              height: 35,
              fit: BoxFit.contain,
            ),
            if (showLine)
              Container(
                width: 2,
                height: 45,
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: Colors.blue,
                      width: 1.2,
                      style: BorderStyle.solid,
                    ),
                  ),
                ),
                child: CustomPaint(
                  painter: _DottedLinePainter(),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        // Right column: texts
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}



class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const double dashHeight = 4;
    const double dashSpace = 4;
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}