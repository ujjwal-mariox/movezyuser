import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/CommonWidgets/button_widget.dart';
import 'package:movezy_user_app/Screens/HelpSupportScreen/help_support_screen.dart';
import 'package:movezy_user_app/Screens/LoginScreen/login_screen.dart';
import 'package:movezy_user_app/Screens/PorterEnterpriseScreen/porter_enterprise_screen.dart';
import 'package:movezy_user_app/Screens/ProfileScreen/Model/user_profile_response.dart';
import 'package:movezy_user_app/Screens/ProfileScreen/ProfileApiService/profile_api_service.dart';
import 'package:movezy_user_app/Screens/ProfileScreen/ProfileApiService/update_profile_api_service.dart';
import 'package:movezy_user_app/Screens/ProfileScreen/update_profile_screen.dart';
import 'package:movezy_user_app/Screens/ReferAndEarn/refer_and_earn_Screen.dart';
import 'package:movezy_user_app/Screens/SavedAddress/saved_address.dart';
import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';
import 'package:movezy_user_app/Utils/PermissionsManager/permissions_manager.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';
import 'package:movezy_user_app/Utils/ShareManager/share_manager.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserData? userData;
  bool isLoading = true;
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();
  bool isUploadingImage = false;
  String? _userGstin;
  String _selectedLanguage = 'English';

  static const String _termsContent = '''
1. By using Movezy, you agree to our terms of service.
2. All deliveries are subject to availability and verification.
3. Cancellation charges may apply after a driver has been assigned.
4. Users must ensure goods are packed properly before pickup.
5. Restricted or prohibited items are not allowed for delivery.
6. Movezy is not responsible for items not declared at the time of booking.
7. Payment must be completed before or upon delivery as per the selected method.
8. Movezy reserves the right to modify pricing and terms at any time.
''';

  static const String _privacyContent = '''
1. We collect your name, phone, email, and location to provide delivery services.
2. Your data is encrypted and stored securely.
3. We do not sell your personal information to third parties.
4. Location data is used only to facilitate pickups and deliveries.
5. Payment information is processed through secure payment gateways.
6. You can request account deletion by contacting support.
7. We may use anonymized data for analytics and service improvement.
8. Push notifications are used for order updates and promotions.
''';

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _fetchUserGst();
  }

  Future<void> _fetchUserGst() async {
    try {
      final token = Prefs.getString('token');
      if (token.isEmpty) return;
      final response = await http.get(
        Uri.parse(ApiUrls.gstUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['data'] != null && json['data']['gstin'] != null) {
          if (mounted) {
            setState(() {
              _userGstin = json['data']['gstin'];
            });
          }
        }
      }
    } catch (e) {
      debugPrint('GST fetch error: $e');
    }
  }

  Future<bool> _submitGstin(String gstin) async {
    try {
      final token = Prefs.getString('token');
      if (token.isEmpty) return false;
      final response = await http.post(
        Uri.parse(ApiUrls.gstUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'gstin': gstin}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('GST submit error: $e');
      return false;
    }
  }

Future<void> _fetchUserProfile() async {
  try {
    final response = await ProfileApiService().getUserProfile(context: context);
    if (response != null && mounted) {
      setState(() {
        userData = response.data;
        isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  } catch (e) {
    debugPrint('Error fetching profile: $e');
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
}

Future<void> _pickAndUploadImage() async {
  try {
    // Show image source selection sheet
    final source = await PermissionsManager.showImageSourceSheet(context);
    
    if (source == null) return; // User cancelled

    // Request appropriate permission
    bool hasPermission = false;
    if (source == 'camera') {
      hasPermission = await PermissionsManager.requestCameraPermission();
    } else {
      hasPermission = await PermissionsManager.requestGalleryPermission();
    }
    
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${source == 'camera' ? 'Camera' : 'Gallery'} permission is required")),
        );
      }
      return;
    }

    final XFile? pickedFile = await _imagePicker.pickImage(
      source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80,
    );

    if (!mounted) return;

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      
      setState(() {
        _selectedImage = imageFile;
        isUploadingImage = true;
      });

      // Upload the image
      bool success = await UpdateProfileApiService().updateUserProfile(
        context: context,
        fullName: userData?.fullName ?? '',
        email: userData?.email ?? '',
        gender: userData?.gender,
        dob: userData?.dob ?? '',
        profileImage: imageFile,
      );

      if (!mounted) return;

      setState(() {
        isUploadingImage = false;
      });

      if (success) {
        // Refresh profile to show updated image
        _fetchUserProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile image updated successfully!")),
          );
        }
      } else {
        _selectedImage = null;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to update profile image")),
          );
        }
      }
    }
  } catch (e) {
    debugPrint('Error picking image: $e');
    if (mounted) {
      setState(() {
        isUploadingImage = false;
        _selectedImage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error picking image")),
      );
    }
  }
}

@override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EF),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.appColor),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _header(context),
                        const SizedBox(height: 16),
                        _topTwoCards(context),
                        const SizedBox(height: 16),
                        _middleList(context),
                        const SizedBox(height: 16),
                        _enterpriseCard(context),
                        const SizedBox(height: 16),
                        logoutCard(context),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // --------------------- HEADER --------------------------
