import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class ApiService {
  late Dio _dio;
  static const String baseUrl = 'http://localhost:8001/api/v1';

  ApiService({String? baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? ApiService.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          try {
            final prefs = await SharedPreferences.getInstance();
            final refreshToken = prefs.getString('refresh_token');
            if (refreshToken != null) {
              final refreshResp = await _dio.post(
                '/auth/refresh/',
                data: {'refresh': refreshToken},
                options: Options(
                  headers: {'Authorization': null}, // no auth header for refresh
                ),
              );
              if (refreshResp.statusCode == 200) {
                final newAccess = refreshResp.data['access'] as String;
                await prefs.setString('access_token', newAccess);
                e.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
                final retryResponse = await _dio.fetch(e.requestOptions);
                return handler.resolve(retryResponse);
              }
            }
          } catch (_) {
            // Terminal failure (refresh failed or banned)
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('access_token');
            await prefs.remove('refresh_token');
            TSpeakApp.navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
          }
        }
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> patch(String path, {dynamic data}) async {
    try {
      return await _dio.patch(path, data: data);
    } catch (e) {
      rethrow;
    }
  }
}
