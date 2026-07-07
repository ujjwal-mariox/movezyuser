import 'package:flutter/material.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/CommonWidgets/button_widget.dart';
import 'package:movezy_user_app/CommonWidgets/wallet_widget.dart';
import 'package:movezy_user_app/Screens/RechangeWalletApp/recharge_wallet_screen.dart';


class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final borderColor = const Color(0xFFBFD6F6); // Light blue border
    final buttonColor = const Color(0xFFA3C24D); // Green Done button
    final questionStyle = const TextStyle(
      fontSize: 12,
      color: Colors.black87,
      fontWeight: FontWeight.w500,
    );
    final answerStyle = const TextStyle(
      fontSize: 11,
      color: Colors.black54,
      height: 1.5,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                        "Help & Support",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Spacer(),

                      InkWell(
                        onTap: (){
                          pushTo(context, WalletRechargeApp());
                        },
                          child: walletWidget(context)
                      ),

                      SizedBox(width: 15,),
                    ],
                  ),
                )
            ),

            SizedBox(height: 20,),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                "Read FAQ’s",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  // FAQ Items with answers
                  _buildFaqItem(
                    question: "How do I create an account on the app?",
                    answer:
                    "To create an account, open the app and tap on ‘Sign Up’. "
                        "Fill in your details such as name, email, and password, "
                        "then tap ‘Create Account’. You will receive a verification email.",
                    borderColor: borderColor,
                    qStyle: questionStyle,
                    aStyle: answerStyle,
                  ),
                  _buildFaqItem(
                    question: "Can I book a ride without creating an account ?",
                    answer:
                    "No, you need to create an account before booking a ride. "
                        "This ensures your trip details, payments, and support requests "
                        "are linked securely to your profile.",
                    borderColor: borderColor,
                    qStyle: questionStyle,
                    aStyle: answerStyle,
                  ),
                  _buildFaqItem(
                    question: "How do I reset my password if I forget it?",
                    answer:
                    "On the login screen, tap on ‘Forgot Password’. "
                        "Enter your registered email address and follow the link "
                        "sent to your inbox to set a new password.",
                    borderColor: borderColor,
                    qStyle: questionStyle,
                    aStyle: answerStyle,
                  ),
                  _buildFaqItem(
                    question: "How do I update my profile information?",
                    answer:
                    "Go to your Profile section from the main menu, then tap "
                        "‘Edit Profile’. You can update your name, email, phone number, "
                        "and profile picture from there.",
                    borderColor: borderColor,
                    qStyle: questionStyle,
                    aStyle: answerStyle,
                  ),
                ],
              ),
            ),


            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                "Raise Ticket",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Text area
            Container(
              height: 204,
              margin: EdgeInsets.only(left: 15, right: 15),
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(6),
              ),
              child:  Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                child: Column(
                  children: [
                    SizedBox(height: 7,),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            labelText: "Subject",
                            labelStyle: TextStyle(color: Colors.indigo),
                          ),
                          items: const [
                            DropdownMenuItem(value: "payment", child: Text("Payment issue")),
                            DropdownMenuItem(value: "ride", child: Text("Ride issue")),
                            DropdownMenuItem(value: "account", child: Text("Account issue")),
                            DropdownMenuItem(value: "other", child: Text("Other")),
                          ],
                          onChanged: (_) {},
                        ),
                      ),
                    ),


                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: "",
                          hintStyle: TextStyle(color: Colors.black38),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),


            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
              child: ButtonWidget(text: 'Done',onTap: ()
              {
               Navigator.pop(context);
              },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem({
    required String question,
    required String answer,
    required Color borderColor,
    required TextStyle qStyle,
    required TextStyle aStyle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          title: Text(question, style: qStyle),
          childrenPadding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 12,
          ),
          children: [
            Text(answer, style: aStyle),
          ],
        ),
      ),
    );
  }
}
