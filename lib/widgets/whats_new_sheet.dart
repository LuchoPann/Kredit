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

/// Flag en memoria: evita que dos llamadas concurrentes muestren dos sheets.
bool _whatsNewShowing = false;

/// Muestra el sheet de novedades si la versión cambió desde la última vez.
/// No hace nada si el usuario ya vio esta versión o si ya hay un sheet abierto.
Future<void> showWhatsNewIfUpdated(BuildContext context) async {
  if (_whatsNewShowing) return;
  final version = await _resolveCurrentVersion();
  final prefs = await SharedPreferences.getInstance();
  final lastSeen = prefs.getString(_kLastSeenVersion);
  if (lastSeen == version) return;
  if (_whatsNewShowing) return; // re-check después del await

  _whatsNewShowing = true;
  // Guardar antes de mostrar: si la app se mata mientras el sheet está abierto,
  // no volvemos a mostrarlo la próxima vez.
  await prefs.setString(_kLastSeenVersion, version);

  if (!context.mounted) {
    _whatsNewShowing = false;
    return;
  }
  await showWhatsNewSheet(context);
  _whatsNewShowing = false;
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

class _WhatsNewContent extends StatefulWidget {
  const _WhatsNewContent();

  @override
  State<_WhatsNewContent> createState() => _WhatsNewContentState();
}

class _WhatsNewContentState extends State<_WhatsNewContent> {
  // Índice dentro de changelog.skip(1); null = ninguno abierto
  int? _expandedIndex;

  void _toggle(int index) {
    setState(() => _expandedIndex = _expandedIndex == index ? null : index);
  }

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    final latest = changelog.first;
    final older = changelog.skip(1).toList();

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

            // Contenido scrollable
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                children: [
                  // Cambios de la versión actual (siempre visibles)
                  ...latest.changes.map((item) => _ChangeRow(item: item)),

                  // Versiones anteriores en acordeón
                  if (older.isNotEmpty) ...[
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 8),
                    ...List.generate(older.length, (i) {
                      final entry = older[i];
                      final isOpen = _expandedIndex == i;
                      return _AccordionVersionTile(
                        entry: entry,
                        isOpen: isOpen,
                        onTap: () => _toggle(i),
                      );
                    }),
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

class _AccordionVersionTile extends StatelessWidget {
  final VersionEntry entry;
  final bool isOpen;
  final VoidCallback onTap;

  const _AccordionVersionTile({
    required this.entry,
    required this.isOpen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Versión ${entry.version}',
                        style: TextStyle(
                          fontSize: KreditTextSize.body,
                          fontWeight: FontWeight.w700,
                          color: kredit.textPrimary,
                        ),
                      ),
                      Text(
                        entry.date,
                        style: TextStyle(
                          fontSize: KreditTextSize.caption,
                          color: kredit.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: KreditIconSize.small,
                    color: kredit.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 240),
          reverseDuration: const Duration(milliseconds: 180),
          sizeCurve: Curves.easeOutCubic,
          firstCurve: Curves.easeOut,
          secondCurve: Curves.easeIn,
          crossFadeState:
              isOpen ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entry.changes.map((item) => _ChangeRow(item: item)).toList(),
            ),
          ),
          secondChild: const SizedBox(width: double.infinity),
        ),
        Divider(height: 1, color: kredit.borderCard),
      ],
    );
  }
}
