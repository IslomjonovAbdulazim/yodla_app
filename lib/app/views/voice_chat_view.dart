// lib/app/views/voice/voice_chat_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/voice_controller.dart';
import '../models/voice_agent_model.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_text_field.dart';

class VoiceChatView extends StatelessWidget {
  const VoiceChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VoiceController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(controller),
          body: Column(
            children: [
              // Connection Status Bar
              _buildStatusBar(controller),

              // Messages List
              Expanded(
                child: _buildMessagesList(controller),
              ),

              // Input Section
              _buildInputSection(controller),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(VoiceController controller) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF7AB2D3)),
        onPressed: () => Get.back(),
      ),
      title: Obx(() {
        final session = controller.currentSession;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session?.agent.title ?? 'Voice Chat',
              style: GoogleFonts.armata(
                color: const Color(0xFF7AB2D3),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (session != null)
              Text(
                session.agent.topic.toUpperCase(),
                style: GoogleFonts.armata(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
          ],
        );
      }),
      actions: [
        // Session Options
        Obx(() {
          if (controller.canShowSessionOptions) {
            return IconButton(
              icon: const Icon(Icons.more_vert, color: Color(0xFF7AB2D3)),
              // onPressed: () => controller.showSessionOptionsDialog(),
              onPressed: () => () {},
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildStatusBar(VoiceController controller) {
    return Obx(() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: controller.sessionStatusColor.withOpacity(0.1),
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Status Indicator
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: controller.sessionStatusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),

            // Status Text
            Text(
              controller.sessionStatusText,
              style: GoogleFonts.armata(
                color: controller.sessionStatusColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),

            const Spacer(),

            // Session Duration
            if (controller.hasActiveSession)
              Text(
                controller.formattedSessionDuration,
                style: GoogleFonts.armata(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildMessagesList(VoiceController controller) {
    return Obx(() {
      if (controller.messages.isEmpty) {
        return _buildEmptyState(controller);
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.messages.length,
        itemBuilder: (context, index) {
          final message = controller.messages[index];
          return _buildMessageBubble(message);
        },
      );
    });
  }

  Widget _buildEmptyState(VoiceController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF7AB2D3).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mic,
              color: Color(0xFF7AB2D3),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Start Conversation',
            style: GoogleFonts.armata(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF7AB2D3),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap and hold the microphone to speak\nor type a message to start chatting',
            textAlign: TextAlign.center,
            style: GoogleFonts.armata(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(VoiceMessage message) {
    final isUser = message.type == VoiceMessageType.user;
    final isSystem = message.type == VoiceMessageType.system;

    if (isSystem) {
      return _buildSystemMessage(message);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // Agent Avatar
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF7AB2D3),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Message Content
          Expanded(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Message Bubble
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(0xFF7AB2D3)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20).copyWith(
                      bottomRight: isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(20),
                      bottomLeft: !isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(20),
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: GoogleFonts.armata(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),

                // Timestamp
                const SizedBox(height: 4),
                Text(
                  _formatMessageTime(message.timestamp),
                  style: GoogleFonts.armata(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          if (isUser) ...[
            const SizedBox(width: 8),
            // User Avatar
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: const Icon(
                Icons.person,
                color: Colors.grey,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSystemMessage(VoiceMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.content,
            style: GoogleFonts.armata(
              color: Colors.orange[800],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection(VoiceController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Recording Button
          _buildRecordingButton(controller),

          const SizedBox(height: 16),

          // Text Input Row
          _buildTextInputRow(controller),
        ],
      ),
    );
  }

  Widget _buildRecordingButton(VoiceController controller) {
    return Obx(() {
      final isRecording = controller.isRecording;
      final canRecord = controller.canRecord;

      return GestureDetector(
        onLongPressStart: (_) {
          if (canRecord) {
            controller.startRecording();
          }
        },
        onLongPressEnd: (_) {
          if (isRecording) {
            controller.stopRecording();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: controller.recordingButtonColor,
            shape: BoxShape.circle,
            boxShadow: [
              if (isRecording)
                BoxShadow(
                  color: controller.recordingButtonColor.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
            ],
          ),
          child: Stack(
            children: [
              // Mic Icon
              Center(
                child: Icon(
                  controller.recordingButtonIcon,
                  color: Colors.white,
                  size: 32,
                ),
              ),

              // Recording Animation
              if (isRecording)
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

  Widget _buildTextInputRow(VoiceController controller) {
    return Obx(() {
      return Row(
        children: [
          // Text Input Field
          Expanded(
            child: CustomTextField(
              controller: controller.messageController,
              hint: 'Type a message...',
              maxLines: 3,
              minLines: 1,
              enabled: controller.canSendMessage,
              onSubmitted: (_) => controller.sendTextMessage(),
            ),
          ),

          const SizedBox(width: 12),

          // Send Button
          GestureDetector(
            onTap: controller.canSendMessage &&
                controller.messageController.text.trim().isNotEmpty
                ? () => controller.sendTextMessage()
                : null,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: controller.canSendMessage &&
                    controller.messageController.text.trim().isNotEmpty
                    ? const Color(0xFF7AB2D3)
                    : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send,
                color: controller.canSendMessage &&
                    controller.messageController.text.trim().isNotEmpty
                    ? Colors.white
                    : Colors.grey[500],
                size: 20,
              ),
            ),
          ),
        ],
      );
    });
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}