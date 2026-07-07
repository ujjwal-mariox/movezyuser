import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/Screens/CoinsScreen/BottomSheets/coins_bottom_screen.dart';


class CoinsScreen extends StatefulWidget {
  const CoinsScreen({super.key});

  @override
  State<CoinsScreen> createState() => _CoinsScreenState();
}

class _CoinsScreenState extends State<CoinsScreen> {
  int _balance = 0;
  bool _loading = true;
  // Which FAQ tiles are expanded (index -> bool).
  final Set<int> _expandedFaqs = {};

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  /// Fetch the real coin balance from the backend (was hardcoded "00").
  Future<void> _fetchBalance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await http.get(
        Uri.parse(ApiUrls.coinsBalanceUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));
      final body = json.decode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final bal = (body['data']?['balance'] ?? 0);
        if (mounted) {
          setState(() {
            _balance = bal is int ? bal : (bal as num).toInt();
            _loading = false;
          });
          return;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
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
                      "Coins",
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

            Container(
              padding: EdgeInsets.only(left: 12, right: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  SizedBox(height: 20,),

                  Stack(
                    children: [

                      SizedBox(
                          width: MediaQuery.of(context).size.width - 30,
                          child: Image.asset("assets/available_coins_bg.png",)
                      ),

                      Container(
                        height: 150,
                        width: MediaQuery.of(context).size.width - 30,
                        padding: const EdgeInsets.only(left: 14, right: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 6,),
                                  Text(
                                    _loading
                                        ? '...'
                                        : _balance.toString().padLeft(2, '0'),
                                    style: const TextStyle(
                                      fontSize: 25,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                   Text(
                                    'Available Coins',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                  SizedBox(height: 5,),
                                  GestureDetector(
                                    onTap: () => _comingSoon('Coin history'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.white70),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Transaction History',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Image.asset(
                              'assets/coins.png',
                              height: 100,
                              fit: BoxFit.cover,
                            )
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 6,),

                  const Text('Use Coins', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(child: _iconCard('Transfer into', 'Movezy Credits', "assets/movezy_credits.png", onTap: _comingSoonTransfer)),
                      const SizedBox(width: 12),
                      Expanded(child: _iconCard('Transfer into', 'Bank Account', "assets/bank_account.png", onTap: _comingSoonTransfer)),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Text('More about Coins', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(child: _iconCard('How do I earn', 'coins?', "assets/earn_coins.png", onTap: _showCoinsInfo)),
                      const SizedBox(width: 12),
                      Expanded(child: _iconCard('How do I use', 'coins?', "assets/how_earn_coins.png", onTap: _showCoinsInfo)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const Center(
                    child: Text(
                      'Frequently asked questions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 16),
                  _faqTile(
                    0,
                    'How can I use Movezy coins?',
                    'Movezy coins are applied as a discount on your bookings at checkout. Coins are earned on completed deliveries.',
                  ),
                  _faqTile(
                    1,
                    'Do Movezy coins have validity?',
                    'Coins remain in your account and can be redeemed on any future booking unless a specific offer states an expiry.',
                  ),
                ],
              ),
            ),

            SizedBox(height: 100,)
          ],
        ),
      ),
    );
  }

  Widget _iconCard(String title, String subtitle, String icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFBEFE3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HexColor('#FF6200')),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: HexColor('#FF6200')),
                ),
                child: Icon(Icons.arrow_forward_ios_sharp, size: 12, color: Colors.orange),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 10)),
                      Text(subtitle, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                    ],
                  ),
                ],
              ),


            ],
          ),
          Spacer(),

          Container(
              child: Image.asset(icon, width: 58,height: 70,fit: BoxFit.fill,)
          ),
          SizedBox(width: 3,)
        ],
      ),
    ),
    );
  }

  Widget _faqTile(int index, String question, String answer) {
    final expanded = _expandedFaqs.contains(index);
    return InkWell(
      onTap: () => setState(() {
        if (expanded) {
          _expandedFaqs.remove(index);
        } else {
          _expandedFaqs.add(index);
        }
      }),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: expanded ? Colors.orange : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    question,
                    style: TextStyle(
                      fontSize: 16,
                      color: expanded ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: expanded ? Colors.white : Colors.orange,
                )
              ],
            ),
            if (expanded) ...[
              const SizedBox(height: 10),
              Text(
                answer,
                style: const TextStyle(fontSize: 13, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Coins transfer (to credits/bank) isn't available yet — be honest.
  void _comingSoonTransfer() => _comingSoon('Coin transfers');

  /// Generic honest "not available yet" feedback for coin features that have
  /// no backend endpoint (transfer, transaction history).
  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature are coming soon.')),
    );
  }

  /// Show the "how coins work" info sheet.
  void _showCoinsInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const EarnCoinsBottomSheet(),
    );
  }
}