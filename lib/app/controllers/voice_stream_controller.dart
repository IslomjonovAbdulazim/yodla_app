// lib/app/controllers/voice_stream_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/voice_stream_model.dart';
import '../services/voice_stream_service.dart';
import '../utils/helpers.dart';

class VoiceStreamController extends GetxController {
  late VoiceStreamService _voiceService;

  // UI state
  final RxBool _isLoading = false.obs;
  final RxList<VoiceAgent> _agents = <VoiceAgent>[].obs;
  final TextEditingController messageController = TextEditingController();

  // Getters
  bool get isLoading => _isLoading.value;
  List<VoiceAgent> get agents => _agents.toList();

  // Expose service observables directly for reactivity
  Rx<VoiceConnectionState> get connectionStateRx => _voiceService.connectionStateRx;
  RxList<VoiceTranscript> get transcriptsRx => _voiceService.transcriptsRx;
  RxBool get isRecordingRx => _voiceService.isRecordingRx;
  RxBool get isPlayingRx => _voiceService.isPlayingRx;

  // Simple getters for logic
  VoiceConnectionState get connectionState => _voiceService.connectionState;
  List<VoiceTranscript> get transcripts => _voiceService.transcripts;
  bool get isRecording => _voiceService.isRecording;
  bool get isPlaying => _voiceService.isPlaying;
  bool get isConnected => _voiceService.isConnected;
  VoiceAgent? get currentAgent => _voiceService.currentAgent;

