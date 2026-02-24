import '../../domain/entities/vault_entry_entity.dart';

/// Model representing a vault entry as stored/transmitted (encrypted blob).
/// The server only ever sees [encryptedData], [iv], and [mac].
class VaultEntryRemoteModel {
  final String id;
  final String encryptedData;
  final String iv;
  final String mac;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VaultEntryRemoteModel({
    required this.id,
    required this.encryptedData,
    required this.iv,
    required this.mac,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VaultEntryRemoteModel.fromJson(Map<String, dynamic> json) {
    return VaultEntryRemoteModel(
      id: json['id'] as String,
      encryptedData: json['encryptedData'] as String,
      iv: json['iv'] as String,
      mac: json['mac'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'encryptedData': encryptedData,
        'iv': iv,
        'mac': mac,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

/// Model for the local (decrypted) representation, maps to VaultEntryEntity.
class VaultEntryModel extends VaultEntryEntity {
  const VaultEntryModel({
    required super.id,
    required super.servicio,
    required super.usuario,
    required super.contrasena,
    required super.url,
    required super.notas,
    required super.categoria,
    required super.fechaCreacion,
    required super.fechaActualizacion,
  });

  factory VaultEntryModel.fromEntity(VaultEntryEntity entity) {
    return VaultEntryModel(
      id: entity.id,
      servicio: entity.servicio,
      usuario: entity.usuario,
      contrasena: entity.contrasena,
      url: entity.url,
      notas: entity.notas,
      categoria: entity.categoria,
      fechaCreacion: entity.fechaCreacion,
      fechaActualizacion: entity.fechaActualizacion,
    );
  }

  factory VaultEntryModel.fromJson(Map<String, dynamic> json) {
    return VaultEntryModel(
      id: json['id'] as String,
      servicio: json['servicio'] as String,
      usuario: json['usuario'] as String,
      contrasena: json['contrasena'] as String,
      url: json['url'] as String? ?? '',
      notas: json['notas'] as String? ?? '',
      categoria: json['categoria'] as String? ?? 'Otros',
      fechaCreacion: DateTime.parse(json['fechaCreacion'] as String),
      fechaActualizacion: DateTime.parse(json['fechaActualizacion'] as String),
    );
  }
}
