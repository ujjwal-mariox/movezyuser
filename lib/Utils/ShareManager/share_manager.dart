import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareManager {
  // App details
  static const String _appName = 'Movezy';
  static const String _appDownloadUrl = 'https://play.google.com/store/apps/details?id=com.movezy.app';
  static const String _appDescription =
      'Download Movezy - Your trusted delivery partner for fast, reliable, and affordable delivery services!';
  static const String _shareMessage =
      'Check out Movezy - Fast, Reliable & Affordable Delivery! Download now: $_appDownloadUrl';

  /// Show native share dialog with multiple platform options
  static Future<void> shareApp(BuildContext context) async {
    try {
      // ignore: deprecated_member_use
      await Share.share(
        _shareMessage,
        subject: _appName,
      );
    } catch (e) {
      debugPrint('Error sharing app: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error sharing app')),
        );
      }
    }
  }

  /// Share via WhatsApp
  static Future<void> shareViaWhatsApp(BuildContext context) async {
    try {
      final whatsappUrl =
          'https://wa.me/?text=${Uri.encodeComponent(_shareMessage)}';
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl));
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('WhatsApp is not installed'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error sharing via WhatsApp: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error sharing via WhatsApp')),
        );
      }
    }
  }

  /// Share via Email
  static Future<void> shareViaEmail(BuildContext context) async {
    try {
      final emailUrl =
          'mailto:?subject=${Uri.encodeComponent(_appName)}&body=${Uri.encodeComponent(_shareMessage)}';
      if (await canLaunchUrl(Uri.parse(emailUrl))) {
        await launchUrl(Uri.parse(emailUrl));
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No email app available'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error sharing via Email: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error sharing via Email')),
        );
      }
    }
  }

  /// Share via SMS
  static Future<void> shareViaSMS(BuildContext context) async {
    try {
      final smsUrl = 'sms:?body=${Uri.encodeComponent(_shareMessage)}';
      if (await canLaunchUrl(Uri.parse(smsUrl))) {
        await launchUrl(Uri.parse(smsUrl));
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('SMS app is not available'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error sharing via SMS: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error sharing via SMS')),
        );
      }
    }
  }

  /// Share via Telegram
  static Future<void> shareViaTelegram(BuildContext context) async {
    try {
      final telegramUrl =
          'https://t.me/share/url?url=${Uri.encodeComponent(_appDownloadUrl)}&text=${Uri.encodeComponent(_appDescription)}';
      if (await canLaunchUrl(Uri.parse(telegramUrl))) {
        await launchUrl(Uri.parse(telegramUrl));
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Telegram is not installed'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error sharing via Telegram: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error sharing via Telegram')),
        );
      }
    }
  }

  /// Share via Facebook
  static Future<void> shareViaFacebook(BuildContext context) async {
    try {
      final facebookUrl =
          'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(_appDownloadUrl)}';
      if (await canLaunchUrl(Uri.parse(facebookUrl))) {
        await launchUrl(Uri.parse(facebookUrl));
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Facebook is not installed'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error sharing via Facebook: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error sharing via Facebook')),
        );
      }
    }
  }

  /// Share via Twitter
  static Future<void> shareViaTwitter(BuildContext context) async {
    try {
      final twitterUrl =
          'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(_shareMessage)}&url=${Uri.encodeComponent(_appDownloadUrl)}';
      if (await canLaunchUrl(Uri.parse(twitterUrl))) {
        await launchUrl(Uri.parse(twitterUrl));
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Twitter is not installed'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error sharing via Twitter: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error sharing via Twitter')),
        );
      }
    }
  }

  /// Share via LinkedIn
  static Future<void> shareViaLinkedIn(BuildContext context) async {
    try {
      final linkedInUrl =
          'https://www.linkedin.com/sharing/share-offsite/?url=${Uri.encodeComponent(_appDownloadUrl)}';
      if (await canLaunchUrl(Uri.parse(linkedInUrl))) {
        await launchUrl(Uri.parse(linkedInUrl));
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('LinkedIn is not available'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error sharing via LinkedIn: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error sharing via LinkedIn')),
        );
      }
    }
  }

  /// Show custom share options bottom sheet
  static void showShareOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Share Movezy',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, size: 24),
                    ),
                  ],
                ),
              ),
              const Divider(),
              
              // Share options grid
              Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildShareOption(
                      context,
                      icon: Icons.share,
                      label: 'Share',
                      onTap: () {
                        Navigator.pop(context);
                        shareApp(context);
                      },
                    ),
                    _buildShareOption(
                      context,
                      icon: Icons.chat,
                      label: 'WhatsApp',
                      onTap: () {
                        Navigator.pop(context);
                        shareViaWhatsApp(context);
                      },
                    ),
                    _buildShareOption(
                      context,
                      icon: Icons.email,
                      label: 'Email',
                      onTap: () {
                        Navigator.pop(context);
                        shareViaEmail(context);
                      },
                    ),
                    _buildShareOption(
                      context,
                      icon: Icons.sms,
                      label: 'SMS',
                      onTap: () {
                        Navigator.pop(context);
                        shareViaSMS(context);
                      },
                    ),
                    _buildShareOption(
                      context,
                      icon: Icons.send,
                      label: 'Telegram',
                      onTap: () {
                        Navigator.pop(context);
                        shareViaTelegram(context);
                      },
                    ),
                    _buildShareOption(
                      context,
                      icon: Icons.people,
                      label: 'Facebook',
                      onTap: () {
                        Navigator.pop(context);
                        shareViaFacebook(context);
                      },
                    ),
                    _buildShareOption(
                      context,
                      icon: Icons.campaign,
                      label: 'Twitter',
                      onTap: () {
                        Navigator.pop(context);
                        shareViaTwitter(context);
                      },
                    ),
                    _buildShareOption(
                      context,
                      icon: Icons.business,
                      label: 'LinkedIn',
                      onTap: () {
                        Navigator.pop(context);
                        shareViaLinkedIn(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build individual share option widget
  static Widget _buildShareOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFE96D2D).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFE96D2D),
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