  // UI helpers
  bool get hasTranscripts => _voiceService.transcripts.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _voiceService = Get.find<VoiceStreamService>();
    loadAgents();
  }

  @override
  void onClose() {
    messageController.dispose();
    disconnect();
    super.onClose();
  }

  /// Load available voice agents
  Future<void> loadAgents() async {
    try {
      _isLoading.value = true;
      final agents = await _voiceService.getAgents();
      _agents.assignAll(agents);

      AppHelpers.logUserAction('agents_loaded', {
        'count': agents.length,
      });
    } catch (e) {
      AppHelpers.logUserAction('load_agents_error', {
        'error': e.toString(),
      });
      AppHelpers.showErrorSnackbar('Failed to load voice agents');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Connect to a voice agent
  Future<void> connectToAgent(VoiceAgent agent) async {
    try {
      AppHelpers.logUserAction('connect_attempt', {
        'agent_id': agent.id,
        'agent_title': agent.title,
      });

      final success = await _voiceService.connect(agent);

      if (success) {
        AppHelpers.logUserAction('connect_success', {
          'agent_id': agent.id,
        });
      } else {
        AppHelpers.logUserAction('connect_failed', {
          'agent_id': agent.id,
        });
      }
    } catch (e) {
      AppHelpers.logUserAction('connect_error', {
        'agent_id': agent.id,
        'error': e.toString(),
      });
    }
  }

  /// Disconnect from current agent
  Future<void> disconnect() async {
    try {
      await _voiceService.disconnect();
      AppHelpers.logUserAction('disconnected');
    } catch (e) {
      AppHelpers.logUserAction('disconnect_error', {
        'error': e.toString(),
      });
    }
  }

  /// Start recording voice
  /// Start recording voice
  void startRecording() {
    try {
      if (_voiceService.connectionState != VoiceConnectionState.connected ||
          _voiceService.isRecording || _voiceService.isPlaying) return;

      _voiceService.startRecording();

      AppHelpers.logUserAction('recording_started', {
        'agent_id': currentAgent?.id,
      });
    } catch (e) {
      AppHelpers.logUserAction('start_recording_error', {
        'error': e.toString(),
      });
      AppHelpers.showErrorSnackbar('Failed to start recording');
    }
  }

  /// Stop recording voice
  void stopRecording() {
    try {
      _voiceService.stopRecording();

      AppHelpers.logUserAction('recording_stopped', {
        'agent_id': currentAgent?.id,
      });
    } catch (e) {
      AppHelpers.logUserAction('stop_recording_error', {
        'error': e.toString(),
      });
    }
  }

  /// Send text message
  /// Send text message
  void sendTextMessage() {
    try {
      if (_voiceService.connectionState != VoiceConnectionState.connected ||
          messageController.text.trim().isEmpty) return;

      final text = messageController.text.trim();
      messageController.clear();

      _voiceService.sendTextMessage(text);

      AppHelpers.logUserAction('text_sent', {
        'agent_id': currentAgent?.id,
        'length': text.length,
      });
    } catch (e) {
      AppHelpers.logUserAction('send_text_error', {
        'error': e.toString(),
      });
      AppHelpers.showErrorSnackbar('Failed to send message');
    }
  }

  /// Send interruption signal
  /// Send interruption signal
  void interrupt() {
    try {
      if (_voiceService.connectionState != VoiceConnectionState.connected) return;

      _voiceService.interrupt();

      AppHelpers.logUserAction('interrupted', {
        'agent_id': currentAgent?.id,
      });

      AppHelpers.showInfoSnackbar('Interrupted agent');
    } catch (e) {
      AppHelpers.logUserAction('interrupt_error', {
        'error': e.toString(),
      });
    }
  }

  /// Clear conversation transcripts
  void clearTranscripts() {
    try {
      _voiceService.clearTranscripts();

      AppHelpers.logUserAction('transcripts_cleared', {
        'agent_id': currentAgent?.id,
      });

      AppHelpers.showInfoSnackbar('Conversation cleared');
    } catch (e) {
      AppHelpers.logUserAction('clear_error', {
        'error': e.toString(),
      });
    }
  }

  /// Copy conversation to clipboard
  void exportConversation() {
    try {
      if (!hasTranscripts) {
        AppHelpers.showInfoSnackbar('No conversation to export');
        return;
      }

      final buffer = StringBuffer();
      buffer.writeln('Conversation with ${currentAgent?.title ?? 'Agent'}');
      buffer.writeln('=' * 50);
      buffer.writeln();

      for (final transcript in transcripts) {
        final speaker = transcript.isUser ? 'You' : currentAgent?.title ?? 'Agent';
        buffer.writeln('$speaker: ${transcript.text}');
        buffer.writeln();
      }

      AppHelpers.copyToClipboard(buffer.toString());

      AppHelpers.logUserAction('conversation_exported', {
        'agent_id': currentAgent?.id,
        'transcript_count': transcripts.length,
      });

      AppHelpers.showSuccessSnackbar('Conversation copied to clipboard');
    } catch (e) {
      AppHelpers.logUserAction('export_error', {
        'error': e.toString(),
      });
      AppHelpers.showErrorSnackbar('Failed to export conversation');
    }
  }

  /// Refresh agents list
  Future<void> refreshAgents() async {
    await loadAgents();
    AppHelpers.showSuccessSnackbar('Agents refreshed');
  }

  /// Show agent selection dialog
  void showAgentSelection() {
    Get.dialog(
      AlertDialog(
        title: const Text('Select Voice Agent'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: agents.length,
            itemBuilder: (context, index) {
              final agent = agents[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(agent.title[0].toUpperCase()),
                ),
                title: Text(agent.title),
                subtitle: Text(agent.description),
                onTap: () {
                  Get.back();
                  connectToAgent(agent);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Show options menu
  void showOptionsMenu() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isConnected) ...[
              ListTile(
                leading: const Icon(Icons.stop),
                title: const Text('Interrupt Agent'),
                onTap: () {
                  Get.back();
                  interrupt();
                },
              ),
              if (hasTranscripts)
                ListTile(
                  leading: const Icon(Icons.clear),
                  title: const Text('Clear Conversation'),
                  onTap: () {
                    Get.back();
                    clearTranscripts();
                  },
                ),
              if (hasTranscripts)
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Export Conversation'),
                  onTap: () {
                    Get.back();
                    exportConversation();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.call_end),
                title: const Text('Disconnect'),
                onTap: () {
                  Get.back();
                  disconnect();
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh Agents'),
              onTap: () {
                Get.back();
                refreshAgents();
              },
            ),
          ],
        ),
      ),
    );
  }
}