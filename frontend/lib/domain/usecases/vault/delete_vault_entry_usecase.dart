import '../../repositories/vault_repository.dart';

class DeleteVaultEntryUseCase {
  final VaultRepository _repository;

  DeleteVaultEntryUseCase(this._repository);

  Future<void> call({required String id}) {
    return _repository.delete(id: id);
  }
}
