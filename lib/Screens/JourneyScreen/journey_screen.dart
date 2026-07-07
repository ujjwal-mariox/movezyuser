import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/Screens/RideDetailsScreen/ride_details_screen.dart';
import 'package:movezy_user_app/Screens/TicketScreen/ticket_screen.dart';
import 'package:hexcolor/hexcolor.dart';

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});
  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {

  @override
  void initState() {
    Future.delayed(Duration(seconds: 4), (){
      pushTo(context, RideDetailsScreen());
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
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        child: Column(
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
              margin: EdgeInsets.only(left: 10, right: 10, top: 15),
              padding: EdgeInsets.only(left: 10, right: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
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
              margin: const EdgeInsets.all(10.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: HexColor("#A2BF49"), width: 1.5)
                        ),
                        child: Icon(Icons.check_rounded, size: 30,color: HexColor("#A2BF49")),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        "Cab completed",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          SizedBox(
                              width: 40,
                              height: 40,
                              child: Image.asset(
                                'assets/metro_train_icon.png',
                                height: 40,
                                width: 40,
                              )
                          ), // Replace with real asset
                          _buildDashedLine(),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                padding: EdgeInsets.all(12),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [

                                    const Text(
                                      "Welcome to Chikka Banaswadi Metro Station",
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 8),
                                    OutlinedButton(
                                      onPressed: () {
                                        pushTo(context, TicketScreen());
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: HexColor("#015EA3")),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                      child: Text("Show QR Metro Ticket", style: TextStyle(color: HexColor("#015EA3"), fontSize: 13),),
                                    ),

                                    const SizedBox(height: 8),

                                    Row(
                                      children: [
                                        const Text("Train to MG Road in "),
                                        const Text("5 mins",
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),

                                    Row(
                                      children: [
                                        const Text("Enter via"),
                                        const Text("Gate No. 2",
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),
                                    Row(
                                      children: const [
                                        Text("Cab fare Paid "),
                                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    const Text("Metro | fare ₹ 35"),
                                    const Text("Deducted from Wallet (₹ 65 Balance)"),
                                  ],
                                ),
                              ),

                            ],
                          ),
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 20),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          SizedBox(
                              height: 40,
                              width: 40,
                              child: Image.asset('assets/metro_train_icon.png', height: 40, width: 40,
                              )
                          ), // Replace with real asset
                          _buildDashedLine(),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: "Metro to MG Road in ", style: TextStyle(fontSize: 12)),
                                  TextSpan(
                                    text: "5 mins",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(width: 10,),

                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: HexColor("#015EA3"))
                              ),
                              child: Text("View Map", style: TextStyle(color: HexColor("#015EA3"), fontSize: 11),),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                          height: 40,
                          width: 40,
                          child: Image.asset('assets/bike_icon.png',
                            height: 40, width: 40,
                          )
                      ), // Replace with real asset
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: "Drop Ride will be assigned near\n"),
                              TextSpan(
                                text: "MG Road Metro",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),

            Container(
              margin: EdgeInsets.only(left: 10, right: 10),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15), // shadow color
                    blurRadius: 10, // how soft the shadow is
                    spreadRadius: 2, // how wide the shadow spreads
                    offset: const Offset(0, 0), // 0,0 means shadow on ALL sides
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bike will be waiting at MG Road Metro for drop to Sambhram College",
                    style: TextStyle(color: Colors.black),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Fare, 50-14 min",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "We’ll auto-assign your bike driver once you exit at MG Road",
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
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

  Widget _buildDashedLine() {
    return Container(
      width: 1,
      height: 40,
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Colors.grey,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
      ),
    );
  }
}
