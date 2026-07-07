import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/CommonWidgets/button_widget.dart';
import 'package:movezy_user_app/CommonWidgets/wallet_widget.dart';
import 'package:movezy_user_app/Screens/DashboardScreen/dashboard_screen.dart';
import 'package:movezy_user_app/Utils/CustomToast/custome_toast.dart';
import 'package:hexcolor/hexcolor.dart';

class BookingConfirmationScreen extends StatefulWidget {
  const BookingConfirmationScreen({super.key});

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  String selected = "UPI";

  @override
  Widget build(BuildContext context) {

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // for Android
      statusBarBrightness: Brightness.dark, // for iOS
    ));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [

          commonAppBar(
              height : 120,
              context : context,
              child: Container(
                padding: const EdgeInsets.only(top: 40),
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
                          "Booking Confirmed",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    Expanded(child: Container(width: 0,)),

                    walletWidget(context),

                    SizedBox(width: 15,),
                  ],
                ),
              )
          ),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
              ),
              child: ListView(
                padding: const EdgeInsets.only(top: 15,left: 15, right: 15),
                children: [
                  // Ride Segments
                  rideTile(
                    type: 'cab',
                    title: "Cab",
                    cost: "₹ 60",
                    icon: "assets/car_icon.png",
                    pickUpTime: "9:05 AM",
                    pickupLocation: "Sec 67, Hariyali Road",
                    totalTime: "12 mins",
                    dropLocation: "Chikka Banaswadi Metro Station",
                    dropTime: "9:17 AM",
                    index: 0
                  ),
                  rideTile(
                    type: 'metro',
                    title: "Metro Chikka Banaswadi",
                    cost: "₹ 35",
                    icon: "assets/metro_train_icon.png",
                    pickUpTime: "9:20 AM",
                    pickupLocation: "Platform No. 2",
                    totalTime: "18 mins",
                    dropLocation: "MG Road Metro, Gate 2",
                    dropTime: "9:38 AM",
                    index: 1
                  ),
                  rideTile(
                    type: 'bike',
                    title: "Bike",
                    cost: "₹ 50",
                    icon: 'assets/bike_icon.png',
                    pickUpTime: "9:45 AM",
                    pickupLocation: "MG Road Metro, Gate 2",
                    totalTime: "10 mins",
                    dropLocation: "Sambhram College",
                    dropTime: "9:55 AM",
                    index: 2
                  ),
                  const SizedBox(height: 12),
              
                  // Fare & Time Summary
                  summaryTile("Total Journey Fare", "₹ 145", 0),
                  Container(
                    height: 1,
                    width: MediaQuery.of(context).size.width - 50,
                    padding: EdgeInsets.only(left: 10, right: 10),
                    child: Image.asset('assets/yellow_dotted_line.png'),
                  ),
                  summaryTile("Total Time", "50 mins", 1),
                  Container(
                    height: 1,
                    width: MediaQuery.of(context).size.width - 50,
                    padding: EdgeInsets.only(left: 10, right: 10),
                    child: Image.asset('assets/yellow_dotted_line.png'),
                  ),
                  summaryTile("Total Journey Fare", "₹ 145", 2),
                  const SizedBox(height: 12),
              
                  // Payment Options
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Time Estimate",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap : (){
                                  selected = "UPI";
                                },
                                child: Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: selected == "UPI" ? Colors.blue : Colors.grey.shade300, width: 1.5),
                                    borderRadius: BorderRadius.circular(8),
                                    color: selected == "UPI" ? Colors.blue.shade50 : Colors.white,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset("assets/upi_icon.png", height: 30,width: 60,),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(width: 10,),

                            Expanded(
                              child: InkWell(
                                onTap : (){
                                  setState(() {
                                    selected = "Card";
                                  });
                                },
                                child: Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: selected == "Card" ? Colors.blue : Colors.grey.shade300, width: 1.5),
                                    borderRadius: BorderRadius.circular(8),
                                    color: selected == "Card" ? Colors.blue.shade50 : Colors.white,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset("assets/card_icon.png", height: 22,width: 22,),
                                      SizedBox(width: 6,),
                                      Text(
                                        "Card",
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(width: 10,),

                            Expanded(
                              child: InkWell(
                                onTap : (){
                                  setState(() {
                                    selected = "Wallet";
                                  });
                                },
                                child: Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: selected == "Wallet" ? Colors.blue : Colors.grey.shade300, width: 1.5),
                                    borderRadius: BorderRadius.circular(8),
                                    color: selected == "Wallet" ? Colors.blue.shade50 : Colors.white,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset("assets/wallet.png", height: 20,width: 20,),
                                      SizedBox(width: 6,),
                                      Text(
                                        "Wallet",
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          "Secure Payment • Instant Refund on Cancellation",
                          style:
                          TextStyle(fontSize: 10, color: Colors.black),
                        ),
                        const SizedBox(height: 3),
                      ],
                    ),
                  ),

                  SizedBox(height: 20,)
                ],
              ),
            ),
          ),

          // Confirm Button - Redirects to Dashboard with message
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 12),
            child: ButtonWidget(text: "Back to Home",onTap: (){
              showCustomToast(context, "Please use the main booking flow from Home screen");
              replaceRoute(context, DashboardScreen());
              },
            ),
          ),

          SizedBox(height: 7,)
        ],
      ),
    );
  }

  // Ride segment widget
   Widget rideTile({
    required String type,
    required String title,
    required String cost,
    required String icon,
    required String pickUpTime,
     required String dropTime,
     required String pickupLocation,
     required String dropLocation,
     required String totalTime,
     required int index
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.only(top: index == 0 ? 15 : 12, left: 12, right: 12,bottom: index == 2 ? 0 : 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topRight: Radius.circular(index == 0 ? 15 : 0),
                topLeft: Radius.circular(index == 0 ? 15 : 0),
                bottomRight: Radius.circular(index == 2 ? 15 : 0),
                bottomLeft: Radius.circular(index == 2 ? 15 : 0)
            )
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      border: Border.all(color: HexColor("#EEEEEF")),
                      borderRadius: BorderRadius.circular(8)
                    ),

                      child: Image.asset(icon, width: 35,height: 35,)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(cost,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        SizedBox(height: 7,),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(pickUpTime,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 11)),
                            SizedBox(width: 7,),
                            Text(pickupLocation,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),

                            Expanded(child: Container(width: 0,)),

                            Text(totalTime,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 11)),
                          ],
                        ),

                        SizedBox(height: 7,),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(dropTime,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w400, fontSize: 11)),
                            SizedBox(width: 7,),
                            Text(dropLocation,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w400, fontSize: 11)),

                            Expanded(child: Container(width: 0,)),

                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 22,),

              if(index != 2)
              SizedBox(
                height: 1,
                width: MediaQuery.of(context).size.width,
                child: Image.asset('assets/yellow_dotted_line.png'),
              )
            ],
          ),
        ),
      ],
    );
  }


  // Fare summary row
   Widget summaryTile(String label, String value, int index) {
    return Container(
      padding: const EdgeInsets.symmetric( vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(index == 0 ? 15 : 0),
              topLeft: Radius.circular(index == 0 ? 15 : 0),
              bottomRight: Radius.circular(index == 2 ? 15 : 0),
              bottomLeft: Radius.circular(index == 2 ? 15 : 0)
          )
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(width: 15,),
          Text(label,
              style: const TextStyle(fontSize: 14, color: Colors.black87)),
          Expanded(child: Container(width: 0,)),
          Text(value,
              style:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),

          SizedBox(width: 15,),
        ],
      ),
    );
  }

  // Payment option button
   Widget paymentOption(String label, IconData icon,
      {bool selected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border.all(
            color: selected ? Colors.blue : Colors.grey.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(8),
        color: selected ? Colors.blue.shade50 : Colors.white,
      ),
      child: Row(
        children: [
          Icon(icon,
              color: selected ? Colors.blue : Colors.black54, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.blue : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
