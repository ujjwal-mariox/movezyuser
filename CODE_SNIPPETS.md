# Code Snippets - User Profile Integration

Quick reference for all code implementations.

## 1. API URLs Configuration

**File:** `lib/ApiUrls/api_urls.dart`

```dart
class ApiUrls {
  static String baseUrlApi = "http://103.194.228.68:9050/v1/api";

  static String loginUrl = "$baseUrlApi/auth/login";

  static String otpUrlVerify = "$baseUrlApi/auth/verifyOtp";

  static String userProfileUrl = "$baseUrlApi/user/profile";
}
```

---

## 2. User Profile Response Model

**File:** `lib/Screens/ProfileScreen/Model/user_profile_response.dart`

```dart
import 'dart:convert';

UserProfileResponse userProfileResponseFromJson(String str) => 
  UserProfileResponse.fromJson(json.decode(str));

class UserProfileResponse {
  int code;
  String message;
  UserData data;

  UserProfileResponse({
    required this.code,
    required this.message,
    required this.data,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) => 
    UserProfileResponse(
      code: json["code"],
      message: json["message"],
      data: UserData.fromJson(json["data"]),
    );
}

class UserData {
  String id;
  String fullName;
  String email;
  String profileImages;
  String gender;
  String dob;
  String countryCode;
  String mobileNumber;
  bool isActive;
  bool isDeleted;
  bool notificationAllowed;
  String createdAt;
  String updatedAt;
  int v;
  String profileImage;

  UserData({
    required this.id,
    required this.fullName,
    required this.email,
    required this.profileImages,
    required this.gender,
    required this.dob,
    required this.countryCode,
    required this.mobileNumber,
    required this.isActive,
    required this.isDeleted,
    required this.notificationAllowed,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
    required this.profileImage,
  });

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
    id: json["_id"] ?? "",
    fullName: json["fullName"] ?? "",
    email: json["email"] ?? "",
    profileImages: json["profileImages"] ?? "",
    gender: json["gender"] ?? "",
    dob: json["dob"] ?? "",
    countryCode: json["countryCode"] ?? "+91",
    mobileNumber: json["mobileNumber"] ?? "",
    isActive: json["isActive"] ?? false,
    isDeleted: json["isDeleted"] ?? false,
    notificationAllowed: json["notificationAllowed"] ?? false,
    createdAt: json["createdAt"] ?? "",
    updatedAt: json["updatedAt"] ?? "",
    v: json["__v"] ?? 0,
    profileImage: json["profileImage"] ?? "",
  );
}
```

---

## 3. Profile API Service

**File:** `lib/Screens/ProfileScreen/ProfileApiService/profile_api_service.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/Screens/ProfileScreen/Model/user_profile_response.dart';
import 'package:movezy_user_app/Utils/CustomToast/custome_toast.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';
import 'package:http/http.dart' as http;

class ProfileApiService {
  Future<UserProfileResponse?> getUserProfile(BuildContext context) async {
    try {
      // Get the token from shared preferences
      String token = Prefs.getString('token');

      var headers = {
        'Content-Type': 'application/json',
      };

      // Add authorization header if token exists
      if (token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      var response = await http.get(
        Uri.parse(ApiUrls.userProfileUrl),
        headers: headers,
      );

      print("Profile API Response: ${response.body}");
      print("Profile API Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        var profileData = userProfileResponseFromJson(response.body);
        return profileData;
      } else {
        var profileData = userProfileResponseFromJson(response.body);
        showCustomToast(context, profileData.message);
        return null;
      }
    } catch (e) {
      print("Profile API Error: $e");
      showCustomToast(context, "Error fetching profile data");
      return null;
    }
  }
}
```

---

## 4. OTP API Service Updates

**File:** `lib/Screens/OtpScreen/OtpApiService/otp_api_service.dart`

Key changes:

```dart
// Import the new screen
import 'package:movezy_user_app/Screens/LocationPermissionScreen/location_permission_screen.dart';

// In the otpVerifyApi method, after successful verification:
if(response.statusCode == 200) {
  // Save user data
  Prefs.setBool('check_log_in', true);
  Prefs.setString('mobile_number', mobileNumber);
  
  // Save token from response
  if(dataT.data != null && dataT.data!.token != null) {
    Prefs.setString('token', dataT.data!.token!);
    if(dataT.data!.userId != null) {
      Prefs.setString('userId', dataT.data!.userId!);
    }
  }
  
  await Prefs.load();
  Prefs.loadData();

  // Navigate to LocationPermissionScreen instead of Dashboard
  pushTo(context, LocationPermissionScreen());
}
```

