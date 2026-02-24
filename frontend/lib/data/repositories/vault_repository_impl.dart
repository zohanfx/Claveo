import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import '../../core/utils/crypto_utils.dart';
import '../../domain/entities/vault_entry_entity.dart';
import '../../domain/repositories/vault_repository.dart';
import '../datasources/remote/vault_remote_datasource.dart';
import '../models/vault_entry_model.dart';

class VaultRepositoryImpl implements VaultRepository {
  final VaultRemoteDatasource _remoteDatasource;

  VaultRepositoryImpl({required VaultRemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  @override
  Future<List<VaultEntryEntity>> getAll({
    required SecretKey encryptionKey,
  }) async {
    final remoteEntries = await _remoteDatasource.getAll();

    final decrypted = await Future.wait(
      remoteEntries.map((e) => _decryptEntry(e, encryptionKey)),
    );

    return decrypted.whereType<VaultEntryEntity>().toList();
  }

  @override
  Future<VaultEntryEntity> create({
    required VaultEntryEntity entry,
    required SecretKey encryptionKey,
  }) async {
    final (encryptedData, iv, mac) = await _encryptEntry(entry, encryptionKey);

    final remoteEntry = await _remoteDatasource.create(
      encryptedData: encryptedData,
      iv: iv,
      mac: mac,
    );

    return entry.copyWith(
      id: remoteEntry.id,
      fechaCreacion: remoteEntry.createdAt,
      fechaActualizacion: remoteEntry.updatedAt,
    );
  }

  @override
  Future<VaultEntryEntity> update({
    required VaultEntryEntity entry,
    required SecretKey encryptionKey,
  }) async {
    final (encryptedData, iv, mac) = await _encryptEntry(entry, encryptionKey);

    final remoteEntry = await _remoteDatasource.update(
      id: entry.id,
      encryptedData: encryptedData,
      iv: iv,
      mac: mac,
    );

    return entry.copyWith(
      fechaActualizacion: remoteEntry.updatedAt,
    );
  }

  @override
  Future<void> delete({required String id}) {
    return _remoteDatasource.delete(id);
  }

  @override
  Future<void> clearLocalCache() async {
    // Placeholder for future local cache implementation
  }

  Future<(String encryptedData, String iv, String mac)> _encryptEntry(
    VaultEntryEntity entry,
    SecretKey key,
  ) async {
    final plaintext = jsonEncode(entry.toJson());
    final encrypted = await CryptoUtils.encrypt(plaintext: plaintext, key: key);
    return (
      encrypted['ciphertext']!,
      encrypted['iv']!,
      encrypted['mac']!,
    );
  }

  Future<VaultEntryEntity?> _decryptEntry(
    VaultEntryRemoteModel remote,
    SecretKey key,
  ) async {
    try {
      final plaintext = await CryptoUtils.decrypt(
        ciphertext: remote.encryptedData,
        iv: remote.iv,
        mac: remote.mac,
        key: key,
      );

      final json = jsonDecode(plaintext) as Map<String, dynamic>;
      json['id'] = remote.id;
      json['fechaCreacion'] = remote.createdAt.toIso8601String();
      json['fechaActualizacion'] = remote.updatedAt.toIso8601String();

      return VaultEntryModel.fromJson(json);
    } catch (e) {
      // Decryption failed — skip this entry (tampered or wrong key)
      return null;
    }
  }
}
