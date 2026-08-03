import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movezy_user_app/CommonWidgets/legal_sheet.dart';
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
import 'package:movezy_user_app/Screens/ProfileScreen/update_profile_screen.dart';
import 'package:movezy_user_app/Screens/ReferAndEarn/refer_and_earn_Screen.dart';
import 'package:movezy_user_app/Screens/SavedAddress/saved_address.dart';
import 'package:movezy_user_app/Services/referral_service.dart';
import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';
import 'package:movezy_user_app/Utils/PermissionsManager/permissions_manager.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';
import 'package:share_plus/share_plus.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserData? userData;
  bool isLoading = true;

  /// Why the profile could not be loaded, when it could not be loaded at all.
  /// Null once a profile is on screen.
  String? _profileError;

  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();
  bool isUploadingImage = false;
  String? _userGstin;

  /// The user's REAL referral code, generated and owned by the backend
  /// (GET /user/referral/stats). Empty until it loads — never substituted.
  String _referralCode = '';

  /// Reward amounts as the server defines them (REFERRER_REWARD_AMOUNT /
  /// REFEREE_REWARD_AMOUNT in referral.controller). Null until loaded, and the
  /// UI then omits the figure rather than printing a guess.
  double? _referrerReward;
  double? _refereeReward;
  Future<void>? _referralLoad;

  // Terms/Privacy text and the sheet now live in
  // CommonWidgets/legal_sheet.dart, shared with the login and OTP screens
  // whose links to them were dead.

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _fetchUserGst();
    _fetchReferral();
  }

  /// Load the referral code + reward amounts.
  ///
  /// This screen advertises "Refer and earn" and offers a Share button, but it
  /// never loaded any referral data — so the share message went out with no
  /// code in it and no reward could ever be attributed. The same call also
  /// carries the reward figures, which were hardcoded here.
  /// De-duplicated: Share tapped while the initState load is still in flight
  /// joins that request instead of starting a second one — or, worse, giving up
  /// and reporting a missing code that was about to arrive.
  Future<void> _fetchReferral() =>
      _referralLoad ??=
          _loadReferral().whenComplete(() => _referralLoad = null);

  Future<void> _loadReferral() async {
    try {
      final data = await ReferralService.getReferralStats();
      if (!mounted) return;
      setState(() {
        _referralCode = data.referralCode;
        _referrerReward = data.referrerRewardAmount;
        _refereeReward = data.refereeRewardAmount;
      });
    } catch (e) {
      debugPrint('Referral fetch error: $e');
    }
  }

  /// Share an invite that actually carries the user's referral code.
  ///
  /// Previously this opened ShareManager's generic "share the app" sheet, whose
  /// message is a plain Play Store blurb with no code — the friend had nothing
  /// to enter, so POST /user/referral/apply could never fire and neither side
  /// was ever rewarded. If the code hasn't loaded we retry once and, failing
  /// that, say so rather than sharing a codeless message.
  Future<void> _shareReferral() async {
    if (_referralCode.isEmpty) await _fetchReferral();
    if (!mounted) return;

    if (_referralCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't load your referral code. Please try again."),
        ),
      );
      return;
    }

    // Only mention the friend's bonus when the server told us what it is.
    final bonus = _refereeReward;
    final message = bonus != null
        ? 'Hey! Use my Movezy referral code $_referralCode when you sign up '
            'and get ₹${bonus.toInt()} in your Movezy wallet.'
        : 'Hey! Use my Movezy referral code $_referralCode when you sign up '
            'on Movezy.';

    try {
      // ignore: deprecated_member_use
      await Share.share(message, subject: 'Movezy Referral');
    } catch (e) {
      debugPrint('Referral share error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the share sheet')),
        );
      }
    }
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

