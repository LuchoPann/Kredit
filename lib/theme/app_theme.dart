import 'package:flutter/material.dart';

/// Palette ported from legacy_pwa/css/style.css :root tokens (pure/dark
/// theme — the app is dark-only, matching the PWA's default). Background
/// tone variants ("cool"/"warm" data-bg-theme) can be layered later via
/// ThemeExtension if the settings screen wires them up.
class AppColors {
  static const bgPrimary = Color(0xFF000000);
  static const bgSecondary = Color(0xFF0A0A0A);
  static const bgCard = Color(0xFF121212);
  static const borderCard = Color(0xFF262626);
  static const borderActive = Color(0xFF525252);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFA3A3A3);
  static const textTertiary = Color(0xFF737373);
  static const accentPrimaryDefault = Color(0xFFFFFFFF);

  // Semantic Colors: vibrant, accessible & modern fintech palette
  static const success = Color(0xFF10B981); // Emerald Green
  static const successBg = Color(0xFF064E3B);
  static const warning = Color(0xFFF59E0B); // Warm Amber
  static const warningBg = Color(0xFF78350F);
  static const danger = Color(0xFFEF4444);  // Crimson Red
  static const dangerBg = Color(0xFF7F1D1D);
  static const info = Color(0xFF06B6D4);    // Cyan

  // Accent color picker options — orden arcoíris (ROYGBIV + cierre):
  // blanco/negro neutro primero, luego 14 colores de la paleta nueva.
  static const accentOptions = <Color>[
    Color(0xFFFFFFFF), // neutro (blanco en oscuro, negro en claro)
    Color(0xFFD72027), // rojo
    Color(0xFFB11F24), // carmesí
    Color(0xFFF25A38), // rojo-naranja
    Color(0xFFF2845C), // naranja
    Color(0xFFFFDE59), // amarillo
    Color(0xFF00BF63), // verde
    Color(0xFF6BAF99), // verde-teal
    Color(0xFFB8E1D7), // menta
    Color(0xFF38B6FF), // azul cielo
    Color(0xFF006BFF), // azul
    Color(0xFF7A0CDC), // violeta profundo
    Color(0xFFCB6CE6), // violeta
    Color(0xFFECADBC), // rosa
  ];
}

/// Shared corner-radius tokens so every card/chip/badge in the app converges
/// on the same handful of values instead of ad-hoc numbers per widget
/// (audit found 9 distinct radii in use: 2/4/6/8/10/12/14/16/20 — this file
/// is the single source of truth going forward).
class KreditRadius {
  /// Top-level content cards (matches `CardThemeData` below), sheets, and
  /// any full-width container that reads as its own "surface".
  static const card = 16.0;

  /// Compact rows/tiles nested inside a card (e.g. list items, form field
  /// groupings) — one step down from [card].
  static const tile = 12.0;

  /// Small chips/badges/pills (status badges, demo badge, color swatches'
  /// square variant if any).
  static const chip = 8.0;
}

/// Shared font-size tokens, same rationale as [KreditRadius]/[KreditSpacing]:
/// an audit of every inline `TextStyle(fontSize: ...)` across the app found
/// ~20 distinct raw values (9, 10, 10.5, 11, 11.5, 12, 12.5, 13, 13.5, 14,
/// 14.5, 15, 16, 17, 18, 19, 20, 22, 26, 38) — mostly the same handful of
/// design intentions repeated with small, accidental variations rather than
/// deliberate differences. This class collapses them into a small, named
/// scale keyed to semantic role (not to whichever file happened to write
/// the number), so the same kind of text reads at the same size everywhere.
///
/// By explicit product decision this is capped at exactly FOUR sizes for
/// the whole app's reading hierarchy — [caption], [body], [heading] and
/// [emphasis] — instead of the finer-grained 9-step scale this class
/// started with. Distinct *roles* that used to get their own slightly
/// different pixel value (e.g. "section eyebrow" at 11 vs. "row subtitle"
/// at 12.5) now share one step of the hierarchy; they stay visually
/// distinguishable through weight/letter-spacing/color instead of size.
/// [hero] is the single documented exception: the dashboard's one-off
/// giant balance numeral is a numeral/logotype treatment, not a step in
/// the reading hierarchy, so it isn't counted among the four.
/// Four-level type scale for Kredit. Every text element uses one of these
/// four roles. The only exception is the 28px numeral in the billing-cycle
/// timeline (day-of-cut / payment-limit indicator), which is hardcoded at
/// its call site because it is a one-off display treatment, not a role.
class KreditTextSize {
  /// Compact diagram labels, chart ticks, timeline day numbers, and any
  /// text that is deliberately tiny (on a diagram, not in body copy).
  static const caption = 12.0;

