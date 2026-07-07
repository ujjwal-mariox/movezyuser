# Share Manager Documentation

The ShareManager utility provides comprehensive app sharing functionality across multiple platforms.

## Features

- 📱 **Native Share Dialog** - Uses the system's native share sheet
- 💬 **WhatsApp** - Direct WhatsApp sharing
- 📧 **Email** - Email sharing with pre-filled subject and message
- 📲 **SMS** - SMS sharing with pre-filled message
- ✈️ **Telegram** - Telegram sharing with deep links
- 👥 **Facebook** - Facebook sharing
- 🐦 **Twitter** - Twitter/X sharing with hashtags support
- 💼 **LinkedIn** - LinkedIn sharing
- 🎨 **Custom UI** - Beautiful bottom sheet with all sharing options

## Usage

### 1. Simple Native Share (Recommended)

```dart
import 'package:movezy_user_app/Utils/ShareManager/share_manager.dart';

// Open native share dialog with installed apps
ShareManager.shareApp(context);
```

### 2. Share via Specific Platform

```dart
// Share via WhatsApp
ShareManager.shareViaWhatsApp(context);

// Share via Email
ShareManager.shareViaEmail(context);

// Share via SMS
ShareManager.shareViaSMS(context);

// Share via Telegram
ShareManager.shareViaTelegram(context);

// Share via Facebook
ShareManager.shareViaFacebook(context);

// Share via Twitter
ShareManager.shareViaTwitter(context);

// Share via LinkedIn
ShareManager.shareViaLinkedIn(context);
```

### 3. Show Custom Share Options Sheet

```dart
// Shows beautiful bottom sheet with all sharing options
ShareManager.showShareOptionsSheet(context);
```

## Implementation Examples

### In ProfileScreen (Refer and Earn)

```dart
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
```

### In a Custom Button

```dart
ElevatedButton(
  onPressed: () => ShareManager.shareApp(context),
  child: const Text('Share App'),
)
```

### In FAB

```dart
FloatingActionButton(
  onPressed: () => ShareManager.showShareOptionsSheet(context),
  child: const Icon(Icons.share),
)
```

## Shared Content

All sharing methods share:

- **App Name:** Movezy
- **Message:** "Check out Movezy - Fast, Reliable & Affordable Delivery! Download now: [Play Store Link]"
- **Download URL:** https://play.google.com/store/apps/details?id=com.movezy.app

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Native Share | ✅ | Works on all platforms with installed apps |
| WhatsApp | ✅ | Web version supported |
| Email | ✅ | Uses mailto links |
| SMS | ✅ | Uses sms: protocol |
| Telegram | ✅ | Web version supported |
| Facebook | ✅ | Web version supported |
| Twitter | ✅ | Web version supported |
| LinkedIn | ✅ | Web version supported |

## Customization

To customize the share message or app details, edit the constants in ShareManager:

```dart
static const String _appName = 'Movezy';
static const String _appDownloadUrl = 'https://play.google.com/store/apps/details?id=com.movezy.app';
static const String _appDescription = '...';
static const String _shareMessage = '...';
```

## Error Handling

All methods include built-in error handling with user-friendly SnackBar messages:

- "WhatsApp is not installed"
- "No email app available"
- "SMS app is not available"
- "Telegram is not installed"
- "Facebook is not installed"
- "Twitter is not installed"
- "LinkedIn is not available"

## Dependencies

Required packages (already added to pubspec.yaml):

- `share_plus: ^11.0.0` - For native share dialog
- `url_launcher: ^6.2.4` - For opening URLs and deep links

## UI/UX

The custom share options sheet features:

- **Grid layout** with 8 sharing options
- **Color-coded icons** (Orange theme)
- **Clean header** with close button
- **Responsive design** for different screen sizes
- **Smooth animations**
- **Haptic feedback** compatible

## Permissions

No additional permissions required beyond what's already in AndroidManifest.xml and Info.plist.

## Best Practices

1. Use `ShareManager.shareApp(context)` for most cases (shows all installed apps)
2. Use `ShareManager.showShareOptionsSheet(context)` for a beautiful custom UI
3. Always pass `BuildContext` to handle errors properly
4. Check if widget is mounted before showing SnackBars

## Future Enhancements

Possible additions:
- Share with custom message per platform
- Track sharing analytics
- Generate referral codes for "Refer and Earn"
- Share to multiple contacts at once
- Custom share UI branding
