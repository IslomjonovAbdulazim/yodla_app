import '../utils/constants.dart';

/// Quiz Session Model - Exact match with backend QuizSession model
class QuizSession {
  final int id;
  final int userId;
  final int folderId;
  final String quizType;
  final int? duration;
  final DateTime createdAt;

  QuizSession({
    required this.id,
    required this.userId,
    required this.folderId,
    required this.quizType,
    this.duration,
    required this.createdAt,
  });

  factory QuizSession.fromJson(Map<String, dynamic> json) {
    return QuizSession(
      id: json['id'],
      userId: json['user_id'],
      folderId: json['folder_id'],
      quizType: json['quiz_type'],
      duration: json['duration'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'folder_id': folderId,
      'quiz_type': quizType,
      'duration': duration,
      'created_at': createdAt.toIso8601String(),
    };
  }

  QuizType get quizTypeEnum => QuizType.values.firstWhere(
        (type) => type.value == quizType,
    orElse: () => QuizType.anagram,
  );

  @override
  String toString() {
    return 'QuizSession{id: $id, userId: $userId, folderId: $folderId, quizType: $quizType, duration: $duration, createdAt: $createdAt}';
  }
}

/// Quiz Result Model - Exact match with backend QuizResult model
class QuizResult {
  final int id;
  final int sessionId;
  final int wordId;
  final bool isCorrect;
  final int timeTaken;

  QuizResult({
    required this.id,
    required this.sessionId,
    required this.wordId,
    required this.isCorrect,
    required this.timeTaken,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      id: json['id'],
      sessionId: json['session_id'],
      wordId: json['word_id'],
      isCorrect: json['is_correct'],
      timeTaken: json['time_taken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'word_id': wordId,
      'is_correct': isCorrect,
      'time_taken': timeTaken,
    };
  }

  @override
  String toString() {
    return 'QuizResult{id: $id, sessionId: $sessionId, wordId: $wordId, isCorrect: $isCorrect, timeTaken: $timeTaken}';
  }
}

/// Start Quiz Request - Matches POST /quiz/{folder_id}/start request
class StartQuizRequest {
  final String quizType;

  StartQuizRequest({
    required this.quizType,
  });

  factory StartQuizRequest.fromType(QuizType type) {
    return StartQuizRequest(quizType: type.value);
  }

  Map<String, dynamic> toJson() {
    return {
      'quiz_type': quizType,
    };
  }

  @override
  String toString() {
    return 'StartQuizRequest{quizType: $quizType}';
  }
}

/// Quiz Question Model - Used in quiz responses
class QuizQuestion {
  final int questionNumber;
  final int wordId;
  final String question;
  final List<String>? options;
  final String? hint;
  final int timeLimit;

  QuizQuestion({
    required this.questionNumber,
    required this.wordId,
    required this.question,
    this.options,
    this.hint,
    required this.timeLimit,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      questionNumber: json['question_number'],
      wordId: json['word_id'],
      question: json['question'],
      options: json['options'] != null
          ? (json['options'] as List<dynamic>).map((option) => option as String).toList()
          : null,
      hint: json['hint'],
      timeLimit: json['time_limit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_number': questionNumber,
      'word_id': wordId,
      'question': question,
      'options': options,
      'hint': hint,
      'time_limit': timeLimit,
    };
  }

  @override
  String toString() {
    return 'QuizQuestion{questionNumber: $questionNumber, wordId: $wordId, question: $question, options: $options, hint: $hint, timeLimit: $timeLimit}';
  }
}

/// Quiz Session Info - Used in quiz responses
class QuizSessionInfo {
  final String sessionId;
  final String quizType;
  final int folderId;
  final int totalQuestions;

  QuizSessionInfo({
    required this.sessionId,
    required this.quizType,
    required this.folderId,
    required this.totalQuestions,
  });

