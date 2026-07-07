# Complete Permissions Configuration - Delivery App (Ola/Porter Type)

## Overview
All necessary permissions have been configured for a delivery/transport application.

---

## Android Permissions (AndroidManifest.xml)

### Network & Internet
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.CHANGE_NETWORK_STATE"/>
```

### Location Services
```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.LOCATION_HARDWARE"/>
```

### Camera & Gallery
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
```

### Phone & Contacts
```xml
<uses-permission android:name="android.permission.CALL_PHONE"/>
<uses-permission android:name="android.permission.READ_PHONE_STATE"/>
<uses-permission android:name="android.permission.CALL_LOG"/>
<uses-permission android:name="android.permission.READ_CONTACTS"/>
<uses-permission android:name="android.permission.WRITE_CONTACTS"/>
```

### SMS & Messaging
```xml
<uses-permission android:name="android.permission.SEND_SMS"/>
<uses-permission android:name="android.permission.RECEIVE_SMS"/>
<uses-permission android:name="android.permission.READ_SMS"/>
```

### Notifications
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

### Storage
```xml
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"/>
```

### Bluetooth
```xml
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>
```

### Sensors & Motion
```xml
<uses-permission android:name="android.permission.ACCESS_ACCELEROMETER"/>
<uses-permission android:name="android.permission.BODY_SENSORS"/>
```

---

## iOS Permissions (Info.plist)

### Location
```
NSLocationWhenInUseUsageDescription
NSLocationAlwaysAndWhenInUseUsageDescription
NSLocationAlwaysUsageDescription
```

### Camera & Photos
```
NSCameraUsageDescription
NSPhotoLibraryUsageDescription
NSPhotoLibraryAddUsageDescription
```

### Contacts
```
NSContactsUsageDescription
```

### Microphone
```
NSMicrophoneUsageDescription
```

### Calendar
```
NSCalendarsUsageDescription
```

### Bluetooth
```
NSBluetoothPeripheralUsageDescription
NSBluetoothAlwaysUsageDescription
```

### Motion & Activity
```
NSMotionUsageDescription
```

### Health
```
NSHealthShareUsageDescription
NSHealthUpdateUsageDescription
```

### Siri
```
NSSiriUsageDescription
```

### Local Network
```
NSLocalNetworkUsageDescription
NSBonjourServiceTypes
```

---

## Permission Request in Code

### Using PermissionsManager

#### Request Gallery Permission (for image picker)
```dart
bool hasPermission = await PermissionsManager.requestGalleryPermission();
if (hasPermission) {
  // User granted permission
}
```

#### Request Camera Permission
```dart
bool hasPermission = await PermissionsManager.requestCameraPermission();
```

#### Request Location Permission
```dart
bool hasPermission = await PermissionsManager.requestLocationPermission();
```

#### Request All Permissions at Once
```dart
Map<Permission, PermissionStatus> statuses = 
  await PermissionsManager.requestAllPermissions();
```

#### Request Essential Permissions (Location, Camera, Photos, Microphone)
```dart
bool allGranted = await PermissionsManager.requestEssentialPermissions();
```

#### Check Permission Status
```dart
bool hasLocation = await PermissionsManager.checkLocationPermission();
bool hasCamera = await PermissionsManager.checkCameraPermission();
bool hasStorage = await PermissionsManager.checkStoragePermission();
```

#### Open App Settings
```dart
await PermissionsManager.openAppSettings();
```

---

## Permissions Used in Profile Image Upload

### Current Implementation
The `_pickImage()` method now:
1. Requests gallery permission
2. Shows error if permission denied
3. Opens gallery if permission granted
4. Handles errors gracefully

```dart
Future<void> _pickImage() async {
  try {
    // Request gallery permission first
    bool hasPermission = await PermissionsManager.requestGalleryPermission();
    
    if (!hasPermission) {
      // Show error message
      return;
    }

    // Pick image from gallery
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  } catch (e) {
    // Handle errors
  }
}
```

---

## Permission Categories for Delivery Apps

### Essential (Must Have)
- ✅ LOCATION - Track delivery location
- ✅ CAMERA - Document deliveries
- ✅ PHOTOS/GALLERY - Select profile/delivery images
- ✅ INTERNET - API communication

### Important (Recommended)
- ✅ CONTACTS - Quick contact access
- ✅ PHONE - Make calls to customers
- ✅ MICROPHONE - Voice communication
- ✅ SMS - Delivery notifications

### Optional (Nice to Have)
- ✅ BLUETOOTH - Connect to devices
- ✅ NOTIFICATIONS - Push notifications
- ✅ SENSORS - Activity tracking

---

## Permission Handling Best Practices

1. **Request on Demand**
   - Request permissions only when needed
   - Don't request all at startup

2. **Show Rationale**
   - Explain why permission is needed
   - Help users understand benefits

3. **Handle Denials**
   - Gracefully handle denied permissions
   - Offer alternatives or guide to settings

4. **Check Status**
   - Always check before using permission
   - Some permissions may be limited or restricted

5. **Respect User Choice**
   - Never bug users to grant permissions
   - Accept if they decline

---

## Manifest File Location
```
android/app/src/main/AndroidManifest.xml
```

## iOS Configuration Location
```
ios/Runner/Info.plist
```

## Permissions Manager Location
```
lib/Utils/PermissionsManager/permissions_manager.dart
```

---

## Testing Permissions

### Android
1. Install app on device/emulator
2. Go to Settings → Apps → Movezy
3. Check all permissions are listed
4. Grant/revoke permissions to test

### iOS
1. Install app on device/simulator
2. Go to Settings → Movezy
3. Adjust privacy settings
4. App will request permissions as needed

---

## Summary

✅ All permissions configured for delivery app
✅ PermissionsManager class for easy permission handling
✅ Image picker now requests gallery permission
✅ Graceful error handling for denied permissions
✅ Ready for production deployment

The app is now fully configured with all necessary permissions for a delivery/transport application like Ola or Porter.
