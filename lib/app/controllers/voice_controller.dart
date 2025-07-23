import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/api_response_model.dart';
import '../models/voice_agent_model.dart';
import '../routes/app_routes.dart';
import '../services/voice_service.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class VoiceController extends GetxController {
  late VoiceService _voiceService;

  // Observable states
  final RxBool _isLoading = false.obs;
  final RxBool _isConnecting = false.obs;
  final RxList<VoiceAgentResponse> _voiceAgents = <VoiceAgentResponse>[].obs;
  final Rx<LocalVoiceSession?> _currentSession = Rx<LocalVoiceSession?>(null);
  final Rx<VoiceSessionStatus> _sessionStatus = VoiceSessionStatus.disconnected.obs;
  final RxList<VoiceMessage> _messages = <VoiceMessage>[].obs;
  final RxBool _isRecording = false.obs;
  final RxBool _isPlaying = false.obs;

  // Text input for manual messaging
  final TextEditingController messageController = TextEditingController();
  final RxBool _isSendingMessage = false.obs;

  // Session statistics
  final RxInt _sessionDuration = 0.obs;
  Timer? _durationTimer;

  // Filter and search
  final Rx<VoiceAgentTopic?> _topicFilter = Rx<VoiceAgentTopic?>(null);

  // Getters
  bool get isLoading => _isLoading.value;
  bool get isConnecting => _isConnecting.value;
  List<VoiceAgentResponse> get voiceAgents => _voiceAgents.toList();
  LocalVoiceSession? get currentSession => _currentSession.value;
  VoiceSessionStatus get sessionStatus => _sessionStatus.value;
  List<VoiceMessage> get messages => _messages.toList();
  bool get isRecording => _isRecording.value;
  bool get isPlaying => _isPlaying.value;
  bool get isSendingMessage => _isSendingMessage.value;
  int get sessionDuration => _sessionDuration.value;
  VoiceAgentTopic? get topicFilter => _topicFilter.value;

  // Computed properties
  bool get hasActiveSession => _currentSession.value != null;
  bool get isConnected => _sessionStatus.value == VoiceSessionStatus.connected;
  bool get canRecord => isConnected && !_isRecording.value && !_isPlaying.value;
  bool get canSendMessage => isConnected && !_isSendingMessage.value;
  bool get hasMessages => _messages.isNotEmpty;

  List<VoiceAgentResponse> get filteredAgents {
    if (_topicFilter.value == null) return _voiceAgents;
    return _voiceAgents.where((agent) => agent.topicEnum == _topicFilter.value).toList();
  }

  List<VoiceAgentResponse> get carsAgents =>
      _voiceAgents.where((agent) => agent.topic == 'cars').toList();
  List<VoiceAgentResponse> get footballAgents =>
      _voiceAgents.where((agent) => agent.topic == 'football').toList();
  List<VoiceAgentResponse> get travelAgents =>
      _voiceAgents.where((agent) => agent.topic == 'travel').toList();

  String get formattedSessionDuration => AppHelpers.formatDuration(_sessionDuration.value);

  @override
  void onInit() {
    super.onInit();
    _voiceService = Get.find<VoiceService>();
    _setupVoiceServiceListeners();
    loadVoiceAgents();
  }

  @override
  void onClose() {
    messageController.dispose();
    _stopDurationTimer();
    super.onClose();
  }

  /// Setup listeners to voice service
  void _setupVoiceServiceListeners() {
    // Listen to session status changes
    ever(_voiceService.sessionStatus.obs, (status) {
      _sessionStatus.value = status;
      _handleSessionStatusChange(status);
    });

    // Listen to current session changes
    ever(_voiceService.currentSession.obs, (session) {
      _currentSession.value = session;
      _handleSessionChange(session);
    });

    // Listen to messages changes
    ever(_voiceService.messages.obs, (messages) {
      _messages.assignAll(messages);
    });

    // Listen to recording state
    ever(_voiceService.isRecording.obs, (recording) {
      _isRecording.value = recording;
    });

    // Listen to playing state
    ever(_voiceService.isPlaying.obs, (playing) {
      _isPlaying.value = playing;
    });

    // Listen to connecting state
    ever(_voiceService.isConnecting.obs, (connecting) {
      _isConnecting.value = connecting;
    });
  }

  /// Handle session status changes
  void _handleSessionStatusChange(VoiceSessionStatus status) {
    switch (status) {
      case VoiceSessionStatus.connected:
        _startDurationTimer();
        AppHelpers.hapticFeedback();
        break;
      case VoiceSessionStatus.disconnected:
      case VoiceSessionStatus.error:
      case VoiceSessionStatus.expired:
        _stopDurationTimer();
        break;
      case VoiceSessionStatus.connecting:
        break;
    }

    AppHelpers.logUserAction('voice_session_status_changed', {
      'status': status.toString(),
    });
  }

  /// Handle session changes
  void _handleSessionChange(LocalVoiceSession? session) {
    if (session == null) {
      _sessionDuration.value = 0;
      _messages.clear();
      messageController.clear();
    }
  }

  /// Load voice agents
  Future<void> loadVoiceAgents() async {
    try {
      _isLoading.value = true;

      AppHelpers.logUserAction('load_voice_agents_attempt');

      final response = await _voiceService.getVoiceAgents();

      if (response.success && response.data != null) {
        _voiceAgents.assignAll(response.data!.agents);

        AppHelpers.logUserAction('load_voice_agents_success', {
          'agent_count': _voiceAgents.length,
          'topics': _voiceAgents.map((a) => a.topic).toSet().toList(),
        });
      } else {
        AppHelpers.logUserAction('load_voice_agents_failed', {
          'error': response.error,
        });

        if (response.statusCode != 401) {
          AppHelpers.showErrorSnackbar(
            response.error ?? 'Failed to load voice agents',
            title: 'Load Error',
          );
        }
      }
    } catch (e) {
      AppHelpers.logUserAction('load_voice_agents_exception', {
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'An unexpected error occurred while loading voice agents',
        title: 'Load Error',
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Start voice session with agent
  Future<void> startVoiceSession(int agentId) async {
    try {
      if (_isConnecting.value) return;

      AppHelpers.logUserAction('start_voice_session_attempt', {
        'agent_id': agentId,
      });

      final response = await _voiceService.startVoiceSession(agentId);

      if (response.success && response.data != null) {
        AppHelpers.logUserAction('start_voice_session_success', {
          'session_id': response.data!.sessionId,
          'agent_id': agentId,
          'agent_topic': response.data!.agent.topic,
        });

        // Navigate to voice chat screen
        Get.toNamed(AppRoutes.voiceChat);
      } else {
        AppHelpers.logUserAction('start_voice_session_failed', {
          'agent_id': agentId,
          'error': response.error,
        });

        AppHelpers.showErrorSnackbar(
          response.error ?? 'Failed to start voice session',
          title: 'Connection Failed',
        );
      }
    } catch (e) {
      AppHelpers.logUserAction('start_voice_session_exception', {
        'agent_id': agentId,
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'An unexpected error occurred while starting voice session',
        title: 'Connection Error',
      );
    }
  }

  /// Stop voice session
  Future<void> stopVoiceSession() async {
    try {
      if (!hasActiveSession) return;

      final sessionId = _currentSession.value!.sessionId;

      AppHelpers.logUserAction('stop_voice_session_attempt', {
        'session_id': sessionId,
        'duration': _sessionDuration.value,
      });

      final response = await _voiceService.stopVoiceSession();

      if (response.success && response.data != null) {
        AppHelpers.logUserAction('stop_voice_session_success', {
          'session_id': sessionId,
          'final_duration': response.data!.duration,
        });

        // Show session summary
        _showSessionSummary(response.data!);

        // Navigate back
        Get.back();
      } else {
        AppHelpers.logUserAction('stop_voice_session_failed', {
          'session_id': sessionId,
          'error': response.error,
        });
      }
    } catch (e) {
      AppHelpers.logUserAction('stop_voice_session_exception', {
        'error': e.toString(),
      });
    }
  }

  /// Start recording audio
  Future<void> startRecording() async {
    try {
      if (!canRecord) return;

      AppHelpers.logUserAction('start_recording_attempt', {
        'session_id': _currentSession.value?.sessionId,
      });

      final success = await _voiceService.startRecording();

      if (success) {
        AppHelpers.logUserAction('start_recording_success', {
          'session_id': _currentSession.value?.sessionId,
        });

        AppHelpers.hapticFeedback();
      } else {
        AppHelpers.logUserAction('start_recording_failed', {
          'session_id': _currentSession.value?.sessionId,
        });
      }
    } catch (e) {
      AppHelpers.logUserAction('start_recording_exception', {
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'Failed to start recording',
        title: 'Recording Error',
      );
    }
  }

  /// Stop recording audio
  Future<void> stopRecording() async {
    try {
      if (!_isRecording.value) return;

      AppHelpers.logUserAction('stop_recording_attempt', {
        'session_id': _currentSession.value?.sessionId,
      });

      await _voiceService.stopRecording();

      AppHelpers.logUserAction('stop_recording_success', {
        'session_id': _currentSession.value?.sessionId,
      });

      AppHelpers.hapticFeedback();
    } catch (e) {
      AppHelpers.logUserAction('stop_recording_exception', {
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'Failed to stop recording',
        title: 'Recording Error',
      );
    }
  }

  /// Send text message
  Future<void> sendTextMessage() async {
    try {
      if (!canSendMessage || messageController.text.trim().isEmpty) return;

      _isSendingMessage.value = true;
      final message = messageController.text.trim();
      messageController.clear();

      AppHelpers.logUserAction('send_text_message_attempt', {
        'session_id': _currentSession.value?.sessionId,
        'message_length': message.length,
      });

      _voiceService.sendTextMessage(message);

      AppHelpers.logUserAction('send_text_message_success', {
        'session_id': _currentSession.value?.sessionId,
        'message_length': message.length,
      });
    } catch (e) {
      AppHelpers.logUserAction('send_text_message_exception', {
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'Failed to send message',
        title: 'Send Error',
      );
    } finally {
      _isSendingMessage.value = false;
    }
  }

  /// Send interruption signal
  void sendInterruption() {
    try {
      if (!isConnected) return;

      AppHelpers.logUserAction('send_interruption', {
        'session_id': _currentSession.value?.sessionId,
      });

      _voiceService.sendInterruption();
      AppHelpers.hapticFeedback();

      AppHelpers.showInfoSnackbar(
        'Interruption sent',
        title: 'Interrupted',
      );
    } catch (e) {
      AppHelpers.logUserAction('send_interruption_exception', {
        'error': e.toString(),
      });
    }
  }

  /// Clear conversation messages
  void clearMessages() {
    try {
      AppHelpers.logUserAction('clear_voice_messages', {
        'session_id': _currentSession.value?.sessionId,
        'message_count': _messages.length,
      });

      _voiceService.clearMessages();

      AppHelpers.showInfoSnackbar(
        'Messages cleared',
        title: 'Cleared',
      );
    } catch (e) {
      AppHelpers.logUserAction('clear_voice_messages_exception', {
        'error': e.toString(),
      });
    }
  }

  /// Export conversation
  Future<void> exportConversation() async {
    try {
      if (!hasMessages) {
        AppHelpers.showInfoSnackbar('No conversation to export');
        return;
      }

      AppHelpers.logUserAction('export_voice_conversation_attempt', {
        'session_id': _currentSession.value?.sessionId,
        'message_count': _messages.length,
      });

      await _voiceService.exportConversation();

      AppHelpers.logUserAction('export_voice_conversation_success', {
        'session_id': _currentSession.value?.sessionId,
        'message_count': _messages.length,
      });
    } catch (e) {
      AppHelpers.logUserAction('export_voice_conversation_exception', {
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'Failed to export conversation',
        title: 'Export Error',
      );
    }
  }

  /// Set topic filter
  void setTopicFilter(VoiceAgentTopic? topic) {
    _topicFilter.value = topic;

    AppHelpers.logUserAction('voice_topic_filter_set', {
      'topic': topic?.value,
    });
  }

  /// Clear topic filter
  void clearTopicFilter() {
    _topicFilter.value = null;

    AppHelpers.logUserAction('voice_topic_filter_cleared');
  }

  /// Get agent by id
  VoiceAgentResponse? getAgentById(int agentId) {
    try {
      return _voiceAgents.firstWhere((agent) => agent.id == agentId);
    } catch (e) {
      return null;
    }
  }

  /// Get agents by topic
  List<VoiceAgentResponse> getAgentsByTopic(VoiceAgentTopic topic) {
    return _voiceAgents.where((agent) => agent.topicEnum == topic).toList();
  }

  /// Show agent selection dialog
  void showAgentSelectionDialog(VoiceAgentTopic topic) {
    final agents = getAgentsByTopic(topic);

    if (agents.isEmpty) {
      AppHelpers.showWarningSnackbar(
        'No agents available for ${topic.value}',
        title: 'No Agents',
      );
      return;
    }

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
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Select ${GetUtils.capitalize(topic.value)} Agent',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...agents.map((agent) => ListTile(
              leading: CircleAvatar(
                backgroundColor: AppHelpers.getVoiceAgentColor(topic),
                child: Text(
                  agent.title[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(agent.title),
              subtitle: Text(agent.description),
              onTap: () {
                Get.back();
                startVoiceSession(agent.id);
              },
            )).toList(),
          ],
        ),
      ),
    );
  }

  /// Start duration timer
  void _startDurationTimer() {
    _stopDurationTimer();
    _sessionDuration.value = 0;

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _sessionDuration.value++;
    });
  }

  /// Stop duration timer
  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  /// Show session summary
  void _showSessionSummary(VoiceSessionStats stats) {
    Get.dialog(
      AlertDialog(
        title: const Text('Session Summary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Topic: ${GetUtils.capitalize(stats.topic)}'),
            Text('Duration: ${stats.formattedDuration}'),
            Text('Messages: ${_messages.length}'),
            Text('Started: ${AppHelpers.formatDateTime(stats.startedAtDateTime)}'),
            Text('Ended: ${AppHelpers.formatDateTime(stats.endedAtDateTime)}'),
          ],
        ),
        actions: [
          if (hasMessages)
            TextButton(
              onPressed: () {
                Get.back();
                exportConversation();
              },
              child: const Text('Export'),
            ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show session options menu
  void showSessionOptionsMenu() {
    if (!hasActiveSession) return;

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
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Session Options',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.stop),
              title: const Text('Send Interruption'),
              subtitle: const Text('Stop agent from speaking'),
              onTap: () {
                Get.back();
                sendInterruption();
              },
            ),
            if (hasMessages)
              ListTile(
                leading: const Icon(Icons.clear_all),
                title: const Text('Clear Messages'),
                subtitle: const Text('Clear conversation history'),
                onTap: () {
                  Get.back();
                  clearMessages();
                },
              ),
            if (hasMessages)
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Export Conversation'),
                subtitle: const Text('Copy conversation to clipboard'),
                onTap: () {
                  Get.back();
                  exportConversation();
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.call_end, color: Colors.red),
              title: const Text('End Session', style: TextStyle(color: Colors.red)),
              onTap: () {
                Get.back();
                stopVoiceSession();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Navigate to voice agents
  void navigateToVoiceAgents() {
    Get.toNamed(AppRoutes.voiceAgents);
    AppHelpers.logUserAction('navigate_to_voice_agents');
  }

  /// Get session status display text
  String get sessionStatusText {
    switch (_sessionStatus.value) {
      case VoiceSessionStatus.connecting:
        return 'Connecting...';
      case VoiceSessionStatus.connected:
        return 'Connected';
      case VoiceSessionStatus.disconnected:
        return 'Disconnected';
      case VoiceSessionStatus.error:
        return 'Error';
      case VoiceSessionStatus.expired:
        return 'Session Expired';
    }
  }

  /// Get session status color
  Color get sessionStatusColor {
    switch (_sessionStatus.value) {
      case VoiceSessionStatus.connecting:
        return AppColors.warning;
      case VoiceSessionStatus.connected:
        return AppColors.success;
      case VoiceSessionStatus.disconnected:
        return AppColors.textTertiary;
      case VoiceSessionStatus.error:
      case VoiceSessionStatus.expired:
        return AppColors.error;
    }
  }

  /// Get recording button color
  Color get recordingButtonColor {
    if (_isRecording.value) {
      return AppColors.error;
    } else if (canRecord) {
      return AppColors.primary;
    } else {
      return AppColors.disabled;
    }
  }

  /// Get recording button icon
  IconData get recordingButtonIcon {
    return _isRecording.value ? Icons.stop : Icons.mic;
  }

  /// Check if can show session options
  bool get canShowSessionOptions {
    return hasActiveSession && (isConnected || _sessionStatus.value == VoiceSessionStatus.error);
  }

  /// Get current agent display name
  String get currentAgentDisplayName {
    return _currentSession.value?.agent.title ?? '';
  }

  /// Get current agent topic
  String get currentAgentTopic {
    return GetUtils.capitalize(_currentSession.value?.agent.topic ?? '') ?? '';
  }

  /// Refresh voice agents
  Future<void> refreshVoiceAgents() async {
    await loadVoiceAgents();

    AppHelpers.logUserAction('voice_agents_refreshed');

    if (_voiceAgents.isNotEmpty) {
      AppHelpers.showSuccessSnackbar(
        'Voice agents refreshed',
        title: 'Refreshed',
      );
    }
  }

  /// Handle app lifecycle changes
  void handleAppLifecycleChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      // Stop recording when app goes to background
        if (_isRecording.value) {
          stopRecording();
        }
        break;
      case AppLifecycleState.resumed:
      // Check session health when app resumes
        _voiceService.checkConnectionHealth();
        break;
      default:
        break;
    }
  }
}