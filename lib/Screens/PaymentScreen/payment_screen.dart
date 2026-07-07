import 'package:flutter/material.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/CommonWidgets/button_widget.dart';
import 'package:movezy_user_app/Screens/DashboardScreen/dashboard_screen.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedMethod = "Google Pay";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      bottomNavigationBar: Container(
        margin: EdgeInsets.only(bottom: 10),
        height: 75,
        padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 12),
        child: ButtonWidget(
          height: 50,
          backgroundColor: AppColors.appColor,
          borderRadius: BorderRadius.circular(10),
          textStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15),
          text: "Confirm & Pay",onTap: (){
               pushTo(context, DashboardScreen(),
             );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            commonAppBar(
                height : 140,
                context : context,
                child: Container(
                  padding: const EdgeInsets.only(top: 50),
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
                            "Payments",
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
              margin: EdgeInsets.only(top: 110),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(topRight: Radius.circular(25), topLeft: Radius.circular(25)),
                color: Colors.white
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 7),

                    const Text(
                      "Preferred Mode",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Preferred Mode Section
                    _buildCard(
                      children: [
                        _buildPaymentTile(
                          icon: "assets/payments/google_pay_icon.png",
                          title: "Google Pay",
                          trailing: selectedMethod == "Google Pay"
                              ?  Icon(Icons.check_circle,
                              color: HexColor("#FFD546"), size: 22)
                              : const Icon(Icons.radio_button_unchecked,
                              color: Colors.grey),
                          onTap: () {
                            setState(() => selectedMethod = "Google Pay");
                          },
                        ),
                        Divider(height: 1, color: HexColor("#ECECEC"),),
                        _buildPaymentTile(
                          icon: "assets/payments/paytm_icon.png",
                          title: "Paytm",
                          onTap: (){
                            setState(() {
                              selectedMethod = "Paytm";
                            });
                          },
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                               Text("₹145",
                                  style: TextStyle(
                                    color: HexColor('#8F8F8F'),
                                      fontSize: 13, fontWeight: FontWeight.w400)),
                              const SizedBox(width: 4),

                              SizedBox(width: 5,),

                              selectedMethod == "Paytm"
                                  ? const Icon(Icons.check_circle,
                                  color: Colors.blue, size: 22)
                                  : const Icon(Icons.radio_button_unchecked,
                                  color: Colors.grey),

                              SizedBox(width: 2,)
                            ],
                          ),
                        ),
                         Divider(height: 1, color: HexColor("#ECECEC"),),
                        _buildPaymentTile(
                          icon: "assets/payments/mastercard_icon.png",
                          title: "•••• 9999",
                          onTap: (){
                            setState(() {
                              selectedMethod = "•••• 9999";
                            });
                          },
                          subtitleWidget: Row(
                            children: const [
                              Icon(Icons.verified_user,
                                  size: 14, color: Colors.blue),
                              SizedBox(width: 4),
                              Text(
                                "Secured",
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(width: 5,),

                              selectedMethod == "•••• 9999"
                                  ? const Icon(Icons.check_circle,
                                  color: Colors.blue, size: 22)
                                  : const Icon(Icons.radio_button_unchecked,
                                  color: Colors.grey),

                              SizedBox(width: 2,)
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // UPI Section
                    const Text(
                      "UPI",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      children: [
                        _buildPaymentTile(
                          icon: "assets/payments/phone_pay.png",
                          title: "PhonePe UPI",
                          subtitle: "Low success rate currently",
                          onTap: (){
                            setState(() {
                              selectedMethod = "PhonePe UPI";
                            });
                          },
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(width: 5,),

                              selectedMethod == "PhonePe UPI"
                                  ? const Icon(Icons.check_circle,
                                  color: Colors.blue, size: 22)
                                  : const Icon(Icons.radio_button_unchecked,
                                  color: Colors.grey),

                              SizedBox(width: 2,)
                            ],
                          ),
                        ),
                        Divider(height: 1, color: HexColor("#ECECEC"),),
                        _buildPaymentTile(
                          icon: "assets/payments/mobikwik_icon.png",
                          title: "Mobikwik",
                          onTap: (){
                            setState(() {
                              selectedMethod = "Mobikwik";
                            });
                          },
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(width: 5,),

                              selectedMethod == "Mobikwik"
                                  ? const Icon(Icons.check_circle,
                                  color: Colors.blue, size: 22)
                                  : const Icon(Icons.radio_button_unchecked,
                                  color: Colors.grey),

                              SizedBox(width: 2,)
                            ],
                          ),
                        ),
                        Divider(height: 1, color: HexColor("#ECECEC"),),
                        _buildPaymentTile(
                          icon: "assets/payments/cred_pay.png",
                          title: "CRED pay",
                          onTap: (){
                            setState(() {
                              selectedMethod = "CRED pay";
                            });
                          },
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(width: 5,),

                              selectedMethod == "CRED pay"
                                  ? const Icon(Icons.check_circle,
                                  color: Colors.blue, size: 22)
                                  : const Icon(Icons.radio_button_unchecked,
                                  color: Colors.grey),

                              SizedBox(width: 2,)
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildPaymentTile({
    required String icon,
    required String title,
    String? subtitle,
    Widget? subtitleWidget,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height:  selectedMethod == title ? title == "PhonePe UPI" ? 133 : 130 : 76,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: selectedMethod == title ? CrossAxisAlignment.center : CrossAxisAlignment.center,
              children: [
                  Container(
                    width: 35, height: 35,
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      border: Border.all(color: HexColor("#CAC7C7")),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Image.asset(icon, width: 32, height: 32, fit: BoxFit.contain)
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        child: Text(title,
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                        )
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),


                    ],
                  ),
                ),

                SizedBox(width: 20,),

                if (trailing != null) trailing,

                SizedBox(width: 8,),
              ],
            ),

            if(selectedMethod == title)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 45, right: 5,bottom: 0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.appColor,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    setState(() => selectedMethod = "Google Pay");
                  },
                  child: Text(
                    "Pay using $title",
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}