// Replace the _header widget in your ProfileScreen with this fixed version:

Widget _header(BuildContext context) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 50, 16, 24),
    decoration: const BoxDecoration(
      color: Color(0xFFE96D2D),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row - Profile title and Edit button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Profile",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            InkWell(
              onTap: () {
                pushTo(context, UpdateProfileScreen(userData: userData)).then((value) {
                  if (value == true) {
                    _fetchUserProfile();
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Edit Profile",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Profile Information Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        // Profile Image Stack
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                GestureDetector(
                  onTap: isUploadingImage ? null : _pickAndUploadImage,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _selectedImage != null
                          ? Image.file(
                              _selectedImage!,
                              height: 95,
                              width: 85,
                              fit: BoxFit.cover,
                            )
                          : userData?.profileImage != null && userData!.profileImage.isNotEmpty
                              ? Image.network(
                                  ApiUrls.imageProxyUrl(userData!.profileImage),
                                  height: 95,
                                  width: 85,
                                  cacheWidth: 170,
                                  cacheHeight: 190,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const SizedBox(
                                      height: 95,
                                      width: 85,
                                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) => Image.asset(
                                    "assets/profile_image.png",
                                    height: 95,
                                    width: 85,
                                    fit: BoxFit.fill,
                                  ),
                                )
                              : Image.asset(
                                  "assets/profile_image.png",
                                  height: 95,
                                  width: 85,
                                  fit: BoxFit.fill,
                                ),
                    ),
                  ),
                ),
                Container(
                  width: 30,
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: isUploadingImage
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Image.asset("assets/edit_profile.png"),
                )
              ],
            ),
            const SizedBox(width: 16),

            // User Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userData?.fullName ?? "User Name",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Email Row
                  if (userData?.email != null && userData!.email.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.email, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              userData!.email,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(Icons.email, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            "No email",
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),

                  // Phone Row
                  if (userData?.mobileNumber != null && userData!.mobileNumber.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.phone, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            userData!.mobileNumber,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  else
                    const Row(
                      children: [
                        Icon(Icons.phone, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          "No phone",
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ],
                    ),

                  const SizedBox(height: 10),

                  // GST Button / Display
                  if (_userGstin != null && _userGstin!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white),
                      ),
                      child: Text(
                        "GST: $_userGstin",
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    )
                  else
                    InkWell(
                      onTap: () => showServiceSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white),
                        ),
                        child: const Text(
                          "+ Add GST Details",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        )
      ],
    ),
  );
}
    // ---------------------- TWO TOP CARDS -------------------------
    Widget _topTwoCards(BuildContext context) {
      return Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: (){
                pushTo(context, SavedAddressScreen());
              },
              child: _roundedBox(
                icon: "assets/pic_up_location.png",
                title: "Saved Addresses",
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: (){
                pushTo(context, HelpSupportScreen());
              },
              child: _roundedBox(
                icon: "assets/headphones.png",
                title: "Help & Support",
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      );
    }

    Widget _roundedBox({required String icon, required String title}) {
      return Container(
        height: 130,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: HexColor("#FFEDE2"),
                borderRadius: BorderRadius.circular(30),
              ),
              height: 45,
              width: 45,
              child: Image.asset(icon, width: 35,color: Colors.black),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            )
          ],
        ),
      );
    }

    // ------------------------ MIDDLE LIST ------------------------
    Widget _middleList(BuildContext context) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            _listItem(
              icon: "assets/gst.png",
              title: "GST Details",
              trailing: _userGstin != null && _userGstin!.isNotEmpty
                  ? Text(
                      _userGstin!,
                      style: const TextStyle(
                        color: Color(0xFFE96D2D),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : InkWell(
                      onTap: () {
                        showServiceSheet(context);
                      },
                      child: _smallBtn("Add GSTIN"),
                    ),
            ),
            InkWell(
              onTap: ()
              {
                pushTo(context, ReferAndEarnScreen());
              },
              child: _listItem(
                icon: "assets/movezy_reward.png",
                title: "Movezy Rewards",
                trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              ),
            ),
            InkWell(
              onTap: () {
                ShareManager.showShareOptionsSheet(context);
              },
              child: _listItem(
                icon: "assets/refer_and_earn.png",
                title: "Refer and earn 200",
                trailing: _smallBtn("Share"),
              ),
            ),
            // ─── Language Selection ───
            InkWell(
              onTap: () => _showLanguageSheet(context),
              child: _listItem(
                icon: "assets/headphones.png",
                title: "Language",
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_selectedLanguage, style: const TextStyle(color: Color(0xFFE96D2D), fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
            // ─── Terms & Conditions ───
            InkWell(
              onTap: () => _showLegalSheet(context, 'Terms & Conditions', _termsContent),
              child: _listItem(
                icon: "assets/gst.png",
                title: "Terms & Conditions",
                trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              ),
            ),
            // ─── Privacy Policy ───
            InkWell(
              onTap: () => _showLegalSheet(context, 'Privacy Policy', _privacyContent),
              child: _listItem(
                icon: "assets/gst.png",
                title: "Privacy Policy",
                trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              ),
            ),
          ],
        ),
      );
    }

    Widget _listItem({
      required String icon,
      required String title,
      required Widget trailing,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFFFCEDE4),
              child: Container(
                padding: EdgeInsets.all(8),
                  child: Image.asset(icon, width: 30,)
              ),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            trailing,
          ],
        ),
      );
    }

    Widget _smallBtn(String text) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFFE96D2D)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFFE96D2D),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    // ---------------------- ENTERPRISE CARD -------------------------
    Widget _enterpriseCard(BuildContext context) {
      return InkWell(
        onTap: ()
        {
          pushTo(context, PorterEnterpriseScreen());
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFFCEDE4),
                child: Container(
                  padding: EdgeInsets.all(9),
                    child: Image.asset("assets/movezy_enterprise.png")
                ),
              ),
              const SizedBox(width: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Movezy Enterprise",
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Upgrade to Business Solution",
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),

              Spacer(),

              Icon(Icons.arrow_forward_ios_sharp, size: 18,)
            ],
          ),
        ),
      );
    }


  // ---------------------- Logout Card -------------------------
  Widget logoutCard(BuildContext context) {
    return InkWell(
      onTap: () async
      {
        await Prefs.setBool('check_log_in', false);
        await Prefs.setString('mobile_number', "");
        await Prefs.setString('token', "");
        await Prefs.setString('userId', "");
        await Prefs.load();
        Prefs.loadData();

        if (!mounted) return;
        if (mounted) {
          // ignore: use_build_context_synchronously
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (Route<dynamic> route) => false,
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFFCEDE4),
              child: Icon(Icons.logout, size: 21,color: Colors.black,),
            ),
            const SizedBox(width: 16),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Logout",
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ],
            ),

            Spacer(),

            Icon(Icons.arrow_forward_ios_sharp, size: 18,)
          ],
        ),
      ),
    );
  }


  // ─── Language Selection Sheet ───
  void _showLanguageSheet(BuildContext context) {
    final languages = ['English', 'Hindi', 'Tamil', 'Telugu', 'Kannada', 'Bengali', 'Marathi'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Select Language', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                InkWell(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...languages.map((lang) => InkWell(
              onTap: () {
                setState(() => _selectedLanguage = lang);
                Navigator.pop(ctx);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: _selectedLanguage == lang ? const Color(0xFFFFF3EC) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: _selectedLanguage == lang ? Border.all(color: const Color(0xFFFF6200)) : null,
                ),
                child: Row(
                  children: [
                    Text(lang, style: TextStyle(fontSize: 15, fontWeight: _selectedLanguage == lang ? FontWeight.w600 : FontWeight.w400)),
                    const Spacer(),
                    if (_selectedLanguage == lang) const Icon(Icons.check_circle, color: Color(0xFFFF6200), size: 20),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ─── Legal Content Sheet (T&C / Privacy) ───
  void _showLegalSheet(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                InkWell(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Text(content, style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF444444))),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void showServiceSheet(BuildContext context) {
    final gstinController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      HexColor("#FDF6AB"),
                      Colors.white,
                      Colors.white,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  blurRadius: 6,
                                )
                              ],
                            ),
                            child: Icon(Icons.close, size: 20, color: HexColor("#FF6200")),
                          ),
                        ),
                      ],
                    ),

                    Container(
                      height: 100,
                      width: 100,
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: AppColors.appColor, width: 2),
                      ),
                      child: Image.asset('assets/gst.png'),
                    ),

                    SizedBox(height: 20),

                    Text(
                      "Add GSTIN",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),

                    SizedBox(height: 10),

                    Container(
                      margin: EdgeInsets.only(left: 20, right: 20),
                      child: Text(
                        "Get invoices with GSTIN for your future orders and claim Input Tax Credit",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Container(
                      margin: EdgeInsets.only(left: 20, right: 20),
                      decoration: BoxDecoration(
                        border: Border.all(color: HexColor("#B8B8B8")),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextFormField(
                        controller: gstinController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'GSTIN',
                          hintStyle: TextStyle(
                            color: HexColor("#B8B8B8"),
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        keyboardType: TextInputType.text,
                      ),
                    ),

                    const SizedBox(height: 18),

                    ButtonWidget(
                      text: isSubmitting ? "Saving..." : "Got it",
                      margin: EdgeInsets.only(left: 15, right: 15),
                      height: 55,
                      borderRadius: BorderRadius.circular(10),
                      backgroundColor: AppColors.appColor,
                      onTap: isSubmitting
                          ? null
                          : () async {
                              final gstin = gstinController.text.trim();
                              if (gstin.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Please enter your GSTIN')),
                                );
                                return;
                              }
                              setSheetState(() { isSubmitting = true; });
                              final success = await _submitGstin(gstin);
                              setSheetState(() { isSubmitting = false; });
                              if (success) {
                                Navigator.pop(context);
                                setState(() {
                                  _userGstin = gstin.toUpperCase();
                                });
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text('GSTIN saved successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to save GSTIN. Please try again.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  }