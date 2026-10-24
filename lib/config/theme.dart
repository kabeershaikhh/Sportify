import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App color palette for Sportify.
class AppColors {
  AppColors._();

  // Primary brand colors (Sporty Light Blue / Sky)
  static const Color primary = Color(0xFF3158ED);
  static const Color primaryLight = Color(0xFF38BDF8); // Sky light blue
  static const Color primaryDark = Color(0xFF1D348B);

  /// Shared by the home hero and player profile headers.
  static const brandGradient = LinearGradient(
    colors: [primaryDark, primary, tertiary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const softBlueGradient = LinearGradient(
    colors: [lavender, Color(0xFFE4F0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Secondary & Tertiary
  static const Color secondary = Color(0xFF0F172A); // Modern deep navy
  static const Color secondaryLight = Color(0xFF334155);
  static const Color tertiary = Color(0xFF4169E1);
  static const Color blueTint = Color(0xFFEAF0FF);
  static const Color lavender = Color(0xFFEEF0FF);
  static const Color peach = Color(0xFFFFF1DF);

  // Neutral colors
  static const Color background = Color(0xFFF5F7FC);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(
    0xFFEDF1FF,
  ); // Soft light blue surface
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF59677D);
  static const Color textHint = Color(0xFF68758C);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFCBD5E1);

  // Status colors
  static const Color success = Color(0xFF2454CB);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF0284C7);
}

/// Material 3 theme configuration for Sportify.
class AppTheme {
  AppTheme._();

  static Widget _buttonBackground(
    BuildContext context,
    Set<WidgetState> states,
    Widget? child,
  ) {
    // Keep disabled and pending actions visually distinct.
    if (states.contains(WidgetState.disabled)) {
      return child ?? const SizedBox.shrink();
    }
    final button = context.widget;
    final theme = Theme.of(context);
    final ShapeBorder shape;
    if (button is FilledButton) {
      shape = button.style?.shape?.resolve(states) ??
          theme.filledButtonTheme.style?.shape?.resolve(states) ??
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    } else if (button is ElevatedButton) {
      shape = button.style?.shape?.resolve(states) ??
          theme.elevatedButtonTheme.style?.shape?.resolve(states) ??
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    } else {
      shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    }
    return Ink(
      decoration: ShapeDecoration(
        gradient: AppColors.brandGradient,
        shape: shape,
      ),
      child: child,
    );
  }

  /// The app uses light surfaces, including when Android is in dark mode.
  static const systemOverlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.white,
  );

  /// Light theme for the application.
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      tertiary: AppColors.tertiary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.divider),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.primary,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -.8,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.5,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: AppColors.textPrimary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.lavender,
        height: 70,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: 'Roboto',
            fontSize: 10,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.primaryDark
                : AppColors.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.surfaceVariant,
        selectedIconTheme: IconThemeData(color: AppColors.primary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.secondary,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ).copyWith(backgroundBuilder: _buttonBackground),
      ),

      // Custom AppBar Theme
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        systemOverlayStyle: systemOverlay,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),

      // Custom Card Theme
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: const Color(0x101C315C),
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.divider),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      // Custom Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        helperMaxLines: 4,
        errorMaxLines: 4,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),

      // Custom Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ).copyWith(backgroundBuilder: _buttonBackground),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lavender,
        selectedColor: AppColors.primary.withAlpha(28),
        labelStyle: const TextStyle(
          fontFamily: 'Roboto',
          color: AppColors.primaryDark,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
