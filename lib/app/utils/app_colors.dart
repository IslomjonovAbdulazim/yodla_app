import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF2563EB); // Blue-600
  static const Color primaryLight = Color(0xFF3B82F6); // Blue-500
  static const Color primaryDark = Color(0xFF1D4ED8); // Blue-700

  // Secondary Colors
  static const Color secondary = Color(0xFF059669); // Emerald-600
  static const Color secondaryLight = Color(0xFF10B981); // Emerald-500
  static const Color secondaryDark = Color(0xFF047857); // Emerald-700

  // Background Colors
  static const Color background = Color(0xFFF8FAFC); // Slate-50
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Slate-100

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate-900
  static const Color textSecondary = Color(0xFF475569); // Slate-600
  static const Color textTertiary = Color(0xFF94A3B8); // Slate-400
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White

  // Input Colors
  static const Color inputBackground = Color(0xFFF1F5F9); // Slate-100
  static const Color inputBorder = Color(0xFFE2E8F0); // Slate-200
  static const Color inputFocused = primary;

  // Status Colors
  static const Color success = Color(0xFF059669); // Emerald-600
  static const Color warning = Color(0xFFD97706); // Amber-600
  static const Color error = Color(0xFFDC2626); // Red-600
  static const Color info = primary;

  // Quiz Category Colors
  static const Color notKnownColor = Color(0xFFEF4444); // Red-500
  static const Color normalColor = Color(0xFFF59E0B); // Amber-500
  static const Color strongColor = Color(0xFF10B981); // Emerald-500

  // Voice Agent Colors
  static const Color carsColor = Color(0xFF6366F1); // Indigo-500
  static const Color footballColor = Color(0xFF059669); // Emerald-600
  static const Color travelColor = Color(0xFFF59E0B); // Amber-500

  // Quiz Type Colors
  static const Color anagramColor = Color(0xFF8B5CF6); // Violet-500
  static const Color translationBlitzColor = Color(0xFF06B6D4); // Cyan-500
  static const Color wordBlitzColor = Color(0xFFEC4899); // Pink-500
  static const Color readingColor = Color(0xFF10B981); // Emerald-500

  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFF3B82F6), // Blue-500
    Color(0xFF2563EB), // Blue-600
  ];

  static const List<Color> successGradient = [
    Color(0xFF10B981), // Emerald-500
    Color(0xFF059669), // Emerald-600
  ];

  static const List<Color> warningGradient = [
    Color(0xFFF59E0B), // Amber-500
    Color(0xFFD97706), // Amber-600
  ];

  static const List<Color> errorGradient = [
    Color(0xFFEF4444), // Red-500
    Color(0xFFDC2626), // Red-600
  ];

  // Border Colors
  static const Color border = Color(0xFFE2E8F0); // Slate-200
  static const Color borderLight = Color(0xFFF1F5F9); // Slate-100
  static const Color borderDark = Color(0xFFCBD5E1); // Slate-300

  // Shadow Colors
  static const Color shadow = Color(0x1A000000); // Black with 10% opacity
  static const Color shadowLight = Color(0x0D000000); // Black with 5% opacity

  // Overlay Colors
  static const Color overlay = Color(0x80000000); // Black with 50% opacity
  static const Color overlayLight = Color(0x40000000); // Black with 25% opacity

  // Card Colors
  static const Color cardBackground = surface;
  static const Color cardBorder = border;

  // Divider
  static const Color divider = Color(0xFFE2E8F0); // Slate-200

  // Disabled
  static const Color disabled = Color(0xFF94A3B8); // Slate-400
  static const Color disabledBackground = Color(0xFFF1F5F9); // Slate-100
}

extension ColorExtension on Color {
  /// Create a MaterialColor from a single Color
  MaterialColor toMaterialColor() {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = red, g = green, b = blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }

    for (double strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }

    return MaterialColor(value, swatch);
  }
}
