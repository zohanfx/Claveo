import 'package:cryptography/cryptography.dart';
import '../../entities/user_entity.dart';
import '../../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  Future<({UserEntity user, String accessToken, String refreshToken, SecretKey encryptionKey})> call({
    required String email,
    required String masterPassword,
  }) {
    return _repository.login(
      email: email,
      masterPassword: masterPassword,
    );
  }
}
