import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/Screens/FeedbackThanksScreen/feed_back_thanks_screen.dart';
import 'package:hexcolor/hexcolor.dart';



class TipScreen extends StatefulWidget {
  const TipScreen({super.key});

  @override
  State<TipScreen> createState() => _TipScreenState();
}

class _TipScreenState extends State<TipScreen> {
  double? selectedAmount;

  final List<double> tipAmounts = [
    1, 2, 3, 4, 5, 10, 15, 20, 25
  ];

  void _showCustomAmountDialog() async {
    TextEditingController controller = TextEditingController();

    double? enteredAmount = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)),
          title: const Text("Enter Custom Amount"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: "Enter amount in \$",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  final value = double.tryParse(controller.text);
                  Navigator.pop(context, value);
                }
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );

    if (enteredAmount != null) {
      setState(() {
        selectedAmount = enteredAmount;
      });
    }
  }

  void _onPayTip() {
    pushTo(context, FeedBackThanksScreen());
  }

  @override
  Widget build(BuildContext context) {

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // for Android
      statusBarBrightness: Brightness.dark, // for iOS
    )
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(0),
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
                            "Pay Tip",
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


            const SizedBox(height: 20),

            // Driver Image
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage("assets/user_image.jpeg"), // replace with real image
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              "Wow 5 Stars!",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // Subtitle
            const Text(
              "Would you like to add a tip to make your \ndriver's day?",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black38),
            ),

            const SizedBox(height: 25),

            // Tip Amount Buttons
            Container(
              margin: EdgeInsets.only(left: 15, right: 15),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 15,
                runSpacing: 15,
                children: tipAmounts.map((amount) {
                  bool isSelected = selectedAmount == amount;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedAmount = amount;
                      });
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.3 - 10,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? HexColor("#A2BF49") : Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: HexColor('#EDEDED')),
                      ),
                      child: Center(
                        child: Text(
                          "\$${amount.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Custom Amount
            GestureDetector(
              onTap: _showCustomAmountDialog,
              child:  Text(
                "Enter custom amount",
                style: TextStyle(
                  fontSize: 14,
                  color: HexColor("#015EA3"),
                ),
              ),
            ),

            const SizedBox(height: 15),

            Container(
              margin: EdgeInsets.only(left: 50, right: 50),
                child: Divider(color: HexColor('#EDEDED'),
                ),
            ),

            const SizedBox(height: 15),

            // Info Text
            const Text(
              "Tip will be charged from your GoRide Wallet.\n100% of the tip goes to drivers.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),

            const Spacer(),


            Divider(color: HexColor('#EDEDED'),),

            const SizedBox(height: 15),


            // Bottom Buttons
            Row(
              children: [

                SizedBox(width: 15,),

                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side:  BorderSide(color: HexColor("#D9D9D9")),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Skipped tip")),
                      );
                    },
                    child: Text(
                      "Skip",
                      style: TextStyle(color: HexColor("#A2BF49"), fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HexColor("#015EA3"),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: _onPayTip,
                    child: const Text(
                      "Pay Tip",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),

                SizedBox(width: 15,),
              ],
            ),

            SizedBox(height: 20,)
          ],
        ),
      ),
    );
  }
}