  /// Default for all body copy, section info, labels, eyebrows, metadata,
  /// hints, and any readable text that is not a title or a number.
  static const body = 16.0;

  /// Subtitles, secondary headings, prominent labels — one step above body.
  static const heading = 18.0;

  /// Screen-level titles: greeting headers ("Buenos días, Usuario"),
  /// view titles, stat call-outs that need prominence.
  static const emphasis = 24.0;

  /// Large display numerals: dashboard total-debt hero figure and other
  /// big stat treatments where the number IS the message.
  static const hero = 38.0;
}

/// Exactly two icon sizes for the whole app (the `KreditLogo` brand mark is
/// the one deliberate exception, sized per its own context) — same
/// "small fixed set of named roles" rationale as [KreditTextSize].
/// Four-level icon scale matching the text scale. Every Icon size uses one
/// of these tokens — no bare numeric size literals anywhere in the app.
class KreditIconSize {
  /// Micro: inline status indicators, tiny badge decorations, dense chips.
  static const micro = 14.0;

  /// Small: section-header glyphs, row leading icons, button icons —
  /// the default for the vast majority of icons in the app.
  static const small = 18.0;

  /// Medium: selection chips, prominent action icons, card decorators.
  static const medium = 22.0;

  /// Large: empty-state/error placeholders, full-screen hero icons.
  static const large = 48.0;
}

/// Shared padding tokens, same rationale as [KreditRadius].
class KreditSpacing {
  /// Standard inner padding for a top-level card/sheet.
  static const card = 16.0;

  /// Inner padding for compact/nested rows.
  static const tile = 12.0;

  /// Vertical gap between distinct sections on a screen.
  static const section = 20.0;
}

/// Background tone variant, ported from legacy_pwa/css/style.css's
/// `:root[data-bg-theme="…"]` blocks (~L13-46). The provider-level
/// `BgTone` class (lib/providers/theme_provider.dart) uses the string
/// literals 'pure' | 'cool' | 'warm' — mirrored here as plain strings
/// (rather than importing that file) to avoid a theme_provider <-> app_theme
/// circular import. 'cool' maps to the CSS `midnight` set (subtle blue
/// tint) and 'warm' maps to the CSS `graphite` set (brighter neutral gray)
/// — the closest visual match to "cool"/"warm" among the two non-default
/// presets the original PWA shipped.
class _BgToneColors {
  final Color bgPrimary;
  final Color bgSecondary;
  final Color bgCard;
  final Color borderCard;

  const _BgToneColors({
    required this.bgPrimary,
    required this.bgSecondary,
    required this.bgCard,
    required this.borderCard,
  });
}

const _bgTonePure = _BgToneColors(
  bgPrimary: AppColors.bgPrimary,
  bgSecondary: AppColors.bgSecondary,
  bgCard: AppColors.bgCard,
  borderCard: AppColors.borderCard,
);

// CSS `:root[data-bg-theme="midnight"]` (~L40-45).
const _bgToneCool = _BgToneColors(
  bgPrimary: Color(0xFF050507),
  bgSecondary: Color(0xFF0A0A0E),
  bgCard: Color(0xFF12121B),
  borderCard: Color(0xFF24242C),
);

// Dark "Grafito" — re-tuned to read as genuinely warm (subtle brown/amber
// undertone) rather than a plain neutral gray, matching the light-mode
// "Arena" variant's intent.
const _bgToneWarm = _BgToneColors(
  bgPrimary: Color(0xFF120E0A),
  bgSecondary: Color(0xFF1A140D),
  bgCard: Color(0xFF211910),
  borderCard: Color(0xFF3A2C1B),
);

