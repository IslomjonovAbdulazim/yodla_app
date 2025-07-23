import '../utils/constants.dart';

/// Folder Model - Exact match with backend Folder model
class Folder {
  final int id;
  final int userId;
  final String name;
  final String? description;
  final int wordCount;
  final DateTime createdAt;

  Folder({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.wordCount,
    required this.createdAt,
  });

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'],
      userId: json['user_id'] ?? 0, // May not be included in responses
      name: json['name'],
      description: json['description'],
      wordCount: json['word_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'word_count': wordCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Folder copyWith({
    int? id,
    int? userId,
    String? name,
    String? description,
    int? wordCount,
    DateTime? createdAt,
  }) {
    return Folder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      wordCount: wordCount ?? this.wordCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if folder has enough words to start quiz (matches backend logic)
  bool canStartQuiz() {
    return wordCount >= AppConstants.minWordsForQuiz;
  }

  /// Check if folder has enough words for reading comprehension (matches backend logic)
  bool canStartReading() {
    return wordCount >= AppConstants.minWordsForReading;
  }

  @override
  String toString() {
    return 'Folder{id: $id, userId: $userId, name: $name, description: $description, wordCount: $wordCount, createdAt: $createdAt}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Folder &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Folder Response - Matches folder list response
class FolderResponse {
  final int id;
  final String name;
  final String? description;
  final int wordCount;
  final String createdAt;

  FolderResponse({
    required this.id,
    required this.name,
    this.description,
    required this.wordCount,
    required this.createdAt,
  });

  factory FolderResponse.fromJson(Map<String, dynamic> json) {
    return FolderResponse(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      wordCount: json['word_count'] ?? 0,
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'word_count': wordCount,
      'created_at': createdAt,
    };
  }

  /// Convert to Folder model
  Folder toFolder() {
    return Folder(
      id: id,
      userId: 0, // Not provided in response
      name: name,
      description: description,
      wordCount: wordCount,
      createdAt: DateTime.parse(createdAt),
    );
  }

  @override
  String toString() {
    return 'FolderResponse{id: $id, name: $name, description: $description, wordCount: $wordCount, createdAt: $createdAt}';
  }
}

/// Folder List Response - Matches GET /folders response
class FolderListResponse {
  final List<FolderResponse> folders;
  final int totalCount;

  FolderListResponse({
    required this.folders,
    required this.totalCount,
  });

  factory FolderListResponse.fromJson(Map<String, dynamic> json) {
    return FolderListResponse(
      folders: (json['folders'] as List<dynamic>)
          .map((folder) => FolderResponse.fromJson(folder))
          .toList(),
      totalCount: json['total_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'folders': folders.map((folder) => folder.toJson()).toList(),
      'total_count': totalCount,
    };
  }

  @override
  String toString() {
    return 'FolderListResponse{folders: ${folders.length}, totalCount: $totalCount}';
  }
}

/// Create Folder Request - Matches POST /folders request
class CreateFolderRequest {
  final String name;
  final String? description;

  CreateFolderRequest({
    required this.name,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null && description!.isNotEmpty) 'description': description,
    };
  }

  @override
  String toString() {
    return 'CreateFolderRequest{name: $name, description: $description}';
  }
}

/// Update Folder Request - Matches PUT /folders/{folder_id} request
class UpdateFolderRequest {
  final String? name;
  final String? description;

  UpdateFolderRequest({
    this.name,
    this.description,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (name != null) json['name'] = name;
    if (description != null) json['description'] = description;
    return json;
  }

  bool get hasChanges => name != null || description != null;

  @override
  String toString() {
    return 'UpdateFolderRequest{name: $name, description: $description}';
  }
}

/// Folder Detail Response - Matches GET /folders/{folder_id} response
class FolderDetailResponse {
  final FolderInfo folder;
  final List<WordWithStats> words;

  FolderDetailResponse({
    required this.folder,
    required this.words,
  });

  factory FolderDetailResponse.fromJson(Map<String, dynamic> json) {
    return FolderDetailResponse(
      folder: FolderInfo.fromJson(json['folder']),
      words: (json['words'] as List<dynamic>)
          .map((word) => WordWithStats.fromJson(word))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'folder': folder.toJson(),
      'words': words.map((word) => word.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'FolderDetailResponse{folder: $folder, words: ${words.length}}';
  }
}

/// Folder Info - Used in folder detail response
class FolderInfo {
  final int id;
  final String name;
  final String? description;
  final int wordCount;
  final String createdAt;

  FolderInfo({
    required this.id,
    required this.name,
    this.description,
    required this.wordCount,
    required this.createdAt,
  });

  factory FolderInfo.fromJson(Map<String, dynamic> json) {
    return FolderInfo(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      wordCount: json['word_count'] ?? 0,
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'word_count': wordCount,
      'created_at': createdAt,
    };
  }

  @override
  String toString() {
    return 'FolderInfo{id: $id, name: $name, description: $description, wordCount: $wordCount, createdAt: $createdAt}';
  }
}

/// Word with Stats - Used in folder detail response
class WordWithStats {
  final int id;
  final String word;
  final String translation;
  final String? exampleSentence;
  final String addedAt;
  final WordStatsInfo stats;

  WordWithStats({
    required this.id,
    required this.word,
    required this.translation,
    this.exampleSentence,
    required this.addedAt,
    required this.stats,
  });

  factory WordWithStats.fromJson(Map<String, dynamic> json) {
    return WordWithStats(
      id: json['id'],
      word: json['word'],
      translation: json['translation'],
      exampleSentence: json['example_sentence'],
      addedAt: json['added_at'],
      stats: WordStatsInfo.fromJson(json['stats']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'translation': translation,
      'example_sentence': exampleSentence,
      'added_at': addedAt,
      'stats': stats.toJson(),
    };
  }

  /// Check if word is complete (has example sentence) - matches backend logic
  bool get isComplete => exampleSentence != null && exampleSentence!.isNotEmpty;

  @override
  String toString() {
    return 'WordWithStats{id: $id, word: $word, translation: $translation, exampleSentence: $exampleSentence, addedAt: $addedAt, stats: $stats}';
  }
}

/// Word Stats Info - Used in word with stats
class WordStatsInfo {
  final String category;
  final List<bool> last5Results;
  final int accuracy;

  WordStatsInfo({
    required this.category,
    required this.last5Results,
    required this.accuracy,
  });

  factory WordStatsInfo.fromJson(Map<String, dynamic> json) {
    return WordStatsInfo(
      category: json['category'] ?? 'not_known',
      last5Results: (json['last_5_results'] as List<dynamic>? ?? [])
          .map((result) => result as bool)
          .toList(),
      accuracy: json['accuracy'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'last_5_results': last5Results,
      'accuracy': accuracy,
    };
  }

  WordCategory get categoryEnum => WordCategory.fromString(category);

  @override
  String toString() {
    return 'WordStatsInfo{category: $category, last5Results: $last5Results, accuracy: $accuracy}';
  }
}

/// Delete Folder Response - Matches DELETE /folders/{folder_id} response
class DeleteFolderResponse {
  final bool success;
  final String message;
  final int deletedWordsCount;

  DeleteFolderResponse({
    required this.success,
    required this.message,
    required this.deletedWordsCount,
  });

  factory DeleteFolderResponse.fromJson(Map<String, dynamic> json) {
    return DeleteFolderResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      deletedWordsCount: json['deleted_words_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'deleted_words_count': deletedWordsCount,
    };
  }

  @override
  String toString() {
    return 'DeleteFolderResponse{success: $success, message: $message, deletedWordsCount: $deletedWordsCount}';
  }
}
