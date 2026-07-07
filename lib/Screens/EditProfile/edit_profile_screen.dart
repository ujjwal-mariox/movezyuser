
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
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
                        "Edit Profile",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(width: 15,),
                    ],
                  ),
                ),
            ),

            Text("Full Name", style: TextStyle(color: HexColor("")),),


            Container(
              margin: EdgeInsets.only(left: 20, right: 20),
              decoration: BoxDecoration(
                  border: Border.all(color: HexColor("#B8B8B8")),
                  borderRadius: BorderRadius.circular(10)
              ),
              child: TextFormField(
                decoration: InputDecoration(
                  hint: Text('MIthu Kumar',
                    style: TextStyle(
                        color: HexColor("#B8B8B8"),
                        fontWeight: FontWeight.w400,
                        fontSize: 13
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                autovalidateMode: AutovalidateMode.always,
                keyboardType: TextInputType.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
