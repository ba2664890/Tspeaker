import 'package:flutter/widgets.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../utils/debug_logger.dart';

class ApiService {
  late Dio _dio;
  static const String baseUrl = 'https://high-donate-vat-wrote.trycloudflare.com/api/v1/';
  bool _isRefreshing = false;

  ApiService({String? baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? ApiService.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) {
        final msg = obj.toString();
        print('DIO_LOG: $msg');
        DebugLogger().log(msg);
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (options.data is FormData) {
          options.contentType = Headers.multipartFormDataContentType;
        }
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401 && !_isRefreshing) {
          // Don't try to refresh if this is already a refresh attempt
          if (e.requestOptions.path.contains('/auth/refresh/')) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('access_token');
            await prefs.remove('refresh_token');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              TSpeakApp.navigatorKey.currentState
                  ?.pushNamedAndRemoveUntil('/login', (route) => false);
            });
            return handler.next(e);
          }

          _isRefreshing = true;
          try {
            final prefs = await SharedPreferences.getInstance();
            final refreshToken = prefs.getString('refresh_token');
            if (refreshToken != null) {
              final refreshDio = Dio(BaseOptions(
                baseUrl: _dio.options.baseUrl,
                connectTimeout: _dio.options.connectTimeout,
                receiveTimeout: _dio.options.receiveTimeout,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ));
              final refreshResp = await refreshDio.post(
                '/auth/refresh/',
                data: {'refresh': refreshToken},
              );
              if (refreshResp.statusCode == 200) {
                final newAccess = refreshResp.data['access']?.toString();
                final newRefresh =
                    refreshResp.data['refresh']?.toString() ?? refreshToken;
                if (newAccess == null || newAccess.isEmpty) {
                  throw DioException(
                    requestOptions: e.requestOptions,
                    message: 'Refresh token response missing access token.',
                  );
                }
                await prefs.setString('access_token', newAccess);
                await prefs.setString('refresh_token', newRefresh);
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
            WidgetsBinding.instance.addPostFrameCallback((_) {
              TSpeakApp.navigatorKey.currentState
                  ?.pushNamedAndRemoveUntil('/login', (route) => false);
            });
          } finally {
            _isRefreshing = false;
          }
        }
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> post(String path, {dynamic data, Options? options}) async {
    try {
      return await _dio.post(path, data: data, options: options);
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
