import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:krezium/theme/app_theme.dart';

/// Widget reutilizable: paleta de colores básicos + botón cuentagotas.
///
/// [color] es el color actualmente seleccionado.
/// [onColorChanged] se llama al cambiar.
/// [colores] paleta de colores predefinidos (opcional, usa la paleta default).
class ColorPickerField extends StatelessWidget {
  final Color color;
  final ValueChanged<Color> onColorChanged;
  final List<Color>? colores;

  const ColorPickerField({
    super.key,
    required this.color,
    required this.onColorChanged,
    this.colores,
  });

  static const _defaultColors = [
    Color(0xFFEF4444), // Rojo
    Color(0xFF3B82F6), // Azul
    Color(0xFF22C55E), // Verde
    Color(0xFFF59E0B), // Amarillo
    Color(0xFF8B5CF6), // Morado
    Color(0xFFEC4899), // Rosa
    Color(0xFF14B8A6), // Verde azul
    Color(0xFFF97316), // Naranja
    Color(0xFF6B7280), // Gris
    Color(0xFF0EA5E9), // Celeste
    Color(0xFFD97706), // Ámbar
    Color(0xFF10B981), // Esmeralda
  ];

  Future<void> _abrirCuentagotas(BuildContext context) async {
    Color temp = color;
    await showDialog(
      context: context,
      builder: (ctx) {
        final tc = Theme.of(ctx).extension<AppThemeColors>()!;
        return AlertDialog(
          backgroundColor: tc.bgCard,
          title: const Text('Color personalizado'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: color,
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
                onColorChanged(temp);
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
  Widget build(BuildContext context) {
    final palette = colores ?? _defaultColors;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...palette.map((c) {
          final selected = color.toARGB32() == c.toARGB32();
          return GestureDetector(
            onTap: () => onColorChanged(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: selected
                    ? Border.all(
                        color: Theme.of(context).colorScheme.onSurface,
                        width: 3,
                      )
                    : null,
                boxShadow: selected
                    ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 6)]
                    : null,
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          );
        }),
        // Botón cuentagotas
        GestureDetector(
          onTap: () => _abrirCuentagotas(context),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1.5,
              ),
              gradient: const SweepGradient(
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
            child: const Icon(Icons.colorize, size: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

/// Convierte un Color a hex sin '#' (ej: 'EF4444')
String colorToHex(Color color) =>
    color.toARGB32().toRadixString(16).substring(2).toUpperCase();

/// Convierte hex sin '#' a Color
Color hexToColor(String hex) =>
    Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
