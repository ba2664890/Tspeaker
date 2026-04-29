import '../models/user.dart';
import 'api_service.dart';

class UserService {
  final ApiService _apiService;

  UserService(this._apiService);

  Future<User> getUserProfile() async {
    final response = await _apiService.get('/auth/me/');
    if (response.statusCode == 200) {
      // Backend wraps: { success: true, data: { ...user } }
      final data =
          (response.data['data'] ?? response.data) as Map<String, dynamic>;
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

  Future<LeaderboardData> getLeaderboard({String scope = 'weekly'}) async {
    final response = await _apiService.get(
      '/auth/leaderboard/',
      queryParameters: {'scope': scope},
    );

    if (response.statusCode == 200) {
      final data =
          (response.data['data'] ?? response.data) as Map<String, dynamic>;
      return LeaderboardData.fromJson(data);
    }

    throw Exception('Impossible de charger le classement');
  }
}
