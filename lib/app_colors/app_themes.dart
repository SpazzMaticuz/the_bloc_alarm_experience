import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppThemes {
  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.scaffoldBackground,
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.cardBackground,
        onPrimary: AppColors.text,
        onSecondary: AppColors.text,
        onSurface: AppColors.text,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.text),
        bodyMedium: TextStyle(color: AppColors.text),
        bodySmall: TextStyle(color: AppColors.text),
        titleLarge: TextStyle(color: AppColors.text),
        titleMedium: TextStyle(color: AppColors.text),
        titleSmall: TextStyle(color: AppColors.text),
        labelLarge: TextStyle(color: AppColors.text),
        labelMedium: TextStyle(color: AppColors.text),
        labelSmall: TextStyle(color: AppColors.text),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.appBarBackground,
        titleTextStyle: TextStyle(color: AppColors.appBarText, fontSize: 20, fontWeight: FontWeight.w600),
        iconTheme: IconThemeData(color: AppColors.appBarText),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        shadowColor: Colors.black54,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.switchThumb),
        trackColor: WidgetStateProperty.all(AppColors.switchTrack),
      ),
    );
  }
}
