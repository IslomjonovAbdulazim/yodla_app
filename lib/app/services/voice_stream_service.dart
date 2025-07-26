// lib/app/services/voice_stream_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/voice_stream_model.dart';
import '../utils/helpers.dart';
import 'api_service.dart';

class VoiceStreamService extends GetxService {
  late ApiService _apiService;

  // WebSocket connection
  WebSocketChannel? _webSocket;
  StreamSubscription? _subscription;

  // State - Make these public for GetX reactivity
  final Rx<VoiceConnectionState> connectionStateRx = VoiceConnectionState.disconnected.obs;
  final RxList<VoiceTranscript> transcriptsRx = <VoiceTranscript>[].obs;
  final RxBool isRecordingRx = false.obs;
  final RxBool isPlayingRx = false.obs;

  // Current agent
  VoiceAgent? _currentAgent;

  // Getters
  VoiceConnectionState get connectionState => connectionStateRx.value;
  List<VoiceTranscript> get transcripts => transcriptsRx.toList();
  bool get isRecording => isRecordingRx.value;
  bool get isPlaying => isPlayingRx.value;
  bool get isConnected => connectionStateRx.value == VoiceConnectionState.connected;
  VoiceAgent? get currentAgent => _currentAgent;

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }

  /// Get available voice agents
  Future<List<VoiceAgent>> getAgents() async {
    try {
      final response = await _apiService.get('/voice/agents');
      if (response.success && response.data != null) {
        final agents = (response.data['agents'] as List)
            .map((json) => VoiceAgent.fromJson(json))
            .where((agent) => agent.isActive)
            .toList();

        AppHelpers.logUserAction('voice_agents_loaded', {
          'count': agents.length,
        });

        return agents;
      }
      return [];
    } catch (e) {
      AppHelpers.logUserAction('get_agents_error', {'error': e.toString()});
      return [];
    }
  }

  /// Connect to voice agent stream
  Future<bool> connect(VoiceAgent agent) async {
    try {
      if (isConnected) await disconnect();

      connectionStateRx.value = VoiceConnectionState.connecting;
      _currentAgent = agent;

      // Get WebSocket URL from backend
      final response = await _apiService.post('/voice/topic/start', data: {
        'agent_id': agent.id,
      });

      if (!response.success || response.data == null) {
        connectionStateRx.value = VoiceConnectionState.error;
        return false;
      }

      final websocketUrl = response.data['websocket_url'];
      if (websocketUrl == null) {
        connectionStateRx.value = VoiceConnectionState.error;
        return false;
      }

      // Connect to ElevenLabs WebSocket
      _webSocket = WebSocketChannel.connect(Uri.parse(websocketUrl));

      // Listen to stream
      _subscription = _webSocket!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
      );

      // Wait for connection
      await Future.delayed(const Duration(milliseconds: 500));
      connectionStateRx.value = VoiceConnectionState.connected;

      AppHelpers.logUserAction('voice_connected', {
        'agent_id': agent.id,
        'agent_title': agent.title,
      });

      AppHelpers.showSuccessSnackbar('Connected to ${agent.title}');

      return true;
    } catch (e) {
      connectionStateRx.value = VoiceConnectionState.error;
      AppHelpers.logUserAction('connect_error', {'error': e.toString()});
      AppHelpers.showErrorSnackbar('Failed to connect: ${e.toString()}');
      return false;
    }
  }

  /// Disconnect from voice stream
  Future<void> disconnect() async {
    try {
      _subscription?.cancel();
      await _webSocket?.sink.close();
      _webSocket = null;
      _subscription = null;
      _currentAgent = null;
      isRecordingRx.value = false;
      isPlayingRx.value = false;
      connectionStateRx.value = VoiceConnectionState.disconnected;

      AppHelpers.logUserAction('voice_disconnected');
    } catch (e) {
      AppHelpers.logUserAction('disconnect_error', {'error': e.toString()});
    }
  }

  /// Send audio chunk to stream
  void sendAudioChunk(Uint8List audioData) {
    if (!isConnected || _webSocket == null) return;

    try {
      final audioBase64 = base64Encode(audioData);
      final event = AudioChunkEvent(audioBase64);
      _webSocket!.sink.add(json.encode(event.toJson()));

      AppHelpers.logUserAction('audio_chunk_sent', {
        'size': audioData.length,
      });
    } catch (e) {
      AppHelpers.logUserAction('send_audio_error', {'error': e.toString()});
    }
  }

  /// Send text message
  void sendTextMessage(String text) {
    if (!isConnected || _webSocket == null || text.trim().isEmpty) return;

    try {
      final event = TextMessageEvent(text.trim());
      _webSocket!.sink.add(json.encode(event.toJson()));

      // Add to transcripts
      transcriptsRx.add(VoiceTranscript.user(text.trim()));

      AppHelpers.logUserAction('text_message_sent', {
        'length': text.length,
      });
    } catch (e) {
      AppHelpers.logUserAction('send_text_error', {'error': e.toString()});
    }
  }

  /// Send interruption signal
  void interrupt() {
    if (!isConnected || _webSocket == null) return;

    try {
      final event = InterruptionEvent();
      _webSocket!.sink.add(json.encode(event.toJson()));

      AppHelpers.logUserAction('interruption_sent');
      AppHelpers.hapticFeedback();
    } catch (e) {
      AppHelpers.logUserAction('interrupt_error', {'error': e.toString()});
    }
  }

  /// Start recording audio
  void startRecording() {
    if (!isConnected) {
      AppHelpers.showErrorSnackbar('Not connected to voice agent');
      return;
    }

    isRecordingRx.value = true;
    AppHelpers.logUserAction('recording_started');
    AppHelpers.hapticFeedback();

    // TODO: Start actual audio recording and stream chunks
    // This would use platform-specific audio recording
    // and call sendAudioChunk() with audio data
  }

  /// Stop recording audio
  void stopRecording() {
    isRecordingRx.value = false;
    AppHelpers.logUserAction('recording_stopped');
    AppHelpers.hapticFeedback();

    // TODO: Stop actual audio recording
  }

  /// Clear conversation
  void clearTranscripts() {
    transcriptsRx.clear();
    AppHelpers.logUserAction('transcripts_cleared');
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic data) {
    try {
      final json = jsonDecode(data);
      final type = json['type'];

      switch (type) {
        case 'audio':
          _handleAgentAudio(json);
          break;
        case 'agent_response':
          _handleAgentText(json);
          break;
        case 'user_transcript':
          _handleUserTranscript(json);
          break;
        case 'error':
          _handleError(json['message'] ?? 'Unknown error');
          break;
        default:
          AppHelpers.logUserAction('unknown_message_type', {'type': type});
      }
    } catch (e) {
      AppHelpers.logUserAction('handle_message_error', {'error': e.toString()});
    }
  }

  /// Handle agent audio response
  void _handleAgentAudio(Map<String, dynamic> json) {
    try {
      final audioEvent = AgentAudioEvent.fromJson(json);

      isPlayingRx.value = true;

      // TODO: Play audio using platform audio player
      // final audioData = base64Decode(audioEvent.audioBase64);
      // playAudio(audioData);

      // Simulate playback for now
      Future.delayed(const Duration(seconds: 2), () {
        isPlayingRx.value = false;
      });

      AppHelpers.logUserAction('agent_audio_received', {
        'event_id': audioEvent.eventId,
      });
    } catch (e) {
      isPlayingRx.value = false;
      AppHelpers.logUserAction('handle_audio_error', {'error': e.toString()});
    }
  }

  /// Handle agent text response
  void _handleAgentText(Map<String, dynamic> json) {
    try {
      final textEvent = AgentTextEvent.fromJson(json);

      if (textEvent.text.isNotEmpty) {
        transcriptsRx.add(VoiceTranscript.agent(textEvent.text));
      }

      AppHelpers.logUserAction('agent_text_received', {
        'length': textEvent.text.length,
      });
    } catch (e) {
      AppHelpers.logUserAction('handle_text_error', {'error': e.toString()});
    }
  }

  /// Handle user transcript
  void _handleUserTranscript(Map<String, dynamic> json) {
    try {
      final transcriptEvent = UserTranscriptEvent.fromJson(json);

      if (transcriptEvent.text.isNotEmpty) {
        transcriptsRx.add(VoiceTranscript.user(transcriptEvent.text));
      }

      AppHelpers.logUserAction('user_transcript_received', {
        'length': transcriptEvent.text.length,
      });
    } catch (e) {
      AppHelpers.logUserAction('handle_transcript_error', {'error': e.toString()});
    }
  }

  /// Handle WebSocket errors
  void _handleError(dynamic error) {
    connectionStateRx.value = VoiceConnectionState.error;
    AppHelpers.logUserAction('websocket_error', {'error': error.toString()});
    AppHelpers.showErrorSnackbar('Voice connection error');
  }

  /// Handle WebSocket disconnect
  void _handleDisconnect() {
    if (connectionStateRx.value == VoiceConnectionState.connected) {
      connectionStateRx.value = VoiceConnectionState.disconnected;
      AppHelpers.showWarningSnackbar('Voice connection lost');
    }
    AppHelpers.logUserAction('websocket_disconnected');
  }
}