/// Tokens that vary by [bgTone] ('pure' | 'cool' | 'warm'), exposed via
/// `Theme.of(context).extension<KreditColors>()!` so widgets outside
/// `app_theme.dart` can read the current tone instead of the hardcoded
/// [AppColors] constants — this lets `MaterialApp.themeAnimationDuration`
/// (see lib/main.dart) interpolate these colors smoothly via [lerp] when
/// `bgTone` changes, instead of jumping.
class KreditColors extends ThemeExtension<KreditColors> {
  final Color bgPrimary;
  final Color bgSecondary;
  final Color bgCard;
  final Color borderCard;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color cardBorderSubtle;

  const KreditColors({
    required this.bgPrimary,
    required this.bgSecondary,
    required this.bgCard,
    required this.borderCard,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    this.success = AppColors.success,
    this.warning = AppColors.warning,
    this.danger = AppColors.danger,
    this.info = AppColors.info,
    this.cardBorderSubtle = const Color(0x1FFFFFFF),
  });

  @override
  KreditColors copyWith({
    Color? bgPrimary,
    Color? bgSecondary,
    Color? bgCard,
    Color? borderCard,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? cardBorderSubtle,
  }) {
    return KreditColors(
      bgPrimary: bgPrimary ?? this.bgPrimary,
      bgSecondary: bgSecondary ?? this.bgSecondary,
      bgCard: bgCard ?? this.bgCard,
      borderCard: borderCard ?? this.borderCard,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      cardBorderSubtle: cardBorderSubtle ?? this.cardBorderSubtle,
    );
  }

