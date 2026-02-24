import 'package:cryptography/cryptography.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<({UserEntity user, String accessToken, String refreshToken})> register({
    required String email,
    required String masterPassword,
  });

  Future<({UserEntity user, String accessToken, String refreshToken, SecretKey encryptionKey})> login({
    required String email,
    required String masterPassword,
  });

  Future<({String accessToken, String refreshToken})> refreshTokens({
    required String refreshToken,
  });

  Future<void> logout({required String refreshToken});

  Future<String?> getSaltForEmail(String email);
}
