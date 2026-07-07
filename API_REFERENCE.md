# User Profile API - Complete Reference

## API Endpoint
```
GET http://103.194.228.68:9050/v1/api/user/profile
```

## Request Headers
```
Content-Type: application/json
Authorization: Bearer {token}
```

## Success Response (Code: 200)
```json
{
    "code": 1,
    "message": "success",
    "data": {
        "_id": "695010075580b40ab760db08",
        "fullName": "test",
        "email": "test@gmail.com",
        "profileImages": "",
        "gender": "Male",
        "dob": "23-12-1999",
        "countryCode": "+91",
        "mobileNumber": "7986341518",
        "isActive": true,
        "isDeleted": false,
        "notificationAllowed": true,
        "createdAt": "2025-12-27T16:57:43.491Z",
        "updatedAt": "2025-12-28T00:50:25.526Z",
        "__v": 0,
        "profileImage": "https://bank-ster-dev.s3.ap-south-1.amazonaws.com/1766883024763_f33333a0c19a5dd7e5ee2ce1745e708f77b9b01c.png"
    }
}
```

## Error Response (Code: 4xx)
```json
{
    "code": 0,
    "message": "Error message here",
    "data": null
}
```

## Data Dictionary

| Field | Type | Description | Current Usage |
|-------|------|-------------|---|
| _id | String | User's unique MongoDB ID | Stored as userId |
| fullName | String | User's full name | ✅ Displayed in profile header |
| email | String | User's email address | ✅ Displayed in profile header |
| profileImages | String | Deprecated field (use profileImage) | ❌ Not used |
| gender | String | User's gender (Male/Female/Other) | 🔲 Available but not displayed |
| dob | String | Date of birth (format: DD-MM-YYYY) | 🔲 Available but not displayed |
| countryCode | String | Country code (e.g., +91 for India) | Stored with mobile |
| mobileNumber | String | User's phone number | ✅ Displayed in profile header |
| isActive | Boolean | Account is active/inactive | 🔲 Available but not displayed |
| isDeleted | Boolean | Account is deleted/active | 🔲 Available but not displayed |
| notificationAllowed | Boolean | User opted-in for notifications | 🔲 Available but not displayed |
| createdAt | String | Account creation timestamp | 🔲 Available but not displayed |
| updatedAt | String | Last profile update timestamp | 🔲 Available but not displayed |
| __v | Integer | MongoDB version field | ❌ Not used |
| profileImage | String | User's profile image URL (S3) | ✅ Displayed in profile header |

## How to Add More Fields to UI

### Example 1: Display Gender
In `profile_screen.dart`, add to the profile header:
```dart
const SizedBox(height: 6),
Text(
  "Gender: ${userData?.gender ?? 'Not specified'}",
  style: const TextStyle(color: Colors.white, fontSize: 12),
),
```

### Example 2: Display Date of Birth
```dart
const SizedBox(height: 4),
Text(
  "DOB: ${userData?.dob ?? 'Not provided'}",
  style: const TextStyle(color: Colors.white, fontSize: 12),
),
```

### Example 3: Display Account Status
```dart
const SizedBox(height: 4),
Text(
  "Status: ${userData?.isActive == true ? 'Active' : 'Inactive'}",
  style: const TextStyle(color: Colors.white, fontSize: 12),
),
```

## How to Create a Detailed Profile Card

```dart
// Add a new widget for extended profile details
Widget _detailedProfileCard() {
  if (userData == null) return SizedBox.shrink();
  
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Personal Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const Divider(),
        _detailRow("Gender", userData!.gender),
        _detailRow("Date of Birth", userData!.dob),
        _detailRow("Country", userData!.countryCode),
        _detailRow("Account Created", userData!.createdAt),
        _detailRow("Last Updated", userData!.updatedAt),
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
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
```

## API Service Methods Available

### Get User Profile
```dart
Future<UserProfileResponse?> getUserProfile(BuildContext context)
```
- Returns: `UserProfileResponse?` (nullable)
- Handles: Errors with toast notifications
- Token: Automatically retrieved from SharedPreferences

### Example Usage
```dart
var response = await ProfileApiService().getUserProfile(context);
if (response != null && response.code == 1) {
  print("User name: ${response.data.fullName}");
  // Use response.data here
}
```

## SharedPreferences Keys Used

| Key | Set By | Used By | Value |
|-----|--------|--------|-------|
| `check_log_in` | OTP API | App startup/navigation | boolean |
| `mobile_number` | OTP API | Profile, etc. | String |
| `token` | OTP API | Profile API, All auth calls | String (Bearer token) |
| `userId` | OTP API | Future user-specific calls | String (MongoDB ID) |

## Future Enhancements

1. **Profile Update Endpoint**
   - PATCH `/user/profile` - Update user details
   - PUT `/user/profile/image` - Upload new profile picture

2. **Profile Fields to Add**
   - Address (pickup/delivery)
   - Business details (if enterprise user)
   - Payment methods
   - Preferences
   - Emergency contacts

3. **Caching Strategy**
   - Cache profile data in SQLite
   - Refresh on app startup
   - Manual refresh button
   - Periodic background refresh

4. **Image Handling**
   - Profile picture upload
   - Compress before upload
   - Crop/edit before save
   - Cache downloaded images

## Troubleshooting

### Profile Data Not Showing
1. Check token is saved in SharedPreferences
2. Check API endpoint URL is correct
3. Check network connectivity
4. Check server logs for auth errors

### Image Not Loading
1. Check S3 URL is accessible
2. Check HTTPS is enabled
3. Check image permissions
4. Verify URL format

### Empty Fields
1. Check API response - field might be missing
2. App defaults to fallback text (e.g., "No email")
3. No error is thrown - graceful degradation
4. Check SharedPreferences for data

## Code Example: Complete Profile Fetch & Display

```dart
import 'package:flutter/material.dart';
import 'package:movezy_user_app/Screens/ProfileScreen/Model/user_profile_response.dart';
import 'package:movezy_user_app/Screens/ProfileScreen/ProfileApiService/profile_api_service.dart';

class MyProfileScreen extends StatefulWidget {
  @override
  _MyProfileScreenState createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  UserData? userData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      var response = await ProfileApiService().getUserProfile(context);
      
      setState(() {
        if (response != null && response.code == 1) {
          userData = response.data;
          errorMessage = null;
        } else {
          errorMessage = response?.message ?? "Failed to load profile";
          userData = null;
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(child: Text(errorMessage!));
    }

    if (userData == null) {
      return Center(child: Text("No profile data"));
    }

    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: ListView(
        children: [
          Text("Name: ${userData!.fullName}"),
          Text("Email: ${userData!.email}"),
          Text("Phone: ${userData!.mobileNumber}"),
          Text("Gender: ${userData!.gender}"),
          Text("DOB: ${userData!.dob}"),
        ],
      ),
    );
  }
}
```
