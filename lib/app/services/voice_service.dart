// lib/app/services/voice_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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

      // Removed microphone permission check - let system handle errors

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
      AppHelpers.logUserAction('stop_voice_session_exception', {
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
      AppHelpers.logUserAction('websocket_connect_attempt', {
        'url': websocketUrl,
      });

      _webSocketChannel = WebSocketChannel.connect(Uri.parse(websocketUrl));

      // Listen to WebSocket messages
      _webSocketSubscription = _webSocketChannel!.stream.listen(
            (data) => _handleWebSocketMessage(data),
        onError: (error) => _handleWebSocketError(error),
        onDone: () => _handleWebSocketDisconnection(),
      );

      // Wait for connection to establish
      await Future.delayed(const Duration(milliseconds: 500));

      AppHelpers.logUserAction('websocket_connected');
      return true;
    } catch (e) {
      AppHelpers.logUserAction('websocket_connect_error', {
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

  /// Handle WebSocket message
  void _handleWebSocketMessage(dynamic data) {
    try {
      final message = json.decode(data);
      final messageType = message['type'] as String?;

      AppHelpers.logUserAction('websocket_message_received', {
        'type': messageType,
      });

      switch (messageType) {
        case 'audio':
          final audioData = message['audio'] as String?;
          if (audioData != null) {
            _playAudioData(audioData);
          }
          break;
        case 'transcript':
          final transcript = message['transcript'] as String?;
          if (transcript != null) {
            _addMessage(VoiceMessage.agent(transcript));
          }
          break;
        case 'error':
          final error = message['error'] as String?;
          AppHelpers.showErrorSnackbar(
            error ?? 'Voice service error',
            title: 'Connection Error',
          );
          break;
        case 'session_expired':
          _sessionStatus.value = VoiceSessionStatus.expired;
          AppHelpers.showWarningSnackbar(
            'Voice session has expired',
            title: 'Session Expired',
          );
          break;
      }
    } catch (e) {
      AppHelpers.logUserAction('websocket_message_parse_error', {
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
      'Connection lost to voice service',
      title: 'Connection Error',
    );
  }

  /// Handle WebSocket disconnection
  void _handleWebSocketDisconnection() {
    AppHelpers.logUserAction('websocket_disconnected');

    if (_sessionStatus.value == VoiceSessionStatus.connected) {
      _sessionStatus.value = VoiceSessionStatus.disconnected;
      AppHelpers.showWarningSnackbar(
        'Disconnected from voice service',
        title: 'Connection Lost',
      );
    }
  }

  /// Send text message via WebSocket
  Future<void> sendTextMessage(String text) async {
    try {
      if (_webSocketChannel == null || !isConnected) {
        AppHelpers.showErrorSnackbar('Not connected to voice service');
        return;
      }

      final message = {
        'type': 'text_input',
        'text': text,
      };

      _webSocketChannel!.sink.add(json.encode(message));

      // Add user message to conversation
      _addMessage(VoiceMessage.user(text));

      AppHelpers.logUserAction('text_message_sent', {
        'message_length': text.length,
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

      // Removed microphone permission check - let system handle errors naturally

      // TODO: Implement actual audio recording
      _isRecording.value = true;

      AppHelpers.logUserAction('recording_started');
      AppHelpers.hapticFeedback();

      return true;
    } catch (e) {
      AppHelpers.logUserAction('start_recording_error', {
        'error': e.toString(),
      });

      // Let the system error bubble up naturally instead of showing custom error
      rethrow;
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

      // Let the system error bubble up naturally
      rethrow;
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

      // Let the system error bubble up naturally
      rethrow;
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