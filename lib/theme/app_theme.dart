import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const background = Color(0xFF101116);
  static const surface = Color(0xFF24262C);
  static const surfaceRaised = Color(0xFF303238);
  static const blue = Color(0xFF173D7B);
  static const blueLight = Color(0xFF9CD5FF);
  static const ink = Color(0xFFF4F7FF);
  static const muted = Color(0xFFADB5C3);
  static const border = Color(0xFF565963);

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    canvasColor: background,
    cardColor: surface,
    dividerColor: border.withValues(alpha: 0.55),
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: blueLight,
      onPrimary: background,
      secondary: blueLight,
      onSecondary: background,
      error: Color(0xFFFF8A80),
      onError: background,
      surface: surface,
      onSurface: ink,
    ),
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: ink,
      elevation: 0,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceRaised,
      contentTextStyle: const TextStyle(color: ink),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: surface,
      showDragHandle: true,
      dragHandleColor: muted,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: blueLight,
      linearTrackColor: border,
      circularTrackColor: border,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: blueLight,
      selectionColor: Color(0x664FAAFF),
      selectionHandleColor: blueLight,
    ),
  );
}
