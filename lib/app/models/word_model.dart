import '../utils/constants.dart';

/// Word Model - Exact match with backend Word model
class Word {
  final int id;
  final int folderId;
  final String word;
  final String translation;
  final String? exampleSentence;
  final DateTime addedAt;

  Word({
    required this.id,
    required this.folderId,
    required this.word,
    required this.translation,
    this.exampleSentence,
    required this.addedAt,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'],
      folderId: json['folder_id'] ?? 0,
      word: json['word'],
      translation: json['translation'],
      exampleSentence: json['example_sentence'],
      addedAt: DateTime.parse(json['added_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'folder_id': folderId,
      'word': word,
      'translation': translation,
      'example_sentence': exampleSentence,
      'added_at': addedAt.toIso8601String(),
    };
  }

  Word copyWith({
    int? id,
    int? folderId,
    String? word,
    String? translation,
    String? exampleSentence,
    DateTime? addedAt,
  }) {
    return Word(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      word: word ?? this.word,
      translation: translation ?? this.translation,
      exampleSentence: exampleSentence ?? this.exampleSentence,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  /// Check if word is complete (matches backend is_complete property)
  bool get isComplete => exampleSentence != null && exampleSentence!.trim().isNotEmpty;

  @override
  String toString() {
    return 'Word{id: $id, folderId: $folderId, word: $word, translation: $translation, exampleSentence: $exampleSentence, addedAt: $addedAt}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Word &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Word Stats Model - Exact match with backend WordStats model
class WordStats {
  final int id;
  final int wordId;
  final int userId;
  final String category;
  final List<bool> last5Results;
  final int totalAttempts;
  final int correctAttempts;

  WordStats({
    required this.id,
    required this.wordId,
    required this.userId,
    required this.category,
    required this.last5Results,
    required this.totalAttempts,
    required this.correctAttempts,
  });

  factory WordStats.fromJson(Map<String, dynamic> json) {
    return WordStats(
      id: json['id'] ?? 0,
      wordId: json['word_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      category: json['category'] ?? 'not_known',
      last5Results: (json['last_5_results'] as List<dynamic>? ?? [])
          .map((result) => result as bool)
          .toList(),
      totalAttempts: json['total_attempts'] ?? 0,
      correctAttempts: json['correct_attempts'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word_id': wordId,
      'user_id': userId,
      'category': category,
      'last_5_results': last5Results,
      'total_attempts': totalAttempts,
      'correct_attempts': correctAttempts,
    };
  }

  /// Calculate accuracy percentage (matches backend accuracy property)
  int get accuracy {
    if (totalAttempts == 0) return 0;
    return ((correctAttempts / totalAttempts) * 100).round();
  }

  WordCategory get categoryEnum => WordCategory.fromString(category);

  /// Add new quiz result (matches backend add_result method logic)
  WordStats addResult(bool isCorrect) {
    final newResults = List<bool>.from(last5Results);
    newResults.add(isCorrect);

    // Keep only last 5 results
    if (newResults.length > 5) {
      newResults.removeAt(0);
    }

    final newTotalAttempts = totalAttempts + 1;
    final newCorrectAttempts = correctAttempts + (isCorrect ? 1 : 0);

    // Calculate new category based on last 5 results
    String newCategory = 'not_known';
    if (newResults.length >= 3) {
      final recentCorrect = newResults.where((result) => result).length;
      final recentAccuracy = recentCorrect / newResults.length;

      if (recentAccuracy >= 0.8) {
        newCategory = 'strong';
      } else if (recentAccuracy >= 0.5) {
        newCategory = 'normal';
      } else {
        newCategory = 'not_known';
      }
    }

    return copyWith(
      last5Results: newResults,
      totalAttempts: newTotalAttempts,
      correctAttempts: newCorrectAttempts,
      category: newCategory,
    );
  }

  WordStats copyWith({
    int? id,
    int? wordId,
    int? userId,
    String? category,
    List<bool>? last5Results,
    int? totalAttempts,
    int? correctAttempts,
  }) {
    return WordStats(
      id: id ?? this.id,
      wordId: wordId ?? this.wordId,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      last5Results: last5Results ?? this.last5Results,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      correctAttempts: correctAttempts ?? this.correctAttempts,
    );
  }

  @override
  String toString() {
    return 'WordStats{id: $id, wordId: $wordId, userId: $userId, category: $category, last5Results: $last5Results, totalAttempts: $totalAttempts, correctAttempts: $correctAttempts}';
  }
}

/// Add Word Request - Matches POST /words/{folder_id} request
class AddWordRequest {
  final String word;
  final String translation;
  final String? exampleSentence;

  AddWordRequest({
    required this.word,
    required this.translation,
    this.exampleSentence,
  });

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'translation': translation,
      if (exampleSentence != null && exampleSentence!.isNotEmpty)
        'example_sentence': exampleSentence,
    };
  }

  @override
  String toString() {
    return 'AddWordRequest{word: $word, translation: $translation, exampleSentence: $exampleSentence}';
  }
}

/// Word Response - Used in word responses
class WordResponse {
  final int id;
  final String word;
  final String translation;
  final String? exampleSentence;
  final String addedAt;

  WordResponse({
    required this.id,
    required this.word,
    required this.translation,
    this.exampleSentence,
    required this.addedAt,
  });

  factory WordResponse.fromJson(Map<String, dynamic> json) {
    return WordResponse(
      id: json['id'],
      word: json['word'],
      translation: json['translation'],
      exampleSentence: json['example_sentence'],
      addedAt: json['added_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'translation': translation,
      'example_sentence': exampleSentence,
      'added_at': addedAt,
    };
  }

  @override
  String toString() {
    return 'WordResponse{id: $id, word: $word, translation: $translation, exampleSentence: $exampleSentence, addedAt: $addedAt}';
  }
}

/// Add Word Response - Matches POST /words/{folder_id} response
class AddWordResponse {
  final WordResponse word;
  final Map<String, dynamic> stats;

  AddWordResponse({
    required this.word,
    required this.stats,
  });

  factory AddWordResponse.fromJson(Map<String, dynamic> json) {
    return AddWordResponse(
      word: WordResponse.fromJson(json['word']),
      stats: json['stats'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word.toJson(),
      'stats': stats,
    };
  }

  @override
  String toString() {
    return 'AddWordResponse{word: $word, stats: $stats}';
  }
}

/// Extracted Word - Used in OCR results
class ExtractedWord {
  final String word;
  final String translation;
  final double confidence;

  ExtractedWord({
    required this.word,
    required this.translation,
    required this.confidence,
  });

  factory ExtractedWord.fromJson(Map<String, dynamic> json) {
    return ExtractedWord(
      word: json['word'],
      translation: json['translation'],
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'translation': translation,
      'confidence': confidence,
    };
  }

  @override
  String toString() {
    return 'ExtractedWord{word: $word, translation: $translation, confidence: $confidence}';
  }
}

/// OCR Response - Matches POST /words/upload-photo response
class OCRResponse {
  final List<ExtractedWord> extractedWords;
  final int totalExtracted;
  final double processingTime;

  OCRResponse({
    required this.extractedWords,
    required this.totalExtracted,
    required this.processingTime,
  });

  factory OCRResponse.fromJson(Map<String, dynamic> json) {
    return OCRResponse(
      extractedWords: (json['extracted_words'] as List<dynamic>)
          .map((word) => ExtractedWord.fromJson(word))
          .toList(),
      totalExtracted: json['total_extracted'] ?? 0,
      processingTime: (json['processing_time'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'extracted_words': extractedWords.map((word) => word.toJson()).toList(),
      'total_extracted': totalExtracted,
      'processing_time': processingTime,
    };
  }

  @override
  String toString() {
    return 'OCRResponse{extractedWords: ${extractedWords.length}, totalExtracted: $totalExtracted, processingTime: $processingTime}';
  }
}

/// Bulk Add Request - Matches POST /words/{folder_id}/bulk-add request
class BulkAddRequest {
  final List<AddWordRequest> words;

  BulkAddRequest({
    required this.words,
  });

  Map<String, dynamic> toJson() {
    return {
      'words': words.map((word) => word.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'BulkAddRequest{words: ${words.length}}';
  }
}

/// Bulk Add Response - Matches POST /words/{folder_id}/bulk-add response
class BulkAddResponse {
  final bool success;
  final int addedCount;
  final List<WordResponse> words;

  BulkAddResponse({
    required this.success,
    required this.addedCount,
    required this.words,
  });

  factory BulkAddResponse.fromJson(Map<String, dynamic> json) {
    return BulkAddResponse(
      success: json['success'] ?? false,
      addedCount: json['added_count'] ?? 0,
      words: (json['words'] as List<dynamic>)
          .map((word) => WordResponse.fromJson(word))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'added_count': addedCount,
      'words': words.map((word) => word.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'BulkAddResponse{success: $success, addedCount: $addedCount, words: ${words.length}}';
  }
}

/// Bulk Delete Request - Matches POST /words/bulk-delete request
class BulkDeleteRequest {
  final List<int> wordIds;

  BulkDeleteRequest({
    required this.wordIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'word_ids': wordIds,
    };
  }

  @override
  String toString() {
    return 'BulkDeleteRequest{wordIds: $wordIds}';
  }
}

/// Bulk Delete Response - Matches POST /words/bulk-delete response
class BulkDeleteResponse {
  final bool success;
  final int deletedCount;
  final List<Map<String, dynamic>> deletedWords;

  BulkDeleteResponse({
    required this.success,
    required this.deletedCount,
    required this.deletedWords,
  });

  factory BulkDeleteResponse.fromJson(Map<String, dynamic> json) {
    return BulkDeleteResponse(
      success: json['success'] ?? false,
      deletedCount: json['deleted_count'] ?? 0,
      deletedWords: (json['deleted_words'] as List<dynamic>)
          .map((word) => word as Map<String, dynamic>)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'deleted_count': deletedCount,
      'deleted_words': deletedWords,
    };
  }

  @override
  String toString() {
    return 'BulkDeleteResponse{success: $success, deletedCount: $deletedCount, deletedWords: ${deletedWords.length}}';
  }
}

/// Generate Example Request - Matches POST /words/generate-example request
class GenerateExampleRequest {
  final String word;
  final String translation;

  GenerateExampleRequest({
    required this.word,
    required this.translation,
  });

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'translation': translation,
    };
  }

  @override
  String toString() {
    return 'GenerateExampleRequest{word: $word, translation: $translation}';
  }
}

/// Generate Example Response - Matches POST /words/generate-example response
class GenerateExampleResponse {
  final String exampleSentence;
  final List<String> alternatives;

  GenerateExampleResponse({
    required this.exampleSentence,
    this.alternatives = const [],
  });

  factory GenerateExampleResponse.fromJson(Map<String, dynamic> json) {
    return GenerateExampleResponse(
      exampleSentence: json['example_sentence'],
      alternatives: (json['alternatives'] as List<dynamic>? ?? [])
          .map((alt) => alt as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'example_sentence': exampleSentence,
      'alternatives': alternatives,
    };
  }

  @override
  String toString() {
    return 'GenerateExampleResponse{exampleSentence: $exampleSentence, alternatives: $alternatives}';
  }
}

/// Word Detail Response - Matches GET /words/{word_id} response
class WordDetailResponse {
  final WordDetailInfo word;
  final WordDetailStats stats;

  WordDetailResponse({
    required this.word,
    required this.stats,
  });

  factory WordDetailResponse.fromJson(Map<String, dynamic> json) {
    return WordDetailResponse(
      word: WordDetailInfo.fromJson(json['word']),
      stats: WordDetailStats.fromJson(json['stats']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word.toJson(),
      'stats': stats.toJson(),
    };
  }

  @override
  String toString() {
    return 'WordDetailResponse{word: $word, stats: $stats}';
  }
}

/// Word Detail Info - Used in word detail response
class WordDetailInfo {
  final int id;
  final String word;
  final String translation;
  final String? exampleSentence;
  final String addedAt;
  final FolderInfo folder;

  WordDetailInfo({
    required this.id,
    required this.word,
    required this.translation,
    this.exampleSentence,
    required this.addedAt,
    required this.folder,
  });

  factory WordDetailInfo.fromJson(Map<String, dynamic> json) {
    return WordDetailInfo(
      id: json['id'],
      word: json['word'],
      translation: json['translation'],
      exampleSentence: json['example_sentence'],
      addedAt: json['added_at'],
      folder: FolderInfo.fromJson(json['folder']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'translation': translation,
      'example_sentence': exampleSentence,
      'added_at': addedAt,
      'folder': folder.toJson(),
    };
  }

  @override
  String toString() {
    return 'WordDetailInfo{id: $id, word: $word, translation: $translation, exampleSentence: $exampleSentence, addedAt: $addedAt, folder: $folder}';
  }
}

/// Folder Info for word detail
class FolderInfo {
  final int id;
  final String name;

  FolderInfo({
    required this.id,
    required this.name,
  });

  factory FolderInfo.fromJson(Map<String, dynamic> json) {
    return FolderInfo(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  String toString() {
    return 'FolderInfo{id: $id, name: $name}';
  }
}

/// Word Detail Stats - Used in word detail response
class WordDetailStats {
  final String category;
  final List<bool> last5Results;
  final int totalAttempts;
  final int correctAttempts;
  final int accuracy;
  final String? lastQuizDate;

  WordDetailStats({
    required this.category,
    required this.last5Results,
    required this.totalAttempts,
    required this.correctAttempts,
    required this.accuracy,
    this.lastQuizDate,
  });

  factory WordDetailStats.fromJson(Map<String, dynamic> json) {
    return WordDetailStats(
      category: json['category'] ?? 'not_known',
      last5Results: (json['last_5_results'] as List<dynamic>? ?? [])
          .map((result) => result as bool)
          .toList(),
      totalAttempts: json['total_attempts'] ?? 0,
      correctAttempts: json['correct_attempts'] ?? 0,
      accuracy: json['accuracy'] ?? 0,
      lastQuizDate: json['last_quiz_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'last_5_results': last5Results,
      'total_attempts': totalAttempts,
      'correct_attempts': correctAttempts,
      'accuracy': accuracy,
      'last_quiz_date': lastQuizDate,
    };
  }

  WordCategory get categoryEnum => WordCategory.fromString(category);

  @override
  String toString() {
    return 'WordDetailStats{category: $category, last5Results: $last5Results, totalAttempts: $totalAttempts, correctAttempts: $correctAttempts, accuracy: $accuracy, lastQuizDate: $lastQuizDate}';
  }
}

/// Update Word Request - Matches PUT /words/{word_id} request
class UpdateWordRequest {
  final String? word;
  final String? translation;
  final String? exampleSentence;

  UpdateWordRequest({
    this.word,
    this.translation,
    this.exampleSentence,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (word != null) json['word'] = word;
    if (translation != null) json['translation'] = translation;
    if (exampleSentence != null) json['example_sentence'] = exampleSentence;
    return json;
  }

  bool get hasChanges => word != null || translation != null || exampleSentence != null;

  @override
  String toString() {
    return 'UpdateWordRequest{word: $word, translation: $translation, exampleSentence: $exampleSentence}';
  }
}

/// Update Word Response - Matches PUT /words/{word_id} response
class UpdateWordResponse {
  final bool success;
  final Map<String, dynamic> word;

  UpdateWordResponse({
    required this.success,
    required this.word,
  });

  factory UpdateWordResponse.fromJson(Map<String, dynamic> json) {
    return UpdateWordResponse(
      success: json['success'] ?? false,
      word: json['word'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'word': word,
    };
  }

  @override
  String toString() {
    return 'UpdateWordResponse{success: $success, word: $word}';
  }
}

/// Delete Word Response - Matches DELETE /words/{word_id} response
class DeleteWordResponse {
  final bool success;
  final String message;
  final Map<String, dynamic> deletedWord;

  DeleteWordResponse({
    required this.success,
    required this.message,
    required this.deletedWord,
  });

  factory DeleteWordResponse.fromJson(Map<String, dynamic> json) {
    return DeleteWordResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      deletedWord: json['deleted_word'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'deleted_word': deletedWord,
    };
  }

  @override
  String toString() {
    return 'DeleteWordResponse{success: $success, message: $message, deletedWord: $deletedWord}';
  }
}

/// Translation models for new translate endpoints
class TranslationOption {
  final String translation;
  final double confidence;

  TranslationOption({
    required this.translation,
    required this.confidence,
  });

  factory TranslationOption.fromJson(Map<String, dynamic> json) {
    return TranslationOption(
      translation: json['translation'],
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}

class TranslateWordRequest {
  final String word;

  TranslateWordRequest({required this.word});

  Map<String, dynamic> toJson() => {'word': word};
}

class TranslateWordResponse {
  final String word;
  final List<TranslationOption> options;
  final int totalOptions;

  TranslateWordResponse({
    required this.word,
    required this.options,
    required this.totalOptions,
  });

  factory TranslateWordResponse.fromJson(Map<String, dynamic> json) {
    return TranslateWordResponse(
      word: json['word'],
      options: (json['options'] as List)
          .map((option) => TranslationOption.fromJson(option))
          .toList(),
      totalOptions: json['total_options'],
    );
  }
}