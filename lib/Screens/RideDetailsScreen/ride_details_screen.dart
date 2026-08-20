import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/Screens/ChatScreen/chat_screen.dart';
import 'package:movezy_user_app/Screens/DestinationSummeryScreen/destination_summery_screen.dart';
import 'package:hexcolor/hexcolor.dart';


class RideDetailsScreen extends StatefulWidget {
  const RideDetailsScreen({super.key});

  @override
  State<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {

  @override
  void initState() {
    Future.delayed(Duration(seconds: 5), (){
      pushTo(context, DestinationSummeryScreen());
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            commonAppBar(
                height : 100,
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

              Container(
                margin: EdgeInsets.only(left: 12, right: 12, top: 15),
                padding: EdgeInsets.only(left: 10, right: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15), // shadow color
                      blurRadius: 10, // how soft the shadow is
                      spreadRadius: 2, // how wide the shadow spreads
                      offset: const Offset(0, 0), // 0,0 means shadow on ALL sides
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    SizedBox(height: 10,),

                    Text(
                      "Total Journey Fare",
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _topInfo("₹ 565"),
                          _topInfo("52 mins", ),
                          _topInfo("3.8 kg"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            Container(
              margin: EdgeInsets.only(left: 12, right: 12, top: 11, bottom: 11),
              padding: EdgeInsets.only(left: 10, right: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15), // shadow color
                    blurRadius: 10, // how soft the shadow is
                    spreadRadius: 2, // how wide the shadow spreads
                    offset: const Offset(0, 0), // 0,0 means shadow on ALL sides
                  ),
                ],
              ),
              child: Column(
                children: [

                  const SizedBox(height: 4),

                  _rideStep(
                    icon: Icons.check_circle,
                    text: "Cab completed",
                    trailing: _outlinedBtn("View Details"),
                    iconColor: Colors.green,
                  ),
                  const SizedBox(height: 8),
                  _rideStep(
                    icon: Icons.check_circle,
                    text: "Metro completed",
                    trailing: _outlinedBtn("View Details"),
                    iconColor: Colors.green,
                  ),
                  const SizedBox(height: 8),
                  _rideStep(
                    icon: Icons.motorcycle,
                    text: "Bike Ride",
                    trailing: _outlinedBtn("Active", active: true),
                    iconColor: Colors.red,
                  ),

                  const SizedBox(height: 8),
                  Container(
                    child: Image.asset("assets/yellow_dotted_line.png"),
                  ),

                  const SizedBox(height: 12),

                  /// Driver info
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

                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            /// Map section
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                "assets/ride_map_icon.png", // placeholder
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topInfo(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ],
    );
  }

  Widget _rideStep({
        required IconData icon,
        required String text,
        required Widget trailing,
        Color iconColor = Colors.black
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: HexColor("#A2BF49"), width: 1.5)
                ),
                child: Icon(Icons.check_rounded, size: 28,color: HexColor("#A2BF49")),
              ),
              const SizedBox(width: 10),
              Text(
                text,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black),
              ),
            ],
          ),

          const SizedBox(width: 12),

          trailing,
        ],
      ),
    );
  }

  Widget _outlinedBtn(String text, {bool active = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(
            color: active ? Colors.blue : Colors.grey.shade400, width: 1),
        borderRadius: BorderRadius.circular(6),
        color: active ? Colors.blue.shade50 : Colors.white,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: active ? Colors.blue : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
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
}
