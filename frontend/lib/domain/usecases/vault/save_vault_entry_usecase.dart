import 'package:cryptography/cryptography.dart';
import '../../entities/vault_entry_entity.dart';
import '../../repositories/vault_repository.dart';

class SaveVaultEntryUseCase {
  final VaultRepository _repository;

  SaveVaultEntryUseCase(this._repository);

  Future<VaultEntryEntity> create({
    required VaultEntryEntity entry,
    required SecretKey encryptionKey,
  }) {
    return _repository.create(entry: entry, encryptionKey: encryptionKey);
  }

  Future<VaultEntryEntity> update({
    required VaultEntryEntity entry,
    required SecretKey encryptionKey,
  }) {
    return _repository.update(entry: entry, encryptionKey: encryptionKey);
  }
}
