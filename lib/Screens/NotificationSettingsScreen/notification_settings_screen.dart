import 'package:flutter/material.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/CommonWidgets/wallet_widget.dart';
import 'package:movezy_user_app/Screens/RechangeWalletApp/recharge_wallet_screen.dart';



class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final Map<String, bool> settings = {
    'General Updates': true,
    'Safety and Security Alerts': true,
    'Account Notifications': false,
    'Ride Status Updates': true,
    'Promo Alerts': true,
    'Rating and Reviews': false,
    'Personalized Recommendations': true,
    'App Updates': true,
    'Service Updates': false,
    'Community Forum Activity': false,
    'Survey and Feedback Requests': false,
    'Important Announcements': true,
    'App Tips and Tutorials': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [

            commonAppBar(
                height : 100,
                context : context,
                child: Container(
                  padding: const EdgeInsets.only(top: 45),
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
                        "Notification Management",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Spacer(),

                      InkWell(
                          onTap: (){
                            pushTo(context, WalletRechargeApp());
                          },
                          child: walletWidget(context)),

                      SizedBox(width: 15,),
                    ],
                  ),
                )
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.only(top: 10, bottom: 20),
                children: settings.keys.map((String key) {

                  return SwitchListTile(
                    title: Text(
                      key,
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    value: settings[key]!,
                    onChanged: (bool value) {
                      setState(() {
                        settings[key] = value;
                      });
                    },

                    trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.transparent; // Color when the switch is ON (selected)
                      }
                      return Colors.transparent; // Color when the switch is OFF
                    }),
                    visualDensity: VisualDensity.compact,
                    activeThumbColor: Colors.green,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey.shade300,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
