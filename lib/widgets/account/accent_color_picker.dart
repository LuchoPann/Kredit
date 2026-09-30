import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class AccentColorPicker extends ConsumerWidget {
  const AccentColorPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(themePreferencesProvider);
    final selected = prefs.accentColor;
    final isDarkMode = prefs.isDarkMode;
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Color de acento', style: TextStyle(color: kredit.textSecondary)),
        const SizedBox(height: KreditSpacing.tile),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: AppColors.accentOptions.map((color) {
            final isSelected = color.toARGB32() == selected.toARGB32();
            // Show the color as it will actually render (the default
            // white swatch flips to near-black in light mode, and every
            // other accent picks up the current bgTone's cool/warm
            // tint) so the preview never lies about what tapping it
            // applies.
            final displayColor = applyBgToneToAccent(
              resolveEffectiveAccent(color, isDarkMode),
              prefs.bgTone,
              isDarkMode,
            );
            final checkColor =
                ThemeData.estimateBrightnessForColor(displayColor) == Brightness.dark
                    ? Colors.white
                    : Colors.black;
            return GestureDetector(
              onTap: () => ref
                  .read(themePreferencesProvider.notifier)
                  .setAccentColor(color),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: displayColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? kredit.textPrimary : kredit.borderCard,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected
                    ? Icon(Icons.check, size: KreditIconSize.small, color: checkColor)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
