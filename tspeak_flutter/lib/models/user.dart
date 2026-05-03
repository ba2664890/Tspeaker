class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
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
  final double avgPronunciation;
  final double avgFluency;
  final double avgGrammar;
  final double avgVocabulary;
  final List<String> languages;
  final String nativeLanguage;
  final String currentLeague;
  final int badgesCount;
  final bool isPremium;
  final bool isPremiumActive;
  final DateTime? premiumUntil;
  final DateTime? joinedAt;

  String get name => '$firstName $lastName'.trim();

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone = '',
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
    this.avgPronunciation = 0.0,
    this.avgFluency = 0.0,
    this.avgGrammar = 0.0,
    this.avgVocabulary = 0.0,
    this.languages = const [],
    this.nativeLanguage = 'french',
    this.currentLeague = 'Pionnier I',
    this.badgesCount = 0,
    this.isPremium = false,
    this.isPremiumActive = false,
    this.premiumUntil,
    this.joinedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Strip "data" wrapper if present
    final d =
        json.containsKey('data') ? json['data'] as Map<String, dynamic> : json;

    // Map level string -> int
    const levelMap = {
      'beginner': 1,
      'elementary': 2,
      'intermediate': 3,
      'upper_intermediate': 4,
      'advanced': 5,
    };
    final levelStr = d['level'] as String? ?? 'beginner';
    final levelInt = levelMap[levelStr] ?? 1;

    // xp_for_next_level may be null (advanced users)
    final xpNext = _parseInt(d['xp_for_next_level']);
    final avgPronunciation = _parseDouble(d['avg_pronunciation']);
    final avgFluency = _parseDouble(d['avg_fluency']);
    final avgGrammar = _parseDouble(d['avg_grammar']);
    final avgVocabulary = _parseDouble(d['avg_vocabulary']);
    final overallAverage =
        (avgPronunciation + avgFluency + avgGrammar + avgVocabulary) / 4;

    return User(
      id: (d['id'] ?? '').toString(),
      firstName: d['first_name'] as String? ?? d['full_name'] as String? ?? '',
      lastName: d['last_name'] as String? ?? '',
      email: d['email'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
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
      averageScore: overallAverage,
      avgPronunciation: avgPronunciation,
      avgFluency: avgFluency,
      avgGrammar: avgGrammar,
      avgVocabulary: avgVocabulary,
      languages: const [],
      nativeLanguage: d['native_language'] as String? ?? 'french',
      currentLeague: 'Pionnier I',
      badgesCount: _parseInt(d['badges_count']),
      isPremium: d['is_premium'] as bool? ?? false,
      isPremiumActive: d['is_premium_active'] as bool? ?? false,
      premiumUntil: _parseDate(d['premium_until']),
      joinedAt: _parseDate(d['date_joined']),
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

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
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
      'avg_pronunciation': avgPronunciation,
      'avg_fluency': avgFluency,
      'avg_grammar': avgGrammar,
      'avg_vocabulary': avgVocabulary,
      'languages': languages,
      'native_language': nativeLanguage,
      'current_league': currentLeague,
      'badges_count': badgesCount,
      'is_premium': isPremium,
      'is_premium_active': isPremiumActive,
      'premium_until': premiumUntil?.toIso8601String(),
      'date_joined': joinedAt?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
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
    double? avgPronunciation,
    double? avgFluency,
    double? avgGrammar,
    double? avgVocabulary,
    List<String>? languages,
    String? nativeLanguage,
    String? currentLeague,
    int? badgesCount,
    bool? isPremium,
    bool? isPremiumActive,
    DateTime? premiumUntil,
    DateTime? joinedAt,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
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
      avgPronunciation: avgPronunciation ?? this.avgPronunciation,
      avgFluency: avgFluency ?? this.avgFluency,
      avgGrammar: avgGrammar ?? this.avgGrammar,
      avgVocabulary: avgVocabulary ?? this.avgVocabulary,
      languages: languages ?? this.languages,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      currentLeague: currentLeague ?? this.currentLeague,
      badgesCount: badgesCount ?? this.badgesCount,
      isPremium: isPremium ?? this.isPremium,
      isPremiumActive: isPremiumActive ?? this.isPremiumActive,
      premiumUntil: premiumUntil ?? this.premiumUntil,
      joinedAt: joinedAt ?? this.joinedAt,
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
  final bool isAccessible;
  final String languageHint;
  final String iconEmoji;
  final int completionsCount;

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
    this.isAccessible = true,
    this.languageHint = '',
    this.iconEmoji = '🎯',
    this.completionsCount = 0,
  });

  factory Simulation.fromJson(Map<String, dynamic> json) {
    final rawRating = json['rating'] ?? 0;
    final rating = rawRating is num
        ? rawRating.toDouble()
        : double.tryParse(rawRating.toString()) ?? 0;

    return Simulation(
      id: (json['id'] ?? '').toString(),
      title: json['name'] ?? json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      difficulty: json['difficulty'] ?? '',
      duration: json['duration_min'] ?? json['duration'] ?? 0,
      rating: rating,
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
      isPremium: json['is_premium'] ?? json['isPremium'] ?? false,
      isAccessible: json['is_accessible'] ?? true,
      languageHint: json['language_hint'] ?? '',
      iconEmoji: json['icon_emoji'] ?? '🎯',
      completionsCount: json['completions_count'] ?? 0,
    );
  }
}