  factory QuizSessionInfo.fromJson(Map<String, dynamic> json) {
    return QuizSessionInfo(
      sessionId: json['session_id'],
      quizType: json['quiz_type'],
      folderId: json['folder_id'],
      totalQuestions: json['total_questions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'quiz_type': quizType,
      'folder_id': folderId,
      'total_questions': totalQuestions,
    };
  }

  QuizType get quizTypeEnum => QuizType.values.firstWhere(
        (type) => type.value == quizType,
    orElse: () => QuizType.anagram,
  );

  @override
  String toString() {
    return 'QuizSessionInfo{sessionId: $sessionId, quizType: $quizType, folderId: $folderId, totalQuestions: $totalQuestions}';
  }
}

/// Start Quiz Response - Matches POST /quiz/{folder_id}/start response
class StartQuizResponse {
  final QuizSessionInfo session;
  final QuizQuestion question;

  StartQuizResponse({
    required this.session,
    required this.question,
  });

  factory StartQuizResponse.fromJson(Map<String, dynamic> json) {
    return StartQuizResponse(
      session: QuizSessionInfo.fromJson(json['session']),
      question: QuizQuestion.fromJson(json['question']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session': session.toJson(),
      'question': question.toJson(),
    };
  }

  @override
  String toString() {
    return 'StartQuizResponse{session: $session, question: $question}';
  }
}

/// Submit Answer Request - Matches POST /quiz/{session_id}/answer request
class SubmitAnswerRequest {
  final int wordId;
  final String answer;
  final int timeTaken;

  SubmitAnswerRequest({
    required this.wordId,
    required this.answer,
    required this.timeTaken,
  });

  Map<String, dynamic> toJson() {
    return {
      'word_id': wordId,
      'answer': answer,
      'time_taken': timeTaken,
    };
  }

  @override
  String toString() {
    return 'SubmitAnswerRequest{wordId: $wordId, answer: $answer, timeTaken: $timeTaken}';
  }
}

/// Submit Answer Response - Matches POST /quiz/{session_id}/answer response
class SubmitAnswerResponse {
  final bool isCorrect;
  final String correctAnswer;
  final String? explanation;
  final QuizQuestion? nextQuestion;

  SubmitAnswerResponse({
    required this.isCorrect,
    required this.correctAnswer,
    this.explanation,
    this.nextQuestion,
  });

