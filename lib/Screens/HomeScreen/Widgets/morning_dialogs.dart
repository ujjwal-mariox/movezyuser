import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';

class MorningDialogs extends StatefulWidget {
  const MorningDialogs({super.key});

  @override
  State<MorningDialogs> createState() => _MorningDialogsState();
}

class _MorningDialogsState extends State<MorningDialogs> {

  int selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          GestureDetector(
            onTap: () => Navigator.pop(context), // Close the sheet
            child: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white
              ),
              child: const Icon(Icons.close, color: Colors.black, size: 25),
            ),
          ),

          SizedBox(height: 13,),

          Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    "Good Morning Aditya",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                   Text("आज कहाँ चलना है?", style: TextStyle(fontSize: 14,color: Colors.black, fontWeight: FontWeight.w600)),
                   Text(
                    "हम आपके लिए best time-saving plan लाए हैं",
                    style: TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                  // Buttons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _optionButton("assets/near_home_icon.png", "Home", 0),
                      const SizedBox(width: 8),
                      _optionButton("assets/near_office_icon.png", "Office", 1),
                      const SizedBox(width: 8),
                      _optionButton("assets/near_metro_icon.png", "Near Metro", 2),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Transport Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Transport Icons
                            Row(
                              children: [
                                Image.asset("assets/car_icon.png", height: 32,width: 32,),
                                SizedBox(width: 4),
                                Icon(Icons.add, size: 18,),
                                SizedBox(width: 4),
                                Image.asset("assets/metro_train_icon.png", height: 25,width: 25,),
                                SizedBox(width: 4),
                                Icon(Icons.add, size: 18,),
                                SizedBox(width: 4),
                                Image.asset("assets/bike_icon.png", height: 25,width: 25,),
                              ],
                            ),
                            const SizedBox(width: 12),

                            const Spacer(),

                            // Time
                            const Text("48 mins", style: TextStyle(fontSize: 16)),
                          ],
                        ),

                        SizedBox(height: 5,),

                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "₹ 145.00",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Save 15 mins vs full cab",
                                style: TextStyle(color: HexColor("#A2BF49"), fontSize: 12),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Book Button
                        SizedBox(
                          height: 50,
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: HexColor('#A2BF49'),
                              padding: const EdgeInsets.symmetric(vertical: 7),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "Yes, Book My Journey",
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                         Text(
                          "Limited-time offer : Earn +20 MetroPoints on this ride",
                          style: TextStyle(fontSize: 9, color: Colors.black, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _optionButton(String icon, String label, int index) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Image.asset(icon,fit: BoxFit.cover,height: 15,color: selectedIndex == index ? Colors.white : HexColor('#015EA3'),),
      label: Text(label, style: TextStyle(color: selectedIndex == index ? Colors.white : HexColor('#015EA3'), fontSize: 11),),
      style: OutlinedButton.styleFrom(backgroundColor:selectedIndex == index ? HexColor("#015EA3") : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
