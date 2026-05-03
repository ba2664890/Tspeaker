import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthException implements Exception {
  final String message;
  final int? statusCode;
  final int? retryAfterSeconds;

  const AuthException(
    this.message, {
    this.statusCode,
    this.retryAfterSeconds,
  });

  @override
  String toString() => message;
}

class AuthService {
  final ApiService _apiService;

  AuthService(this._apiService);

  // ──────────────────────────────── Token management ────────────────────

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) return false;

    // Verify token validity by calling /auth/me/
    try {
      final response = await _apiService.get('/auth/me/');
      return response.statusCode == 200;
    } catch (e) {
      // If unauthorized, clear tokens
      await _clearTokens();
      return false;
    }
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> _saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
  }

  Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  // ──────────────────────────────── Auth actions ────────────────────────

  /// Returns User on success, null on failure.
  Future<User?> login(String email, String password) async {
    try {
      final response = await _apiService.post('auth/login/', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        await _saveTokens(
          response.data['access'] as String,
          response.data['refresh'] as String,
        );
        // Backend enriches login response with user data
        if (response.data['user'] != null) {
          return User.fromJson(response.data['user'] as Map<String, dynamic>);
        }
        return null;
      }
      return null;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;

      if (statusCode == 401) {
        return null;
      }

      if (statusCode == 429) {
        throw AuthException(
          _extractErrorMessage(responseData) ??
              'Trop de tentatives. Réessaie dans quelques secondes.',
          statusCode: statusCode,
          retryAfterSeconds: _extractRetryAfterSeconds(responseData),
        );
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw const AuthException(
          'Impossible de joindre le serveur pour le moment.',
        );
      }

      throw AuthException(
        _extractErrorMessage(responseData) ??
            'Une erreur est survenue pendant la connexion.',
        statusCode: statusCode,
      );
    }
  }

  Future<User?> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String nativeLanguage,
    required String level,
    required bool gdprConsent,
    String bio = '',
    String country = '',
    String learningGoal = '',
    String interests = '',
    String ageRange = '',
  }) async {
    try {
      final response = await _apiService.post('/auth/register/', data: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'password_confirm': password,
        'native_language': nativeLanguage,
        'level': level,
        'bio': bio,
        'country': country,
        'learning_goal': learningGoal,
        'interests': interests,
        'age_range': ageRange,
        'gdpr_consent': gdprConsent,
      });

      if (response.statusCode == 201) {
        // Register endpoint returns tokens directly — no second login call needed
        await _saveTokens(
          response.data['tokens']['access'] as String,
          response.data['tokens']['refresh'] as String,
        );
        return User.fromJson(response.data['user'] as Map<String, dynamic>);
      }
      return null;
    } on DioException {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      if (refreshToken != null) {
        await _apiService.post('/auth/logout/', data: {
          'refresh_token': refreshToken,
        });
      }
    } catch (_) {
      // Ignore errors — clear tokens regardless
    } finally {
      await _clearTokens();
    }
  }

  Future<bool> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      if (refreshToken == null) return false;

      final response = await _apiService.post('/auth/refresh/', data: {
        'refresh': refreshToken,
      });
      if (response.statusCode == 200) {
        await _saveTokens(
          response.data['access'] as String,
          response.data['refresh'] as String, // Update refresh token too
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  String? _extractErrorMessage(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final error = responseData['error'];
      if (error is Map<String, dynamic>) {
        final message = error['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
      }

      final detail = responseData['detail'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
    }

    return null;
  }

  int? _extractRetryAfterSeconds(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final retryAfter = responseData['retry_after'];
      if (retryAfter is int) return retryAfter;
      if (retryAfter is num) return retryAfter.toInt();

      final detail = responseData['detail'];
      if (detail is String) {
        final match = RegExp(r'(\d+)').firstMatch(detail);
        if (match != null) {
          return int.tryParse(match.group(1)!);
        }
      }
    }

    return null;
  }
}
