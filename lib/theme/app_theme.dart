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

  // Accent color picker options (modern electric/cyber swatches).
  static const accentOptions = <Color>[
    Color(0xFFFFFFFF),
    Color(0xFF00F2FE),
    Color(0xFFC084FC),
    Color(0xFF4FACFE),
    Color(0xFFFACC15),
    Color(0xFF34D399),
    Color(0xFFFB7185),
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
/// This does NOT mean "one size for all text" — different roles (a section
/// title vs. a caption) are still visually distinct on purpose.
class KreditTextSize {
  /// Smallest extreme: tiny badges/counters (e.g. demo badge, progress-ring
  /// mini label).
  static const micro = 10.0;

  /// Uppercase section eyebrows/labels (e.g. "MONTO Y CUOTA"), secondary
  /// captions.
  static const caption = 11.0;

  /// Secondary/metadata text: row subtitles, contextual help/notes under a
  /// field, hint text.
  static const label = 12.5;

  /// Default "normal" text: form field values, list-row titles, most body
  /// copy.
  static const body = 14.0;

  /// Sub-section titles within a screen (one step below [title]).
  static const bodyLarge = 15.0;

  /// Full section titles at the screen level (e.g. "Próximos pagos", "Tus
  /// créditos").
  static const title = 17.0;

  /// Stat-tile figures (matches the recently-unified `_SecondaryStat` /
  /// `_StatColumn` / `_StatTile` value size).
  static const value = 19.0;

  /// Second-level highlighted figures (dialog confirmation amounts, larger
  /// stat call-outs).
  static const valueLarge = 22.0;

  /// Dashboard hero figure ("DEUDA TOTAL").
  static const display = 38.0;
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

// Light mode tone variants — distinctly differentiated
const _bgToneLightPure = _BgToneColors(
  bgPrimary: Color(0xFFFFFFFF),
  bgSecondary: Color(0xFFF1F5F9),
  bgCard: Color(0xFFF8FAFC),
  borderCard: Color(0xFFE2E8F0),
);

const _bgToneLightCool = _BgToneColors(
  bgPrimary: Color(0xFFEEF2F6),
  bgSecondary: Color(0xFFE2E8F0),
  bgCard: Color(0xFFFFFFFF),
  borderCard: Color(0xFFCBD5E1),
);

const _bgToneLightWarm = _BgToneColors(
  bgPrimary: Color(0xFFFDFBF7),
  bgSecondary: Color(0xFFF5F0E6),
  bgCard: Color(0xFFFFFFFF),
  borderCard: Color(0xFFE7E5E4),
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

// Subtle reference hues blended into a chosen accent to make it feel part of
// the selected bgTone's temperature — a light nudge, not a hue replacement.
const _coolTintRef = Color(0xFF5AA9FF);
const _warmTintRef = Color(0xFFFF9D4D);

/// Tints [accent] toward the given [bgTone]'s temperature ('cool' → bluer,
/// 'warm' → oranger, 'pure' → unchanged), so a user's chosen accent colour
/// feels coherent with the background variant they picked instead of
/// clashing against it. The neutral black/white default swatch is excluded
/// on purpose — those are meant to stay perfectly neutral regardless of
/// bgTone, since [resolveEffectiveAccent] already treats them as "no accent
/// colour chosen".
Color applyBgToneToAccent(Color accent, String bgTone, bool isDarkMode) {
  final isNeutral = accent == AppColors.accentPrimaryDefault ||
      accent == Colors.white ||
      accent == const Color(0xFF0F172A);
  if (isNeutral) return accent;

  switch (bgTone) {
    case 'cool':
      return Color.lerp(accent, _coolTintRef, 0.16)!;
    case 'warm':
      return Color.lerp(accent, _warmTintRef, 0.16)!;
    case 'pure':
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
/// foreground depending on which screen rendered it. 0.4 sits at the
/// midpoint of the two ad-hoc values previously in use and biases slightly
/// toward white foreground (better for the mid-tone/saturated accent colors
/// this app offers, which tend to still read as "dark" backgrounds even
/// above 0.3 luminance) while still flipping to black for genuinely light
/// backgrounds like the default white accent.
Color legibleForegroundOn(Color background) {
  return background.computeLuminance() > 0.4 ? Colors.black : Colors.white;
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
  // Full-strength text in both modes — 100% white on dark, 100% near-black on
  // light — per explicit product decision to never let text read as "grayed
  // out"/low-contrast. Hierarchy between primary/secondary/tertiary roles
  // still comes through (font size, weight, letter-spacing), just not via
  // reduced opacity/tint, which was reading as illegible gray to users.
  final textPrimary = isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
  final textSecondary = textPrimary;
  final textTertiary = textPrimary;

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
      bodyLarge: const TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w500,
        fontSize: 15,
        height: 1.4,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w400,
        fontSize: 13.5,
        height: 1.35,
        color: textSecondary,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w400,
        fontSize: 12,
        height: 1.3,
        color: textTertiary,
      ),
      labelLarge: const TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w700,
        fontSize: 13.5,
        letterSpacing: 0.4,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w600,
        fontSize: 11.5,
        letterSpacing: 0.6,
        color: textSecondary,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w600,
        fontSize: 10.5,
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
        fontSize: 20,
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
