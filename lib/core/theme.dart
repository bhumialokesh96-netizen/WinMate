import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modern, gamified color palette for WinMate app
class AppTheme {
  // Primary Colors - Vibrant Green Theme
  static const Color primaryGreen = Color(0xFF00C853);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color darkGreen = Color(0xFF00796B);
  static const Color tealGreen = Color(0xFF00BFA5);
  static const Color brightGreen = Color(0xFF00E676);
  
  // Accent Colors
  static const Color accentOrange = Color(0xFFFF9100);
  static const Color accentYellow = Color(0xFFFFEB3B);
  static const Color accentPurple = Color(0xFF9C27B0);
  static const Color accentBlue = Color(0xFF2196F3);
  
  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFF00E676), // Bright Green
    Color(0xFF00C853), // Medium Green
    Color(0xFF00BFA5), // Teal
  ];
  
  static const List<Color> cardGradient = [
    Color(0xFF00E676),
    Color(0xFF00BFA5),
  ];
  
  static const List<Color> orangeGradient = [
    Color(0xFFFF9100),
    Color(0xFFFF3D00),
  ];
  
  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color darkGrey = Color(0xFF424242);
  
  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);
  
  // Shadow Colors
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);
  static const Color shadowDark = Color(0x66000000);
  
  /// Get the main theme data for the app
  static ThemeData getTheme() {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: primaryGreen,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: accentOrange,
        surface: white,
        error: error,
      ),
      
      // Typography
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: white,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: white,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: white,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: white,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: white,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: darkGrey,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: darkGrey,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: darkGrey,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: darkGrey,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: grey,
        ),
      ),
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: white,
        ),
        iconTheme: const IconThemeData(color: white),
      ),
      
      // Card Theme
      cardTheme: CardTheme(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: white,
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: white,
          elevation: 5,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightGrey,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: grey,
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: primaryGreen,
        unselectedItemColor: grey,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryGreen,
        circularTrackColor: lightGrey,
      ),
    );
  }
  
  /// Create a gradient background decoration
  static BoxDecoration gradientBackground() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: primaryGradient,
      ),
    );
  }
  
  /// Create a card decoration with gradient
  static BoxDecoration cardDecoration({
    List<Color>? gradientColors,
    Color? solidColor,
    double borderRadius = 20,
  }) {
    return BoxDecoration(
      gradient: solidColor == null
          ? LinearGradient(
              colors: gradientColors ?? cardGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
      color: solidColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: shadowMedium,
          blurRadius: 15,
          offset: const Offset(0, 10),
        ),
      ],
      border: Border.all(
        color: white.withOpacity(0.2),
        width: 1,
      ),
    );
  }
  
  /// Pattern overlay for background
  static Widget patternOverlay() {
    return Opacity(
      opacity: 0.05,
      child: Container(
        decoration: BoxDecoration(
          color: white.withOpacity(0.05),
          // Using simple pattern instead of external URL for better performance and reliability
        ),
      ),
    );
  }
}

/// Reusable 3D text widget for gamified UI
class Text3D extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color mainColor;
  final Color shadowColor;
  final double depth;
  final FontWeight fontWeight;
  
  const Text3D(
    this.text, {
    super.key,
    this.fontSize = 18,
    this.mainColor = AppTheme.white,
    this.shadowColor = AppTheme.darkGreen,
    this.depth = 2,
    this.fontWeight = FontWeight.w900,
  });
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Shadow text
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: shadowColor,
          ),
        ),
        // Front text
        Transform.translate(
          offset: Offset(0, -depth),
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: mainColor,
              shadows: const [
                Shadow(color: AppTheme.shadowMedium, blurRadius: 2),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Reusable 3D icon widget for gamified UI
class Icon3D extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color mainColor;
  final Color shadowColor;
  final double depth;
  
  const Icon3D(
    this.icon, {
    super.key,
    this.size = 24,
    this.mainColor = AppTheme.white,
    this.shadowColor = AppTheme.shadowDark,
    this.depth = 1,
  });
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Shadow icon
        Icon(
          icon,
          size: size,
          color: shadowColor,
        ),
        // Front icon
        Transform.translate(
          offset: Offset(0, -depth),
          child: Icon(
            icon,
            size: size,
            color: mainColor,
          ),
        ),
      ],
    );
  }
}
