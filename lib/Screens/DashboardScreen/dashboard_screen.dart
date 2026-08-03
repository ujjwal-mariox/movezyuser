import 'package:flutter/material.dart';
import 'package:movezy_user_app/Screens/BookingHistory/booking_history.dart';
import 'package:movezy_user_app/Screens/CoinsScreen/coins_screen.dart';
import 'package:movezy_user_app/Screens/HomeScreen/home_screen.dart';
import 'package:movezy_user_app/Screens/ProfileScreen/profile_screen.dart';
import 'package:movezy_user_app/Screens/RechangeWalletApp/recharge_wallet_screen.dart';
import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  Widget _buildPage(int index) {
    switch (index) {
      case 0: return HomeScreen();
      case 1: return BookingHistory();
      case 2: return CoinsScreen();
      case 3: return WalletRechargeApp();
      case 4: return ProfileScreen();
      default: return HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
               height: 107,
               width: MediaQuery.of(context).size.width,
               child: Stack(
                 children: [
                   Container(
                     margin: EdgeInsets.only(top: 31),
                     child: ClipRRect(
                       borderRadius: BorderRadius.only(
                         topLeft: Radius.circular(25),
                         topRight: Radius.circular(25),
                       ),
                       child: Image.asset(
                         "assets/bottom_navigation_bg.png",
                         fit: BoxFit.cover,
                         height: 76,
                         width: MediaQuery.of(context).size.width,
                       ),
                     ),
                   ),


                   Positioned(
                       bottom: 8,
                       left: 0,
                       right: 0,
                       child: Container(
                         child: Row(
                           children: [
                             Expanded(
                               child: InkWell(
                                 onTap: (){
                                   setState(() {
                                     _currentIndex = 0;
                                   });
                                 },
                                 child: Container(
                                   child: Column(
                                     children: [
                                       Image.asset(_currentIndex == 0 ? "assets/home_se_ds.png" : "assets/home_ds.png", width: 24,),
                                       Text("Home", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 12, letterSpacing: -0.36),)
                                     ],
                                   ),
                                 ),
                               ),
                             ),

                             Expanded(
                               child: InkWell(
                                 onTap: (){
                                   setState(() {
                                     _currentIndex = 1;
                                   });
                                 },
                                 child: Container(
                                   child: Column(
                                     children: [
                                       Image.asset(_currentIndex == 1 ? "assets/clock_se_ds.png" : "assets/clock_ds.png", width: 24,),
                                       Text("History", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 12, letterSpacing: -0.36),)
                                     ],
                                   ),
                                 ),
                               ),
                             ),

                             Expanded(
                               child: InkWell(
                                 onTap: (){
                                   setState(() {
                                     _currentIndex = 2;
                                   });
                                 },
                                 child: Container(
                                   child: Column(
                                     children: [
                                       // Icon lives in the raised badge above;
                                       // a second one here doubled it up.
                                       const SizedBox(height: 24),
                                       Text("Coin", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14, letterSpacing: -0.36),)
                                     ],
                                   ),
                                 ),
                               ),
                             ),

                             Expanded(
                               child: InkWell(
                                 onTap: (){
                                   setState(() {
                                     _currentIndex = 3;
                                   });
                                 },
                                 child: Container(
                                   child: Column(
                                     children: [
                                       Image.asset(_currentIndex == 3 ? "assets/wallet_se_ds.png" : "assets/wallet_ds.png", width: 24,),
                                       Text("Wallet", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 12, letterSpacing: -0.36),)
                                     ],
                                   ),
                                 ),
                               ),
                             ),

                             Expanded(
                               child: InkWell(
                                 onTap: (){
                                   setState(() {
                                     _currentIndex = 4;
                                   });
                                 },
                                 child: Container(
                                   child: Column(
                                     children: [
                                       Image.asset(_currentIndex == 4 ? "assets/profile_se_ds.png" : "assets/profile_ds.png", width: 24,),
                                       Text("Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 12, letterSpacing: -0.36),)
                                     ],
                                   ),
                                 ),
                               ),
                             ),
                           ],
                         ),
                       )
                   ),

                   Positioned(
                     top: 0,
                     left: 0,
                     right: 0,
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       crossAxisAlignment: CrossAxisAlignment.center,
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         // The raised coin badge is the most prominent thing in
                         // the nav bar and was a bare Container — no InkWell,
                         // no GestureDetector — so tapping it did nothing at
                         // all. It now opens Coins, like the tab beneath it.
                         Container(
                           padding: const EdgeInsets.all(4),
                           decoration: const BoxDecoration(
                             color: Colors.white,
                             shape: BoxShape.circle,
                           ),
                           child: Material(
                             color: AppColors.appColor,
                             shape: const CircleBorder(),
                             clipBehavior: Clip.antiAlias,
                             child: InkWell(
                               onTap: () => setState(() => _currentIndex = 2),
                               child: Container(
                                 height: 52,
                                 width: 52,
                                 padding: EdgeInsets.all(14),
                                 child: Image.asset("assets/coins_dashboard.png", height: 24),
                               ),
                             ),
                           ),
                         ),
                       ],
                     ),
                   ),
                 ],
               ),
          ),
          // The system gesture-bar strip, in brand orange so the bar reads as
          // one continuous element down to the screen edge.
          Container(
            height: MediaQuery.of(context).padding.bottom,
            width: MediaQuery.of(context).size.width,
            color: AppColors.appColor,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(5, (i) => _buildPage(i)),
      ),
    );
  }
}
