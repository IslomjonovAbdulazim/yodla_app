// lib/app/utils/permission_helper.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import 'helpers.dart';

class PermissionHelper {
  /// Request microphone permission with user-friendly flow
  static Future<bool> requestMicrophonePermission({
    bool showRationale = true,
  }) async {
    try {
      // First check current status
      final status = await Permission.microphone.status;

      AppHelpers.logUserAction('microphone_permission_check', {
        'current_status': status.toString(),
      });

      // If already granted, return immediately
      if (status.isGranted) {
        return true;
      }

      // If permanently denied, show settings dialog
      if (status.isPermanentlyDenied) {
        return await _showPermissionDeniedDialog();
      }

      // If denied but not permanently, show rationale first
      if (status.isDenied && showRationale) {
        final shouldRequest = await _showPermissionRationaleDialog();
        if (!shouldRequest) {
          return false;
        }
      }

      // Request permission
      final newStatus = await Permission.microphone.request();

      AppHelpers.logUserAction('microphone_permission_requested', {
        'status': newStatus.toString(),
      });

      // Handle the result
      if (newStatus.isGranted) {
        _showPermissionGrantedSnackbar();
        return true;
      } else if (newStatus.isPermanentlyDenied) {
        return await _showPermissionDeniedDialog();
      } else {
        _showPermissionRequiredSnackbar();
        return false;
      }
    } catch (e) {
      AppHelpers.logUserAction('microphone_permission_error', {
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'Failed to request microphone permission',
        title: 'Permission Error',
      );
      return false;
    }
  }

  /// Show rationale dialog before requesting permission
  static Future<bool> _showPermissionRationaleDialog() async {
    return await Get.dialog<bool>(
      AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.mic,
              color: const Color(0xFF7AB2D3),
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Microphone Access',
              style: GoogleFonts.armata(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To have voice conversations with AI agents, we need access to your microphone.',
              style: GoogleFonts.armata(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              'This allows you to:',
              style: GoogleFonts.armata(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildPermissionFeature(
              icon: Icons.record_voice_over,
              text: 'Speak directly to AI agents',
            ),
            _buildPermissionFeature(
              icon: Icons.chat,
              text: 'Have natural voice conversations',
            ),
            _buildPermissionFeature(
              icon: Icons.security,
              text: 'Audio is processed securely',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info,
                    color: Colors.blue[700],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can still use text chat without microphone access',
                      style: GoogleFonts.armata(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              'Text Only',
              style: GoogleFonts.armata(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7AB2D3),
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Allow Microphone',
              style: GoogleFonts.armata(),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    ) ?? false;
  }

  /// Show dialog when permission is permanently denied
  static Future<bool> _showPermissionDeniedDialog() async {
    return await Get.dialog<bool>(
      AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.mic_off,
              color: Colors.orange[700],
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Microphone Blocked',
              style: GoogleFonts.armata(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Microphone access has been disabled. To enable voice conversations, please follow these steps:',
              style: GoogleFonts.armata(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Platform.isIOS ? 'iOS Instructions:' : 'Android Instructions:',
                    style: GoogleFonts.armata(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...Platform.isIOS ? _iosInstructions() : _androidInstructions(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info,
                    color: Colors.blue[700],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can continue with text-only chat if you prefer',
                      style: GoogleFonts.armata(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              'Continue Text Only',
              style: GoogleFonts.armata(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await openAppSettings();
              Get.back(result: false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Open Settings',
              style: GoogleFonts.armata(),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    ) ?? false;
  }

  static List<Widget> _iosInstructions() {
    return [
      _buildInstructionStep('1.', 'Tap "Open Settings" below'),
      _buildInstructionStep('2.', 'Find and tap your app name'),
      _buildInstructionStep('3.', 'Toggle "Microphone" to ON'),
      _buildInstructionStep('4.', 'Return to the app'),
    ];
  }

  static List<Widget> _androidInstructions() {
    return [
      _buildInstructionStep('1.', 'Tap "Open Settings" below'),
      _buildInstructionStep('2.', 'Tap "Permissions" or "App permissions"'),
      _buildInstructionStep('3.', 'Tap "Microphone"'),
      _buildInstructionStep('4.', 'Select "Allow" or toggle to ON'),
      _buildInstructionStep('5.', 'Return to the app'),
    ];
  }

  static Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: GoogleFonts.armata(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.armata(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildPermissionFeature({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF7AB2D3),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.armata(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  static void _showPermissionGrantedSnackbar() {
    AppHelpers.showSuccessSnackbar(
      'Microphone access granted! You can now use voice features.',
      title: 'Permission Granted',
    );
  }

  static void _showPermissionRequiredSnackbar() {
    AppHelpers.showWarningSnackbar(
      'Microphone access is required for voice conversations. You can still use text chat.',
      title: 'Permission Required',
    );
  }

  /// Check if microphone permission is available
  static Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Show a simple dialog to retry permission
  static Future<bool> showRetryPermissionDialog() async {
    return await Get.dialog<bool>(
      AlertDialog(
        title: Text(
          'Try Again?',
          style: GoogleFonts.armata(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Would you like to try enabling microphone access again?',
          style: GoogleFonts.armata(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              'No, Continue Text Only',
              style: GoogleFonts.armata(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7AB2D3),
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Try Again',
              style: GoogleFonts.armata(),
            ),
          ),
        ],
      ),
    ) ?? false;
  }
}