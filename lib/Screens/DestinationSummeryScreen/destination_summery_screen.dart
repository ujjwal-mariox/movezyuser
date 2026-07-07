import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/CommonWidgets/button_widget.dart';
import 'package:movezy_user_app/Screens/TipScreen/tip_screen.dart';
import 'package:hexcolor/hexcolor.dart';

class DestinationSummeryScreen extends StatefulWidget {
  const DestinationSummeryScreen({super.key});

  @override
  State<DestinationSummeryScreen> createState() => _DestinationSummeryScreenState();
}

class _DestinationSummeryScreenState extends State<DestinationSummeryScreen> {

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
      bottomNavigationBar: Container(
        margin: EdgeInsets.only(bottom: 10),
        height: 75,
        padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 12),
        child: ButtonWidget(
          backgroundColor: HexColor("#A2BF49"),
          height: 50,
          text: "Book Return",onTap: (){
          pushTo(context, TipScreen());
        },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                            "Ride Complete",
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

            SizedBox(height: 25,),

            SizedBox(
              width: 80,
              height: 80,
              child: Image.asset("assets/success_icon.png"),
            ),


            SizedBox(height: 10,),

            const Text(
              "You've reached your destination!",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Sambhram College",
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),

            // Total Section
            Container(
              margin: EdgeInsets.only(left: 15, right: 15),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
                children: const [
                  Text(
                    "Total : 145   |   52 mins",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "You saved 3.8 kg CO₂ compared to taking only a cab.\nGreat choice for a greener planet!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.black87),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Rewards Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              margin: EdgeInsets.only(left: 15, right: 15),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.card_giftcard, color: Colors.black87),
                      SizedBox(width: 6),
                      Text(
                        "You earned +20 MetroPoints",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                      children: [
                        TextSpan(text: "Total : "),
                        TextSpan(
                          text: "120 MetroPoints",
                          style: TextStyle(color: HexColor("#015EA3")),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5,
                    (index) => const Icon(Icons.star,
                    color: Colors.amber, size: 32),
              ),
            ),

            const SizedBox(height: 20),

            // Tags
            Container(
              width: MediaQuery.of(context).size.width,
              margin: EdgeInsets.only(left: 15, right: 15),
              child: Row(
                children: [
                  _Tag(label: "Driver polite"),
                  SizedBox(width: 2,),
                  _Tag(label: "Metro clean"),
                  SizedBox(width: 2,),
                  _Tag(label: "Bike fast"),
                  SizedBox(width: 2,),
                  _Tag(label: "Time saved"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Tile widget for Cab, Metro, Bike rows
class _TransportTile extends StatelessWidget {
  final String icon;
  final String label;
  final String details;

  const _TransportTile({
    required this.icon,
    required this.label,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const SizedBox(width: 5),
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
             border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(10),
            ),
              child: Image.asset(icon,width: 32, height: 32,)),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Tag Chip
class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.blue),
        ),
      ),
    );
  }
}
