import '../../entities/user_entity.dart';
import '../../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  Future<({UserEntity user, String accessToken, String refreshToken})> call({
    required String email,
    required String masterPassword,
  }) {
    return _repository.register(
      email: email,
      masterPassword: masterPassword,
    );
  }
}
