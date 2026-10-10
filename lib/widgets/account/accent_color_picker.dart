import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class AccentColorPicker extends ConsumerWidget {
  const AccentColorPicker({super.key});

  Future<void> _abrirCuentagotas(BuildContext context, WidgetRef ref, Color current) async {
    Color temp = current;
    await showDialog(
      context: context,
      builder: (ctx) {
        final kredit = Theme.of(ctx).extension<AppThemeColors>()!;
        return AlertDialog(
          backgroundColor: kredit.bgCard,
          title: const Text('Color personalizado'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: current,
              onColorChanged: (c) => temp = c,
              enableAlpha: false,
              labelTypes: const [],
              pickerAreaHeightPercent: 0.7,
              displayThumbColor: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                ref.read(themePreferencesProvider.notifier).setAccentColor(temp);
                Navigator.pop(ctx);
              },
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(themePreferencesProvider);
    final selected = prefs.accentColor;
    final isDarkMode = prefs.isDarkMode;
    final kredit = Theme.of(context).extension<AppThemeColors>()!;

    // Verifica si el color seleccionado es personalizado (no está en la paleta)
    final isCustom = !AppColors.accentOptions
        .any((c) => c.toARGB32() == selected.toARGB32());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Color de acento', style: TextStyle(color: kredit.textSecondary)),
        const SizedBox(height: AppSpacing.tile),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            ...AppColors.accentOptions.map((color) {
              final isSelected = color.toARGB32() == selected.toARGB32();
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
                      ? Icon(Icons.check, size: AppIconSize.small, color: checkColor)
                      : null,
                ),
              );
            }),
            // Botón cuentagotas — muestra el color personalizado si aplica
            GestureDetector(
              onTap: () => _abrirCuentagotas(context, ref, selected),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCustom ? kredit.textPrimary : kredit.borderCard,
                    width: isCustom ? 3 : 1.5,
                  ),
                  // Si hay color personalizado, mostrarlo; si no, gradiente arcoíris
                  color: isCustom ? selected : null,
                  gradient: isCustom
                      ? null
                      : const SweepGradient(
                          colors: [
                            Color(0xFFEF4444),
                            Color(0xFFF97316),
                            Color(0xFFF59E0B),
                            Color(0xFF22C55E),
                            Color(0xFF3B82F6),
                            Color(0xFF8B5CF6),
                            Color(0xFFEC4899),
                            Color(0xFFEF4444),
                          ],
                        ),
                ),
                child: isCustom
                    ? Icon(
                        Icons.check,
                        size: AppIconSize.small,
                        color: ThemeData.estimateBrightnessForColor(selected) == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      )
                    : const Icon(Icons.colorize, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
