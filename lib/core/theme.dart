import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Hybrid palette: coffee-warm surfaces (UI UX Pro Max) + Instagram gradient
// accents on primary interactive elements (heart swipe, CTAs, active states).
// Photography still carries the app — chrome stays neutral until the user acts.
const kBackground    = Color(0xFFFDF6E3); // warm cream, softer than #FEF3C7
const kSurface       = Color(0xFFFFFDF7); // near-white, subtle warmth
const kCardSurface   = Color(0xFFFFFFFF); // pure white for saved-shop cards
const kTextPrimary   = Color(0xFF451A03); // deep coffee brown
const kTextSecondary = Color(0xFF7A5A3A); // muted brown
const kBorder        = Color(0xFFE8DCC6); // warm divider

// Instagram gradient stops (for the heart button and primary CTAs only).
const kIgPink    = Color(0xFFDD2A7B);
const kIgOrange  = Color(0xFFF58529);
const kIgYellow  = Color(0xFFFEDA77);
const kIgPurple  = Color(0xFF833AB4);

const igGradient = LinearGradient(
  begin: Alignment.bottomLeft,
  end: Alignment.topRight,
  colors: [kIgYellow, kIgOrange, kIgPink, kIgPurple],
  stops: [0.0, 0.35, 0.7, 1.0],
);

ThemeData buildCoffeeTheme() {
  final base = ThemeData.light(useMaterial3: true);

  // Plus Jakarta Sans for all headline / display / title styles.
  // Inter for body and label styles — crisp and readable.
  final plusJakarta = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);
  final textTheme = plusJakarta.copyWith(
    bodyLarge:   GoogleFonts.inter(textStyle: plusJakarta.bodyLarge),
    bodyMedium:  GoogleFonts.inter(textStyle: plusJakarta.bodyMedium),
    bodySmall:   GoogleFonts.inter(textStyle: plusJakarta.bodySmall),
    labelLarge:  GoogleFonts.inter(textStyle: plusJakarta.labelLarge),
    labelMedium: GoogleFonts.inter(textStyle: plusJakarta.labelMedium),
    labelSmall:  GoogleFonts.inter(textStyle: plusJakarta.labelSmall),
  ).apply(
    bodyColor: kTextPrimary,
    displayColor: kTextPrimary,
  );

  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: kIgPink,
      brightness: Brightness.light,
    ).copyWith(
      primary: kIgPink,
      secondary: kIgOrange,
      surface: kSurface,
      onSurface: kTextPrimary,
    ),
    scaffoldBackgroundColor: kBackground,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: kBackground,
      foregroundColor: kTextPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: kTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: kCardSurface,
      elevation: 3,
      shadowColor: kTextPrimary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kIgPink,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: kBackground,
      side: const BorderSide(color: kBorder),
      labelStyle: GoogleFonts.inter(color: kTextPrimary, fontSize: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
    dividerColor: kBorder,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: kSurface,
      indicatorColor: kIgPink.withValues(alpha: 0.12),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: kIgPink);
        }
        return const IconThemeData(color: kTextSecondary);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.inter(
            color: kIgPink,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          );
        }
        return GoogleFonts.inter(color: kTextSecondary, fontSize: 12);
      }),
    ),
  );
}
