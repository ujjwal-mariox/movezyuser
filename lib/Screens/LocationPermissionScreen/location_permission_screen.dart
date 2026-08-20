import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/CommonWidgets/button_widget.dart';
import 'package:movezy_user_app/Screens/DashboardScreen/dashboard_screen.dart';
import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';
import 'package:movezy_user_app/Utils/CustomToast/custome_toast.dart';
import 'package:movezy_user_app/Services/referral_service.dart';
import 'package:hexcolor/hexcolor.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool showLoader = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  /// Check if location permission is already granted
  Future<void> _checkLocationPermission() async {
    try {
      final status = await Geolocator.checkPermission();

      // If permission is already granted, navigate to dashboard directly
      if (status == LocationPermission.whileInUse || status == LocationPermission.always) {
        // Permission already granted, move to dashboard
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            replaceRoute(context, DashboardScreen());
          }
        });
      }
    } catch (e) {
      print("Error checking location permission: $e");
    }
  }

  /// Request location permission
  Future<void> _requestLocationPermission() async {
    try {
      setState(() {
        showLoader = true;
      });

      final status = await Geolocator.requestPermission();

      setState(() {
        showLoader = false;
      });

      if (status == LocationPermission.whileInUse || status == LocationPermission.always) {
        // Permission granted, navigate to dashboard
        showCustomToast(context, "Location permission granted!");
        replaceRoute(context, DashboardScreen());
      } else if (status == LocationPermission.denied) {
        showCustomToast(context, "Location permission denied. You can enable it later in settings.");
      } else if (status == LocationPermission.deniedForever) {
        // Permission denied forever, show option to open settings
        showCustomToast(context, "Location permission is disabled in your settings.");
      }
    } catch (e) {
      setState(() {
        showLoader = false;
      });
      showCustomToast(context, "Error requesting location permission");
      print("Error requesting location permission: $e");
    }
  }

  /// Skip location permission and go to dashboard
  void _skipLocationPermission() {
    replaceRoute(context, DashboardScreen());
  }

  /// Show referral code input dialog
  void _showReferralCodeDialog() {
    final controller = TextEditingController();
    bool isApplying = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Enter Referral Code",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Got a referral code from a friend? Enter it below to earn rewards!",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: "e.g. ABC12345",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.appColor, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    "Skip",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: isApplying
                      ? null
                      : () async {
                          final code = controller.text.trim();
                          if (code.isEmpty) {
                            showCustomToast(context, "Please enter a referral code");
                            return;
                          }

                          setDialogState(() => isApplying = true);

                          try {
                            final result = await ReferralService.applyReferralCode(code);
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                            if (mounted) {
                              showCustomToast(context, result.message);
                            }
                          } catch (e) {
                            setDialogState(() => isApplying = false);
                            if (mounted) {
                              showCustomToast(context, "Failed to apply code. Try again.");
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.appColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isApplying
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Apply", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Map background (optional - you can add a map widget here or just keep it as is)
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: HexColor("#F5F5F5"),
            child: Image.asset(
              "assets/login_map_icon.png",
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.3),
            ),
          ),

          // Main content
          Center(
            child: SingleChildScrollView(
              child: Padding(
                // Scroll clearance: once the content is taller than the viewport
                // (small screen / large text scale) the last row — "Have a
                // referral code?" — ended up under the gesture bar, so add the
                // real inset to the scrolled content.
                padding: EdgeInsets.only(
                    left: 20.0,
                    right: 20.0,
                    bottom: MediaQuery.of(context).padding.bottom),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Location icon with gradient background
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: HexColor("#FFE8D9"),
                      ),
                      child: Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.appColor,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.location_on_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Title
                    Text(
                      "Enable your location",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 15),

                    // Description
                    Text(
                      "Choose your location to start find the request around you",
                      style: TextStyle(
                        fontSize: 14,
                        color: HexColor("#A0A0A0"),
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    // Use My Location Button
                    ButtonWidget(
                      text: "Use my location",
                      textStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      backgroundColor: AppColors.appColor,
                      borderRadius: BorderRadius.circular(12),
                      onTap: _requestLocationPermission,
                    ),

                    const SizedBox(height: 20),

                    // Skip for now Button
                    InkWell(
                      onTap: _skipLocationPermission,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        child: Text(
                          "Skip for now",
                          style: TextStyle(
                            fontSize: 16,
                            color: HexColor("#A0A0A0"),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Have a referral code?
                    InkWell(
                      onTap: _showReferralCodeDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          "Have a referral code?",
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.appColor,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.appColor,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // Loading indicator
          if (showLoader)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              top: 0,
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 50,
                      width: 50,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.appColor),
                      ),
                    ),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }
}
