import 'package:get/get.dart';
import 'package:yodla_app/app/bindings/splash_binding.dart';

import '../bindings/auth_binding.dart';
import '../bindings/home_binding.dart';
import '../bindings/folder_binding.dart';
import '../bindings/word_binding.dart';
import '../bindings/quiz_binding.dart';
import '../bindings/voice_binding.dart';

import '../views/auth/splash_view.dart';
import '../views/auth/login_view.dart';
import '../views/home/home_view.dart';
import '../views/home/dashboard_view.dart';
import '../views/folders/folders_view.dart';
import '../views/folders/folder_detail_view.dart';
import '../views/folders/create_folder_view.dart';
import '../views/words/add_word_view.dart';
import '../views/words/word_detail_view.dart';
import '../views/words/ocr_camera_view.dart';
import '../views/words/ocr_results_view.dart';
import '../views/quiz/quiz_home_view.dart';
import '../views/quiz/quiz_play_view.dart';
import '../views/quiz/quiz_results_view.dart';
import '../views/voice/voice_agents_view.dart';
import '../views/voice/voice_chat_view.dart';
import '../views/profile/profile_view.dart';
import '../views/profile/settings_view.dart';

import 'app_routes.dart';

class AppPages {
  AppPages._();

  static const String initial = AppRoutes.splash;

  static final List<GetPage> routes = [
    // Authentication routes
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => LoginView(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Main app routes
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    // GetPage(
    //   name: AppRoutes.dashboard,
    //   page: () => const DashboardView(),
    //   binding: HomeBinding(),
    //   transition: Transition.rightToLeft,
    //   transitionDuration: const Duration(milliseconds: 300),
    // ),
    //
    // // Folder routes
    // GetPage(
    //   name: AppRoutes.folders,
    //   page: () => const FoldersView(),
    //   binding: FolderBinding(),
    //   transition: Transition.rightToLeft,
    //   transitionDuration: const Duration(milliseconds: 300),
    // ),
    // GetPage(
    //   name: AppRoutes.folderDetail,
    //   page: () => const FolderDetailView(),
    //   binding: FolderBinding(),
    //   transition: Transition.rightToLeft,
    //   transitionDuration: const Duration(milliseconds: 300),
    // ),
    // GetPage(
    //   name: AppRoutes.createFolder,
    //   page: () => const CreateFolderView(),
    //   binding: FolderBinding(),
    //   transition: Transition.downToUp,
    //   transitionDuration: const Duration(milliseconds: 300),
    // ),
    //
    // // Word routes
    // GetPage(
    //   name: AppRoutes.addWord,
    //   page: () => const AddWordView(),
    //   binding: WordBinding(),
    //   transition: Transition.downToUp,
    //   transitionDuration: const Duration(milliseconds: 300),
    // ),
    // GetPage(
    //   name: AppRoutes.wordDetail,
    //   page: () => const WordDetailView(),
    //   binding: WordBinding(),
    //   transition: Transition.rightToLeft,
    //   transitionDuration: const Duration(milliseconds: 300),
    // ),
    // GetPage(
    //   name: AppRoutes.ocrCamera,
    //   page: () => const OCRCameraView(),
    //   binding: WordBinding(),
    //   transition: Transition.downToUp,
    //   transitionDuration: const Duration(milliseconds: 300),
    // ),
    // GetPage(
    //   name: AppRoutes.ocrResults,
    //   page: () => const OCRResultsView(),
    //   binding: WordBinding(),
    //   transition: Transition.rightToLeft,
    //   transitionDuration: const Duration(milliseconds: 300),
    // ),
    //
    // // Quiz routes
    // GetPage(
    //   name: AppRoutes.quizHome,
    //   page: () => const QuizHomeView(),
    //   binding: QuizBinding(),
    //   transition: Transition.rightToLeft,
    //   transitionDuration: const Duration(milliseconds: 300),
    // ),
    // GetPage(
    //   name: AppRoutes.quizPlay,
    //   page: () => const QuizPlayView(),
    //   binding: QuizBinding(),
    //   transition: Transition.rightToLeft,
    //   transitionDuration: const Duration(milliseconds: 300),
    // ),
    // GetPage(
    //   name: AppRoutes.quizResults,
    //   page: () => const QuizResultsView(),
    //   binding: QuizBinding(),
    //   transition: Transition.rightToLeft,
    //   transitionDuration: const Duration(milliseconds: 300),
    // ),
    //
    // // Voice routes
    // GetPage(
    //   name: AppRoutes.voiceAgents,
    //   page: () => const VoiceAgentsView(),
    //   binding: VoiceBinding(),
    //   transition: Transition.rightToLeft,
    //   transitionDuration: const Duration(milliseconds: 300),
    // ),
    // GetPage(
    //   name: AppRoutes.voiceChat,
    //   page: () => const VoiceChatView(),
    //   binding: VoiceBinding(),
    //   transition: Transition.rightToLeft,
    //   transitionDuration: const Duration(milliseconds: 300),
    // ),
    //
    // // Profile routes
    // GetPage(
    //   name: AppRoutes.profile,
    //   page: () => const ProfileView(),
    //   binding: HomeBinding(),
    //   transition: Transition.rightToLeft,
    //   transitionDuration: const Duration(milliseconds: 300),
    // ),
    // GetPage(
    //   name: AppRoutes.settings,
    //   page: () => const SettingsView(),
    //   binding: HomeBinding(),
    //   transition: Transition.rightToLeft,
    //   transitionDuration: const Duration(milliseconds: 300),
    // ),
  ];
}