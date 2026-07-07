import 'dart:async';
import 'package:flutter/material.dart';
import 'package:movezy_user_app/CommonWidgets/button_widget.dart';
import 'package:movezy_user_app/Screens/OtpScreen/OtpApiService/otp_api_service.dart';
import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';
import 'package:movezy_user_app/Utils/CustomToast/custome_toast.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:pinput/pinput.dart';


class OtpScreen extends StatefulWidget {
  final String mobileNumber;
   String token;
   OtpScreen({super.key, required this.mobileNumber, required this.token});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  int _secondsRemaining = 60;
  Timer? _timer;
  String pinValue = "";
  bool showLoader = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    _timer?.cancel();
    _secondsRemaining = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0; // rebuild so "Resend again" becomes active
        });
      }
      else
      {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  /// Verify the entered OTP. Shows a blocking loader while the request runs
  /// and guards against double-submits.
  Future<void> _verifyOtp() async {
    if (showLoader) return; // already verifying
    if (pinValue.toString().length < 6) {
      showCustomToast(context, "Please enter valid OTP.");
      return;
    }
    setState(() => showLoader = true);
    try {
      await OtpApiService().otpVerifyApi(
        context: context,
        otp: pinValue.toString(),
        token: widget.token,
        mobileNumber: widget.mobileNumber,
      );
    } finally {
      if (mounted) setState(() => showLoader = false);
    }
  }

  /// Resend the OTP, restart the 60s countdown, and refresh the txn token.
  Future<void> _resendOtp() async {
    if (showLoader) return;
    setState(() => showLoader = true);
    try {
      var res = await OtpApiService().resendOtp(context, widget.mobileNumber);
      widget.token = res?.data?.txnId ?? widget.token;
      startTimer();
    } finally {
      if (mounted) setState(() => showLoader = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 50,
      margin: EdgeInsets.only(left: 3, right: 3),
      textStyle: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: HexColor("#AFAFAF"), // or any color you want
            width: 2.0,
          ),
        ),
      ),
    );

    final focusedPinTheme = PinTheme(
      width: 50,
      height: 50,
      margin: EdgeInsets.only(left: 3, right: 3),
      textStyle: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: HexColor("#AFAFAF"), // or any color you want
            width: 2.0,
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 100,
        leading: InkWell(
          onTap: (){
            Navigator.pop(context);
          },
          child: Container(
            padding: EdgeInsets.only(left: 20, top: 12, bottom: 8, right: 12),
            height: 30,
              width: 90,
              child: Row(
                children: [
                  Icon(Icons.arrow_back_ios_rounded, size: 19,),
                  SizedBox(width: 5,),
                  Text("Back", style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w500),
                  )
                ],
              )
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 0),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Text(
                    "Phone verification",
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 7),

                // Subtitle
                 Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 20),
                   child: Text(
                    "We've sent a 6-digit verification code to your\nmobile number or email. Please enter the\ncode below to verify your identity.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: HexColor("#A0A0A0"),
                      fontWeight: FontWeight.w400
                    ),
                               ),
                 ),
                const SizedBox(height: 40),

                // OTP boxes
                Container(
                  margin: EdgeInsets.only(left: 30, right: 30),
                  child: Center(
                    child: Pinput(
                      length: 6,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: focusedPinTheme,
                      onChanged: (value){
                        pinValue = value;
                        setState(() {

                        });
                      },
                      onCompleted: (pin) {
                        pinValue = pin;
                        _verifyOtp();
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Resend row: shows a live countdown, becomes tappable at 0.
                Center(
                  child: _secondsRemaining > 0
                      ? Text.rich(
                          TextSpan(
                            text: "Didn’t receive code?  ",
                            style: TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.w500),
                            children: [
                              TextSpan(
                                text: "Resend in 0:${_secondsRemaining.toString().padLeft(2, '0')}",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: HexColor("#A0A0A0"),
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        )
                      : InkWell(
                          onTap: _resendOtp,
                          child: Text.rich(
                            TextSpan(
                              text: "Didn’t receive code?  ",
                              style: TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.w500),
                              children: [
                                TextSpan(
                                  text: "Resend again",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: HexColor("#FF4E80"),
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                ),
                const SizedBox(height: 12),

                Expanded(child: Container(width: 0,)),

                // Sign In Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: ButtonWidget(
                    borderRadius: BorderRadius.circular(10),
                    backgroundColor: AppColors.appColor,
                    textStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17
                    ),
                    text: " Verify",
                    onTap: _verifyOtp,
                  ),
                ),

                SizedBox(height: 15,),

                Container(
                  margin: EdgeInsets.only(left: 30, right: 30),
                  child: Center(
                    child: Text.rich(
                      TextSpan(
                        text: "By continuing you agree to our ",
                        style: TextStyle(fontSize: 12, color: HexColor('#A0A0A0'), fontWeight: FontWeight.w500),
                        children: [
                          TextSpan(
                            text: "Terms of Services",
                            style:  TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: HexColor("#0082DF"),
                            ),
                          ),
                          TextSpan(
                            text: " and ",
                            style:  TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: HexColor("#A0A0A0"),
                            ),
                          ),
                          TextSpan(
                            text: "Privacy Policy",
                            style:  TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: HexColor("#0082DF"),
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                SizedBox(height: 20,),
              ],
            ),

            if(showLoader == true)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                top: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                        height: 40,
                        width: 40,
                        child: CircularProgressIndicator()
                    ),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}
