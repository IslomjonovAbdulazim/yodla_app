import '../utils/constants.dart';

/// Voice Agent Model - Exact match with backend VoiceAgent model
class VoiceAgent {
  final int id;
  final String topic;
  final String title;
  final String description;
  final String imageUrl;
  final String agentId;
  final bool isActive;
  final DateTime createdAt;

  VoiceAgent({
    required this.id,
    required this.topic,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.agentId,
    required this.isActive,
    required this.createdAt,
  });

  factory VoiceAgent.fromJson(Map<String, dynamic> json) {
    return VoiceAgent(
      id: json['id'],
      topic: json['topic'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['image_url'],
      agentId: json['agent_id'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topic': topic,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'agent_id': agentId,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  VoiceAgent copyWith({
    int? id,
    String? topic,
    String? title,
    String? description,
    String? imageUrl,
    String? agentId,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return VoiceAgent(
      id: id ?? this.id,
      topic: topic ?? this.topic,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      agentId: agentId ?? this.agentId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  VoiceAgentTopic get topicEnum => VoiceAgentTopic.fromString(topic);

  @override
  String toString() {
    return 'VoiceAgent{id: $id, topic: $topic, title: $title, description: $description, imageUrl: $imageUrl, agentId: $agentId, isActive: $isActive, createdAt: $createdAt}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is VoiceAgent &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Voice Agent Response - Used in API responses
class VoiceAgentResponse {
  final int id;
  final String topic;
  final String title;
  final String description;
  final String imageUrl;
  final String agentId;
  final bool isActive;

  VoiceAgentResponse({
    required this.id,
    required this.topic,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.agentId,
    required this.isActive,
  });

  factory VoiceAgentResponse.fromJson(Map<String, dynamic> json) {
    return VoiceAgentResponse(
      id: json['id'],
      topic: json['topic'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['image_url'],
      agentId: json['agent_id'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topic': topic,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'agent_id': agentId,
      'is_active': isActive,
    };
  }

  /// Convert to VoiceAgent model
  VoiceAgent toVoiceAgent() {
    return VoiceAgent(
      id: id,
      topic: topic,
      title: title,
      description: description,
      imageUrl: imageUrl,
      agentId: agentId,
      isActive: isActive,
      createdAt: DateTime.now(), // Not provided in response
    );
  }

  VoiceAgentTopic get topicEnum => VoiceAgentTopic.fromString(topic);

  @override
  String toString() {
    return 'VoiceAgentResponse{id: $id, topic: $topic, title: $title, description: $description, imageUrl: $imageUrl, agentId: $agentId, isActive: $isActive}';
  }
}

/// Voice Agents Response - Matches GET /voice/agents response
class VoiceAgentsResponse {
  final List<VoiceAgentResponse> agents;

  VoiceAgentsResponse({
    required this.agents,
  });

  factory VoiceAgentsResponse.fromJson(Map<String, dynamic> json) {
    return VoiceAgentsResponse(
      agents: (json['agents'] as List<dynamic>)
          .map((agent) => VoiceAgentResponse.fromJson(agent))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agents': agents.map((agent) => agent.toJson()).toList(),
    };
  }

  /// Get agents by topic
  List<VoiceAgentResponse> getAgentsByTopic(VoiceAgentTopic topic) {
    return agents.where((agent) => agent.topic == topic.value).toList();
  }

  /// Get active agents only
  List<VoiceAgentResponse> get activeAgents {
    return agents.where((agent) => agent.isActive).toList();
  }

  @override
  String toString() {
    return 'VoiceAgentsResponse{agents: ${agents.length}}';
  }
}

/// Start Topic Request - Matches POST /voice/topic/start request
class StartTopicRequest {
  final int agentId;

  StartTopicRequest({
    required this.agentId,
  });

  Map<String, dynamic> toJson() {
    return {
      'agent_id': agentId,
    };
  }

  @override
  String toString() {
    return 'StartTopicRequest{agentId: $agentId}';
  }
}

/// Voice Agent Info - Used in start topic response
class VoiceAgentInfo {
  final int id;
  final String topic;
  final String title;
  final String agentId;

  VoiceAgentInfo({
    required this.id,
    required this.topic,
    required this.title,
    required this.agentId,
  });

  factory VoiceAgentInfo.fromJson(Map<String, dynamic> json) {
    return VoiceAgentInfo(
      id: json['id'],
      topic: json['topic'],
      title: json['title'],
      agentId: json['agent_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topic': topic,
      'title': title,
      'agent_id': agentId,
    };
  }

  VoiceAgentTopic get topicEnum => VoiceAgentTopic.fromString(topic);

  @override
  String toString() {
    return 'VoiceAgentInfo{id: $id, topic: $topic, title: $title, agentId: $agentId}';
  }
}

/// Start Topic Response - Matches POST /voice/topic/start response
class StartTopicResponse {
  final String sessionId;
  final VoiceAgentInfo agent;
  final String websocketUrl;
  final String connectionExpiresAt;

  StartTopicResponse({
    required this.sessionId,
    required this.agent,
    required this.websocketUrl,
    required this.connectionExpiresAt,
  });

  factory StartTopicResponse.fromJson(Map<String, dynamic> json) {
    return StartTopicResponse(
      sessionId: json['session_id'],
      agent: VoiceAgentInfo.fromJson(json['agent']),
      websocketUrl: json['websocket_url'],
      connectionExpiresAt: json['connection_expires_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'agent': agent.toJson(),
      'websocket_url': websocketUrl,
      'connection_expires_at': connectionExpiresAt,
    };
  }

  DateTime get expiresAt => DateTime.parse(connectionExpiresAt);

  @override
  String toString() {
    return 'StartTopicResponse{sessionId: $sessionId, agent: $agent, websocketUrl: $websocketUrl, connectionExpiresAt: $connectionExpiresAt}';
  }
}

/// Stop Topic Request - Matches POST /voice/topic/stop request
class StopTopicRequest {
  final String sessionId;

  StopTopicRequest({
    required this.sessionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
    };
  }

  @override
  String toString() {
    return 'StopTopicRequest{sessionId: $sessionId}';
  }
}

/// Voice Session Stats - Used in stop topic response
class VoiceSessionStats {
  final String sessionId;
  final int duration;
  final String topic;
  final String startedAt;
  final String endedAt;

  VoiceSessionStats({
    required this.sessionId,
    required this.duration,
    required this.topic,
    required this.startedAt,
    required this.endedAt,
  });

  factory VoiceSessionStats.fromJson(Map<String, dynamic> json) {
    return VoiceSessionStats(
      sessionId: json['session_id'],
      duration: json['duration'],
      topic: json['topic'],
      startedAt: json['started_at'],
      endedAt: json['ended_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'duration': duration,
      'topic': topic,
      'started_at': startedAt,
      'ended_at': endedAt,
    };
  }

  VoiceAgentTopic get topicEnum => VoiceAgentTopic.fromString(topic);

  /// Format duration for display
  String get formattedDuration {
    if (duration < 60) {
      return '${duration}s';
    } else if (duration < 3600) {
      final minutes = duration ~/ 60;
      final seconds = duration % 60;
      return '${minutes}m ${seconds}s';
    } else {
      final hours = duration ~/ 3600;
      final minutes = (duration % 3600) ~/ 60;
      return '${hours}h ${minutes}m';
    }
  }

  DateTime get startedAtDateTime => DateTime.parse(startedAt);
  DateTime get endedAtDateTime => DateTime.parse(endedAt);

  @override
  String toString() {
    return 'VoiceSessionStats{sessionId: $sessionId, duration: $duration, topic: $topic, startedAt: $startedAt, endedAt: $endedAt}';
  }
}

/// Stop Topic Response - Matches POST /voice/topic/stop response
class StopTopicResponse {
  final bool success;
  final String message;
  final VoiceSessionStats sessionStats;

  StopTopicResponse({
    required this.success,
    required this.message,
    required this.sessionStats,
  });

  factory StopTopicResponse.fromJson(Map<String, dynamic> json) {
    return StopTopicResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      sessionStats: VoiceSessionStats.fromJson(json['session_stats']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'session_stats': sessionStats.toJson(),
    };
  }

  @override
  String toString() {
    return 'StopTopicResponse{success: $success, message: $message, sessionStats: $sessionStats}';
  }
}

/// Local Voice Session State - For client-side voice session management
class LocalVoiceSession {
  final String sessionId;
  final VoiceAgentInfo agent;
  final String websocketUrl;
  final DateTime startedAt;
  final DateTime expiresAt;
  final VoiceSessionStatus status;
  final List<VoiceMessage> messages;

  LocalVoiceSession({
    required this.sessionId,
    required this.agent,
    required this.websocketUrl,
    required this.startedAt,
    required this.expiresAt,
    required this.status,
    this.messages = const [],
  });

  factory LocalVoiceSession.fromStartResponse(StartTopicResponse response) {
    return LocalVoiceSession(
      sessionId: response.sessionId,
      agent: response.agent,
      websocketUrl: response.websocketUrl,
      startedAt: DateTime.now(),
      expiresAt: response.expiresAt,
      status: VoiceSessionStatus.connecting,
    );
  }

  Duration get duration => DateTime.now().difference(startedAt);
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isActive => status == VoiceSessionStatus.connected;

  LocalVoiceSession copyWith({
    String? sessionId,
    VoiceAgentInfo? agent,
    String? websocketUrl,
    DateTime? startedAt,
    DateTime? expiresAt,
    VoiceSessionStatus? status,
    List<VoiceMessage>? messages,
  }) {
    return LocalVoiceSession(
      sessionId: sessionId ?? this.sessionId,
      agent: agent ?? this.agent,
      websocketUrl: websocketUrl ?? this.websocketUrl,
      startedAt: startedAt ?? this.startedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      messages: messages ?? List.from(this.messages),
    );
  }

  LocalVoiceSession addMessage(VoiceMessage message) {
    return copyWith(messages: [...messages, message]);
  }

  @override
  String toString() {
    return 'LocalVoiceSession{sessionId: $sessionId, agent: $agent, websocketUrl: $websocketUrl, startedAt: $startedAt, expiresAt: $expiresAt, status: $status, messages: ${messages.length}}';
  }
}

/// Voice Session Status
enum VoiceSessionStatus {
  connecting,
  connected,
  disconnected,
  error,
  expired,
}

/// Voice Message - For chat-like interface
class VoiceMessage {
  final String id;
  final VoiceMessageType type;
  final String content;
  final DateTime timestamp;
  final VoiceMessageStatus status;

  VoiceMessage({
    required this.id,
    required this.type,
    required this.content,
    required this.timestamp,
    this.status = VoiceMessageStatus.sent,
  });

  factory VoiceMessage.user(String content) {
    return VoiceMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: VoiceMessageType.user,
      content: content,
      timestamp: DateTime.now(),
    );
  }

  factory VoiceMessage.agent(String content) {
    return VoiceMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: VoiceMessageType.agent,
      content: content,
      timestamp: DateTime.now(),
    );
  }

  factory VoiceMessage.system(String content) {
    return VoiceMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: VoiceMessageType.system,
      content: content,
      timestamp: DateTime.now(),
    );
  }

  VoiceMessage copyWith({
    String? id,
    VoiceMessageType? type,
    String? content,
    DateTime? timestamp,
    VoiceMessageStatus? status,
  }) {
    return VoiceMessage(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'VoiceMessage{id: $id, type: $type, content: $content, timestamp: $timestamp, status: $status}';
  }
}

/// Voice Message Type
enum VoiceMessageType {
  user,
  agent,
  system,
}

/// Voice Message Status
enum VoiceMessageStatus {
  sending,
  sent,
  delivered,
  error,
}

/// WebSocket Message Types - For ElevenLabs integration
class WebSocketMessage {
  final String type;
  final Map<String, dynamic> data;

  WebSocketMessage({
    required this.type,
    required this.data,
  });

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: json['type'] ?? '',
      data: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      ...data,
    };
  }

  @override
  String toString() {
    return 'WebSocketMessage{type: $type, data: $data}';
  }
}

/// Audio Event - For handling ElevenLabs audio responses
class AudioEvent {
  final String audioBase64;
  final int eventId;

  AudioEvent({
    required this.audioBase64,
    required this.eventId,
  });

  factory AudioEvent.fromJson(Map<String, dynamic> json) {
    return AudioEvent(
      audioBase64: json['audio_base_64'] ?? '',
      eventId: json['event_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'audio_base_64': audioBase64,
      'event_id': eventId,
    };
  }

  @override
  String toString() {
    return 'AudioEvent{audioBase64: ${audioBase64.substring(0, 20)}..., eventId: $eventId}';
  }
}

/// Agent Response Event - For handling ElevenLabs text responses
class AgentResponseEvent {
  final String agentResponse;

  AgentResponseEvent({
    required this.agentResponse,
  });

  factory AgentResponseEvent.fromJson(Map<String, dynamic> json) {
    return AgentResponseEvent(
      agentResponse: json['agent_response'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agent_response': agentResponse,
    };
  }

  @override
  String toString() {
    return 'AgentResponseEvent{agentResponse: $agentResponse}';
  }
}

/// User Transcription Event - For handling user speech transcription
class UserTranscriptionEvent {
  final String userTranscript;

  UserTranscriptionEvent({
    required this.userTranscript,
  });

  factory UserTranscriptionEvent.fromJson(Map<String, dynamic> json) {
    return UserTranscriptionEvent(
      userTranscript: json['user_transcript'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_transcript': userTranscript,
    };
  }

  @override
  String toString() {
    return 'UserTranscriptionEvent{userTranscript: $userTranscript}';
  }
}