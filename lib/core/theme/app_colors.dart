import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Light Theme ──
  static const Color primary = Color(0xFFC2185B);
  static const Color secondary = Color(0xFF880E4F);
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFF3F4F6);
  static const Color card = Color(0xFFFFFFFF);
  
  static const Color safe = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);
  
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF4B5563);
  
  static const Color meshActive = Color(0xFF7C4DFF);

  // ── Dark Theme ──
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
