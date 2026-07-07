import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/CommonWidgets/button_widget.dart';
import 'package:movezy_user_app/Screens/DashboardScreen/dashboard_screen.dart';
import 'package:hexcolor/hexcolor.dart';


class RideCanceledSuccessScreen extends StatefulWidget {
  const RideCanceledSuccessScreen({super.key});

  @override
  State<RideCanceledSuccessScreen> createState() => _RideCanceledSuccessScreenState();
}

class _RideCanceledSuccessScreenState extends State<RideCanceledSuccessScreen> {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // for Android
      statusBarBrightness: Brightness.dark, // for iOS
      )
    );

    return Scaffold(
      bottomNavigationBar: Container(
        margin: EdgeInsets.only(bottom: 10),
        height: 75,
        padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 12),
        child: ButtonWidget(
          backgroundColor: HexColor("#A2BF49"),
          height: 50,
          text: "Ok",onTap: ()
          {
             replaceRoute(context, DashboardScreen());
          },
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
                            "Cancel Ride",
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
                        color: HexColor("#34C759"),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 50),
                    ),

                    SizedBox(height: 20,),

                    Text("Ride has been canceled!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),

                    SizedBox(height: 10,),

                    Container(
                      margin: EdgeInsets.only(left: 20, right: 20),
                        child: Text(
                          "Funds have been returned to your account. You can see the cancellation history in the activity manu",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Colors.grey),
                          textAlign: TextAlign.center,
                        )
                    ),

                  ],
                ))
          ],
        ),
      ),
    );
  }
}
