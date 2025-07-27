// lib/app/models/voice_stream_model.dart

/// Voice Agent model
class VoiceAgent {
  final int id;
  final String topic;
  final String title;
  final String description;
  final String agentId; // ElevenLabs agent ID
  final bool isActive;

  VoiceAgent({
    required this.id,
    required this.topic,
    required this.title,
    required this.description,
    required this.agentId,
    required this.isActive,
  });

  factory VoiceAgent.fromJson(Map<String, dynamic> json) {
    return VoiceAgent(
      id: json['id'],
      topic: json['topic'],
      title: json['title'],
      description: json['description'],
      agentId: json['agent_id'],
      isActive: json['is_active'] ?? true,
    );
  }
}

/// Simple connection state
enum VoiceConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

/// WebSocket Events for audio streaming
class AudioChunkEvent {
  final String audioBase64;

  AudioChunkEvent(this.audioBase64);

  Map<String, dynamic> toJson() => {
    'user_audio_chunk': audioBase64,
  };
}

/// Agent audio response event
class AgentAudioEvent {
  final String audioBase64;
  final int eventId;

  AgentAudioEvent({
    required this.audioBase64,
    required this.eventId,
  });

  factory AgentAudioEvent.fromJson(Map<String, dynamic> json) {
    return AgentAudioEvent(
      audioBase64: json['audio_event']['audio_base_64'] ?? '',
      eventId: json['audio_event']['event_id'] ?? 0,
    );
  }
}