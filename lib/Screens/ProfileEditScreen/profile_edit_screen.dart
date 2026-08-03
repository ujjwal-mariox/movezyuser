import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/CommonWidgets/button_widget.dart';
import 'package:movezy_user_app/CommonWidgets/wallet_widget.dart';
import 'package:hexcolor/hexcolor.dart';


class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  TextEditingController phoneNumber = TextEditingController();

  @override
  Widget build(BuildContext context) {

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark,
      )
    );

    return Scaffold(
      backgroundColor: Colors.grey[200],
      // SafeArea(top: false): this bar is a raw fixed-height Container, which
      // Scaffold gives no bottom inset, so "Save" sat under the Android gesture
      // bar / nav buttons and could not be tapped.
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          height: 95,
          child: Column(
            children: [
              Container(
                height: 1,
                width: MediaQuery.of(context).size.width,
                color: HexColor("#212020").withOpacity(0.2),
              ),

              SizedBox(height: 20,),

              // Sign In Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: ButtonWidget(
                  text: "Save",
                  onTap: (){
                  },
                ),
              ),

              SizedBox(height: 20,),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        
            SizedBox(
              height: 250,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    children: [
                      commonAppBar(
                          height : 150,
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
                                  "Profile",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
        
                                Spacer(),

                                walletWidget(context),
        
                                SizedBox(width: 15,),
                              ],
                            ),
                          )
                      ),
        
                      Expanded(child: Container(height: 0,))
                    ],
                  ),
        
                  Positioned(
                    top: 85,
                    child: SizedBox(
                        height: 155,width: 155,
                        child: Image.asset("assets/profile_1.png", height: 150,width: 150,)),
                  )
                ],
              ),
            ),
        
            SizedBox(height: 10,),
        
            Container(
              margin: EdgeInsets.only(left: 15, right: 15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Full Name", style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500)),
              
                  SizedBox(height: 8,),
              
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10)
                    ),
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        counterText: "",
                        hintText: "MIthu Kumar",
                        hintStyle: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w400),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
              
                  SizedBox(height: 12,),
              
              
                  Text("Email", style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500)),
              
                  SizedBox(height: 8,),
              
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        counterText: "",
                        prefixIcon: Container(
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                            child: Icon(Icons.email_outlined, color: Colors.black)),
                        hintText: "andrew.ainsley@yourdomain.com",
                        hintStyle: TextStyle(color: Colors.black,fontSize: 13, fontWeight: FontWeight.w400),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 12,),

                  Text("Phone Number", style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500)),
              
                  SizedBox(height: 8,),
              
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: TextField(
                      controller: phoneNumber,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        counterText: "",
                        prefixIcon: const Icon(Icons.phone_in_talk, color: Colors.black),
                        hintText: "Phone Number",
                        hintStyle: TextStyle(color: Colors.black,fontSize: 13, fontWeight: FontWeight.w400),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
              
                  SizedBox(height: 12,),
              
              
                  Text("Gender", style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500)),
              
                  SizedBox(height: 8,),
              
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10)
                    ),
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        counterText: "",
                        hintText: "Male",
                        hintStyle: TextStyle(color: Colors.grey,fontSize: 13, fontWeight: FontWeight.w400),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
              
                  SizedBox(height: 12,),
              
              
                  Text("Date of Birth", style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500)),
              
                  SizedBox(height: 8,),
              
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10)
                    ),
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        counterText: "",
                        hintText: "08/02/2001",
                        hintStyle: TextStyle(color: Colors.grey,fontSize: 13, fontWeight: FontWeight.w400),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
              
                  SizedBox(height: 12,),
                ],
              ),
            ),
        
            SizedBox(height: 15,),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(String title, String icon, {Widget? trailing}) {
    return ListTile(
      leading: SizedBox(
        height: 27,
        width: 27,
        child: Image.asset(icon, height: 27, width: 27,fit: BoxFit.cover,),
      ),
      title: Text(title, style: TextStyle(fontSize: 13),),
      trailing: trailing ??  Icon(Icons.arrow_forward_ios,color: HexColor("#6B7280"), size: 16),
    );
  }
}
