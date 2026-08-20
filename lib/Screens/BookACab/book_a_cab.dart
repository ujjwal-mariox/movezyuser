
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/CommonWidgets/wallet_widget.dart';
import 'package:movezy_user_app/Screens/BookACab/Widgets/routes_widget.dart';
import 'package:hexcolor/hexcolor.dart';

class BookACab extends StatefulWidget {
  const BookACab({super.key});

  @override
  State<BookACab> createState() => _BookACabState();
}

class _BookACabState extends State<BookACab> {

  // Colors tuned to the screenshot
  static const Color outerBlue = Color(0xFF1F5F9A); // deep blue frame
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFF3F6F7);
  static const Color priceGreen = Color(0xFF2E8B57);
  static const Color priceBlue = Color(0xFF2E67B3);
  static const Color tagBg = Color(0xFFFFF6E6);



  @override
  Widget build(BuildContext context) {

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // for Android
      statusBarBrightness: Brightness.dark, // for iOS
      )
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Stack(
          children: [
            Column(
              children: [
                commonAppBar(
                    height : 300,
                    context : context,
                    child: Container(
                      padding: const EdgeInsets.only(top: 50),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Row (Profile + Greeting + Wallet)
                          Row(
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
                                    "Book a cab",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              Expanded(child: Container(width: 0,)),

                              walletWidget(context),

                              SizedBox(width: 15,),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Pickup Location Field
                          Container(
                            margin: EdgeInsets.only(left: 15, right: 15),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: HexColor("#017CD7"),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              decoration: InputDecoration(
                                  icon: Image.asset("assets/location_on.png", height: 25,width: 25,),
                                  hintText: "Your current location",
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(
                                      fontSize: 15,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w400
                                  )
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),

                          Container(
                            margin: EdgeInsets.only(left: 15, right: 15),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              decoration: InputDecoration(
                                  icon: Image.asset("assets/search_icon.png", height: 22,width: 22,),
                                  hintText: "Where to ?",
                                  border: InputBorder.none,
                                  suffixIcon: InkWell(
                                    onTap: (){
                                    //  pushTo(context, name);
                                    },
                                    child: Container(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [

                                            SizedBox(width: 10,),

                                            Container(
                                              height: 35,
                                              width: 1.2,
                                              color: HexColor("#015EA3"),
                                            ),

                                            SizedBox(width: 10,),

                                            Icon(Icons.add, size: 24,color: HexColor("#015EA3"),),
                                          ],
                                        )),
                                  ),
                                  hintStyle: TextStyle(
                                      fontSize: 14,
                                      color: HexColor("#017CD7"),
                                      fontWeight: FontWeight.w400
                                  )
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                ),

                SizedBox(
                  height: 170,
                    width: MediaQuery.of(context).size.width,
                    child: Image.asset("assets/cap_service_image.png", fit: BoxFit.cover,)),

              ],
            ),


            Positioned(
              bottom: 355,
                left: 2,
                right: 2,
                child:  _buildFilterPills()
            ),
              // Scrollable list of cards),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              // NOTE: this screen is unreachable — nothing in lib/ constructs
              // BookACab and it has no entry in the router. A gesture-bar inset
              // was added here and then reverted: this Container is transparent
              // and the blue panel background lives inside RoutesWidget, so
              // padding it lifted the panel off the screen edge and exposed a
              // white band behind the gesture bar (targetSdk 36 forces
              // edge-to-edge, so the inset is genuinely non-zero). If this
              // screen is ever wired up, add the inset to RoutesWidget's own
              // EdgeInsets.all(7) instead, so the background still bleeds to
              // the edge while the content is inset.
              child: const SizedBox(
                height: 350,
                child: RoutesWidget(),
              ),
            )
          ],
        ),
      ),
    );
  }


  Widget _buildFilterPills() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Container(
        height: 45,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
            color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15), // shadow color
              blurRadius: 10, // how soft the shadow is
              spreadRadius: 2, // how wide the shadow spreads
              offset: const Offset(0, 0), // 0,0 means shadow on ALL sides
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(width: 5,),
            _filterPill('All', isSelected: true),
            Expanded(child: Container(width: 0,)),
            _filterPill('Affordable'),
            Expanded(child: Container(width: 0,)),
            _filterPill('Save Time'),
            Expanded(child: Container(width: 0,)),
            _filterPill('Conventional'),
            SizedBox(width: 5,),
          ],
        ),
      ),
    );
  }

  Widget _filterPill(String text, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? HexColor("#015EA3") : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isSelected
            ? [
          BoxShadow(
            color: Colors.blue.shade900.withOpacity(0.12),
            blurRadius: 2,
            offset: const Offset(0, 1),
          )
        ]
            : [],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  static Widget bottomShortcut(String title, String icon) {
    return Container(
      height: 40,
      padding: EdgeInsets.only(top: 4,bottom: 4),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.white,width: 1),
          borderRadius: BorderRadius.circular(100)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 10,),
          Image.asset(icon, width: 16,height: 16,),
          const SizedBox(width: 3),
          Text(title, style: TextStyle(fontSize: 11, color: Colors.white),),
          SizedBox(width: 10,),
        ],
      ),
    );
  }

}
