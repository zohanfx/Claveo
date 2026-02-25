import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../models/user_model.dart';

class AuthRemoteDatasource {
  final Dio _dio;

  AuthRemoteDatasource(this._dio);

  Future<String> getSalt(String email) async {
    try {
      final response = await _dio.get(
        '/auth/salt',
        queryParameters: {'email': email},
      );
      return response.data['data']['salt'] as String;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String authPassword,
    required String kdfSalt,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'authPassword': authPassword,
        'kdfSalt': kdfSalt,
      });
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String authPassword,
  }) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'authPassword': authPassword,
      });
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Map<String, dynamic>> refresh(String refreshToken) async {
    try {
      final response = await _dio.post('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
    } on DioException catch (e) {
      // Best effort — don't throw on logout failure
      if (e.response?.statusCode != 401) {
        throw _mapDioError(e);
      }
    }
  }

  Failure _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkFailure();
    }

    final statusCode = e.response?.statusCode;
    final message = _extractMessage(e.response?.data) ?? 'Error desconocido';
    final code = _extractCode(e.response?.data);

    if (statusCode == 401) return AuthFailure(message, code);
    if (statusCode == 409) return ServerFailure(message, code);
    if (statusCode == 400) return ValidationFailure(message);
    if (statusCode == 429) {
      return const ServerFailure(
        'Demasiados intentos. Intenta en 15 minutos.',
        'RATE_LIMIT',
      );
    }

    return ServerFailure(message, code);
  }

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) return data['message'] as String?;
    return null;
  }

  String? _extractCode(dynamic data) {
    if (data is Map<String, dynamic>) return data['code'] as String?;
    return null;
  }
}

final dioProvider = Dio(
  BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 15),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ),
);

/// Intercepts 401 responses, refreshes the access token, and retries.
/// On refresh failure clears all local credentials so the router redirects
/// the user back to the login screen.
class TokenRefreshInterceptor extends Interceptor {
  final dynamic _storage; // SecureStorageDatasource — typed as dynamic to avoid circular import
  final Dio _dio;
  bool _refreshing = false;

  TokenRefreshInterceptor(this._storage, this._dio);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final path = err.requestOptions.path;

    // Only handle 401s that are NOT from the refresh/logout endpoints
    if (statusCode != 401 ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/logout')) {
      return handler.next(err);
    }

    if (_refreshing) return handler.next(err);
    _refreshing = true;

    try {
      final refreshToken = await _storage.getRefreshToken() as String?;
      if (refreshToken == null) {
        await _storage.clearAll();
        return handler.next(err);
      }

      // Call refresh endpoint directly (bypass interceptor chain)
      final refreshDio = Dio(_dio.options);
      final res = await refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final data = res.data['data'] as Map<String, dynamic>;
      final newAccess = data['accessToken'] as String;
      final newRefresh = data['refreshToken'] as String;

      await _storage.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );

      // Update the shared Dio header for future requests
      _dio.options.headers['Authorization'] = 'Bearer $newAccess';

      // Retry the original failed request with the new token
      final opts = err.requestOptions;
      opts.headers['Authorization'] = 'Bearer $newAccess';
      final retried = await _dio.fetch(opts);
      return handler.resolve(retried);
    } catch (_) {
      await _storage.clearAll();
      return handler.next(err);
    } finally {
      _refreshing = false;
    }
  }
}

UserModel parseUserFromResponse(Map<String, dynamic> data) {
  final user = data['user'] as Map<String, dynamic>;
  return UserModel.fromJson(user);
}
