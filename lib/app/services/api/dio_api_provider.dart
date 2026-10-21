import 'dart:async';
import 'package:dio/dio.dart';
import '../../app_constants/app_config.dart';
import '../../app_constants/app_text.dart';
import '../../shared/errors/app_failure.dart';
import 'api_provider_service.dart';

/// HTTP scaffold. The workshop uses MockApiProvider.
class DioApiProvider implements ApiProviderService {
  DioApiProvider({required String baseUrl})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: AppConfig.networkTimeout,
          receiveTimeout: AppConfig.networkTimeout,
          headers: {'Content-Type': 'application/json'},
        ),
      );
  final Dio _dio;
  String? token;
  final _changes = StreamController<void>.broadcast();
  @override
  Stream<void> get changes => _changes.stream;
  @override
  Future<Json> request(
    String method,
    String path, {
    Json body = const {},
    Json query = const {},
  }) async {
    try {
      final response = await _dio.request<Json>(
        path,
        data: method == 'GET' ? null : body,
        queryParameters: query,
        options: Options(
          method: method,
          headers: token == null ? null : {'Authorization': 'Bearer $token'},
        ),
      );
      final data = response.data ?? <String, dynamic>{};
      if (path.endsWith('/otp/verify')) {
        token = (data['data'] as Json?)?['token'] as String?;
      }
      if (path.endsWith('/logout')) token = null;
      if (method != 'GET') _changes.add(null);
      return data;
    } on DioException catch (error) {
      final code = error.response?.statusCode;
      throw AppFailure('$code', switch (code) {
        401 => AppText.authRequired,
        403 => AppText.accessDenied,
        404 => AppText.notFound,
        _ => AppText.connectionFailure,
      });
    }
  }

  @override
  Future<void> dispose() async {
    _dio.close();
    await _changes.close();
  }
}
