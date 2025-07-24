// lib/app/views/voice/voice_agents_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/voice_controller.dart';
import '../utils/app_colors.dart';
import '../widgets/speak_page.dart';

class VoiceAgentsView extends StatelessWidget {
  const VoiceAgentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF7AB2D3)),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Voice Agents',
          style: GoogleFonts.armata(
            color: const Color(0xFF7AB2D3),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          GetBuilder<VoiceController>(
            builder: (controller) => IconButton(
              icon: Icon(
                Icons.refresh,
                color: controller.isLoading
                    ? Colors.grey
                    : const Color(0xFF7AB2D3),
              ),
              onPressed: controller.isLoading
                  ? null
                  : () => controller.refreshVoiceAgents(),
            ),
          ),
        ],
      ),
      body: const SpeakPage(),
    );
  }
}