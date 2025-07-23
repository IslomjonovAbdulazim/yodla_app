/// User Model - Exact match with backend User model
class User {
  final int id;
  final String email;
  final String nickname;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.nickname,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      nickname: json['nickname'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'created_at': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? email,
    String? nickname,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'User{id: $id, email: $email, nickname: $nickname, createdAt: $createdAt}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is User &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// User Statistics - Matches backend user stats calculation
class UserStats {
  final int totalFolders;
  final int totalWords;
  final int totalQuizzes;
  final WordCategoryStats wordsByCategory;

  UserStats({
    required this.totalFolders,
    required this.totalWords,
    required this.totalQuizzes,
    required this.wordsByCategory,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalFolders: json['total_folders'] ?? 0,
      totalWords: json['total_words'] ?? 0,
      totalQuizzes: json['total_quizzes'] ?? 0,
      wordsByCategory: WordCategoryStats.fromJson(
        json['words_by_category'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_folders': totalFolders,
      'total_words': totalWords,
      'total_quizzes': totalQuizzes,
      'words_by_category': wordsByCategory.toJson(),
    };
  }

  @override
  String toString() {
    return 'UserStats{totalFolders: $totalFolders, totalWords: $totalWords, totalQuizzes: $totalQuizzes, wordsByCategory: $wordsByCategory}';
  }
}

/// Word Category Statistics - Matches backend WordStats categories
class WordCategoryStats {
  final int notKnown;
  final int normal;
  final int strong;

  WordCategoryStats({
    required this.notKnown,
    required this.normal,
    required this.strong,
  });

  factory WordCategoryStats.fromJson(Map<String, dynamic> json) {
    return WordCategoryStats(
      notKnown: json['not_known'] ?? 0,
      normal: json['normal'] ?? 0,
      strong: json['strong'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'not_known': notKnown,
      'normal': normal,
      'strong': strong,
    };
  }

  int get total => notKnown + normal + strong;

  double get notKnownPercentage => total > 0 ? (notKnown / total) * 100 : 0;
  double get normalPercentage => total > 0 ? (normal / total) * 100 : 0;
  double get strongPercentage => total > 0 ? (strong / total) * 100 : 0;

  @override
  String toString() {
    return 'WordCategoryStats{notKnown: $notKnown, normal: $normal, strong: $strong}';
  }
}

/// User Profile Response - Matches GET /user/profile response
class UserProfileResponse {
  final User user;
  final UserStats stats;

  UserProfileResponse({
    required this.user,
    required this.stats,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      user: User.fromJson(json['user']),
      stats: UserStats.fromJson(json['stats']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'stats': stats.toJson(),
    };
  }

  @override
  String toString() {
    return 'UserProfileResponse{user: $user, stats: $stats}';
  }
}

/// Update Profile Request - Matches PUT /user/profile request
class UpdateProfileRequest {
  final String nickname;

  UpdateProfileRequest({
    required this.nickname,
  });

  Map<String, dynamic> toJson() {
    return {
      'nickname': nickname,
    };
  }

  @override
  String toString() {
    return 'UpdateProfileRequest{nickname: $nickname}';
  }
}

/// User Update Response - Matches PUT /user/profile response
class UserUpdateResponse {
  final bool success;
  final User user;

  UserUpdateResponse({
    required this.success,
    required this.user,
  });

  factory UserUpdateResponse.fromJson(Map<String, dynamic> json) {
    return UserUpdateResponse(
      success: json['success'] ?? false,
      user: User.fromJson(json['user']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'user': user.toJson(),
    };
  }

  @override
  String toString() {
    return 'UserUpdateResponse{success: $success, user: $user}';
  }
}

/// Apple Sign In Request - Matches POST /auth/apple-signin request
class AppleSignInRequest {
  final String identityToken;
  final String userIdentifier;
  final String? nickname;

  AppleSignInRequest({
    required this.identityToken,
    required this.userIdentifier,
    this.nickname,
  });

  Map<String, dynamic> toJson() {
    return {
      'identity_token': identityToken,
      'user_identifier': userIdentifier,
      if (nickname != null) 'nickname': nickname,
    };
  }

  @override
  String toString() {
    return 'AppleSignInRequest{identityToken: ${identityToken.substring(0, 20)}..., userIdentifier: $userIdentifier, nickname: $nickname}';
  }
}

/// Auth Response - Matches authentication response
class AuthResponse {
  final String accessToken;
  final String tokenType;
  final User user;

  AuthResponse({
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'],
      tokenType: json['token_type'] ?? 'bearer',
      user: User.fromJson(json['user']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'user': user.toJson(),
    };
  }

  @override
  String toString() {
    return 'AuthResponse{accessToken: ${accessToken.substring(0, 20)}..., tokenType: $tokenType, user: $user}';
  }
}

/// Test Login Request - Matches POST /auth/test-login (dev only)
class TestLoginRequest {
  final String email;
  final String nickname;

  TestLoginRequest({
    required this.email,
    this.nickname = 'Test User',
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'nickname': nickname,
    };
  }

  @override
  String toString() {
    return 'TestLoginRequest{email: $email, nickname: $nickname}';
  }
}