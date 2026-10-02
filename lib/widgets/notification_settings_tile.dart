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
  // Cuando el switch maestro ya se muestra afuera (p. ej. la bienvenida
  // trae su propio interruptor con su propia copia) se oculta este header
  // duplicado y solo se rendieren los pasos 1-3 de configuración.
  final bool showHeader;

  const NotificationSettingsTile({super.key, this.showHeader = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final stepBg = kredit.bgSecondary;
    final on = settings.enabled;
    final dimmed = on ? kredit.textPrimary : kredit.textTertiary;
    final dimmedSecondary = on ? kredit.textSecondary : kredit.textTertiary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) ...[
              // --- Header: master on/off ---
              Row(
                children: [
                  Icon(Icons.notifications_active_outlined, size: KreditIconSize.small, color: kredit.textSecondary),
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
            ],

            // --- Step 1: how many days ahead ---
            _StepHeader(icon: Icons.calendar_today_outlined, text: 'DÍAS DE ANTICIPACIÓN', color: dimmedSecondary),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: stepBg,
                borderRadius: BorderRadius.circular(KreditRadius.tile),
                border: Border.all(color: kredit.borderCard),
              ),
              child: Row(
                children: [
                  _StepperButton(
                    icon: Icons.remove,
                    onTap: on && settings.daysBefore > 1
                        ? () => notifier.setDaysBefore(settings.daysBefore - 1)
                        : null,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${settings.daysBefore} día${settings.daysBefore == 1 ? '' : 's'} antes',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: dimmed, fontWeight: FontWeight.w800, fontSize: KreditTextSize.heading),
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            overlayShape: SliderComponentShape.noOverlay,
                          ),
                          child: Slider(
                            value: settings.daysBefore.toDouble(),
                            min: 1,
                            max: 7,
                            divisions: 6,
                            onChanged: on ? (v) => notifier.setDaysBefore(v.round()) : null,
                          ),
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
            ),
            const SizedBox(height: KreditSpacing.section),

            // --- Step 2: what time ---
            _StepHeader(icon: Icons.schedule_outlined, text: 'HORA DEL AVISO', color: dimmedSecondary),
            const SizedBox(height: 8),
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
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                decoration: BoxDecoration(
                  color: stepBg,
                  borderRadius: BorderRadius.circular(KreditRadius.tile),
                  border: Border.all(color: kredit.borderCard),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Recibir el aviso a las', style: TextStyle(color: dimmedSecondary)),
                    ),
                    Text(
                      settings.reminderTime.format(context),
                      style: TextStyle(color: dimmed, fontWeight: FontWeight.w800, fontSize: KreditTextSize.heading),
                    ),
                    if (on) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: KreditIconSize.small, color: dimmedSecondary),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: KreditSpacing.section),

            // --- Step 3: how often ---
            _StepHeader(icon: Icons.repeat, text: 'FRECUENCIA', color: dimmedSecondary),
            const SizedBox(height: 8),
            _FrequencyOption(
              selected: !settings.repeatDaily,
              enabled: on,
              bg: stepBg,
              title: 'Un solo aviso',
              subtitle: 'Recibes una notificación el día ${settings.daysBefore} antes del vencimiento.',
              onTap: () => notifier.setRepeatDaily(false),
            ),
            const SizedBox(height: 8),
            _FrequencyOption(
              selected: settings.repeatDaily,
              enabled: on,
              bg: stepBg,
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

/// Encabezado de paso: ícono + texto en mayúsculas — mismo lenguaje que
/// `_SectionCard` en `add_credit_sheet.dart` (icono+caption+letterSpacing),
/// en vez de los círculos numerados 1-2-3 anteriores, para que esta tarjeta
/// se sienta parte del mismo sistema visual que el resto de la app.
class _StepHeader extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _StepHeader({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: KreditIconSize.small, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: KreditTextSize.body,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: color,
          ),
        ),
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
  final Color bg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FrequencyOption({
    required this.selected,
    required this.enabled,
    required this.bg,
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
          color: bg,
          borderRadius: BorderRadius.circular(KreditRadius.tile),
          border: Border.all(color: borderColor, width: selected && enabled ? 1.5 : 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: KreditIconSize.small,
              color: selected && enabled ? accent : kredit.textTertiary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: KreditTextSize.body, color: subtitleColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
