import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class BgTonePicker extends ConsumerWidget {
  const BgTonePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(themePreferencesProvider);
    final selected = prefs.bgTone;
    final isDark = prefs.isDarkMode;
    final options = isDark
        ? const [
            (value: BgTone.pure, label: 'Oscuro Puro'),
            (value: BgTone.cool, label: 'Medianoche'),
            (value: BgTone.warm, label: 'Ámbar'),
          ]
        : const [
            (value: BgTone.pure, label: 'Blanco Puro'),
            (value: BgTone.cool, label: 'Nube'),
            (value: BgTone.warm, label: 'Arena'),
          ];

    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isDark ? 'Variante de Tema Oscuro' : 'Variante de Tema Claro',
          style: TextStyle(color: kredit.textSecondary),
        ),
        const SizedBox(height: AppSpacing.tile),
        Row(
          children: options.map((opt) {
            final isSelected = opt.value == selected;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(opt.label),
                  selected: isSelected,
                  onSelected: (_) => ref
                      .read(themePreferencesProvider.notifier)
                      .setBgTone(opt.value),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
