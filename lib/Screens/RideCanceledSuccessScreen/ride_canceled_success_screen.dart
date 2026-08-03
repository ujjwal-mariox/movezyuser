import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/CommonWidgets/button_widget.dart';
import 'package:movezy_user_app/Screens/DashboardScreen/dashboard_screen.dart';
import 'package:hexcolor/hexcolor.dart';


class RideCanceledSuccessScreen extends StatefulWidget {
  /// What the cancel API actually reported: wasPaid, refundAmount,
  /// refundPercentage, refundProcessed, coinsRestored.
  ///
  /// Null when we genuinely don't know (e.g. the booking was cancelled by the
  /// driver or an admin and we only learned via a status poll). In that case
  /// this screen says NOTHING about money — it used to claim "Funds have been
  /// returned to your account" unconditionally, including for unpaid bookings
  /// and for cancellations that refunded nothing.
  final Map<String, dynamic>? cancelResult;

  const RideCanceledSuccessScreen({super.key, this.cancelResult});

  @override
  State<RideCanceledSuccessScreen> createState() => _RideCanceledSuccessScreenState();
}

class _RideCanceledSuccessScreenState extends State<RideCanceledSuccessScreen> {
  /// Only ever states what the server confirmed.
  String _refundMessage() {
    final r = widget.cancelResult;
    const tail = 'You can see this booking in your order history.';
    if (r == null) return tail;

    final num amount = (r['refundAmount'] as num?) ?? 0;
    final bool processed = r['refundProcessed'] == true;
    final bool wasPaid = r['wasPaid'] == true;
    final int coins = (r['coinsRestored'] as num?)?.toInt() ?? 0;

    final parts = <String>[];
    if (!wasPaid) {
      parts.add('No payment was taken for this booking.');
    } else if (amount > 0 && processed) {
      parts.add('₹${amount.toStringAsFixed(0)} has been refunded to your original payment method.');
    } else if (amount > 0) {
      parts.add('A refund of ₹${amount.toStringAsFixed(0)} is being processed.');
    } else {
      parts.add('No refund is due for this cancellation.');
    }
    if (coins > 0) parts.add('$coins coins have been returned.');
    parts.add(tail);
    return parts.join(' ');
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
            backgroundColor: HexColor("#A2BF49"),
            height: 50,
            text: "Ok",onTap: ()
            {
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
                              safeBack(context);
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
                          _refundMessage(),
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
