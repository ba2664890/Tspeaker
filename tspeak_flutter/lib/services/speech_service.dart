import 'dart:async';
import 'package:dio/dio.dart';
import 'api_service.dart';

class VoiceSessionStart {
  final String sessionId;
  final String firstQuestion;

  const VoiceSessionStart({
    required this.sessionId,
    required this.firstQuestion,
  });
}

class SpeechService {
  final ApiService _apiService;

  SpeechService(this._apiService);

  Future<VoiceSessionStart?> startSessionDetails({
    String sessionType = 'conversation',
    String scenario = 'daily_life',
    String difficulty = 'beginner',
    String? simulationId,
  }) async {
    try {
      final response = await _apiService.post('/sessions/start/', data: {
        'session_type': sessionType,
        'scenario': scenario,
        'difficulty': difficulty,
        if (simulationId != null) 'simulation_id': simulationId,
      });
      if (response.statusCode == 201 || response.statusCode == 200) {
        final sessionId = response.data['session_id']?.toString();
        if (sessionId == null || sessionId.isEmpty) return null;
        return VoiceSessionStart(
          sessionId: sessionId,
          firstQuestion: (response.data['first_question'] ??
                  'Hello! Tell me about yourself and your goals today.')
              .toString(),
        );
      }
      return null;
    } on DioException {
      return null;
    }
  }

  Future<String?> startSession({
    String sessionType = 'conversation',
    String scenario = 'daily_life',
    String difficulty = 'beginner',
    String? simulationId,
  }) async {
    final details = await startSessionDetails(
      sessionType: sessionType,
      scenario: scenario,
      difficulty: difficulty,
      simulationId: simulationId,
    );
    return details?.sessionId;
  }

  Future<Map<String, dynamic>?> uploadAudio(
    String sessionId,
    String filePath, {
    String question = '',
    double durationSec = 0,
  }) async {
    try {
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(filePath),
        'question': question,
        'duration_sec': durationSec,
      });

      final response = await _apiService.post(
        '/sessions/$sessionId/audio/',
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        return response.data;
      }
      return null;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) return data;
      return null;
    }
  }

  Future<Map<String, dynamic>?> getExchangeResult(String exchangeId) async {
    try {
      final response = await _apiService.get(
        '/sessions/exchanges/$exchangeId/result/',
        options: Options(receiveTimeout: const Duration(seconds: 120)),
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) return data;
      return null;
    }
  }

  Future<Map<String, dynamic>?> waitForExchangeResult(
    String exchangeId, {
    Duration timeout = const Duration(seconds: 45),
    Duration interval = const Duration(seconds: 2),
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      final response = await getExchangeResult(exchangeId);
      if (response != null && response['status'] == 'completed') {
        return response;
      }
      if (response != null &&
          (response['status'] == 'failed' || response['success'] == false)) {
        return response;
      }
      await Future<void>.delayed(interval);
    }

    return null;
  }

  Future<Map<String, dynamic>?> endSession(
    String sessionId, {
    int durationSec = 0,
  }) async {
    try {
      final response = await _apiService.post(
        '/sessions/$sessionId/end/',
        data: {'duration_sec': durationSec},
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getSessionScores(String sessionId) async {
    try {
      final response = await _apiService.get('/scores/$sessionId/');
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
