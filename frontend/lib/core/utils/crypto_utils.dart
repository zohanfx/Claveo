import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import '../constants/app_constants.dart';

class CryptoUtils {
  CryptoUtils._();

  /// Generate a cryptographically secure random salt (base64url encoded)
  static String generateSalt([int byteLength = 32]) {
    final random = Random.secure();
    final bytes = Uint8List.fromList(
      List<int>.generate(byteLength, (_) => random.nextInt(256)),
    );
    return base64Url.encode(bytes);
  }

  /// Derive the AES-256 encryption key from master password.
  /// This key NEVER leaves the device.
  static Future<SecretKey> deriveEncryptionKey({
    required String masterPassword,
    required String email,
    required String salt,
  }) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: AppConstants.pbkdf2EncIterations,
      bits: AppConstants.keyLengthBits,
    );

    // Nonce = email + static suffix + user salt
    final nonce = utf8.encode(
      '${email.toLowerCase()}${AppConstants.encKeySuffix}$salt',
    );

    return pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(masterPassword)),
      nonce: nonce,
    );
  }

  /// Derive the authentication password to send to the server.
  /// Uses different derivation params than the encryption key.
  /// The server hashes this with bcrypt — it never sees the master password.
  static Future<String> deriveAuthPassword({
    required String masterPassword,
    required String email,
    required String salt,
  }) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: AppConstants.pbkdf2AuthIterations,
      bits: AppConstants.keyLengthBits,
    );

    final nonce = utf8.encode(
      '${email.toLowerCase()}${AppConstants.authKeySuffix}$salt',
    );

    final key = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(masterPassword)),
      nonce: nonce,
    );

    final keyBytes = await key.extractBytes();
    return base64Url.encode(keyBytes);
  }

  /// Encrypt a plaintext string with AES-256-GCM.
  /// Returns a map with 'ciphertext', 'iv', and 'mac' (all base64 encoded).
  static Future<Map<String, String>> encrypt({
    required String plaintext,
    required SecretKey key,
  }) async {
    final aesGcm = AesGcm.with256bits();
    final secretBox = await aesGcm.encryptString(
      plaintext,
      secretKey: key,
    );

    return {
      'ciphertext': base64.encode(secretBox.cipherText),
      'iv': base64.encode(secretBox.nonce),
      'mac': base64.encode(secretBox.mac.bytes),
    };
  }

  /// Decrypt a ciphertext with AES-256-GCM.
  static Future<String> decrypt({
    required String ciphertext,
    required String iv,
    required String mac,
    required SecretKey key,
  }) async {
    final aesGcm = AesGcm.with256bits();

    final secretBox = SecretBox(
      base64.decode(ciphertext),
      nonce: base64.decode(iv),
      mac: Mac(base64.decode(mac)),
    );

    return aesGcm.decryptString(secretBox, secretKey: key);
  }

  /// Serialize a SecretKey to raw bytes for secure storage.
  static Future<Uint8List> secretKeyToBytes(SecretKey key) async {
    final bytes = await key.extractBytes();
    return Uint8List.fromList(bytes);
  }

  /// Deserialize raw bytes back into a SecretKey.
  static SecretKey bytesToSecretKey(List<int> bytes) {
    return SecretKey(bytes);
  }

  /// Zeroize a byte list in memory (best-effort; Dart GC may still hold copies).
  static void zeroize(List<int> bytes) {
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = 0;
    }
  }
}
