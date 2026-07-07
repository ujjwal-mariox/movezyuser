import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/CommonWidgets/button_widget.dart';
import 'package:movezy_user_app/Screens/PaymentSuccessScreen/payment_success_screen.dart';
import 'package:hexcolor/hexcolor.dart';

class PaymentCheckoutScreen extends StatefulWidget {
  const PaymentCheckoutScreen({super.key});

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  // Colors chosen to match the screenshot visually; adjust to taste.
  static const Color background = Colors.white;
  static const Color lightBluePill = Color(0xFFEAF3FF);
  static const Color pillText = Color(0xFF5C6B7A);
  static const Color primaryGreen = Color(0xFF9DB64A); // button
  static const Color footerGray = Color(0xFFF6F6F6);

  @override
  Widget build(BuildContext context) {

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // for Android
      statusBarBrightness: Brightness.dark, // for iOS
    ));

    return Scaffold(
      backgroundColor: background,
      body: Column(
        children: [

          SizedBox(height: 50,),

          // small close icon top-left
          InkWell(
            onTap: (){
              Navigator.pop(context);
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Icon(Icons.close, size: 25, color: Colors.grey[600]),
              ),
            ),
          ),

          // Main centered column
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // circular logo
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    width: 92,
                    height: 92,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: HexColor("#A2BF49"),
                    ),
                    child: Image.asset('assets/circular_app_icon.png', fit: BoxFit.cover,),
                  ),
                ),

                const SizedBox(height: 14),

                // Title
                const Text(
                  'Metromovezy_user_app',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 4),

                // subtitle/email
                Text(
                  'metromovezy_user_app@axisbank',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 22),

                // Amount rupee
                const Text(
                  '₹145.00',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 14),

                // Pill with order id
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: lightBluePill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Doordash Order Id 151091256777',
                    style: TextStyle(
                      fontSize: 13,
                      color: pillText,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom card-like area: account selection + Pay button
          Container(
            width: double.infinity,
            // approximate height similar to screenshot
            padding: EdgeInsets.only(top: 22, left: 18, right: 18, bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // "CHOOSE ACCOUNT OR CARD TO PAY WITH" label
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'CHOOSE ACCOUNT OR CARD TO PAY WITH',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Axis bank tile
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      // bank logo
                      Container(
                        width: 60,
                        height: 42,
                        decoration: BoxDecoration(
                          border: Border.all(color: HexColor("#CAC7C7")),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Image.asset('assets/axis_bank_icon.jpg', fit: BoxFit.contain),
                      ),
                      const SizedBox(width: 12),
                      // Bank name & masked number
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Axis Bank •••• 9999',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '9976567788@okaxis',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // chevron
                      Icon(Icons.keyboard_arrow_down,size: 28, color: Colors.grey[600]),
                    ],
                  ),
                ),

                const SizedBox(height: 10),


                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  child: ButtonWidget(text: 'Pay ₹145',onTap: ()
                    {
                      pushTo(context, PaymentSuccessScreen());
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Powered by row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'POWERED BY ',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black38,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Image.asset("assets/upi_icon.png", width: 35,height: 28,color: Colors.black38,),
                        const SizedBox(width: 12),
                        // Axis small text
                        Text(
                          '| Axis Bank',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black38,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