/// Load the profile.
///
/// A failure used to be indistinguishable from success here: the service
/// returned null, `userData` stayed null, and the layout below rendered
/// "User Name / No email / No phone" as though those were the account's real
/// details — with no way back short of restarting the app. The service now
/// throws [ProfileApiException] with the server's message, and this records it
/// so the screen can offer a genuine error state.
Future<void> _fetchUserProfile() async {
  try {
    final response = await ProfileApiService().getUserProfile();
    if (!mounted) return;
    setState(() {
      userData = response.data;
      _profileError = null;
      isLoading = false;
    });
  } on ProfileApiException catch (e) {
    if (!mounted) return;
    setState(() {
      isLoading = false;
      // A background refresh (after a photo upload or an edit) must not replace
      // a profile that is already on screen with an error page, so the error
      // state is only raised when there is nothing to fall back on.
      if (userData == null) _profileError = e.message;
    });
  } catch (e) {
    debugPrint('Error fetching profile: $e');
    if (!mounted) return;
    setState(() {
      isLoading = false;
      if (userData == null) {
        _profileError = 'Something went wrong while loading your profile.';
      }
    });
  }
}

/// Re-run every request this screen depends on, from the error state's Retry.
void _reloadProfile() {
  setState(() {
    isLoading = true;
    _profileError = null;
  });
  _fetchUserProfile();
  _fetchUserGst();
  _fetchReferral();
}

