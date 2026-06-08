import 'package:flutter/material.dart';

/// Shared app theme matching MSIC_FE web frontend styling
class AppTheme {
  AppTheme._();

  // ========== COLORS ==========

  // Primary - Indigo
  static const indigo50 = Color(0xFFEEF2FF);
  static const indigo100 = Color(0xFFE0E7FF);
  static const indigo600 = Color.fromARGB(255, 4, 1, 55);
  static const indigo700 = Color.fromARGB(255, 5, 0, 66);

  // Gray scale
  static const gray50 = Color(0xFFF9FAFB);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray200 = Color(0xFFE5E7EB);
  static const gray300 = Color(0xFFD1D5DB);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray500 = Color(0xFF6B7280);
  static const gray700 = Color(0xFF374151);
  static const gray900 = Color(0xFF111827);

  // Slate
  static const slate50 = Color(0xFFF8FAFC);

  // Status colors
  static const green100 = Color(0xFFDCFCE7);
  static const green500 = Color(0xFF22C55E);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue500 = Color(0xFF3B82F6);
  static const amber100 = Color(0xFFFEF3C7);
  static const amber500 = Color(0xFFF59E0B);
  static const orange100 = Color(0xFFFFEDD5);
  static const orange500 = Color(0xFFF97316);
  static const red100 = Color(0xFFFEE2E2);
  static const red500 = Color(0xFFEF4444);

  // ========== SPACING ==========
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacingLg = 16;
  static const double spacingXl = 20;
  static const double spacing2xl = 24;

  // ========== BORDER RADIUS ==========
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusFull = 999;

  // ========== TEXT STYLES ==========
  static const TextStyle headingLg = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: gray900,
  );

  static const TextStyle headingMd = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: gray900,
  );

  static const TextStyle headingSm = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: gray900,
  );

  static const TextStyle bodyLg = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: gray900,
  );

  static const TextStyle bodyMd = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: gray700,
  );

  static const TextStyle bodySm = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: gray700,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: gray500,
  );

  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: gray400,
  );

  static const TextStyle labelUppercase = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: gray400,
  );

  // ========== DECORATIONS ==========
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radiusLg),
    border: Border.all(color: gray200),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration get inputDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radiusMd),
    border: Border.all(color: gray300),
  );

  static BoxDecoration get chipDecoration => BoxDecoration(
    color: indigo50,
    borderRadius: BorderRadius.circular(radiusMd),
  );

  static Decoration get gradientAccent => BoxDecoration(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(radiusLg)),
    gradient: LinearGradient(colors: [indigo600, Colors.purple.shade500]),
  );

  // ========== INPUT DECORATION ==========
  static InputDecoration textFieldDecoration({
    required String hint,
    IconData? prefixIcon,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: gray400, fontSize: 14),
    prefixIcon: prefixIcon != null
        ? Icon(prefixIcon, color: gray500, size: 20)
        : null,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: spacingMd,
      vertical: 14,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMd),
      borderSide: BorderSide(color: gray300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMd),
      borderSide: BorderSide(color: gray300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMd),
      borderSide: BorderSide(color: indigo600, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMd),
      borderSide: BorderSide(color: red500),
    ),
  );

  // ========== BUTTON STYLES ==========
  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
    backgroundColor: const Color.fromARGB(255, 6, 6, 24),
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: spacingLg, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMd),
    ),
    textStyle: const TextStyle(fontWeight: FontWeight.w600),
  );

  static ButtonStyle get successButton => ElevatedButton.styleFrom(
    backgroundColor: green500,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: spacingLg, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMd),
    ),
    textStyle: const TextStyle(fontWeight: FontWeight.w600),
  );

  static ButtonStyle get dangerButton => ElevatedButton.styleFrom(
    backgroundColor: red500,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: spacingLg, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMd),
    ),
    textStyle: const TextStyle(fontWeight: FontWeight.w600),
  );

  // ========== APP BAR ==========
  static AppBarTheme get appBarTheme => const AppBarTheme(
    backgroundColor: Colors.white,
    elevation: 0,
    scrolledUnderElevation: 1,
    centerTitle: true,
    titleTextStyle: headingMd,
    iconTheme: IconThemeData(color: gray700),
  );

  // ========== STATUS HELPERS ==========
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return green500;
      case 'supplied':
        return green500;
      case 'completed':
        return blue500;
      case 'returned':
        return amber500;
      case 'disposed':
        return red500;
      case 'expired':
        return orange500;
      case 'pending supply':
        return indigo600;
      case 'draft':
        return gray500;
      default:
        return gray500;
    }
  }

  static Color statusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return green100;
      case 'supplied':
        return green100;
      case 'completed':
        return blue100;
      case 'returned':
        return amber100;
      case 'disposed':
        return red100;
      case 'expired':
        return orange100;
      case 'pending supply':
        return indigo50;
      case 'draft':
        return gray100;
      default:
        return gray100;
    }
  }
}
