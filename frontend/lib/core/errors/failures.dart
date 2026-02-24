import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Error de conexión. Verifica tu internet.'])
      : super(message, code: 'NETWORK_ERROR');
}

class ServerFailure extends Failure {
  const ServerFailure([
    String message = 'Error del servidor. Intenta más tarde.',
    String? code,
  ]) : super(message, code: code);
}

class AuthFailure extends Failure {
  const AuthFailure([
    String message = 'Error de autenticación.',
    String? code,
  ]) : super(message, code: code);
}

class CryptoFailure extends Failure {
  const CryptoFailure([String message = 'Error de cifrado.', String? code])
      : super(message, code: code);
}

class StorageFailure extends Failure {
  const StorageFailure([
    String message = 'Error de almacenamiento local.',
    String? code,
  ]) : super(message, code: code);
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message, code: 'VALIDATION_ERROR');
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([
    String message = 'Recurso no encontrado.',
    String? code = 'NOT_FOUND',
  ]) : super(message, code: code);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([
    String message = 'Ocurrió un error inesperado.',
    String? code = 'UNEXPECTED',
  ]) : super(message, code: code);
}
