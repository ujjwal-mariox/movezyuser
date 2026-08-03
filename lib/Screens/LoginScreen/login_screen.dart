import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:movezy_user_app/CommonWidgets/button_widget.dart';
import 'package:movezy_user_app/CommonWidgets/legal_sheet.dart';
import 'package:movezy_user_app/Screens/LoginScreen/LoginApiService/login_api_service.dart';
import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';
import 'package:movezy_user_app/Utils/CustomToast/custome_toast.dart';
import 'package:hexcolor/hexcolor.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isChecked = false;
  bool showLoader = false;

  @override
  Widget build(BuildContext context) {
    // viewPadding (not padding): padding.bottom collapses to 0 while the
    // keyboard is open, which made the card's bottom rows jump as soon as the
    // phone field was focused.
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [

              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.45,
                child: Stack(
                  children: [

                    Container(
                      height: MediaQuery.of(context).size.height * 0.45,
                      width: MediaQuery.of(context).size.width,
                      color: HexColor("#FF6200"),
                    ),

                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      top: 0,
                      child: Image.asset(
                        width: MediaQuery.of(context).size.width,
                        height: 300,
                        "assets/trucks_icon.png",
                        fit: BoxFit.fill,
                      ),
                    ),

                    Positioned(
                      bottom: 50,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          SizedBox(
                            width: 100,
                            child: Image.asset(
                              width: 100,
                              height: 100,
                              "assets/track_trip.png",
                            ),
                          ),

                          SizedBox(height: 20,),

                          Container(
                            margin: EdgeInsets.only(left: 30, right: 30),
                            child: Center(
                              child: Text.rich(
                                TextSpan(
                                  text: "Track trips ",
                                  style: TextStyle(fontSize: 21, color: Colors.amber, fontWeight: FontWeight.bold),
                                  children: [
                                    TextSpan(
                                      text: "from pickup \nto drop",
                                      style:  TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Positioned(
                      top: 55,
                        right: 20,
                        child:  Container(
                          height: 35,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 0.3),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            children: [
                              SizedBox(width: 10),
                              Container(
                                child: Image.asset(
                                  "assets/headphones.png",
                                  color: Colors.white,
                                  width: 22,
                                  height: 22,
                                ),
                              ),
                              SizedBox(width: 10),
                              const Text(
                                "Help",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 10),
                            ],
                          ),
                        ),
                    )
                  ],
                ),
              ),

              Positioned(
                top: MediaQuery.of(context).size.height * 0.42,
                left: 0,
                right: 0,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.58,
                  // This card is flush with the bottom of the screen, so its
                  // last rows (the WhatsApp opt-in and the terms line) sat
                  // underneath the gesture bar / nav buttons. Reserve the
                  // device's real bottom inset rather than guessing a constant.
                  padding: EdgeInsets.only(bottom: bottomInset),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25))
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.24,
                        child: Image.asset("assets/app_icon.png"),
                      ),

                      // Phone number label
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        width: MediaQuery.of(context).size.width,
                        alignment: Alignment.topLeft,
                        child: const Text(
                          "Log in with your mobile number",
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black
                          ),
                        ),
                      ),

                      SizedBox(height: 20,),

                      // Phone number input
                      Container(
                        margin: EdgeInsets.only(left: 16, right: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: HexColor("#B8B8B8")),
                        ),
                        child: TextField(
                          maxLength: 10,
                          controller: _phoneController,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9]')),
                          ],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            counterText: "",
                            hintText: "Enter Phone Number",
                            hintStyle: TextStyle(color: HexColor("#B8B8B8")),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 10,),

                      Expanded(child: Container(height: 0,)),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: ButtonWidget(
                          text: "Get OTP",
                          textStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                          backgroundColor: AppColors.appColor,
                          borderRadius: BorderRadius.circular(10),
                          onTap: () async {
                            if(_phoneController.text.toString() == "")
                            {
                              showCustomToast(context, "Please enter mobile number.");
                            }
                            else if(_phoneController.text.toString().length != 10)
                            {
                              showCustomToast(context, "Please enter valid mobile number.");
                            }
                            else
                            {
                              setState(() {
                                showLoader = true;
                              });

                              await LoginApiService().loginApi(
                                  context, _phoneController.text.toString(),
                                  whatsappOptIn: _isChecked);

                              if (mounted) {
                                setState(() {
                                  showLoader = false;
                                });
                              }
                            }
                          },
                        ),
                      ),

                      SizedBox(height: 10,),

                      Expanded(child: Container(height: 0,)),

                      Container(
                        width: MediaQuery.of(context).size.width,
                        margin: EdgeInsets.only(left: 15, right: 15),
                        alignment: Alignment.center,
                        child: Text.rich(
                            TextSpan(
                              text: "By signing up, you accept our ",
                              style: TextStyle(fontSize: 9, color: Colors.black, fontWeight: FontWeight.bold),
                              children: [
                                TextSpan(
                                  text: "Terms of use",
                                  // Styled as a link but had no recognizer, so
                                  // the user was asked to accept terms they had
                                  // no way to read.
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => showLegalSheet(context,
                                        'Terms & Conditions', LegalText.terms),
                                  style:  TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: HexColor("#0082DF"),
                                  ),
                                ),
                                TextSpan(
                                  text: " and ",
                                  style:  TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                TextSpan(
                                  text: "Privacy Policy",
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => showLegalSheet(context,
                                        'Privacy Policy', LegalText.privacy),
                                  style:  TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: HexColor("#0082DF"),
                                  ),
                                ),
                              ],
                            )
                        ),
                      ),

                      Expanded(child: Container(height: 0,)),

                      SizedBox(height: 10,),

                      // Checkbox
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap : (){
                                if(_isChecked == true)
                                {
                                  _isChecked = false;
                                }
                                else
                                {
                                  _isChecked = true;
                                }

                                setState(() {});
                              },
                              child: Container(
                                height: 25,
                                width: 25,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.black, width: 1.5)
                                ),
                                child: _isChecked == true ? Icon(Icons.check_outlined, size: 20,color: Colors.black) : Container(width: 0,),
                              ),
                            ),

                            SizedBox(width: 7,),

                            // Flexible: as a bare Row child this got unbounded
                            // width, so it could never ellipsize and the row
                            // overflowed on narrow screens / large text scale.
                            Flexible(
                              child: Text(
                                "Get notifications on ",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ),

                            SizedBox(width: 5,),

                            Image.asset("assets/whats_app_icon.png", width: 22,height: 22,),

                            SizedBox(width: 5,),

                            Text("WhatsApp", style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500),),
                          ],
                        ),
                      ),

                      Expanded(child: Container(height: 0,)),

                      SizedBox(height: 10,),
                    ],
                  ),
                ),
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
      ),
    );
  }

}
