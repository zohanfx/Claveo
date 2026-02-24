import 'package:cryptography/cryptography.dart';
import '../../core/utils/crypto_utils.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/secure_storage_datasource.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remoteDatasource;
  final SecureStorageDatasource _localStorage;

  AuthRepositoryImpl({
    required AuthRemoteDatasource remoteDatasource,
    required SecureStorageDatasource localStorage,
  })  : _remoteDatasource = remoteDatasource,
        _localStorage = localStorage;

  @override
  Future<({UserEntity user, String accessToken, String refreshToken})> register({
    required String email,
    required String masterPassword,
  }) async {
    final kdfSalt = CryptoUtils.generateSalt();

    final authPassword = await CryptoUtils.deriveAuthPassword(
      masterPassword: masterPassword,
      email: email,
      salt: kdfSalt,
    );

    final responseData = await _remoteDatasource.register(
      email: email,
      authPassword: authPassword,
      kdfSalt: kdfSalt,
    );

    final user = UserModel.fromJson(responseData['user'] as Map<String, dynamic>);
    final tokens = responseData['tokens'] as Map<String, dynamic>;
    final accessToken = tokens['accessToken'] as String;
    final refreshToken = tokens['refreshToken'] as String;

    // Derive encryption key and store securely
    final encKey = await CryptoUtils.deriveEncryptionKey(
      masterPassword: masterPassword,
      email: email,
      salt: kdfSalt,
    );
    final keyBytes = await CryptoUtils.secretKeyToBytes(encKey);

    await Future.wait([
      _localStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      ),
      _localStorage.saveUserEmail(email),
      _localStorage.saveKdfSalt(kdfSalt),
      _localStorage.saveEncryptionKey(keyBytes),
    ]);

    return (user: user as UserEntity, accessToken: accessToken, refreshToken: refreshToken);
  }

  @override
  Future<({UserEntity user, String accessToken, String refreshToken, SecretKey encryptionKey})>
      login({
    required String email,
    required String masterPassword,
  }) async {
    // Step 1: Retrieve the KDF salt stored for this user
    final kdfSalt = await _remoteDatasource.getSalt(email);

    // Step 2: Derive authentication password (sent to server)
    final authPassword = await CryptoUtils.deriveAuthPassword(
      masterPassword: masterPassword,
      email: email,
      salt: kdfSalt,
    );

    // Step 3: Login
    final responseData = await _remoteDatasource.login(
      email: email,
      authPassword: authPassword,
    );

    final user = UserModel.fromJson(
      responseData['user'] as Map<String, dynamic>,
    );
    final tokensMap = responseData['tokens'] as Map<String, dynamic>;
    final accessToken = tokensMap['accessToken'] as String;
    final refreshToken = tokensMap['refreshToken'] as String;

    // Step 4: Derive encryption key (client-side only, using master password)
    final encryptionKey = await CryptoUtils.deriveEncryptionKey(
      masterPassword: masterPassword,
      email: email,
      salt: kdfSalt,
    );

    final keyBytes = await CryptoUtils.secretKeyToBytes(encryptionKey);

    await Future.wait([
      _localStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      ),
      _localStorage.saveUserEmail(email),
      _localStorage.saveKdfSalt(kdfSalt),
      _localStorage.saveEncryptionKey(keyBytes),
    ]);

    return (
      user: user as UserEntity,
      accessToken: accessToken,
      refreshToken: refreshToken,
      encryptionKey: encryptionKey,
    );
  }

  @override
  Future<({String accessToken, String refreshToken})> refreshTokens({
    required String refreshToken,
  }) async {
    final data = await _remoteDatasource.refresh(refreshToken);
    final newAccessToken = data['accessToken'] as String;
    final newRefreshToken = data['refreshToken'] as String;

    await _localStorage.saveTokens(
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
    );

    return (accessToken: newAccessToken, refreshToken: newRefreshToken);
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    await _remoteDatasource.logout(refreshToken);
    await _localStorage.clearSensitiveData();
  }

  @override
  Future<String?> getSaltForEmail(String email) async {
    try {
      return await _remoteDatasource.getSalt(email);
    } catch (_) {
      return null;
    }
  }
}
