import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:hexcolor/hexcolor.dart';


class EarnCoinsBottomSheet extends StatefulWidget {
  const EarnCoinsBottomSheet({super.key});

  @override
  State<EarnCoinsBottomSheet> createState() => _EarnCoinsBottomSheetState();
}

class _EarnCoinsBottomSheetState extends State<EarnCoinsBottomSheet> {
  int currentIndex = 0;
  final CarouselSliderController carouselController = CarouselSliderController();


  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration:  BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            HexColor("#FDF6AB"),
            HexColor("#FFFFFF"),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "How to earn coins ?",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                height: 38,
                width: 38,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close, color: Colors.orange),
                  onPressed: () => Navigator.pop(context),
                ),
              )
            ],
          ),

          const SizedBox(height: 20),

          // Carousel
          Expanded(
            child: CarouselSlider(
              carouselController: carouselController,
              options: CarouselOptions(
                height: double.infinity,
                viewportFraction: 1,
                enableInfiniteScroll: false,
                enlargeCenterPage: true,
                autoPlay: false,
                onPageChanged: (i, _) {
                  setState(() => currentIndex = i);
                },
              ),
              items: [
                buildPage1(),
                buildPage2(),
                buildPage3(),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Custom Indicators (3 orange bars)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                height: 4,
                width: 42,
                decoration: BoxDecoration(
                  color: i == currentIndex ? Colors.orange : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Page 1 UI
  Widget buildPage1() {
    return Column(
      children: [
        Image.asset("assets/coins_plus.png", height: 120),
        const SizedBox(height: 20),
        const Text(
          "Earn 2 coins on every ₹100 spent on\nTruck or 2-wheeler booking",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Page 2 UI
  Widget buildPage2() {
    return Column(
      children: [
        Image.asset("assets/coins_conversion.png", height: 120),
        const Text(
          "For Movezy Credits: 1 Coin = ₹1",
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        const Text(
          "For Bank Transfer: 1 Coin = ₹0.9",
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  /// Page 3 UI
  Widget buildPage3() {
    return Column(
      children: [
        Image.asset("assets/hourglass.png", height: 120),
        const SizedBox(height: 20),
        const Text(
          "Movezy Coins expire after 30 days from\nthe date of credit",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
