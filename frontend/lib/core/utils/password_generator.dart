import 'dart:math';

class PasswordGenerator {
  PasswordGenerator._();

  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _numbers = '0123456789';
  static const String _symbols = '!@#\$%^&*()-_=+[]{}|;:,.<>?';

  static String generate({
    int length = 16,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSymbols = true,
  }) {
    assert(
      includeUppercase || includeLowercase || includeNumbers || includeSymbols,
      'At least one character set must be selected',
    );

    final random = Random.secure();
    final charset = StringBuffer();
    final required = <String>[];

    if (includeUppercase) {
      charset.write(_uppercase);
      required.add(_uppercase[random.nextInt(_uppercase.length)]);
    }
    if (includeLowercase) {
      charset.write(_lowercase);
      required.add(_lowercase[random.nextInt(_lowercase.length)]);
    }
    if (includeNumbers) {
      charset.write(_numbers);
      required.add(_numbers[random.nextInt(_numbers.length)]);
    }
    if (includeSymbols) {
      charset.write(_symbols);
      required.add(_symbols[random.nextInt(_symbols.length)]);
    }

    final charsetStr = charset.toString();
    final remaining = List<String>.generate(
      length - required.length,
      (_) => charsetStr[random.nextInt(charsetStr.length)],
    );

    final all = [...required, ...remaining];

    // Fisher-Yates shuffle
    for (var i = all.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final tmp = all[i];
      all[i] = all[j];
      all[j] = tmp;
    }

    return all.join();
  }

  static PasswordStrength evaluateStrength(String password) {
    if (password.isEmpty) return PasswordStrength.none;
    if (password.length < 6) return PasswordStrength.weak;

    int score = 0;

    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.length >= 16) score++;

    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*()\-_=+\[\]{}|;:,.<>?]').hasMatch(password)) score++;

    // Penalize common patterns
    if (RegExp(r'(.)\1{2,}').hasMatch(password)) score -= 2;
    if (RegExp(r'(012|123|234|345|456|567|678|789|890|abc|bcd|cde)').hasMatch(password.toLowerCase())) score -= 1;

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.fair;
    if (score <= 6) return PasswordStrength.good;
    return PasswordStrength.strong;
  }
}

enum PasswordStrength {
  none,
  weak,
  fair,
  good,
  strong;

  String get label {
    switch (this) {
      case PasswordStrength.none:
        return '';
      case PasswordStrength.weak:
        return 'Muy débil';
      case PasswordStrength.fair:
        return 'Débil';
      case PasswordStrength.good:
        return 'Buena';
      case PasswordStrength.strong:
        return 'Muy fuerte';
    }
  }

  double get progress {
    switch (this) {
      case PasswordStrength.none:
        return 0;
      case PasswordStrength.weak:
        return 0.25;
      case PasswordStrength.fair:
        return 0.5;
      case PasswordStrength.good:
        return 0.75;
      case PasswordStrength.strong:
        return 1.0;
    }
  }
}
