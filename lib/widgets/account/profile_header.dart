import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import 'shadowed_card.dart';

class ProfileHeader extends ConsumerWidget {
  final String profileName;
  const ProfileHeader({super.key, required this.profileName});

  String get _initials {
    final parts = profileName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(themePreferencesProvider).accentColor;
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return ShadowedCard(
      child: Padding(
        padding: const EdgeInsets.all(KreditSpacing.card),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: accent,
              child: Text(
                _initials,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
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
                    'Presiona el lápiz para editar',
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
        ),
      ),
    );
  }
}
