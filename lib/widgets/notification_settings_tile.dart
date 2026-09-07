import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notification_settings_provider.dart';
import '../theme/app_theme.dart';

/// "Notificaciones" settings card. Kept as a standalone widget (rather than
/// inlined into `account_screen.dart`) so it can be dropped into that screen
/// with a single-line insertion.
///
/// Laid out as three clearly labeled, disabled-when-off steps (días de
/// anticipación → hora → frecuencia) plus a plain-language summary at the
/// bottom, instead of a flat stack of controls — the previous layout mixed
/// a slider, an inline time row, and a lone switch with no grouping, which
/// read as "confuso" (user feedback).
class NotificationSettingsTile extends ConsumerWidget {
  const NotificationSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final on = settings.enabled;
    final dimmed = on ? kredit.textPrimary : kredit.textTertiary;
    final dimmedSecondary = on ? kredit.textSecondary : kredit.textTertiary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header: master on/off ---
            Row(
              children: [
                Icon(Icons.notifications_active_outlined, size: 18, color: kredit.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Avisos de vencimiento',
                    style: TextStyle(color: kredit.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ),
                Switch(
                  value: settings.enabled,
                  onChanged: (v) => notifier.setEnabled(v),
                ),
              ],
            ),
            Divider(height: KreditSpacing.section, color: kredit.borderCard),

            // --- Step 1: how many days ahead ---
            _StepLabel(number: 1, text: '¿Con cuántos días de anticipación?', color: dimmedSecondary),
            const SizedBox(height: 4),
            Row(
              children: [
                _StepperButton(
                  icon: Icons.remove,
                  onTap: on && settings.daysBefore > 1
                      ? () => notifier.setDaysBefore(settings.daysBefore - 1)
                      : null,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${settings.daysBefore} día${settings.daysBefore == 1 ? '' : 's'} antes',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: dimmed, fontWeight: FontWeight.w700, fontSize: KreditTextSize.bodyLarge),
                      ),
                      Slider(
                        value: settings.daysBefore.toDouble(),
                        min: 1,
                        max: 7,
                        divisions: 6,
                        onChanged: on ? (v) => notifier.setDaysBefore(v.round()) : null,
                      ),
                    ],
                  ),
                ),
                _StepperButton(
                  icon: Icons.add,
                  onTap: on && settings.daysBefore < 7
                      ? () => notifier.setDaysBefore(settings.daysBefore + 1)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: KreditSpacing.tile),

            // --- Step 2: what time ---
            _StepLabel(number: 2, text: '¿A qué hora?', color: dimmedSecondary),
            const SizedBox(height: 4),
            InkWell(
              borderRadius: BorderRadius.circular(KreditRadius.tile),
              onTap: on
                  ? () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: settings.reminderTime,
                      );
                      if (picked != null) notifier.setReminderTime(picked);
                    }
                  : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: kredit.bgSecondary,
                  borderRadius: BorderRadius.circular(KreditRadius.tile),
                  border: Border.all(color: kredit.borderCard),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_outlined, size: 18, color: dimmedSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Hora del aviso', style: TextStyle(color: dimmedSecondary)),
                    ),
                    Text(
                      settings.reminderTime.format(context),
                      style: TextStyle(color: dimmed, fontWeight: FontWeight.w700),
                    ),
                    if (on) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 18, color: dimmedSecondary),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: KreditSpacing.tile),

            // --- Step 3: how often ---
            _StepLabel(number: 3, text: '¿Con qué frecuencia?', color: dimmedSecondary),
            const SizedBox(height: 4),
            _FrequencyOption(
              selected: !settings.repeatDaily,
              enabled: on,
              icon: Icons.notifications_none,
              title: 'Un solo aviso',
              subtitle: 'Recibes una notificación el día ${settings.daysBefore} antes del vencimiento.',
              onTap: () => notifier.setRepeatDaily(false),
            ),
            const SizedBox(height: 8),
            _FrequencyOption(
              selected: settings.repeatDaily,
              enabled: on,
              icon: Icons.repeat,
              title: 'Recordatorio diario',
              subtitle:
                  'Recibes una notificación cada día, desde ${settings.daysBefore} día${settings.daysBefore == 1 ? '' : 's'} antes hasta el día del vencimiento.',
              onTap: () => notifier.setRepeatDaily(true),
            ),
          ],
        ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  final int number;
  final String text;
  final Color color;

  const _StepLabel({required this.number, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 9,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text('$number', style: TextStyle(fontSize: KreditTextSize.caption, fontWeight: FontWeight.w700, color: color)),
        ),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: KreditTextSize.label)),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: kredit.bgSecondary,
        shape: const CircleBorder(),
      ),
    );
  }
}

class _FrequencyOption extends StatelessWidget {
  final bool selected;
  final bool enabled;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FrequencyOption({
    required this.selected,
    required this.enabled,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    final borderColor = selected && enabled ? accent : kredit.borderCard;
    final textColor = enabled ? kredit.textPrimary : kredit.textTertiary;
    final subtitleColor = enabled ? kredit.textSecondary : kredit.textTertiary;

    return InkWell(
      borderRadius: BorderRadius.circular(KreditRadius.tile),
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(KreditSpacing.tile),
        decoration: BoxDecoration(
          color: kredit.bgSecondary,
          borderRadius: BorderRadius.circular(KreditRadius.tile),
          border: Border.all(color: borderColor, width: selected && enabled ? 1.5 : 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 20,
              color: selected && enabled ? accent : kredit.textTertiary,
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 18, color: subtitleColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: KreditTextSize.label, color: subtitleColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