class PracticeSessionLaunch {
  final String sessionId;
  final String openingMessage;
  final Simulation simulation;

  const PracticeSessionLaunch({
    required this.sessionId,
    required this.openingMessage,
    required this.simulation,
  });

  factory PracticeSessionLaunch.fromJson(Map<String, dynamic> json) {
    return PracticeSessionLaunch(
      sessionId: (json['session_id'] ?? '').toString(),
      openingMessage: json['opening_message'] ?? '',
      simulation: Simulation.fromJson(
        (json['simulation'] ?? const <String, dynamic>{})
            as Map<String, dynamic>,
      ),
    );
  }
}

class LeaderboardEntry {
  final String id;
  final int rank;
  final String name;
  final String avatarUrl;
  final int xp;
  final int totalXp;
  final String level;
  final int levelNumber;
  final String league;
  final int streakDays;
  final int sessionsCount;
  final double averageScore;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.id,
    required this.rank,
    required this.name,
    required this.avatarUrl,
    required this.xp,
    this.totalXp = 0,
    this.level = 'beginner',
    this.levelNumber = 1,
    required this.league,
    this.streakDays = 0,
    this.sessionsCount = 0,
    this.averageScore = 0,
    this.isCurrentUser = false,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: (json['id'] ?? '').toString(),
      rank: json['rank'] ?? 0,
      name: json['name'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      xp: json['xp'] ?? json['xp_total'] ?? 0,
      totalXp: json['total_xp'] ?? json['xp_total'] ?? 0,
      level: json['level'] ?? 'beginner',
      levelNumber: json['level_number'] ?? 1,
      league: json['league'] ?? '',
      streakDays: json['streak_days'] ?? 0,
      sessionsCount: json['sessions_count'] ?? 0,
      averageScore: (json['average_score'] ?? 0).toDouble(),
      isCurrentUser: json['is_current_user'] ?? false,
    );
  }
}

class LeaderboardSummary {
  final String scope;
  final String scopeLabel;
  final String scopeDescription;
  final String scoreLabel;
  final int totalLearners;
  final int topScore;
  final int bestStreak;
  final int userRank;
  final int userPercentile;
  final int gapToTarget;
  final int leadOverChaser;
  final String targetName;
  final String chaserName;
  final String currentLeague;
  final String nextLeague;
  final double leagueProgress;
  final int nextLeagueTarget;
  final int scoreToNextLeague;
  final int currentScore;
  final int currentTotalXp;
  final DateTime? generatedAt;