/// Upload ONLY the profile photo.
///
/// This used to go through UpdateProfileApiService.updateUserProfile, which
/// rejects an empty fullName before it sends anything
/// (update_profile_api_service.dart:88 — "Full name is required"). Every fresh
/// signup has no name yet, so changing the photo was impossible for exactly the
/// users most likely to try. That service also puts `fullName` in the body
/// unconditionally, so simply dropping the guard would have posted an empty
/// name and blanked it server-side.
///
/// PUT /user/profile whitelists each field independently (user.controller
/// editUser) and takes the file from `req.files`, so the image alone is a
/// complete, valid request.
Future<bool> _uploadProfileImage(File image) async {
  try {
    final token = Prefs.getString('token');
    if (token.isEmpty) return false;

    final request =
        http.MultipartRequest('PUT', Uri.parse(ApiUrls.userProfileUrl))
          ..headers['Authorization'] = 'Bearer $token'
          ..files.add(
              await http.MultipartFile.fromPath('profileImage', image.path));

    final response = await http.Response.fromStream(
      await request.send().timeout(const Duration(seconds: 30)),
    );

    if (response.statusCode != 200) {
      debugPrint('Profile image upload failed: '
          '${response.statusCode} ${response.body}');
      return false;
    }

    // Backend envelope is { code, message, data }; code 1 means success.
    final body = jsonDecode(response.body);
    return body is Map && (body['code'] ?? 1) == 1;
  } catch (e) {
    // Swallowed here so the caller reports an upload failure rather than the
    // enclosing handler's "Error picking image", which blames the wrong step.
    debugPrint('Profile image upload error: $e');
    return false;
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

      // Upload the image on its own — no name/email/dob ride along, so this
      // works on an account that has none of them yet.
      bool success = await _uploadProfileImage(imageFile);

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
        // Was a bare assignment outside setState, so a failed upload left the
        // picked photo on screen looking as though it had been saved.
        setState(() => _selectedImage = null);
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
          : userData == null
          ? _profileLoadErrorState(context)
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

  // --------------------- LOAD ERROR --------------------------

  /// Shown when the profile could not be loaded at all.
  ///
  /// Previously the screen fell through to its normal layout with `userData`
  /// null, so a failed request looked exactly like an account with nothing
  /// filled in and there was no way to retry.
  Widget _profileLoadErrorState(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 56, color: Colors.black26),
              const SizedBox(height: 16),
              const Text(
                "Couldn't load your profile",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                _profileError ?? 'Please try again.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _reloadProfile,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.appColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // An expired or revoked token fails every retry, and the logout
              // row lives in the layout this state replaces — without this the
              // only way out would be reinstalling the app.
              TextButton(
                onPressed: () => _logout(context),
                child: const Text(
                  'Log out',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
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
                  // This branch only renders once a profile has actually
                  // loaded, so the old `?? "User Name"` fallback was both dead
                  // (userData is non-null here) and wrong for the case it did
                  // hit — an account with no name yet rendered an empty line.
                  Text(
                    (userData?.fullName ?? '').isNotEmpty
                        ? userData!.fullName
                        : "Add your name",
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
              // Flexible: trailing is dropped straight into _listItem's Row as a
              // non-flex child, so this server-driven GSTIN got unbounded width —
              // and having no spaces it could not soft-wrap either.
              trailing: _userGstin != null && _userGstin!.isNotEmpty
                  ? Flexible(
                      child: Text(
                        _userGstin!,
                        style: const TextStyle(
                          color: Color(0xFFE96D2D),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
              onTap: _shareReferral,
              child: _listItem(
                icon: "assets/refer_and_earn.png",
                // The amount now comes from the server
                // (referrerRewardAmount on /user/referral/stats) instead of
                // being written into the label. It was hardcoded — first as
                // "₹200", then as "₹100" to match the constant — so any change
                // to the programme silently made this screen lie. Until it
                // loads, the row simply omits the figure.
                title: _referrerReward != null
                    ? "Refer and earn ₹${_referrerReward!.toInt()}"
                    : "Refer and earn",
                trailing: _smallBtn("Share"),
              ),
            ),
            // The language selector was removed. It offered English, Hindi,
            // Tamil, Telugu, Kannada, Bengali and Marathi, but the user app has
            // no localization at all — picking one only repainted the label, so
            // it promised six languages the app cannot speak. Restore this once
            // the strings are actually translated.
            // ─── Terms & Conditions ───
            InkWell(
              onTap: () => showLegalSheet(context, 'Terms & Conditions', LegalText.terms),
              child: _listItem(
                icon: "assets/gst.png",
                title: "Terms & Conditions",
                trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              ),
            ),
            // ─── Privacy Policy ───
            InkWell(
              onTap: () => showLegalSheet(context, 'Privacy Policy', LegalText.privacy),
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

              // Expanded: as a bare Row child this Column got unbounded width, so
              // the 28-char subtitle laid out at its intrinsic width and could
              // never ellipsize. The Spacer goes with it — Expanded already takes
              // the slack that used to push the chevron to the right edge.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Movezy Enterprise",
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Upgrade to Business Solution",
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              Icon(Icons.arrow_forward_ios_sharp, size: 18,)
            ],
          ),
        ),
      );
    }


  // ---------------------- Logout -------------------------

  /// Clear the session and return to login. Extracted from the logout row so
  /// the profile-load error state can offer the same escape hatch.
  Future<void> _logout(BuildContext context) async {
    await Prefs.setBool('check_log_in', false);
    await Prefs.setString('mobile_number', "");
    await Prefs.setString('token', "");
    await Prefs.setString('userId', "");
    await Prefs.load();
    Prefs.loadData();

    if (!mounted) return;
    // ignore: use_build_context_synchronously
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Widget logoutCard(BuildContext context) {
    return InkWell(
      onTap: () => _logout(context),
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




  // ─── Legal Content Sheet (T&C / Privacy) ───


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
                        // Same rules as the Review Booking GSTIN sheet
                        // (review_booking_screen.dart `_showGstSheet`): exactly
                        // 15 alphanumeric characters. This sheet used to accept
                        // any non-empty string, so the two entry points for the
                        // same field disagreed about what a GSTIN is.
                        maxLength: 15,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Za-z0-9]'),
                          ),
                        ],
                        decoration: InputDecoration(
                          counterText: '',
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
                              if (gstin.length != 15) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please enter a valid 15-character GSTIN',
                                    ),
                                  ),
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