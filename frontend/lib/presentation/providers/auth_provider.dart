import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/utils/crypto_utils.dart';
import '../../data/datasources/local/secure_storage_datasource.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/auth/login_usecase.dart';
import '../../domain/usecases/auth/logout_usecase.dart';
import '../../domain/usecases/auth/register_usecase.dart';

// ── Dependency providers ──────────────────────────────────────────────────────

final _storageProvider = Provider<SecureStorageDatasource>(
  (_) => SecureStorageDatasource(),
);

final _dioProvider = Provider<Dio>((_) => dioProvider);

final _authRemoteProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasource(ref.watch(_dioProvider));
});

final _authRepoProvider = Provider<AuthRepositoryImpl>((ref) {
  return AuthRepositoryImpl(
    remoteDatasource: ref.watch(_authRemoteProvider),
    localStorage: ref.watch(_storageProvider),
  );
});

// ── Auth state ────────────────────────────────────────────────────────────────

enum AuthStatus { loading, authenticated, unauthenticated }

@immutable
class AuthState {
  final AuthStatus status;
  final UserEntity? user;
  final SecretKey? encryptionKey;
  final bool isVaultUnlocked;
  final bool onboardingDone;
  final bool pinSetupRequired;
  final String? error;

  const AuthState({
    this.status = AuthStatus.loading,
    this.user,
    this.encryptionKey,
    this.isVaultUnlocked = false,
    this.onboardingDone = false,
    this.pinSetupRequired = false,
    this.error,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    SecretKey? encryptionKey,
    bool? isVaultUnlocked,
    bool? onboardingDone,
    bool? pinSetupRequired,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      encryptionKey: encryptionKey ?? this.encryptionKey,
      isVaultUnlocked: isVaultUnlocked ?? this.isVaultUnlocked,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      pinSetupRequired: pinSetupRequired ?? this.pinSetupRequired,
      error: error,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends ChangeNotifier {
  final AuthRepositoryImpl _repo;
  final SecureStorageDatasource _storage;
  final LocalAuthentication _localAuth = LocalAuthentication();

  AuthState _state = const AuthState();
  AuthState get state => _state;

  // Convenience getter used by vault_provider
  SecretKey? get encryptionKey => _state.encryptionKey;

  AuthNotifier(this._repo, this._storage) {
    // Register token-refresh interceptor; remove first to avoid duplicates on hot-restart
    dioProvider.interceptors
      ..removeWhere((i) => i is TokenRefreshInterceptor)
      ..add(TokenRefreshInterceptor(_storage, dioProvider));
    _initialize();
  }

  void _emit(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> _initialize() async {
    final onboardingDone = await _storage.isOnboardingDone();
    final accessToken = await _storage.getAccessToken();
    final email = await _storage.getUserEmail();

    if (accessToken == null || email == null) {
      _emit(AuthState(
        status: AuthStatus.unauthenticated,
        onboardingDone: onboardingDone,
      ));
      return;
    }

    // Tokens exist — user is authenticated but vault needs unlock
    _emit(AuthState(
      status: AuthStatus.authenticated,
      onboardingDone: onboardingDone,
      isVaultUnlocked: false,
    ));

    // Update auth header on the Dio instance
    _updateDioToken(accessToken);
  }

  Future<void> register({
    required String email,
    required String masterPassword,
  }) async {
    _emit(_state.copyWith(status: AuthStatus.loading, error: null));
    try {
      final useCase = RegisterUseCase(_repo);
      final result = await useCase(email: email, masterPassword: masterPassword);

      _updateDioToken(result.accessToken);

      // After registration, derive encryption key for the session
      final salt = await _storage.getKdfSalt();
      SecretKey? encKey;
      if (salt != null) {
        encKey = await CryptoUtils.deriveEncryptionKey(
          masterPassword: masterPassword,
          email: email,
          salt: salt,
        );
      }

      final hasPin = await _storage.hasPin();

      _emit(_state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        encryptionKey: encKey,
        isVaultUnlocked: true,
        pinSetupRequired: !hasPin,
      ));
    } catch (e) {
      _emit(_state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      ));
      rethrow;
    }
  }

  Future<void> login({
    required String email,
    required String masterPassword,
  }) async {
    _emit(_state.copyWith(status: AuthStatus.loading, error: null));
    try {
      final useCase = LoginUseCase(_repo);
      final result = await useCase(email: email, masterPassword: masterPassword);

      _updateDioToken(result.accessToken);
      await _storage.updateLastActiveTime();

      final hasPin = await _storage.hasPin();

      _emit(_state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        encryptionKey: result.encryptionKey,
        isVaultUnlocked: true,
        pinSetupRequired: !hasPin,
      ));
    } catch (e) {
      _emit(_state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      ));
      rethrow;
    }
  }

  Future<void> logout() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken != null) {
      final useCase = LogoutUseCase(_repo);
      await useCase(refreshToken: refreshToken).catchError((_) {});
    }

    _clearDioToken();
    _emit(AuthState(
      status: AuthStatus.unauthenticated,
      onboardingDone: _state.onboardingDone,
    ));
  }

  Future<bool> unlockWithBiometric() async {
    try {
      final canAuth = await _localAuth.canCheckBiometrics;
      if (!canAuth) return false;

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Desbloquea Claveo con tu huella o Face ID',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (!authenticated) return false;

      // Retrieve stored encryption key
      final keyBytes = await _storage.getEncryptionKey();
      if (keyBytes == null) return false;

      final encKey = CryptoUtils.bytesToSecretKey(keyBytes);
      await _storage.updateLastActiveTime();

      _emit(_state.copyWith(
        isVaultUnlocked: true,
        encryptionKey: encKey,
      ));

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unlockWithPin(String pin) async {
    try {
      var storedPin = await _storage.getPin();
      // No PIN stored yet — bootstrap the default on first use
      if (storedPin == null) {
        await _storage.savePin('1234');
        storedPin = '1234';
      }
      if (pin != storedPin) return false;

      final keyBytes = await _storage.getEncryptionKey();
      if (keyBytes == null) return false;

      final encKey = CryptoUtils.bytesToSecretKey(keyBytes);
      await _storage.updateLastActiveTime();

      _emit(_state.copyWith(
        isVaultUnlocked: true,
        encryptionKey: encKey,
      ));

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getStoredEmail() => _storage.getUserEmail();

  Future<void> completePinSetup(String pin) async {
    await _storage.savePin(pin);
    _emit(_state.copyWith(pinSetupRequired: false));
  }

  void lockVault() {
    _emit(_state.copyWith(isVaultUnlocked: false, encryptionKey: null));
  }

  Future<void> completeOnboarding() async {
    await _storage.setOnboardingDone();
    _emit(_state.copyWith(onboardingDone: true));
  }

  Future<void> updateLastActive() async {
    await _storage.updateLastActiveTime();
  }

  Future<bool> checkAutoLock() async {
    final lastMs = await _storage.getLastActiveMs();
    if (lastMs == null) return true;

    final elapsed = DateTime.now().millisecondsSinceEpoch - lastMs;
    final timeoutMs = 300 * 1000; // 5 min
    return elapsed > timeoutMs;
  }

  void _updateDioToken(String token) {
    dioProvider.options.headers['Authorization'] = 'Bearer $token';
  }

  void _clearDioToken() {
    dioProvider.options.headers.remove('Authorization');
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final authProvider = ChangeNotifierProvider<AuthNotifier>((ref) {
  return AuthNotifier(
    ref.watch(_authRepoProvider),
    ref.watch(_storageProvider),
  );
});
