import 'dart:io';
import 'package:dio/dio.dart';
import 'api_service.dart';

class SpeechService {
  final ApiService _apiService;

  SpeechService(this._apiService);

  Future<String?> startSession(String simulationId) async {
    try {
      final response = await _apiService.post('/sessions/start/', data: {
        'simulation_id': simulationId,
      });
      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data['session_id'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> uploadAudio(String sessionId, String filePath) async {
    try {
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(filePath),
      });

      final response = await _apiService.post(
        '/sessions/$sessionId/audio/',
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getExchangeResult(String exchangeId) async {
    try {
      final response = await _apiService.get('/sessions/exchanges/$exchangeId/result/');
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
