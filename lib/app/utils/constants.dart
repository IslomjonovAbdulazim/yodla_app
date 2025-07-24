class AppConstants {
  // App Info
  static const String appName = 'Vocabulary Learning';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String baseUrl = 'https://conversationaibackend-production.up.railway.app'; // TODO: Replace with your actual API URL
  static const String apiVersion = 'v1';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Storage Keys
  static const String tokenKey = 'access_token';
  static const String userKey = 'user_data';
  static const String refreshTokenKey = 'refresh_token';

  // Quiz Configuration (matching backend settings)
  static const int minWordsForQuiz = 5;
  static const int minWordsForReading = 8;
  static const Map<String, int> quizTimeLimits = {
    'anagram': 45,
    'translation_blitz': 30,
    'word_blitz': 30,
    'reading': 120,
  };

  // Voice Session
  static const Duration voiceSessionTimeout = Duration(minutes: 30);

  // Image Processing
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];
}

/// API Endpoints - Exact match with backend
class ApiEndpoints {
  // Authentication
  static const String appleSignIn = '/auth/apple-signin';
  static const String testLogin = '/auth/test-login'; // Dev only

  // User Management
  static const String userProfile = '/user/profile';
  static const String updateProfile = '/user/profile';

  // Folder Management
  static const String folders = '/folders';
  static String folderDetail(int folderId) => '/folders/$folderId';
  static String updateFolder(int folderId) => '/folders/$folderId';
  static String deleteFolder(int folderId) => '/folders/$folderId';

  // Word Management
  static String addWord(int folderId) => '/words/$folderId';
  static const String uploadPhoto = '/words/upload-photo';
  static String bulkAddWords(int folderId) => '/words/$folderId/bulk-add';
  static const String bulkDeleteWords = '/words/bulk-delete';
  static const String generateExample = '/words/generate-example';
  static String wordDetail(int wordId) => '/words/$wordId';
  static String updateWord(int wordId) => '/words/$wordId';
  static String deleteWord(int wordId) => '/words/$wordId';

  // Quiz Engine
  static String startQuiz(int folderId) => '/quiz/$folderId/start';
  static String submitAnswer(String sessionId) => '/quiz/$sessionId/answer';
  static String completeQuiz(String sessionId) => '/quiz/$sessionId/complete';

  // Voice Conversation
  static const String voiceAgents = '/voice/agents';
  static const String startVoiceSession = '/voice/topic/start';
  static const String stopVoiceSession = '/voice/topic/stop';
  static const String cleanupVoiceSessions = '/voice/sessions/cleanup';

  // Health Check
  static const String health = '/health';
}

/// Quiz Types - Exact match with backend
enum QuizType {
  anagram('anagram'),
  translationBlitz('translation_blitz'),
  wordBlitz('word_blitz'),
  reading('reading');

  const QuizType(this.value);
  final String value;
}

/// Word Categories - Exact match with backend WordStats
enum WordCategory {
  notKnown('not_known'),
  normal('normal'),
  strong('strong');

  const WordCategory(this.value);
  final String value;

  static WordCategory fromString(String value) {
    switch (value) {
      case 'not_known':
        return WordCategory.notKnown;
      case 'normal':
        return WordCategory.normal;
      case 'strong':
        return WordCategory.strong;
      default:
        return WordCategory.notKnown;
    }
  }
}

/// Voice Agent Topics - Exact match with backend
enum VoiceAgentTopic {
  cars('cars'),
  football('football'),
  travel('travel');

  const VoiceAgentTopic(this.value);
  final String value;

  static VoiceAgentTopic fromString(String value) {
    switch (value) {
      case 'cars':
        return VoiceAgentTopic.cars;
      case 'football':
        return VoiceAgentTopic.football;
      case 'travel':
        return VoiceAgentTopic.travel;
      default:
        return VoiceAgentTopic.cars;
    }
  }
}

/// Regular Expressions for Validation
class AppRegex {
  static final RegExp email = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  static final RegExp englishWord = RegExp(r"^[a-zA-Z\s\-']+$");
  static final RegExp englishText = RegExp(r"^[a-zA-Z0-9\s.,!?\\\-']+$");
}

/// Error Messages
class ErrorMessages {
  static const String networkError = 'Network connection failed';
  static const String serverError = 'Server error occurred';
  static const String unauthorized = 'Authentication failed';
  static const String invalidCredentials = 'Invalid credentials';
  static const String tokenExpired = 'Session expired. Please login again';
  static const String unknownError = 'An unknown error occurred';

  // Validation
  static const String emailRequired = 'Email is required';
  static const String emailInvalid = 'Invalid email format';
  static const String nicknameRequired = 'Nickname is required';
  static const String nicknameTooLong = 'Nickname too long (max 50 characters)';
  static const String folderNameRequired = 'Folder name is required';
  static const String folderNameTooLong = 'Folder name too long (max 100 characters)';
  static const String wordRequired = 'Word is required';
  static const String translationRequired = 'Translation is required';
  static const String invalidEnglishWord = 'Only English letters, spaces, hyphens and apostrophes allowed';
}
