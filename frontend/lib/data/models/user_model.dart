import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.kdfSalt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      kdfSalt: json['kdfSalt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'kdfSalt': kdfSalt,
      };

  UserModel copyWithModel({String? id, String? email, String? kdfSalt}) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      kdfSalt: kdfSalt ?? this.kdfSalt,
    );
  }
}
