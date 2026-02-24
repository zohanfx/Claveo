import 'package:equatable/equatable.dart';

class VaultEntryEntity extends Equatable {
  final String id;
  final String servicio;
  final String usuario;
  final String contrasena;
  final String url;
  final String notas;
  final String categoria;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  const VaultEntryEntity({
    required this.id,
    required this.servicio,
    required this.usuario,
    required this.contrasena,
    required this.url,
    required this.notas,
    required this.categoria,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  VaultEntryEntity copyWith({
    String? id,
    String? servicio,
    String? usuario,
    String? contrasena,
    String? url,
    String? notas,
    String? categoria,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return VaultEntryEntity(
      id: id ?? this.id,
      servicio: servicio ?? this.servicio,
      usuario: usuario ?? this.usuario,
      contrasena: contrasena ?? this.contrasena,
      url: url ?? this.url,
      notas: notas ?? this.notas,
      categoria: categoria ?? this.categoria,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'servicio': servicio,
        'usuario': usuario,
        'contrasena': contrasena,
        'url': url,
        'notas': notas,
        'categoria': categoria,
        'fechaCreacion': fechaCreacion.toIso8601String(),
        'fechaActualizacion': fechaActualizacion.toIso8601String(),
      };

  factory VaultEntryEntity.fromJson(Map<String, dynamic> json) {
    return VaultEntryEntity(
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

  @override
  List<Object?> get props => [
        id,
        servicio,
        usuario,
        contrasena,
        url,
        notas,
        categoria,
        fechaCreacion,
        fechaActualizacion,
      ];
}