  factory SubmitAnswerResponse.fromJson(Map<String, dynamic> json) {
    return SubmitAnswerResponse(
      isCorrect: json['is_correct'],
      correctAnswer: json['correct_answer'],
      explanation: json['explanation'],
      nextQuestion: json['next_question'] != null
          ? QuizQuestion.fromJson(json['next_question'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_correct': isCorrect,
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'next_question': nextQuestion?.toJson(),
    };
  }

  @override
  String toString() {
    return 'SubmitAnswerResponse{isCorrect: $isCorrect, correctAnswer: $correctAnswer, explanation: $explanation, nextQuestion: $nextQuestion}';
  }
}

/// Quiz Results Info - Used in complete quiz response
class QuizResultsInfo {
  final String sessionId;
  final int totalQuestions;
  final int correctAnswers;
  final int totalTime;
  final int accuracy;
  final String quizType;

  QuizResultsInfo({
    required this.sessionId,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.totalTime,
    required this.accuracy,
    required this.quizType,
  });

  factory QuizResultsInfo.fromJson(Map<String, dynamic> json) {
    return QuizResultsInfo(
      sessionId: json['session_id'],
      totalQuestions: json['total_questions'],
      correctAnswers: json['correct_answers'],
      totalTime: json['total_time'],
      accuracy: json['accuracy'],
      quizType: json['quiz_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'total_questions': totalQuestions,
      'correct_answers': correctAnswers,
      'total_time': totalTime,
      'accuracy': accuracy,
      'quiz_type': quizType,
    };
  }

  QuizType get quizTypeEnum => QuizType.values.firstWhere(
        (type) => type.value == quizType,
    orElse: () => QuizType.anagram,
  );

  /// Format total time for display
  String get formattedTime {
    if (totalTime < 60) {
      return '${totalTime}s';
    } else if (totalTime < 3600) {
      final minutes = totalTime ~/ 60;
      final seconds = totalTime % 60;
      return '${minutes}m ${seconds}s';
    } else {
      final hours = totalTime ~/ 3600;
      final minutes = (totalTime % 3600) ~/ 60;
      return '${hours}h ${minutes}m';
    }
  }

  @override
  String toString() {
    return 'QuizResultsInfo{sessionId: $sessionId, totalQuestions: $totalQuestions, correctAnswers: $correctAnswers, totalTime: $totalTime, accuracy: $accuracy, quizType: $quizType}';
  }
}

/// Updated Category Info - Used in complete quiz response
class UpdatedCategoryInfo {
  final int wordId;
  final String newCategory;

  UpdatedCategoryInfo({
    required this.wordId,
    required this.newCategory,
  });

  factory UpdatedCategoryInfo.fromJson(Map<String, dynamic> json) {
    return UpdatedCategoryInfo(
      wordId: json['word_id'],
      newCategory: json['new_category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word_id': wordId,
      'new_category': newCategory,
    };
  }

  WordCategory get categoryEnum => WordCategory.fromString(newCategory);

  @override
  String toString() {
    return 'UpdatedCategoryInfo{wordId: $wordId, newCategory: $newCategory}';
  }
}

/// Quiz Performance Info - Used in complete quiz response
class QuizPerformanceInfo {
  final String improvement;
  final List<String> strongestWords;
  final List<String> needsPractice;

  QuizPerformanceInfo({
    required this.improvement,
    required this.strongestWords,
    required this.needsPractice,
  });

  factory QuizPerformanceInfo.fromJson(Map<String, dynamic> json) {
    return QuizPerformanceInfo(
      improvement: json['improvement'],
      strongestWords: (json['strongest_words'] as List<dynamic>)
          .map((word) => word as String)
          .toList(),
      needsPractice: (json['needs_practice'] as List<dynamic>)
          .map((word) => word as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'improvement': improvement,
      'strongest_words': strongestWords,
      'needs_practice': needsPractice,
    };
  }

  @override
  String toString() {
    return 'QuizPerformanceInfo{improvement: $improvement, strongestWords: $strongestWords, needsPractice: $needsPractice}';
  }
}

/// Complete Quiz Response - Matches POST /quiz/{session_id}/complete response
class CompleteQuizResponse {
  final QuizResultsInfo results;
  final List<UpdatedCategoryInfo> updatedCategories;
  final QuizPerformanceInfo performance;

  CompleteQuizResponse({
    required this.results,
    required this.updatedCategories,
    required this.performance,
  });

  factory CompleteQuizResponse.fromJson(Map<String, dynamic> json) {
    return CompleteQuizResponse(
      results: QuizResultsInfo.fromJson(json['results']),
      updatedCategories: (json['updated_categories'] as List<dynamic>)
          .map((category) => UpdatedCategoryInfo.fromJson(category))
          .toList(),
      performance: QuizPerformanceInfo.fromJson(json['performance']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'results': results.toJson(),
      'updated_categories': updatedCategories.map((category) => category.toJson()).toList(),
      'performance': performance.toJson(),
    };
  }

  @override
  String toString() {
    return 'CompleteQuizResponse{results: $results, updatedCategories: ${updatedCategories.length}, performance: $performance}';
  }
}

/// Local Quiz Session State - For client-side quiz management
class LocalQuizSession {
  final String sessionId;
  final QuizType quizType;
  final int folderId;
  final List<QuizQuestion> questions;
  final List<QuizAnswer> answers;
  final DateTime startedAt;
  int currentQuestionIndex;

  LocalQuizSession({
    required this.sessionId,
    required this.quizType,
    required this.folderId,
    required this.questions,
    required this.startedAt,
    this.answers = const [],
    this.currentQuestionIndex = 0,
  });

  QuizQuestion? get currentQuestion {
    if (currentQuestionIndex < questions.length) {
      return questions[currentQuestionIndex];
    }
    return null;
  }

  bool get isComplete => currentQuestionIndex >= questions.length;

  int get totalQuestions => questions.length;
  int get answeredQuestions => answers.length;
  int get correctAnswers => answers.where((answer) => answer.isCorrect).length;
  int get totalTime => answers.fold(0, (sum, answer) => sum + answer.timeTaken);

  double get accuracy {
    if (answeredQuestions == 0) return 0.0;
    return (correctAnswers / answeredQuestions) * 100;
  }

  Duration get elapsedTime => DateTime.now().difference(startedAt);

  void addAnswer(QuizAnswer answer) {
    answers.add(answer);
    currentQuestionIndex++;
  }

  LocalQuizSession copyWith({
    String? sessionId,
    QuizType? quizType,
    int? folderId,
    List<QuizQuestion>? questions,
    List<QuizAnswer>? answers,
    DateTime? startedAt,
    int? currentQuestionIndex,
  }) {
    return LocalQuizSession(
      sessionId: sessionId ?? this.sessionId,
      quizType: quizType ?? this.quizType,
      folderId: folderId ?? this.folderId,
      questions: questions ?? this.questions,
      answers: answers ?? List.from(this.answers),
      startedAt: startedAt ?? this.startedAt,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
    );
  }

  @override
  String toString() {
    return 'LocalQuizSession{sessionId: $sessionId, quizType: $quizType, folderId: $folderId, questions: ${questions.length}, answers: ${answers.length}, currentQuestionIndex: $currentQuestionIndex}';
  }
}

/// Quiz Answer - For local quiz state management
class QuizAnswer {
  final int wordId;
  final String userAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final int timeTaken;
  final DateTime answeredAt;

  QuizAnswer({
    required this.wordId,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.timeTaken,
    required this.answeredAt,
  });

  factory QuizAnswer.fromResponse(
      int wordId,
      String userAnswer,
      int timeTaken,
      SubmitAnswerResponse response,
      ) {
    return QuizAnswer(
      wordId: wordId,
      userAnswer: userAnswer,
      correctAnswer: response.correctAnswer,
      isCorrect: response.isCorrect,
      timeTaken: timeTaken,
      answeredAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word_id': wordId,
      'user_answer': userAnswer,
      'correct_answer': correctAnswer,
      'is_correct': isCorrect,
      'time_taken': timeTaken,
      'answered_at': answeredAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'QuizAnswer{wordId: $wordId, userAnswer: $userAnswer, correctAnswer: $correctAnswer, isCorrect: $isCorrect, timeTaken: $timeTaken, answeredAt: $answeredAt}';
  }
}

/// Quiz Statistics - For displaying quiz performance
class QuizStatistics {
  final int totalQuizzes;
  final int totalQuestions;
  final int totalCorrect;
  final double averageAccuracy;
  final Duration totalTime;
  final Map<QuizType, int> quizzesByType;
  final Map<WordCategory, int> wordsByCategory;

  QuizStatistics({
    required this.totalQuizzes,
    required this.totalQuestions,
    required this.totalCorrect,
    required this.averageAccuracy,
    required this.totalTime,
    required this.quizzesByType,
    required this.wordsByCategory,
  });

  factory QuizStatistics.empty() {
    return QuizStatistics(
      totalQuizzes: 0,
      totalQuestions: 0,
      totalCorrect: 0,
      averageAccuracy: 0.0,
      totalTime: Duration.zero,
      quizzesByType: {},
      wordsByCategory: {},
    );
  }

  @override
  String toString() {
    return 'QuizStatistics{totalQuizzes: $totalQuizzes, totalQuestions: $totalQuestions, totalCorrect: $totalCorrect, averageAccuracy: $averageAccuracy, totalTime: $totalTime}';
  }
}