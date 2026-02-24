import 'package:cryptography/cryptography.dart';
import '../entities/vault_entry_entity.dart';

abstract class VaultRepository {
  Future<List<VaultEntryEntity>> getAll({required SecretKey encryptionKey});

  Future<VaultEntryEntity> create({
    required VaultEntryEntity entry,
    required SecretKey encryptionKey,
  });

  Future<VaultEntryEntity> update({
    required VaultEntryEntity entry,
    required SecretKey encryptionKey,
  });

  Future<void> delete({required String id});

  Future<void> clearLocalCache();
}
