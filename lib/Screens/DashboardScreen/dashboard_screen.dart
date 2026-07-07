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
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: List.generate(5, (i) => _buildPage(i)),
          ),


         Column(
           children: [
             Spacer(),
             SizedBox(
               height: 97,
               width: MediaQuery.of(context).size.width,
               child: Stack(
                 children: [
                   Container(
                     margin: EdgeInsets.only(top: 30),
                     child: ClipRRect(
                       borderRadius: BorderRadius.only(
                         topLeft: Radius.circular(25),
                         topRight: Radius.circular(25),
                       ),
                       child: Image.asset(
                         "assets/bottom_navigation_bg.png",
                         fit: BoxFit.cover,
                         height: 70,
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
                                       Image.asset(_currentIndex == 0 ? "assets/home_se_ds.png" : "assets/home_ds.png", width: 20,),
                                       Text("Home", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),)
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
                                       Image.asset(_currentIndex == 1 ? "assets/clock_se_ds.png" : "assets/clock_ds.png", width: 22,),
                                       Text("History", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),)
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
                                       Opacity(
                                         opacity: _currentIndex == 2 ? 1.0 : 0.6,
                                         child: Image.asset("assets/coins_dashboard.png", width: 22, height: 22,),
                                       ),
                                       Text("Coin", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),)
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
                                       Image.asset(_currentIndex == 3 ? "assets/wallet_se_ds.png" : "assets/wallet_ds.png", width: 22,),
                                       Text("Wallet", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),)
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
                                       Image.asset(_currentIndex == 4 ? "assets/profile_se_ds.png" : "assets/profile_ds.png", width: 22,),
                                       Text("Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),)
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
                         Container(
                           height: 45,
                           width: 45,
                           padding: EdgeInsets.all(10),
                           decoration: BoxDecoration(
                             color: AppColors.appColor,
                             borderRadius: BorderRadius.circular(100),
                           ),
                           child: Image.asset("assets/coins_dashboard.png", height: 20),
                         ),
                       ],
                     ),
                   ),
                 ],
               ),
             )
           ],
         )
        ],
      ),
    );
  }
}
