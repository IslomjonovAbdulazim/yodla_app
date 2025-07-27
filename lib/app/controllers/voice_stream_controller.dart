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

  // Getters
  bool get isLoading => _isLoading.value;
  List<VoiceAgent> get agents => _agents.toList();

  // Expose service observables directly for reactivity
  Rx<VoiceConnectionState> get connectionStateRx => _voiceService.connectionStateRx;
  RxBool get isRecordingRx => _voiceService.isRecordingRx;
  RxBool get isPlayingRx => _voiceService.isPlayingRx;

  // Simple getters for logic
  VoiceConnectionState get connectionState => _voiceService.connectionState;
  bool get isRecording => _voiceService.isRecording;
  bool get isPlaying => _voiceService.isPlaying;
  bool get isConnected => _voiceService.isConnected;
  VoiceAgent? get currentAgent => _voiceService.currentAgent;

  @override
  void onInit() {
    super.onInit();
    _voiceService = Get.find<VoiceStreamService>();
    loadAgents();
  }

  @override
  void onClose() {
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

  /// Refresh agents list
  Future<void> refreshAgents() async {
    await loadAgents();
    AppHelpers.showSuccessSnackbar('Agents refreshed');
  }
}