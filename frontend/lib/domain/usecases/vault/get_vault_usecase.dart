import 'package:cryptography/cryptography.dart';
import '../../entities/vault_entry_entity.dart';
import '../../repositories/vault_repository.dart';

class GetVaultUseCase {
  final VaultRepository _repository;

  GetVaultUseCase(this._repository);

  Future<List<VaultEntryEntity>> call({required SecretKey encryptionKey}) {
    return _repository.getAll(encryptionKey: encryptionKey);
  }
}
