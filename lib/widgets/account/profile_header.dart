import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class ProfileHeader extends ConsumerWidget {
  final String profileName;
  const ProfileHeader({super.key, required this.profileName});

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: profileName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar nombre de perfil'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Tu nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      await ref.read(themePreferencesProvider.notifier).setProfileName(result);
    }
  }

  Future<void> _pickImage(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;
      await ref.read(themePreferencesProvider.notifier).setAvatarFromFile(picked.path);
    } catch (e) {
      debugPrint('pickImage failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo cargar la imagen.')),
        );
      }
    }
  }

  Future<void> _showAvatarOptions(
    BuildContext context,
    WidgetRef ref,
    bool hasAvatar,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir de galería'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(context, ref, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(context, ref, ImageSource.camera);
                },
              ),
              if (hasAvatar)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                  title: const Text('Quitar imagen', style: TextStyle(color: AppColors.danger)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref.read(themePreferencesProvider.notifier).clearAvatar();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(themePreferencesProvider);
    final accent = prefs.accentColor;
    final avatarPath = prefs.avatarPath;
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Row(
      children: [
        GestureDetector(
          onTap: () => _showAvatarOptions(context, ref, avatarPath != null),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: accent,
            backgroundImage: avatarPath != null ? FileImage(File(avatarPath)) : null,
            child: avatarPath == null
                ? Icon(
                    Icons.person,
                    color: legibleForegroundOn(accent),
                    size: 32,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profileName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kredit.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Presiona la foto o el lápiz para editar',
                style: TextStyle(fontSize: 12, color: kredit.textTertiary),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => _editName(context, ref),
        ),
      ],
    );
  }
}
