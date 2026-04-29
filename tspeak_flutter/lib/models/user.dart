class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String avatarUrl;
  final String bio;
  final String country;
  final String learningGoal;
  final String interests;
  final String ageRange;
  final int level;
  final int xp;
  final int xpToNextLevel;
  final int streak;
  final int sessions;
  final double averageScore;
  final List<String> languages;
  final String nativeLanguage;
  final String currentLeague;

  String get name => "$firstName $lastName".trim();

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.avatarUrl,
    this.bio = '',
    this.country = '',
    this.learningGoal = '',
    this.interests = '',
    this.ageRange = '',
    this.level = 1,
    this.xp = 0,
    this.xpToNextLevel = 1500,
    this.streak = 0,
    this.sessions = 0,
    this.averageScore = 0.0,
    this.languages = const [],
    this.nativeLanguage = 'french',
    this.currentLeague = 'Pionnier I',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Strip "data" wrapper if present
    final d = json.containsKey('data') ? json['data'] as Map<String, dynamic> : json;

    // Map level string -> int
    const levelMap = {
      'beginner': 1, 'elementary': 2, 'intermediate': 3,
      'upper_intermediate': 4, 'advanced': 5,
    };
    final levelStr = d['level'] as String? ?? 'beginner';
    final levelInt = levelMap[levelStr] ?? 1;

    // xp_for_next_level may be null (advanced users)
    final xpNext = _parseInt(d['xp_for_next_level']);

    return User(
      id: (d['id'] ?? '').toString(),
      firstName: d['first_name'] as String? ?? d['full_name'] as String? ?? '',
      lastName: d['last_name'] as String? ?? '',
      email: d['email'] as String? ?? '',
      avatarUrl: d['avatar_url'] as String? ?? '',
      bio: d['bio'] as String? ?? '',
      country: d['country'] as String? ?? '',
      learningGoal: d['learning_goal'] as String? ?? '',
      interests: d['interests'] as String? ?? '',
      ageRange: d['age_range'] as String? ?? '',
      level: levelInt,
      xp: _parseInt(d['xp_total']),
      xpToNextLevel: xpNext == 0 ? 99999 : xpNext,
      streak: _parseInt(d['streak_days']),
      sessions: _parseInt(d['sessions_count']),
      averageScore: _parseDouble(d['avg_pronunciation']),
      languages: const [],
      nativeLanguage: d['native_language'] as String? ?? 'french',
      currentLeague: 'Pionnier I',
    );
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'avatar_url': avatarUrl,
      'bio': bio,
      'country': country,
      'learning_goal': learningGoal,
      'interests': interests,
      'age_range': ageRange,
      'level': level,
      'xp': xp,
      'xp_to_next_level': xpToNextLevel,
      'streak': streak,
      'sessions_count': sessions,
      'average_score': averageScore,
      'languages': languages,
      'native_language': nativeLanguage,
      'current_league': currentLeague,
    };
  }

  User copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? avatarUrl,
    String? bio,
    String? country,
    String? learningGoal,
    String? interests,
    String? ageRange,
    int? level,
    int? xp,
    int? xpToNextLevel,
    int? streak,
    int? sessions,
    double? averageScore,
    List<String>? languages,
    String? nativeLanguage,
    String? currentLeague,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      country: country ?? this.country,
      learningGoal: learningGoal ?? this.learningGoal,
      interests: interests ?? this.interests,
      ageRange: ageRange ?? this.ageRange,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      streak: streak ?? this.streak,
      sessions: sessions ?? this.sessions,
      averageScore: averageScore ?? this.averageScore,
      languages: languages ?? this.languages,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      currentLeague: currentLeague ?? this.currentLeague,
    );
  }
}

class Badge {
  final String id;
  final String name;
  final String icon;
  final ColorType colorType;
  final bool isUnlocked;

  Badge({
    required this.id,
    required this.name,
    required this.icon,
    this.colorType = ColorType.primary,
    this.isUnlocked = false,
  });
}

enum ColorType { primary, secondary, tertiary }

class Simulation {
  final String id;
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final int duration;
  final double rating;
  final String imageUrl;
  final bool isPremium;

  Simulation({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.duration,
    required this.rating,
    required this.imageUrl,
    this.isPremium = false,
  });
}

class LeaderboardEntry {
  final int rank;
  final String name;
  final String avatarUrl;
  final int xp;
  final String league;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.avatarUrl,
    required this.xp,
    required this.league,
    this.isCurrentUser = false,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] ?? 0,
      name: json['name'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      xp: json['xp'] ?? 0,
      league: json['league'] ?? '',
      isCurrentUser: json['is_current_user'] ?? false,
    );
  }
}

class SessionResult {
  final int overallScore;
  final int xpEarned;
  final int streak;
  final Map<String, int> metrics;
  final String aiFeedback;

  SessionResult({
    required this.overallScore,
    required this.xpEarned,
    required this.streak,
    required this.metrics,
    required this.aiFeedback,
  });
}
