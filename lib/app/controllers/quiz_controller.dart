import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/api_response_model.dart';
import '../models/quiz_model.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class QuizController extends GetxController {
  late ApiService _apiService;

  // Observable states
  final RxBool _isLoading = false.obs;
  final RxBool _isStarting = false.obs;
  final RxBool _isSubmitting = false.obs;
  final RxBool _isCompleting = false.obs;
  final Rx<LocalQuizSession?> _currentSession = Rx<LocalQuizSession?>(null);
  final Rx<QuizQuestion?> _currentQuestion = Rx<QuizQuestion?>(null);
  final RxString _userAnswer = ''.obs;
  final RxList<String> _shuffledOptions = <String>[].obs;

  // Timer for quiz questions
  Timer? _questionTimer;
  final RxInt _timeRemaining = 0.obs;
  final RxInt _questionStartTime = 0.obs;

  // Quiz statistics
  final RxInt _correctAnswers = 0.obs;
  final RxInt _totalQuestions = 0.obs;
  final RxInt _totalTime = 0.obs;

  // Quiz results
  final Rx<CompleteQuizResponse?> _lastQuizResults = Rx<CompleteQuizResponse?>(null);

  // Getters
  bool get isLoading => _isLoading.value;
  bool get isStarting => _isStarting.value;
  bool get isSubmitting => _isSubmitting.value;
  bool get isCompleting => _isCompleting.value;
  LocalQuizSession? get currentSession => _currentSession.value;
  QuizQuestion? get currentQuestion => _currentQuestion.value;
  String get userAnswer => _userAnswer.value;
  List<String> get shuffledOptions => _shuffledOptions.toList();
  int get timeRemaining => _timeRemaining.value;
  int get correctAnswers => _correctAnswers.value;
  int get totalQuestions => _totalQuestions.value;
  int get totalTime => _totalTime.value;
  CompleteQuizResponse? get lastQuizResults => _lastQuizResults.value;

  // Computed properties
  bool get hasActiveQuiz => _currentSession.value != null;
  bool get isQuizComplete => _currentSession.value?.isComplete ?? false;
  int get currentQuestionNumber => (_currentSession.value?.currentQuestionIndex ?? 0) + 1;
  int get answeredQuestions => _currentSession.value?.answeredQuestions ?? 0;
  double get progress => totalQuestions > 0 ? (answeredQuestions / totalQuestions) : 0.0;
  double get accuracy => answeredQuestions > 0 ? (correctAnswers / answeredQuestions) * 100 : 0.0;

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
  }

  @override
  void onClose() {
    _stopQuestionTimer();
    super.onClose();
  }

  /// Start a new quiz
  Future<void> startQuiz(int folderId, QuizType quizType) async {
    try {
      if (_isStarting.value) return;

      _isStarting.value = true;
      _clearQuizState();

      AppHelpers.logUserAction('start_quiz_attempt', {
        'folder_id': folderId,
        'quiz_type': quizType.value,
      });

      final request = StartQuizRequest.fromType(quizType);
      final response = await _apiService.post<StartQuizResponse>(
        ApiEndpoints.startQuiz(folderId),
        data: request.toJson(),
        fromJson: (json) => StartQuizResponse.fromJson(json),
      );

      if (response.success && response.data != null) {
        // Create local quiz session
        _currentSession.value = LocalQuizSession(
          sessionId: response.data!.session.sessionId,
          quizType: quizType,
          folderId: folderId,
          questions: [response.data!.question],
          startedAt: DateTime.now(),
        );

        // Set up first question
        _setupQuestion(response.data!.question);
        _totalQuestions.value = response.data!.session.totalQuestions;

        AppHelpers.logUserAction('start_quiz_success', {
          'session_id': response.data!.session.sessionId,
          'folder_id': folderId,
          'quiz_type': quizType.value,
          'total_questions': response.data!.session.totalQuestions,
        });

        AppHelpers.showSuccessSnackbar(
          'Quiz started! Answer ${response.data!.session.totalQuestions} questions.',
          title: '${_getQuizTypeDisplayName(quizType)} Quiz',
        );
      } else {
        AppHelpers.logUserAction('start_quiz_failed', {
          'folder_id': folderId,
          'quiz_type': quizType.value,
          'error': response.error,
        });

        AppHelpers.showErrorSnackbar(
          response.error ?? 'Failed to start quiz',
          title: 'Quiz Start Failed',
        );
      }
    } catch (e) {
      AppHelpers.logUserAction('start_quiz_exception', {
        'folder_id': folderId,
        'quiz_type': quizType.value,
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'An unexpected error occurred while starting quiz',
        title: 'Quiz Error',
      );
    } finally {
      _isStarting.value = false;
    }
  }

  /// Set up a question
  void _setupQuestion(QuizQuestion question) {
    _currentQuestion.value = question;
    _userAnswer.value = '';
    _questionStartTime.value = DateTime.now().millisecondsSinceEpoch;
    _timeRemaining.value = question.timeLimit;

    // Setup options for multiple choice questions
    if (question.options != null) {
      _shuffledOptions.assignAll(question.options!);
    } else {
      _shuffledOptions.clear();
    }

    // Start question timer
    _startQuestionTimer();

    AppHelpers.logUserAction('question_setup', {
      'question_number': question.questionNumber,
      'word_id': question.wordId,
      'quiz_type': _currentSession.value?.quizType.value,
      'time_limit': question.timeLimit,
    });
  }

  /// Start question timer
  void _startQuestionTimer() {
    _stopQuestionTimer();

    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining.value > 0) {
        _timeRemaining.value--;
      } else {
        // Time's up - auto submit
        _autoSubmitAnswer();
        timer.cancel();
      }
    });
  }

  /// Stop question timer
  void _stopQuestionTimer() {
    _questionTimer?.cancel();
    _questionTimer = null;
  }

  /// Auto submit answer when time runs out
  void _autoSubmitAnswer() {
    if (_currentQuestion.value != null && !_isSubmitting.value) {
      AppHelpers.logUserAction('auto_submit_answer', {
        'question_number': _currentQuestion.value!.questionNumber,
        'time_remaining': _timeRemaining.value,
      });

      AppHelpers.showWarningSnackbar(
        'Time\'s up! Moving to next question.',
        title: 'Time Up',
      );

      submitAnswer(_userAnswer.value.isEmpty ? '' : _userAnswer.value);
    }
  }

  /// Submit answer for current question
  Future<void> submitAnswer(String answer) async {
    try {
      if (_isSubmitting.value || _currentQuestion.value == null || _currentSession.value == null) {
        return;
      }

      _isSubmitting.value = true;
      _stopQuestionTimer();

      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final timeTaken = ((currentTime - _questionStartTime.value) / 1000).round();

      final request = SubmitAnswerRequest(
        wordId: _currentQuestion.value!.wordId,
        answer: answer,
        timeTaken: timeTaken,
      );

      AppHelpers.logUserAction('submit_answer_attempt', {
        'session_id': _currentSession.value!.sessionId,
        'question_number': _currentQuestion.value!.questionNumber,
        'word_id': _currentQuestion.value!.wordId,
        'answer': answer,
        'time_taken': timeTaken,
      });

      final response = await _apiService.post<SubmitAnswerResponse>(
        ApiEndpoints.submitAnswer(_currentSession.value!.sessionId),
        data: request.toJson(),
        fromJson: (json) => SubmitAnswerResponse.fromJson(json),
      );

      if (response.success && response.data != null) {
        final isCorrect = response.data!.isCorrect;
        final correctAnswer = response.data!.correctAnswer;

        // Update local statistics
        if (isCorrect) {
          _correctAnswers.value++;
        }
        _totalTime.value += timeTaken;

        // Create quiz answer
        final quizAnswer = QuizAnswer.fromResponse(
          _currentQuestion.value!.wordId,
          answer,
          timeTaken,
          response.data!,
        );

        // Update session
        _currentSession.value = _currentSession.value!.copyWith(
          answers: [..._currentSession.value!.answers, quizAnswer],
          currentQuestionIndex: _currentSession.value!.currentQuestionIndex + 1,
        );

        AppHelpers.logUserAction('submit_answer_success', {
          'session_id': _currentSession.value!.sessionId,
          'question_number': _currentQuestion.value!.questionNumber,
          'is_correct': isCorrect,
          'correct_answer': correctAnswer,
          'time_taken': timeTaken,
        });

        // Show feedback
        _showAnswerFeedback(isCorrect, correctAnswer, response.data!.explanation);

        // Setup next question or complete quiz
        if (response.data!.nextQuestion != null) {
          // Delay before showing next question
          await Future.delayed(const Duration(seconds: 2));
          _setupQuestion(response.data!.nextQuestion!);
        } else {
          // Quiz complete
          await Future.delayed(const Duration(seconds: 2));
          await completeQuiz();
        }
      } else {
        AppHelpers.logUserAction('submit_answer_failed', {
          'session_id': _currentSession.value!.sessionId,
          'error': response.error,
        });

        AppHelpers.showErrorSnackbar(
          response.error ?? 'Failed to submit answer',
          title: 'Submit Failed',
        );
      }
    } catch (e) {
      AppHelpers.logUserAction('submit_answer_exception', {
        'session_id': _currentSession.value?.sessionId,
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'An unexpected error occurred while submitting answer',
        title: 'Submit Error',
      );
    } finally {
      _isSubmitting.value = false;
    }
  }

  /// Show answer feedback
  void _showAnswerFeedback(bool isCorrect, String correctAnswer, String? explanation) {
    final icon = isCorrect ? Icons.check_circle : Icons.cancel;
    final color = isCorrect ? AppColors.success : AppColors.error;
    final title = isCorrect ? 'Correct!' : 'Incorrect';

    String message = isCorrect
        ? 'Well done!'
        : 'The correct answer is: $correctAnswer';

    if (explanation != null && explanation.isNotEmpty) {
      message += '\n$explanation';
    }

    Get.snackbar(
      title,
      message,
      backgroundColor: color,
      colorText: Colors.white,
      icon: Icon(icon, color: Colors.white),
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );

    // Haptic feedback
    AppHelpers.hapticFeedback();
  }

  /// Complete the quiz
  Future<void> completeQuiz() async {
    try {
      if (_isCompleting.value || _currentSession.value == null) {
        return;
      }

      _isCompleting.value = true;

      AppHelpers.logUserAction('complete_quiz_attempt', {
        'session_id': _currentSession.value!.sessionId,
        'answered_questions': _currentSession.value!.answeredQuestions,
        'correct_answers': _correctAnswers.value,
      });

      final response = await _apiService.post<CompleteQuizResponse>(
        ApiEndpoints.completeQuiz(_currentSession.value!.sessionId),
        fromJson: (json) => CompleteQuizResponse.fromJson(json),
      );

      if (response.success && response.data != null) {
        _lastQuizResults.value = response.data!;

        AppHelpers.logUserAction('complete_quiz_success', {
          'session_id': _currentSession.value!.sessionId,
          'final_score': response.data!.results.accuracy,
          'total_time': response.data!.results.totalTime,
          'updated_categories': response.data!.updatedCategories.length,
        });

        AppHelpers.showSuccessSnackbar(
          'Quiz completed! Score: ${response.data!.results.accuracy}%',
          title: 'Quiz Complete',
        );

        // Navigate to results screen
        Get.offNamed(AppRoutes.quizResults);
      } else {
        AppHelpers.logUserAction('complete_quiz_failed', {
          'session_id': _currentSession.value!.sessionId,
          'error': response.error,
        });

        AppHelpers.showErrorSnackbar(
          response.error ?? 'Failed to complete quiz',
          title: 'Complete Failed',
        );
      }
    } catch (e) {
      AppHelpers.logUserAction('complete_quiz_exception', {
        'session_id': _currentSession.value?.sessionId,
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'An unexpected error occurred while completing quiz',
        title: 'Complete Error',
      );
    } finally {
      _isCompleting.value = false;
    }
  }

  /// Set user answer
  void setUserAnswer(String answer) {
    _userAnswer.value = answer;

    AppHelpers.logUserAction('user_answer_set', {
      'question_number': _currentQuestion.value?.questionNumber,
      'answer_length': answer.length,
    });
  }

  /// Select multiple choice option
  void selectOption(String option) {
    setUserAnswer(option);

    AppHelpers.logUserAction('option_selected', {
      'question_number': _currentQuestion.value?.questionNumber,
      'selected_option': option,
    });

    // Auto-submit for multiple choice after small delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_userAnswer.value == option && !_isSubmitting.value) {
        submitAnswer(option);
      }
    });
  }

  /// Quit quiz
  Future<void> quitQuiz() async {
    try {
      if (_currentSession.value == null) return;

      final confirmed = await AppHelpers.showConfirmationDialog(
        title: 'Quit Quiz',
        message: 'Are you sure you want to quit the quiz? Your progress will be lost.',
        confirmText: 'Quit',
        cancelText: 'Continue',
        confirmColor: Colors.red,
      );

      if (!confirmed) return;

      AppHelpers.logUserAction('quit_quiz', {
        'session_id': _currentSession.value!.sessionId,
        'answered_questions': _currentSession.value!.answeredQuestions,
        'quiz_type': _currentSession.value!.quizType.value,
      });

      _clearQuizState();
      Get.back();

      AppHelpers.showInfoSnackbar(
        'Quiz cancelled',
        title: 'Quiz Cancelled',
      );
    } catch (e) {
      AppHelpers.logUserAction('quit_quiz_exception', {
        'error': e.toString(),
      });
    }
  }

  /// Clear quiz state
  void _clearQuizState() {
    _stopQuestionTimer();
    _currentSession.value = null;
    _currentQuestion.value = null;
    _userAnswer.value = '';
    _shuffledOptions.clear();
    _timeRemaining.value = 0;
    _questionStartTime.value = 0;
    _correctAnswers.value = 0;
    _totalQuestions.value = 0;
    _totalTime.value = 0;
  }

  /// Get quiz type display name
  String _getQuizTypeDisplayName(QuizType type) {
    switch (type) {
      case QuizType.anagram:
        return 'Anagram Attack';
      case QuizType.translationBlitz:
        return 'Translation Blitz';
      case QuizType.wordBlitz:
        return 'Word Blitz';
      case QuizType.reading:
        return 'Reading Comprehension';
    }
  }

  /// Get quiz type description
  String getQuizTypeDescription(QuizType type) {
    switch (type) {
      case QuizType.anagram:
        return 'Unscramble English letters using Uzbek translation as hint';
      case QuizType.translationBlitz:
        return 'See Uzbek translation, choose correct English word';
      case QuizType.wordBlitz:
        return 'See example sentence, choose word that fits';
      case QuizType.reading:
        return 'Fill in the blanks in AI-generated passages';
    }
  }

  /// Get quiz type icon
  IconData getQuizTypeIcon(QuizType type) {
    switch (type) {
      case QuizType.anagram:
        return Icons.shuffle;
      case QuizType.translationBlitz:
        return Icons.translate;
      case QuizType.wordBlitz:
        return Icons.flash_on;
      case QuizType.reading:
        return Icons.menu_book;
    }
  }

  /// Get quiz type color
  Color getQuizTypeColor(QuizType type) {
    return AppHelpers.getQuizTypeColor(type);
  }

  /// Get formatted time remaining
  String get formattedTimeRemaining {
    final minutes = _timeRemaining.value ~/ 60;
    final seconds = _timeRemaining.value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get time remaining percentage
  double get timeRemainingPercentage {
    if (_currentQuestion.value == null) return 0.0;
    return _timeRemaining.value / _currentQuestion.value!.timeLimit;
  }

  /// Check if time is running low
  bool get isTimeRunningLow {
    return _timeRemaining.value <= 10;
  }

  /// Get current quiz type display name
  String get currentQuizTypeDisplayName {
    if (_currentSession.value == null) return '';
    return _getQuizTypeDisplayName(_currentSession.value!.quizType);
  }

  /// Get performance rating based on accuracy
  String getPerformanceRating(double accuracy) {
    if (accuracy >= 90) return 'Excellent';
    if (accuracy >= 80) return 'Great';
    if (accuracy >= 70) return 'Good';
    if (accuracy >= 60) return 'Fair';
    return 'Needs Practice';
  }

  /// Get performance color based on accuracy
  Color getPerformanceColor(double accuracy) {
    if (accuracy >= 80) return AppColors.success;
    if (accuracy >= 60) return AppColors.warning;
    return AppColors.error;
  }

  /// Restart quiz
  Future<void> restartQuiz() async {
    if (_currentSession.value == null) return;

    final confirmed = await AppHelpers.showConfirmationDialog(
      title: 'Restart Quiz',
      message: 'Are you sure you want to restart the quiz? Your current progress will be lost.',
      confirmText: 'Restart',
      cancelText: 'Continue',
    );

    if (!confirmed) return;

    final folderId = _currentSession.value!.folderId;
    final quizType = _currentSession.value!.quizType;

    AppHelpers.logUserAction('restart_quiz', {
      'session_id': _currentSession.value!.sessionId,
      'folder_id': folderId,
      'quiz_type': quizType.value,
    });

    await startQuiz(folderId, quizType);
  }

  /// Navigate to quiz home
  void navigateToQuizHome(int folderId) {
    Get.toNamed(AppRoutes.quizHome, arguments: folderId);
    AppHelpers.logUserAction('navigate_to_quiz_home', {
      'folder_id': folderId,
    });
  }

  /// Navigate back to folder
  void navigateBackToFolder() {
    if (_currentSession.value != null) {
      Get.offAllNamed(AppRoutes.folderDetail, arguments: _currentSession.value!.folderId);
    } else {
      Get.back();
    }
  }

  /// Get quiz summary for results
  Map<String, dynamic> get quizSummary {
    if (_lastQuizResults.value == null) return {};

    final results = _lastQuizResults.value!.results;
    return {
      'quiz_type': _getQuizTypeDisplayName(results.quizTypeEnum),
      'total_questions': results.totalQuestions,
      'correct_answers': results.correctAnswers,
      'accuracy': results.accuracy,
      'total_time': results.formattedTime,
      'performance_rating': getPerformanceRating(results.accuracy.toDouble()),
      'improvement': _lastQuizResults.value!.performance.improvement,
      'strongest_words': _lastQuizResults.value!.performance.strongestWords,
      'needs_practice': _lastQuizResults.value!.performance.needsPractice,
    };
  }

  /// Share quiz results
  Future<void> shareQuizResults() async {
    if (_lastQuizResults.value == null) return;

    try {
      final results = _lastQuizResults.value!.results;
      final performance = _lastQuizResults.value!.performance;

      final shareText = '''
🎯 Quiz Results - ${_getQuizTypeDisplayName(results.quizTypeEnum)}

📊 Score: ${results.correctAnswers}/${results.totalQuestions} (${results.accuracy}%)
⏱️ Time: ${results.formattedTime}
🏆 Rating: ${getPerformanceRating(results.accuracy.toDouble())}

💪 Strongest Words: ${performance.strongestWords.take(3).join(', ')}
📚 Need Practice: ${performance.needsPractice.take(3).join(', ')}

Keep learning with Vocabulary App! 🚀
''';

      await AppHelpers.copyToClipboard(shareText);

      AppHelpers.logUserAction('quiz_results_shared', {
        'session_id': results.sessionId,
        'accuracy': results.accuracy,
      });
    } catch (e) {
      AppHelpers.logUserAction('share_quiz_results_exception', {
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'Failed to share quiz results',
        title: 'Share Error',
      );
    }
  }
}