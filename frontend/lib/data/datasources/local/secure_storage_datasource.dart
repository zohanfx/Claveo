import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_constants.dart';

class SecureStorageDatasource {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // ── Token management ──────────────────────────────────────

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: AppConstants.kAccessToken, value: accessToken),
      _storage.write(key: AppConstants.kRefreshToken, value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken() =>
      _storage.read(key: AppConstants.kAccessToken);

  Future<String?> getRefreshToken() =>
      _storage.read(key: AppConstants.kRefreshToken);

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: AppConstants.kAccessToken),
      _storage.delete(key: AppConstants.kRefreshToken),
    ]);
  }

  // ── Encryption key ────────────────────────────────────────

  Future<void> saveEncryptionKey(Uint8List keyBytes) async {
    await _storage.write(
      key: AppConstants.kEncryptionKeyBytes,
      value: base64.encode(keyBytes),
    );
  }

  Future<Uint8List?> getEncryptionKey() async {
    final encoded = await _storage.read(key: AppConstants.kEncryptionKeyBytes);
    if (encoded == null) return null;
    return base64.decode(encoded);
  }

  Future<void> clearEncryptionKey() async {
    await _storage.delete(key: AppConstants.kEncryptionKeyBytes);
  }

  // ── User info ─────────────────────────────────────────────

  Future<void> saveUserEmail(String email) =>
      _storage.write(key: AppConstants.kUserEmail, value: email);

  Future<String?> getUserEmail() =>
      _storage.read(key: AppConstants.kUserEmail);

  Future<void> saveKdfSalt(String salt) =>
      _storage.write(key: AppConstants.kKdfSalt, value: salt);

  Future<String?> getKdfSalt() => _storage.read(key: AppConstants.kKdfSalt);

  // ── Settings ──────────────────────────────────────────────

  Future<void> setBiometricEnabled(bool enabled) => _storage.write(
        key: AppConstants.kBiometricEnabled,
        value: enabled.toString(),
      );

  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: AppConstants.kBiometricEnabled);
    return val == 'true';
  }

  Future<void> setOnboardingDone() =>
      _storage.write(key: AppConstants.kOnboardingDone, value: 'true');

  Future<bool> isOnboardingDone() async {
    final val = await _storage.read(key: AppConstants.kOnboardingDone);
    return val == 'true';
  }

  Future<void> setDarkMode(bool enabled) => _storage.write(
        key: AppConstants.kDarkMode,
        value: enabled.toString(),
      );

  Future<bool> getDarkMode() async {
    final val = await _storage.read(key: AppConstants.kDarkMode);
    return val == 'true';
  }

  Future<void> updateLastActiveTime() => _storage.write(
        key: AppConstants.kLastActiveMs,
        value: DateTime.now().millisecondsSinceEpoch.toString(),
      );

  Future<int?> getLastActiveMs() async {
    final val = await _storage.read(key: AppConstants.kLastActiveMs);
    if (val == null) return null;
    return int.tryParse(val);
  }

  // ── PIN ───────────────────────────────────────────────────

  Future<void> savePin(String pin) =>
      _storage.write(key: AppConstants.kPinCode, value: pin);

  Future<String?> getPin() => _storage.read(key: AppConstants.kPinCode);

  Future<bool> hasPin() async {
    final val = await _storage.read(key: AppConstants.kPinCode);
    return val != null;
  }

  // ── Full clear (on logout) ────────────────────────────────

  Future<void> clearSensitiveData() async {
    await Future.wait([
      _storage.delete(key: AppConstants.kAccessToken),
      _storage.delete(key: AppConstants.kRefreshToken),
      _storage.delete(key: AppConstants.kEncryptionKeyBytes),
      _storage.delete(key: AppConstants.kKdfSalt),
    ]);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
