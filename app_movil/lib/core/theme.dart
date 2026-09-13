import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Las 2 paletas seleccionables desde Perfil > Apariencia.
enum AppThemeOption { energetic, premium }

/// Paleta centralizada. Todo el look de la app sale de aquí — cambiar un
/// tema es cambiar esta clase, no ir pantalla por pantalla.
class AppColors {
  AppColors._();

  /// Opción A "Energético": naranja como primario, teal como acento.
  static const energeticPrimary = Color(0xFFFF6B35);
  static const energeticSecondary = Color(0xFF2EC4B6);

  /// Opción B "Premium": verde oscuro como primario, el naranja pasa a
  /// ser solo el acento.
  static const premiumPrimary = Color(0xFF1B5E4F);
  static const premiumSecondary = Color(0xFFFF6B35);

  static const onPrimary = Colors.white;
  static const onSecondary = Colors.white;

  static const background = Color(0xFFFAFAFA);
  static const surface = Colors.white;

  static const error = Color(0xFFD64545);
  static const onSurface = Color(0xFF1C1B1F);

  /// Semántico para estados "activo" (ej. badge de rutina en curso) -
  /// igual en ambas paletas.
  static const success = Color(0xFF2E8B57);

  /// Paleta para avatares con iniciales (clientes, perfil): un color
  /// consistente por nombre, no aleatorio en cada rebuild. Igual en
  /// ambas paletas -no depende del tema elegido-.
  static const avatarPalette = [
    Color(0xFFEF6C57),
    Color(0xFF2EC4B6),
    Color(0xFF5B8DEF),
    Color(0xFFB98BDE),
    Color(0xFFFFB627),
    Color(0xFF48A9A6),
    Color(0xFFE76F51),
  ];
}

/// Datos de tema que ThemeData no modela directamente (ej. el degradado
/// suave del header en las pantallas principales de la paleta Energético).
/// Se lee con `Theme.of(context).extension<AppGradients>()`.
class AppGradients extends ThemeExtension<AppGradients> {
  final Gradient? headerGradient;

  const AppGradients({this.headerGradient});

  @override
  AppGradients copyWith({Gradient? headerGradient}) {
    return AppGradients(headerGradient: headerGradient ?? this.headerGradient);
  }

  @override
  AppGradients lerp(ThemeExtension<AppGradients>? other, double t) {
    if (other is! AppGradients) return this;
    return AppGradients(headerGradient: Gradient.lerp(headerGradient, other.headerGradient, t));
  }
}

ThemeData _buildTheme({
  required Color primary,
  required Color secondary,
  required Gradient? headerGradient,
}) {
  final colorScheme = ColorScheme.light(
    primary: primary,
    onPrimary: AppColors.onPrimary,
    secondary: secondary,
    onSecondary: AppColors.onSecondary,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    error: AppColors.error,
    onError: Colors.white,
  );

  final base = ThemeData(colorScheme: colorScheme, useMaterial3: true);

  final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
    headlineMedium: GoogleFonts.poppins(
      fontSize: 26,
      fontWeight: FontWeight.w600,
      color: AppColors.onSurface,
    ),
    titleMedium: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.onSurface,
    ),
    bodyMedium: GoogleFonts.poppins(
      fontSize: 14,
      color: AppColors.onSurface.withValues(alpha: 0.7),
    ),
    labelSmall: GoogleFonts.poppins(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
      color: AppColors.onSurface.withValues(alpha: 0.6),
    ),
  );

  return base.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      margin: EdgeInsets.zero,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: textTheme.titleMedium?.copyWith(color: Colors.white),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: secondary,
        side: BorderSide(color: secondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: primary,
      unselectedItemColor: AppColors.onSurface.withValues(alpha: 0.45),
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      selectedLabelStyle: textTheme.labelSmall?.copyWith(color: primary),
      unselectedLabelStyle: textTheme.labelSmall,
    ),
    extensions: [AppGradients(headerGradient: headerGradient)],
  );
}

/// Los 2 ThemeData completos y seleccionables desde Perfil > Apariencia.
class AppTheme {
  AppTheme._();

  /// Opción A: naranja energético + header con degradado suave
  /// (#FFF3ED -> blanco) en las pantallas principales.
  static ThemeData get energetic => _buildTheme(
        primary: AppColors.energeticPrimary,
        secondary: AppColors.energeticSecondary,
        headerGradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF3ED), Colors.white],
        ),
      );

  /// Opción B: verde oscuro como primario, naranja como acento, fondo
  /// neutro plano (sin degradado).
  static ThemeData get premium => _buildTheme(
        primary: AppColors.premiumPrimary,
        secondary: AppColors.premiumSecondary,
        headerGradient: null,
      );
}

ThemeData themeFor(AppThemeOption option) {
  return switch (option) {
    AppThemeOption.energetic => AppTheme.energetic,
    AppThemeOption.premium => AppTheme.premium,
  };
}
