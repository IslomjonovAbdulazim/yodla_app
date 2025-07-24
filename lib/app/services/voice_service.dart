import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/api_response_model.dart';
import '../models/voice_agent_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'api_service.dart';

class VoiceService extends GetxService {
  late ApiService _apiService;

  // WebSocket connection
  WebSocketChannel? _webSocketChannel;
  StreamSubscription? _webSocketSubscription;

  // Current session
  final Rx<LocalVoiceSession?> _currentSession = Rx<LocalVoiceSession?>(null);
  final Rx<VoiceSessionStatus> _sessionStatus = VoiceSessionStatus.disconnected.obs;
  final RxList<VoiceMessage> _messages = <VoiceMessage>[].obs;

  // Audio recording state
  final RxBool _isRecording = false.obs;
  final RxBool _isPlaying = false.obs;
  final RxBool _isConnecting = false.obs;

  // Getters
  LocalVoiceSession? get currentSession => _currentSession.value;
  VoiceSessionStatus get sessionStatus => _sessionStatus.value;
  List<VoiceMessage> get messages => _messages.toList();
  bool get isRecording => _isRecording.value;
  bool get isPlaying => _isPlaying.value;
  bool get isConnecting => _isConnecting.value;
  bool get isConnected => _sessionStatus.value == VoiceSessionStatus.connected;
  bool get hasActiveSession => _currentSession.value != null;

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
  }

  @override
  void onClose() {
    _disconnectWebSocket();
    super.onClose();
  }

  /// Get available voice agents
  Future<ApiResponse<VoiceAgentsResponse>> getVoiceAgents() async {
    try {
      final response = await _apiService.get<VoiceAgentsResponse>(
        ApiEndpoints.voiceAgents,
        fromJson: (json) => VoiceAgentsResponse.fromJson(json),
      );

      if (response.success && response.data != null) {
        AppHelpers.logUserAction('voice_agents_fetched', {
          'agent_count': response.data!.agents.length,
        });
      }

      return response;
    } catch (e) {
      AppHelpers.logUserAction('get_voice_agents_error', {
        'error': e.toString(),
      });

      return ApiResponse.error(
        error: 'Failed to get voice agents: ${e.toString()}',
      );
    }
  }

  /// Start voice conversation session
  Future<ApiResponse<LocalVoiceSession>> startVoiceSession(int agentId) async {
    try {
      // Check if already has active session
      if (hasActiveSession) {
        await stopVoiceSession();
      }

      _isConnecting.value = true;
      _sessionStatus.value = VoiceSessionStatus.connecting;

      // Request microphone permission
      final hasPermission = await _requestMicrophonePermission();
      if (!hasPermission) {
        _isConnecting.value = false;
        _sessionStatus.value = VoiceSessionStatus.error;
        return ApiResponse.error(error: 'Microphone permission required');
      }

      // Start session via API
      final request = StartTopicRequest(agentId: agentId);
      final response = await _apiService.post<StartTopicResponse>(
        ApiEndpoints.startVoiceSession,
        data: request.toJson(),
        fromJson: (json) => StartTopicResponse.fromJson(json),
      );

      if (!response.success || response.data == null) {
        _isConnecting.value = false;
        _sessionStatus.value = VoiceSessionStatus.error;
        return ApiResponse.error(
          error: response.error ?? 'Failed to start voice session',
        );
      }

      // Create local session
      final session = LocalVoiceSession.fromStartResponse(response.data!);
      _currentSession.value = session;

      // Connect to WebSocket
      final connected = await _connectWebSocket(session.websocketUrl);
      if (!connected) {
        _currentSession.value = null;
        _isConnecting.value = false;
        _sessionStatus.value = VoiceSessionStatus.error;
        return ApiResponse.error(error: 'Failed to connect to voice service');
      }

      _isConnecting.value = false;
      _sessionStatus.value = VoiceSessionStatus.connected;

      // Add welcome message
      _addMessage(VoiceMessage.system(
        'Connected to ${session.agent.title}. Start speaking!',
      ));

      AppHelpers.logUserAction('voice_session_started', {
        'session_id': session.sessionId,
        'agent_id': agentId,
        'agent_topic': session.agent.topic,
      });

      AppHelpers.showSuccessSnackbar(
        'Connected to ${session.agent.title}',
        title: 'Voice Session Started',
      );

      return ApiResponse.success(data: session);
    } catch (e) {
      _isConnecting.value = false;
      _sessionStatus.value = VoiceSessionStatus.error;

      AppHelpers.logUserAction('start_voice_session_error', {
        'agent_id': agentId,
        'error': e.toString(),
      });

      return ApiResponse.error(
        error: 'Failed to start voice session: ${e.toString()}',
      );
    }
  }

  /// Stop voice conversation session
  Future<ApiResponse<VoiceSessionStats>> stopVoiceSession() async {
    try {
      if (!hasActiveSession) {
        return ApiResponse.error(error: 'No active voice session');
      }

      final sessionId = _currentSession.value!.sessionId;

      // Disconnect WebSocket first
      _disconnectWebSocket();

      // Stop session via API
      final request = StopTopicRequest(sessionId: sessionId);
      final response = await _apiService.post<StopTopicResponse>(
        ApiEndpoints.stopVoiceSession,
        data: request.toJson(),
        fromJson: (json) => StopTopicResponse.fromJson(json),
      );

      // Clear local session
      _currentSession.value = null;
      _sessionStatus.value = VoiceSessionStatus.disconnected;
      _messages.clear();
      _isRecording.value = false;
      _isPlaying.value = false;

      if (response.success && response.data != null) {
        AppHelpers.logUserAction('voice_session_stopped', {
          'session_id': sessionId,
          'duration': response.data!.sessionStats.duration,
        });

        AppHelpers.showSuccessSnackbar(
          'Voice session ended (${response.data!.sessionStats.formattedDuration})',
          title: 'Session Ended',
        );

        return ApiResponse.success(data: response.data!.sessionStats);
      } else {
        AppHelpers.logUserAction('stop_voice_session_error', {
          'session_id': sessionId,
          'error': response.error,
        });

        return ApiResponse.error(
          error: response.error ?? 'Failed to stop voice session',
        );
      }
    } catch (e) {
      AppHelpers.logUserAction('stop_voice_session_error', {
        'error': e.toString(),
      });

      return ApiResponse.error(
        error: 'Failed to stop voice session: ${e.toString()}',
      );
    }
  }

  /// Connect to WebSocket
  Future<bool> _connectWebSocket(String websocketUrl) async {
    try {
      _webSocketChannel = WebSocketChannel.connect(Uri.parse(websocketUrl));

      _webSocketSubscription = _webSocketChannel!.stream.listen(
        _handleWebSocketMessage,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketClosed,
      );

      // Send initial connection message if needed
      await Future.delayed(const Duration(milliseconds: 500));

      AppHelpers.logUserAction('websocket_connected', {
        'url': websocketUrl,
      });

      return true;
    } catch (e) {
      AppHelpers.logUserAction('websocket_connection_error', {
        'url': websocketUrl,
        'error': e.toString(),
      });

      return false;
    }
  }

  /// Disconnect WebSocket
  void _disconnectWebSocket() {
    try {
      _webSocketSubscription?.cancel();
      _webSocketChannel?.sink.close();
      _webSocketChannel = null;
      _webSocketSubscription = null;

      AppHelpers.logUserAction('websocket_disconnected');
    } catch (e) {
      AppHelpers.logUserAction('websocket_disconnect_error', {
        'error': e.toString(),
      });
    }
  }

  /// Handle WebSocket messages
  void _handleWebSocketMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = json.decode(message);
      final webSocketMessage = WebSocketMessage.fromJson(data);

      switch (webSocketMessage.type) {
        case 'audio':
          _handleAudioMessage(webSocketMessage.data);
          break;
        case 'agent_response':
          _handleAgentResponse(webSocketMessage.data);
          break;
        case 'user_transcript':
          _handleUserTranscript(webSocketMessage.data);
          break;
        case 'error':
          _handleWebSocketError(webSocketMessage.data['message'] ?? 'WebSocket error');
          break;
        default:
          AppHelpers.logUserAction('unknown_websocket_message', {
            'type': webSocketMessage.type,
          });
      }
    } catch (e) {
      AppHelpers.logUserAction('websocket_message_error', {
        'error': e.toString(),
        'message': message.toString(),
      });
    }
  }

  /// Handle audio message from agent
  void _handleAudioMessage(Map<String, dynamic> data) {
    try {
      final audioEvent = AudioEvent.fromJson(data);

      // TODO: Play audio using audio service
      _playAudioData(audioEvent.audioBase64);

      AppHelpers.logUserAction('audio_message_received', {
        'event_id': audioEvent.eventId,
        'audio_length': audioEvent.audioBase64.length,
      });
    } catch (e) {
      AppHelpers.logUserAction('handle_audio_message_error', {
        'error': e.toString(),
      });
    }
  }

  /// Handle agent text response
  void _handleAgentResponse(Map<String, dynamic> data) {
    try {
      final agentResponse = AgentResponseEvent.fromJson(data);

      _addMessage(VoiceMessage.agent(agentResponse.agentResponse));

      AppHelpers.logUserAction('agent_response_received', {
        'response_length': agentResponse.agentResponse.length,
      });
    } catch (e) {
      AppHelpers.logUserAction('handle_agent_response_error', {
        'error': e.toString(),
      });
    }
  }

  /// Handle user transcript
  void _handleUserTranscript(Map<String, dynamic> data) {
    try {
      final transcriptEvent = UserTranscriptionEvent.fromJson(data);

      if (transcriptEvent.userTranscript.isNotEmpty) {
        _addMessage(VoiceMessage.user(transcriptEvent.userTranscript));
      }

      AppHelpers.logUserAction('user_transcript_received', {
        'transcript_length': transcriptEvent.userTranscript.length,
      });
    } catch (e) {
      AppHelpers.logUserAction('handle_user_transcript_error', {
        'error': e.toString(),
      });
    }
  }

  /// Handle WebSocket error
  void _handleWebSocketError(dynamic error) {
    AppHelpers.logUserAction('websocket_error', {
      'error': error.toString(),
    });

    _sessionStatus.value = VoiceSessionStatus.error;

    AppHelpers.showErrorSnackbar(
      'Voice connection error: ${error.toString()}',
      title: 'Connection Error',
    );
  }

  /// Handle WebSocket closed
  void _handleWebSocketClosed() {
    AppHelpers.logUserAction('websocket_closed');

    if (_sessionStatus.value == VoiceSessionStatus.connected) {
      _sessionStatus.value = VoiceSessionStatus.disconnected;

      AppHelpers.showWarningSnackbar(
        'Voice connection closed',
        title: 'Connection Lost',
      );
    }
  }

  /// Send audio data to WebSocket
  void _sendAudioData(Uint8List audioData) {
    try {
      if (_webSocketChannel == null || !isConnected) {
        return;
      }

      final message = {
        'user_audio_chunk': base64Encode(audioData),
      };

      _webSocketChannel!.sink.add(json.encode(message));

      AppHelpers.logUserAction('audio_data_sent', {
        'data_length': audioData.length,
      });
    } catch (e) {
      AppHelpers.logUserAction('send_audio_data_error', {
        'error': e.toString(),
      });
    }
  }

  /// Send text message to WebSocket
  void sendTextMessage(String message) {
    try {
      if (_webSocketChannel == null || !isConnected) {
        AppHelpers.showErrorSnackbar('Not connected to voice service');
        return;
      }

      final data = {
        'type': 'user_message',
        'text': message,
      };

      _webSocketChannel!.sink.add(json.encode(data));

      _addMessage(VoiceMessage.user(message));

      AppHelpers.logUserAction('text_message_sent', {
        'message_length': message.length,
      });
    } catch (e) {
      AppHelpers.logUserAction('send_text_message_error', {
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar('Failed to send message');
    }
  }

  /// Send interruption signal
  void sendInterruption() {
    try {
      if (_webSocketChannel == null || !isConnected) {
        return;
      }

      final message = {
        'type': 'interruption',
      };

      _webSocketChannel!.sink.add(json.encode(message));

      AppHelpers.logUserAction('interruption_sent');
    } catch (e) {
      AppHelpers.logUserAction('send_interruption_error', {
        'error': e.toString(),
      });
    }
  }

  /// Start recording audio
  Future<bool> startRecording() async {
    try {
      if (!isConnected) {
        AppHelpers.showErrorSnackbar('Not connected to voice service');
        return false;
      }

      if (_isRecording.value) {
        return true; // Already recording
      }

      final hasPermission = await _requestMicrophonePermission();
      if (!hasPermission) {
        return false;
      }

      // TODO: Implement actual audio recording
      _isRecording.value = true;

      AppHelpers.logUserAction('recording_started');
      AppHelpers.hapticFeedback();

      return true;
    } catch (e) {
      AppHelpers.logUserAction('start_recording_error', {
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar('Failed to start recording');
      return false;
    }
  }

  /// Stop recording audio
  Future<void> stopRecording() async {
    try {
      if (!_isRecording.value) {
        return; // Not recording
      }

      // TODO: Implement actual audio recording stop
      _isRecording.value = false;

      AppHelpers.logUserAction('recording_stopped');
      AppHelpers.hapticFeedback();
    } catch (e) {
      AppHelpers.logUserAction('stop_recording_error', {
        'error': e.toString(),
      });
    }
  }

  /// Play audio data
  void _playAudioData(String base64Audio) {
    try {
      _isPlaying.value = true;

      // TODO: Implement actual audio playback
      // final audioData = base64Decode(base64Audio);
      // Play audioData using audio service

      // Simulate playback completion
      Future.delayed(const Duration(seconds: 2), () {
        _isPlaying.value = false;
      });

      AppHelpers.logUserAction('audio_playback_started', {
        'audio_length': base64Audio.length,
      });
    } catch (e) {
      _isPlaying.value = false;

      AppHelpers.logUserAction('play_audio_error', {
        'error': e.toString(),
      });
    }
  }

  /// Add message to conversation
  void _addMessage(VoiceMessage message) {
    _messages.add(message);

    // Update current session
    if (_currentSession.value != null) {
      _currentSession.value = _currentSession.value!.addMessage(message);
    }
  }

  /// Request microphone permission
  /// Request microphone permission
  /// Request microphone permission
  Future<bool> _requestMicrophonePermission() async {
    try {
      // First check current permission status
      final currentStatus = await Permission.microphone.status;

      AppHelpers.logUserAction('microphone_permission_check', {
        'current_status': currentStatus.toString(),
      });

      // If already granted, return true
      if (currentStatus.isGranted) {
        return true;
      }

      // If permanently denied, show settings dialog
      if (currentStatus.isPermanentlyDenied) {
        final shouldOpenSettings = await _showPermissionDialog(
          title: 'Microphone Access Required',
          message: 'To use voice conversations, please enable microphone access in your device settings.\n\nGo to Settings > Privacy & Security > Microphone > Yodla App',
          confirmText: 'Open Settings',
          cancelText: 'Cancel',
          isSettingsDialog: true,
        );

        if (shouldOpenSettings) {
          await openAppSettings();

          // Wait for user to come back and check again
          await Future.delayed(const Duration(milliseconds: 1000));
          final newStatus = await Permission.microphone.status;

          AppHelpers.logUserAction('permission_recheck_after_settings', {
            'status': newStatus.toString(),
          });

          if (newStatus.isGranted) {
            AppHelpers.showSuccessSnackbar('Microphone access enabled!');
            return true;
          } else {
            AppHelpers.showWarningSnackbar(
                'Microphone access is still disabled. Voice conversations won\'t work without it.',
                title: 'Permission Still Disabled'
            );
            return false;
          }
        }

        return false;
      }

      // Show explanation dialog first
      final shouldRequestPermission = await _showPermissionDialog(
        title: 'Enable Voice Conversations',
        message: 'Yodla needs access to your microphone to enable voice conversations with AI agents.\n\nYour voice data is processed securely and never stored without your consent.',
        confirmText: 'Allow Access',
        cancelText: 'Not Now',
        isSettingsDialog: false,
      );

      if (!shouldRequestPermission) {
        return false;
      }

      // Now request the actual permission
      final status = await Permission.microphone.request();

      AppHelpers.logUserAction('microphone_permission_requested', {
        'status': status.toString(),
      });

      if (status.isGranted) {
        AppHelpers.showSuccessSnackbar('Microphone access granted!');
        return true;
      } else if (status.isPermanentlyDenied) {
        AppHelpers.showWarningSnackbar(
            'Microphone access was denied. You can enable it later in Settings if you change your mind.',
            title: 'Permission Denied'
        );
        return false;
      } else {
        // Denied but not permanently
        AppHelpers.showWarningSnackbar(
            'Microphone access is required for voice conversations.',
            title: 'Permission Needed'
        );
        return false;
      }

    } catch (e) {
      AppHelpers.logUserAction('microphone_permission_error', {
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'Failed to request microphone permission: ${e.toString()}',
        title: 'Permission Error',
      );

      return false;
    }
  }

  /// Show permission explanation dialog
  Future<bool> _showPermissionDialog({
    required String title,
    required String message,
    required String confirmText,
    required String cancelText,
    required bool isSettingsDialog,
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Row(
          children: [
            Icon(
              isSettingsDialog ? Icons.settings : Icons.mic,
              color: Get.theme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              cancelText,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              confirmText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    return result ?? false;
  }

  /// Check if microphone permission is available in device settings
  Future<bool> _isMicrophonePermissionAvailable() async {
    try {
      // Check if the permission is properly configured
      final status = await Permission.microphone.status;

      // If it's undetermined, it means the permission is properly set up
      // If it's permanently denied, it should still appear in settings
      return status != PermissionStatus.restricted;
    } catch (e) {
      AppHelpers.logUserAction('check_microphone_availability_error', {
        'error': e.toString(),
      });
      return false;
    }
  }

  /// Clear conversation messages
  void clearMessages() {
    _messages.clear();

    if (_currentSession.value != null) {
      _currentSession.value = _currentSession.value!.copyWith(messages: []);
    }

    AppHelpers.logUserAction('messages_cleared');
  }

  /// Get session duration
  Duration? get sessionDuration {
    return _currentSession.value?.duration;
  }

  /// Check if session is expired
  bool get isSessionExpired {
    return _currentSession.value?.isExpired ?? false;
  }

  /// Handle session expiry
  void _handleSessionExpiry() {
    if (isSessionExpired && hasActiveSession) {
      AppHelpers.showWarningSnackbar(
        'Voice session has expired',
        title: 'Session Expired',
      );

      stopVoiceSession();
    }
  }

  /// Get conversation transcript
  String getConversationTranscript() {
    final transcript = StringBuffer();

    for (final message in _messages) {
      final speaker = message.type == VoiceMessageType.user ? 'You' :
      message.type == VoiceMessageType.agent ? _currentSession.value?.agent.title ?? 'Agent' :
      'System';

      transcript.writeln('$speaker: ${message.content}');
    }

    return transcript.toString();
  }

  /// Export conversation
  Future<void> exportConversation() async {
    try {
      final transcript = getConversationTranscript();

      if (transcript.isEmpty) {
        AppHelpers.showInfoSnackbar('No conversation to export');
        return;
      }

      await AppHelpers.copyToClipboard(transcript);

      AppHelpers.logUserAction('conversation_exported', {
        'message_count': _messages.length,
      });

    } catch (e) {
      AppHelpers.logUserAction('export_conversation_error', {
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar('Failed to export conversation');
    }
  }

  /// Check connection health
  void checkConnectionHealth() {
    if (_currentSession.value != null && _sessionStatus.value == VoiceSessionStatus.connected) {
      _handleSessionExpiry();
    }
  }
}

/// Voice session manager for background tasks
class VoiceSessionManager extends GetxService {
  Timer? _healthCheckTimer;

  @override
  void onInit() {
    super.onInit();
    _startHealthCheck();
  }

  @override
  void onClose() {
    _healthCheckTimer?.cancel();
    super.onClose();
  }

  void _startHealthCheck() {
    _healthCheckTimer = Timer.periodic(
      const Duration(minutes: 1),
          (timer) {
        final voiceService = Get.find<VoiceService>();
        voiceService.checkConnectionHealth();
      },
    );
  }
}