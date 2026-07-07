import 'package:flutter/material.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/CommonWidgets/wallet_widget.dart';
import 'package:hexcolor/hexcolor.dart';


class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  int selectedIndex = 0;
  final List<String> tabs = ['Complete', 'Upcoming', 'Cancelled'];


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: Column(
          children: [

            commonAppBar(
                height : 110,
                context : context,
                child: Container(
                  padding: const EdgeInsets.only(top: 50),
                  child: Row(
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
                        "Ride History",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Spacer(),

                      walletWidget(context),

                      SizedBox(width: 15,),
                    ],
                  ),
                )
            ),

            SizedBox(height: 10,),

            Container(
              margin: EdgeInsets.only(left: 15, right: 15),
              height: 45,
              decoration: BoxDecoration(
                color: const Color(0xFFE9F4FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: HexColor('#015EA3')),
              ),
              child: Row(
                children: List.generate(tabs.length, (index) {
                  final isSelected = selectedIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color:
                          isSelected ? const Color(0xFF0C62A3) : Colors.transparent,
                          borderRadius: _getTabRadius(index),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          tabs[index],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            SizedBox(height: 5,),

            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Row(
                children: const [
                  Icon(Icons.location_on_outlined, color: Colors.grey),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Search",
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  Icon(Icons.close, color: Colors.grey),
                ],
              ),
            ),

            // List of rides
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: 3,
                itemBuilder: (context, index) {
                  return const RideCard();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  BorderRadius _getTabRadius(int index) {
    if (index == 0) {
      return const BorderRadius.only(
          topLeft: Radius.circular(8), bottomLeft: Radius.circular(8));
    } else if (index == tabs.length - 1) {
      return const BorderRadius.only(
          topRight: Radius.circular(8), bottomRight: Radius.circular(8));
    } else {
      return BorderRadius.zero;
    }
  }
}

class RideCard extends StatelessWidget {
  const RideCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage("assets/ride_history_driver.png"), // replace with your asset
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Mon, july 10",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "10 : 00 AM",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: HexColor("#A2BF49"),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Complete",
                  style: TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric( vertical: 4),
                child: const Text(
                  "₹220.00",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Pick up & Drop
          Row(
            children: [

              SizedBox(width: 60,),

              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 28,
                    color: Colors.green,
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Pick up Point",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text("Drop Point"),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Details Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              Column(
                children: [
                  Row(
                    children: const [
                      Icon(Icons.access_time, size: 18, color: Colors.black54),
                      SizedBox(width: 6),
                      Text("15 min"),
                    ],
                  ),
                  Row(
                    children: const [
                      Icon(Icons.timeline, size: 18, color: Colors.black54),
                      SizedBox(width: 6),
                      Text("5.2 miles"),
                    ],
                  ),
                ],
              ),

              Column(
                children: [
                  Row(
                    children: const [
                      Icon(Icons.directions_car,
                          size: 18, color: Colors.black54),
                      SizedBox(width: 6),
                      Text("Sedan\nabc 1234",
                          style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Row(
                    children: const [
                      Icon(Icons.credit_card, size: 18, color: Colors.black54),
                      SizedBox(width: 6),
                      Text("•••• 1324"),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: HexColor("#A2BF49"),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      topLeft: Radius.circular(8),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "View Details",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: HexColor("#A2BF49"),
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "Share Receipt",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
