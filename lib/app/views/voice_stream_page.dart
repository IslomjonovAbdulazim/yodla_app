// lib/app/widgets/voice_stream_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/voice_stream_controller.dart';
import '../models/voice_stream_model.dart';
import '../utils/app_colors.dart';

class VoiceStreamPage extends StatelessWidget {
  const VoiceStreamPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VoiceStreamController>(
      init: VoiceStreamController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // Header with connection status
                _buildHeader(controller),

                // Agent selection or conversation area
                Expanded(
                  child: Obx(() {
                    // Show conversation only when connected AND agent is selected
                    if (controller.connectionStateRx.value == VoiceConnectionState.connected &&
                        controller.currentAgent != null) {
                      return _buildConversationArea(controller);
                    } else {
                      // Always show agent selection when not connected to an agent
                      return _buildAgentSelection(controller);
                    }
                  }),
                ),

                // Controls (only when connected)
                Obx(() {
                  if (controller.connectionStateRx.value == VoiceConnectionState.connected &&
                      controller.currentAgent != null) {
                    return _buildControls(controller);
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(VoiceStreamController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button when connected
          Obx(() {
            if (controller.connectionStateRx.value == VoiceConnectionState.connected &&
                controller.currentAgent != null) {
              return IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: controller.disconnect,
                color: AppColors.primary,
              );
            }
            return Icon(
              Icons.mic,
              color: AppColors.primary,
              size: 24,
            );
          }),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voice Chat',
                  style: GoogleFonts.armata(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Builder(builder: (a) {
                  final agent = controller.currentAgent;
                  return Text(
                    agent != null ? agent.title : 'Select an agent to start',
                    style: GoogleFonts.armata(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  );
                }),
              ],
            ),
          ),
          _buildConnectionIndicator(controller),
          // Options menu only when connected
          Obx(() {
            if (controller.connectionStateRx.value == VoiceConnectionState.connected &&
                controller.currentAgent != null) {
              return IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: controller.showOptionsMenu,
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildConnectionIndicator(VoiceStreamController controller) {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getConnectionColor(controller.connectionStateRx.value).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _getConnectionColor(controller.connectionStateRx.value)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _getConnectionColor(controller.connectionStateRx.value),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _getConnectionText(controller.connectionStateRx.value),
              style: GoogleFonts.armata(
                fontSize: 12,
                color: _getConnectionColor(controller.connectionStateRx.value),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    });
  }

  Color _getConnectionColor(VoiceConnectionState state) {
    switch (state) {
      case VoiceConnectionState.connected:
        return Colors.green;
      case VoiceConnectionState.connecting:
        return Colors.orange;
      case VoiceConnectionState.error:
        return Colors.red;
      case VoiceConnectionState.disconnected:
        return Colors.grey;
    }
  }

  String _getConnectionText(VoiceConnectionState state) {
    switch (state) {
      case VoiceConnectionState.connected:
        return 'Connected';
      case VoiceConnectionState.connecting:
        return 'Connecting...';
      case VoiceConnectionState.error:
        return 'Error';
      case VoiceConnectionState.disconnected:
        return 'Disconnected';
    }
  }

  Widget _buildAgentSelection(VoiceStreamController controller) {
    return Obx(() {
      if (controller.isLoading) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (controller.agents.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.voice_over_off,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No voice agents available',
                style: GoogleFonts.armata(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: controller.refreshAgents,
                child: Text(
                  'Refresh',
                  style: GoogleFonts.armata(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.agents.length,
        itemBuilder: (context, index) {
          final agent = controller.agents[index];
          return _buildAgentCard(agent, controller);
        },
      );
    });
  }

  Widget _buildAgentCard(VoiceAgent agent, VoiceStreamController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            agent.title[0].toUpperCase(),
            style: GoogleFonts.armata(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          agent.title,
          style: GoogleFonts.armata(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              agent.description,
              style: GoogleFonts.armata(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                agent.topic.toUpperCase(),
                style: GoogleFonts.armata(
                  fontSize: 10,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Connect',
            style: GoogleFonts.armata(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () => controller.connectToAgent(agent),
      ),
    );
  }

  Widget _buildConversationArea(VoiceStreamController controller) {
    return Obx(() {
      if (controller.transcriptsRx.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.waves,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Start speaking or type a message',
                style: GoogleFonts.armata(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.transcriptsRx.length,
        itemBuilder: (context, index) {
          final transcript = controller.transcriptsRx[index];
          return _buildTranscriptBubble(transcript, controller);
        },
      );
    });
  }

  Widget _buildTranscriptBubble(VoiceTranscript transcript, VoiceStreamController controller) {
    final isUser = transcript.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 12,
          left: isUser ? 64 : 0,
          right: isUser ? 0 : 64,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              transcript.text,
              style: GoogleFonts.armata(
                color: isUser ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(transcript.timestamp),
              style: GoogleFonts.armata(
                color: isUser ? Colors.white70 : Colors.grey[500],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(VoiceStreamController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Recording button
          _buildRecordingButton(controller),

          // Text input
          const SizedBox(height: 16),
          _buildTextInput(controller),
        ],
      ),
    );
  }

  Widget _buildRecordingButton(VoiceStreamController controller) {
    return Obx(() {
      return GestureDetector(
        onLongPressStart: (_) => controller.startRecording(),
        onLongPressEnd: (_) => controller.stopRecording(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _getRecordButtonColor(controller),
            shape: BoxShape.circle,
            boxShadow: [
              if (controller.isRecordingRx.value)
                BoxShadow(
                  color: _getRecordButtonColor(controller).withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  controller.isRecordingRx.value ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              if (controller.isRecordingRx.value)
                Center(
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Color _getRecordButtonColor(VoiceStreamController controller) {
    if (controller.isRecordingRx.value) return Colors.red;
    if (controller.connectionStateRx.value == VoiceConnectionState.connected &&
        !controller.isPlayingRx.value) return Colors.blue;
    return Colors.grey;
  }

  Widget _buildTextInput(VoiceStreamController controller) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller.messageController,
            decoration: InputDecoration(
              hintText: 'Type a message...',
              hintStyle: GoogleFonts.armata(color: Colors.grey[500]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: GoogleFonts.armata(),
            onSubmitted: (_) => controller.sendTextMessage(),
          ),
        ),
        const SizedBox(width: 12),
        Obx(() {
          return GestureDetector(
            onTap: _canSendText(controller) ? controller.sendTextMessage : null,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _canSendText(controller) ? AppColors.primary : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send,
                color: _canSendText(controller) ? Colors.white : Colors.grey[500],
                size: 20,
              ),
            ),
          );
        }),
      ],
    );
  }

  bool _canSendText(VoiceStreamController controller) {
    return controller.connectionStateRx.value == VoiceConnectionState.connected &&
        controller.messageController.text.trim().isNotEmpty;
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}