  @override
  KreditColors lerp(ThemeExtension<KreditColors>? other, double t) {
    if (other is! KreditColors) return this;
    return KreditColors(
      bgPrimary: Color.lerp(bgPrimary, other.bgPrimary, t)!,
      bgSecondary: Color.lerp(bgSecondary, other.bgSecondary, t)!,
      bgCard: Color.lerp(bgCard, other.bgCard, t)!,
      borderCard: Color.lerp(borderCard, other.borderCard, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      cardBorderSubtle: Color.lerp(cardBorderSubtle, other.cardBorderSubtle, t)!,
    );
  }
}

// Light mode tone variants.
// Design rule mirrors dark mode: bgCard is ALWAYS brighter/whiter than
// bgPrimary so cards visually elevate above the background — the same
// relationship dark mode has (bgCard #121212 on bgPrimary #000000).
// bgPrimary is never pure white so cards have a surface to elevate from.

// Blanco Puro — neutral light gray bg, white cards
const _bgToneLightPure = _BgToneColors(
  bgPrimary: Color(0xFFF0F4F8),
  bgSecondary: Color(0xFFE2E8F0),
  bgCard: Color(0xFFFFFFFF),
  borderCard: Color(0xFFCAD2DD),
);

// Nube — cool blue-tinted bg (analogous to dark Medianoche's subtle blue)
const _bgToneLightCool = _BgToneColors(
  bgPrimary: Color(0xFFE8F0FB),
  bgSecondary: Color(0xFFD5E3F5),
  bgCard: Color(0xFFFFFFFF),
  borderCard: Color(0xFFB8CEE8),
);

// Arena — warm cream-tinted bg (analogous to dark Ámbar's subtle warm)
const _bgToneLightWarm = _BgToneColors(
  bgPrimary: Color(0xFFF5EDE0),
  bgSecondary: Color(0xFFEDD9C4),
  bgCard: Color(0xFFFFFFFF),
  borderCard: Color(0xFFD4BEA0),
);

_BgToneColors _resolveBgTone(String bgTone, bool isDarkMode) {
  if (isDarkMode) {
    switch (bgTone) {
      case 'cool':
        return _bgToneCool;
      case 'warm':
        return _bgToneWarm;
      case 'pure':
      default:
        return _bgTonePure;
    }
  } else {
    switch (bgTone) {
      case 'cool':
        return _bgToneLightCool;
      case 'warm':
        return _bgToneLightWarm;
      case 'pure':
      default:
        return _bgToneLightPure;
    }
  }
}

/// Resolves the accent color actually rendered on screen for a given
/// [isDarkMode]: the default white swatch flips to near-black (#0F172A) in
/// light mode so it stays visible against a light background — any other
/// chosen accent color passes through unchanged. Shared by [buildAppTheme]
/// and the accent-color picker UI so the swatch preview always matches what
/// gets applied.
Color resolveEffectiveAccent(Color accent, bool isDarkMode) {
  final isDefaultWhite = accent == AppColors.accentPrimaryDefault || accent == Colors.white;
  return (!isDarkMode && isDefaultWhite) ? const Color(0xFF0F172A) : accent;
}

// Referencias de temperatura para el lerp de tono.
// Warm: ámbar (naranja suave) — Cool: azul cielo.
const _warmTintRef = Color(0xFFFFA040);
const _coolTintRef = Color(0xFF4090FF);
// Factor 0.25 → cambio visible (~25% mezcla) pero no tan extremo
// que el color pierda su identidad.
const _toneLerpFactor = 0.25;

/// Desplaza [accent] hacia la temperatura del [bgTone] seleccionado:
/// 'warm' → mezcla 25% hacia ámbar, 'cool' → 25% hacia azul claro.
/// Todos los acentos reciben exactamente el mismo grado de desplazamiento,
/// así la diferencia entre tonos se percibe de forma consistente.
/// El neutro blanco/negro queda excluido — siempre pasa sin cambio.
Color applyBgToneToAccent(Color accent, String bgTone, bool isDarkMode) {
  final isNeutral = accent == AppColors.accentPrimaryDefault ||
      accent == Colors.white ||
      accent == const Color(0xFF0F172A);
  if (isNeutral || bgTone == 'pure') return accent;

  switch (bgTone) {
    case 'warm':
      return Color.lerp(accent, _warmTintRef, _toneLerpFactor)!;
    case 'cool':
      return Color.lerp(accent, _coolTintRef, _toneLerpFactor)!;
    default:
      return accent;
  }
}

/// Picks a legible foreground (black or white) for text/icons drawn directly
/// on top of [background], based on its relative luminance.
///
/// Single unified threshold of 0.4 — the audit found this logic duplicated
/// across the app with two different thresholds (0.3 in dashboard_screen.dart
/// / credits_list_screen.dart, 0.5 in schedule_tab.dart), which meant the
/// same accent color could flip to a different (and sometimes wrong)
/// foreground depending on which screen rendered it.
///
/// Picks whichever of black/white gives the higher WCAG contrast ratio
/// against [background], instead of a single fixed luminance threshold.
/// A fixed cutoff (e.g. "luminance > 0.4 → black") gets several of this
/// app's own accent options wrong — the pastel purple/blue/pink swatches
/// sit just under 0.4 luminance, so a threshold picks white for them, but
/// black is actually 3-4x higher contrast on every one of them (their
/// luminance is "medium", not genuinely dark). Computing both ratios and
/// comparing directly gets every accent right without needing to special-
/// case any of them.
Color legibleForegroundOn(Color background) {
  final bgLuminance = background.computeLuminance();
  final contrastWithBlack = (bgLuminance + 0.05) / 0.05;
  final contrastWithWhite = 1.05 / (bgLuminance + 0.05);
  return contrastWithBlack >= contrastWithWhite ? Colors.black : Colors.white;
}

ThemeData buildAppTheme({
  Color accent = AppColors.accentPrimaryDefault,
  String bgTone = 'pure',
  bool isDarkMode = true,
}) {
  final base = isDarkMode ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
  final tone = _resolveBgTone(bgTone, isDarkMode);

  final bgPrimary = tone.bgPrimary;
  final bgSecondary = tone.bgSecondary;
  final bgCard = tone.bgCard;
  final borderCard = tone.borderCard;
  // Dark mode: full-strength white for all levels (hierarchy via size/weight).
  // Light mode: 3-level slate scale — primary=dark navy, secondary=medium
  // slate, tertiary=lighter slate — mirrors the depth that dark-mode backgrounds
  // provide naturally, giving both modes the same visual hierarchy.
  final textPrimary = isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
  final textSecondary = isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF334155);
  final textTertiary = isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF64748B);

  final effectiveAccent = applyBgToneToAccent(
    resolveEffectiveAccent(accent, isDarkMode),
    bgTone,
    isDarkMode,
  );

  return base.copyWith(
    scaffoldBackgroundColor: bgPrimary,
    focusColor: Colors.transparent,
    highlightColor: (isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.05),
    splashColor: (isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.05),
    colorScheme: base.colorScheme.copyWith(
      surface: bgCard,
      primary: effectiveAccent,
      secondary: effectiveAccent,
      error: Colors.redAccent,
    ),
    // Dual typographic system:
    // 1. Display / Metrics / Headings: 'SpaceGrotesk' (aesthetic, geometric character)
    // 2. Functional Body / Labels / Data: 'Outfit' (100% legible, clean line heights)
    textTheme: base.textTheme.apply(
      fontFamily: 'Outfit',
      bodyColor: textPrimary,
      displayColor: textPrimary,
    ).copyWith(
      displayLarge: base.textTheme.displayLarge?.copyWith(
        fontFamily: 'SpaceGrotesk',
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: -1.2,
      ),
      displayMedium: base.textTheme.displayMedium?.copyWith(
        fontFamily: 'SpaceGrotesk',
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: -0.8,
      ),
      displaySmall: base.textTheme.displaySmall?.copyWith(
        fontFamily: 'SpaceGrotesk',
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontFamily: 'SpaceGrotesk',
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontFamily: 'SpaceGrotesk',
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontFamily: 'SpaceGrotesk',
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontFamily: 'SpaceGrotesk',
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontFamily: 'SpaceGrotesk',
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleSmall: base.textTheme.titleSmall?.copyWith(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      // Material's own default style for TextField/DropdownButtonFormField
      // input text (and nothing else — no other widget in this app reads
      // bodyLarge). Set to body (14px) for consistency: all input fields
      // use the same size, matching the standard body token.
      bodyLarge: const TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w500,
        fontSize: KreditTextSize.body,
        height: 1.3,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w400,
        fontSize: KreditTextSize.body,
        height: 1.35,
        color: textSecondary,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w400,
        fontSize: KreditTextSize.body,
        height: 1.3,
        color: textTertiary,
      ),
      labelLarge: const TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w700,
        fontSize: KreditTextSize.body,
        letterSpacing: 0.4,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w600,
        fontSize: KreditTextSize.body,
        letterSpacing: 0.6,
        color: textSecondary,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w600,
        fontSize: KreditTextSize.body,
        letterSpacing: 1.1,
        color: textTertiary,
      ),
    ),
    cardTheme: CardThemeData(
      color: bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: borderCard),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bgPrimary,
      foregroundColor: textPrimary,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: KreditTextSize.emphasis,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        textStyle: const TextStyle(fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w700),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: const TextStyle(fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textPrimary,
        textStyle: const TextStyle(fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w600),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      // Matches the scaffold's own background (not bgSecondary) so the nav
      // bar blends into whichever bgTone the user picked instead of reading
      // as a visibly different strip of color.
      backgroundColor: bgPrimary,
      selectedItemColor: effectiveAccent,
      unselectedItemColor: textTertiary,
    ),
    dividerColor: borderCard,
    canvasColor: bgCard,
    dialogTheme: DialogThemeData(backgroundColor: bgCard),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: bgCard),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return effectiveAccent.computeLuminance() > 0.7 ? Colors.black : Colors.white;
        }
        return null;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) return effectiveAccent;
        return null;
      }),
    ),
    extensions: [
      KreditColors(
        bgPrimary: bgPrimary,
        bgSecondary: bgSecondary,
        bgCard: bgCard,
        borderCard: borderCard,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        textTertiary: textTertiary,
        success: isDarkMode ? const Color(0xFF10B981) : const Color(0xFF059669),
        warning: isDarkMode ? const Color(0xFFF59E0B) : const Color(0xFFD97706),
        danger: isDarkMode ? const Color(0xFFEF4444) : const Color(0xFFDC2626),
        info: isDarkMode ? const Color(0xFF06B6D4) : const Color(0xFF0891B2),
        cardBorderSubtle: isDarkMode
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06),
      ),
    ],
  );
}
