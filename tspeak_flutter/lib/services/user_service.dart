import '../models/user.dart';
import 'api_service.dart';

class UserService {
  final ApiService _apiService;

  UserService(this._apiService);

  Future<User> getUserProfile() async {
    final response = await _apiService.get('/auth/me/');
    if (response.statusCode == 200) {
      // Backend wraps: { success: true, data: { ...user } }
      final data = (response.data['data'] ?? response.data) as Map<String, dynamic>;
      return User.fromJson(data);
    }
    throw Exception('Impossible de charger le profil utilisateur');
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.patch('/auth/me/', data: data);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<LeaderboardEntry>> getLeaderboard() async {
    try {
      final response = await _apiService.get('/auth/leaderboard/');
      if (response.statusCode == 200) {
        return (response.data as List)
            .map<LeaderboardEntry>((e) => LeaderboardEntry.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

// Add fromJson to LeaderboardEntry if missing
extension LeaderboardEntryJson on LeaderboardEntry {
  static LeaderboardEntry fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'],
      name: json['name'],
      avatarUrl: json['avatar_url'] ?? '',
      xp: json['xp'],
      league: json['league'] ?? '',
      isCurrentUser: json['is_current_user'] ?? false,
    );
  }
}
