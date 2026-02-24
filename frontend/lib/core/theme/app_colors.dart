import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary palette (deep blue) ──────────────────────────
  static const Color primary = Color(0xFF1A2E6C);
  static const Color primaryDark = Color(0xFF0E1D47);
  static const Color primaryMid = Color(0xFF243F8F);
  static const Color primaryLight = Color(0xFF3356B8);

  // ── Accent ───────────────────────────────────────────────
  static const Color accent = Color(0xFF4B7BE5);
  static const Color accentLight = Color(0xFF6B98F7);
  static const Color accentDark = Color(0xFF2F5CC7);

  // ── Semantic ─────────────────────────────────────────────
  static const Color success = Color(0xFF2ECC71);
  static const Color successLight = Color(0xFFD5F5E3);
  static const Color warning = Color(0xFFF39C12);
  static const Color warningLight = Color(0xFFFEF3CD);
  static const Color error = Color(0xFFE74C3C);
  static const Color errorLight = Color(0xFFFAD7D4);
  static const Color info = Color(0xFF3498DB);

  // ── Light mode backgrounds ────────────────────────────────
  static const Color background = Color(0xFFF4F7FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color inputBg = Color(0xFFF0F4FF);
  static const Color inputBorder = Color(0xFFDDE3F5);
  static const Color divider = Color(0xFFEBEFF8);

  // ── Dark mode backgrounds ─────────────────────────────────
  static const Color darkBg = Color(0xFF080D1F);
  static const Color darkSurface = Color(0xFF111829);
  static const Color darkCard = Color(0xFF192035);
  static const Color darkBorder = Color(0xFF253050);
  static const Color darkInputBg = Color(0xFF192035);

  // ── Light mode text ───────────────────────────────────────
  static const Color textPrimary = Color(0xFF0E1D47);
  static const Color textSecondary = Color(0xFF5B6E9E);
  static const Color textHint = Color(0xFF9BAAC8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Dark mode text ────────────────────────────────────────
  static const Color textDarkPrimary = Color(0xFFE8EEFF);
  static const Color textDarkSecondary = Color(0xFF8A99C8);
  static const Color textDarkHint = Color(0xFF5B6E9E);

  // ── Password strength ─────────────────────────────────────
  static const Color strengthWeak = Color(0xFFE74C3C);
  static const Color strengthFair = Color(0xFFF39C12);
  static const Color strengthGood = Color(0xFF2ECC71);
  static const Color strengthStrong = Color(0xFF1ABC9C);

  // ── Category chip colors ──────────────────────────────────
  static const List<Color> categoryColors = [
    Color(0xFF4B7BE5),
    Color(0xFF2ECC71),
    Color(0xFFF39C12),
    Color(0xFF9B59B6),
    Color(0xFFE74C3C),
    Color(0xFF1ABC9C),
    Color(0xFF3498DB),
  ];

  // ── Gradients ─────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary, primaryLight],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentLight],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryDark, primary, primaryMid],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );
}
