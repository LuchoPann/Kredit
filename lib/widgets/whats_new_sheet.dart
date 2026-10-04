import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/changelog.dart';
import '../theme/app_theme.dart';

const _kLastSeenVersion = 'whats_new_last_seen_version';

/// Versión actual leída desde pubspec (única fuente de verdad).
/// Fallback al primer entry del changelog si PackageInfo falla.
Future<String> _resolveCurrentVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    if (info.version.isNotEmpty) return info.version;
  } catch (_) {}
  return changelog.first.version;
}

/// Muestra el sheet de novedades si la versión cambió desde la última vez.
/// No hace nada si el usuario ya vio esta versión.
Future<void> showWhatsNewIfUpdated(BuildContext context) async {
  final version = await _resolveCurrentVersion();
  final prefs = await SharedPreferences.getInstance();
  final lastSeen = prefs.getString(_kLastSeenVersion);
  if (lastSeen == version) return;

  if (!context.mounted) return;
  await showWhatsNewSheet(context);

  await prefs.setString(_kLastSeenVersion, version);
}

/// Muestra el sheet de novedades siempre (llamado desde la pantalla de cuenta).
Future<void> showWhatsNewSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => const _WhatsNewContent(),
  );
}

class _WhatsNewContent extends StatelessWidget {
  const _WhatsNewContent();

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    final latest = changelog.first;

    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (ctx, controller) => Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: kredit.borderCard,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.new_releases_outlined,
                        color: accent, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Novedades',
                          style: TextStyle(
                            fontSize: KreditTextSize.emphasis,
                            fontWeight: FontWeight.w800,
                            color: kredit.textPrimary,
                          ),
                        ),
                        Text(
                          'Versión ${latest.version} · ${latest.date}',
                          style: TextStyle(
                              fontSize: KreditTextSize.caption,
                              color: kredit.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Divider(height: 1, color: kredit.borderCard),

            // Lista de cambios
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                children: [
                  ...latest.changes.map((item) => _ChangeRow(item: item)),
                  if (changelog.length > 1) ...[
                    const SizedBox(height: 16),
                    Divider(height: 1, color: kredit.borderCard),
                    const SizedBox(height: 16),
                    Text(
                      'VERSIONES ANTERIORES',
                      style: TextStyle(
                        fontSize: KreditTextSize.caption,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: kredit.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...changelog.skip(1).map((entry) => _OlderVersionBlock(entry: entry)),
                  ],
                ],
              ),
            ),

            // Botón cerrar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50)),
                child: const Text('Entendido'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  final ChangeItem item;
  const _ChangeRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;

    final (icon, color) = switch (item.type) {
      ChangeType.nuevo => (Icons.add_circle_outline, accent),
      ChangeType.mejora => (Icons.auto_awesome_outlined, Colors.amber.shade600),
      ChangeType.correccion => (Icons.build_circle_outlined, Colors.green.shade500),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 1),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.description,
              style: TextStyle(
                fontSize: KreditTextSize.body,
                color: kredit.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OlderVersionBlock extends StatelessWidget {
  final VersionEntry entry;
  const _OlderVersionBlock({required this.entry});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Versión ${entry.version} · ${entry.date}',
          style: TextStyle(
            fontSize: KreditTextSize.body,
            fontWeight: FontWeight.w700,
            color: kredit.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...entry.changes.map((item) => _ChangeRow(item: item)),
        const SizedBox(height: 8),
      ],
    );
  }
}
