class AppConstants {
  AppConstants._();

  static const String appName = 'Claveo';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Tu vault. Solo tuyo.';

  // API
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  // KDF — encryption key derivation
  static const int pbkdf2EncIterations = 600000;
  static const int pbkdf2AuthIterations = 100000;
  static const int keyLengthBits = 256;
  static const String encKeySuffix = ':enc:claveo-v1';
  static const String authKeySuffix = ':auth:claveo-v1';

  // Auto-lock timeout (seconds)
  static const int autoLockSeconds = 300; // 5 min

  // Secure storage keys
  static const String kAccessToken = 'claveo_access_token';
  static const String kRefreshToken = 'claveo_refresh_token';
  static const String kUserEmail = 'claveo_user_email';
  static const String kEncryptionKeyBytes = 'claveo_enc_key';
  static const String kKdfSalt = 'claveo_kdf_salt';
  static const String kBiometricEnabled = 'claveo_biometric';
  static const String kOnboardingDone = 'claveo_onboarding';
  static const String kLastActiveMs = 'claveo_last_active';
  static const String kDarkMode = 'claveo_dark_mode';
  static const String kPinCode = 'claveo_pin';

  // Vault entry categories
  static const List<String> categories = [
    'Todas',
    'Redes Sociales',
    'Finanzas',
    'Trabajo',
    'Correo',
    'Compras',
    'Entretenimiento',
    'Otros',
  ];

  static const List<String> categoriesWithoutAll = [
    'Redes Sociales',
    'Finanzas',
    'Trabajo',
    'Correo',
    'Compras',
    'Entretenimiento',
    'Otros',
  ];

  // Password generator defaults
  static const int defaultPasswordLength = 16;
  static const bool defaultUppercase = true;
  static const bool defaultLowercase = true;
  static const bool defaultNumbers = true;
  static const bool defaultSymbols = true;
}
