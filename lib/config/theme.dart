import 'package:flutter/material.dart';

import 'app_config.dart';

/// Tema visual do aplicativo (Material 3, escuro por padrão).
class AppTheme {
  AppTheme._();

  static ThemeData escuro() {
    final base = ColorScheme.fromSeed(
      seedColor: AppConfig.primaryColor,
      brightness: Brightness.dark,
    );
    final scheme = base.copyWith(
      primary: AppConfig.primaryColor,
      secondary: AppConfig.accentColor,
      surface: AppConfig.surfaceDark,
      error: AppConfig.chorusAccent,
      onSurface: AppConfig.textoClaro,
    );
    return _montar(
      scheme: scheme,
      scaffold: AppConfig.backgroundDark,
      brightness: Brightness.dark,
      textoPrincipal: AppConfig.textoClaro,
      textoSecundario: AppConfig.textoSecundario,
      corCampo: AppConfig.cardDark,
      divisor: Colors.white12,
    );
  }

  static ThemeData claro() {
    final base = ColorScheme.fromSeed(
      seedColor: AppConfig.primaryColor,
      brightness: Brightness.light,
    );
    final scheme = base.copyWith(
      primary: const Color(0xFFE65100),
      secondary: const Color(0xFF1565C0),
      surface: AppConfig.surfaceLight,
      error: AppConfig.chorusAccent,
    );
    return _montar(
      scheme: scheme,
      scaffold: AppConfig.backgroundLight,
      brightness: Brightness.light,
      textoPrincipal: const Color(0xFF1C1B1F),
      textoSecundario: const Color(0xFF5F5F5F),
      corCampo: Colors.white,
      divisor: Colors.black12,
    );
  }

  static ThemeData _montar({
    required ColorScheme scheme,
    required Color scaffold,
    required Brightness brightness,
    required Color textoPrincipal,
    required Color textoSecundario,
    required Color corCampo,
    required Color divisor,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: textoPrincipal,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textoPrincipal,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: corCampo,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: textoSecundario),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: divisor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppConfig.primaryColor, width: 1.4),
        ),
      ),
      dividerTheme: DividerThemeData(color: divisor, thickness: 1),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.black,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: corCampo,
        side: BorderSide(color: divisor),
        labelStyle: TextStyle(color: textoPrincipal, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      textTheme: Typography.material2021(platform: TargetPlatform.android)
          .black
          .apply(
            bodyColor: textoPrincipal,
            displayColor: textoPrincipal,
          ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppConfig.primaryColor,
      ),
    );
  }
}
