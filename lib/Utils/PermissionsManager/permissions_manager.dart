import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsManager {
  static const String _tag = 'PermissionsManager';

  // ===================== CHECK PERMISSIONS =====================

  static Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    debugPrint('$_tag - Camera check: ${status.name}');
    return status.isGranted;
  }

  static Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    debugPrint('$_tag - Microphone check: ${status.name}');
    return status.isGranted;
  }

  static Future<bool> checkLocationPermission() async {
    final status = await Permission.location.status;
    debugPrint('$_tag - Location check: ${status.name}');
    return status.isGranted;
  }

  static Future<bool> checkGalleryPermission() async {
    final status = await Permission.photos.status;
    debugPrint('$_tag - Gallery check: ${status.name}');
    return status.isGranted;
  }

  // ===================== REQUEST PERMISSIONS =====================

  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    debugPrint('$_tag - Camera request: ${status.name}');
    return status.isGranted;
  }

  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    debugPrint('$_tag - Microphone request: ${status.name}');
    return status.isGranted;
  }

  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    debugPrint('$_tag - Location request: ${status.name}');
    return status.isGranted;
  }

  static Future<bool> requestGalleryPermission() async {
    final status = await Permission.photos.request();
    debugPrint('$_tag - Gallery request: ${status.name}');
    return status.isGranted;
  }

  // ===================== REQUEST WITH DIALOG =====================

  static Future<bool> requestCameraPermissionWithDialog(
      BuildContext context) async {
    final status = await Permission.camera.status;

    if (status.isGranted) return true;

    if (status.isPermanentlyDenied && context.mounted) {
      _showPermissionDialog(
        context,
        title: 'Camera Permission',
        message:
            'Camera permission is permanently denied. Please enable it in app settings.',
        showSettings: true,
      );
      return false;
    }

    return requestCameraPermission();
  }

  static Future<bool> requestGalleryPermissionWithDialog(
      BuildContext context) async {
    final status = await Permission.photos.status;

    if (status.isGranted) return true;

    if (status.isPermanentlyDenied && context.mounted) {
      _showPermissionDialog(
        context,
        title: 'Gallery Permission',
        message:
            'Gallery permission is permanently denied. Please enable it in app settings.',
        showSettings: true,
      );
      return false;
    }

    final result = await Permission.photos.request();
    return result.isGranted;
  }

  static Future<bool> requestLocationPermissionWithDialog(
      BuildContext context) async {
    final status = await Permission.location.status;

    if (status.isGranted) return true;

    if (status.isPermanentlyDenied && context.mounted) {
      _showPermissionDialog(
        context,
        title: 'Location Permission',
        message:
            'Location permission is permanently denied. Please enable it in app settings.',
        showSettings: true,
      );
      return false;
    }

    final result = await Permission.location.request();
    return result.isGranted;
  }

  // ===================== REQUEST ALL ESSENTIAL =====================

  static Future<bool> requestEssentialPermissions() async {
    final results = await Future.wait([
      Permission.camera.request(),
      Permission.microphone.request(),
      Permission.location.request(),
      Permission.photos.request(),
    ]);

    return results.every((status) => status.isGranted);
  }

  // ===================== APP SETTINGS =====================

  static Future<void> openAppSettingsPage() async {
    await openAppSettings();
    debugPrint('$_tag - Opened app settings');
  }

  // ===================== DIALOG =====================

  static void _showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
    bool showSettings = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          content: Text(message, style: const TextStyle(fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            if (showSettings)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  openAppSettingsPage();
                },
                child: const Text('Open Settings'),
              ),
          ],
        );
      },
    );
  }

  // ===================== IMAGE SOURCE PICKER =====================

  static Future<String?> showImageSourceSheet(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pick from Gallery'),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }
}