import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String kdfSalt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.kdfSalt,
  });

  @override
  List<Object?> get props => [id, email, kdfSalt];
}
