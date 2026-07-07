import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:hexcolor/hexcolor.dart';



class TicketScreen extends StatefulWidget {
  const TicketScreen({super.key});
  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {

  @override
  Widget build(BuildContext context) {

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // for Android
      statusBarBrightness: Brightness.dark, // for iOS
      )
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: SingleChildScrollView(
        child: Column(
          children: [

            commonAppBar(
                height : 100,
                context : context,
                child: Container(
                  padding: const EdgeInsets.only(top: 47),
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
                            "Your Metro Ticket (45:30M)",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: Column(
                children: [
                  // Card container that visually matches the screenshot
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                    child: Column(
                      children: [
                        // QR image
                        SizedBox(
                          height: 210,
                          child: Center(
                            child: Image.asset(
                              'assets/qr_code.png', // add your QR image here
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Name
                        const Text(
                          'Mithu Singh',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Route with arrow and station
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Flexible(
                              child: Text(
                                'Chikka Banaswadi',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward, size: 16, color: Colors.black54),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'MG | Road',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Date and time
                        const Text(
                          'Apr 24, 2024 • 16:15',
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                        ),

                        const SizedBox(height: 16),

                        // Fare & Wallet row inside a slightly rounded white box
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              // Fare
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Fare', style: TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.w700)),
                                    SizedBox(height: 6),
                                    Text('Paid from wallet', style: TextStyle(fontWeight: FontWeight.w400, fontSize: 13)),
                                  ],
                                ),
                              ),

                              // Wallet
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children:  [

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text('Wallet', style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w700)),
                                        SizedBox(width: 25),
                                        Text('₹195', style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w700)),
                                        SizedBox(width: 4),
                                      ],
                                    ),

                                    Text('Auto top-up enabled', style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w400)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Instruction rows
                        Column(
                          children: [
                            _InfoRow(icon: Icons.location_on, text: 'Enter via Gate No. 2',),
                            SizedBox(height: 8),
                            _InfoRow(icon: Icons.schedule, text: 'Next metro in 5 mins'),
                            SizedBox(height: 8),
                            _InfoRow(icon: Icons.qr_code_2, text: 'Show this QR at entry & exit gates'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bottom buttons - placed outside the white card
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: HexColor("#A2BF49"),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Refresh Ticket',
                            style: TextStyle(fontWeight: FontWeight.w400, color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: HexColor("#015EA3"),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Station Map',
                            style: TextStyle(fontWeight: FontWeight.w400, color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Colors.black),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }
}
