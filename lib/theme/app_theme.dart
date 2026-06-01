import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

<<<<<<< HEAD
  static const Color background = Color(0xFF101820);
  static const Color surface = Color(0xFF17212B);
  static const Color card = Color(0xFF202B36);
  static const Color primary = Color(0xFF22D3C5);
  static const Color secondary = Color(0xFFFFC857);
  static const Color emergency = Color(0xFFE53935);
  static const Color success = Color(0xFF4ADE80);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFFAEB7C2);
  static const Color muted = Color(0xFF6E7A88);
  static const Color border = Color(0xFF2D3A47);
=======
  static const Color background = Color(0xFF1A1F26); // dark navy/black
  static const Color primary = Color(0xFFFFD700); // gold
  static const Color card = Color(0xFF252A34); // slightly lighter card
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFFA0A0A0);
>>>>>>> de408701751cae7e5e23c4f3f5bba691d3828f01
}

class AppTheme {
  AppTheme._();

  static ThemeData get theme {
<<<<<<< HEAD
    final colorScheme = const ColorScheme.dark().copyWith(
      surface: AppColors.background,
      primary: AppColors.primary,
      onPrimary: AppColors.background,
      secondary: AppColors.secondary,
      onSurface: AppColors.white,
      error: AppColors.emergency,
=======
    final colorScheme = ColorScheme.dark().copyWith(
      // Use `surface` as the app's main background tone per update
      surface: AppColors.background,
      primary: AppColors.primary,
      onPrimary: Colors.black,
      secondary: AppColors.card,
      onSurface: AppColors.white,
>>>>>>> de408701751cae7e5e23c4f3f5bba691d3828f01
    );

    final base = ThemeData.dark();

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      primaryColor: AppColors.primary,
      cardColor: AppColors.card,
      highlightColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        elevation: 0,
<<<<<<< HEAD
        centerTitle: false,
=======
        centerTitle: true,
>>>>>>> de408701751cae7e5e23c4f3f5bba691d3828f01
        iconTheme: const IconThemeData(color: AppColors.white),
        titleTextStyle: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.bold,
<<<<<<< HEAD
          fontSize: 30,
=======
          fontSize: 28,
>>>>>>> de408701751cae7e5e23c4f3f5bba691d3828f01
        ),
        displayMedium: TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w700,
<<<<<<< HEAD
          fontSize: 24,
=======
          fontSize: 22,
>>>>>>> de408701751cae7e5e23c4f3f5bba691d3828f01
        ),
        titleLarge: TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        titleMedium: TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyLarge: TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        bodyMedium: TextStyle(
          color: AppColors.grey,
          fontWeight: FontWeight.w400,
          fontSize: 13,
        ),
      ),

      cardTheme: const CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
<<<<<<< HEAD
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        labelStyle: const TextStyle(color: AppColors.grey),
        hintStyle: const TextStyle(color: AppColors.muted),
        prefixIconColor: AppColors.primary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.emergency),
=======
          borderRadius: BorderRadius.all(Radius.circular(24)),
>>>>>>> de408701751cae7e5e23c4f3f5bba691d3828f01
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
<<<<<<< HEAD
          foregroundColor: AppColors.background,
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
=======
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
>>>>>>> de408701751cae7e5e23c4f3f5bba691d3828f01
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.white,
<<<<<<< HEAD
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return AppColors.surface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.background;
            }
            return AppColors.white;
          }),
          side: WidgetStateProperty.all(
            const BorderSide(color: AppColors.border),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),

      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.card,
        contentTextStyle: TextStyle(color: AppColors.white),
      ),

=======
          side: const BorderSide(color: AppColors.grey),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

>>>>>>> de408701751cae7e5e23c4f3f5bba691d3828f01
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey,
        showUnselectedLabels: true,
        elevation: 8,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
      ),

      // Reduce motion where possible
<<<<<<< HEAD
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
=======
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      }),
>>>>>>> de408701751cae7e5e23c4f3f5bba691d3828f01
    );
  }
}
