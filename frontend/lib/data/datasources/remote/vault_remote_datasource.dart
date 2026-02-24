import 'package:dio/dio.dart';
import '../../../core/errors/failures.dart';
import '../../models/vault_entry_model.dart';

class VaultRemoteDatasource {
  final Dio _dio;

  VaultRemoteDatasource(this._dio);

  Future<List<VaultEntryRemoteModel>> getAll() async {
    try {
      final response = await _dio.get('/vault');
      final data = response.data['data'] as List<dynamic>;
      return data
          .map((e) => VaultEntryRemoteModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<VaultEntryRemoteModel> create({
    required String encryptedData,
    required String iv,
    required String mac,
  }) async {
    try {
      final response = await _dio.post('/vault', data: {
        'encryptedData': encryptedData,
        'iv': iv,
        'mac': mac,
      });
      return VaultEntryRemoteModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<VaultEntryRemoteModel> update({
    required String id,
    required String encryptedData,
    required String iv,
    required String mac,
  }) async {
    try {
      final response = await _dio.put('/vault/$id', data: {
        'encryptedData': encryptedData,
        'iv': iv,
        'mac': mac,
      });
      return VaultEntryRemoteModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete('/vault/$id');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  Failure _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return const NetworkFailure();
    }

    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    final message = (data is Map<String, dynamic>)
        ? (data['message'] as String? ?? 'Error del servidor')
        : 'Error del servidor';
    final code = (data is Map<String, dynamic>)
        ? (data['code'] as String?)
        : null;

    if (statusCode == 401) {
      return AuthFailure(message, code);
    }
    if (statusCode == 404) {
      return NotFoundFailure(message, code);
    }
    return ServerFailure(message, code);
  }
}
