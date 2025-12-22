import 'package:flutter/material.dart';

class AppStyle {
  // Primary Colors
  static const Color primaryColor = Color(0xFF00C853); // Green
  static const Color accentColor = Color(0xFFFF9100); // Orange
  static const Color textColor = Color(0xFF333333); // Dark Grey

  // Button Styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 5,
    shadowColor: primaryColor.withOpacity(0.3),
  );

  // Text Styles
  static TextStyle headingTextStyle = const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static TextStyle subHeadingTextStyle = const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textColor,
  );

  static TextStyle bodyTextStyle = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textColor,
  );
}