---

## 5. Profile Screen Implementation

**File:** `lib/Screens/ProfileScreen/profile_screen.dart`

Key changes - Full State Implementation:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movezy_user_app/Screens/ProfileScreen/Model/user_profile_response.dart';
import 'package:movezy_user_app/Screens/ProfileScreen/ProfileApiService/profile_api_service.dart';
import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserData? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      var response = await ProfileApiService().getUserProfile(context);
      if (response != null) {
        setState(() {
          userData = response.data;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching profile: $e");
      setState(() {
        isLoading = false;
      });
    }
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
          : SingleChildScrollView(
              child: Column(
                children: [
                  _header(context),
                  // ... rest of the widgets
                ],
              ),
            ),
    );
  }

  // Header with dynamic data
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
          Row(
            children: [
              const Text(
                "Profile",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  // TODO: Navigate to EditProfileScreen
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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
          // Profile Row with dynamic data
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: userData?.profileImage != null &&
                          userData!.profileImage.isNotEmpty
                          ? Image.network(
                              userData!.profileImage,
                              height: 95,
                              width: 85,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  "assets/profile_image.png",
                                  height: 95,
                                  width: 85,
                                  fit: BoxFit.fill,
                                );
                              },
                            )
                          : Image.asset(
                              "assets/profile_image.png",
                              height: 95,
                              width: 85,
                              fit: BoxFit.fill,
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
                    child: Image.asset("assets/edit_profile.png"),
                  )
                ],
              ),
              const SizedBox(width: 16),
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
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (userData?.email != null &&
                            userData!.email.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.email,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  userData!.email,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        else
                          const Row(
                            children: [
                              Icon(Icons.email,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text(
                                "No email",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(width: 10),
                        if (userData?.mobileNumber != null &&
                            userData!.mobileNumber.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.phone,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                userData!.mobileNumber,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          )
                        else
                          const Row(
                            children: [
                              Icon(Icons.phone,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text(
                                "No phone",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white),
                      ),
                      child: const Text(
                        "+ Add GST Details",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
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
}
```

---

## 6. To Add More Fields

Example: Add Gender Display

```dart
// In the profile header Column, add after mobileNumber:
const SizedBox(height: 4),
if (userData?.gender != null && userData!.gender.isNotEmpty)
  Text(
    "Gender: ${userData!.gender}",
    style: const TextStyle(
      color: Colors.white,
      fontSize: 10,
    ),
  )
```

---

## 7. To Add a Refresh Button

```dart
// In the ProfileScreen build method, wrap the body:
body: RefreshIndicator(
  onRefresh: () async {
    await _fetchUserProfile();
  },
  child: isLoading
      ? Center(child: CircularProgressIndicator())
      : SingleChildScrollView(...),
)
```

---

## 8. To Add Profile Details Card

```dart
Widget _profileDetailsCard() {
  if (userData == null) return const SizedBox.shrink();
  
  return Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          blurRadius: 8,
        )
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Personal Details",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(),
        _detailRow("Gender", userData!.gender),
        _detailRow("Date of Birth", userData!.dob),
        _detailRow("Country Code", userData!.countryCode),
      ],
    ),
  );
}

Widget _detailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value.isEmpty ? "-" : value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
```

---

## 9. Complete Imports for Profile Screen

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/CommonWidgets/button_widget.dart';
import 'package:movezy_user_app/Screens/HelpSupportScreen/help_support_screen.dart';
import 'package:movezy_user_app/Screens/LoginScreen/login_screen.dart';
import 'package:movezy_user_app/Screens/PorterEnterpriseScreen/porter_enterprise_screen.dart';
import 'package:movezy_user_app/Screens/ProfileScreen/Model/user_profile_response.dart';
import 'package:movezy_user_app/Screens/ProfileScreen/ProfileApiService/profile_api_service.dart';
import 'package:movezy_user_app/Screens/ReferAndEarn/refer_and_earn_Screen.dart';
import 'package:movezy_user_app/Screens/SavedAddress/saved_address.dart';
import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';
```

---

These snippets provide everything needed to understand and extend the profile integration!
