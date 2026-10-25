import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// jamTik design tokens, taken from the exported screens.
class JT {
  static const bg = Color(0xFF000000);
  static const surface = Color(0xFF1A1A1A);
  static const surfaceAlt = Color(0xFF262626);
  static const surfaceDim = Color(0xFF111111);
  static const border = Color(0xFF2A2A2A);
  static const green = Color(0xFF00C853);
  static const yellow = Color(0xFFFFEB3B);
  static const textMuted = Color(0xFF9CA3AF);
  static const textFaint = Color(0xFF6B7280);
  static const danger = Color(0xFFEF4444);
}

/// Space Grotesk for headings, titles, prices.
TextStyle jtHeading(
  double size, {
  FontWeight weight = FontWeight.w700,
  Color color = Colors.white,
}) =>
    GoogleFonts.spaceGrotesk(fontSize: size, fontWeight: weight, color: color);

/// Inter for body copy and labels.
TextStyle jtBody(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = JT.textMuted,
}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

ThemeData buildJamTikTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  OutlineInputBorder outline(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c),
      );

  return base.copyWith(
    scaffoldBackgroundColor: JT.bg,
    colorScheme: const ColorScheme.dark(
      primary: JT.green,
      onPrimary: Colors.black,
      secondary: JT.yellow,
      surface: JT.surface,
    ),
    textTheme: GoogleFonts.interTextTheme(base.textTheme)
        .apply(bodyColor: Colors.white, displayColor: Colors.white),
    appBarTheme: AppBarTheme(
      backgroundColor: JT.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: jtHeading(16),
    ),
    dividerColor: JT.border,
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: JT.surfaceAlt,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: JT.surface,
      border: outline(JT.border),
      enabledBorder: outline(JT.border),
      focusedBorder: outline(JT.green),
      hintStyle: jtBody(14, color: JT.textFaint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}
