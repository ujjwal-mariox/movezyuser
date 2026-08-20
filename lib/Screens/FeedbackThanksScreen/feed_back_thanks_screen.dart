import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/CommonWidgets/button_widget.dart';
import 'package:movezy_user_app/Screens/DashboardScreen/dashboard_screen.dart';
import 'package:hexcolor/hexcolor.dart';


class FeedBackThanksScreen extends StatefulWidget {
  const FeedBackThanksScreen({super.key});

  @override
  State<FeedBackThanksScreen> createState() => _FeedBackThanksScreenState();
}

class _FeedBackThanksScreenState extends State<FeedBackThanksScreen> {
  @override
  Widget build(BuildContext context) {

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // for Android
      statusBarBrightness: Brightness.dark, // for iOS
      )
    );

    return Scaffold(
      // SafeArea(top: false): the bar applies no inset itself, so the 10pt
      // design margin left the "Ok" button under the gesture bar / nav buttons.
      // The 10 stays; the device inset is added on top of it.
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: EdgeInsets.only(bottom: 10),
          height: 75,
          padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 12),
          child: ButtonWidget(
            backgroundColor: HexColor("#015EA3"),
            height: 50,
            text: "Ok",onTap: (){
              replaceRoute(context, DashboardScreen());
            },
          ),
        ),
      ),
      body: Container(
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


            Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [

                     Container(
                       width: 80,
                       height: 80,
                       decoration: BoxDecoration(
                         color: HexColor("#A2BF49"),
                         shape: BoxShape.circle,
                       ),
                       child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
                     ),

                      SizedBox(height: 20,),

                      Text("Thanks for your feedback!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),

                      SizedBox(height: 10,),

                      Text("See you on your next trip!", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: Colors.grey),),


              ],
            ))
          ],
        ),
      ),
    );
  }
}
