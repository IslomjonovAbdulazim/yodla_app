// lib/app/utils/mock_voice_data.dart
import '../controllers/voice_controller.dart';
import '../models/voice_agent_model.dart';

class MockVoiceData {
  static List<VoiceAgentResponse> getMockAgents() {
    return [
      VoiceAgentResponse(
        id: 1,
        topic: "cars",
        title: "Car Expert",
        description: "Discuss everything about automobiles, engines, driving techniques, maintenance, and automotive industry news",
        imageUrl: "https://images.unsplash.com/photo-1550355291-bbee04a92027?w=400",
        agentId: "agent_3201k0xj8t6jfra8na00s910sah7",
        isActive: true,
      ),
      VoiceAgentResponse(
        id: 2,
        topic: "travel",
        title: "Travel Guide",
        description: "Explore destinations, cultural insights, travel planning, transportation, accommodation, and local cuisine",
        imageUrl: "https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=400",
        agentId: "agent_3901k0xawmnpermr2vgy4d6ewza3",
        isActive: true,
      ),
      VoiceAgentResponse(
        id: 3,
        topic: "football",
        title: "Football Coach",
        description: "Master soccer tactics, formations, player analysis, match predictions, training techniques, and football history",
        imageUrl: "https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=400",
        agentId: "agent_01k0rx0fe8fz6tfyj1n5w7ek80",
        isActive: true,
      ),
    ];
  }

  static VoiceAgentsResponse getMockAgentsResponse() {
    return VoiceAgentsResponse(agents: getMockAgents());
  }
}

// Extension to VoiceController for testing with mock data
extension VoiceControllerMocking on VoiceController {
  void loadMockAgents() {
    final mockAgents = MockVoiceData.getMockAgents();
    // This would be used in VoiceController's loadVoiceAgents method
    // if you want to test with mock data when API is unavailable
  }
}