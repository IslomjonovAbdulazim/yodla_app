// lib/app/views/home/widgets/speak_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../controllers/voice_controller.dart';
import '../models/voice_agent_model.dart';
import '../utils/app_colors.dart';

class SpeakPage extends StatelessWidget {
  const SpeakPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VoiceController>(
      init: Get.find<VoiceController>(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Voice Conversation',
                          style: GoogleFonts.armata(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF7AB2D3),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose an AI agent to start speaking',
                          style: GoogleFonts.armata(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Agents Grid
                Obx(() {
                  if (controller.isLoading) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF7AB2D3),
                        ),
                      ),
                    );
                  }

                  if (controller.voiceAgents.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.mic_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No voice agents available',
                              style: GoogleFonts.armata(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pull to refresh',
                              style: GoogleFonts.armata(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () => controller.loadVoiceAgents(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7AB2D3),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Retry',
                                style: GoogleFonts.armata(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final agent = controller.voiceAgents[index];
                          return AgentCard(
                            agent: agent,
                            onTap: () => controller.startVoiceSession(agent.id),
                          );
                        },
                        childCount: controller.voiceAgents.length,
                      ),
                    ),
                  );
                }),

                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AgentCard extends StatelessWidget {
  final VoiceAgentResponse agent;
  final VoidCallback onTap;

  const AgentCard({
    super.key,
    required this.agent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Agent Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: agent.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.grey,
                        size: 40,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.error,
                        color: Colors.grey,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Agent Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Topic Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getTopicColor(agent.topic),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          agent.topic.toUpperCase(),
                          style: GoogleFonts.armata(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Agent Title
                      Text(
                        agent.title,
                        style: GoogleFonts.armata(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Agent Description
                      Text(
                        agent.description,
                        style: GoogleFonts.armata(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Action Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7AB2D3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.mic,
                    color: Color(0xFF7AB2D3),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTopicColor(String topic) {
    switch (topic.toLowerCase()) {
      case 'cars':
        return const Color(0xFFE74C3C);
      case 'travel':
        return const Color(0xFF3498DB);
      case 'football':
        return const Color(0xFF27AE60);
      default:
        return const Color(0xFF7AB2D3);
    }
  }
}