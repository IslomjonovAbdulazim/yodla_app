abstract class AppRoutes {
  // Authentication routes
  static const String splash = '/splash';
  static const String login = '/login';

  // Main app routes
  static const String home = '/home';
  static const String dashboard = '/dashboard';

  // Folder routes
  static const String folders = '/folders';
  static const String folderDetail = '/folder-detail';
  static const String createFolder = '/create-folder';

  // Word routes
  static const String addWord = '/add-word';
  static const String wordDetail = '/word-detail';
  static const String ocrCamera = '/ocr-camera';
  static const String ocrResults = '/ocr-results';

  // Quiz routes
  static const String quizHome = '/quiz-home';
  static const String quizPlay = '/quiz-play';
  static const String quizResults = '/quiz-results';

  // Voice routes
  static const String voiceAgents = '/voice-agents';
  static const String voiceChat = '/voice-chat';

  // Profile routes
  static const String profile = '/profile';
  static const String settings = '/settings';
}