// lib/utils/whatsapp_helper.dart
// NEW FILE - Helper for WhatsApp functionality

import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class WhatsAppHelper {
  /// Opens WhatsApp to call a specific phone number
  /// phoneNumber should be in format: +94771234567 or 0771234567
  static Future<void> makeWhatsAppCall({
    required BuildContext context,
    required String phoneNumber,
    required String workerName,
  }) async {
    try {
      // Clean the phone number - remove spaces, dashes, etc.
      String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      // If number starts with 0, replace with +94 (Sri Lanka code)
      if (cleanNumber.startsWith('0')) {
        cleanNumber = '+94${cleanNumber.substring(1)}';
      }

      // If number doesn't start with +, add +94
      if (!cleanNumber.startsWith('+')) {
        cleanNumber = '+94$cleanNumber';
      }

      // WhatsApp call URL format
      final Uri whatsappUri = Uri.parse('https://wa.me/$cleanNumber');

      // Try to launch WhatsApp
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(
          whatsappUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Show error if WhatsApp cannot be opened
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Could not open WhatsApp. Please make sure WhatsApp is installed.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Error opening WhatsApp: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening WhatsApp: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Shows a confirmation dialog before calling via WhatsApp
  static Future<void> showCallConfirmationDialog({
    required BuildContext context,
    required String phoneNumber,
    required String workerName,
  }) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.phone, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Expanded(child: Text('Call via WhatsApp')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Do you want to call $workerName via WhatsApp?'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone, color: Colors.grey[700], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      phoneNumber,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'This will open WhatsApp and connect you with the worker.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: Icon(Icons.phone, size: 18),
            label: Text('Call Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await makeWhatsAppCall(
        context: context,
        phoneNumber: phoneNumber,
        workerName: workerName,
      );
    }
  }
}
