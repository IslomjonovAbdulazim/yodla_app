import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/api_response_model.dart';
import '../models/folder_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class HomeController extends GetxController {
  late ApiService _apiService;
  late AuthService _authService;

  // Observable states
  final RxBool _isLoading = false.obs;
  final RxBool _isRefreshing = false.obs;
  final Rx<UserStats?> _userStats = Rx<UserStats?>(null);
  final RxList<Folder> _recentFolders = <Folder>[].obs;

  // Getters
  bool get isLoading => _isLoading.value;
  bool get isRefreshing => _isRefreshing.value;
  Rx<UserStats?> get userStats => _userStats;
  List<Folder> get recentFolders => _recentFolders.toList();
  RxInt selectedIndex = 0.obs;

  void changeIndex(int index) {
    selectedIndex.value = index;
  }

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    _authService = Get.find<AuthService>();
    _loadInitialData();
  }

  @override
  void onReady() {
    super.onReady();
    // Any additional setup after controller is ready
  }

  /// Load initial data when controller is created
  Future<void> _loadInitialData() async {
    try {
      _isLoading.value = true;

      AppHelpers.logUserAction('home_load_initial_data');

      // Load user stats and recent folders in parallel
      await Future.wait([
        _loadUserStats(),
        _loadRecentFolders(),
      ]);

      AppHelpers.logUserAction('home_initial_data_loaded');
    } catch (e) {
      AppHelpers.logUserAction('home_load_initial_data_error', {
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'Failed to load dashboard data',
        title: 'Loading Error',
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Refresh all data (called by pull-to-refresh)
  Future<void> refreshData() async {
    try {
      _isRefreshing.value = true;

      AppHelpers.logUserAction('home_refresh_data');

      // Refresh user stats and recent folders
      await Future.wait([
        _loadUserStats(),
        _loadRecentFolders(),
      ]);

      AppHelpers.logUserAction('home_data_refreshed');

      AppHelpers.showSuccessSnackbar(
        'Dashboard updated',
        // duration: const Duration(seconds: 1),
      );
    } catch (e) {
      AppHelpers.logUserAction('home_refresh_data_error', {
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'Failed to refresh data',
        title: 'Refresh Error',
      );
    } finally {
      _isRefreshing.value = false;
    }
  }

  /// Load user statistics
  Future<void> _loadUserStats() async {
    try {
      final response = await _authService.getUserStats();

      if (response.success && response.data != null) {
        _userStats.value = response.data;

        AppHelpers.logUserAction('home_user_stats_loaded', {
          'total_words': response.data!.totalWords,
          'total_folders': response.data!.totalFolders,
          'total_quizzes': response.data!.totalQuizzes,
        });
      } else {
        AppHelpers.logUserAction('home_user_stats_load_failed', {
          'error': response.error,
        });

        // Set default stats if loading fails
        _userStats.value = UserStats(
          totalWords: 0,
          totalFolders: 0,
          totalQuizzes: 0,
          wordsByCategory: WordCategoryStats(
            notKnown: 0,
            normal: 0,
            strong: 0,
          ),
        );
      }
    } catch (e) {
      AppHelpers.logUserAction('home_user_stats_exception', {
        'error': e.toString(),
      });

      // Set default stats on exception
      _userStats.value = UserStats(
        totalWords: 0,
        totalFolders: 0,
        totalQuizzes: 0,
        wordsByCategory: WordCategoryStats(
          notKnown: 0,
          normal: 0,
          strong: 0,
        ),
      );
    }
  }

  /// Load recent folders (last 5 folders)
  Future<void> _loadRecentFolders() async {
    try {
      final response = await _apiService.get<List<Folder>>(
        ApiEndpoints.folders,
        fromJson: (json) => (json as List).map((item) => Folder.fromJson(item)).toList(),
      );

      if (response.success && response.data != null) {
        // Take only the first 5 folders for recent display
        final folders = response.data!.take(5).toList();
        _recentFolders.assignAll(folders);

        AppHelpers.logUserAction('home_recent_folders_loaded', {
          'count': folders.length,
        });
      } else {
        AppHelpers.logUserAction('home_recent_folders_load_failed', {
          'error': response.error,
        });

        _recentFolders.clear();
      }
    } catch (e) {
      AppHelpers.logUserAction('home_recent_folders_exception', {
        'error': e.toString(),
      });

      _recentFolders.clear();
    }
  }

  /// Navigate to folder detail
  void navigateToFolder(int folderId) {
    AppHelpers.logUserAction('home_navigate_to_folder', {
      'folder_id': folderId,
    });

    Get.toNamed('/folder-detail', arguments: folderId);
  }

  /// Get greeting message based on time of day
  String getGreetingMessage() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning!';
    } else if (hour < 17) {
      return 'Good afternoon!';
    } else {
      return 'Good evening!';
    }
  }

  /// Get motivational message based on user progress
  String getMotivationalMessage() {
    if (_userStats.value == null) {
      return 'Start your learning journey today!';
    }

    final stats = _userStats.value!;

    if (stats.totalWords == 0) {
      return 'Add your first words to get started!';
    } else if (stats.totalWords < 10) {
      return 'Great start! Keep adding more words.';
    } else if (stats.totalWords < 50) {
      return 'You\'re building a solid vocabulary!';
    } else if (stats.totalWords < 100) {
      return 'Impressive progress! You\'re doing great.';
    } else {
      return 'Amazing! You\'re a vocabulary master!';
    }
  }

  /// Check if user has any folders to show quick actions
  bool get hasFolders => _recentFolders.isNotEmpty;

  /// Check if user can take quizzes (has folders with enough words)
  bool get canTakeQuizzes {
    return _recentFolders.any((folder) =>
    (folder.wordCount ?? 0) >= 5
    );
  }

  /// Get the folder with most words for quiz suggestion
  Folder? get bestFolderForQuiz {
    if (_recentFolders.isEmpty) return null;

    return _recentFolders.reduce((a, b) =>
    (a.wordCount ?? 0) > (b.wordCount ?? 0) ? a : b
    );
  }

  /// Force refresh stats after folder/word operations
  void invalidateStats() {
    _loadUserStats();
  }

  /// Force refresh folders after folder operations
  void invalidateFolders() {
    _loadRecentFolders();
  }

  /// Handle navigation to create first folder
  void createFirstFolder() {
    AppHelpers.logUserAction('home_create_first_folder');
    Get.toNamed('/create-folder');
  }

  /// Handle navigation to take quiz with best folder
  void takeQuizWithBestFolder() {
    final folder = bestFolderForQuiz;
    if (folder != null) {
      AppHelpers.logUserAction('home_take_quiz_best_folder', {
        'folder_id': folder.id,
        'word_count': folder.wordCount,
      });

      Get.toNamed('/quiz-home', arguments: folder.id);
    } else {
      AppHelpers.showWarningSnackbar(
        'Create folders with at least 5 words to take quizzes',
        title: 'No Folders Available',
      );
    }
  }

  /// Handle error states
  void handleError(String message, {String? title}) {
    AppHelpers.showErrorSnackbar(
      message,
      title: title ?? 'Error',
    );
  }

  /// Show app info
  void showAppInfo() {
    Get.dialog(
      AlertDialog(
        title: const Text('VocabMaster'),
        content: const Text(
          'Learn English vocabulary with AI-powered lessons, '
              'interactive quizzes, and voice practice.\n\n'
              'Version 1.0.0',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}