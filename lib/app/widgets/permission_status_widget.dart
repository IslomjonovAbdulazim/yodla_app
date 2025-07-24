// lib/app/widgets/permission_status_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/permission_helper.dart';

class PermissionStatusWidget extends StatelessWidget {
  final bool isTextOnlyMode;
  final VoidCallback? onPermissionGranted;

  const PermissionStatusWidget({
    super.key,
    required this.isTextOnlyMode,
    this.onPermissionGranted,
  });

  @override
  Widget build(BuildContext context) {
    if (!isTextOnlyMode) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.mic_off,
                color: Colors.orange[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Text Mode Active',
                  style: GoogleFonts.armata(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Voice recording is disabled. You can still chat by typing messages!',
            style: GoogleFonts.armata(
              color: Colors.orange[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _retryPermission(),
                  icon: Icon(
                    Icons.mic,
                    size: 16,
                    color: Colors.orange[700],
                  ),
                  label: Text(
                    'Enable Voice',
                    style: GoogleFonts.armata(
                      color: Colors.orange[700],
                      fontSize: 12,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.orange[300]!),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Optional',
                style: GoogleFonts.armata(
                  color: Colors.orange[600],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _retryPermission() async {
    final granted = await PermissionHelper.requestMicrophonePermission();
    if (granted && onPermissionGranted != null) {
      onPermissionGranted!();
    }
  }
}

// Usage in Voice Chat View - add this to the body
class VoiceModeIndicator extends StatelessWidget {
  final bool isTextOnlyMode;
  final bool isConnected;

  const VoiceModeIndicator({
    super.key,
    required this.isTextOnlyMode,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    if (!isConnected) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isTextOnlyMode ? Colors.orange[100] : Colors.green[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTextOnlyMode ? Colors.orange[300]! : Colors.green[300]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isTextOnlyMode ? Icons.keyboard : Icons.mic,
            size: 14,
            color: isTextOnlyMode ? Colors.orange[700] : Colors.green[700],
          ),
          const SizedBox(width: 6),
          Text(
            isTextOnlyMode ? 'Text Mode' : 'Voice Mode',
            style: GoogleFonts.armata(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isTextOnlyMode ? Colors.orange[700] : Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }
}