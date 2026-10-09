import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Bottom sheet de confirmación (reemplaza AlertDialog con bool).
/// Retorna true si el usuario confirmó, false/null si canceló.
Future<bool> showAppConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool isDanger = false,
  String cancelLabel = 'Cancelar',
  IconData? icon,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final kredit = Theme.of(ctx).extension<AppThemeColors>()!;
      final accent = Theme.of(ctx).colorScheme.primary;
      final actionColor = isDanger ? AppColors.danger : accent;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: kredit.borderCard,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (icon != null) ...[
                Icon(icon, size: 28, color: actionColor),
                const SizedBox(height: 12),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: AppTextSize.heading,
                  fontWeight: FontWeight.w700,
                  color: kredit.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  fontSize: AppTextSize.body,
                  color: kredit.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: actionColor,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(confirmLabel),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46),
                ),
                child: Text(cancelLabel,
                    style: TextStyle(color: kredit.textSecondary)),
              ),
            ],
          ),
        ),
      );
    },
  );
  return result == true;
}

/// Abre un bottom sheet con el estilo visual estándar de Kredit:
/// fondo transparente, DraggableScrollableSheet, borde r=24, handle pill.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext ctx, ScrollController scrollController) builder,
  double initialSize = 0.6,
  double minSize = 0.35,
  double maxSize = 0.92,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: initialSize,
      minChildSize: minSize,
      maxChildSize: maxSize,
      builder: (ctx, scrollController) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).extension<AppThemeColors>()!.borderCard,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: builder(ctx, scrollController),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Header estándar para bottom sheets de Kredit.
/// Ícono con fondo translúcido + título + subtítulo.
class AppSheetHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const AppSheetHeader({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: AppTextSize.emphasis,
                  fontWeight: FontWeight.w800,
                  color: kredit.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: AppTextSize.caption,
                  color: kredit.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet de entrada de texto (reemplaza AlertDialog con String).
/// Retorna el texto ingresado o null si canceló.
Future<String?> showAppInputSheet(
  BuildContext context, {
  required String title,
  String? initialValue,
  String? hint,
  String confirmLabel = 'Guardar',
  String cancelLabel = 'Cancelar',
  TextInputType keyboardType = TextInputType.text,
  int? maxLines = 1,
}) async {
  final controller = TextEditingController(text: initialValue ?? '');
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final kredit = Theme.of(ctx).extension<AppThemeColors>()!;
      return Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: kredit.borderCard,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: AppTextSize.heading,
                fontWeight: FontWeight.w700,
                color: kredit.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: keyboardType,
              maxLines: maxLines,
              decoration: InputDecoration(hintText: hint),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
              child: Text(confirmLabel),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46)),
              child: Text(cancelLabel,
                  style: TextStyle(color: kredit.textSecondary)),
            ),
          ],
        ),
      );
    },
  );
}
