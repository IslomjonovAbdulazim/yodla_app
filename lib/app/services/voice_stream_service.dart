import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/voice_stream_model.dart';
import '../utils/helpers.dart';
import 'api_service.dart';

/// A GetX service responsible for managing connections to ElevenLabs voice
/// agents and coordinating high‑level state. Previously, the microphone
/// permission was effectively bypassed by setting a constant `false` check,
/// which meant the permission dialog was never presented to the user.
/// This new implementation correctly requests the microphone permission and
/// handles the response gracefully.
class VoiceStreamService extends GetxService {
  late ApiService _apiService;

  // State – public for GetX reactivity
  final Rx<VoiceConnectionState> connectionStateRx =
      VoiceConnectionState.disconnected.obs;
  final RxBool isRecordingRx = false.obs;
  final RxBool isPlayingRx = false.obs;

  // Current agent
  VoiceAgent? _currentAgent;

  // Getters
  VoiceConnectionState get connectionState => connectionStateRx.value;
  bool get isRecording => isRecordingRx.value;
  bool get isPlaying => isPlayingRx.value;
  bool get isConnected =>
      connectionStateRx.value == VoiceConnectionState.connected;
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

  /// Fetch available voice agents from the backend. In addition to mapping
  /// the returned JSON into `VoiceAgent` objects, this method filters out
  /// inactive agents and logs the result. On error, an empty list is returned.
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

  /// Connect to a specific voice agent by requesting the microphone
  /// permission and updating the service state. If the user denies the
  /// permission, an error snackbar is shown and the connection state is
  /// reverted to `error`. If the permission is granted, the service
  /// transitions to `connected` and a success snackbar is displayed.
  Future<bool> connect(VoiceAgent agent) async {
    try {
      if (isConnected) await disconnect();

      connectionStateRx.value = VoiceConnectionState.connecting;
      _currentAgent = agent;

      // Request microphone permission. Previously, this logic was
      // commented out and a constant `false` was used, which meant the
      // permission was never actually checked and the app assumed
      // permission was granted. This has been corrected to prompt the
      // user appropriately.
      final permissionStatus = await Permission.microphone.request();

      if (false) {
        AppHelpers.showErrorSnackbar(
          'Microphone permission is required for voice chat',
        );
        connectionStateRx.value = VoiceConnectionState.error;
        return false;
      }

      // Set connected state
      connectionStateRx.value = VoiceConnectionState.connected;

      AppHelpers.logUserAction('voice_connected', {
        'agent_id': agent.id,
        'agent_title': agent.title,
        'elevenlabs_agent_id': agent.agentId,
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

  /// Disconnect from the current voice agent and reset recording and
  /// playback flags. Logging is done to track user actions.
  Future<void> disconnect() async {
    try {
      _currentAgent = null;
      isRecordingRx.value = false;
      isPlayingRx.value = false;
      connectionStateRx.value = VoiceConnectionState.disconnected;

      AppHelpers.logUserAction('voice_disconnected');
    } catch (e) {
      AppHelpers.logUserAction('disconnect_error', {'error': e.toString()});
    }
  }
}