// lib/app/models/voice_stream_model.dart
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

/// Voice transcript for display
class VoiceTranscript {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  VoiceTranscript({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  static VoiceTranscript user(String text) {
    return VoiceTranscript(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
  }

  static VoiceTranscript agent(String text) {
    return VoiceTranscript(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
    );
  }
}

/// WebSocket Events - ElevenLabs Protocol
class AudioChunkEvent {
  final String audioBase64;

  AudioChunkEvent(this.audioBase64);

  Map<String, dynamic> toJson() => {
    'user_audio_chunk': audioBase64,
  };
}

class TextMessageEvent {
  final String text;

  TextMessageEvent(this.text);

  Map<String, dynamic> toJson() => {
    'type': 'user_message',
    'text': text,
  };
}

class InterruptionEvent {
  Map<String, dynamic> toJson() => {
    'type': 'interruption',
  };
}

/// Received Events
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

class AgentTextEvent {
  final String text;

  AgentTextEvent(this.text);

  factory AgentTextEvent.fromJson(Map<String, dynamic> json) {
    return AgentTextEvent(
      json['agent_response_event']['agent_response'] ?? '',
    );
  }
}

class UserTranscriptEvent {
  final String text;

  UserTranscriptEvent(this.text);

  factory UserTranscriptEvent.fromJson(Map<String, dynamic> json) {
    return UserTranscriptEvent(
      json['user_transcription_event']['user_transcript'] ?? '',
    );
  }
}