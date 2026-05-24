import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Brand colors ──────────────────────────────────────────────────────────────
class AppColors {
  // Backgrounds
  static const background     = Color(0xFF0F1117);
  static const surface        = Color(0xFF1A1D27);
  static const surfaceVariant = Color(0xFF252836);
  static const card           = Color(0xFF1E2130);

  // Accent
  static const teal           = Color(0xFF00D4AA);
  static const tealDark       = Color(0xFF00A882);
  static const tealSurface    = Color(0xFF003D33);

  // Status
  static const success        = Color(0xFF4CAF50);
  static const warning        = Color(0xFFFF9800);
  static const error          = Color(0xFFEF5350);
  static const info           = Color(0xFF2196F3);

  // Text
  static const textPrimary    = Color(0xFFE8EAF0);
  static const textSecondary  = Color(0xFF8B8FA8);
  static const textDisabled   = Color(0xFF4A4D60);

  // Border
  static const border         = Color(0xFF2A2D3E);
  static const borderLight    = Color(0xFF353848);
}

class AppTheme {
  static ThemeData get dark {
    const cs = ColorScheme(
      brightness:           Brightness.dark,
      primary:              AppColors.teal,
      onPrimary:            AppColors.background,
      primaryContainer:     AppColors.tealSurface,
      onPrimaryContainer:   AppColors.teal,
      secondary:            AppColors.teal,
      onSecondary:          AppColors.background,
      secondaryContainer:   AppColors.surfaceVariant,
      onSecondaryContainer: AppColors.textPrimary,
      tertiary:             AppColors.teal,
      onTertiary:           AppColors.background,
      tertiaryContainer:    AppColors.surfaceVariant,
      onTertiaryContainer:  AppColors.textPrimary,
      error:                AppColors.error,
      onError:              Colors.white,
      errorContainer:       Color(0xFF4D1515),
      onErrorContainer:     AppColors.error,
      background:           AppColors.background,
      onBackground:         AppColors.textPrimary,
      surface:              AppColors.surface,
      onSurface:            AppColors.textPrimary,
      surfaceVariant:       AppColors.surfaceVariant,
      onSurfaceVariant:     AppColors.textSecondary,
      outline:              AppColors.border,
      outlineVariant:       AppColors.borderLight,
      shadow:               Colors.black,
      scrim:                Colors.black,
      inverseSurface:       AppColors.textPrimary,
      onInverseSurface:     AppColors.background,
      inversePrimary:       AppColors.tealDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColors.background,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor:        AppColors.background,
        foregroundColor:        AppColors.textPrimary,
        elevation:              0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor:          Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color:         AppColors.textPrimary,
          fontSize:      18,
          fontWeight:    FontWeight.w600,
          letterSpacing: -0.3,
        ),
        iconTheme:        IconThemeData(color: AppColors.textPrimary),
        actionsIconTheme: IconThemeData(color: AppColors.textSecondary),
      ),

      // Bottom navigation
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor:  AppColors.tealSurface,
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: AppColors.teal, size: 22);
          }
          return const IconThemeData(color: AppColors.textSecondary, size: 22);
        }),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const TextStyle(
              color:      AppColors.teal,
              fontSize:   11,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color:    AppColors.textSecondary,
            fontSize: 11,
          );
        }),
        elevation:     0,
        height:        64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      // Cards — fixed: CardTheme -> CardThemeData
      cardTheme: CardThemeData(
        color:     AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor:     AppColors.surfaceVariant,
        selectedColor:       AppColors.tealSurface,
        labelStyle:          const TextStyle(color: AppColors.textPrimary, fontSize: 12),
        secondaryLabelStyle: const TextStyle(color: AppColors.teal, fontSize: 12),
        side:  const BorderSide(color: AppColors.border, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),

      // Input / TextField
      inputDecorationTheme: InputDecorationTheme(
        filled:    true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
        ),
        hintStyle:      const TextStyle(color: AppColors.textDisabled),
        labelStyle:     const TextStyle(color: AppColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense:        true,
      ),

      // Buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: AppColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.teal,
          side:  const BorderSide(color: AppColors.teal),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.teal),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color:     AppColors.border,
        thickness: 0.5,
        space:     0,
      ),

      // Progress indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color:            AppColors.teal,
        linearTrackColor: AppColors.border,
      ),

      // Icon
      iconTheme: const IconThemeData(color: AppColors.textSecondary),

      // Text
      textTheme: const TextTheme(
        displayLarge:   TextStyle(color: AppColors.textPrimary,   fontWeight: FontWeight.w700),
        displayMedium:  TextStyle(color: AppColors.textPrimary,   fontWeight: FontWeight.w700),
        displaySmall:   TextStyle(color: AppColors.textPrimary,   fontWeight: FontWeight.w600),
        headlineLarge:  TextStyle(color: AppColors.textPrimary,   fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: AppColors.textPrimary,   fontWeight: FontWeight.w600),
        headlineSmall:  TextStyle(color: AppColors.textPrimary,   fontWeight: FontWeight.w600),
        titleLarge:     TextStyle(color: AppColors.textPrimary,   fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium:    TextStyle(color: AppColors.textPrimary,   fontWeight: FontWeight.w500, fontSize: 15),
        titleSmall:     TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500, fontSize: 13),
        bodyLarge:      TextStyle(color: AppColors.textPrimary,   fontSize: 15),
        bodyMedium:     TextStyle(color: AppColors.textPrimary,   fontSize: 13),
        bodySmall:      TextStyle(color: AppColors.textSecondary, fontSize: 12),
        labelLarge:     TextStyle(color: AppColors.textPrimary,   fontWeight: FontWeight.w600, fontSize: 13),
        labelMedium:    TextStyle(color: AppColors.textSecondary, fontSize: 12),
        labelSmall:     TextStyle(color: AppColors.textDisabled,  fontSize: 10),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor:  AppColors.surfaceVariant,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),

      // Dialog — fixed: DialogTheme -> DialogThemeData
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          color:      AppColors.textPrimary,
          fontSize:   17,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color:    AppColors.textSecondary,
          fontSize: 14,
        ),
      ),

      // List tile
      listTileTheme: const ListTileThemeData(
        textColor: AppColors.textPrimary,
        iconColor: AppColors.textSecondary,
        tileColor: Colors.transparent,
      ),
    );
  }

  // Light theme — fallback ke dark (app ini full dark)
  static ThemeData get light => dark;
}
