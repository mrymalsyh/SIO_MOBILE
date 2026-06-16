import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color bg;
  final Color panel;
  final Color panelSoft;
  final Color text;
  final Color muted;
  final Color line;
  final Color accent;
  final Color accentForeground;
  final Color surface;

  const AppColors({
    required this.bg,
    required this.panel,
    required this.panelSoft,
    required this.text,
    required this.muted,
    required this.line,
    required this.accent,
    required this.accentForeground,
    required this.surface,
  });

  @override
  ThemeExtension<AppColors> copyWith({
    Color? bg,
    Color? panel,
    Color? panelSoft,
    Color? text,
    Color? muted,
    Color? line,
    Color? accent,
    Color? accentForeground,
    Color? surface,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      panel: panel ?? this.panel,
      panelSoft: panelSoft ?? this.panelSoft,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      accent: accent ?? this.accent,
      accentForeground: accentForeground ?? this.accentForeground,
      surface: surface ?? this.surface,
    );
  }

  @override
  ThemeExtension<AppColors> lerp(covariant ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      panelSoft: Color.lerp(panelSoft, other.panelSoft, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentForeground: Color.lerp(accentForeground, other.accentForeground, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
    );
  }
}

/// Shared app theme matching SIO web frontend styling
class AppTheme {
  AppTheme._();

  // Status colors (kept from original)
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

  // Spacing
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacingLg = 16;
  static const double spacingXl = 20;
  static const double spacing2xl = 24;

  // Border Radius
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusFull = 999;

  // ========== TEXT STYLES ==========
  static const TextStyle headingLg = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle headingMd = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle headingSm = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyLg = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle bodyMd = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle bodySm = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static const TextStyle labelUppercase = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static const AppColors lightColors = AppColors(
    bg: Color(0xFFFFFFFF),
    panel: Color(0xFFF4F4F5),
    panelSoft: Color(0xFFF4F4F5),
    text: Color(0xFF09090B),
    muted: Color(0xFF71717A),
    line: Color(0xFFE4E4E7),
    accent: Color(0xFF18181B),
    accentForeground: Color(0xFFFAFAFA),
    surface: Color(0xFFFFFFFF),
  );

  static const AppColors darkColors = AppColors(
    bg: Color(0xFF09090B),
    panel: Color(0xFF18181B),
    panelSoft: Color(0xFF18181B),
    text: Color(0xFFFAFAFA),
    muted: Color(0xFFA1A1AA),
    line: Color(0xFF27272A),
    accent: Color(0xFFFAFAFA),
    accentForeground: Color(0xFF09090B),
    surface: Color(0xFF18181B),
  );

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: lightColors.accent,
      scaffoldBackgroundColor: lightColors.bg,
      colorScheme: ColorScheme.light(
        primary: lightColors.accent,
        onPrimary: lightColors.accentForeground,
        surface: lightColors.surface,
        onSurface: lightColors.text,
        error: red500,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightColors.bg,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: lightColors.text,
        ),
        iconTheme: IconThemeData(color: lightColors.text),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: lightColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: lightColors.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: lightColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: lightColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: lightColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: red500),
        ),
        filled: true,
        fillColor: lightColors.surface,
        hintStyle: TextStyle(color: lightColors.muted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightColors.accent,
          foregroundColor: lightColors.accentForeground,
          padding: const EdgeInsets.symmetric(horizontal: spacingLg, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: lightColors.accent,
        foregroundColor: lightColors.accentForeground,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightColors.bg,
        selectedItemColor: lightColors.accent,
        unselectedItemColor: lightColors.muted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: DividerThemeData(
        color: lightColors.line,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        backgroundColor: lightColors.accent,
        contentTextStyle: TextStyle(color: lightColors.accentForeground),
      ),
      fontFamily: 'Roboto',
      useMaterial3: true,
      extensions: [lightColors],
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: darkColors.accent,
      scaffoldBackgroundColor: darkColors.bg,
      colorScheme: ColorScheme.dark(
        primary: darkColors.accent,
        onPrimary: darkColors.accentForeground,
        surface: darkColors.surface,
        onSurface: darkColors.text,
        error: red500,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkColors.bg,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkColors.text,
        ),
        iconTheme: IconThemeData(color: darkColors.text),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: darkColors.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: darkColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: darkColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: darkColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: red500),
        ),
        filled: true,
        fillColor: darkColors.surface,
        hintStyle: TextStyle(color: darkColors.muted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkColors.accent,
          foregroundColor: darkColors.accentForeground,
          padding: const EdgeInsets.symmetric(horizontal: spacingLg, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkColors.accent,
        foregroundColor: darkColors.accentForeground,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkColors.bg,
        selectedItemColor: darkColors.accent,
        unselectedItemColor: darkColors.muted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: DividerThemeData(
        color: darkColors.line,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        backgroundColor: darkColors.accent,
        contentTextStyle: TextStyle(color: darkColors.accentForeground),
      ),
      fontFamily: 'Roboto',
      useMaterial3: true,
      extensions: [darkColors],
    );
  }

  // ========== STATUS HELPERS ==========
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
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
        return const Color(0xFF3B82F6); // Changed from indigo to blue
      case 'draft':
        return const Color(0xFF6B7280); // Gray
      default:
        return const Color(0xFF6B7280);
    }
  }

  static Color statusBgColor(String status, bool isDark) {
    // Return dark mode friendly background variants
    if (isDark) {
      switch (status.toLowerCase()) {
        case 'available':
        case 'supplied':
          return const Color.fromRGBO(34, 197, 94, 0.15);
        case 'completed':
          return const Color.fromRGBO(59, 130, 246, 0.15);
        case 'returned':
          return const Color.fromRGBO(245, 158, 11, 0.15);
        case 'disposed':
          return const Color.fromRGBO(239, 68, 68, 0.15);
        case 'expired':
          return const Color.fromRGBO(249, 115, 22, 0.15);
        case 'pending supply':
          return const Color.fromRGBO(59, 130, 246, 0.15);
        case 'draft':
          return const Color.fromRGBO(107, 114, 128, 0.15);
        default:
          return const Color.fromRGBO(107, 114, 128, 0.15);
      }
    } else {
      switch (status.toLowerCase()) {
        case 'available':
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
          return blue100;
        case 'draft':
          return const Color(0xFFF3F4F6);
        default:
          return const Color(0xFFF3F4F6);
      }
    }
  }
}
