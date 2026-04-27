import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // Backgrounds — darkest to lightest
  static const background = Color(0xFF0F1318);
  static const toolbar = Color(0xFF0C1016);
  static const surface = Color(0xFF161C22);
  static const surfaceAlt = Color(0xFF1D2530);
  static const surfaceElevated = Color(0xFF232D38);

  // Borders
  static const border = Color(0xFF2D3A45);

  // Text hierarchy
  static const text = Color(0xFFE2EBF2);
  static const mutedText = Color(0xFF8A9AAB);
  static const dimText = Color(0xFF4E6070);

  // Accents
  static const accent = Color(0xFF38B2AC); // teal — primary
  static const accentBlue = Color(0xFF4A9EE8); // blue — secondary
  static const codeBlue = Color(0xFF79C0FF); // register syntax

  // State
  static const changed = Color(0xFFFFC857); // value changed
  static const danger = Color(0xFFFF6B6B); // error
  static const success = Color(0xFF4CAF81); // halted / ok
}
