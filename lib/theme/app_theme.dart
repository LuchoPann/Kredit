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
  static const success = Color(0xFFFFFFFF);
  static const successBg = Color(0xFF262626);
  static const warning = Color(0xFFA3A3A3);
  static const danger = Color(0xFFFFFFFF);

  // Accent color picker options (ported from index.html color-option swatches).
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

// CSS `:root[data-bg-theme="graphite"]` (~L34-39).
const _bgToneWarm = _BgToneColors(
  bgPrimary: Color(0xFF0D0D0D),
  bgSecondary: Color(0xFF141414),
  bgCard: Color(0xFF191919),
  borderCard: Color(0xFF2E2E2E),
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

  const KreditColors({
    required this.bgPrimary,
    required this.bgSecondary,
    required this.bgCard,
    required this.borderCard,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
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
  }) {
    return KreditColors(
      bgPrimary: bgPrimary ?? this.bgPrimary,
      bgSecondary: bgSecondary ?? this.bgSecondary,
      bgCard: bgCard ?? this.bgCard,
      borderCard: borderCard ?? this.borderCard,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
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
  final textPrimary = isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
  final textSecondary = isDarkMode ? const Color(0xFFA3A3A3) : const Color(0xFF475569);
  final textTertiary = isDarkMode ? const Color(0xFF737373) : const Color(0xFF64748B);

  final effectiveAccent = resolveEffectiveAccent(accent, isDarkMode);

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
    // Two-tier type system ported from legacy_pwa/css/style.css:
    // `--font-family: 'Outfit'` for body copy, `--font-family-display:
    // 'Space Grotesk'` for headings/titles/big numbers/buttons. Outfit is
    // the base applied to the whole TextTheme; the display/headline/title
    // categories are overridden back to SpaceGrotesk to match the CSS split.
    textTheme: base.textTheme.apply(
      fontFamily: 'Outfit',
      bodyColor: textPrimary,
      displayColor: textPrimary,
    ).copyWith(
      bodyMedium: TextStyle(fontFamily: 'Outfit', color: textSecondary),
      displayLarge: base.textTheme.displayLarge?.copyWith(fontFamily: 'SpaceGrotesk', color: textPrimary),
      displayMedium: base.textTheme.displayMedium?.copyWith(fontFamily: 'SpaceGrotesk', color: textPrimary),
      displaySmall: base.textTheme.displaySmall?.copyWith(fontFamily: 'SpaceGrotesk', color: textPrimary),
      headlineLarge: base.textTheme.headlineLarge?.copyWith(fontFamily: 'SpaceGrotesk', color: textPrimary),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(fontFamily: 'SpaceGrotesk', color: textPrimary),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(fontFamily: 'SpaceGrotesk', color: textPrimary),
      titleLarge: base.textTheme.titleLarge?.copyWith(fontFamily: 'SpaceGrotesk', color: textPrimary),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontFamily: 'SpaceGrotesk', color: textPrimary),
      titleSmall: base.textTheme.titleSmall?.copyWith(fontFamily: 'SpaceGrotesk', color: textPrimary),
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
      backgroundColor: bgSecondary,
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
      ),
    ],
  );
}