  const LeaderboardSummary({
    required this.scope,
    required this.scopeLabel,
    required this.scopeDescription,
    required this.scoreLabel,
    required this.totalLearners,
    required this.topScore,
    required this.bestStreak,
    required this.userRank,
    required this.userPercentile,
    required this.gapToTarget,
    required this.leadOverChaser,
    required this.targetName,
    required this.chaserName,
    required this.currentLeague,
    required this.nextLeague,
    required this.leagueProgress,
    required this.nextLeagueTarget,
    required this.scoreToNextLeague,
    required this.currentScore,
    required this.currentTotalXp,
    required this.generatedAt,
  });

  factory LeaderboardSummary.fromJson(Map<String, dynamic> json) {
    return LeaderboardSummary(
      scope: json['scope'] ?? 'weekly',
      scopeLabel: json['scope_label'] ?? 'Hebdomadaire',
      scopeDescription: json['scope_description'] ?? '',
      scoreLabel: json['score_label'] ?? 'XP',
      totalLearners: json['total_learners'] ?? 0,
      topScore: json['top_score'] ?? 0,
      bestStreak: json['best_streak'] ?? 0,
      userRank: json['user_rank'] ?? 0,
      userPercentile: json['user_percentile'] ?? 0,
      gapToTarget: json['gap_to_target'] ?? 0,
      leadOverChaser: json['lead_over_chaser'] ?? 0,
      targetName: json['target_name'] ?? '',
      chaserName: json['chaser_name'] ?? '',
      currentLeague: json['current_league'] ?? '',
      nextLeague: json['next_league'] ?? '',
      leagueProgress: (json['league_progress'] ?? 0).toDouble(),
      nextLeagueTarget: json['next_league_target'] ?? 0,
      scoreToNextLeague: json['score_to_next_league'] ?? 0,
      currentScore: json['current_score'] ?? 0,
      currentTotalXp: json['current_total_xp'] ?? 0,
      generatedAt: json['generated_at'] != null
          ? DateTime.tryParse(json['generated_at'].toString())
          : null,
    );
  }
}

class LeaderboardData {
  final LeaderboardSummary summary;
  final LeaderboardEntry? currentUser;
  final List<LeaderboardEntry> podium;
  final List<LeaderboardEntry> leaderboard;
  final List<LeaderboardEntry> aroundMe;

  const LeaderboardData({
    required this.summary,
    required this.currentUser,
    required this.podium,
    required this.leaderboard,
    required this.aroundMe,
  });

  factory LeaderboardData.fromJson(Map<String, dynamic> json) {
    return LeaderboardData(
      summary: LeaderboardSummary.fromJson(
        (json['summary'] ?? const <String, dynamic>{}) as Map<String, dynamic>,
      ),
      currentUser: json['current_user'] == null
          ? null
          : LeaderboardEntry.fromJson(
              json['current_user'] as Map<String, dynamic>,
            ),
      podium: (json['podium'] as List? ?? const [])
          .map(
              (item) => LeaderboardEntry.fromJson(item as Map<String, dynamic>))
          .toList(),
      leaderboard: (json['leaderboard'] as List? ?? const [])
          .map(
              (item) => LeaderboardEntry.fromJson(item as Map<String, dynamic>))
          .toList(),
      aroundMe: (json['around_me'] as List? ?? const [])
          .map(
              (item) => LeaderboardEntry.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SessionResult {
  final int overallScore;
  final int xpEarned;
  final int streak;
  final Map<String, int> metrics;
  final String aiFeedback;
  final String transcription;
  final int durationSec;
  final String nextQuestion;

  SessionResult({
    required this.overallScore,
    required this.xpEarned,
    required this.streak,
    required this.metrics,
    required this.aiFeedback,
    this.transcription = '',
    this.durationSec = 0,
    this.nextQuestion = '',
  });
}
